SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                














	


CREATE PROCEDURE [dbo].[ARAPCalculateDiscount_sp] 
		@dis_terms_code 	VARCHAR(8),
		@cr_date_doc 		int,
		@dis_doc_date 		int,		
		@discount_flag 		smallint OUTPUT, 
		@discount_prc		float	OUTPUT
AS
DECLARE
	@terms_type		smallint,
	@days_due		int,
	@days_discount		int,
	@discount_val		int,
	@dis_year		int,
	@dis_month		int,
	@dis_day		int,
	@seq			int,
	@date_init		int,
	@discount_days		int,
	@date_dif		int,
	@first_day_of_date_discount int,
	@year_dis 			int, 
	@month_dis 			int, 
	@day_dis			int,
	@year 				int, 
	@month 				int, 
	@day 				int


	
		EXEC appdtjul_sp @dis_year OUTPUT, @dis_month OUTPUT, @dis_day OUTPUT, @cr_date_doc

		SELECT 	@terms_type 	= terms_type,
			@days_due 	= days_due,
			@days_discount 	= discount_days			
		FROM arterms 
		WHERE terms_code 	= @dis_terms_code

		SELECT @discount_prc = 0

		IF @terms_type in (1,4)
		BEGIN

			SELECT @date_dif = @cr_date_doc - @dis_doc_date
				
			IF @date_dif = 0
				SELECT @date_dif = 1

			SELECT 	@seq = 0, @date_init = -9999999
		
			WHILE 1=1
			BEGIN

				SELECT 	@seq 		= MIN(sequence_id)
				FROM 	artermsd
				WHERE 	terms_code 	= @dis_terms_code
				AND	sequence_id > @seq
	
				IF @seq IS NULL
				BEGIN
					BREAK
				END

				SELECT 	@discount_days	= discount_days,
					@discount_prc	= discount_prc	
				FROM	artermsd
				WHERE 	terms_code 	= @dis_terms_code
				AND	sequence_id 	= @seq


				SELECT @discount_flag = SIGN(@discount_days)


				IF 	@date_dif >= @date_init AND @date_dif <= @discount_days
				begin
					BREAK
				end
				ELSE
				BEGIN
					SELECT @date_init  = @discount_days
					SELECT @discount_prc = 0 
				END

			END	

		END			

		IF @terms_type = 2
		BEGIN
			EXEC	appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @cr_date_doc

			EXEC	appdtjul_sp @year_dis OUTPUT, @month_dis OUTPUT, @day_dis OUTPUT, @dis_doc_date
			
			EXEC    appjuldt_sp @year_dis , @month_dis , 1 , @first_day_of_date_discount OUTPUT


			SELECT 	@seq = 0, @date_init = 0
	
			WHILE 1=1
			BEGIN
				SELECT 	@seq = MIN(sequence_id)
				FROM 	artermsd
				WHERE 	terms_code = @dis_terms_code
				AND	sequence_id > @seq
	
				IF @seq IS NULL
				BEGIN
					BREAK
				END

				SELECT 	@discount_days	= discount_days,
					@discount_prc	= discount_prc
				FROM	artermsd
				WHERE 	terms_code = @dis_terms_code
				AND	sequence_id = @seq

				SELECT @discount_flag = SIGN(@discount_days)

				if @cr_date_doc <= (@first_day_of_date_discount + (@discount_days - 1) )
					BREAK
				ELSE
				BEGIN
					SELECT @date_init  = @discount_days
					SELECT @discount_prc = 0 
				END
			END	
		
		END

		IF @terms_type = 3
		BEGIN
















			SELECT 	@seq = 0, @date_init = 693594
		
			WHILE 1=1
			BEGIN
	
				SELECT 	@seq = MIN(sequence_id)
				FROM 	artermsd
				WHERE 	terms_code = @dis_terms_code
				AND	sequence_id > @seq
		
				IF @seq IS NULL
				BEGIN	
					BREAK
				END
		
				SELECT 	@discount_val	= date_discount,
					@discount_prc	= discount_prc
				FROM	artermsd
				WHERE 	terms_code = @dis_terms_code
				AND	sequence_id = @seq
			
				SELECT @discount_flag = SIGN(@discount_val)
	
				IF @cr_date_doc > @date_init AND @cr_date_doc <= @discount_val
					BREAK
				ELSE
				BEGIN
					SELECT @date_init  	= @discount_val
					SELECT @discount_prc = 0 
				END

			END	


		END   
		



























	
RETURN
GO
GRANT EXECUTE ON  [dbo].[ARAPCalculateDiscount_sp] TO [public]
GO
