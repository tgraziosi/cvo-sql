SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




















CREATE  PROCEDURE [dbo].[appycrh_sp]
	@module_id		smallint,
	@val_mode		smallint,
	@trx_ctrl_num 	varchar(16) OUTPUT,
    @trx_type		smallint,
	@doc_ctrl_num	varchar(16),
	@trx_desc		varchar(40),
	@batch_code		varchar(16),
	@cash_acct_code	varchar(32),
	@date_entered	int,
	@date_applied	int,
	@date_doc		int,
    @vendor_code		varchar(12),
	@pay_to_code		varchar(8),
	@approval_code	varchar(8),
	@payment_code 	varchar(8),
	@payment_type 	smallint,
    @amt_payment		float,
	@amt_on_acct		float,
	@posted_flag		smallint,
	@printed_flag	smallint,
	@hold_flag		smallint,
	@approval_flag	smallint,
	@gen_id			int,
	@user_id			smallint,
	@void_type		smallint, 					 
	@amt_disc_taken	float,
	@print_batch_num	int,   	  
 	@company_code	varchar(8),
	@process_group_num varchar(16),
	@nat_cur_code			varchar(8),
	@rate_type_home			varchar(8),
	@rate_type_oper			varchar(8),
	@rate_home				float,
	@rate_oper				float,
	@org_id			varchar(30) = ''		   
	
AS

DECLARE @result	int




IF( (@org_id IS NULL) OR  @org_id = '' OR (LEN(RTRIM(@org_id)) = 0))
IF @org_id = ''
BEGIN
	SELECT 	@org_id  = organization_id
	FROM	Organization
	WHERE	outline_num = '1'	
END	




IF  ( LTRIM(@trx_ctrl_num) IS NULL OR LTRIM(@trx_ctrl_num) = " " )
BEGIN

	EXEC    @result = apnewnum_sp   @trx_type, @company_code, @trx_ctrl_num  OUTPUT
	IF ( @result != 0 )
		RETURN @result

END




INSERT  #apinppyt(
	trx_ctrl_num,
    trx_type,
	doc_ctrl_num,
	trx_desc,
	batch_code,
	cash_acct_code,
	date_entered,
	date_applied,
	date_doc,
    vendor_code,
	pay_to_code,
	approval_code,
	payment_code,
	payment_type,
    amt_payment,
	amt_on_acct,
	posted_flag,
	printed_flag,
	hold_flag,
	approval_flag,
	gen_id,
	user_id,
	void_type, 					 
	amt_disc_taken,
	print_batch_num,   	  
 	company_code,
 	process_group_num,
	nat_cur_code,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper,
	trx_state,
	org_id,
	mark_flag
   	   
)       
VALUES (
	@trx_ctrl_num,
    @trx_type,
	@doc_ctrl_num,
	@trx_desc,
	@batch_code,
	@cash_acct_code,
	@date_entered,
	@date_applied,
	@date_doc,
    @vendor_code,
	@pay_to_code,
	@approval_code,
	@payment_code,
	@payment_type,
    @amt_payment,
	@amt_on_acct,
	@posted_flag,
	@printed_flag,
	@hold_flag,
	@approval_flag,
	@gen_id,
	@user_id,
	@void_type, 					 
	@amt_disc_taken,
	@print_batch_num,   	  
 	@company_code,
 	@process_group_num,
	@nat_cur_code,
	@rate_type_home,
	@rate_type_oper,
	@rate_home,
	@rate_oper,
	0,
	@org_id,
	0
   	   
)

IF ( @@error != 0 )
	RETURN  -1
	
RETURN  0

GO
GRANT EXECUTE ON  [dbo].[appycrh_sp] TO [public]
GO
