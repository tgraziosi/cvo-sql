SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[ESC_CashAppPytBal_vw]
as
select d.ParentRecID,d.CustCode,d.SeqID,d.TrxNum,d.DocNum as PytDoc,d.DocDate,d.DocDue,d.DocAmt,d.DocBal,d.AmtApplied,d.DocBal+d.AmtApplied as NetBal, 1 AppType
from ESC_CashAppDet d (NOLOCK)
where	d.DocType = 'PYT'
and		d.DocBal+d.AmtApplied <> 0

union all
select h.ParentRecID,h.PayerCustCode,0,'',h.CheckNum,h.CheckDate,0,(h.CheckAmt*-1),isnull(h.RemBalance,0),h.CheckAmt-isnull(h.RemBalance,0),isnull(h.RemBalance,0), 2
from ESC_CashAppHdr h (NOLOCK)
where isnull(h.RemBalance,0) <> 0
GO
GRANT REFERENCES ON  [dbo].[ESC_CashAppPytBal_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ESC_CashAppPytBal_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ESC_CashAppPytBal_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ESC_CashAppPytBal_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ESC_CashAppPytBal_vw] TO [public]
GO
