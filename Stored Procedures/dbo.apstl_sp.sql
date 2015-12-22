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




create proc [dbo].[apstl_sp] @WhereClause varchar(1024)="" as
DECLARE
	@OrderBy	varchar(255)




create table #Settlements
(
	settlement_ctrl_num		varchar(16),
	org_id				varchar(30) NULL, 
	vendor_name			varchar(40),
	vendor_code			varchar(12),
	pay_to_code		        varchar(8),
	date_entered			int, 
	date_applied			int,
	posted_flag      		varchar(4),
	hold_flag               	varchar(4),	 
	disc_total_home			float,
	disc_total_oper			float,
	debit_memo_total_home		float,
	debit_memo_total_oper		float,
	on_acct_pay_total_home		float,
	on_acct_pay_total_oper		float,
	payments_total_home		float,
	payments_total_oper		float,
	put_on_acct_total_home		float,
	put_on_acct_total_oper		float,
	gain_total_home			float,
	gain_total_oper			float,
	loss_total_home			float,
	loss_total_oper			float

)
create clustered index pst_1 on #Settlements (vendor_name,vendor_code,settlement_ctrl_num)


select @OrderBy = " order by vendor_name,vendor_code,settlement_ctrl_num"







	
	insert into #Settlements 
	(
		settlement_ctrl_num, 
		org_id,
		vendor_name,
		vendor_code,
   		pay_to_code,
		date_entered, 
		date_applied,
		posted_flag,
		hold_flag,	 
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
		loss_total_oper
    )
	select
		appystl.settlement_ctrl_num, 
		appystl.org_id,
		apvend.vendor_name,
		appystl.vendor_code,
   		appystl.pay_to_code,
		appystl.date_entered, 
		appystl.date_applied,
		posted_flag='Yes',
		hold_flag='No',	 
		appystl.disc_total_home,
		appystl.disc_total_oper,
		appystl.debit_memo_total_home,
		appystl.debit_memo_total_oper,
		appystl.on_acct_pay_total_home,
		appystl.on_acct_pay_total_oper,
		appystl.payments_total_home,
		appystl.payments_total_oper,
		appystl.put_on_acct_total_home,
		appystl.put_on_acct_total_oper,
		appystl.gain_total_home,
		appystl.gain_total_oper,
		appystl.loss_total_home,
		appystl.loss_total_oper
		
	from    
		appystl appystl, apvend apvend
	where appystl.vendor_code = apvend.vendor_code          
	
		





insert into #Settlements 
	(
		settlement_ctrl_num, 
		org_id,
		vendor_name,
		vendor_code,
   		pay_to_code,
		date_entered, 
		date_applied,
		posted_flag,
		hold_flag,	 
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
		loss_total_oper
    )
	select
		apinpstl.settlement_ctrl_num, 
		apinpstl.org_id,
		apvend.vendor_name,
		apinpstl.vendor_code,
   		apinpstl.pay_to_code,
		apinpstl.date_entered, 
		apinpstl.date_applied,
		posted_flag = 'No',
		hold_flag = case apinpstl.hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,	 
		apinpstl.disc_total_home,
		apinpstl.disc_total_oper,
		apinpstl.debit_memo_total_home,
		apinpstl.debit_memo_total_oper,
		apinpstl.on_acct_pay_total_home,
		apinpstl.on_acct_pay_total_oper,
		apinpstl.payments_total_home,
		apinpstl.payments_total_oper,
		apinpstl.put_on_acct_total_home,
		apinpstl.put_on_acct_total_oper,
		apinpstl.gain_total_home,
		apinpstl.gain_total_oper,
		apinpstl.loss_total_home,
		apinpstl.loss_total_oper 
		
	from    
		apinpstl apinpstl, apvend apvend
	where apinpstl.vendor_code = apvend.vendor_code          






exec ("	select *, x_date_entered=date_entered, x_date_applied=date_applied, x_disc_total_home=disc_total_home, x_disc_total_oper=disc_total_oper, x_debit_memo_total_home=debit_memo_total_home, x_debit_memo_total_oper=debit_memo_total_oper, x_on_acct_pay_total_home=on_acct_pay_total_home, x_on_acct_pay_total_oper=on_acct_pay_total_oper, x_payments_total_home=payments_total_home, x_payments_total_oper=payments_total_oper, x_put_on_acct_total_home=put_on_acct_total_home, x_put_on_acct_total_oper=put_on_acct_total_oper, x_gain_total_home=gain_total_home, x_gain_total_oper=gain_total_oper, x_loss_total_home=loss_total_home, x_loss_total_oper=loss_total_oper from #Settlements" + @WhereClause + @OrderBy)


GO
GRANT EXECUTE ON  [dbo].[apstl_sp] TO [public]
GO
