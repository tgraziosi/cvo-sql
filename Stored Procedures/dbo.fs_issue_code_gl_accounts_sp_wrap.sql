SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[fs_issue_code_gl_accounts_sp_wrap] @issue_code varchar (12) , @org_id varchar(30)=''  as


BEGIN

DECLARE          @account varchar (32) ,
		@direct_account_expense varchar (32),  -- this is labor
		@ovhd_account_expense varchar (32) ,
		@util_account_expense varchar (32) ,
		@desc_account varchar (40) ,
		@desc_direct_accnt varchar (40) ,
		@desc_ovhd_accnt varchar (40) ,
		@desc_util_accnt varchar ( 40 ) ,
		@ref_account_flag int ,
		@ref_direct_accnt_flag  int ,
		@ref_ovhd_accnt_flag   int ,
		@ref_util_accnt_flag  int 
exec  dbo.fs_issue_code_gl_accounts_sp @issue_code , 
		@account output,
		@direct_account_expense  output ,  -- this is labor
		@ovhd_account_expense  output ,
		@util_account_expense  output ,
		@desc_account  output ,
		@desc_direct_accnt  output ,
		@desc_ovhd_accnt output ,
		@desc_util_accnt  output ,
		@ref_account_flag output ,
		@ref_direct_accnt_flag  output ,
		@ref_ovhd_accnt_flag   output ,
		@ref_util_accnt_flag   output ,
		@org_id

SELECT 	@account,
		@direct_account_expense ,  -- this is labor
		@ovhd_account_expense ,
		@util_account_expense ,
		@desc_account ,
		@desc_direct_accnt ,
		@desc_ovhd_accnt ,
		@desc_util_accnt ,
		@ref_account_flag ,
		@ref_direct_accnt_flag ,
		@ref_ovhd_accnt_flag ,
		@ref_util_accnt_flag

END 
GO
GRANT EXECUTE ON  [dbo].[fs_issue_code_gl_accounts_sp_wrap] TO [public]
GO
