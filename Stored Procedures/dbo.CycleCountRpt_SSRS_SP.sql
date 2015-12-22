SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<elabarbera>
-- Create date: <Dec 2013>
-- Description:	<Cycle Counts and Inventory Adjustments>
-- EXEC CycleCountRpt_SSRS_SP '1/1/2014','3/25/2014'
-- =============================================
CREATE PROCEDURE [dbo].[CycleCountRpt_SSRS_SP]

 @DateFrom datetime,
 @DateTo datetime

AS
BEGIN
	SET NOCOUNT ON;
	SET QUOTED_IDENTIFIER OFF;
	SET ANSI_NULLS ON

--DECLARE @DateFrom datetime
--DECLARE @DateTo datetime
--SET @DateFrom = '1/13/2014'
--SET @DateTo = '3/25/2014'
	SET @dateTo=dateadd(second,-1,@dateTo)
	SET @dateTo=dateadd(day,1,@dateTo)	

--  select @dateFrom 'FROM', @dateTo 'TO'

-- BELOW is the Start of pulling the cyclecounts  (Table1)
IF(OBJECT_ID('tempdb.dbo.#DETCC') is not null)
drop table dbo.#DETCC
select location, t3.category Coll, t2.field_2 AS Model, t1.part_no, UPPER(Left(bin_no,1)) Bin_Type, bin_no, update_user as userid,
count_date, update_date, 
cast(adm_actual_qty as decimal(8,0)) adm_actual_qty,
0 as count_qty,
cast(post_qty as decimal(8,0)) post_qty, cast((post_qty-adm_actual_qty) as decimal(8,0)) as final,
'CycCnt' Source,'CycleCount' InvAdjCode,0 as NumCounts
INTO #DETCC
from tdc_cyc_count_log t1 (nolock)
join inv_master_add t2 (nolock) on t1.part_no=t2.part_no
join inv_master t3 (nolock) on  t1.part_no=t3.part_no
AND count_date between @DateFrom and @DateTo
AND TYPE_CODE IN ('SUN','FRAME')
--  SELECT * from #DETCC where location <>'001'

--  BELOW is the start of finding the ADHOC (Table2)
IF(OBJECT_ID('tempdb.dbo.#CountADJ') is not null)
drop table dbo.#CountADJ
select t1.location_from as location, t1.issue_date as tran_date, t1.issue_no as tran_no, t1.part_no, 
isnull(t4.bin_no,'')bin_no, 
t1.who_entered as userid, (t1.qty*t1.direction) as quantity, 
 case IsNULL(reason_code,'') When '' then code when NULL then code else reason_code End as InvAdjCode,
--isnull(t1.reason_code, isnull(t1.code,'')) as InvAdjCode,
 0 as NumCounts
INTO #CountADJ
from issues t1 (nolock)
join lot_bin_tran t4 (nolock) on t1.issue_no=t4.tran_no 
left outer join tdc_log t2 (nolock) on t2.tran_no=cast(t1.issue_no as varchar(16)) and t2.tran_ext = 0
JOIN INV_MASTER T3 (NOLOCK) ON T3.PART_NO=T1.PART_NO
where issue_date between @DateFrom and @DateTo AND code <> 'xfr' AND TYPE_CODE IN ('SUN','FRAME')

-- pull all data Table 1
IF(OBJECT_ID('tempdb.dbo.#CycleFinalCnts') is not null)
drop table dbo.#CycleFinalCnts
select * into #CycleFinalCnts FROM
(select * from #detcc
	union all
-- pull all data Table2
select location, t3.category Coll, field_2 Model, t1.part_no, UPPER(left(bin_no,1)) Bin_Type, bin_no, userid, '' as count_date, tran_date as update_date, 
'0' adm_actual_qty, '0' COUNT_QTY, '0' post_qty, cast(quantity as decimal(8,0)) as final, 'AdHoc' Source, InvAdjCode, NumCounts 
from #COUNTADJ t1 
join inv_master_add t2 (nolock) on t1.part_no=t2.part_no
join inv_master t3 (nolock) on  t1.part_no=t3.part_no
) as tmp
-- select * from #CycleFinalCnts       order by update_date, part_no 
UPDATE #CycleFinalCnts SET userid = REPLACE (userid,'CVOPTICAL\','')

-- -- --  -- -- --  -- -- --  -- -- --  -- -- --  -- -- --  -- -- --  -- -- --  
select *, CONVERT(VARCHAR(10),update_date,101) AS DateOnly, (CONVERT(CHAR(4), update_date, 100) + CONVERT(CHAR(4), update_date, 120)) as MthYr
from #CycleFinalCnts
order by update_date asc, coll, model, part_no

END
GO
