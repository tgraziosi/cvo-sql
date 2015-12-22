SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/** Sales Register - Report request # 55
Run by date range
(by Day)
Date, # Invoices, Invoice Sales, # Credits, Credit Sales, Net # Items, Net Sales
(ascending orders by date)
8/14/2012 - added gross and discount amount to view
**/
CREATE view [dbo].[cvo_SalesReg_vw]
AS
select i.date_applied, 
isnull((select count(trx_ctrl_num) from cvo_invreg_vw (nolock) ii 
	where ii.date_applied = i.date_applied and ii.invcrm='Invoice'), 0) NumInvoice, 
isnull((select sum(amt_gross) from cvo_invreg_vw (nolock) ii 
	where ii.date_applied = i.date_applied and ii.invcrm='Invoice'), 0) GrossInvoice, 
isnull((select sum(amt_discount) from cvo_invreg_vw (nolock) ii 
	where ii.date_applied = i.date_applied and ii.invcrm='Invoice'), 0) DiscInvoice, 
isnull((select sum(amt_net) from cvo_invreg_vw (nolock) ii 
	where ii.date_applied = i.date_applied and ii.invcrm='Invoice'), 0) NetInvoice, 
isnull((select count(trx_ctrl_num) from cvo_invreg_vw (nolock) ii 
	where ii.date_applied = i.date_applied and ii.invcrm='Credit'), 0) NumCredit, 
isnull((select sum(amt_gross) from cvo_invreg_vw (nolock) ii 
	where ii.date_applied = i.date_applied and ii.invcrm='Credit'), 0) GrossCredit, 
isnull((select sum(amt_discount) from cvo_invreg_vw (nolock) ii 
	where ii.date_applied = i.date_applied and ii.invcrm='Credit'), 0) DiscCredit, 
isnull((select sum(amt_net) from cvo_invreg_vw (nolock) ii 
	where ii.date_applied = i.date_applied and ii.invcrm='Credit'), 0) NetCredit, 
isnull((select count(trx_ctrl_num) from cvo_invreg_vw (nolock) ii 
	where ii.date_applied = i.date_applied), 0) Num, 
isnull((select sum(amt_net) from cvo_invreg_vw (nolock) ii 
	where ii.date_applied = i.date_applied), 0) Net 

from cvo_invreg_vw i (nolock)
group by i.date_applied
GO
GRANT REFERENCES ON  [dbo].[cvo_SalesReg_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_SalesReg_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_SalesReg_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_SalesReg_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_SalesReg_vw] TO [public]
GO
