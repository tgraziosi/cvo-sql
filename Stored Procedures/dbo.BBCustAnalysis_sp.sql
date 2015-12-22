SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 4/5/2013
-- Description:	Business Builder Customer Analysis
--  EXEC BBCustAnalysis_sp 2015
-- tag - 6/4/2015 - change sales table to cvo_sbm_details
-- =============================================
CREATE PROCEDURE [dbo].[BBCustAnalysis_sp]
	@Year int 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF(OBJECT_ID('tempdb.dbo.#BB1') is not null)  
drop table #BB1
SELECT progyear as Year, 
(SELECT TERRITORY_CODE from armaster AR2 (nolock) WHERE BB.MASTER_CUST_CODE=AR2.CUSTOMER_CODE and AR2.address_type=0)MTERR
, master_cust_code
, (SELECT ADDRESS_NAME from armaster AR2 WHERE BB.MASTER_CUST_CODE=AR2.CUSTOMER_CODE and AR2.address_type=0)MNAME
, territory_code as Terr
, cust_code
, ADDRESS_NAME AS NAME
, CITY
, STATE
, sum(goal1) Goal1
, sum(rebatepct1) RebatePct1
, sum(goal2) Goal2
, sum(rebatepct2) RebatePct2
, sum(lys.lys) lys
-- (select sum(anet) from cvo_sbm_details S where right(s.customer,5)=right(bb.cust_code,5) and yyyymmdd between ('1/1/'+convert(varchar,(@year-1))) and ('12/31/'+convert(varchar,(@year-1))+ ' 23:59:59') ) LYS,
, sum(tys.tys) tys
-- (select sum(anet) from cvo_sbm_details S where right(s.customer,5)=right(bb.cust_code,5) and yyyymmdd between ('1/1/'+convert(varchar,(@year))) and ('12/31/'+convert(varchar,(@year))+ ' 23:59:59') ) TYS,
, (select goal1 from cvo_businessbuildercusts BB2 WHERE BB2.MASTER_CUST_CODE=BB.MASTER_CUST_CODE and bb2.cust_code=bb.cust_code AND bb2.PROGYEAR=(@YEAR-1) and bb2.goal1 is not null)LYGoal1
, (select goal2 from cvo_businessbuildercusts BB2 WHERE BB2.MASTER_CUST_CODE=BB.MASTER_CUST_CODE and bb2.cust_code=bb.cust_code AND bb2.PROGYEAR=(@YEAR-1) and bb2.goal2 is not null)LYGoal2
INTO #BB1
FROM cvo_businessbuildercusts BB (nolock) 
join armaster AR (nolock) on BB.CUST_CODE=AR.customer_code
left outer join 
(
select right(customer,5) customer, sum(anet) LYS 
from cvo_sbm_details 
where yyyymmdd between ('1/1/'+convert(varchar,(@year-1))) and ('12/31/'+convert(varchar,(@year-1))+ ' 23:59:59')
group by right(customer,5)
) lys on lys.customer = right(bb.cust_code,5)
left outer join 
(
select right(customer,5) customer, sum(anet) tys 
from cvo_sbm_details 
where yyyymmdd between ('1/1/'+convert(varchar,(@year))) and ('12/31/'+convert(varchar,(@year))+ ' 23:59:59')
group by right(customer,5)
) tys on tys.customer = right(bb.cust_code,5)
WHERE progyear=@year
and AR.address_type=0
group by progyear, master_cust_code, cust_code, territory_code, ADDRESS_NAME, CITY, STATE
order by MASTER_CUST_CODE, CUST_CODE

SELECT 
Year, MTERR, master_cust_code, MNAME, Terr, cust_code, NAME, CITY, STATE, 
Goal1, ((GOAL1-(SELECT SUM(LYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE))/(SELECT SUM(LYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE))LYVG1, RebatePct1, 
Goal2, ((GOAL2-(SELECT SUM(LYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE))/(SELECT SUM(LYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE))LYVG2, RebatePct2, 
TYS, 
CASE WHEN GOAL1 IS NULL THEN NULL ELSE (SELECT SUM(TYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE) END AS TYSM,
CASE WHEN GOAL1 IS NULL THEN NULL ELSE ((SELECT SUM(TYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE)/GOAL1) END AS G1PctAch,
CASE WHEN GOAL1 IS NULL THEN NULL WHEN ((SELECT SUM(TYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE)-GOAL1) > 1 THEN 0 ELSE ((SELECT SUM(TYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE)-GOAL1)*-1 END AS G1Diff,
CASE WHEN GOAL2 IS NULL THEN NULL ELSE ((SELECT SUM(TYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE)/GOAL2) END AS G2PctAch,
CASE WHEN GOAL2 IS NULL THEN NULL ELSE ((SELECT SUM(TYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE)-GOAL2) END AS G2Diff,
LYS, 
CASE WHEN LYGOAL1 IS NULL THEN NULL ELSE (SELECT SUM(LYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE) END AS LYSM,
LYGoal1, 
CASE WHEN LYGOAL1 IS NULL THEN NULL ELSE ((SELECT SUM(LYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE)/LYGOAL1) END AS LYG1PctAch,
LYGoal2,
CASE WHEN LYGOAL2 IS NULL THEN NULL ELSE ((SELECT SUM(LYS) FROM #BB1 T11 WHERE T1.MASTER_CUST_CODE=T11.MASTER_CUST_CODE)/LYGOAL2) END AS LYG2PctAch,
case when master_cust_code=cust_code then 'x' else '' end as Line,
(select count(master_cust_code) from #BB1 t12 where t1.master_cust_code=t12.master_cust_code) CntM

 FROM #BB1 T1
 ORDER BY MASTER_CUST_CODE, CUST_CODE


END

GO
