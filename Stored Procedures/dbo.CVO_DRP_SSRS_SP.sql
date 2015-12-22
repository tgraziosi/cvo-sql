SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		ELABARBERA
-- Create date: 5/8/2013
-- Description:	DRP NEW REBUILD
-- EXEC CVO_DRP_SSRS_SP 
-- =============================================
CREATE PROCEDURE [dbo].[CVO_DRP_SSRS_SP] 
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @COLLECTION VARCHAR(30)
DECLARE @STYLE VARCHAR(30)
DECLARE @LOC VARCHAR(30)
SET @COLLECTION = 'BCBG'
SET @STYLE = 'ADALINA'
SET @LOC  = '001'

DECLARE @TodayDayOfWeek INT                                        
DECLARE @EndOfPrevWeek DateTime                                        
DECLARE @StartOfPrevWeek4 DateTime                                        
DECLARE @StartOfPrevWeek12 DateTime                                        
DECLARE @StartOfPrevWeek26 DateTime                                        
DECLARE @StartOfPrevWeek52 DateTime                                         
DECLARE @location tinyint                        
DECLARE @ctrl int                              
DECLARE @locationName varchar(80) 

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

IF(OBJECT_ID('tempdb.dbo.#weeks') is not null)
drop table #weeks 
CREATE TABLE #weeks
(	startDate smalldatetime,
	endDate smalldatetime,
	week tinyint	)

Insert Into #weeks Values(@StartOfPrevWeek4, @EndOfPrevWeek, 4)
Insert Into #weeks Values(@StartOfPrevWeek12, @EndOfPrevWeek, 12)
Insert Into #weeks Values(@StartOfPrevWeek26, @EndOfPrevWeek, 26)
Insert Into #weeks Values(@StartOfPrevWeek52, @EndOfPrevWeek, 52)


IF(OBJECT_ID('tempdb.dbo.#weeks2') is not null)
drop table #weeks2
CREATE TABLE #weeks2
(	startDate smalldatetime,
	endDate smalldatetime,
	week tinyint	)

Insert Into #weeks2 Values(@StartOfPrevWeek4, @EndOfPrevWeek, 4)
Insert Into #weeks2 Values(@StartOfPrevWeek12, DateAdd(d,-1,@StartOfPrevWeek4), 12)
Insert Into #weeks2 Values(@StartOfPrevWeek26, DateAdd(d,-1,@StartOfPrevWeek12), 26)
Insert Into #weeks2 Values(@StartOfPrevWeek52, DateAdd(d,-1,@StartOfPrevWeek26), 52)

-- Get Historical Sales Data  
IF(OBJECT_ID('tempdb.dbo.#History') is not null)                          
drop table #History
select t1.part_no, 
CASE WHEN T1.QSALES <> 0 THEN 'I' ELSE 'C' END AS Type,
(t1.qsales + -1*t1.qreturns) Shipped,
yyyymmdd as date_shipped,
location,
(select week from #weeks2 t2 WHERE t1.yyyymmdd between startdate and enddate) Week
INTO #History
FROM cvo_sbm_details (nolock) T1
WHERE yyyymmdd >= (Select MIN(startdate) From #weeks) and location in (select * from DPR_locations)
--  select * from #HISTORY 

-- SUM up weekly by part_no & location
IF(OBJECT_ID('tempdb.dbo.#ShippedTotal') is not null)                          
drop table #ShippedTotal 
Select a.part_no, a.location, b.e4_wu, c.e12_wu, d.e26_wu, e.e52_wu
Into #ShippedTotal
From (Select distinct part_no, location From #History) a left join 
(Select part_no, location, CAST(SUM(ISNULL(Shipped,0))/4 as int) e4_wu From #History Where week = 4 Group By part_no, location) b on a.part_no = b.part_no and a.location = b.location
left join 
(Select part_no, location, CAST(SUM(ISNULL(Shipped,0))/12 as int) e12_wu From #History Where week in (4, 12) Group By part_no, location) c on a.part_no = c.part_no and a.location = c.location
left join 
(Select part_no, location, CAST(SUM(ISNULL(Shipped,0))/26 as int)e26_wu From #History Where week  in (4, 12, 26) Group By part_no, location) d on a.part_no = d.part_no and a.location = d.location
left join 
(Select part_no, location, CAST(SUM(ISNULL(Shipped,0))/52 as int)e52_wu From #History Where week in (4, 12, 26, 52) Group By part_no, location) e on a.part_no = e.part_no and a.location = e.location

-- PULL Part_no Information
IF(OBJECT_ID('tempdb.dbo.#data') is not null)  
drop table #data
select distinct t1.part_no, t1.location, category as Collection, field_2 as Style, field_26 as ReleaseDate, field_28 as POM, ISNULL(category_1,'') as Watch,
CASE WHEN (FIELD_26 <=GETDATE() AND FIELD_28 IS NULL) OR (FIELD_26 <=GETDATE() AND FIELD_28 >GETDATE()) THEN 'Active' else 'InActive' end as [Status],
 Vendor, LeadTime,
 Type_code,
--CASE When Type_code in ('SUN','FRAME','BRUIT') Then 'Frame/Sun' Else Type_code end As Type_code,
cmdty_code Material, category_2 Gender, 
(select max(lead_time) from inv_list il (nolock) where il.part_no=t1.part_no) PartLeadTime,
t1.std_cost FCost, (t1.std_cost + t1.Std_ovhd_dolrs + t1.std_util_dolrs) LCost 
INTO #data
FROM inv_list t1 (nolock)
join inv_master t2 (nolock) on t1.part_no=t2.part_no
join inv_master_add t3 (nolock) on t1.part_no=t3.part_no
left join (Select vendor_code, MAX(ISNULL(lead_time,0))LeadTime From apmaster_all (nolock) Group By vendor_code) T4 on t2.vendor = T4.vendor_code         
where t1.location in (select * from DPR_locations) and t2.void <> 'v' and t1.void <> 'v'
order by Category, field_2, t1.part_no

-- PULL BO
IF(OBJECT_ID('tempdb.dbo.#BO_data') is not null)  
drop table #BO_data
Select t1.part_no, t1.location, (SUM(ISNULL(ordered,0))-sum(isnull(qty,0)))bo
INTO #BO_data
From ord_list t1 (nolock) inner join orders_all t2 (nolock) on t1.order_no=t2.order_no and t1.order_ext=t2.ext                                  
inner join cvo_orders_all t3 (nolock) on t2.order_no=t3.order_no and t2.ext=t3.ext                                  
full outer join tdc_soft_alloc_tbl t4 (nolock) on t4.order_no=t1.order_no and t4.order_ext=t1.order_ext  and t4.line_no=t1.line_no   
Where t1.location in (select * from DPR_locations) and t2.type='I' and t2.ext<>0 and t2.status not in ('T','V')
Group By t1.part_no, t1.location

 -- Pull data for RR
IF(OBJECT_ID('tempdb.dbo.#TBRR_data') is not null)  
drop table #TBRR_data
Select t1.part_no, t1.location, ordered, cr_ordered,type, 
CASE 
When t2.date_shipped between dateadd(m,-1,getdate()) and getdate() Then 1
Else 3
End Month
Into #TBRR_data
From ord_list t1 (nolock) 
inner join orders_all t2 (nolock) on t1.order_no=t2.order_no and t1.order_ext=t2.ext                                  
inner join cvo_orders_all t3 (nolock) on t2.order_no=t3.order_no and t2.ext=t3.ext
Where t2.date_shipped BETWEEN dateadd(m,-3,getdate()) and getdate()
and t2.ext=0 and t2.status='T'
and t1.location in (select * from DPR_Locations)

-- RR 1 & 3
IF(OBJECT_ID('tempdb.dbo.#TBRR') is not null)                          
drop table #TBRR
Select ISNULL(a.part_no, b.part_no)part_no, ISNULL(a.location, b.location)location, 
cast(ISNULL(sum(ISNULL(a.CR_ordered,0) / (ISNULL(a.ordered,0) + .0001)),0) as float) RR1, 
cast(ISNULL(sum(ISNULL(b.CR_ordered,0) / (ISNULL(b.ordered,0) + .0001)),0) as float) RR3
Into #TBRR
From (Select part_no, LOCATION, SUM(cast(ISNULL(ordered,0)as float))ordered, SUM(ISNULL(cast(CR_ordered as float),0))CR_ordered  FROM #TBRR_DATA Where [MONTH] = 1 Group By part_no, LOCATION) a 
full join
(Select part_no, LOCATION, SUM(cast(ISNULL(ordered,0)as float))ordered, SUM(ISNULL(cast(CR_ordered as float),0))CR_ordered  FROM #TBRR_DATA Where [MONTH] = 3 Group By part_no, LOCATION) b  on a.part_no = b.part_no AND a.location=b.location
group by a.part_no, a.location,b.part_no, b.location

update #TBRR set RR1 = 1.00  WHERE RR1 > 1
update #TBRR set RR3 = 1.00  WHERE RR3 > 1

-- Pull RL, In_Stock (on_hand), SoftAllocated (SOF), Avail to Promise
IF(OBJECT_ID('tempdb.dbo.#ItemAvl1') is not null)                          
drop table #ItemAvl1
Select t1.part_no, t1.location, MAX(ISNULL(ReserveQty,0))RL, 
SUM(ISNULL(in_stock,0))on_hand,
sum(ISNULL(QTY_AVL,0))AvlToProm,
( sum(ISNULL(Allocated,0))+sum(ISNULL(SOF,0)) )Alloc
Into #ItemAvl1
From cvo_item_avail_vw (nolock) T1
Where t1.location in (select * from DPR_Locations)
Group By t1.part_no, t1.location

-- Pull QC ON HAND
IF(OBJECT_ID('tempdb.dbo.#QCOH') is not null)                          
drop table #QCOH
Select part_no, location, SUM(ISNULL(qty,0))QCOH
Into #QCOH
From lot_Bin_recv (nolock) T1
where qc_flag ='y'
and location in (Select * From DPR_Locations)
Group By part_no, location

-- Add in QC to On_hand
IF(OBJECT_ID('tempdb.dbo.#ItemAvl') is not null)                          
drop table #ItemAvl
select t1.part_no, t1.location, RL, ( t1.on_hand + sum(isnull(QCOH,0)) ) on_hand,
 AvlToProm, Alloc
into #ItemAvl
from #ItemAvl1 t1
left join #QCOH t2 on t1.part_no=t2.part_no and t1.location=t2.location
group by t1.part_no, t1.location, RL, on_hand, AvlToProm, Alloc

-- PULL EVERYTHING TOGETHER
IF(OBJECT_ID('tempdb.dbo.#AllData') is not null)                          
drop table #AllData
select a.*, isnull(b.bo,0)BO, round(isnull(c.RR1,0),2)RR1, round(isnull(c.RR3,0),2)RR3, isnull(d.e4_wu,0)e4_wu, isnull(d.e12_wu,0)e12_wu,isnull(d.e26_wu,0)e26_wu,isnull(d.e52_wu,0)e52_wu, ISNULL(e.RL,0)RL, ISNULL(e.on_hand,0)on_hand, ISNULL(E.AvlToProm,0)AvlToProm, ISNULL(e.Alloc,0)Alloc
INTO #AllData
from #data a
left outer join #bo_data b on a.part_no=b.part_no and a.location=b.location
left outer join #TBRR c on a.part_no=c.part_no and a.location=c.location
left outer join #ShippedTotal d on a.part_no=d.part_no and a.location=d.location
left outer join #ItemAvl e on a.part_no=e.part_no and a.location=e.location
order by location, collection, style, part_no

-- Add in Future  Alloc  &  PO's
IF(OBJECT_ID('tempdb.dbo.#Future') is not null)                          
drop table #Future                           
Select a.*, 
ISNULL(c.alloc1,0)alloc1, (ISNULL(d.nalloc1,0))nalloc1, ISNULL(e.FO1,0)FO1, 
ISNULL(f.alloc2,0)alloc2, (ISNULL(g.nalloc2,0))nalloc2, ISNULL(h.FO2,0)FO2, 
ISNULL(i.alloc3,0)alloc3, (ISNULL(j.nalloc3,0))nalloc3, ISNULL(k.FO3,0)FO3,
ISNULL(l.alloc4,0)alloc4, (ISNULL(m.nalloc4,0))nalloc4, ISNULL(n.FO4,0)FO4,
ISNULL(o.alloc5,0)alloc5, (ISNULL(p.nalloc5,0))nalloc5, ISNULL(q.FO5,0)FO5,
ISNULL(r.alloc6,0)alloc6, (ISNULL(s.nalloc6,0))nalloc6, ISNULL(t.FO6,0)FO6                          
Into #Future From #Alldata a            

-- BUILD Future
left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc1 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                         
and t1.location in (Select * From DPR_Locations)                       
and t3.inhouse_date between dateadd(yy,-1,getdate()) and DATEADD(S,-1,DATEADD(dd, 28, DATEDIFF(dd, 0,getdate())))
and po_type <> 'xx' Group By t1.part_no, t1.location) c /*  */ on a.part_no = c.part_no and a.location=c.location

left join          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc1 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                        
and t1.location in (Select * From DPR_Locations)                       
and t3.inhouse_date between dateadd(yy,-1,getdate()) and DATEADD(S,-1,DATEADD(dd, 28, DATEDIFF(dd, 0,getdate()))) and po_type = 'xx' Group By t1.part_no, t1.location) d  /*  */ on a.part_no = d.part_no and a.location=d.location

left join                          
(Select t2.part_no, t2.location, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO1 From orders_all (nolock) t1                                  
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext                     
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date between '1/1/2012' and DATEADD(S,-1,DATEADD(dd, 28, DATEDIFF(dd, 0,getdate())))
and t4.allocation_date > getdate() 
and t2.location in (Select * From DPR_Locations) and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no,t2.location) e  /*  */ on a.part_no = e.part_no and a.location=e.location

--2                        
left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc2 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                        
and t1.location in (Select * From DPR_Locations)                      
and t3.inhouse_date between DATEADD(dd, 28, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 56, DATEDIFF(dd, 0,getdate()))) and po_type <> 'xx' Group By t1.part_no, t1.location) f /*  */  on a.part_no = f.part_no and a.location = f.location

left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc2 from pur_list (nolock) t1                              
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                        
and t1.location in (Select * From DPR_Locations)                      
and t3.inhouse_date between DATEADD(dd, 28, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 56, DATEDIFF(dd, 0,getdate()))) and po_type = 'xx' Group By t1.part_no, t1.location) g /*  */  on a.part_no = g.part_no and a.location=g.location

left join                          
(Select t2.part_no, t2.location, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO2 From orders_all (nolock) t1                                  
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date between DATEADD(dd, 28, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 56, DATEDIFF(dd, 0,getdate())))
and t4.allocation_date > getdate() 
and t2.location in (Select * From DPR_Locations) and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no, t2.location) h /*  */  on a.part_no = h.part_no and a.location = h.location


--3                        
left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc3 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                         
and t1.location in (Select * From DPR_Locations)                      
and t3.inhouse_date between DATEADD(dd, 56, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 84, DATEDIFF(dd, 0,getdate()))) and po_type <> 'xx' Group By t1.part_no, t1.location) i /*  */  on a.part_no = i.part_no and a.location = i.location

left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc3 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                       
and t1.location in (Select * From DPR_Locations)                      
and t3.inhouse_date between DATEADD(dd, 56, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 84, DATEDIFF(dd, 0,getdate()))) and po_type = 'xx' Group By t1.part_no, t1.location) j /*  */  on a.part_no = j.part_no and a.location = j.location

left join                          
(Select t2.part_no, t2.location, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO3 From orders_all (nolock) t1                                  
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date between DATEADD(dd, 56, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 84, DATEDIFF(dd, 0,getdate())))
and t4.allocation_date > getdate() 
and t2.location in (Select * From DPR_Locations)  and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no, t2.location) k /*  */  on a.part_no = k.part_no and a.location = k.location


--4                        
left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc4 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                           
and t1.location in (Select * From DPR_Locations)                      
and t3.inhouse_date between DATEADD(dd, 84, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 112, DATEDIFF(dd, 0,getdate())))  and po_type <> 'xx' Group By t1.part_no, t1.location) l /*  */  on a.part_no = l.part_no and a.location = l.location

left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc4 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                       
and t1.location in (Select * From DPR_Locations)                      
and t3.inhouse_date between DATEADD(dd, 84, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 112, DATEDIFF(dd, 0,getdate())))  and po_type = 'xx' Group By t1.part_no, t1.location) m /*  */  on a.part_no = m.part_no and a.location = m.location

left join                          
(Select t2.part_no, t2.location, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO4 From orders_all (nolock) t1                        
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date between DATEADD(dd, 84, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 112, DATEDIFF(dd, 0,getdate()))) 
and t4.allocation_date > getdate() 
and t2.location in (Select * From DPR_Locations)  and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no, t2.location) n /*  */  on a.part_no = n.part_no and a.location = n.location


--5                        
left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc5 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                                             
and t1.location in (Select * From DPR_Locations)                      
and t3.inhouse_date between DATEADD(dd, 112, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 140, DATEDIFF(dd, 0,getdate()))) and po_type <> 'xx' Group By t1.part_no, t1.location) o /*  */  on a.part_no = o.part_no and a.location = o.location

left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc5 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                                              
and t1.location in (Select * From DPR_Locations)                      
and t3.inhouse_date between DATEADD(dd, 112, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 140, DATEDIFF(dd, 0,getdate()))) and po_type = 'xx' Group By t1.part_no, t1.location) p /*  */  on a.part_no = p.part_no and a.location = p.location 

left join                          
(Select t2.part_no, t2.location, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO5 From orders_all (nolock) t1                                  
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date between DATEADD(dd, 112, DATEDIFF(dd, 0,getdate())) and DATEADD(S,-1,DATEADD(dd, 140, DATEDIFF(dd, 0,getdate())))
and t4.allocation_date > getdate() 
and t2.location in (Select * From DPR_Locations)  and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no, t2.location) q /*  */  on a.part_no = q.part_no and a.location = q.location 


--6                        
left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))alloc6 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                                             
and t1.location in (Select * From DPR_Locations)                      
and t3.inhouse_date >= DATEADD(dd, 140, DATEDIFF(dd, 0,getdate()))
and po_type <> 'xx' Group By t1.part_no, t1.location) r /*  */  on a.part_no = r.part_no and a.location = r.location 

left join                          
(select t1.part_no, t1.location, SUM(ISNULL(qty_ordered,0)-ISNULL(qty_received,0))nalloc6 from pur_list (nolock) t1                                  
join purchase (nolock) t2 on t1.po_no=t2.po_no
	join releases (nolock) t3 on t3.PO_line=t1.line and t3.po_no=t1.po_no
where t2.status IN ('H','O') AND t1.status='O'                                            
and t1.location in (Select * From DPR_Locations)                      
and t3.inhouse_date >= DATEADD(dd, 140, DATEDIFF(dd, 0,getdate()))
and po_type = 'xx' Group By t1.part_no, t1.location) s on a.part_no = s.part_no and a.location = s.location 

left join                          
(Select t2.part_no, t2.location, SUM(t2.ordered) - SUM(ISNULL(t3.qty,0))FO6 From orders_all (nolock) t1                                  
join ord_list (nolock) t2 on t1.order_no=t2.order_no and t1.ext=t2.order_ext
left join (Select order_no, location, line_no, SUM(qty)qty, part_no from tdc_soft_alloc_tbl (nolock) Group By part_no, order_no, line_no ,location) t3 on t2.order_no = t3.order_no and t2.location = t3.location and t2.part_no = t3.part_no and t2.line_no = t3.line_no
join cvo_orders_all t4 (nolock) on t1.order_no=t4.order_no and t1.ext=t4.ext
where t1.req_ship_date >= DATEADD(dd, 140, DATEDIFF(dd, 0,getdate()))
and t4.allocation_date > getdate() 
and t2.location in (Select * From DPR_Locations) and t1.ext=0            
and t1.status not in ('T','V')  Group By t2.part_no, t2.location) t /*  */  on a.part_no = t.part_no and a.location = t.location                       

IF(OBJECT_ID('tempdb.dbo.#tbAvend') is not null)                          
drop table #tbAvend                        
Select a.*, (ISNULL(on_hand,0) - ISNULL(alloc,0))avend                        
Into #tbAvend 
From #Future a
                          
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

IF(OBJECT_ID('dbo.DRP_Data') is not null)                          
drop table DRP_Data
select * INTO DRP_Data FROM (
select * from  #tbAv24end
	UNION ALL
select DISTINCT
part_no, 'ALL' as location, Collection, Style, ReleaseDate, POM, Watch, Status, Vendor, LeadTime, Type_code, 
Material, Gender, PartLeadTime, 
(select Max(FCost) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )FCost,
(select Max(LCost) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )LCost,
(select sum(isnull(BO,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )BO,
(select sum(isnull(RR1,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )RR1,
(select sum(isnull(RR3,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )RR3,
(select sum(isnull(e4_wu,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )e4_wu,
(select sum(isnull(e12_wu,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )e12_wu,
(select sum(isnull(e26_wu,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )e26_wu,
(select sum(isnull(e52_wu,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )e52_wu,
(select sum(isnull(RL,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )RL,
(select sum(isnull(on_hand,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )on_hand,
(select sum(isnull(AvlToProm,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )AvlToProm,
(select sum(isnull(Alloc,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )Alloc,
(select sum(isnull(alloc1,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )alloc1,
(select sum(isnull(nalloc1,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )nalloc1,
(select sum(isnull(FO1,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )FO1,
(select sum(isnull(alloc2,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )alloc2,
(select sum(isnull(Nalloc2,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )nalloc2,
(select sum(isnull(FO2,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )FO2,
(select sum(isnull(alloc3,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )alloc3,
(select sum(isnull(Nalloc3,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )nalloc3,
(select sum(isnull(FO3,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )FO3,
(select sum(isnull(alloc4,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )alloc4,
(select sum(isnull(Nalloc4,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )nalloc4,
(select sum(isnull(FO4,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )FO4,
(select sum(isnull(alloc5,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )alloc5,
(select sum(isnull(Nalloc5,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )nalloc5,
(select sum(isnull(FO5,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )FO5,
(select sum(isnull(alloc6,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )alloc6,
(select sum(isnull(nalloc6,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )nalloc6,
(select sum(isnull(FO6,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )FO6,
(select sum(isnull(avend,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )avend,
(select sum(isnull(av4end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )av4end,
(select sum(isnull(av8end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )av8end,
(select sum(isnull(av12end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )av12end,
(select sum(isnull(av16end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )av16end,
(select sum(isnull(av20end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )av20end,
(select sum(isnull(av24end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location not in ('all','key accounts') )av24end,
MOQ
from #tbAv24end t1
where t1.location not in ('all','key accounts')
	UNION ALL
select DISTINCT
part_no, 'KEY ACCOUNTS' as location, Collection, Style, ReleaseDate, POM, Watch, Status, Vendor, LeadTime, Type_code, 
Material, Gender, PartLeadTime,
(select Max(FCost) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )FCost,
(select Max(LCost) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )LCost,
(select sum(isnull(BO,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )BO,
(select sum(isnull(RR1,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )RR1,
(select sum(isnull(RR3,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )RR3,
(select sum(isnull(e4_wu,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )e4_wu,
(select sum(isnull(e12_wu,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )e12_wu,
(select sum(isnull(e26_wu,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )e26_wu,
(select sum(isnull(e52_wu,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )e52_wu,
(select sum(isnull(RL,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )RL,
(select sum(isnull(on_hand,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )on_hand,
(select sum(isnull(AvlToProm,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )AvlToProm,
(select sum(isnull(Alloc,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )Alloc,
(select sum(isnull(alloc1,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )alloc1,
(select sum(isnull(nalloc1,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )nalloc1,
(select sum(isnull(FO1,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )FO1,
(select sum(isnull(alloc2,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )alloc2,
(select sum(isnull(Nalloc2,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )nalloc2,
(select sum(isnull(FO2,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )FO2,
(select sum(isnull(alloc3,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )alloc3,
(select sum(isnull(Nalloc3,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )nalloc3,
(select sum(isnull(FO3,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )FO3,
(select sum(isnull(alloc4,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )alloc4,
(select sum(isnull(Nalloc4,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )nalloc4,
(select sum(isnull(FO4,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )FO4,
(select sum(isnull(alloc5,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )alloc5,
(select sum(isnull(Nalloc5,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )nalloc5,
(select sum(isnull(FO5,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )FO5,
(select sum(isnull(alloc6,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )alloc6,
(select sum(isnull(nalloc6,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )nalloc6,
(select sum(isnull(FO6,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )FO6,
(select sum(isnull(avend,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )avend,
(select sum(isnull(av4end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )av4end,
(select sum(isnull(av8end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )av8end,
(select sum(isnull(av12end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )av12end,
(select sum(isnull(av16end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )av16end,
(select sum(isnull(av20end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )av20end,
(select sum(isnull(av24end,0)) from #tbAv24end t2 where t1.part_no=t2.part_no and t2.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') )av24end,
MOQ
from #tbAv24end t1
where t1.location IN ('Kaiser','Luxottica','Centennial','Insight','Costco','Nordstrom') ) AS TMP

DELETE FROM DRP_Data
where location in ('costco', 'insight', 'centennial', 'kaiser', 'luxottica', 'Astucci', 'Liberty', 'ME Retail', 'U.S.Vision', 'KEY Accounts','Nordstrom')
and e4_WU =0
and e12_WU =0
and e26_WU =0
and e52_WU =0
and On_Hand =0
and BO =0
and AvlToProm =0
and Alloc=0
and Nalloc2 =0
and Alloc2 =0
and FO2 =0
and Nalloc3 =0
and Alloc3 =0
and FO3 =0
and Nalloc4 =0
and Alloc4 =0
and FO4 =0
and Nalloc5 =0
and Alloc5 =0
and FO5 =0
and Nalloc6 =0
and Alloc6 =0
and FO6 =0
and avend =0
and av4end =0
and av8end =0
and av12end =0
and av16end =0
and av20end =0
and av24end =0

DELETE FROM DRP_Data
where type_code ='Bruit' 
and e4_WU =0
and e12_WU =0
and e26_WU =0
and e52_WU =0
and On_Hand =0
and BO =0
and AvlToProm =0
and Alloc=0
and Nalloc2 =0
and Alloc2 =0
and FO2 =0
and Nalloc3 =0
and Alloc3 =0
and FO3 =0
and Nalloc4 =0
and Alloc4 =0
and FO4 =0
and Nalloc5 =0
and Alloc5 =0
and FO5 =0
and Nalloc6 =0
and Alloc6 =0
and FO6 =0
and avend =0
and av4end =0
and av8end =0
and av12end =0
and av16end =0
and av20end =0
and av24end =0


IF(OBJECT_ID('tempdb.dbo.#List1') is not null)  drop table #List1
select part_no, location, collection, style, ReleaseDate, LeadTime, PartLeadTime, AvlToProm, e12_wu, NAlloc1, NAlloc2, NAlloc3, NAlloc4, NAlloc5, NAlloc6, 
Av4End as Av4End1,		Av8End as Av8End2,		Av12End as Av12End3,		Av16End as Av16End4,		Av20End as Av20End5,		Av24End as Av24End6
INTO #List1
from DRP_Data
where ReleaseDate < getdate() and Type_code like  'Frame%' and location ='001'
AND (Nalloc1 <> 0 OR Nalloc2 <> 0 OR Nalloc3 <> 0 OR Nalloc4 <> 0 OR Nalloc5 <> 0 OR Nalloc6 <> 0 )
Order by Collection, Style

IF(OBJECT_ID('tempdb.dbo.#List2') is not null)  drop table #List2
select * INTO #List2 from (
-- Moved from 8Weeks to 12Weeks
select location, Collection, Style, part_no, Nalloc2, 'Nalloc2' as Period from #List1
where Nalloc2 <> 0 AND (Av8End2-NAlloc2)>0 AND  (Av12End3-NAlloc2)>0 
  UNION ALL
-- Moved from 12Weeks to 16Weeks
select location, Collection, Style, part_no, Nalloc3, 'Nalloc3' as Period  from #List1
where Nalloc3 <> 0 AND (Av12End3-NAlloc3)>0 AND  (Av16End4-NAlloc3)>0 
  UNION ALL
-- Moved from 16Weeks to 20Weeks
select location, Collection, Style, part_no, Nalloc4, 'Nalloc4' as Period  from #List1
where Nalloc4 <> 0 AND (Av16End4-NAlloc4)>0 AND  (Av20End5-NAlloc4)>0 
  UNION ALL
-- Moved from 20Weeks to 24Weeks
select location, Collection, Style, part_no, Nalloc5, 'Nalloc5' as Period  from #List1
where Nalloc5 <> 0 AND (Av20End5-NAlloc5)>0 AND  (Av24End6-NAlloc5)>0  ) tmp
Order by Period, Collection, Style

IF(OBJECT_ID('tempdb.dbo.#List3') is not null)  drop table #List3
select *,
(select TOP 1 ISNULL(Style,'') from #List2 T2 Where t1.location=t2.location and t1.collection=t2.collection and t1.style=t2.style Order By Period)POMoveStyle,
(select TOP 1 ISNULL(part_no,'') from #List2 T2 Where t1.location=t2.location and t1.part_no=t2.part_no Order by Period)POMovePartNo,
(select TOP 1 ISNULL(Period,'') from #List2 T2 Where t1.location=t2.location and t1.part_no=t2.part_no Order by Period)POMovePeriod
INTO #List3
 from DRP_DATA t1



/* -- set up real table cvo_vendor_moq instead
IF(OBJECT_ID('tempdb.dbo.#VendorMOQ') is not null)   drop table dbo.#VendorMOQ
Create Table dbo.#VendorMOQ (
VendorCode varchar(20),
MOQ varchar(200)
)
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('ACTGROU','100 Sku')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('AISUOPT','Metal - 150 / Acetate - 200')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('ATDESI','300 Order / 100 Sku')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('COUNTO','One Size Per Order 300; Two Sizes / 200 Per Size / 400 Order / 100 Color; Sun&Kids / 300 Order / 100 Color')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('COMOPT','100 Order')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('ELEOPT','100 Either Color or Size')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('FUKUSH','200 Order')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('GEM001','200 Order')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('GRACE','100 Sku')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('GREATDRA','200 Color')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('HI-TEC','200 Sku')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('HINDAR','300 Order / 100 Sku')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('WEN001','300 Order / 100 Sku')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('SKY001','300 Order / 100 Sku')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('IDEYES','300 Order')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('KAITAI','200 Size / 100 Color')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('MAZEN0','100 Order / 50 Sku')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('OUHAI','300 Order')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('PINOPT','200 Order / 500 Lillian, Mae, Miranda and Vivienne')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('RAYCHU','300 Order')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('SAMWON','100 Sku')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('SUNHIN','50 Sku')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('UNITED CRE','200 Order; Color 100')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('VISPRO','Order / 300 Metal / 300 Acetate; Sku / 50 Metal / 100 Acetate')
INSERT INTO #VendorMOQ (VendorCode, MOQ) VALUES ('KIL001','100 per SKU') -- 091614 - per tb request
*/

IF(OBJECT_ID('DRP_DATA') is not null)  drop table DRP_DATA
select t1.*,ISNULL(t2.MOQ_info,'')MOQ_tmp INTO DRP_DATA from #List3 t1
left outer join cvo_Vendor_MOQ t2 on t1.Vendor=t2.Vendor_Code


UPDATE DRP_DATA SET POMoveStyle = 'Y' where POMoveStyle  is not null
UPDATE DRP_DATA SET POMoveStyle = '' where POMoveStyle  is null

UPDATE DRP_DATA SET POMovePartNo = 'Y' where POMovePartNo  is not null
UPDATE DRP_DATA SET POMovePartNo = '' where POMovePartNo  is null

UPDATE DRP_DATA SET POMovePeriod = '' where POMovePeriod  is null


/*  code for testing
--133842
select * from DRP_DATA where part_no=  --where collection =@Coll   and Style = @Style   and location = @Loc

   where collection ='BCBG'
   and Style = '804'
   and location = '001'
   and Status = '1'  -- 1-Active / 0-Inactive
   and type_code = 'Frame/Sun'  -- Frame/Sun, Parts, CASE, CLIPS, OTHER, PATTERN, POP
   and vendor like '%%'
order by Collection, Style, part_no, Location
   
*/
END

GO
