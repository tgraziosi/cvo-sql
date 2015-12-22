SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*

EXEC ESC_ProcessCVOPayments_sp 'ABC001','sa', 1

*/


CREATE procedure [dbo].[ESC_ProcessCVOPayments_sp] @ParRecID varchar(40),@UserName varchar(30) = 'sa', @final smallint = 1, @MsgOut smallint OUTPUT
as


-- Rev 1- GEP 2/23/2012 put new cash receipts on hold if they already exist. Update PDT aging date from invoice
-- Rev 2- GEP 5/08/2012 Use Check Date as Apply Date


set nocount on


-- select @final = 0 

CREATE TABLE #arinppyt_hdr(
	[trx_ctrl_num] [varchar](16) NOT NULL,
	[doc_ctrl_num] [varchar](16) NOT NULL,
	[trx_desc] [varchar](40) NOT NULL,
	[batch_code] [varchar](16) NOT NULL,
	[trx_type] [smallint] NOT NULL,
	[non_ar_flag] [smallint] NOT NULL,
	[non_ar_doc_num] [varchar](16) NOT NULL,
	[gl_acct_code] [varchar](32) NOT NULL,
	[date_entered] [int] NOT NULL,
	[date_applied] [int] NOT NULL,
	[date_doc] [int] NOT NULL,
	[customer_code] [varchar](8) NOT NULL,
	[payment_code] [varchar](8) NOT NULL,
	[payment_type] [smallint] NOT NULL,
	[amt_payment] [float] NOT NULL,
	[amt_on_acct] [float] NOT NULL,
	[prompt1_inp] [varchar](30) NOT NULL,
	[prompt2_inp] [varchar](30) NOT NULL,
	[prompt3_inp] [varchar](30) NOT NULL,
	[prompt4_inp] [varchar](30) NOT NULL,
	[deposit_num] [varchar](16) NOT NULL,
	[bal_fwd_flag] [smallint] NOT NULL,
	[printed_flag] [smallint] NOT NULL,
	[posted_flag] [smallint] NOT NULL,
	[hold_flag] [smallint] NOT NULL,
	[wr_off_flag] [smallint] NOT NULL,
	[on_acct_flag] [smallint] NOT NULL,
	[user_id] [smallint] NOT NULL,
	[max_wr_off] [float] NOT NULL,
	[days_past_due] [int] NOT NULL,
	[void_type] [smallint] NOT NULL,
	[cash_acct_code] [varchar](32) NOT NULL,
	[origin_module_flag] [smallint] NULL,
	[process_group_num] [varchar](16) NULL,
	[source_trx_ctrl_num] [varchar](16) NULL,
	[source_trx_type] [smallint] NULL,
	[nat_cur_code] [varchar](8) NOT NULL,
	[rate_type_home] [varchar](8) NOT NULL,
	[rate_type_oper] [varchar](8) NOT NULL,
	[rate_home] [float] NOT NULL,
	[rate_oper] [float] NOT NULL,
	[amt_discount] [float] NULL,
	[reference_code] [varchar](32) NULL,
	[settlement_ctrl_num] [varchar](16) NULL,
	[doc_amount] [float] NULL,
	[org_id] [varchar](30) NULL,
	[parent_cust] [varchar](8) NULL,
	[SourceType] [smallint]
)

CREATE TABLE #arinppdt_det
(
	[trx_ctrl_num] [varchar](16) NOT NULL,
	[doc_ctrl_num] [varchar](16) NOT NULL,
	[sequence_id] [int] NOT NULL,
	[trx_type] [smallint] NOT NULL,
	[apply_to_num] [varchar](16) NOT NULL,
	[apply_trx_type] [smallint] NOT NULL,
	[customer_code] [varchar](8) NOT NULL,
	[date_aging] [int] NOT NULL,
	[amt_applied] [float] NOT NULL,
	[amt_disc_taken] [float] NOT NULL,
	[wr_off_flag] [smallint] NOT NULL,
	[amt_max_wr_off] [float] NOT NULL,
	[void_flag] [smallint] NOT NULL,
	[line_desc] [varchar](40) NOT NULL,
	[sub_apply_num] [varchar](16) NOT NULL,
	[sub_apply_type] [smallint] NOT NULL,
	[amt_tot_chg] [float] NOT NULL,
	[amt_paid_to_date] [float] NOT NULL,
	[terms_code] [varchar](8) NOT NULL,
	[posting_code] [varchar](8) NOT NULL,
	[date_doc] [int] NOT NULL,
	[amt_inv] [float] NOT NULL,
	[gain_home] [float] NOT NULL,
	[gain_oper] [float] NOT NULL,
	[inv_amt_applied] [float] NOT NULL,
	[inv_amt_disc_taken] [float] NOT NULL,
	[inv_amt_max_wr_off] [float] NOT NULL,
	[inv_cur_code] [varchar](8) NOT NULL,
	[writeoff_code] [varchar](8) NULL DEFAULT (''),
	[writeoff_amount] [float] NULL DEFAULT ((0)),
	[cross_rate] [float] NULL,
	[org_id] [varchar](30) NULL,
	[chargeback] [smallint] NULL DEFAULT ((0)),
	[chargeref] [varchar](16) NULL,
	[chargeamt] [float] NULL DEFAULT ((0.0)),
	[cb_reason_code] [varchar](8) NULL,
	[cb_responsibility_code] [varchar](8) NULL,
	[cb_store_number] [varchar](16) NULL,
	[cb_reason_desc] [varchar](40) NULL,
	[cb_nat_cur_code] [varchar](8) NULL,
	[cb_credit_memo] [smallint] NULL DEFAULT ((0) ),
	[parent_cust]	[varchar] (8) ,
	[SettleNum] [varchar] (16),
	[SourceType] [smallint] ,
	[PytTrx] [varchar] (16),
	[RowID]	[Int] Identity(1,1)
)

CREATE TABLE #arinpstlhdr_hdr(
	[settlement_ctrl_num] [varchar](16) NOT NULL,
	[description] [varchar](40) NOT NULL,
	[hold_flag] [smallint] NOT NULL,
	[posted_flag] [smallint] NOT NULL,
	[date_entered] [int] NOT NULL,
	[date_applied] [int] NOT NULL,
	[user_id] [smallint] NOT NULL,
	[process_group_num] [varchar](16) NULL,
	[doc_count_expected] [int] NOT NULL,
	[doc_count_entered] [int] NOT NULL,
	[doc_sum_expected] [float] NOT NULL,
	[doc_sum_entered] [float] NOT NULL,
	[cr_total_home] [float] NOT NULL,
	[cr_total_oper] [float] NOT NULL,
	[oa_cr_total_home] [float] NOT NULL,
	[oa_cr_total_oper] [float] NOT NULL,
	[cm_total_home] [float] NOT NULL,
	[cm_total_oper] [float] NOT NULL,
	[inv_total_home] [float] NOT NULL,
	[inv_total_oper] [float] NOT NULL,
	[disc_total_home] [float] NOT NULL,
	[disc_total_oper] [float] NOT NULL,
	[wroff_total_home] [float] NOT NULL,
	[wroff_total_oper] [float] NOT NULL,
	[onacct_total_home] [float] NOT NULL,
	[onacct_total_oper] [float] NOT NULL,
	[gain_total_home] [float] NOT NULL,
	[gain_total_oper] [float] NOT NULL,
	[loss_total_home] [float] NOT NULL,
	[loss_total_oper] [float] NOT NULL,
	[customer_code] [varchar](8) NOT NULL,
	[nat_cur_code] [varchar](8) NOT NULL,
	[batch_code] [varchar](16) NULL,
	[rate_type_home] [varchar](8) NOT NULL,
	[rate_home] [float] NOT NULL,
	[rate_type_oper] [varchar](8) NOT NULL,
	[rate_oper] [float] NOT NULL,
	[inv_amt_nat] [float] NOT NULL,
	[amt_doc_nat] [float] NOT NULL,
	[amt_dist_nat] [float] NOT NULL,
	[amt_on_acct] [float] NOT NULL,
	[settle_flag] [smallint] NOT NULL,
	[org_id] [varchar](30) NULL
)

CREATE TABLE #arinpstlhdr_hdr1(
	[settlement_ctrl_num] [varchar](16) NOT NULL,
	[description] [varchar](40) NOT NULL,
	[hold_flag] [smallint] NOT NULL,
	[posted_flag] [smallint] NOT NULL,
	[date_entered] [int] NOT NULL,
	[date_applied] [int] NOT NULL,
	[user_id] [smallint] NOT NULL,
	[process_group_num] [varchar](16) NULL,
	[doc_count_expected] [int] NOT NULL,
	[doc_count_entered] [int] NOT NULL,
	[doc_sum_expected] [float] NOT NULL,
	[doc_sum_entered] [float] NOT NULL,
	[cr_total_home] [float] NOT NULL,
	[cr_total_oper] [float] NOT NULL,
	[oa_cr_total_home] [float] NOT NULL,
	[oa_cr_total_oper] [float] NOT NULL,
	[cm_total_home] [float] NOT NULL,
	[cm_total_oper] [float] NOT NULL,
	[inv_total_home] [float] NOT NULL,
	[inv_total_oper] [float] NOT NULL,
	[disc_total_home] [float] NOT NULL,
	[disc_total_oper] [float] NOT NULL,
	[wroff_total_home] [float] NOT NULL,
	[wroff_total_oper] [float] NOT NULL,
	[onacct_total_home] [float] NOT NULL,
	[onacct_total_oper] [float] NOT NULL,
	[gain_total_home] [float] NOT NULL,
	[gain_total_oper] [float] NOT NULL,
	[loss_total_home] [float] NOT NULL,
	[loss_total_oper] [float] NOT NULL,
	[customer_code] [varchar](8) NOT NULL,
	[nat_cur_code] [varchar](8) NOT NULL,
	[batch_code] [varchar](16) NULL,
	[rate_type_home] [varchar](8) NOT NULL,
	[rate_home] [float] NOT NULL,
	[rate_type_oper] [varchar](8) NOT NULL,
	[rate_oper] [float] NOT NULL,
	[inv_amt_nat] [float] NOT NULL,
	[amt_doc_nat] [float] NOT NULL,
	[amt_dist_nat] [float] NOT NULL,
	[amt_on_acct] [float] NOT NULL,
	[settle_flag] [smallint] NOT NULL,
	[org_id] [varchar](30) NULL
)


declare @UserID int		-- GEP 1/28/2012
declare @PytNum varchar(16), @NewStlNum varchar(16)
declare @num_type smallint,@masked varchar(35),	@num int 

select
	ParentRecID,
	CustCode,
	DocNum,
	abs(DocBal) DocBal
into #PytHeaders	
from ESC_CashAppDet
where ParentRecID = @ParRecID
and DocType = 'PYT'


-- select * from #PytHeaders	


-- GEP 1/28/2012
select @UserID = user_id from glusers_vw where user_name = @UserName
if @UserID is null
begin
	select @UserID = 1
end

select @num_type = 2015

exec 	ARGetNextControl_SP 	@num_type, 
								@masked output, 
								@num OUTPUT, 
								0

select @NewStlNum = left(@masked,16)


insert into #arinppdt_det
select 
	'',														-- [trx_ctrl_num] [varchar](16) NOT NULL,
	d.PytDoc,												-- [doc_ctrl_num] [varchar](16) NOT NULL,
	0,														-- [sequence_id] [int] NOT NULL,
	2111,													-- [trx_type] [smallint] NOT NULL,
	d.InvDoc,												-- [apply_to_num] [varchar](16) NOT NULL,
	2031,													-- [apply_trx_type] [smallint] NOT NULL,
	x.customer_code,										-- [customer_code] [varchar](8) NOT NULL,
	x.date_aging,												-- [date_aging] [int] NOT NULL,
	abs(d.PytApp),											-- [amt_applied] [float] NOT NULL,
	0,														-- [amt_disc_taken] [float] NOT NULL,
	0,														-- [wr_off_flag] [smallint] NOT NULL,
	0,														-- [amt_max_wr_off] [float] NOT NULL,
	0,														-- [void_flag] [smallint] NOT NULL,
	'',														-- [line_desc] [varchar](40) NOT NULL,
	'',														-- [sub_apply_num] [varchar](16) NOT NULL,
	0,														-- [sub_apply_type] [smallint] NOT NULL,
	x.amt_tot_chg,											-- [amt_tot_chg] [float] NOT NULL,
	x.amt_paid_to_date,										-- [amt_paid_to_date] [float] NOT NULL,
	x.terms_code,											-- [terms_code] [varchar](8) NOT NULL,
	'',														-- [posting_code] [varchar](8) NOT NULL,
	x.date_doc,												-- [date_doc] [int] NOT NULL,
	x.amt_net,												-- [amt_inv] [float] NOT NULL,
	0,														-- [gain_home] [float] NOT NULL,
	0,														-- [gain_oper] [float] NOT NULL,
	abs(d.PytApp),											-- [inv_amt_applied] [float] NOT NULL,
	0,														-- [inv_amt_disc_taken] [float] NOT NULL,
	0,														-- [inv_amt_max_wr_off] [float] NOT NULL,
	x.nat_cur_code,											-- [inv_cur_code] [varchar](8) NOT NULL,
	NULL,													-- [writeoff_code] [varchar](8) NULL DEFAULT (''),
	0,														-- [writeoff_amount] [float] NULL DEFAULT ((0)),
	1,													-- [cross_rate] [float] NULL,
	x.org_id,												-- [org_id] [varchar](30) NULL,
	NULL,													-- [chargeback] [smallint] NULL DEFAULT ((0)),
	NULL,													-- [chargeref] [varchar](16) NULL,
	NULL,													-- [chargeamt] [float] NULL DEFAULT ((0.0)),
	NULL,													-- [cb_reason_code] [varchar](8) NULL,
	NULL,													-- [cb_responsibility_code] [varchar](8) NULL,
	NULL,													-- [cb_store_number] [varchar](16) NULL,
	NULL,													-- [cb_reason_desc] [varchar](40) NULL,
	NULL,													-- [cb_nat_cur_code] [varchar](8) NULL,
	NULL,													-- [cb_credit_memo] [smallint] NULL DEFAULT ((0)
	'',														-- parent_cust
	@NewStlNum,												-- SettleNum
	d.ApplyType,											-- SourceType
	d.PytTrx												-- PytTrx
from	ESC_CashAppInvDet d (NOLOCK) , artrx_all x (NOLOCK)
where	d.ParentRecID	= @ParRecID
and		d.InvDoc		= x.doc_ctrl_num
and		d.ApplyType		= 1
and		x.trx_type		= 2031
Order by d.PytDoc,d.InvDoc


update	pd
set		pd.parent_cust	=  cd.CustCode
from	#arinppdt_det pd, ESC_CashAppDet cd
where	pd.PytTrx		= cd.TrxNum
and		cd.DocType		= 'PYT'
and		cd.ParentRecID  = @ParRecID

-- Next lets assign the trx numbers for settlements before adding the Check payment.
declare @Cust varchar(8), @Doc varchar(16),@next_tcn	varchar(16)

declare GetPytNumbers cursor
for
select distinct customer_code,doc_ctrl_num
from #arinppdt_det
order by customer_code,doc_ctrl_num

open GetPytNumbers

fetch next from GetPytNumbers
into @Cust, @Doc

while @@fetch_status = 0
begin


	exec arnewnum_sp	
			2111,						-- @trx_type	smallint,
			@next_tcn  OUTPUT
					
	update 	#arinppdt_det
	set		trx_ctrl_num = 	@next_tcn
	where 	customer_code = @Cust
	and		doc_ctrl_num = @Doc
	
					
	fetch next from GetPytNumbers
	into @Cust, @Doc
end 
close GetPytNumbers
deallocate GetPytNumbers

declare @ChkNum varchar(16), @ChkDate int, @ChkAmt float, @PytCode varchar(8), @PayerCust varchar(8)

select	@PayerCust	= PayerCustCode,
		@ChkNum		= CheckNum, 
		@ChkDate	= CheckDate, 
		@ChkAmt		= CheckAmt,
		@PytCode	= PytCode
from ESC_CashAppHdr where ParentRecID = @ParRecID

select @next_tcn = ''

if @ChkNum != ''
begin

	-- OK now lets get the check info and populate the remaining details.
	exec arnewnum_sp	
			2111,						-- @trx_type	smallint,
			@next_tcn  OUTPUT


	select @num_type = 2015
	select @NewStlNum = ''

	exec 	ARGetNextControl_SP 	@num_type, 
									@masked output, 
									@num OUTPUT, 
									0

	select @NewStlNum = left(@masked,16)

	insert into #arinppdt_det
	select 
		@next_tcn,												-- [trx_ctrl_num] [varchar](16) NOT NULL,
		@ChkNum,												-- [doc_ctrl_num] [varchar](16) NOT NULL,
		0,														-- [sequence_id] [int] NOT NULL,
		2111,													-- [trx_type] [smallint] NOT NULL,
		d.InvDoc,												-- [apply_to_num] [varchar](16) NOT NULL,
		2031,													-- [apply_trx_type] [smallint] NOT NULL,
		x.customer_code,										-- [customer_code] [varchar](8) NOT NULL,
		x.date_aging,											-- [date_aging] [int] NOT NULL,
		abs(d.PytApp),											-- [amt_applied] [float] NOT NULL,
		0,														-- [amt_disc_taken] [float] NOT NULL,
		0,														-- [wr_off_flag] [smallint] NOT NULL,
		0,														-- [amt_max_wr_off] [float] NOT NULL,
		0,														-- [void_flag] [smallint] NOT NULL,
		'',														-- [line_desc] [varchar](40) NOT NULL,
		'',														-- [sub_apply_num] [varchar](16) NOT NULL,
		0,														-- [sub_apply_type] [smallint] NOT NULL,
		x.amt_tot_chg,											-- [amt_tot_chg] [float] NOT NULL,
		x.amt_paid_to_date,										-- [amt_paid_to_date] [float] NOT NULL,
		'',														-- [terms_code] [varchar](8) NOT NULL,
		'',														-- [posting_code] [varchar](8) NOT NULL,
		x.date_doc,												-- [date_doc] [int] NOT NULL,
		x.amt_net,												-- [amt_inv] [float] NOT NULL,
		0,														-- [gain_home] [float] NOT NULL,
		0,														-- [gain_oper] [float] NOT NULL,
		abs(d.PytApp),											-- [inv_amt_applied] [float] NOT NULL,
		0,														-- [inv_amt_disc_taken] [float] NOT NULL,
		0,														-- [inv_amt_max_wr_off] [float] NOT NULL,
		x.nat_cur_code,											-- [inv_cur_code] [varchar](8) NOT NULL,
		NULL,													-- [writeoff_code] [varchar](8) NULL DEFAULT (''),
		0,														-- [writeoff_amount] [float] NULL DEFAULT ((0)),
		NULL,													-- [cross_rate] [float] NULL,
		x.org_id,												-- [org_id] [varchar](30) NULL,
		0,														-- [chargeback] [smallint] NULL DEFAULT ((0)),
		'',														-- [chargeref] [varchar](16) NULL,
		0,														-- [chargeamt] [float] NULL DEFAULT ((0.0)),
		'',														-- [cb_reason_code] [varchar](8) NULL,
		'',														-- [cb_responsibility_code] [varchar](8) NULL,
		'',														-- [cb_store_number] [varchar](16) NULL,
		'',														-- [cb_reason_desc] [varchar](40) NULL,
		NULL,													-- [cb_nat_cur_code] [varchar](8) NULL,
		NULL,													-- [cb_credit_memo] [smallint] NULL DEFAULT ((0)
		@PayerCust,												-- parent_cust
		@NewStlNum,												-- SettleNum
		d.ApplyType,											-- SourceType
		d.PytTrx												-- PytTrx

	from	ESC_CashAppDet i (NOLOCK),ESC_CashAppInvDet d (NOLOCK), artrx_all x (NOLOCK)
	where	i.ParentRecID	= d.ParentRecID
	and		i.SeqID			= d.SeqID
	and		i.TrxNum		= x.trx_ctrl_num
	and		i.ParentRecID	= @ParRecID
	and		d.ApplyType		= 2
	and		i.DocType		= 'INV'
	and		x.trx_type		= 2031

end


select trx_ctrl_num Trx,min(RowID) SeqID
into #tempSeq
from #arinppdt_det
group by trx_ctrl_num

update	#arinppdt_det
set		sequence_id = RowID - SeqID+1
from #tempSeq
where	trx_ctrl_num = Trx

drop table #tempSeq


-- Update writeoff codes
update	d
set		d.writeoff_code = c.writeoff_code
from	#arinppdt_det d, arcust c (NOLOCK)
where	d.parent_cust = c.customer_code

			
insert into #arinppyt_hdr
select 
	trx_ctrl_num,								-- [trx_ctrl_num] [varchar](16) NOT NULL,
	doc_ctrl_num,								-- [doc_ctrl_num] [varchar](16) NOT NULL,
	'CashApp - Check Portion',					-- [trx_desc] [varchar](40) NOT NULL,
	'',											-- [batch_code] [varchar](16) NOT NULL,
	2111,										-- [trx_type] [smallint] NOT NULL,
	0,											-- [non_ar_flag] [smallint] NOT NULL,
	'',											-- [non_ar_doc_num] [varchar](16) NOT NULL,
	'',											-- [gl_acct_code] [varchar](32) NOT NULL,
	722815+ datediff(dd,'1/1/80',getdate()),	-- [date_entered] [int] NOT NULL,
	722815+ datediff(dd,'1/1/80',getdate()),	-- [date_applied] [int] NOT NULL,
	0,											-- [date_doc] [int] NOT NULL,
	parent_cust,								-- [customer_code] [varchar](8) NOT NULL,
	'',											-- [payment_code] [varchar](8) NOT NULL,
	1,											-- [payment_type] [smallint] NOT NULL,		******* Set this after header creation.
	case 
		when trx_ctrl_num = @next_tcn then @ChkAmt
		else 0
	end,										-- [amt_payment] [float] NOT NULL,
	0,											-- [amt_on_acct] [float] NOT NULL,
	'',											-- [prompt1_inp] [varchar](30) NOT NULL,
	'',											-- [prompt2_inp] [varchar](30) NOT NULL,
	'',											-- [prompt3_inp] [varchar](30) NOT NULL,
	'',											-- [prompt4_inp] [varchar](30) NOT NULL,
	'',											-- [deposit_num] [varchar](16) NOT NULL,
	0,											-- [bal_fwd_flag] [smallint] NOT NULL,
	0,											-- [printed_flag] [smallint] NOT NULL,
	0,											-- [posted_flag] [smallint] NOT NULL,
	0,											-- [hold_flag] [smallint] NOT NULL,
	0,											-- [wr_off_flag] [smallint] NOT NULL,
	0,											-- [on_acct_flag] [smallint] NOT NULL,
	@UserID,									-- [user_id] [smallint] NOT NULL,
	0,											-- [max_wr_off] [float] NOT NULL,
	0,											-- [days_past_due] [int] NOT NULL,
	0,											-- [void_type] [smallint] NOT NULL,
	'',											-- [cash_acct_code] [varchar](32) NOT NULL,
	NULL,										-- [origin_module_flag] [smallint] NULL,
	NULL,										-- [process_group_num] [varchar](16) NULL,
	NULL,										-- [source_trx_ctrl_num] [varchar](16) NULL,
	NULL,										-- [source_trx_type] [smallint] NULL,
	'USD',										-- [nat_cur_code] [varchar](8) NOT NULL,
	'SELL',										-- [rate_type_home] [varchar](8) NOT NULL,
	'SELL',										-- [rate_type_oper] [varchar](8) NOT NULL,
	1,											-- [rate_home] [float] NOT NULL,
	1,											-- [rate_oper] [float] NOT NULL,
	0,											-- [amt_discount] [float] NULL,
	'',											-- [reference_code] [varchar](32) NULL,
	SettleNum,									-- [settlement_ctrl_num] [varchar](16) NULL,
	case 
		when trx_ctrl_num = @next_tcn then @ChkAmt
		else 0
	end,										-- [doc_amount] [float] NULL,
	org_id,										-- [org_id] [varchar](30) NULL
	parent_cust,								-- [parent_cust] [varchar](8) NULL
	SourceType									-- SourceType
from #arinppdt_det
where SourceType = 2
group by  trx_ctrl_num,
doc_ctrl_num,
parent_cust,
SettleNum,
org_id,
SourceType


			
insert into #arinppyt_hdr
select 
	trx_ctrl_num ,								-- [trx_ctrl_num] [varchar](16) NOT NULL,
	doc_ctrl_num,								-- [doc_ctrl_num] [varchar](16) NOT NULL,
	'CashApp - Settlement Portion',				-- [trx_desc] [varchar](40) NOT NULL,
	'',											-- [batch_code] [varchar](16) NOT NULL,
	2111,										-- [trx_type] [smallint] NOT NULL,
	0,											-- [non_ar_flag] [smallint] NOT NULL,
	'',											-- [non_ar_doc_num] [varchar](16) NOT NULL,
	'',											-- [gl_acct_code] [varchar](32) NOT NULL,
	722815+ datediff(dd,'1/1/80',getdate()),	-- [date_entered] [int] NOT NULL,
	722815+ datediff(dd,'1/1/80',getdate()),	-- [date_applied] [int] NOT NULL,
	0,											-- [date_doc] [int] NOT NULL,
	parent_cust,								-- [customer_code] [varchar](8) NOT NULL,
	'',											-- [payment_code] [varchar](8) NOT NULL,
	0,											-- [payment_type] [smallint] NOT NULL,		******* Set this after header creation.
	case 
		when trx_ctrl_num = @next_tcn then @ChkAmt
		else 0
	end,										-- [amt_payment] [float] NOT NULL,
	0,											-- [amt_on_acct] [float] NOT NULL,
	'',											-- [prompt1_inp] [varchar](30) NOT NULL,
	'',											-- [prompt2_inp] [varchar](30) NOT NULL,
	'',											-- [prompt3_inp] [varchar](30) NOT NULL,
	'',											-- [prompt4_inp] [varchar](30) NOT NULL,
	'',											-- [deposit_num] [varchar](16) NOT NULL,
	0,											-- [bal_fwd_flag] [smallint] NOT NULL,
	0,											-- [printed_flag] [smallint] NOT NULL,
	0,											-- [posted_flag] [smallint] NOT NULL,
	0,											-- [hold_flag] [smallint] NOT NULL,
	0,											-- [wr_off_flag] [smallint] NOT NULL,
	0,											-- [on_acct_flag] [smallint] NOT NULL,
	@UserID,									-- [user_id] [smallint] NOT NULL,
	0,											-- [max_wr_off] [float] NOT NULL,
	0,											-- [days_past_due] [int] NOT NULL,
	0,											-- [void_type] [smallint] NOT NULL,
	'',											-- [cash_acct_code] [varchar](32) NOT NULL,
	NULL,										-- [origin_module_flag] [smallint] NULL,
	NULL,										-- [process_group_num] [varchar](16) NULL,
	NULL,										-- [source_trx_ctrl_num] [varchar](16) NULL,
	NULL,										-- [source_trx_type] [smallint] NULL,
	'USD',										-- [nat_cur_code] [varchar](8) NOT NULL,
	'SELL',										-- [rate_type_home] [varchar](8) NOT NULL,
	'SELL',										-- [rate_type_oper] [varchar](8) NOT NULL,
	1,											-- [rate_home] [float] NOT NULL,
	1,											-- [rate_oper] [float] NOT NULL,
	0,											-- [amt_discount] [float] NULL,
	'',											-- [reference_code] [varchar](32) NULL,
	SettleNum,									-- [settlement_ctrl_num] [varchar](16) NULL,
	case 
		when trx_ctrl_num = @next_tcn then @ChkAmt
		else 0
	end,										-- [doc_amount] [float] NULL,
	org_id,										-- [org_id] [varchar](30) NULL
	parent_cust,								-- [parent_cust] [varchar](8) NULL
	SourceType									-- SourceType
from #arinppdt_det
where SourceType = 1
group by  trx_ctrl_num,
doc_ctrl_num,
customer_code,
SettleNum,
org_id,
parent_cust,
SourceType


update #arinppyt_hdr
set		amt_payment = DocBal,
		doc_amount = DocBal
from #PytHeaders
where	#arinppyt_hdr.doc_ctrl_num = #PytHeaders.DocNum
and		#arinppyt_hdr.customer_code = #PytHeaders.CustCode

drop table #PytHeaders

-- Now figure out the On Account amounts for each document.
-- Just see what has been applied for each document
select	trx_ctrl_num, sum(amt_applied) AmtApplied
into	#tempOA
from	#arinppdt_det
group by trx_ctrl_num

-- select * from #tempOA

-- And then just subtract it from the payment amount.
update	#arinppyt_hdr
set		#arinppyt_hdr.amt_on_acct = abs(convert(dec(20,2),#arinppyt_hdr.amt_payment - #tempOA.AmtApplied))
from	#tempOA
where	#arinppyt_hdr.trx_ctrl_num = #tempOA.trx_ctrl_num

drop table #tempOA

update	#arinppyt_hdr
set		on_acct_flag = 1 
where	amt_on_acct > 0.001 


update #arinppyt_hdr
set doc_amount = amt_payment - amt_on_acct
where on_acct_flag = 1 


-- Now set the payment type
update	h
set		h.payment_type = 
		case t.payment_type
			when 1	then 2		-- OACR
			when 3	then 4		-- OACM
			-- else 1				-- New Payment
		end,
		h.payment_code = 
		case t.payment_type
			when 1	then t.payment_code		-- OACR follows the original payment code
			when 3	then ''					-- OACM does not need payment code
			-- else	''						-- New Payment
		end,
		h.date_doc  = 
		case t.payment_type
			when 1	then t.date_doc			-- OACR follows the original payment code
			when 3	then t.date_doc			-- OACM does not need payment code
			-- else	0						-- New Payment
		end,
		h.cash_acct_code = t.cash_acct_code
				
from	#arinppyt_hdr h 
left outer join artrx_all t (NOLOCK) on  h.doc_ctrl_num = t.doc_ctrl_num  
		and		h.customer_code = t.customer_code
where 		t.trx_type = 2111
 

update	#arinppyt_hdr
set		date_doc = @ChkDate,
		date_applied = @ChkDate,		-- Rev 2
		payment_code = @PytCode
where	trx_ctrl_num = @next_tcn

update	#arinppyt_hdr
set		cash_acct_code = asset_acct_code
from	arpymeth
where	#arinppyt_hdr.payment_code = arpymeth.payment_code
and		trx_ctrl_num = @next_tcn


-- Put Cash Receipts on hold if the CR already exists.
update	h
set		h.hold_flag = 1
from	#arinppyt_hdr h
inner join artrx_all t (NOLOCK) on  h.doc_ctrl_num = t.doc_ctrl_num  
		and		h.customer_code = t.customer_code
where	h.payment_type = 1

update	h
set		h.hold_flag = 1
from	#arinppyt_hdr h
inner join arinppyt_all t (NOLOCK) on  h.doc_ctrl_num = t.doc_ctrl_num  
		and		h.customer_code = t.customer_code
where	h.payment_type = 1

-- Now delete the cash receipt where there are no details
delete #arinppyt_hdr
where trx_ctrl_num not in (select distinct trx_ctrl_num from #arinppdt_det)







/*
select trx_ctrl_num, sum(amt_applied) Applied, sum(amt_inv) AmtInv, sum(gain_home) GHome,
				sum(gain_oper) GOper
into #StlDetail
from #arinppdt_det
group by trx_ctrl_num
*/


insert into #arinpstlhdr_hdr1
select 
	h.settlement_ctrl_num,								-- [settlement_ctrl_num] [varchar](16) NOT NULL,
	'CashApp - Settlement',								-- [description] [varchar](40) NOT NULL,
	0,													-- [hold_flag] [smallint] NOT NULL,
	0,													-- [posted_flag] [smallint] NOT NULL,
	h.date_entered,										-- [date_entered] [int] NOT NULL,
	h.date_applied,										-- [date_applied] [int] NOT NULL,
	h.user_id,											-- [user_id] [smallint] NOT NULL,
	NULL,												-- [process_group_num] [varchar](16) NULL,
	0,													-- [doc_count_expected] [int] NOT NULL,
	0,													-- [doc_count_entered] [int] NOT NULL,
	0,													-- [doc_sum_expected] [float] NOT NULL,
	sum(h.amt_payment-h.amt_on_acct),					-- [doc_sum_entered] [float] NOT NULL,
	case 
		when h.payment_type = 1 then sum(h.amt_payment-h.amt_on_acct)
		when h.payment_type = 2 then sum(h.amt_payment-h.amt_on_acct)
		else 0
	end,												-- [cr_total_home] [float] NOT NULL,
	case 
		when h.payment_type = 1 then sum(h.amt_payment-h.amt_on_acct)
		when h.payment_type = 2 then sum(h.amt_payment-h.amt_on_acct)
		else 0
	end,												-- [cr_total_oper] [float] NOT NULL,
	case 
		when h.payment_type = 2 then sum(h.amt_payment-h.amt_on_acct)
		else 0
	end,												-- [oa_cr_total_home] [float] NOT NULL,	case h.payment_type
	case 
		when h.payment_type = 2 then sum(h.amt_payment-h.amt_on_acct)
		else 0
	end,												-- [oa_cr_total_oper] [float] NOT NULL,
	case 
		when h.payment_type = 4 then sum(h.amt_payment-h.amt_on_acct)
		else 0
	end,												-- [cm_total_home] [float] NOT NULL,
	case 
		when h.payment_type = 4 then sum(h.amt_payment-h.amt_on_acct)
		else 0
	end,												-- [cm_total_oper] [float] NOT NULL,
	sum(h.amt_payment-h.amt_on_acct),					-- [inv_total_home] [float] NOT NULL,
	sum(h.amt_payment-h.amt_on_acct),					-- [inv_total_oper] [float] NOT NULL,
	0,													-- [disc_total_home] [float] NOT NULL,
	0,													-- [disc_total_oper] [float] NOT NULL,
	0,													-- [wroff_total_home] [float] NOT NULL,
	0,													-- [wroff_total_oper] [float] NOT NULL,
	sum(h.amt_on_acct),									-- [onacct_total_home] [float] NOT NULL,
	sum(h.amt_on_acct),									-- [onacct_total_oper] [float] NOT NULL,
	0,													-- [gain_total_home] [float] NOT NULL,
	0,													-- [gain_total_oper] [float] NOT NULL,
	0,													-- [loss_total_home] [float] NOT NULL,
	0,													-- [loss_total_oper] [float] NOT NULL,
	@ParRecID,											-- [customer_code] [varchar](8) NOT NULL,
	h.nat_cur_code,										-- [nat_cur_code] [varchar](8) NOT NULL,
	'',													-- [batch_code] [varchar](16) NULL,
	h.rate_type_home,									-- [rate_type_home] [varchar](8) NOT NULL,
	h.rate_home,										-- [rate_home] [float] NOT NULL,
	h.rate_type_oper,									-- [rate_type_oper] [varchar](8) NOT NULL,
	h.rate_oper,										-- [rate_oper] [float] NOT NULL,
	sum(h.amt_payment-h.amt_on_acct),					-- [inv_amt_nat] [float] NOT NULL,
	sum(h.amt_payment),									-- [amt_doc_nat] [float] NOT NULL,
	case 
		when h.payment_type = 1 then sum(h.amt_payment-h.amt_on_acct)
		else 0
	end,												-- [amt_dist_nat] [float] NOT NULL,
	case 
		when h.payment_type = 1 then sum(h.amt_on_acct)
		else sum(h.amt_on_acct)
	end,												-- [amt_on_acct] [float] NOT NULL,
	case 
		when h.payment_type = 1 then 0
		else 1
	end,												-- [settle_flag] [smallint] NOT NULL,
	h.org_id											-- [org_id] [varchar](30) NULL
from #arinppyt_hdr h
group by 
	h.settlement_ctrl_num,
	h.date_entered,
	h.date_applied,										-- [date_applied] [int] NOT NULL,
	h.user_id,											-- [user_id] [smallint] NOT NULL,
	h.payment_type,
	h.parent_cust,										-- [customer_code] [varchar](8) NOT NULL,
	h.nat_cur_code,										-- [nat_cur_code] [varchar](8) NOT NULL,
	h.rate_type_home,									-- [rate_type_home] [varchar](8) NOT NULL,
	h.rate_home,										-- [rate_home] [float] NOT NULL,
	h.rate_type_oper,									-- [rate_type_oper] [varchar](8) NOT NULL,
	h.rate_oper,										-- [rate_oper] [float] NOT NULL,
	h.org_id											-- [org_id] [varchar](30) NULL


insert into #arinpstlhdr_hdr
select 
	settlement_ctrl_num,								-- [settlement_ctrl_num] [varchar](16) NOT NULL,
	description,										-- [description] [varchar](40) NOT NULL,
	0,													-- [hold_flag] [smallint] NOT NULL,
	0,													-- [posted_flag] [smallint] NOT NULL,
	date_entered,										-- [date_entered] [int] NOT NULL,
	date_applied,										-- [date_applied] [int] NOT NULL,
	user_id,											-- [user_id] [smallint] NOT NULL,
	'',													-- [process_group_num] [varchar](16) NULL,
	sum(doc_count_expected),							-- [doc_count_expected] [int] NOT NULL,
	sum(doc_count_entered),								-- [doc_count_entered] [int] NOT NULL,
	sum(doc_sum_expected),								-- [doc_sum_expected] [float] NOT NULL,
	sum(doc_sum_entered),								-- [doc_sum_entered] [float] NOT NULL,
	sum(cr_total_home),									-- [cr_total_home] [float] NOT NULL,
	sum(cr_total_oper),									-- [cr_total_oper] [float] NOT NULL,
	sum(oa_cr_total_home),								-- [oa_cr_total_home] [float] NOT NULL,
	sum(oa_cr_total_oper),								-- [oa_cr_total_oper] [float] NOT NULL,
	sum(cm_total_home),									-- [cm_total_home] [float] NOT NULL,
	sum(cm_total_oper),									-- [cm_total_oper] [float] NOT NULL,
	sum(inv_total_home),								-- [inv_total_home] [float] NOT NULL,
	sum(inv_total_oper),								-- [inv_total_oper] [float] NOT NULL,
	sum(disc_total_home),								-- [disc_total_home] [float] NOT NULL,
	sum(disc_total_oper),								-- [disc_total_oper] [float] NOT NULL,
	sum(wroff_total_home),								-- [wroff_total_home] [float] NOT NULL,
	sum(wroff_total_oper),								-- [wroff_total_oper] [float] NOT NULL,
	sum(onacct_total_home),								-- [onacct_total_home] [float] NOT NULL,
	sum(onacct_total_oper),								-- [onacct_total_oper] [float] NOT NULL,
	sum(gain_total_home),								-- [gain_total_home] [float] NOT NULL,
	sum(gain_total_oper),								-- [gain_total_oper] [float] NOT NULL,
	sum(loss_total_home),								-- [loss_total_home] [float] NOT NULL,
	sum(loss_total_oper),								-- [loss_total_oper] [float] NOT NULL,
	customer_code,										-- [customer_code] [varchar](8) NOT NULL,
	nat_cur_code,										-- [nat_cur_code] [varchar](8) NOT NULL,
	'',													-- [batch_code] [varchar](16) NULL,
	rate_type_home,										-- [rate_type_home] [varchar](8) NOT NULL,
	1,													-- [rate_home] [float] NOT NULL,
	rate_type_oper,										-- [rate_type_oper] [varchar](8) NOT NULL,
	1,													-- [rate_oper] [float] NOT NULL,
	sum(inv_amt_nat),									-- [inv_amt_nat] [float] NOT NULL,
	sum(amt_doc_nat),									-- [amt_doc_nat] [float] NOT NULL,
	sum(amt_dist_nat),									-- [amt_dist_nat] [float] NOT NULL,
	sum(amt_on_acct),									-- [amt_on_acct] [float] NOT NULL,
	settle_flag,										-- [settle_flag] [smallint] NOT NULL,
	org_id												-- [org_id] [varchar](30) NULL
from #arinpstlhdr_hdr1
group by 	
	settlement_ctrl_num,								-- [settlement_ctrl_num] [varchar](16) NOT NULL,
	description,										-- [description] [varchar](40) NOT NULL,
	date_entered,										-- [date_entered] [int] NOT NULL,
	date_applied,										-- [date_applied] [int] NOT NULL,
	user_id,											-- [user_id] [smallint] NOT NULL,
	customer_code,										-- [customer_code] [varchar](8) NOT NULL,
	nat_cur_code,										-- [nat_cur_code] [varchar](8) NOT NULL,
	rate_type_home,										-- [rate_type_home] [varchar](8) NOT NULL,
	rate_type_oper,										-- [rate_type_oper] [varchar](8) NOT NULL,
	settle_flag,										-- [settle_flag] [smallint] NOT NULL,
	org_id												-- [org_id] [varchar](30) NULL
	
-- At this point the data is staged.
-- we need to populate the static tables
-- Also update the ESC_ProcessInvoices table as processed.



if @final = 0
begin
--	select * from #arinpstlhdr_hdr
--	select * from #arinppyt_hdr
--	order by trx_ctrl_num

	select * from #arinppdt_det
	order by trx_ctrl_num,sequence_id
end

declare @err_flag smallint
select  @err_flag = 0 

if @final = 1
begin

	begin tran push_data

	insert into arinppyt_all
	select 
	null,trx_ctrl_num,doc_ctrl_num,trx_desc,batch_code,trx_type,non_ar_flag,non_ar_doc_num,
	gl_acct_code,date_entered,date_applied,date_doc,customer_code,payment_code,payment_type,
	amt_payment,amt_on_acct,prompt1_inp,prompt2_inp,prompt3_inp,prompt4_inp,deposit_num,
	bal_fwd_flag,printed_flag,posted_flag,hold_flag,wr_off_flag,on_acct_flag,user_id,max_wr_off,
	days_past_due,void_type,cash_acct_code,origin_module_flag,process_group_num,
	source_trx_ctrl_num,source_trx_type,nat_cur_code,rate_type_home,rate_type_oper,rate_home,
	rate_oper,amt_discount,reference_code,settlement_ctrl_num,doc_amount,org_id
	from #arinppyt_hdr

	if @@error <> 0 
	begin
		rollback tran push_data
		return
	end



	insert into arinppdt
	select 
	null,trx_ctrl_num,doc_ctrl_num,sequence_id,trx_type,apply_to_num,apply_trx_type,
	customer_code,date_aging,amt_applied,amt_disc_taken,wr_off_flag,amt_max_wr_off,void_flag,
	line_desc,sub_apply_num,sub_apply_type,amt_tot_chg,amt_paid_to_date,terms_code,posting_code,
	date_doc,amt_inv,gain_home,gain_oper,inv_amt_applied,inv_amt_disc_taken,inv_amt_max_wr_off,
	inv_cur_code,writeoff_code,writeoff_amount,cross_rate,org_id,chargeback,chargeref,cb_store_number,
	cb_reason_code,cb_responsibility_code,cb_reason_desc,chargeamt
	from #arinppdt_det
	if @@error <> 0 
	begin
		rollback tran push_data
		return
	end



	insert into arinpstlhdr_all
	select 
	null,settlement_ctrl_num,description,hold_flag,posted_flag,date_entered,date_applied,
	user_id,process_group_num,doc_count_expected,doc_count_entered,doc_sum_expected,
	doc_sum_entered,cr_total_home,cr_total_oper,oa_cr_total_home,oa_cr_total_oper,cm_total_home,
	cm_total_oper,inv_total_home,inv_total_oper,disc_total_home,disc_total_oper,
	wroff_total_home,wroff_total_oper,onacct_total_home,onacct_total_oper,gain_total_home,
	gain_total_oper,loss_total_home,loss_total_oper,customer_code,nat_cur_code,batch_code,
	rate_type_home,rate_home,rate_type_oper,rate_oper,inv_amt_nat,amt_doc_nat,amt_dist_nat,
	amt_on_acct,settle_flag,org_id
	from #arinpstlhdr_hdr
	if @@error <> 0 
	begin
		rollback tran push_data
		return
	end

		
	delete ESC_CashAppHdr
	where ParentRecID = @ParRecID
	if @@error <> 0 
	begin
		rollback tran push_data
		return
	end
	
	delete ESC_CashAppDet
	where ParentRecID = @ParRecID
	if @@error <> 0 
	begin
		rollback tran push_data
		return
	end

	delete ESC_CashAppInvDet
	where ParentRecID = @ParRecID
	if @@error <> 0 
	begin
		rollback tran push_data
		return
	end
		


	commit tran push_data


select @MsgOut = 0 
			 

end


GO
GRANT EXECUTE ON  [dbo].[ESC_ProcessCVOPayments_sp] TO [public]
GO
