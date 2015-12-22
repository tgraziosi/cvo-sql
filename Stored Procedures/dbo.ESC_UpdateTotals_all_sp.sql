SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

  
CREATE procedure [dbo].[ESC_UpdateTotals_all_sp]  @ParRecID varchar(40)  
as  
  
  
-- Now just get the sum of each type of record and update.  
-- Update the PYT transactions first.  
select ParentRecID,PytTrx,sum(PytApp) PytAmt  
into #tempdata1  
from ESC_CashAppInvDet  
where ApplyType = 1  
and  ParentRecID = @ParRecID  
group by ParentRecID,PytTrx  
  
update cd  
set  cd.AmtApplied = abs(isnull(t1.PytAmt,0))  
from ESC_CashAppDet cd  
left outer join #tempdata1 t1 on cd.ParentRecID = t1.ParentRecID and cd.TrxNum = t1.PytTrx  
where  cd.DocType = 'PYT'  
and  cd.ParentRecID = @ParRecID  
  
  
-- Next update the invoice lines  
select ParentRecID,SeqID,sum(PytApp) InvAmt  
into #tempdata2  
from ESC_CashAppInvDet  
where ParentRecID = @ParRecID  
group by ParentRecID,SeqID  
  
update cd  
set  cd.AmtApplied = isnull(t2.InvAmt,0)  
from ESC_CashAppDet cd   
left outer join #tempdata2 t2 on cd.ParentRecID = t2.ParentRecID and cd.SeqID = t2.SeqID   
where cd.DocType = 'INV'  
and  cd.ParentRecID = @ParRecID  
  
  
-- Lastly update the Check balance  
select ParentRecID,sum(PytApp) ChkDsb  
into #tempdata3  
from ESC_CashAppInvDet  
where ApplyType = 2  
and  ParentRecID = @ParRecID  
group by ParentRecID  
  
select ParentRecID,sum(DocBal+AmtApplied) CrmDsb		-- 08/27/2012 BNM - resolve issue 781, Manual cash application, identify Manual credits not fully applied
into	#tempdata4
from	ESC_CashAppDet
where	IncludeInPyt = 1
and		ParentRecID = @ParRecID
and exists(select 1 from #ManualCredits where #ManualCredits.ParentRecID = ESC_CashAppDet.ParentRecID and #ManualCredits.SeqID = ESC_CashAppDet.SeqID)
group by ParentRecID

update ch  
set		ch.RemBalance = ch.CheckAmt + isnull(t3.ChkDsb,0) - isnull(t4.CrmDsb,0),		-- 08/27/2012 BNM - resolve issue 781, Manual cash application, include Manual credits not fully applied
		ch.RemChkBal = ch.CheckAmt + isnull(t3.ChkDsb,0),
		ch.RemCrmBal = 0.0 - isnull(t4.CrmDsb,0)
from ESC_CashAppHdr ch  
left outer join #tempdata3 t3 on ch.ParentRecID = t3.ParentRecID  
left outer join #tempdata4 t4 on ch.ParentRecID = t4.ParentRecID
where   ch.ParentRecID = @ParRecID  
  
update ESC_CashAppDet  
set IncludeInPyt =   
 case   
  when AmtApplied = 0 then 0  
  else 1  
 end  
where not exists(select 1 from #ManualCredits where #ManualCredits.ParentRecID = ESC_CashAppDet.ParentRecID and #ManualCredits.SeqID = ESC_CashAppDet.SeqID)
		-- 08/23/2012 BNM - resolve issue 781, Manual cash application, exclude Manual Credits

GO
GRANT EXECUTE ON  [dbo].[ESC_UpdateTotals_all_sp] TO [public]
GO
