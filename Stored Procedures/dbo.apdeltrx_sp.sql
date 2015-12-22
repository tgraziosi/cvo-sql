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




















































CREATE PROCEDURE [dbo].[apdeltrx_sp]
	@trx_ctrl_num varchar(30), @trx_type smallint
AS
DECLARE @vendor_code 	varchar(12),
	@pay_to_code 	varchar(8),
	@class_code  	varchar(8),
	@branch_code 	varchar(8),
	@amt_due 	float,
	@voucher_type	smallint,
	@payment_type	smallint,
	@rate_home float,
	@rate_oper float,
	@po_type		smallint



SELECT	@voucher_type = 4091,	@payment_type = 4111, @po_type = 4090

BEGIN TRANSACTION delete_trx




IF	@trx_type = @voucher_type
BEGIN
	SELECT	@vendor_code = vendor_code,
		@pay_to_code = pay_to_code,
		@class_code = class_code,
		@branch_code = branch_code,
		@amt_due = amt_due,
		@rate_home = rate_home,
		@rate_oper = rate_oper
	FROM	apinpchg
	WHERE	trx_ctrl_num = @trx_ctrl_num
	AND	trx_type = @trx_type

	


	DELETE 	FROM apinpchg
	WHERE 	trx_ctrl_num = @trx_ctrl_num
	AND 	trx_type = @trx_type

	


	DELETE 	FROM apinpcdt
	WHERE 	trx_ctrl_num = @trx_ctrl_num
	AND 	trx_type = @trx_type

	


	DELETE 	FROM apinpage
	WHERE 	trx_ctrl_num = @trx_ctrl_num
	AND 	trx_type = @trx_type

	


	DELETE 	FROM apinptax
	WHERE 	trx_ctrl_num = @trx_ctrl_num
	AND 	trx_type = @trx_type

	


	SELECT	@amt_due = @amt_due * -1

	EXEC apactinp_sp
	   @vendor_code, @pay_to_code, @class_code, @branch_code, @amt_due, @rate_home, @rate_oper

END
ELSE IF @trx_type = @payment_type
BEGIN
	SELECT	@vendor_code = vendor_code,
		@pay_to_code = pay_to_code
	FROM	apinppyt
	WHERE	trx_ctrl_num = @trx_ctrl_num
	AND	trx_type = @trx_type

	


	DELETE 	FROM apinppyt
	WHERE 	trx_ctrl_num = @trx_ctrl_num
	AND 	trx_type = @trx_type

	


	DELETE 	FROM apinppdt
	WHERE 	trx_ctrl_num = @trx_ctrl_num
	AND 	trx_type = @trx_type
END
ELSE if @trx_type = @po_type
BEGIN
	UPDATE purchase_all
	set status = 'V', void = 'V', void_who = suser_sname(), void_date = getdate()
	where po_no = @trx_ctrl_num


END 



DELETE	FROM apaprtrx
WHERE 	trx_ctrl_num = @trx_ctrl_num
AND 	trx_type = @trx_type

commit transaction  DELETE_trx



GO
GRANT EXECUTE ON  [dbo].[apdeltrx_sp] TO [public]
GO
