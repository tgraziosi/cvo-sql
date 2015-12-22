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


CREATE PROC [dbo].[calc_discount_sp] @date_doc int, @trx_ctrl_num varchar(16), @terms_code varchar(8), @prc float OUTPUT
AS

DECLARE @terms_type 	int,
	@date_dif	int,
	@seq		int,
	@date_init	int,
	@discount_days	int,
	@day 		int,
	@month		int,
	@year		int,
	@date_discount	int,
	@date_invoice	int,
	@due_date	int,
	@first_day_of_date_discount int,
	@year_dis 			int, 
	@month_dis 			int, 
	@day_dis			int

SELECT  @terms_type = ISNULL(terms_type,1)
FROM 	apterms
WHERE 	terms_code = @terms_code

SELECT @prc = 0

IF @terms_type in (1,4)
BEGIN

	SELECT @date_invoice = date_doc
	FROM	apvohdr
	WHERE	trx_ctrl_num = @trx_ctrl_num

	IF @date_invoice is NULL
		RETURN @prc

	SELECT @date_dif = @date_doc - @date_invoice
	
	IF @date_dif = 0
		SELECT @date_dif = 1

	SELECT 	@seq = 0, @date_init = 0
	
	WHILE 1=1
	BEGIN

		SELECT 	@seq = MIN(sequence_id)
		FROM 	aptermsd
		WHERE 	terms_code = @terms_code
		AND	sequence_id > @seq
	
		IF @seq IS NULL
		BEGIN
			BREAK
		END

		SELECT 	@discount_days	= discount_days,
			@prc		= discount_prc
		FROM	aptermsd
		WHERE 	terms_code = @terms_code
		AND	sequence_id = @seq

		IF 	@date_dif < 0
			BREAK
		
		IF 	@date_dif >= @date_init AND @date_dif <= @discount_days
			BREAK
		ELSE
		BEGIN
			SELECT @date_init  = @discount_days
			SELECT @prc = 0 
		END

	END	

END	


IF @terms_type = 2
BEGIN

	
	SELECT 	@date_discount  = date_discount,
		@due_date	= date_due
	FROM	apvohdr
	WHERE	trx_ctrl_num = @trx_ctrl_num

	EXEC	appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @date_doc

	EXEC	appdtjul_sp @year_dis OUTPUT, @month_dis OUTPUT, @day_dis OUTPUT, @date_discount
	
	EXEC    appjuldt_sp @year_dis , @month_dis , 1 , @first_day_of_date_discount OUTPUT


	SELECT 	@seq = 0, @date_init = 0
	
	WHILE 1=1
	BEGIN
		SELECT 	@seq = MIN(sequence_id)
		FROM 	aptermsd
		WHERE 	terms_code = @terms_code
		AND	sequence_id > @seq
	
		IF @seq IS NULL
		BEGIN
			BREAK
		END

		SELECT 	@discount_days	= discount_days,
			@prc		= discount_prc
		FROM	aptermsd
		WHERE 	terms_code = @terms_code
		AND	sequence_id = @seq

		if @date_doc <= (@first_day_of_date_discount + (@discount_days - 1) )
			BREAK
		ELSE
		BEGIN
			SELECT @date_init  = @discount_days
			SELECT @prc = 0 
		END
	END	


END 


IF @terms_type = 3
BEGIN

	SELECT 	@seq = 0, @date_init = 693594
	
	WHILE 1=1
	BEGIN

		SELECT 	@seq = MIN(sequence_id)
		FROM 	aptermsd
		WHERE 	terms_code = @terms_code
		AND	sequence_id > @seq
	
		IF @seq IS NULL
		BEGIN
			BREAK
		END

		SELECT 	@date_discount	= date_discount,
			@prc		= discount_prc
		FROM	aptermsd
		WHERE 	terms_code = @terms_code
		AND	sequence_id = @seq

		IF @date_doc > @date_init AND @date_doc <= @date_discount
			BREAK
		ELSE
		BEGIN
			SELECT @date_init  = @date_discount
			SELECT @prc = 0 
		END

	END	

END  

SELECT @prc = @prc /100

RETURN @prc 

GO
GRANT EXECUTE ON  [dbo].[calc_discount_sp] TO [public]
GO
