SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- AR By Cust Credits with Applied Debits
-- Author = E.L.

--declare @customer_code nvarchar(15) 
--DECLARE @DateFrom datetime
--	declare @date1 datetime
--		declare @JDateFrom int
--DECLARE @DateTo datetime
--	declare @date2 datetime
--		declare @JDateTo int
--
--SET @customer_code = '000525'
--SET @DateFrom = '1/1/2012'
--	SET @DateTo = '6/30/2012 23:59:59'
--
--SET @date1=@DateFrom
--	select @JDateFrom = datediff(day,'1/1/1950',convert(datetime,
--	  convert(varchar( 8), (year(@date1) * 10000) + (month(@date1) * 100) + day(@date1)))  ) + 711858
--SET @date2=@DateTo
--	select @JDateTo = datediff(day,'1/1/1950',convert(datetime,
--	  convert(varchar( 8), (year(@date2) * 10000) + (month(@date2) * 100) + day(@date2)))  ) + 711858
--
CREATE view [dbo].[cvo_ar_credit_AppliedDebit_vw] as
select 
	t2.address_name,	
	t2.customer_code, 	
	t1.doc_ctrl_num, 	 
	t1.trx_ctrl_num, 
	(select Amt_net from artrx where trx_ctrl_num = t1.trx_ctrl_num) as 'Credit Amount',
--	convert(varchar,dateadd(day,(t3.date_doc-711858),'1/1/1950'),101) as 'Date Applied',
	t3.date_doc,
	invoice_no=t1.apply_to_num,	
--	convert(varchar,dateadd(day,((select date_entered from artrx where doc_ctrl_num = t1.apply_to_num)-711858),'1/1/1950'),101) as 'Inv Date',
	(select date_entered from artrx where doc_ctrl_num = t1.apply_to_num) as 'InvDate',
	(select date_due from artrx where doc_ctrl_num = t1.apply_to_num) as 'Stmt Due Date',
	(select Customer_code from artrx where doc_ctrl_num = t1.apply_to_num) as 'CustomerCode',
	(select CASE WHEN trx_type = '2031' THEN (amt_net) ELSE (amt_net) * -1  END  from artrx where doc_ctrl_num = t1.apply_to_num) as 'Inv Amount',
	payment_amt=t1.amt_applied	
 from 
-- 	artrxpdt t1, armaster t2, artrx_cm_vw t3, artrx_inv_vw t4
	artrxpdt t1 (nolock) 
	inner join artrx_cm_vw (nolock) t3 on t3.doc_ctrl_num = t1.doc_ctrl_num and t3.trx_ctrl_num = t1.trx_ctrl_num
	inner join artrx_inv_vw t4 (nolock) on t4.doc_ctrl_num = t1.apply_to_num
	inner join armaster (nolock) t2 on t2.customer_code = t3.customer_code
 where 
	 --t2.customer_code = t3.customer_code
	 --and t2.address_type = 0
	t2.address_type = 0
	and t1.trx_type in (2111) 
	--and t1.doc_ctrl_num = t3.doc_ctrl_num
	--and t1.trx_ctrl_num = t3.trx_ctrl_num
	--and t1.apply_to_num = t4.doc_ctrl_num
	--and t3.payment_type in (3,4)
--and t2.customer_code = (@customer_code)
--and t3.date_doc between @JDateFrom and @JDateTo
	union all
select 
	t2.address_name,	
	t2.customer_code, 	
	t1.doc_ctrl_num, 	 
	t1.trx_ctrl_num, 
	(select Amt_net from artrx where trx_ctrl_num = t1.trx_ctrl_num) as 'Credit Amount',
--	convert(varchar,dateadd(day,(t3.date_doc-711858),'1/1/1950'),101) as 'Date Applied',
	t3.date_doc,
	invoice_no=t1.apply_to_num,	
--	convert(varchar,dateadd(day,((select date_entered from artrx where doc_ctrl_num = t1.apply_to_num)-711858),'1/1/1950'),101) as 'Inv Date',
	(select date_entered from artrx where doc_ctrl_num = t1.apply_to_num) as 'InvDate',
	(select date_due from artrx where doc_ctrl_num = t1.apply_to_num) as 'Stmt Due Date',
	(select Customer_code from artrx where doc_ctrl_num = t1.apply_to_num) as 'CustomerCode',
	(select CASE WHEN trx_type = '2031' THEN (amt_net) ELSE (amt_net) * -1  END  from artrx where doc_ctrl_num = t1.apply_to_num) as 'Inv Amount',
	payment_amt=t1.amt_applied	
 from 
	--artrxpdt t1, armaster t2, artrx_pyt_vw t3, artrx_inv_vw t4
	artrxpdt t1 (nolock) 
	inner join artrx_pyt_vw (nolock) t3 on t3.doc_ctrl_num = t1.doc_ctrl_num and t3.trx_ctrl_num = t1.trx_ctrl_num
	inner join artrx_inv_vw t4 (nolock) on t4.doc_ctrl_num = t1.apply_to_num
	inner join armaster (nolock) t2 on t2.customer_code = t3.customer_code
 where 
	 --t2.customer_code = t3.customer_code
	 --and t2.address_type = 0
	t2.address_type = 0
	and t1.trx_type in (2111) 
	--and t1.doc_ctrl_num = t3.doc_ctrl_num
	--and t1.trx_ctrl_num = t3.trx_ctrl_num
	--and t1.apply_to_num = t4.doc_ctrl_num
	--and t3.payment_type in (1,2)
--and t2.customer_code = (@customer_code)
--and t3.date_doc between @JDateFrom and @JDateTo
--order by customer_code, trx_ctrl_num

-- write offs
/*
select customer_code, doc_ctrl_num, trx_ctrl_num, amt_wr_off, apply_to_num, line_desc, writeoff_code,* from artrxpdt where trx_ctrl_num like 'WRTRX%'
and customer_code in ('000542')
*/


GO
GRANT REFERENCES ON  [dbo].[cvo_ar_credit_AppliedDebit_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_ar_credit_AppliedDebit_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_ar_credit_AppliedDebit_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_ar_credit_AppliedDebit_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_ar_credit_AppliedDebit_vw] TO [public]
GO
