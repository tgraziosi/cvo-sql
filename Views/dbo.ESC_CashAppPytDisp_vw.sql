SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create view [dbo].[ESC_CashAppPytDisp_vw]
as
select  ParentRecID,SeqID,CustCode,TrxNum,DocNum,DocAmt,(DocBal+AmtApplied) as DocBal,1 as ApplyType
from	ESC_CashAppDet
where	DocType = 'PYT'

union all
select ParentRecID,0,PayerCustCode,CheckNum,CheckNum,(CheckAmt*-1),isnull(RemBalance,0)*-1, 2
from	ESC_CashAppHdr

GO
GRANT REFERENCES ON  [dbo].[ESC_CashAppPytDisp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ESC_CashAppPytDisp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ESC_CashAppPytDisp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ESC_CashAppPytDisp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ESC_CashAppPytDisp_vw] TO [public]
GO
