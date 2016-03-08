
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		ELaBarbera
-- Create date: 8/8/2013
-- Description:	PO Received Air vs Ocean Report
-- EXEC cvo_PORec_AvO_NOSS_sp '10/1/2013','12/31/2013'
-- =============================================
CREATE PROCEDURE [dbo].[cvo_PORec_AvO_NOSS_sp] 
	
@DateFrom datetime,
@DateTo datetime

AS
BEGIN
	SET NOCOUNT ON;
-- RECEIVED PO AIR/OCEAN REPORT
--DECLARE @DateFrom datetime                                    
--DECLARE @DateTo datetime		

--SET @DateFrom = '5/1/2013'
--SET @DateTo = '7/31/2013'
	SET @dateTo= dateadd(day,1,(dateadd(second,-1,@dateTo)))

IF(OBJECT_ID('tempdb.dbo.#D1') is not null)  
drop table #D1 
select vendor_no, ship_to_no, re.po_no, re.po_line, re.part_no, ISNULL(type_code,'Other')type_code, 
CASE WHEN p.ship_via_method IS NULL AND PA.SHIP_VIA_METHOD IS NULL THEN 2 
	WHEN p.ship_via_method IS NULL AND PA.SHIP_VIA_METHOD = 0 THEN 2
	WHEN p.ship_via_method IS NULL THEN PA.SHIP_VIA_METHOD 
	WHEN p.ship_via_method = 0 THEN 2
ELSE P.SHIP_VIA_METHOD END SHIP_VIA,
recv_date, CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(recv_date)-1),recv_date),111) AS Mth,
re.quantity, (re.quantity*re.unit_cost) extd_cost, re.unit_cost, re.std_cost, re.std_ovhd_dolrs, re.std_util_dolrs, user_category
INTO #D1
from pur_list p (nolock) 
inner join purchase_all pa (nolock) on pa.po_key = p.po_key
left join releases r (nolock) on p.po_no = r.po_no and p.line = r.po_line
left join receipts re (nolock) on p.po_no = re.po_no and p.line = re.po_line
left join inv_master inv (nolock) on re.part_no=inv.part_no
where recv_date between @DateFrom and @DateTo
and type_code in ('sun','frame')
order by vendor_no, ship_to_no, re.po_no, re.po_line, re.part_no

delete from #D1 where quantity=0

IF(OBJECT_ID('tempdb.dbo.#D2') is not null)  
drop table #D2 
select vendor_no, case when ship_via = 1 THEN 'Air' ELSE 'Ocean' END as Method, Mth, 
sum(quantity)Qty, 
(select sum(quantity) from #D1 T11 where t1.Vendor_no=t11.vendor_no and t1.mth=t11.mth and user_category <> 'Frame-SS' and user_category <> 'Frame-1') AllQty,
sum(extd_cost)Value,
(select sum(extd_cost) from #D1 T11 where t1.Vendor_no=t11.vendor_no and t1.mth=t11.mth and user_category <> 'Frame-SS' and user_category <> 'Frame-1') AllValue
INTO #D2
from #D1 t1
Where user_category <> 'Frame-SS'
AND user_category <> 'Frame-1'
Group by Vendor_NO, Ship_via, Mth
Order by Vendor_NO, Ship_via, Mth

UPDATE #D2 SET ALLQTY = 0 WHERE QTY = 0
UPDATE #D2 SET ALLVALUE = 0 WHERE VALUE = 0

select Vendor_no, Method, CASE WHEN Mth=@DateFrom THEN 1  	WHEN DATEADD(MONTH,+1,@DateFrom)=Mth  THEN 2   	ELSE 3 END AS MthSort,  Mth, Qty, AllQty,
(select sum(Qty) from #D2 t2 where t1.Vendor_no=t2.vendor_no)  ttlQty,
 Value, AllValue,
(select sum(Value) from #D2 t2 where t1.Vendor_no=t2.vendor_no)  ttlValue 
  from #D2 t1 Order by Vendor_NO, Method, Mth

END

GO
