SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tine Graziosi
-- Create date: 9/20/2012
-- Description:	Sales Register - Summary of sales/credits for a date range
-- exec CVO_SalesRegister_sp '9/1/2012', '9/30/2012'
-- =============================================
CREATE PROCEDURE [dbo].[CVO_SalesRegister_sp] @DateFrom datetime, @DateTo datetime		
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

/** Sales Register - Report request # 55
Run by date range
(by Day)
Date, # Invoices, Invoice Sales, # Credits, Credit Sales, Net # Items, Net Sales
(ascending orders by date)
8/14/2012 - added gross and discount amount to view
**/

--DECLARE @DateFrom datetime                                    
--DECLARE @DateTo datetime		

DECLARE @JDateFrom int                                    
DECLARE @JDateTo int	

--SET @DateFrom = '9/1/2012'
--SET @DateTo = '9/30/2012'

SET @dateTo=dateadd(second,-1,@dateTo)
SET @dateTo=dateadd(day,1,@dateTo)

set @JDATEFROM = datediff(day,'1/1/1950',convert(datetime,
  convert(varchar( 8), (year(@datefrom) * 10000) + (month(@datefrom) * 100) + day(@datefrom)))  ) + 711858

select @JDATETO = datediff(day,'1/1/1950',convert(datetime,
  convert(varchar( 8), (year(@dateto) * 10000) + (month(@dateto) * 100) + day(@dateto)))  ) + 711858


IF(OBJECT_ID('tempdb.dbo.#salesreg_tmp') is not null)  
drop table #salesreg_tmp

create table #salesreg_tmp
(
date_applied int,
invcount int,
crdcount int,
trx_ctrl_num varchar(16),
order_ctrl_num varchar(16),
inv_amt_list decimal(20,8),
inv_amt_gross decimal(20,8),
inv_amt_discount decimal(20,8),
inv_amt_net decimal(20,8),
crd_amt_list decimal(20,8),
crd_amt_gross decimal(20,8),
crd_amt_discount decimal(20,8),
crd_amt_net decimal(20,8)
)

insert into #salesreg_tmp
select 
date_applied,
case when invcrm = 'Invoice' then 1 else 0 end as invcount,
case when invcrm = 'Credit' then 1 else 0 end as crdcount,
trx_ctrl_num,
order_ctrl_num, 
0 as inv_amt_list,
case when invcrm = 'Invoice' then amt_gross else 0 end as inv_amt_gross,
case when invcrm = 'Invoice' then amt_discount else 0 end as inv_amt_discount,
case when invcrm = 'Invoice' then amt_net else 0 end as inv_amt_net,
0 as inv_amt_list,
case when invcrm = 'Credit' then amt_gross else 0 end as crd_amt_gross,
case when invcrm = 'Credit' then amt_discount else 0 end as crd_amt_discount,
case when invcrm = 'Credit' then amt_net else 0 end as crd_amt_net

from cvo_invreg_vw i (nolock)
where i.date_applied between @jdatefrom and @jdateto

insert into #salesreg_tmp
select x.date_applied,
0  as invcount,
0  as crdcount,
x.trx_ctrl_num,
order_ctrl_num, 
case when x.trx_type = 2031 then col.list_price * ol.shipped else 0 end as inv_amt_list,
0 as inv_amt_gross,
0 as inv_amt_discount,
0 as inv_amt_net,
case when x.trx_type = 2032 then (col.list_price * ol.cr_shipped)*-1 else 0 end as crd_amt_list,
0 as crd_amt_gross,
0 as crd_amt_discount,
0 as crd_amt_net

from artrx x (nolock)
inner join orders_invoice oi (nolock) on x.trx_ctrl_num = oi.trx_ctrl_num 
inner join ord_list ol (nolock) on ol.order_no = oi.order_no and ol.order_ext = oi.order_ext
inner join cvo_ord_list col (nolock) on col.order_no = ol.order_no and col.order_ext = ol.order_ext 
		and col.line_no = ol.line_no
where x.trx_type in (2031,2032) AND x.DOC_DESC NOT LIKE 'CONVERTED%'
AND x.doc_desc NOT LIKE '%NONSALES%' AND x.doc_ctrl_num NOT LIKE 'CB%'
AND x.doc_ctrl_num NOT LIKE 'FIN%'and x.void_flag = 0 and x.posted_flag = 1
and x.date_applied between  @jdatefrom and @jdateto

insert into #salesreg_tmp
select x.date_applied,
0  as invcount,
0  as crdcount,
x.trx_ctrl_num,
order_ctrl_num, 
case when x.trx_type = 2031 then col.list_price * ol.shipped else 0 end as inv_amt_list,
0 as inv_amt_gross,
0 as inv_amt_discount,
0 as inv_amt_net,
case when x.trx_type = 2032 then (col.list_price * ol.cr_shipped)*-1 else 0 end as crd_amt_list,
0 as crd_amt_gross,
0 as crd_amt_discount,
0 as crd_amt_net
from arinpchg x (nolock)
inner join orders_invoice oi (nolock) on x.trx_ctrl_num = oi.trx_ctrl_num 
inner join ord_list ol (nolock) on ol.order_no = oi.order_no and ol.order_ext = oi.order_ext
inner join cvo_ord_list col (nolock) on col.order_no = ol.order_no and col.order_ext = ol.order_ext 
		and col.line_no = ol.line_no
where x.trx_type in (2031,2032) AND x.DOC_DESC NOT LIKE 'CONVERTED%'
AND x.doc_desc NOT LIKE '%NONSALES%' AND x.doc_ctrl_num NOT LIKE 'CB%'
AND x.doc_ctrl_num NOT LIKE 'FIN%'
-- and x.void_flag = 0 and x.posted_flag = 1
and x.date_applied between  @jdatefrom and @jdateto


select 
convert(datetime,dateadd(dd,date_applied-639906,'01/01/1753'),101) as Date_Applied, 
sum(invcount) numinvoice,
sum(inv_amt_list) listinvoice,
sum(inv_amt_gross) grossinvoice,
sum(inv_amt_list-inv_amt_gross+inv_amt_discount) discinvoice,
sum(inv_amt_net) netinvoice,

sum(crdcount) numcredit,
sum(crd_amt_list) listcredit,
sum(crd_amt_gross) grosscredit,
sum(crd_amt_list-crd_amt_gross+crd_amt_discount) disccredit,
sum(crd_amt_net) netcredit,

sum(invcount) + sum(crdcount) Num,
sum(inv_amt_net) + sum(crd_amt_net) Net

from #salesreg_tmp
group by date_applied
order by date_applied
END

GO
