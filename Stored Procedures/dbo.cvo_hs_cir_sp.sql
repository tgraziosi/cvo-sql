
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_hs_cir_sp] AS 

BEGIN

-- 11/17/2015 - tag - Create csv file for HS CIR

-- EXEC cvo_hs_cir_sp
/*
select c.* From cvo_hs_cir_tbl c
JOIN armaster ar on ar.customer_code = c.customer AND ar.ship_to_code = c.ship_to
WHERE ar.territory_code IN ('40456','40454')
*/

SET NOCOUNT ON 
SET ANSI_WARNINGS off

DECLARE @asofdate DATETIME, @startdate datetime
SELECT @asofdate = GETDATE()
, @startdate = DATEADD(YEAR,-2, GETDATE())

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t
IF(OBJECT_ID('dbo.cvo_hs_cir_tbl') is not null)  drop table cvo_hs_cir_tbl

CREATE TABLE [dbo].[cvo_hs_cir_tbl](
	[report_id] VARCHAR(10) NOT NULL,
	[customer] [varchar](10) NOT NULL,
	[ship_to] [varchar](10) NULL,
	[mastersku] [varchar](30) NULL,
	[part_no] [varchar](30) NULL,
	[st_units] [float] NULL,
	[rx_units] [float] NULL,
	[ret_units] [float] NULL,
	[first_st] VARCHAR(10) NULL,
	[last_st] VARCHAR(10) NULL,
	[CL] VARCHAR(2) NULL,
	[RYG] varchar(1) NULL,
	[size] [int] NULL,
	[color] VARCHAR(40) null
) ON [PRIMARY]

-- SELECT '** get sales data'	, GETDATE()
SELECT s.customer, s.ship_to
, SPACE(30) AS mastersku
, s.part_no
, st_units = SUM(CASE WHEN s.user_category LIKE 'st%' AND s.user_category NOT LIKE '%rb' THEN qsales ELSE 0 end)
, rx_units = SUM(CASE WHEN s.user_category LIKE 'rx%' AND s.user_category NOT LIKE '%rb' THEN qsales ELSE 0 end)
, ret_units = SUM(CASE WHEN s.user_category NOT LIKE '%rb' AND s.return_code <> 'exc' THEN qreturns ELSE 0 end)
, first_st = MIN(CASE WHEN s.user_category LIKE 'st%' and s.user_category NOT LIKE '%rb' THEN dateordered ELSE NULL END)
, last_st = max(CASE WHEN s.user_category LIKE 'st%' and s.user_category NOT LIKE '%rb' THEN dateordered ELSE null end)
, CL = MAX(s.isCL)
, RYG = ''
, size = CAST(ISNULL(ia.field_17,0) AS INT) -- eye size
, color = ISNULL(ia.field_3,'') -- color name
INTO #t
FROM inv_master i (NOLOCK) 
INNER JOIN inv_master_add ia (NOLOCK) ON ia.part_no = i.part_no
INNER join cvo_sbm_details s (NOLOCK) oN s.part_no = i.part_no
WHERE s.yyyymmdd >= @startdate AND i.type_code IN ('frame','sun') AND ISNULL(i.void,'n') = 'n'
AND i.category NOT IN ('FP')
GROUP BY s.customer ,
         s.ship_to ,
         s.part_no ,
         ia.field_17 ,
         ia.field_3

CREATE INDEX idx_ryg ON #t (part_no)

-- SELECT '** set ryg status'	, GETDATE()

IF(OBJECT_ID('tempdb.dbo.#ryg') is not null)  drop table #ryg
SELECT DISTINCT #t.part_no, ' ' AS RYg INTO #ryg FROM #t

UPDATE #ryg SET ryg = dbo.f_cvo_get_part_tl_status(#ryg.part_no, @asofdate)
FROM #ryg

UPDATE #t SET ryg = CASE WHEN #ryg.RYg ='x' THEN '' ELSE #ryg.RYg END 
FROM #ryg JOIN #t ON #t.part_no = #ryg.part_no

-- SELECT '** set mastersku status', GETDATE()
UPDATE #T SET MASTERSKU = ISNULL(HS.MASTERSKU,'')
FROM #t
LEFT OUTER JOIN dbo.cvo_hs_inventory_8 hs (NOLOCK) ON hs.sku = #T.part_no

INSERT dbo.cvo_hs_cir_tbl 
SELECT 'CIR v2',
		customer ,
       ship_to ,
       mastersku ,
       upper(part_no) part_no ,
       st_units ,
       rx_units ,
       ret_units ,
       ' '+ISNULL(CAST(DATEPART(MONTH,first_st) AS VARCHAR(2)) + '/' + RIGHT(CAST(DATEPART(YEAR,first_st) AS VARCHAR(4)),2),'') AS first_st  ,
       ' '+ISNULL(CAST(DATEPART(MONTH,last_st) AS VARCHAR(2)) + '/' + RIGHT(CAST(DATEPART(YEAR,last_st) AS VARCHAR(4)),2),'') AS last_st ,
       CL = CASE WHEN #t.CL > 0 THEN 'CL' ELSE '' END ,
       RYG,
	   CAST(size AS INT) size,
	   upper(ISNULL(color,'')) color
FROM #t order by customer, ship_to, part_no


end

GO


GRANT EXECUTE ON  [dbo].[cvo_hs_cir_sp] TO [public]
GO
