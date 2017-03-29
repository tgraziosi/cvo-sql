SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		ELABARBERA
-- Create date: 5/17/2013
-- Description:	LISTS FOR EOS - END OF SUNS
-- EXEC CVO_EOS_SP
-- 090314 - tag - read sku list from new table cvo_eos_tbl
-- =============================================

CREATE PROCEDURE [dbo].[CVO_EOS_SP]

AS
BEGIN

	SET NOCOUNT ON;

declare @numberOfColumns int
SET @numberOfColumns = 3

IF(OBJECT_ID('tempdb.dbo.#Data') is not null)  
drop table #Data

select * 
INTO #Data 
from 
(
select 'EOS' as Prog, Brand, style, eos.part_no, pom_date, 
case when gender LIKE '%CHILD%' THEN 'Kids' 
	when gender = 'FEMALE-ADULT' THEN 'Womens' 
	else 'Mens' end as Gender, Avail, ReserveQty, 
	Avail as  TrueAvail
 -- tag 090314 - change to table from list of skus
 from cvo_eos_tbl eos 
 left outer join cvo_items_discontinue_vw id (nolock) on eos.part_no = id.part_no
 where isnull(id.type,'SUN') = 'SUN'
 and eos.eff_date < getdate() and isnull(eos.obs_date, getdate()) >= getdate()
 ) s
 order by Prog, gender, brand, style, part_no


-- select * from #Data where TrueAvail=0


IF(OBJECT_ID('tempdb.dbo.#Num') is not null)  drop table #Num
SELECT DISTINCT PROG, GENDER, BRAND, STYLE, 
row_number() over(order by Prog, Gender, brand, style) AS Num 
INTO #Num 
FROM #DATA 
group by PROG, GENDER, BRAND, STYLE 
ORDER BY PROG, GENDER, BRAND, STYLE

-- select * from #data
-- select * from #Num

--select CASE WHEN Num%2=0 THEN 0 ELSE 1 END as Col, * from #Data t1 join #num t2 on t1.prog=t2.prog and t1.brand=t2.brand and t1.style=t2.style
select ((Num+ @numberOfColumns - 1) % @numberOfColumns + 1) as Col, 
t1.Prog, t1.Brand, t1.Style, t1.part_no, t1.pom_date, 
 t1.Gender,
 t1.Avail, t1.ReserveQty, 
 t1.TrueAvail as TrueAvail_2,
 CASE WHEN t1.TrueAvail > 100 THEN '100+' ELSE convert(varchar(20),convert(int,t1.TrueAvail)) END 
 AS TrueAvail
 from #Data t1 
 join #num t2 on t1.prog=t2.prog and t1.gender=t2.gender and t1.brand=t2.brand and t1.style=t2.style order by Prog, Gender, Brand, Style

END

GO
