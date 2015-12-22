SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[fs_issue_code_gl_accounts_sp] @issue_code varchar (12) , 
		@account varchar (32) output ,
		@direct_account_expense varchar (32) output ,  -- this is labor
		@ovhd_account_expense varchar (32) output ,
		@util_account_expense varchar (32) output ,
		@desc_account varchar (40) output ,
		@desc_direct_accnt varchar (40) output ,
		@desc_ovhd_accnt varchar (40) output ,
		@desc_util_accnt varchar ( 40 ) output ,
		@ref_account_flag int  output ,
		@ref_direct_accnt_flag  int   output ,
		@ref_ovhd_accnt_flag   int   output ,
		@ref_util_accnt_flag  int   output ,
		@org_id varchar(30)
as

select 	@account = account_code,
	@desc_account = account_description
from 	issue_code ,
  adm_glchart_all (nolock) 
WHERE inactive_flag = 0 and code = @issue_code 	and 
  dbo.adm_mask_acct_fn(issue_code.account, @org_id) = adm_glchart_all.account_code 

if @@rowcount = 1 
  begin							
	
	select 	@account = isnull(@account,''),
                @direct_account_expense =  isnull(@account,''),
		@ovhd_account_expense = isnull(@account,''),
		@util_account_expense = isnull(@account,''),
		@desc_direct_accnt  = @desc_account ,
		@desc_ovhd_accnt = @desc_account ,
		@desc_util_accnt =  @desc_account 

	





	select  	@ref_account_flag = isnull ( min ( dbo.glrefact.reference_flag ) , 1 )
	from 	dbo.glrefact	
	where 	@account   like dbo.glrefact.account_mask 	and 
		dbo.glrefact.reference_flag >= 2

	select  	@ref_direct_accnt_flag = isnull ( min ( dbo.glrefact.reference_flag ) , 1 )
	from 	dbo.glrefact	
	where 	@direct_account_expense like dbo.glrefact.account_mask 	and 
		dbo.glrefact.reference_flag >= 2

	select  	@ref_ovhd_accnt_flag = isnull ( min ( dbo.glrefact.reference_flag ) , 1 )
	from 	dbo.glrefact	
	where 	@ovhd_account_expense  like dbo.glrefact.account_mask 	and 
		dbo.glrefact.reference_flag >= 2

	select  	@ref_util_accnt_flag = isnull ( min ( dbo.glrefact.reference_flag ) , 1 )
	from 	dbo.glrefact	
	where 	@util_account_expense  like dbo.glrefact.account_mask 	and 
		dbo.glrefact.reference_flag >= 2

	return 0
  end
else
 begin
	--raiserror issue code does not exist / fs_issue_code_gl_accounts_sp
	select @account = '', @direct_account_expense = '', @ovhd_account_expense = '', @util_account_expense = ''
	return 1
 end


GO
GRANT EXECUTE ON  [dbo].[fs_issue_code_gl_accounts_sp] TO [public]
GO
