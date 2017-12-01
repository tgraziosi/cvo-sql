SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_hs_cir_sp]  @t VARCHAR(1000) = NULL AS 

BEGIN

-- 11/17/2015 - tag - Create csv file for HS CIR

-- EXEC cvo_hs_cir_sp 
/*
select c.* From cvo_hs_cir_tbl c
JOIN armaster ar on ar.customer_code = c.customer AND ar.ship_to_code = c.ship_to
WHERE ar.territory_code IN ('40456','40454')
*/

SET NOCOUNT ON 
SET ANSI_WARNINGS OFF

--DECLARE @t VARCHAR(1000)
--SELECT @t = NULL

DECLARE @asofdate DATETIME, @startdate DATETIME, @terr varchar(1000)
SELECT @asofdate = GETDATE()
, @startdate = DATEADD(YEAR,-2, GETDATE())
, @terr = @t

IF(OBJECT_ID('tempdb.dbo.#t') is not null)  drop table #t

IF(OBJECT_ID('tempdb.dbo.#territory') is not null)  drop table #territory
CREATE TABLE #territory ([territory] VARCHAR(10),
						 [region] VARCHAR(3))

-- SELECT @terr = '20206,40456,50503,20220,30302,70765,40440,30310,70720'

if @terr is NULL 
begin
	insert #territory
	select distinct territory_code, dbo.calculate_region_fn(territory_code) region
	from arterr where territory_code is not NULL
    ORDER BY territory_code
end
else
begin
	INSERT INTO #territory ([territory],[region])
	SELECT distinct LISTITEM, dbo.calculate_region_fn(listitem) region FROM dbo.f_comma_list_to_table(@terr)
	ORDER BY ListItem
END

-- 1/10/2107 - remove bob bassett for HS troubleshooting
-- DELETE FROM #territory WHERE territory = '30310'


IF(OBJECT_ID('dbo.cvo_hs_cir_tbl') is null)  
begin
CREATE TABLE [dbo].[cvo_hs_cir_tbl](
	[report_id] [VARCHAR](10) NOT NULL,
	[customer] [VARCHAR](10) NOT NULL,
	[ship_to] [VARCHAR](10) NULL,
	[mastersku] [VARCHAR](30) NULL,
	[part_no] [VARCHAR](30) NULL,
	[st_units] [FLOAT] NULL,
	[rx_units] [FLOAT] NULL,
	[ret_units] [FLOAT] NULL,
	[first_st] [VARCHAR](10) NULL,
	[last_st] [VARCHAR](10) NULL,
	[CL] [VARCHAR](2) NULL,
	[RYG] [VARCHAR](1) NULL,
	[size] [INT] NULL,
	[color] [VARCHAR](40) NULL,
	[rec_id] [INT] IDENTITY(1,1) NOT NULL,
	[last_update] [DATETIME] NULL,
	[date_added] [DATETIME] NULL
) ON [PRIMARY]


CREATE CLUSTERED INDEX [pk_hs_cir] ON [dbo].[cvo_hs_cir_tbl]
(
	[rec_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [idx_hs_cir_main] ON [dbo].[cvo_hs_cir_tbl]
(
	[customer] ASC,
	[ship_to] ASC,
	[part_no] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

END

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
INNER JOIN armaster ar (NOLOCK) ON ar.customer_code = s.customer AND ar.ship_to_code = s.ship_to
INNER JOIN #territory AS t ON t.territory = ar.territory_code
WHERE s.yyyymmdd >= @startdate AND i.type_code IN ('frame','sun') AND ISNULL(i.void,'n') = 'n'
AND i.category NOT IN ('FP','CH','ME','UN') -- 5/18/2017 - REMOVE CH, ME, AND UN NO LONGER SELLING
AND EXISTS (SELECT 1 FROM dbo.hs_cust_tbl AS hct WHERE hct.id = s.customer)
AND s.ship_to <> '0002.' -- 11/29/2017 - fudge for bad data till we fix it permanently

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


SELECT 'CIR v2' report_id,
		customer ,
       ship_to ,
       mastersku ,
       upper(part_no) part_no ,
       ISNULL(st_units,0) st_units ,
       ISNULL(rx_units,0) rx_units ,
       ISNULL(ret_units,0) ret_units ,
       ' '+ISNULL(CAST(DATEPART(MONTH,first_st) AS VARCHAR(2)) + '/' + RIGHT(CAST(DATEPART(YEAR,first_st) AS VARCHAR(4)),2),'') AS first_st  ,
       ' '+ISNULL(CAST(DATEPART(MONTH,last_st) AS VARCHAR(2)) + '/' + RIGHT(CAST(DATEPART(YEAR,last_st) AS VARCHAR(4)),2),'') AS last_st ,
       CL = CASE WHEN ISNULL(#t.CL,0) > 0 THEN 'CL' ELSE '' END ,
       ISNULL(RYG,'') ryg,
	   CAST(ISNULL(size,0) AS INT) size,
	   upper(ISNULL(color,'')) color
INTO #cir
FROM #t 

WHERE mastersku > ''
-- order by customer, ship_to, part_no

-- add new records

INSERT dbo.cvo_hs_cir_tbl
        ( report_id ,
          customer ,
          ship_to ,
          mastersku ,
          part_no ,
          st_units ,
          rx_units ,
          ret_units ,
          first_st ,
          last_st ,
          CL ,
          RYG ,
          size ,
          color ,
          last_update ,
          date_added
        )
SELECT #cir.report_id ,
       #cir.customer ,
       #cir.ship_to ,
       #cir.mastersku ,
       #cir.part_no ,
       #cir.st_units ,
       #cir.rx_units ,
       #cir.ret_units ,
       #cir.first_st ,
       #cir.last_st ,
       #cir.CL ,
       #cir.RYG ,
       #cir.size ,
       #cir.color,
	   GETDATE() AS last_update,
	   GETDATE() AS date_added
FROM #cir
WHERE NOT EXISTS (SELECT 1 FROM dbo.cvo_hs_cir_tbl AS chct 
				  WHERE #cir.part_no = chct.part_no 
				  AND #cir.customer = chct.customer
				  AND #cir.ship_to = chct.ship_to)

-- UPDATE existing ones

UPDATE chct 
SET 
 chct.cl = #cir.CL
,chct.first_st = #cir.first_st
,chct.last_st = #cir.last_st
,chct.ret_units = #cir.ret_units
,chct.rx_units = #cir.rx_units
,chct.RYG = #cir.RYG
,chct.st_units = #cir.st_units
,last_update = GETDATE()
-- select  * 
FROM dbo.cvo_hs_cir_tbl AS chct
INNER JOIN #cir ON #cir.customer = chct.customer 
				AND #cir.part_no = chct.part_no
				AND #cir.ship_to = chct.ship_to
WHERE 
(
chct.cl <> #cir.CL
OR chct.first_st <> #cir.first_st
OR chct.last_st <> #cir.last_st
OR chct.ret_units <> #cir.ret_units
OR chct.rx_units <> #cir.rx_units
OR chct.RYG <> #cir.RYG
OR chct.st_units <> #cir.st_units
)

-- deletes

UPDATE chct 
SET 
last_update = '1/1/1900'
-- select  * 
FROM dbo.cvo_hs_cir_tbl AS chct
WHERE NOT EXISTS  (SELECT 1 FROM #cir WHERE
				 #cir.customer = chct.customer 
				AND #cir.part_no = chct.part_no
				AND #cir.ship_to = chct.ship_to)
				OR chct.ship_to = '0002.'

END







GO




GRANT EXECUTE ON  [dbo].[cvo_hs_cir_sp] TO [public]
GO
