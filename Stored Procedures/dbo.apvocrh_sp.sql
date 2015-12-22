SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[apvocrh_sp]
	@module_id			smallint,
	@val_mode			smallint,
	@trx_ctrl_num		varchar(16) OUTPUT,
	@trx_type			smallint,
	@doc_ctrl_num		varchar(16),
	@apply_to_num		varchar(16),
	@user_trx_type_code	varchar(8),
	@batch_code			varchar(16),
	@po_ctrl_num		varchar(16),
	@vend_order_num		varchar(20),
	@ticket_num			varchar(20),
	@date_applied		int,
	@date_aging			int,
	@date_due			int,
	@date_doc			int,
	@date_entered		int,
	@date_received		int,
	@date_required		int,
	@date_recurring		int,
	@date_discount		int,
	@posting_code		varchar(8),
	@vendor_code		varchar(12),
	@pay_to_code		varchar(8),
	@branch_code		varchar(8),
	@class_code			varchar(8),
	@approval_code		varchar(8),
	@comment_code		varchar(8),
	@fob_code			varchar(8),
	@terms_code			varchar(8),
	@tax_code			varchar(8),
	@recurring_code		varchar(8),
	@location_code		varchar(8),
	@payment_code		varchar(8),
	@times_accrued		smallint,
	@accrual_flag		smallint,
	@drop_ship_flag		smallint,
	@posted_flag		smallint,
	@hold_flag			smallint,
	@add_cost_flag		smallint,
	@approval_flag		smallint,
	@recurring_flag		smallint,
	@one_time_vend_flag	smallint,
	@one_check_flag		smallint,
	@amt_gross			float,
	@amt_discount		float,
	@amt_tax			float,
	@amt_freight		float,
	@amt_misc			float,
	@amt_net			float,
	@amt_paid			float,
	@amt_due			float,
	@amt_restock		float,
	@amt_tax_included	float,
	@frt_calc_tax		float,
	@doc_desc			varchar(40),
	@hold_desc			varchar(40),
	@user_id			smallint,
	@next_serial_id		smallint,
	@pay_to_addr1		varchar(40),
	@pay_to_addr2		varchar(40),
	@pay_to_addr3		varchar(40),
	@pay_to_addr4		varchar(40),
	@pay_to_addr5		varchar(40),
	@pay_to_addr6		varchar(40),
	@attention_name		varchar(40),
	@attention_phone	varchar(30),
	@intercompany_flag	smallint,
	@company_code	varchar(8),
	@cms_flag		smallint,
	@process_group_num varchar(16),
	@nat_cur_code 			varchar(8),	 
	@rate_type_home 			varchar(8),	 
	@rate_type_oper			varchar(8),	 
	@rate_home 				float,		
	@rate_oper				float,
	@net_original_amt			float,
        @org_id                        varchar(30)  = '',          
	@tax_freight_no_recoverable	float = 0.0
		
AS

DECLARE @result	int




IF @org_id = ''
BEGIN
	SELECT 	@org_id  = organization_id
	FROM	Organization
	WHERE	outline_num = '1'	
END





IF  ( LTRIM(@trx_ctrl_num) IS NULL OR LTRIM(@trx_ctrl_num) = " " )
BEGIN

	EXEC    @result = apnewnum_sp   @trx_type, @company_code, @trx_ctrl_num       OUTPUT
	IF ( @result != 0 )
		RETURN @result
END



IF @hold_flag = 13
    SELECT @hold_flag = 0
ELSE
   SELECT @hold_flag = 1

if (@recurring_flag = 1 AND (SELECT on_hold from apcycle where cycle_code = @recurring_code) = 1)
SELECT @hold_flag = 1
IF (@recurring_flag = 1 AND (SELECT on_hold from apcycle where cycle_code = @recurring_code) = 0)
SELECT @hold_flag = 0




INSERT  #apinpchg(
	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	apply_to_num,
	user_trx_type_code,
	batch_code,
	po_ctrl_num,
	vend_order_num,
	ticket_num,
	date_applied,
	date_aging,
	date_due,
	date_doc,
	date_entered,
	date_received,
	date_required,
	date_recurring,
	date_discount,
	posting_code,
	vendor_code,
	pay_to_code,
	branch_code,
	class_code,
	approval_code,
	comment_code,
	fob_code,
	terms_code,
	tax_code,
	recurring_code,
	location_code,
	payment_code,
	times_accrued,
	accrual_flag,
	drop_ship_flag,
	posted_flag,
	hold_flag,
	add_cost_flag,
	approval_flag,
	recurring_flag,
	one_time_vend_flag,
	one_check_flag,
	amt_gross,
	amt_discount,
	amt_tax,
	amt_freight,
	amt_misc,
	amt_net	,
	amt_paid,
	amt_due,
	amt_restock,
	amt_tax_included,
	frt_calc_tax,
	doc_desc,
	hold_desc,
	user_id,
	next_serial_id,
	pay_to_addr1,
	pay_to_addr2,
	pay_to_addr3,
	pay_to_addr4,
	pay_to_addr5,
	pay_to_addr6,
	attention_name,
	attention_phone,
	intercompany_flag,
	company_code,
	cms_flag,
	process_group_num,
	nat_cur_code,	 
	rate_type_home,	 
	rate_type_oper,	 
	rate_home,		   
	rate_oper,		   
	trx_state,
	mark_flag,
	net_original_amt,
        org_id,                
	tax_freight_no_recoverable
)       
VALUES (
	@trx_ctrl_num,
	@trx_type,
	@doc_ctrl_num,
	@apply_to_num,
	@user_trx_type_code,
	@batch_code,
	@po_ctrl_num,
	@vend_order_num,
	@ticket_num,
	@date_applied,
	@date_aging,
	@date_due,
	@date_doc,
	@date_entered,
	@date_received,
	@date_required,
	@date_recurring,
	@date_discount,
	@posting_code,
	@vendor_code,
	@pay_to_code,
	@branch_code,
	@class_code,
	@approval_code,
	@comment_code,
	@fob_code,
	@terms_code,
	@tax_code,
	@recurring_code,
	@location_code,
	@payment_code,
	@times_accrued,
	@accrual_flag,
	@drop_ship_flag,
	@posted_flag,
	@hold_flag,
	@add_cost_flag,
	@approval_flag,
	@recurring_flag,
	@one_time_vend_flag,
	@one_check_flag,
	@amt_gross,
	@amt_discount,
	@amt_tax,
	@amt_freight,
	@amt_misc,
	@amt_net,
	@amt_paid,
	@amt_due,
	@amt_restock,
	@amt_tax_included,
	@frt_calc_tax,
	@doc_desc,
	@hold_desc,
	@user_id,
	@next_serial_id,
	@pay_to_addr1,
	@pay_to_addr2,
	@pay_to_addr3,
	@pay_to_addr4,
	@pay_to_addr5,
	@pay_to_addr6,
	@attention_name,
	@attention_phone,
	@intercompany_flag,
	@company_code,
	@cms_flag,
	@process_group_num,
	@nat_cur_code,	 
	@rate_type_home,	 
	@rate_type_oper,	 
	@rate_home,		   
	@rate_oper,		   
	0,
	0,
	@net_original_amt,
        @org_id,                
	@tax_freight_no_recoverable
)

IF ( @@error != 0 )
	RETURN  -1
	

RETURN  0


GO
GRANT EXECUTE ON  [dbo].[apvocrh_sp] TO [public]
GO
