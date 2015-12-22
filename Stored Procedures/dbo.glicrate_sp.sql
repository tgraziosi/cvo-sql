SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glicrate.SPv - e7.2.2 : 1.7
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                
















 



					 










































 







































































































































































































































































 










































































































































































CREATE 	PROCEDURE [dbo].[glicrate_sp]
	@apply_date			int,
	@origin_home_currency		varchar(8), 
	@origin_home_amount		float,		
	@origin_natural_currency	varchar(8),	
	@origin_natural_amount		float,		
	@origin_oper_currency		varchar(8), 
	@origin_oper_amount		float,		
	@rate_mode			smallint,	
	@rate_type_home			varchar(8),
	@rate_type_oper			varchar(8),
	@recip_home_currency		varchar(8),
	@recip_oper_currency		varchar(8), 
	@recip_home_amount		float	 		OUTPUT,
	@recip_oper_amount		float	 		OUTPUT,
	@recip_natural_currency		varchar(8)	OUTPUT,
	@recip_natural_amount		float	 		OUTPUT,
	@recip_rate_used		float			OUTPUT,
	@recip_rate_oper		float			OUTPUT

AS 
BEGIN

	DECLARE	@result	int

	
	IF	( @origin_natural_currency = @recip_home_currency )
	BEGIN
		IF ( @rate_mode = 4 )
		BEGIN
			SELECT	@recip_home_amount = @origin_natural_amount,
				@recip_natural_amount = @origin_home_amount,
				@recip_natural_currency = @origin_home_currency
				
			EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
				@recip_natural_currency, @recip_natural_amount, 
				@recip_home_currency, @rate_type_home, @recip_home_amount OUTPUT, 
				@recip_rate_used OUTPUT, 0
			
		END
		
		ELSE
		BEGIN
			SELECT	@recip_home_amount = @origin_natural_amount,
				@recip_natural_amount = @origin_natural_amount,
				@recip_natural_currency = @recip_home_currency,
				@recip_rate_used = 1.0
		END

		EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
			@recip_natural_currency, @recip_natural_amount, 
			@recip_oper_currency, @rate_type_oper, 
			@recip_oper_amount OUTPUT, 
			@recip_rate_oper OUTPUT, 0


	END

	ELSE
	BEGIN
		
		IF ( @rate_mode = 1 AND @recip_home_currency != @origin_home_currency )
		BEGIN	
			SELECT	@recip_natural_currency = @origin_natural_currency,
				@recip_natural_amount	= @origin_natural_amount

			
			EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
				@recip_natural_currency, @recip_natural_amount, 
				@recip_home_currency, @rate_type_home, @recip_home_amount OUTPUT, 
				@recip_rate_used OUTPUT, 0

			IF @result = 0
			BEGIN
				
				EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
			@recip_natural_currency, @recip_natural_amount, 
					@recip_oper_currency, @rate_type_oper, 
					@recip_oper_amount OUTPUT, 
					@recip_rate_oper OUTPUT, 0


			END
		END

		ELSE IF ( @rate_mode = 1 AND @recip_home_currency = @origin_home_currency )
		BEGIN
			SELECT	@recip_natural_currency = @origin_natural_currency,
				@recip_natural_amount	= @origin_natural_amount,
				@recip_home_amount	= @origin_home_amount,
				@recip_rate_used 	= 1

			EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
			@recip_natural_currency, @recip_natural_amount, 
				@recip_oper_currency, @rate_type_oper, 
				@recip_oper_amount OUTPUT, 
				@recip_rate_oper OUTPUT, 0


		END

		
		IF ( @rate_mode = 2 )	 
		BEGIN	
			SELECT	@recip_natural_currency = @origin_natural_currency,
				@recip_natural_amount	= @origin_natural_amount

			
			EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
				@origin_home_currency, @origin_home_amount, 
				@recip_home_currency, @rate_type_home,
				@recip_home_amount OUTPUT, @recip_rate_used OUTPUT, 0


			IF @result = 0
			BEGIN
				SELECT	@recip_rate_used = @recip_home_amount / @recip_natural_amount

				EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
			@recip_natural_currency, @recip_natural_amount, 
					@recip_oper_currency, @rate_type_oper, 
					@recip_oper_amount OUTPUT, 
					@recip_rate_oper OUTPUT, 0


			END
		END

		
		IF ( @rate_mode = 3 )	 
		BEGIN
			EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
				@origin_home_currency, @origin_home_amount, 
				@recip_home_currency, @rate_type_home,
				@recip_home_amount OUTPUT, @recip_rate_used OUTPUT, 0

			IF @result = 0
			BEGIN
				SELECT	@recip_natural_currency = @recip_home_currency,
					@recip_natural_amount	= @recip_home_amount, 
					@recip_rate_used 	= 1.0

				EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
			@recip_natural_currency, @recip_natural_amount, 
					@recip_oper_currency, @rate_type_oper, 
					@recip_oper_amount OUTPUT, 
					@recip_rate_oper OUTPUT, 0


			END
		END

		
		IF ( @rate_mode = 4 )
		BEGIN
			EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
				@origin_home_currency, @origin_home_amount, 
				@recip_home_currency, @rate_type_home,
				@recip_home_amount OUTPUT, @recip_rate_used OUTPUT, 0


			IF @result = 0
			BEGIN
				SELECT	@recip_natural_currency = @origin_home_currency,
					@recip_natural_amount 	= @origin_home_amount


				EXEC	@result = CVO_Control..mccurcvt_sp @apply_date, 1, 
			@recip_natural_currency, @recip_natural_amount, 
					@recip_oper_currency, @rate_type_oper, 
					@recip_oper_amount OUTPUT, 
					@recip_rate_oper OUTPUT, 0


			END
		END
	END
	
	IF	@result = 100
		SELECT	@result = 1047
	ELSE IF @result = 101
		SELECT	@result = 1048
	ELSE IF	@result = 102
		SELECT	@result = 1049
	ELSE
		SELECT	@result = 0

	RETURN @result
END
GO
GRANT EXECUTE ON  [dbo].[glicrate_sp] TO [public]
GO
