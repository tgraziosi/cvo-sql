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
































  



					  

























































 






















































































































































































































































































































CREATE PROC [dbo].[apstlmp_sp]
	@settlement_ctrl_num 	varchar(16),
	@debug_level		smallint = 0
AS
BEGIN
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apstlmp.cpp' + ', line ' + STR( 16, 5 ) + ' -- ENTRY: '

IF NOT EXISTS (
	SELECT settlement_ctrl_num
	FROM	apinppyt
	WHERE	settlement_ctrl_num = @settlement_ctrl_num )
BEGIN
	INSERT 	appystl(
	settlement_ctrl_num, 
	vendor_code,
	pay_to_code,
	date_entered, 
	date_applied,
	user_id,
	batch_code,
	process_group_num,
	state_flag,
	disc_total_home,
	disc_total_oper,
	debit_memo_total_home,
	debit_memo_total_oper,
	on_acct_pay_total_home,
	on_acct_pay_total_oper,
	payments_total_home,
	payments_total_oper,
	put_on_acct_total_home,
	put_on_acct_total_oper,
	gain_total_home,
	gain_total_oper,
	loss_total_home,
	loss_total_oper,
        org_id)

	SELECT 
	settlement_ctrl_num, 
	vendor_code,
	pay_to_code,
	date_entered, 
	date_applied,
	user_id,
	batch_code,
	'',			
	0,			
	disc_total_home,
	disc_total_oper,
	debit_memo_total_home,
	debit_memo_total_oper,
	on_acct_pay_total_home,
	on_acct_pay_total_oper,
	payments_total_home,
	payments_total_oper,
	put_on_acct_total_home,
	put_on_acct_total_oper,
	gain_total_home,
	gain_total_oper,
	loss_total_home,
	loss_total_oper,
        org_id
	
	FROM apinpstl
	WHERE settlement_ctrl_num = @settlement_ctrl_num

	IF @@rowcount != 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apstlmp.cpp' + ', line ' + STR( 79, 5 ) + ' -- MSG: ' + 'Insert settlement number ' + @settlement_ctrl_num + ' into appystl '

	DELETE	apinpstl
	WHERE	settlement_ctrl_num = @settlement_ctrl_num 

	IF @@rowcount != 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apstlmp.cpp' + ', line ' + STR( 85, 5 ) + ' -- MSG: ' + 'Delete settlement number ' + @settlement_ctrl_num + ' from apinpstl '
	
END
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apstlmp.cpp' + ', line ' + STR( 88, 5 ) + ' -- EXIT: '

END
GO
GRANT EXECUTE ON  [dbo].[apstlmp_sp] TO [public]
GO
