SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glupbegb.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[glupbegb_sp]	@trx_type	smallint
AS
DECLARE	@home_curr_prec	smallint,
	@oper_curr_prec	smallint

IF (@trx_type IS NULL)
BEGIN
	SELECT " "
	SELECT "Usage: EXEC glupbegb_sp TRX_TYPE"
	SELECT "Where TRX_TYPE is valid transaction type for Beginning Balances"
	SELECT "Example: EXEC glupbegb_sp 101"
	RETURN
END

SELECT	@home_curr_prec = curr_precision
FROM	glcurr_vw, glco
WHERE	home_currency = currency_code

SELECT	@oper_curr_prec = curr_precision
FROM	glcurr_vw, glco
WHERE	oper_currency = currency_code


UPDATE gltrxdet
SET	balance = ROUND(nat_balance * ( SIGN(1 + SIGN(rate))*(rate) + (SIGN(ABS(SIGN(ROUND(rate,6))))/(rate 	+ SIGN(1 - ABS(SIGN(ROUND(rate,6)))))) 	* SIGN(SIGN(rate) - 1) ),@home_curr_prec),
	balance_oper = ROUND(nat_balance * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper 	+ SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) 	* SIGN(SIGN(rate_oper) - 1) ),@oper_curr_prec)
WHERE	trx_type = @trx_type


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glupbegb_sp] TO [public]
GO
