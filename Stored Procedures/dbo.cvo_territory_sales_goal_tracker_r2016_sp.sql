SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_territory_sales_goal_tracker_r2016_sp]
    @CompareYear INT = NULL ,
--v2
    @territory VARCHAR(1000) = NULL -- multi-valued parameter
AS
    SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

    BEGIN

-- exec cvo_territory_sales_goal_tracker_r2016_sp 2016

--DECLARE @compareyear INT, @territory VARCHAR(1000)
--SELECT @compareyear = 2016, @territory = null


        DECLARE @cy INT ,
            @terr VARCHAR(1000) ,
            @today DATETIME;
        SELECT  @cy = @CompareYear ,
                @terr = @territory ,
                @today = GETDATE();

-- 032614 - tag - performance improvements - add multi-value param for territory
--  move setting the region to last.

--declare @compareyear int
--set @compareyear = 2013

-- 082914 - performance
        DECLARE @sdate DATETIME ,
            @edate DATETIME ,
            @sdately DATETIME ,
            @edately DATETIME;

        IF @cy IS NULL
            SELECT  @cy = YEAR(@today);

        SET @sdately = DATEADD(YEAR, ( @cy - 1 ) - 1900, '01-01-1900');
        SET @edately = CASE WHEN @cy = YEAR(@today)
                            THEN DATEADD(dd,
                                         DATEDIFF(dd, 0,
                                                  DATEADD("yyyy", -1, @today))
                                         + -1, 0)
                            ELSE DATEADD(ms, -2,
                                         ( DATEADD(YEAR,
                                                   ( @cy - 1 ) - 1900 + 1,
                                                   '01-01-1900') ))
                       END;
        SET @sdate = DATEADD(YEAR, ( @cy ) - 1900, '01-01-1900');
        SET @edate = CASE WHEN @cy = YEAR(@today) THEN @today
                          ELSE DATEADD(ms, -2,
                                       ( DATEADD(YEAR, ( @cy ) - 1900 + 1,
                                                 '01-01-1900') ))
                     END;

	   -- SELECT @sdate, @edate

        IF ( OBJECT_ID('tempdb.dbo.#temp') IS NOT NULL )
            DROP TABLE #temp;

        IF ( OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL )
            DROP TABLE #territory;
        CREATE TABLE #territory
            (
              territory VARCHAR(10) ,
              region VARCHAR(3) ,
              r_id INT ,
              t_id INT IDENTITY(1, 1)
            );

        IF @terr IS NULL
            BEGIN
                INSERT  #territory
                        SELECT DISTINCT
                                territory_code ,
                                dbo.calculate_region_fn(territory_code) region ,
                                0
                        FROM    armaster
                        WHERE   territory_code IS NOT NULL
                        ORDER BY territory_code;
            END;
        ELSE
            BEGIN
                INSERT  INTO #territory
                        ( territory ,
                          region
                        )
                        SELECT DISTINCT
                                ListItem ,
                                dbo.calculate_region_fn(ListItem) region
                        FROM    dbo.f_comma_list_to_table(@terr)
                        ORDER BY ListItem;
            END;

        UPDATE  t
        SET     t.r_id = r.r_id
-- SELECT * 
        FROM    #territory AS t
                JOIN ( SELECT DISTINCT
                                region ,
                                RANK() OVER ( ORDER BY region ) r_id
                       FROM     ( SELECT DISTINCT
                                            region
                                  FROM      #territory
                                ) AS r
                     ) AS r ON t.region = r.region;

-- SELECT * FROM #territory AS t

-- code in report to figure out pct_year
/*
SELECT pct_year = 
		(SELECT SUM(pct_sales) FROM cvo_dmd_mult
		WHERE asofdate <= dd.today AND obs_date IS NULL
		AND mm < MONTH(dd.today))
		+
		(SELECT (pct_sales * (CAST(dd.workday AS FLOAT)/CAST(dd.totalworkdays AS FLOAT)))
			FROM dbo.cvo_dmd_mult AS cdm
			WHERE ASofdate <= dd.today AND obs_date IS NULL		
			AND mm = MONTH(dd.today))
		, dd.Today
		, dd.WorkDay
		, dd.TotalWorkDays

FROM 
( SELECT  Today = ( SELECT    EndDate
                  FROM      dbo.cvo_date_range_vw AS cdrv
                  WHERE     Period = 'month to date'
                ) ,
        WorkDay = ( SELECT  dbo.cvo_f_get_work_days(BeginDate, EndDate)
                    FROM    dbo.cvo_date_range_vw AS cdrv
                    WHERE   Period = 'MONTH TO DATE'
                ) ,
        TotalWorkDays = ( SELECT    dbo.cvo_f_get_work_days(BeginDate, EndDate)
                          FROM      dbo.cvo_date_range_vw AS cdrv
                          WHERE     Period = 'THIS MONTH'
                 )
) DD
*/

-- get TY net sales for core, revo and blutech
        SELECT  a.territory_code ,
                ISNULL(c.year, YEAR(@today)) AS Year ,
                SUM(ISNULL(c.anet, 0)) anet ,
                SUM(ISNULL(CASE WHEN i.type_code IN ( 'frame', 'sun' )
                                THEN c.qnet
                           END, 0)) qnet ,
				CAST(0 AS INT)  numprog,
                tot = CASE WHEN ISNULL(i.category, 'Core') IN ('revo', 'BT','AS','OP' )
                           THEN i.category
                           ELSE 'Core'
                      END
        INTO    #temp
        FROM    #territory t
                INNER JOIN armaster (NOLOCK) a ON a.territory_code = t.territory
                INNER JOIN cvo_sbm_details c ( NOLOCK ) ON a.customer_code = c.customer
                                                           AND a.ship_to_code = c.ship_to
                INNER JOIN inv_master i ( NOLOCK ) ON i.part_no = c.part_no
        WHERE   1 = 1
-- and (yyyymmdd between @sdately and @edately) or (yyyymmdd between @sdate and @edate)
                AND ( yyyymmdd BETWEEN @sdate AND @edate )
        GROUP BY a.territory_code ,
                c.year ,
                CASE WHEN ISNULL(i.category, 'Core') IN ( 'revo', 'BT','AS','OP' )
                     THEN i.category
                     ELSE 'Core'
                END;


-- fill in the blanks so that all buckets are covered
-- select * from #temp
-- ty
        INSERT  INTO #temp
                SELECT   DISTINCT
                        territory ,
                        @cy AS Year ,
                        0 anet ,
                        0 qnet ,
						0 numprog,
                        'Core'
                FROM    #territory AS t
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   #temp
                                     WHERE  #temp.territory_code = t.territory
                                            AND tot = 'core' );

        INSERT  INTO #temp
                SELECT   DISTINCT
                        territory ,
                        @cy AS Year ,
                        0 anet ,
                        0 qnet ,
						0 numprog,
                        'BT'
                FROM    #territory AS t
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   #temp
                                     WHERE  #temp.territory_code = t.territory
                                            AND tot = 'BT' );
	
        INSERT  INTO #temp
                SELECT   DISTINCT
                        territory ,
                        @cy AS Year ,
                        0 anet ,
                        0 qnet ,
						0 numprog,
                        'REVO'
                FROM    #territory AS t
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   #temp
                                     WHERE  #temp.territory_code = t.territory
                                            AND tot = 'REVO' );
		INSERT  INTO #temp
                SELECT   DISTINCT
                        territory ,
                        @cy AS Year ,
                        0 anet ,
                        0 qnet ,
						0 numprog,
                        'AS'
                FROM    #territory AS t
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   #temp
                                     WHERE  #temp.territory_code = t.territory
                                            AND tot = 'AS' );
		 INSERT  INTO #temp
                SELECT   DISTINCT
                        territory ,
                        @cy AS Year ,
                        0 anet ,
                        0 qnet ,
						0 numprog,
                        'OP'
                FROM    #territory AS t
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   #temp
                                     WHERE  #temp.territory_code = t.territory
                                            AND tot = 'OP' );


-- get TY num programs for revo and blutech
IF ( OBJECT_ID('tempdb.dbo.#promotrkr') IS NOT NULL )
            DROP TABLE #promotrkr;
IF ( OBJECT_ID('tempdb.dbo.#r') IS NOT NULL )
            DROP TABLE #r;
IF ( OBJECT_ID('tempdb.dbo.#ty') IS NOT NULL )
            DROP TABLE #ty;
IF ( OBJECT_ID('tempdb.dbo.#s1') IS NOT NULL )
            DROP TABLE #s1;



SELECT 
o.order_no, o.ext, o.total_amt_order, o.total_invoice, o.orig_no, o.orig_ext, 
t.territory, o.cust_code, o.ship_to,
o.promo_id, o.promo_level, o.order_type, 
o.FramesOrdered, o.FramesShipped, o.back_ord_flag, o.Cust_type, 
cast('1/1/1900' as datetime) as return_date,
space(40) as reason,
cast(0.00 as decimal(20,8)) as return_amt,
0 as return_qty,
o.source
, qual_order = 0
, uc = 0

into #promotrkr

FROM  #territory t 
INNER join cvo_adord_vw AS o WITH (nolock) on t.territory = o.territory
where 1=1
AND ( (o.promo_id IN ('revo') and o.promo_level in ('launch 1','launch 2','launch 3','1','2','3'))
	OR (o.promo_id IN ('Blue') AND o.promo_level IN ('1','kids','suns'))
	OR (o.promo_id IN ('sunps') AND o.promo_level IN ('OP'))
	OR (promo_id IN ('aspire') AND promo_level IN ('1','3','vew','launch','new'))
)
AND o.date_entered BETWEEN @sdate AND @edate
AND o.who_entered <> 'backordr' -- 1/18/2016
and o.status <> 'V' -- 110714 - exclude void orders

-- SELECT * FROM #promotrkr AS p

-- Collect the returns

select o.orig_no order_no, o.orig_ext ext,
	return_date = o.date_entered, 
	reason = min(rc.return_desc)
into #r
from #promotrkr t inner join  orders o (nolock) on t.order_no = o.orig_no and t.ext = o.orig_ext
 inner join ord_list ol (nolock) on   ol.order_no = o.order_no and ol.order_ext = o.ext
 INNER JOIN inv_master i(nolock) ON ol.part_no = i.part_no 
 INNER JOIN po_retcode rc(nolock) ON ol.return_code = rc.return_code
 WHERE 1=1
 -- and LEFT(ol.return_code, 2) <> '05' -- AND i.type_code = 'sun'
  AND o.status = 't' and o.type = 'c' 
  and (o.total_invoice = t.total_invoice or o.total_amt_order = t.total_amt_order)
group by o.orig_no, o.orig_ext, o.date_entered, o.total_amt_order -- o.total_invoice


update t set 
t.return_date = #r.return_date,
t.reason = #r.reason
from #r , #promotrkr t where #r.order_no = t.order_no and #r.ext = t.ext

--select * from #r
--select * From #promotrkr

update t set uc = 1
	from 
	(select cust_code, promo_id, min(order_no) min_order from #promotrkr 
		inner join cvo_armaster_all car (nolock) on car.customer_code = #promotrkr.cust_code
			and car.ship_to = #promotrkr.ship_to
		where source <> 'T' and (isnull(reason,'') = '' 
		and not exists (select 1 from cvo_promo_override_audit poa 
			where poa.order_no = #promotrkr.order_no and poa.order_ext = #promotrkr.ext))
		and car.door = 1
		group by cust_code, promo_id
	) as m 	inner join #promotrkr t 
	on t.cust_code = m.cust_code and t.promo_id = m.promo_id and t.order_no = m.min_order
 
UPDATE t SET qual_order =  case when source = 'T' then 0 
when isnull(reason,'') = '' and not exists (select 1 from cvo_promo_override_audit poa where poa.order_no = t.order_no and poa.order_ext = t.ext) then 1 
else 0 END
FROM #promotrkr t


INSERT INTO #temp
SELECT 
Territory,
YEAR(@today) AS year,
0 AS anet,
0 AS qnet,
SUM(qual_order) numprog,
tot = CASE WHEN promo_id = 'blue' THEN 'BT'
	 WHEN promo_id = 'revo' THEN 'REVO'
	 WHEN promo_id = 'aspire' THEN 'AS'
	 WHEN promo_id = 'sunps' THEN 'OP'
	ELSE 'xxx' end 
from #promotrkr 
GROUP BY CASE WHEN promo_id = 'blue' THEN 'BT'
         WHEN promo_id = 'revo' THEN 'REVO'
		 WHEN promo_id = 'aspire' THEN 'AS'
		 WHEN promo_id = 'sunps' THEN 'OP'
         ELSE 'xxx'
         END ,
         Territory


-- get this year figures

        SELECT  a.territory_code ,
                a.Year ,
                SUM(a.anet) anet ,
                SUM(a.qnet) qnet ,
				SUM(a.numprog) numprog,
                a.tot
        INTO    #ty
        FROM    #temp a
        WHERE   a.Year = @cy
        GROUP BY a.territory_code ,
                a.Year ,
                a.tot;


-- fixup sales person names

        SELECT  t.territory territory_code ,
                salesperson_code = ISNULL(( SELECT TOP 1
                                                    salesperson_name
                                            FROM    arsalesp
                                            WHERE   salesperson_code <> 'smithma'
                                                    AND territory_code = t.territory
                                                    AND ISNULL(date_of_hire,
                                                              '1/1/1900') <= @today
                                                    AND status_type = 1
                                          ), 'Empty') ,
                t.region ,
                t.r_id ,
                t.t_id
        INTO    #s1
        FROM    #territory t;

-- select * From #territory order by territory
-- select * from #s1 where territory_code in (30398,30399) order by territory_code 
-- select * From arsalesp where territory_code = 30398

        SELECT  #ty.territory_code ,
                #s1.salesperson_code ,
                Year ,
                ROUND(anet, 2) anet ,
                qnet ,
				CAST(numprog AS INT) numprog,
                tot ,
				Actual = CASE WHEN tot = 'Core' THEN ROUND(anet, 2) ELSE numprog end ,
				Goal = 0,
                #s1.region  Region,
                #s1.r_id ,
                #s1.t_id
        FROM    #ty -- ty
                LEFT OUTER JOIN #s1 ON #s1.territory_code = #ty.territory_code
        UNION ALL -- get goals
        SELECT  g.Territory_Code ,
                'Goal' AS salesperson_code ,
                @cy AS yyear ,
                ISNULL(g.Core_Goal_Amt, 0) AS anet ,
                0 AS qnet ,
				CAST(0 AS INT) numprog,
                'Core' tot ,
				Actual = 0 ,
				Goal = ISNULL(g.Core_Goal_Amt, 0),
                terr.region ,
                #s1.r_id ,
                #s1.t_id
        FROM    #territory terr
                LEFT OUTER JOIN dbo.cvo_terr_scorecard AS g ON terr.territory = g.Territory_Code
                LEFT OUTER JOIN #s1 ON #s1.territory_code = g.Territory_Code
        WHERE   1 = 1
                AND ( g.Stat_Year = CAST(@cy AS VARCHAR(5)) )
        UNION ALL
        SELECT  g.Territory_Code ,
                'Goal' AS salesperson_code ,
                @cy AS yyear ,
                0 AS anet ,
                0 AS qnet ,
				CAST(ISNULL(g.Revo_Goal_Amt,0) AS INT) AS numprog,
                'Revo' tot ,
				Actual = 0,
				Goal = CAST(ISNULL(g.Revo_Goal_Amt,0) AS INT),
                terr.region ,
                #s1.r_id ,
                #s1.t_id
        FROM    #territory terr
                LEFT OUTER JOIN dbo.cvo_terr_scorecard AS g ON terr.territory = g.Territory_Code
                LEFT OUTER JOIN #s1 ON #s1.territory_code = g.Territory_Code
        WHERE   1 = 1
                AND ( g.Stat_Year = CAST(@cy AS VARCHAR(5)) )
        UNION ALL
        SELECT  g.Territory_Code ,
                'Goal' AS salesperson_code ,
                @cy AS yyear ,
                0 AS anet,
                0 AS qnet ,
				CAST(ISNULL(g.Blutech_Goal_Amt, 0) AS INT) AS numprog,
                'BT' tot ,
				Actual = 0,
				Goal = CAST(ISNULL(g.Blutech_Goal_Amt,0) AS INT),
                terr.region ,
                #s1.r_id ,
                #s1.t_id
        FROM    #territory terr
                LEFT OUTER JOIN dbo.cvo_terr_scorecard AS g ON terr.territory = g.Territory_Code
                LEFT OUTER JOIN #s1 ON #s1.territory_code = g.Territory_Code
        WHERE   1 = 1
                AND ( g.Stat_Year = CAST(@cy AS VARCHAR(5)) );
	
    END;

GO
