SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- exec cvo_dpr_bi

CREATE PROCEDURE [dbo].[CVO_dpr_bi]
AS

set nocount on;
SET ANSI_WARNINGS OFF;

TRUNCATE TABLE 
-- select * From 
DPR_report
                              
                              
DECLARE @TodayDayOfWeek INT                                        
DECLARE @EndOfPrevWeek DateTime                                        
DECLARE @StartOfPrevWeek4 DateTime                                        
DECLARE @StartOfPrevWeek12 DateTime                                        
DECLARE @StartOfPrevWeek26 DateTime                                        
DECLARE @StartOfPrevWeek52 DateTime                                         
DECLARE @location tinyint                        
DECLARE @ctrl int                              
DECLARE @locationName varchar(80)                        

-- REBUILT BY ELABARBERA
--get number of a current day (1-Monday, 2-Tuesday... 7-Sunday)                                        
 SET @TodayDayOfWeek = datepart(dw, GetDate())                                        
--get the last day of the previous week (last Sunday)                                        
 SET @EndOfPrevWeek = DATEADD(ms, -3, DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())))
--get the first day of the previous week (the Monday before last)                                        
 SET @StartOfPrevWeek4 = DATEADD(ms, +4, DATEADD(dd, -(28), @EndOfPrevWeek))                                       
-- 12 weeks                                        
 SET @StartOfPrevWeek12 = DATEADD(ms, +4, DATEADD(dd, -(84), @EndOfPrevWeek))                                    
-- 26                                        
 SET @StartOfPrevWeek26 = DATEADD(ms, +4, DATEADD(dd, -(182), @EndOfPrevWeek))                                         
-- 52                                        
 SET @StartOfPrevWeek52 = DATEADD(ms, +4, DATEADD(dd, -(364), @EndOfPrevWeek))                                         
          
SET @ctrl = 1    

IF(OBJECT_ID('tempdb.dbo.#weeks') is not null)
drop table #weeks 
CREATE TABLE #weeks
(
	startDate smalldatetime,
	endDate smalldatetime,
	week tinyint
)

Insert Into #weeks Values(@StartOfPrevWeek4, @EndOfPrevWeek, 4)
Insert Into #weeks Values(@StartOfPrevWeek12, @EndOfPrevWeek, 12)
Insert Into #weeks Values(@StartOfPrevWeek26, @EndOfPrevWeek, 26)
Insert Into #weeks Values(@StartOfPrevWeek52, @EndOfPrevWeek, 52)
     
IF(OBJECT_ID('tempdb.dbo.#prelocations') is not null)                          
drop table #prelocations                      
Select *, identity(int, 1, 1)ctrl Into #prelocations From DPR_Locations                        
  
IF(OBJECT_ID('tempdb.dbo.#locations') is not null)                          
drop table #locations                        
Select Top 0 * Into #locations From DPR_Locations                        
                        
Select @location = MAX(ctrl) From #prelocations         


-- Get Historical Sales Data
-- Live
IF(OBJECT_ID('tempdb.dbo.#vsDataTable') is not null)                          
drop table #vsDataTable
select t1.part_no, t3.type,
CASE T3.TYPE WHEN 'I' THEN t1.shipped ELSE (t1.cr_shipped*-1) END AS Shipped,
 date_shipped, cast(t3.location  as varchar(80)) location
		INTO #vsDataTable
from orders_all t3 (nolock) inner join ord_list (nolock) t1 on t1.order_no=t3.order_no and t1.order_ext=t3.ext
left outer join inv_master (nolock) t2 on t1.part_no=t2.part_no
join inv_master_add (nolock) t4 on t4.part_no=t1.part_no
		Where t3.date_shipped >= (Select MIN(startdate) From #weeks) and t1.shipped is not null
--group by t1.part_no, T3.TYPE, t1.shipped, t1.cr_shipped, date_shipped, t1.location

---- History    
--Insert Into #vsDataTable
--select t1.part_no, t3.type,
--CASE T3.TYPE WHEN 'I' THEN t1.shipped ELSE (t1.cr_shipped*-1) END AS Shipped,
-- date_shipped, t1.location 
--from cvo_ord_list_hist (nolock) t1
--left outer join inv_master (nolock) t2 on t1.part_no=t2.part_no
--join cvo_orders_all_hist (nolock) t3 on t1.order_no=t3.order_no and t1.order_ext=t3.ext
--join inv_master_add (nolock) t4 on t4.part_no=t1.part_no
--		Where t3.date_shipped >= (Select MIN(startdate) From #weeks) and t1.shipped is not null
----group by t1.part_no, T3.TYPE, t1.shipped, t1.cr_shipped, date_shipped, t1.location

-- Pull All Item Codes for all locations

insert into #vsdatatable 
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, left(l.location,80) location
from inv_master i (nolock) cross join dpr_locations l
where i.void = 'n'

-- select * From #vsdatatable

/*
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, '001' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'costco' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'insight' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'centennial' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'kaiser' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'luxottica' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'Astucci' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'Liberty' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'ME Retail' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'U.S.Vision' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'Nordstrom' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'Visionwork' as location
from inv_master  where VOID ='N'
*/

--
WHILE(@ctrl <= @location)                        
BEGIN                        
 truncate table #locations                        
                        
 Select @locationName = location From #prelocations Where ctrl = @ctrl                        
                        
 IF(@locationName = 'ALL')                        
  Insert Into #locations Select * From DPR_Locations Where location not in('ALL', 'Key Accounts')                        
 ELSE IF(@locationName = 'Key Accounts')                        
  Insert Into #locations Select * From DPR_Locations Where location not in('ALL', 'Key Accounts', '001', 'Astucci', 'Liberty', 'ME Retail', 'U.S.Vision', 'Nordstrom')                        
 ELSE Insert Into #locations Values(@locationName)                        
                        
print cast(@ctrl as varchar) + ': ' + @locationName                         

--Sales Shipped Live & Hist
IF(OBJECT_ID('tempdb.dbo.#WeekShipped') is not null)                          
drop table #WeekShipped 
Select part_no,
ISNULL(Shipped,0) as shipped,
CASE
	When date_shipped BETWEEN (Select startDate From #weeks Where week = 4) and (Select endDate From #weeks Where week = 4) Then 4
	When date_shipped BETWEEN (Select startDate From #weeks Where week = 12) and (Select endDate From #weeks Where week = 12) Then 12
	When date_shipped BETWEEN (Select startDate From #weeks Where week = 26) and (Select endDate From #weeks Where week = 26) Then 26
	When date_shipped BETWEEN (Select startDate From #weeks Where week = 52) and (Select endDate From #weeks Where week = 52) Then 52
	When date_shipped IS NULL THEN 4
End Week
Into #WeekShipped
From #vsDataTable 
inner join #locations l on l.location = #vsdatatable.location
-- Where location in (Select * From #locations) 

-- Total shipped Live & Hist
IF(OBJECT_ID('tempdb.dbo.#ShippedTotal') is not null)                          
drop table #ShippedTotal 
Select a.part_no, b.e4_wu, c.e12_wu, d.e26_wu, e.e52_wu
Into #ShippedTotal
From (Select distinct part_no From #WeekShipped) a left join 
(Select part_no, CAST(SUM(ISNULL(Shipped,0))/4 as int) e4_wu From #WeekShipped Where week = 4 Group By part_no) b on a.part_no = b.part_no
left join 
(Select part_no, CAST(SUM(ISNULL(Shipped,0))/12 as int) e12_wu From #WeekShipped Where week in (4, 12) Group By part_no) c on a.part_no = c.part_no
left join 
(Select part_no, CAST(SUM(ISNULL(Shipped,0))/26 as int)e26_wu From #WeekShipped Where week  in (4, 12, 26) Group By part_no) d on a.part_no = d.part_no
left join 
(Select part_no, CAST(SUM(ISNULL(Shipped,0))/52 as int)e52_wu From #WeekShipped Where week in (4, 12, 26, 52) Group By part_no) e on a.part_no = e.part_no
  
-- Forecast 
IF(OBJECT_ID('tempdb.dbo.#WeekForecast') is not null)                          
drop table #WeekForecast
select '' as part_no, '0' AS forecast, '4' AS Week
Into #WeekForecast

-- Total forecast
IF(OBJECT_ID('tempdb.dbo.#ForescastTotal') is not null)                          
drop table #ForescastTotal 
Select a.*, '0' AS s4_wu, '0' AS s12_wu, '0' AS s26_wu, '0' AS s52_wu
Into #ForescastTotal
From #ShippedTotal a 

-- BO
IF(OBJECT_ID('tempdb.dbo.#TBBo') is not null)                          
drop table #TBBo 
Select t1.part_no, (SUM(ISNULL(ordered,0))-sum(isnull(qty,0)))bo,SUM(ISNULL(ordered,0))bod,sum(isnull(qty,0))AllBo
Into #TBBo
From #locations l inner join orders_all t2 (nolock) on t2.location = l.location
inner join ord_list t1 (nolock) on t1.order_no=t2.order_no and t1.order_ext=t2.ext                                  
inner join cvo_orders_all t3 (nolock) on t2.order_no=t3.order_no and t2.ext=t3.ext                                  
full outer join tdc_soft_alloc_tbl t4 (nolock) on t4.order_no=t1.order_no and t4.order_ext=t1.order_ext  and t4.line_no=t1.line_no   
Where 1=1
-- and t1.location in (Select * From #locations) 
and t2.type='I' and t2.ext<>0 and t2.status not in ('T','V')
Group By t1.part_no

-- Pull data for RR
IF(OBJECT_ID('tempdb.dbo.#TBRRI') is not null)  
drop table #TBRRI
Select t1.part_no, ordered,
CASE 
When t2.date_shipped between dateadd(m,-1,getdate()) and getdate() Then 1
Else 3
End Month
Into #TBRRI
From ord_list t1 (nolock) 
inner join orders_all t2 (nolock) on t1.order_no=t2.order_no and t1.order_ext=t2.ext                                  
inner join cvo_orders_all t3 (nolock) on t2.order_no=t3.order_no and t2.ext=t3.ext
Where t2.type='I' and t2.date_shipped BETWEEN dateadd(m,-3,getdate()) and getdate()
and t2.ext=0 and t2.status='T'

IF(OBJECT_ID('tempdb.dbo.#TBRRC') is not null)                          
drop table #TBRRC
Select t1.part_no, cr_ordered as ordered,
CASE 
When t2.date_shipped between dateadd(m,-1,getdate()) and getdate() Then 1
Else 3
End Month
Into #TBRRC
From 
orders_all t2 (nolock) inner join ord_list t1 (nolock) on t1.order_no=t2.order_no and t1.order_ext=t2.ext                                  
inner join cvo_orders_all t3 (nolock) on t2.order_no=t3.order_no and t2.ext=t3.ext
Where t2.type='C' and t2.date_shipped BETWEEN dateadd(m,-3,getdate()) and getdate() 
and t2.ext=0 and t2.status='T' 


-- RR1
IF(OBJECT_ID('tempdb.dbo.#TBRR1') is not null)                          
drop table #TBRR1
Select ISNULL(a.part_no, b.part_no)part_no,
ISNULL((a.ordered / (b.ordered + .0001)),0) RR1
Into #TBRR1
From (Select part_no, SUM(ISNULL(cast(ordered as float),0))ordered FROM #TBRRC Where [MONTH] = 1 Group By part_no) a 
full join
(Select part_no, SUM(ISNULL(cast(ordered as float),0))ordered FROM #TBRRI Where [MONTH] = 1 Group By part_no) b on a.part_no = b.part_no 

-- RR3
IF(OBJECT_ID('tempdb.dbo.#TBRR3') is not null) 
drop table #TBRR3
Select ISNULL(a.part_no, b.part_no)part_no,
ISNULL((a.ordered / (b.ordered + .0001)),0) RR3
Into #TBRR3
From (Select part_no, SUM(ISNULL(cast(ordered as float),0))ordered FROM #TBRRC Group By part_no) a 
full join
(Select part_no, SUM(ISNULL(cast(ordered as float),0))ordered FROM #TBRRI Group By part_no) b on a.part_no = b.part_no 
                                     

-- Add BO, RR1 & RR3
IF(OBJECT_ID('tempdb.dbo.#TBA') is not null) 
drop table #TBA
Select a.*, c.bo, d.RR1, e.RR3
Into #TBA
From #ForescastTotal a 
left join #TBBo c on a.part_no = c.part_no
left join #TBRR1 d on a.part_no = d.part_no
left join #TBRR3 e on a.part_no = e.part_no


-- Add addl collection, vendor, obsolete
IF(OBJECT_ID('tempdb.dbo.#TBB') is not null) 
drop table #TBB
Select a.*,  category collection, vendor, --obsolete status_Old,
CASE
When Type_code in ('SUN','FRAME','BRUIT') Then 'Frame/Sun'
Else Type_code end As Type_code
Into #TBB
From #TBA a left join inv_master (nolock) b on a.part_no = b.part_no
Where obsolete in (1,0)

-- Add addl POM, RD, Style             
IF(OBJECT_ID('tempdb.dbo.#DPR_InvMaster') is not null)                          
drop table #DPR_InvMaster                          
Select a.*, 
DATEADD(dd, 0, DATEDIFF(dd, 0, field_28)) POM,
DATEADD(dd, 0, DATEDIFF(dd, 0, field_26)) RD, 
CASE WHEN (FIELD_26 <=GETDATE() AND FIELD_28 IS NULL) OR (FIELD_26 <=GETDATE() AND FIELD_28 >GETDATE()) THEN 0 ELSE 1 end as [status],
-- CASE WHEN FIELD_26 <=GETDATE() OR FIELD_28 >=GETDATE() THEN 1 ELSE 0 end as [status],
field_2 style Into #DPR_InvMaster                          
From #TBB a left join inv_master_add (nolock) b on a.part_no = b.part_no                          
             
-- Pull Reserve Level, In Stock
IF(OBJECT_ID('tempdb.dbo.#vs1DPRInventory') is not null)                          
drop table #vs1DPRInventory
Select part_no, MAX(ISNULL(min_stock,0))RL, SUM(ISNULL(in_stock,0))on_hand
Into #vs1DPRInventory
From #locations l 
inner join cvo_item_avail_vw (nolock) c on c.location = l.location
-- Where location in (Select * From #locations)
Group By part_no  

-- Pull QC ON HAND
IF(OBJECT_ID('tempdb.dbo.#vs2DPRInventory') is not null)                          
drop table #vs2DPRInventory
Select part_no, SUM(ISNULL(qty,0))QCOH
Into #vs2DPRInventory
From #locations l inner join lot_Bin_recv (nolock) r on r.location = l.location
where qc_flag ='y'
-- and location in (Select * From #locations)
Group By part_no  

-- add soft allocation table
IF(OBJECT_ID('tempdb.dbo.#vs3DPRInventory') is not null)                          
drop table #vs3DPRInventory
--SELECT part_no, sum(ISNULL( DBO.f_cvo_get_soft_alloc_stock('0', LOCATION, PART_NO),0) ) AS SA_Alloc  -- GET RID OF FUNCTION
Select part_no, (sum(ISNULL(Allocated,0))+sum(ISNULL(SOF,0)) )SA_Alloc
INTO #vs3DPRInventory
FROM #locations l inner join cvo_item_avail_vw t1(NOLOCK) on t1.location = l.location
-- Where location in (Select * From #locations)
GROUP BY PART_NO   

--IF(OBJECT_ID('tempdb.dbo.#ItemAvl') is not null)                          
--drop table #ItemAvl
--Select part_no, location, MAX(ISNULL(min_stock,0))RL, SUM(ISNULL(in_stock,0))on_hand, sum(ISNULL(QTY_AVL,0))AvlToProm, ( sum(ISNULL(Allocated,0))+sum(ISNULL(SOF,0)) )Alloc
--Into #ItemAvl
--From cvo_item_avail_vw (nolock)
--Where location in (select * from DPR_Locations)
--Group By part_no, location



-- add soft allocation table
IF(OBJECT_ID('tempdb.dbo.#vs4DPRInventory') is not null)                          
drop table #vs4DPRInventory
SELECT PART_NO, sum(ISNULL(QTY_AVL,0)) as SA_ALLOCATED    -- SA_Allocated is actually Available to Promise
INTO #vs4DPRInventory
FROM #locations l inner join CVO_ITEM_AVAIL_VW (nolock) c on c.location = l.location
-- Where location in (Select * From #locations)
GROUP BY PART_NO

--     SELECT * FROM #vs1DPRInventory WHERE part_no='BC804HOR5818'
--     SELECT * FROM #DPR_ApMaster  WHERE part_no='BC804HOR5818'


--  Add INV Master data to RL & OH & QC
IF(OBJECT_ID('tempdb.dbo.#DPR_Inventory') is not null)                          
drop table #DPR_Inventory                           
Select a.*, b.RL, sum(isnull(b.on_hand,0)+isnull(c.qcoh,0))on_hand, D.SA_Alloc, E.SA_ALLOCATED  -- SA_Allocated is actually Available to Promise
Into #DPR_Inventory
From #DPR_InvMaster a 
left join #vs1DPRInventory b on a.part_no = b.part_no
left join #vs2DPRInventory c on a.part_no = C.part_no
left join #vs3DPRInventory D on a.part_no = D.part_no
left join #vs4DPRInventory e on a.part_no = e.part_no
group by a.part_no, a.e4_wu, a.e12_wu, a.e26_wu, a.e52_wu, a.s4_wu, a.s12_wu, a.s26_wu, a.s52_wu, a.bo, a.RR1, a.RR3, 
a.collection, a.vendor, a.status, a.Type_code, a.POM, a.RD, a.style,b.RL, d.SA_Alloc, E.SA_ALLOCATED

-- Add Addl LT
IF(OBJECT_ID('tempdb.dbo.#DPR_ApMaster') is not null)                          
drop table #DPR_ApMaster                          
Select a.*, b.lt Into #DPR_ApMaster                          
From #DPR_Inventory a left join (Select vendor_code, MAX(ISNULL(lead_time,0))lt From apmaster_all (nolock) Group By vendor_code) b on a.vendor = b.vendor_code         



-- BUILD Alloc

IF(OBJECT_ID('tempdb.dbo.#tbAlloc') is not null)                          
drop table #tbAlloc                           
Select a.*, (/*ISNULL(b.alloc,0)+*/isnull(a.sa_alloc,0))alloc, ISNULL(c.alloc1,0)alloc1, (ISNULL(d.nalloc1,0))nalloc1, ISNULL(e.FO1,0)FO1, ISNULL(f.alloc2,0)alloc2,                          
(ISNULL(g.nalloc2,0))nalloc2, ISNULL(h.FO2,0)FO2, ISNULL(i.alloc3,0)alloc3, (ISNULL(j.nalloc3,0))nalloc3, ISNULL(k.FO3,0)FO3,                          
ISNULL(l.alloc4, 0)alloc4, (ISNULL(m.nalloc4,0))nalloc4, ISNULL(n.FO4,0)FO4, ISNULL(o.alloc5,0)alloc5, (ISNULL(p.nalloc5,0) )nalloc5,                          
ISNULL(q.FO5,0)FO5, ISNULL(r.alloc6,0)alloc6, (ISNULL(s.nalloc6,0))nalloc6, ISNULL(t.FO6,0)FO6                          
Into #tbAlloc 
From #DPR_ApMaster a left join                           
(select t2.part_no, SUM(t1.qty)alloc 
from #locations l inner join tdc_soft_alloc_tbl t1 (nolock) on t1.location = l.location                                 
inner join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.order_ext=t2.order_ext  and t1.line_no=t2.line_no                        
inner join orders_all t3 (nolock) on t2.order_no=t3.order_no and t2.order_ext=t3.ext                                            
where t3.status not in ('T','V') and t3.type='I' and t1.alloc_type<>'xf' 
-- and t3.location in (Select * From #locations) 
Group By t2.part_no) b /*  */ on a.part_no = b.part_no                          


-- BUILD Future
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc1 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location
inner join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	inner join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                         
--and t2.ship_to_no in (Select * From #locations)                       
-- and t1.location in (Select * From #locations)                       
and t3.inhouse_date between dateadd(yy,-1,getdate()) and DATEADD(S,-1,DATEADD(dd, 28, DATEDIFF(dd, 0,getdate())))
and po_type = 'XX' Group By t1.part_no) c /*  */ on a.part_no = c.part_no                          
left join          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc1 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location                               
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                        
--and t2.ship_to_no in (Select * From #locations)                       
-- and t1.location in (Select * From #locations)                       
and t2.inhouse_date between getdate() and DATEADD(S,-1,DATEADD(dd, 28, DATEDIFF(dd, 0,getdate()))) and po_type <> 'XX' Group By t1.part_no) d  /*  */ on a.part_no = d.part_no                          
left join                          
(Select t2.part_no, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO1 
From #locations l inner join orders_all (nolock) t1  on t1.location = l.location                             
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext                     
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
left join (Select order_no, location, line_no, SUM(qty)qty
, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date between '1/1/2012' and DATEADD(S,-1,DATEADD(dd, 28, DATEDIFF(dd, 0,getdate())))                               
and t4.allocation_date > getdate() 
-- and t2.location in (Select * From #locations) 
and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no) e  /*  */ on a.part_no = e.part_no 


--2                        
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc2 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                        
--and t2.ship_to_no in (Select * From #locations) 
-- and t1.location in (Select * From #locations)                     
and t3.inhouse_date between DATEADD(dd, 28, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 56, DATEDIFF(dd, 0,getdate()))) and po_type = 'XX' Group By t1.part_no) f /*  */  on a.part_no = f.part_no                          
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc2 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                        
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)                       
and t3.inhouse_date between DATEADD(dd, 28, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 56, DATEDIFF(dd, 0,getdate()))) and po_type <> 'XX' Group By t1.part_no) g /*  */  on a.part_no = g.part_no                          
left join                          
(Select t2.part_no, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO2 
From #locations l inner join orders_all (nolock) t1  on t1.location = l.location
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date between DATEADD(dd, 28, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 56, DATEDIFF(dd, 0,getdate())))
and t4.allocation_date > getdate() 
-- and t2.location in (Select * From #locations) 
and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no) h /*  */  on a.part_no = h.part_no                          
--3                        
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc3 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                         
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)
and t3.inhouse_date between DATEADD(dd, 56, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 84, DATEDIFF(dd, 0,getdate()))) and po_type = 'XX' Group By t1.part_no) i /*  */  on a.part_no = i.part_no                          
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc3 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                       
and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)                       
and t3.inhouse_date between DATEADD(dd, 56, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 84, DATEDIFF(dd, 0,getdate()))) and po_type <> 'XX' Group By t1.part_no) j /*  */  on a.part_no = j.part_no                          
left join                          
(Select t2.part_no, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO3 
From #locations l inner join orders_all (nolock) t1  on t1.location = l.location
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date between DATEADD(dd, 56, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 84, DATEDIFF(dd, 0,getdate())))
and t4.allocation_date > getdate() 
-- and t2.location in (Select * From #locations)  
and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no) k /*  */  on a.part_no = k.part_no                          
--4                        
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc4 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                           
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)
and t3.inhouse_date between DATEADD(dd, 84, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 112, DATEDIFF(dd, 0,getdate()))) and po_type = 'XX' Group By t1.part_no) l /*  */  on a.part_no = l.part_no                          
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc4 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                       
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)                       
and t3.inhouse_date between DATEADD(dd, 84, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 112, DATEDIFF(dd, 0,getdate()))) and po_type <> 'XX' Group By t1.part_no) m /*  */  on a.part_no = m.part_no                          
left join                          
(Select t2.part_no, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO4 
From #locations l inner join orders_all (nolock) t1  on t1.location = l.location
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date between DATEADD(dd, 84, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 112, DATEDIFF(dd, 0,getdate())))                               
and t4.allocation_date > getdate() 
-- and t2.location in (Select * From #locations)  
and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no) n /*  */  on a.part_no = n.part_no                          
--5                        
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc5 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                                             
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)
and t3.inhouse_date between DATEADD(dd, 112, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 140, DATEDIFF(dd, 0,getdate()))) and po_type = 'XX' Group By t1.part_no) o /*  */  on a.part_no = o.part_no                          
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc5 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                                              
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)                       
and t3.inhouse_date between DATEADD(dd, 112, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 140, DATEDIFF(dd, 0,getdate()))) and po_type <> 'XX' Group By t1.part_no) p /*  */  on a.part_no = p.part_no                          
left join                          
(Select t2.part_no, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO5 
From #locations l inner join orders_all (nolock) t1  on t1.location = l.location
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date between DATEADD(dd, 112, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 140, DATEDIFF(dd, 0,getdate())))
and t4.allocation_date > getdate() 
-- and t2.location in (Select * From #locations)  
and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no) q /*  */  on a.part_no = q.part_no                          
--6                        
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc6 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                                             
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)
and t3.inhouse_date >= DATEADD(dd, 140, DATEDIFF(dd, 0,getdate()))
and po_type = 'XX' Group By t1.part_no) r /*  */  on a.part_no = r.part_no                          
left join                          
(select t1.part_no, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc6 
from #locations l inner join pur_list (nolock) t1  on t1.location = l.location  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                                            
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)                       
and t3.inhouse_date >= DATEADD(dd, 140, DATEDIFF(dd, 0,getdate()))
and po_type <> 'XX' Group By t1.part_no) s on a.part_no = s.part_no                          
left join                          
(Select t2.part_no, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO6 
From #locations l inner join orders_all (nolock) t1  on t1.location = l.location
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date >= DATEADD(dd, 140, DATEDIFF(dd, 0,getdate()))
and t4.allocation_date > getdate() 
-- and t2.location in (Select * From #locations) 
and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no) t /*  */  on a.part_no = t.part_no                            
                          
                             
IF(OBJECT_ID('tempdb.dbo.#tbAvend') is not null)                          
drop table #tbAvend                        
Select a.*, (ISNULL(on_hand,0) - ISNULL(alloc,0))avend                        
Into #tbAvend 
From #tbAlloc a
           
                          
IF(OBJECT_ID('tempdb.dbo.#tbAv4end') is not null)                          
drop table #tbAv4end                        
Select a.*, (ISNULL(avend,0) - (4*ISNULL(e12_wu,0)) + ISNULL(nalloc1,0)+ ISNULL(alloc1,0)-ISNULL(FO1,0))av4end                        
Into #tbAv4end 
From #tbAvend a  

                    
IF(OBJECT_ID('tempdb.dbo.#tbAv8end') is not null)                          
drop table #tbAv8end
Select a.*, (ISNULL(av4end,0) - (4*ISNULL(e12_wu,0)) + ISNULL(nalloc2,0)+ ISNULL(alloc2,0)-ISNULL(FO2,0) )av8end
Into #tbAv8end From #tbAv4end a                        
                        
                        
IF(OBJECT_ID('tempdb.dbo.#tbAv12end') is not null)                          
drop table #tbAv12end                      
Select a.*, (ISNULL(av8end,0) - (4*ISNULL(e12_wu,0)) + ISNULL(nalloc3,0)+ ISNULL(alloc3,0)-ISNULL(FO3,0))av12end                        
Into #tbAv12end From #tbAv8end a                        
                        
                        
IF(OBJECT_ID('tempdb.dbo.#tbAv16end') is not null)                          
drop table #tbAv16end                        
Select a.*, (ISNULL(av12end,0) - (4*ISNULL(e12_wu,0)) + ISNULL(nalloc4,0)+ ISNULL(alloc4,0)-ISNULL(FO4,0))av16end                        
Into #tbAv16end From #tbAv12end a                        
                        
                        
IF(OBJECT_ID('tempdb.dbo.#tbAv20end') is not null)                          
drop table #tbAv20end                        
Select a.*, (ISNULL(av16end,0) - (4*ISNULL(e12_wu,0)) + ISNULL(nalloc5,0)+ ISNULL(alloc5,0)-ISNULL(FO5,0) )av20end                        
Into #tbAv20end From #tbAv16end a                        
                        
                        
IF(OBJECT_ID('tempdb.dbo.#tbAv24end') is not null)                          
drop table #tbAv24end                     
Select a.*, (ISNULL(av20end,0) - (4*ISNULL(e12_wu,0)) + ISNULL(nalloc6,0)+ ISNULL(alloc6,0)-ISNULL(FO6,0))av24end, 1 MOQ                        
Into #tbAv24end From #tbAv20end a                        
                      
            
Insert Into DPR_report (part_no,Reserver_Level,POM_date,e4_WU,e12_WU,e26_WU,e52_WU,                                        
s4_WU,s12_WU,s26_WU,s52_WU,on_hand,BackOrder,Allocated, SA_Allocated,        -- SA_Allocated is actually Available to Promise                               
Non_Allocated_PO,Allocated_PO,Future_Orders,                                        
Non_Allocated_PO2,Allocated_PO2,Future_Orders2,                                        
Non_Allocated_PO3,Allocated_PO3,Future_Orders3,                                        
Non_Allocated_PO4,Allocated_PO4,Future_Orders4,                                        
Non_Allocated_PO5,Allocated_PO5,Future_Orders5,                                      
Non_Allocated_PO6,Allocated_PO6,Future_Orders6,                                      
avend,av4end,av8end,av12end,av16end,av20end,av24end,                                    
style,collection,vendor,moq,rr1,rr3,                                    
status, status_description,
 release_date,lead_time,location, type_code                                  
)                           
Select                         
part_no,RL,POM,e4_wu,e12_wu,e26_wu,e52_wu,                                        
s4_wu,s12_wu,s26_wu,s52_wu,on_hand,bo, alloc, sa_allocated,                                       
ISNULL(alloc1,0),ISNULL(nalloc1,0),FO1,             
ISNULL(alloc2,0),ISNULL(nalloc2,0),FO2,                                        
ISNULL(alloc3,0),ISNULL(nalloc3,0),FO3,                                        
ISNULL(alloc4,0),ISNULL(nalloc4,0),FO4,                                        
ISNULL(alloc5,0),ISNULL(nalloc5,0),FO5,                                      
ISNULL(alloc6,0),ISNULL(nalloc6,0),FO6,                                     
avend,av4end,av8end,av12end,av16end,av20end,av24end,                                    
style,collection,vendor,moq,rr1,rr3,                                    
status, case when status=0 then 'Active' else 'Inactive' end as status_description,
rd,lt,@locationName, type_code                       
From #tbAv24end
order by collection, part_no
                    

SET @ctrl = @ctrl + 1                        
END

DELETE FROM DPR_report
where location not in ('ALL')
and e4_WU =0
and e12_WU =0
and e26_WU =0
and e52_WU =0
and S4_WU =0
and S12_WU =0
and S26_WU =0
and S52_WU =0
and On_Hand =0
and BackOrder IS null
and Allocated =0
and Non_Allocated_PO =0
and Allocated_PO =0
and Future_Orders =0
and Non_Allocated_PO2 =0
and Allocated_PO2 =0
and Future_Orders2 =0
and Non_Allocated_PO3 =0
and Allocated_PO3 =0
and Future_Orders3 =0
and Non_Allocated_PO4 =0
and Allocated_PO4 =0
and Future_Orders4 =0
and Non_Allocated_PO5 =0
and Allocated_PO5 =0
and Future_Orders5 =0
and Non_Allocated_PO6 =0
and Allocated_PO6 =0
and Future_Orders6 =0
and avend =0
and av4end =0
and av8end =0
and av12end =0
and av16end =0
and av20end =0
and av24end =0

delete from dpr_report where dpr_report.location = '001' and dpr_report.part_no in (
select t1.part_no
FROM DPR_report T1
join inv_master_add t2 on t1.part_no=t2.part_no
where location in ('001') and t2.field_32='Retail' and t1.part_no like 'ME%'
and e4_WU =0
and e12_WU =0
and e26_WU =0
and e52_WU =0
and S4_WU =0
and S12_WU =0
and S26_WU =0
and S52_WU =0
and On_Hand =0
and BackOrder IS null
and Allocated =0
and Non_Allocated_PO =0
and Allocated_PO =0
and Future_Orders =0
and Non_Allocated_PO2 =0
and Allocated_PO2 =0
and Future_Orders2 =0
and Non_Allocated_PO3 =0
and Allocated_PO3 =0
and Future_Orders3 =0
and Non_Allocated_PO4 =0
and Allocated_PO4 =0
and Future_Orders4 =0
and Non_Allocated_PO5 =0
and Allocated_PO5 =0
and Future_Orders5 =0
and Non_Allocated_PO6 =0
and Allocated_PO6 =0
and Future_Orders6 =0
and avend =0
and av4end =0
and av8end =0
and av12end =0
and av16end =0
and av20end =0
and av24end =0)

DELETE FROM DPR_report  WHERE part_no in (select part_no from inv_master (NOLOCK) where void = 'v')




GO
GRANT EXECUTE ON  [dbo].[CVO_dpr_bi] TO [public]
GO
