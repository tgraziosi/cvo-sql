SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_matl_fcst_style_season_sp]
    @startrank DATETIME ,
    @asofdate DATETIME ,
    @endrel DATETIME = NULL , -- ending release date
    @UseDrp INT = 1 ,
    @current INT = 1 ,
    @collection VARCHAR(1000) = NULL ,
    @Style VARCHAR(8000) = NULL ,
    @SpecFit VARCHAR(1000) = NULL ,
    @usg_option CHAR(1) = 'O' ,
    @Season_start INT = NULL ,
    @Season_end INT = NULL ,
    @Season_mult DECIMAL(20, 8) = NULL ,
    @debug INT = 0
--
/*
 exec cvo_matl_fcst_style_season_sp
 @startrank = '12/23/2013',
 @asofdate = '1/1/2016', 
 @endrel = '1/1/2016', 
 @usedrp = 1, 
 @current = 1, 
 @collection = 'jmc', 
 @style = '049', 
 @specfit = '*all*',
 @usg_option = 'o',
 @debug = 0 -- debug

 
*/
-- 090314 - tag
-- get sales since the asof date, and use it to consume the demand line
-- 10/29/2014 - ADD additional info to match DRP
-- 1/9/2015 - update sales PCT for demand multipliers per BL schedule
-- 2/11/2015 - fix po line not picking up po's for suns

-- @usedrp - 0 = no, use FCT; 1 = use drp for all
-- @current - 0 = show all, 1 = current only (no POMs)
-- 12/3/14 - tag - fix pom styles/skus
-- 6/17/15 - fix sku's doubling up because of release dates
-- 7/20/15 - add avail to promise and option to select by Specialty Fit attribute
-- 7/22/15 - add usage option for orders or shipments
-- 07/29/2015 - dont include credit hold orders
-- 8/18/2015 - fix po qty when there are multiple po's in the same month
-- 9/3/2015 - fix for  po lines in next year
-- 10/6/2015 - PO lines - make the outer range < not <= to avoid 13th bucket on report
-- 10/20/2015 - add seasonality multiplier, promo and substitute flagging
-- 7/15/2016 - calc starting inventory with allocations if usage is on orders as allocations are already in the demand number. If on shipments, then net out allocations.
-- 8/22/2016 - have to use the core spread
AS
    BEGIN

        SET NOCOUNT ON;
        SET ANSI_WARNINGS OFF;


        DECLARE @startdate DATETIME ,
            @enddate DATETIME ,
            @pomdate DATETIME;
/* for testing
--, @startrank datetime
--, @asofdate datetime
--, @usedrp int
--, @current int
*/

        SET @pomdate = @asofdate;
        SET @startdate = '01/01/1949';  -- starting release date
-- set @enddate = '12/31/2020' -- ending release date
-- set @enddate = @asofdate
        SET @enddate = ISNULL(@endrel, @asofdate);
        DECLARE @coll_list VARCHAR(1000) ,
            @style_list VARCHAR(8000) ,
            @sf VARCHAR(1000) ,
            @s_start INT ,
            @s_end INT ,
            @s_mult DECIMAL(20, 8);

        SELECT  @coll_list = @collection ,
                @style_list = @Style ,
                @sf = @SpecFit ,
                @s_start = ISNULL(@Season_start, 1) ,
                @s_end = ISNULL(@Season_end, 12) ,
                @s_mult = ISNULL(@Season_mult, 1);

-- select @style_list

        CREATE TABLE #coll ( coll VARCHAR(20) );
        IF @coll_list IS NULL
            BEGIN
                INSERT  INTO #coll
                        SELECT DISTINCT
                                kys
                        FROM    category
                        WHERE   void = 'n';
            END;
        ELSE
            BEGIN
                INSERT  INTO #coll
                        ( coll
                        )
                        SELECT  ListItem
                        FROM    dbo.f_comma_list_to_table(@coll_list);
            END;

        CREATE TABLE #style_list ( style VARCHAR(40) );
        IF @style_list IS NULL
            OR @style_list LIKE '%*ALL*%'
            BEGIN
                INSERT  INTO #style_list
                        SELECT DISTINCT
                                field_2
                        FROM    inv_master_add ia ( NOLOCK )
                                INNER JOIN inv_master i ( NOLOCK ) ON i.part_no = ia.part_no
                                INNER JOIN #coll ON #coll.coll = i.category
                        WHERE   i.void = 'n'; 
            END;
        ELSE
            BEGIN
                INSERT  INTO #style_list
                        ( style
                        )
                        SELECT  ListItem
                        FROM    dbo.f_comma_list_to_table(@style_list);
            END;

        CREATE TABLE #sf ( sf VARCHAR(20) );
        IF @sf IS NULL
            OR @sf LIKE '%*ALL*%'
            BEGIN
                INSERT  INTO #sf
                        ( sf )
                VALUES  ( '' );
                INSERT  INTO #sf
                        ( sf
                        )
                        SELECT DISTINCT
                                kys
                        FROM    cvo_specialty_fit
                        WHERE   void = 'n';
            END;
        ELSE
            BEGIN
                INSERT  INTO #sf
                        ( sf
                        )
                        SELECT  ListItem
                        FROM    dbo.f_comma_list_to_table(@sf);
            END;

--select * from #style_list
--select @style_list

        IF ISNULL(@debug, 0) = 1
            BEGIN
                SELECT  @SpecFit;
                SELECT  *
                FROM    #sf;
            END;

        DECLARE @loc VARCHAR(10);
        SELECT  @loc = '001';

        IF ( OBJECT_ID('tempdb.dbo.#dmd_mult') IS NOT NULL )
            DROP TABLE #dmd_mult;
        CREATE TABLE #dmd_mult
            (
              mm INT ,
              pct_sales DECIMAL(20, 8) ,
              mult DECIMAL(20, 8) ,
              s_mult DECIMAL(20, 8) ,
              sort_seq INT
            );

        INSERT  INTO #dmd_mult
                SELECT  mm ,
                        pct_sales ,
                        0 ,
                        0 ,
                        0
                FROM    cvo_dmd_mult
                WHERE   obs_date IS NULL
                        AND asofdate = ( SELECT MAX(asofdate)
                                         FROM   cvo_dmd_mult
                                         WHERE  asofdate <= GETDATE() AND spread ='CORE'
                                       )
-- 8/22/2016
                        AND spread = 'CORE';

-- select sum(pct_sales) from #dmd_mult -- 1.0001 for 2015
-- 0.99980000 for 2/2015

        UPDATE  #dmd_mult
        SET     sort_seq = CASE WHEN mm < MONTH(@asofdate)
                                THEN mm - MONTH(@asofdate) + 13
                                ELSE mm - MONTH(@asofdate) + 1
                           END; 

        DECLARE @sort_seq INT ,
            @base_pct FLOAT;
/*
select @sort_seq = 3
while @sort_seq <= 15
begin
 select @base_pct = avg(pct_sales) from #dmd_mult where sort_seq between @sort_seq - 2 and @sort_seq
 update #dmd_mult set mult = 1+((pct_sales-@base_pct)/@base_pct)
		where sort_seq = @sort_seq - 2
 -- each months' multiplier s/b the average of the prior 3 months
 select @sort_seq = @sort_seq + 1
end
*/

        SET @base_pct = ( SELECT    AVG(pct_sales)
                          FROM      #dmd_mult
                          WHERE     sort_seq IN ( 10, 11, 12 )/*(11,12,1)*/
                        ); -- last 3 months sales %
-- the multiplier s/b the average of the 3 months prior to the asofdate

        SET @sort_seq = 1;
        WHILE @sort_seq <= 12
            BEGIN
 
                UPDATE  #dmd_mult
                SET     mult = ROUND(1 + ( ( pct_sales - @base_pct )
                                           / @base_pct ), 4) ,
                        s_mult = CASE WHEN @sort_seq BETWEEN @s_start AND @s_end
                                      THEN @s_mult
                                      ELSE 1.0
                                 END
                WHERE   sort_seq = @sort_seq;

                SET @sort_seq = @sort_seq + 1;
            END;

        DECLARE @flatten DECIMAL(20, 8);
        SELECT  @flatten = SUM(mult)
        FROM    #dmd_mult;
        UPDATE  #dmd_mult
        SET     mult = mult * ( 12 / @flatten );

-- select * From #dmd_mult

        IF ( OBJECT_ID('tempdb.dbo.#inv_rank') IS NOT NULL )
            DROP TABLE #inv_rank;
        CREATE TABLE #inv_rank
            (
              collection VARCHAR(10) ,
              inv_Rank VARCHAR(1) ,
              m3 FLOAT ,
              m12 FLOAT ,
              m24 FLOAT
            );

--insert into #inv_rank values ('BCBG','A','2500','7900','3500')
--insert into #inv_rank values ('BCBG','B','1500','4700','1200')
--insert into #inv_rank values ('BCBG','C','1','2300','300')
--insert into #inv_rank values ('CH','A','900','3100','1500')
--insert into #inv_rank values ('CH','B','700','2200','800')
--insert into #inv_rank values ('CH','C','1','1300','500')
--insert into #inv_rank values ('CVO','A','1100','3800','1900')
--insert into #inv_rank values ('CVO','B','700','2600','900')
--insert into #inv_rank values ('CVO','C','1','1800','500')
--insert into #inv_rank values ('ET','A','2000','6300','3200')
--insert into #inv_rank values ('ET','B','1500','4500','1100')
--insert into #inv_rank values ('ET','C','1','2400','1000')
--insert into #inv_rank values ('IZOD','A','1200','4400','1900')
--insert into #inv_rank values ('IZOD','B','800','2800','600')
--insert into #inv_rank values ('IZOD','C','1','1200','300')
--insert into #inv_rank values ('IZX','A','1000','3700','1600')
--insert into #inv_rank values ('IZX','B','700','2300','1200')
--insert into #inv_rank values ('IZX','C','1','1300','500')
--insert into #inv_rank values ('JC','A','1100','4000','1600')
--insert into #inv_rank values ('JC','B','800','3000','1200')
--insert into #inv_rank values ('JC','C','1','1800','500')
--insert into #inv_rank values ('JMC','A','2000','7500','2800')
--insert into #inv_rank values ('JMC','B','1200','3900','1600')
--insert into #inv_rank values ('JMC','C','1','2600','800')
--insert into #inv_rank values ('ME','A','2000','5900','2800')
--insert into #inv_rank values ('ME','B','1200','3900','1600')
--insert into #inv_rank values ('ME','C','1','1300','300')
--insert into #inv_rank values ('OP','A','1400','4300','2000')
--insert into #inv_rank values ('OP','B','1100','4000','1900')
--insert into #inv_rank values ('OP','C','1','2200','800')

-- year 2 updates - only for styles with full 2 years history
        INSERT  INTO #inv_rank
        VALUES  ( 'BCBG', 'A', '2500', '7900', '3900' );
        INSERT  INTO #inv_rank
        VALUES  ( 'BCBG', 'B', '1500', '4700', '1400' );
        INSERT  INTO #inv_rank
        VALUES  ( 'BCBG', 'C', '1', '2300', '500' );
        INSERT  INTO #inv_rank
        VALUES  ( 'CH', 'A', '900', '3100', '1600' );
        INSERT  INTO #inv_rank
        VALUES  ( 'CH', 'B', '700', '2200', '900' );
        INSERT  INTO #inv_rank
        VALUES  ( 'CH', 'C', '1', '1300', '400' );
        INSERT  INTO #inv_rank
        VALUES  ( 'CVO', 'A', '1100', '3800', '2000' );
        INSERT  INTO #inv_rank
        VALUES  ( 'CVO', 'B', '700', '2600', '1500' );
        INSERT  INTO #inv_rank
        VALUES  ( 'CVO', 'C', '1', '1800', '500' );
        INSERT  INTO #inv_rank
        VALUES  ( 'ET', 'A', '2000', '6300', '3100' );
        INSERT  INTO #inv_rank
        VALUES  ( 'ET', 'B', '1500', '4500', '1100' );
        INSERT  INTO #inv_rank
        VALUES  ( 'ET', 'C', '1', '2400', '700' );
        INSERT  INTO #inv_rank
        VALUES  ( 'IZOD', 'A', '1200', '4400', '3400' );
        INSERT  INTO #inv_rank
        VALUES  ( 'IZOD', 'B', '800', '2800', '1900' );
        INSERT  INTO #inv_rank
        VALUES  ( 'IZOD', 'C', '1', '1200', '300' );
        INSERT  INTO #inv_rank
        VALUES  ( 'IZX', 'A', '1000', '3700', '2700' );
        INSERT  INTO #inv_rank
        VALUES  ( 'IZX', 'B', '700', '2300', '1200' );
        INSERT  INTO #inv_rank
        VALUES  ( 'IZX', 'C', '1', '1300', '400' );
        INSERT  INTO #inv_rank
        VALUES  ( 'JC', 'A', '1100', '4000', '2400' );
        INSERT  INTO #inv_rank
        VALUES  ( 'JC', 'B', '800', '3000', '1700' );
        INSERT  INTO #inv_rank
        VALUES  ( 'JC', 'C', '1', '1800', '500' );
        INSERT  INTO #inv_rank
        VALUES  ( 'JMC', 'A', '2000', '7500', '4900' );
        INSERT  INTO #inv_rank
        VALUES  ( 'JMC', 'B', '1200', '3900', '1400' );
        INSERT  INTO #inv_rank
        VALUES  ( 'JMC', 'C', '1', '2600', '900' );
        INSERT  INTO #inv_rank
        VALUES  ( 'ME', 'A', '2000', '5900', '2800' );
        INSERT  INTO #inv_rank
        VALUES  ( 'ME', 'B', '1200', '3900', '1200' );
        INSERT  INTO #inv_rank
        VALUES  ( 'ME', 'C', '1', '1300', '600' );
        INSERT  INTO #inv_rank
        VALUES  ( 'OP', 'A', '1400', '4300', '2100' );
        INSERT  INTO #inv_rank
        VALUES  ( 'OP', 'B', '1100', '4000', '2300' );
        INSERT  INTO #inv_rank
        VALUES  ( 'OP', 'C', '1', '2200', '1000' );

        IF ( OBJECT_ID('tempdb.dbo.#sls_det') IS NOT NULL )
            DROP TABLE #sls_det;
        IF ( OBJECT_ID('tempdb.dbo.#cte') IS NOT NULL )
            DROP TABLE #cte;
        IF ( OBJECT_ID('tempdb.dbo.#style') IS NOT NULL )
            DROP TABLE #style;
        IF ( OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL )
            DROP TABLE #tmp;
        IF ( OBJECT_ID('tempdb.dbo.#t') IS NOT NULL )
            DROP TABLE #t;
        IF ( OBJECT_ID('tempdb.dbo.#SKU') IS NOT NULL )
            DROP TABLE #SKU;
        IF ( OBJECT_ID('tempdb.dbo.#usage') IS NOT NULL )
            DROP TABLE #usage;

-- get weekly usage

        CREATE TABLE #usage
            (
              location VARCHAR(12) ,
              part_no VARCHAR(40) ,
              usg_option CHAR(1) ,
              asofdate DATETIME ,
              e4_wu INT ,
              e12_wu INT ,
              e26_wu INT ,
              e52_wu INT ,
              subs_w4 INT ,
              subs_w12 INT ,
              promo_w4 INT ,
              promo_w12 INT
            );

        INSERT  INTO #usage
                ( location ,
                  part_no ,
                  usg_option ,
                  asofdate ,
                  e4_wu ,
                  e12_wu ,
                  e26_wu ,
                  e52_wu ,
                  subs_w4 ,
                  subs_w12 ,
                  promo_w4 ,
                  promo_w12
                )
                SELECT  location ,
                        part_no ,
                        usg_option ,
                        asofdate ,
                        e4_wu ,
                        e12_wu ,
                        e26_wu ,
                        e52_wu ,
                        subs_w4 ,
                        subs_w12 ,
                        promo_w4 ,
                        promo_w12
                FROM    dbo.f_cvo_calc_weekly_usage(@usg_option);

-- get sales history
        SELECT  i.category brand ,
                ia.field_2 style ,
                i.part_no ,
                i.type_code ,
                ISNULL(ia.field_28, '1/1/1900') pom_date ,
                ia.field_26 rel_date ,
                DATEDIFF(m, ia.field_26, ISNULL(s.yyyymmdd, @asofdate)) AS rel_month ,
                SUM(CASE WHEN ISNULL(s.yyyymmdd, @asofdate) < DATEADD(mm, 18,
                                                              ia.field_26)
                         THEN ISNULL(qsales, 0) - ISNULL(qreturns, 0)
                         ELSE 0
                    END) yr1_net_qty ,
                SUM(CASE WHEN ISNULL(s.yyyymmdd, @asofdate) < @asofdate
                              AND DATEDIFF(m, ia.field_26,
                                           ISNULL(s.yyyymmdd, @asofdate)) <= 12
                         THEN ISNULL(qsales, 0) - ISNULL(qreturns, 0)
                         ELSE 0
                    END) yr1_net_qty_b4_asof ,
                SUM(CASE WHEN ISNULL(s.yyyymmdd, @asofdate) < @asofdate
                              AND DATEDIFF(m, ia.field_26,
                                           ISNULL(s.yyyymmdd, @asofdate)) > 12
                         THEN ISNULL(qsales, 0) - ISNULL(qreturns, 0)
                         ELSE 0
                    END) yr2_net_qty_b4_asof ,
                SUM(ISNULL(qsales, 0)) AS sales_qty ,
                SUM(ISNULL(qreturns, 0)) AS ret_qty
        INTO    #sls_det
        FROM    inv_master i ( NOLOCK )
                INNER JOIN inv_master_add ia ( NOLOCK ) ON i.part_no = ia.part_no
                INNER JOIN #coll ON #coll.coll = i.category
                INNER JOIN #style_list ON #style_list.style = ia.field_2
-- inner join #sf on #sf.sf = ia.field_32
                LEFT OUTER JOIN cvo_sbm_details s ( NOLOCK ) ON s.part_no = i.part_no
                LEFT OUTER JOIN armaster a ( NOLOCK ) ON a.customer_code = s.customer
                                                         AND a.ship_to_code = s.ship_to
        WHERE   i.type_code IN ( 'FRAME', 'sun', 'BRUIT' )
                AND ia.field_26 BETWEEN @startdate AND @enddate
-- and isnull(ia.field_28, @pomdate) >= @pomdate
-- 10/22/2015 - and i.category not in ('rr','un')
                AND i.void = 'N'
                AND EXISTS ( SELECT 1
                             FROM   #sf
                             WHERE  #sf.sf = ISNULL(ia.field_32, '') )
                AND ISNULL(s.yyyymmdd, @asofdate) >= DATEADD(mm, -18,
                                                             @asofdate) -- look back 18 months
                AND ISNULL(s.customer, '') NOT IN ( '045733', '019482',
                                                    '045217' ) -- stanton and insight and costco
                AND ISNULL(s.return_code, '') = ''
                AND ISNULL(s.isCL, 0) = 0 -- no closeouts
                AND ISNULL(s.location, @loc) = @loc

--and s.yyyymmdd >= dateadd(mm,-18,@asofdate) -- look back 18 months
--and s.customer not in ('045733','019482','045217') -- stanton and insight and costco
--and s.return_code = ''
--and s.iscl = 0 -- no closeouts
--and s.location = @loc
        GROUP BY ia.field_26 ,
                ia.field_28 ,
                i.category ,
                ia.field_2 ,
                i.part_no ,
                i.type_code ,
                -- yyyymmdd
				DATEDIFF(m, ia.field_26, ISNULL(s.yyyymmdd, @asofdate)); -- end cte

        IF @debug = 1
            SELECT DISTINCT
                    rel_date
            FROM    #sls_det; -- where part_no like 'jm185%'

        SELECT  #sls_det.brand ,
                #sls_det.style ,
                MAX(type_code) type_code ,
                ISNULL(tt.style_pom, MIN(#sls_det.pom_date)) pom_date ,
                MIN(rel_date) rel_date ,
                rel_month ,
                SUM(yr1_net_qty) yr1_net_qty ,
                SUM(yr1_net_qty_b4_asof) yr1_net_qty_b4_asof ,
                SUM(yr2_net_qty_b4_asof) yr2_net_qty_b4_asof ,
                SUM(sales_qty) AS sales_qty ,
                SUM(ret_qty) AS ret_qty
        INTO    #cte
        FROM    #sls_det
                LEFT OUTER JOIN ( SELECT    t.Collection brand ,
                                            t.model style ,
                                            MAX(t.pom_date) style_pom
                                  FROM      dbo.cvo_inv_master_r2_vw t
                                            JOIN #sls_det ON #sls_det.brand = t.Collection
                                                             AND #sls_det.style = t.model
                                  GROUP BY  t.Collection ,
                                            t.model
                                  HAVING    COUNT(t.part_no) = COUNT(t.pom_date) -- fully pom'd style
                                ) AS tt ON tt.brand = #sls_det.brand
                                           AND tt.style = #sls_det.style
        GROUP BY #sls_det.brand ,
                #sls_det.style ,
                #sls_det.rel_month ,
                tt.style_pom;
-- must have 3 or mor months of activity to be included
-- having max(rel_month) >=3

        IF @debug = 1
            SELECT  ' cte ' ,
                    *
            FROM    #cte; -- where style = '185' order by style, rel_month

-- Create style summary list
-- 11/20/2014 - include suns, but don't rank them ... yet

        SELECT  cte.brand ,
                cte.style ,
                '' AS part_no ,
                MIN(cte.pom_date) pom_date ,
                MIN(cte.rel_date) rel_date ,
                MAX(rel_month) mth_since_rel ,
                CASE WHEN MAX(rel_month) BETWEEN 13 AND 18
                     THEN 6 - ( MAX(rel_month) - 12 )
                     WHEN MAX(rel_month) <= 12 THEN 12
                     ELSE 0
                END mths_left_y2 ,
                CASE WHEN MAX(rel_month) > 12 THEN 0
                     ELSE 12 - MAX(rel_month)
                END mths_left_y1 ,
                DATEADD(mm, 18 - MAX(rel_month), @asofdate) yr2_end_date ,
                DATEADD(mm, 12 - MAX(rel_month), @asofdate) yr1_end_date ,
                inv_rank = CASE WHEN MAX(cte.type_code) = 'sun' THEN ''
                                WHEN MIN(cte.rel_date) < @startrank THEN ''
                                WHEN MIN(cte.rel_date) > DATEADD(mm, -3,
                                                              @asofdate)
                                THEN 'N'
                                ELSE ISNULL(( SELECT TOP 1
                                                        inv_Rank
                                              FROM      #inv_rank r
                                              WHERE     cte.brand = r.collection
                                                        AND SUM(CASE
                                                              WHEN ISNULL(cte.rel_month,
                                                              0) <= 3
                                                              THEN ISNULL(cte.sales_qty,
                                                              0)
                                                              ELSE 0
                                                              END) > r.m3
                                              ORDER BY  r.collection ASC ,
                                                        r.m3 DESC
                                            ), '')
                           END ,
                rank_24m_sales = CASE WHEN MIN(cte.rel_date) < @startrank
                                           OR MAX(cte.type_code) = 'sun'
                                      THEN 0
                                      ELSE ISNULL(( SELECT TOP 1
                                                            m24
                                                    FROM    #inv_rank r
                                                    WHERE   cte.brand = r.collection
                                                            AND SUM(CASE
                                                              WHEN ISNULL(cte.rel_month,
                                                              0) <= 3
                                                              THEN ISNULL(cte.sales_qty,
                                                              0)
                                                              ELSE 0
                                                              END) > r.m3
                                                    ORDER BY r.collection ASC ,
                                                            r.m3 DESC
                                                  ), 0)
                                 END ,
                rank_12m_sales = CASE WHEN MIN(cte.rel_date) < @startrank
                                           OR MAX(cte.type_code) = 'sun'
                                      THEN 0
                                      ELSE ISNULL(( SELECT TOP 1
                                                            m12
                                                    FROM    #inv_rank r
                                                    WHERE   cte.brand = r.collection
                                                            AND SUM(CASE
                                                              WHEN ISNULL(cte.rel_month,
                                                              0) <= 3
                                                              THEN ISNULL(cte.sales_qty,
                                                              0)
                                                              ELSE 0
                                                              END) > r.m3
                                                    ORDER BY r.collection ASC ,
                                                            r.m3 DESC
                                                  ), 0)
                                 END ,
                sales_y2tg = CASE WHEN MIN(cte.rel_date) < @startrank
                                       OR MAX(cte.type_code) = 'sun' THEN 0
                                  ELSE ISNULL(( SELECT TOP 1
                                                        m24
                                                FROM    #inv_rank r
                                                WHERE   cte.brand = r.collection
                                                        AND SUM(CASE
                                                              WHEN ISNULL(cte.rel_month,
                                                              0) <= 3
                                                              THEN ISNULL(cte.sales_qty,
                                                              0)
                                                              ELSE 0
                                                              END) > r.m3
                                                ORDER BY r.collection ASC ,
                                                        r.m3 DESC
                                              ), 0)
                                       - SUM(CASE WHEN rel_month BETWEEN 13 AND 24
                                                  THEN sales_qty
                                                  ELSE 0
                                             END)
                             END ,
                sales_y1tg = CASE WHEN MIN(cte.rel_date) < @startrank
                                       OR MAX(cte.type_code) = 'sun' THEN 0
                                  ELSE ISNULL(( SELECT TOP 1
                                                        m12
                                                FROM    #inv_rank r
                                                WHERE   cte.brand = r.collection
                                                        AND SUM(CASE
                                                              WHEN ISNULL(cte.rel_month,
                                                              0) <= 3
                                                              THEN ISNULL(cte.sales_qty,
                                                              0)
                                                              ELSE 0
                                                              END) > r.m3
                                                ORDER BY r.collection ASC ,
                                                        r.m3 DESC
                                              ), 0)
                                       - SUM(CASE WHEN rel_month <= 12
                                                  THEN sales_qty
                                                  ELSE 0
                                             END)
                             END ,
                SUM(CASE WHEN rel_month <= 3 THEN sales_qty
                         ELSE 0
                    END) [Sales M1-3] ,
                SUM(CASE WHEN rel_month <= 12 THEN sales_qty
                         ELSE 0
                    END) [Sales M1-12] ,
                ISNULL(drp.s_e4_wu, 0) s_e4_wu ,
                ISNULL(drp.s_e12_wu, 0) s_e12_wu ,
                ISNULL(drp.s_e52_wu, 0) s_e52_wu ,
                ISNULL(drp.s_promo_w4, 0) s_promo_w4 ,
                ISNULL(drp.s_promo_w12, 0) s_promo_w12
        INTO    #style -- tally up style level information
        FROM    #cte cte
                LEFT OUTER JOIN ( SELECT -- usage info
                                            i.category collection ,
                                            ia.field_2 style ,
                                            SUM(ISNULL(e4_wu, 0)) s_e4_wu ,
                                            SUM(ISNULL(e12_wu, 0)) s_e12_wu ,
                                            SUM(ISNULL(e52_wu, 0)) s_e52_wu ,
                                            SUM(ISNULL(promo_w4, 0)) s_promo_w4 ,
                                            SUM(ISNULL(promo_w12, 0)) s_promo_w12
                                  FROM      inv_master i ( NOLOCK )
                                            LEFT OUTER JOIN #usage drp ( NOLOCK ) ON i.part_no = drp.part_no
                                            INNER JOIN inv_master_add ia ( NOLOCK ) ON ia.part_no = i.part_no
                                  WHERE     i.void = 'N'
                                            AND drp.location = @loc
                                  GROUP BY  i.category ,
                                            ia.field_2
                                ) AS drp ON drp.collection = cte.brand
                                            AND drp.style = cte.style
        GROUP BY cte.brand ,
                cte.style ,
                drp.s_e4_wu ,
                drp.s_e12_wu ,
                drp.s_e52_wu ,
                drp.s_promo_w4 ,
                drp.s_promo_w12
        ORDER BY cte.brand ,
                inv_rank ,
                cte.style;

-- select * from #style where style = '185'

-- Check for current styles

        IF @debug = 1
            SELECT  *
            FROM    #style;

-- 8/31/2015 - don't do this yet

--if @current = 1 -- if reporting current styles/skus only remove any pom styles pom'd before the as of date (12/3/2014)
--begin
--	delete from #style where ( pom_date <> '1/1/1900' and pom_date < @asofdate )
--end

        UPDATE  #style
        SET     inv_rank = 'N' ,
                rank_24m_sales = 0 ,
                rank_12m_sales = 0 ,
                sales_y1tg = 0 ,
                sales_y2tg = 0
        WHERE   mth_since_rel < 3
                OR inv_rank = 'N';

        UPDATE  #style
        SET     rank_24m_sales = 0 ,
                rank_12m_sales = 0 ,
                sales_y1tg = 0 ,
                sales_y2tg = 0
        WHERE   inv_rank = '';

-- select * From #style where style = 'clarissa'

-- summarize further and start adding part level information

        SELECT  s.brand ,
                s.style ,
                i.part_no ,
                s.rel_date ,
                s.pom_date ,
                s.mth_since_rel ,
                s.mths_left_y2 ,
                s.mths_left_y1 ,
                s.yr2_end_date ,
                s.yr1_end_date ,
                s.inv_Rank ,
                s.rank_24m_sales ,
                s.rank_12m_sales ,
                CASE WHEN s.sales_y2tg > 0 THEN s.sales_y2tg
                     ELSE 0
                END AS sales_y2tg ,
                CASE WHEN s.sales_y1tg > 0 THEN s.sales_y1tg
                     ELSE 0
                END AS sales_y1tg ,
                ROUND(CASE WHEN mths_left_y2 = 0 THEN 0
                           ELSE ( CASE WHEN s.sales_y2tg < 0 THEN 0
                                       ELSE s.sales_y2tg
                                  END ) / mths_left_y2
                      END, 0, 1) AS sales_y2tg_per_month ,
                ROUND(CASE WHEN mths_left_y1 = 0 THEN 0
                           ELSE ( CASE WHEN s.sales_y1tg < 0 THEN 0
                                       ELSE s.sales_y1tg
                                  END ) / mths_left_y1
                      END, 0, 1) AS sales_y1tg_per_month ,
                ISNULL(s.s_e4_wu, 0) s_e4_wu ,
                ISNULL(s.s_e12_wu, 0) s_e12_wu ,
                ISNULL(s.s_e52_wu, 0) s_e52_wu ,
                ISNULL(s.s_promo_w4, 0) s_promo_w4 ,
                ISNULL(s.s_promo_w12, 0) s_promo_w12 ,
                ISNULL(drp.p_e4_wu, 0) p_e4_wu ,
                ISNULL(drp.p_e12_wu, 0) p_e12_wu ,
                ISNULL(drp.p_e52_wu, 0) p_e52_wu ,
                ISNULL(drp.p_subs_w4, 0) p_subs_w4 ,
                ISNULL(drp.p_subs_w12, 0) p_subs_w12 ,
                s_mth_usg = ROUND(( CASE WHEN mth_since_rel <= 3
                                         THEN ISNULL(s_e4_wu, 0) * 52 / 12
                                         ELSE ISNULL(s_e12_wu, 0) * 52 / 12
                                    END ), 0, 1) ,
                p_mth_usg = ROUND(( CASE WHEN mth_since_rel <= 3
                                         THEN ISNULL(p_e4_wu, 0) * 52 / 12
                                         ELSE ISNULL(p_e12_wu, 0) * 52 / 12
                                    END ), 0, 1) ,
                s_mth_usg_mult = ROUND(( ( CASE WHEN mth_since_rel <= 3
                                                THEN ISNULL(s_e4_wu, 0) * 52
                                                     / 12
                                                ELSE ISNULL(s_e12_wu, 0) * 52
                                                     / 12
                                           END ) * mult ), 0, 1) ,
                p_mth_usg_mult = ROUND(( ( CASE WHEN mth_since_rel <= 3
                                                THEN ISNULL(p_e4_wu, 0) * 52
                                                     / 12
                                                ELSE ISNULL(p_e12_wu, 0) * 52
                                                     / 12
                                           END ) * mult ), 0, 1) ,
                pct_of_style = ROUND(( CASE WHEN ISNULL(s_e12_wu, 0) <> 0
                                            THEN ISNULL(p_e12_wu, 0)
                                                 / ISNULL(s_e12_wu, 0)
                                            ELSE 0
                                       END ), 4) ,
                first_po = ISNULL(( SELECT TOP 1
                                            quantity
                                    FROM    releases
                                    WHERE   part_no = i.part_no
                                            AND location = @loc
                                            AND part_type = 'p'
                                            AND status = 'c'
                                    ORDER BY release_date
                                  ), 0) ,
                pct_first_po = CAST (0 AS FLOAT) -- calulate this later
                ,
                p_sales_m1_3 = 0 ,
                pct_sales_style_m1_3 = CAST(0 AS FLOAT) ,
                mm ,
                mult ,
                s_mult ,
                sort_seq -- stuff from #dmd_mult
                ,
                mth_demand_src = 'xxx' ,
                mth_demand_mult = NULL ,
                p_po_qty_y1 = CAST (0 AS FLOAT)
        INTO    #t
        FROM    inv_master i ( NOLOCK )
                INNER JOIN inv_master_add ia ( NOLOCK ) ON i.part_no = ia.part_no
                INNER JOIN #style s ON s.brand = i.category
                                       AND s.style = ia.field_2
                                       AND ia.field_26 BETWEEN @startdate AND @enddate
                LEFT OUTER JOIN ( SELECT -- drp info by part
                                            drp.part_no ,
                                            SUM(e4_wu) p_e4_wu ,
                                            SUM(e12_wu) p_e12_wu ,
                                            SUM(e52_wu) p_e52_wu ,
                                            SUM(drp.subs_w4) p_subs_w4 ,
                                            SUM(drp.subs_w12) p_subs_w12
                                  FROM      #usage drp ( NOLOCK )
                                  WHERE     drp.location = @loc
                                  GROUP BY  drp.part_no
                                ) AS drp ON drp.part_no = i.part_no
                CROSS JOIN #dmd_mult
        WHERE   i.type_code IN ( 'frame', 'sun', 'bruit' )
                AND i.void = 'n';

        CREATE INDEX idx_t ON #t (part_no ASC);

        IF ISNULL(@debug, 0) = 1
            BEGIN
                SELECT  *
                FROM    #dmd_mult;
                SELECT  *
                FROM    #t;
            END; 

        IF @current = 1  -- if reporting current styles/skus only remove any pom skus 
            BEGIN
                DELETE  FROM #t
                WHERE   EXISTS ( SELECT 1
                                 FROM   inv_master_add
                                 WHERE  part_no = #t.part_no
                                        AND field_28 IS NOT NULL
                                        AND field_28 < @asofdate );
            END

-- figure out pct of first purchase
;
        WITH    x AS ( SELECT DISTINCT
                                brand ,
                                style ,
                                part_no ,
                                first_po ,
                                style_first_po = ( SELECT   SUM(ISNULL(t.first_po,
                                                              0))
                                                   FROM     ( SELECT DISTINCT
                                                              part_no ,
                                                              first_po
                                                              FROM
                                                              #t
                                                              WHERE
                                                              #t.style = sku.style
                                                              AND #t.brand = sku.brand
                                                            ) AS t
                                                 )
                       FROM     #t sku
                     )
            UPDATE  #t
            SET     pct_first_po = ROUND(( CASE WHEN ISNULL(x.style_first_po,
                                                            0.00) = 0.00
                                                THEN 0.00
                                                ELSE CAST(ISNULL(x.first_po,
                                                              0.00)
                                                     / ISNULL(x.style_first_po,
                                                              1) AS FLOAT)
                                           END ), 4)
            FROM    #t
                    INNER JOIN x ON #t.part_no = x.part_no
            WHERE   ISNULL(x.style_first_po, 0.00) <> 0.00
-- where #t.style = 'clarissa'

-- figure out first 3 months sales by part

;
        WITH    x AS ( SELECT   s.part_no ,
                                SUM(s.sales_qty) p_sales_m1_3
                       FROM     #sls_det s
                       WHERE    s.rel_month <= 3
                       GROUP BY part_no
--order by part_no
                     )
            UPDATE  #t
            SET     #t.p_sales_m1_3 = x.p_sales_m1_3 ,
                    #t.pct_sales_style_m1_3 = ROUND(x.p_sales_m1_3
                                                    / ISNULL(s.[Sales M1-3], 1),
                                                    4)
            FROM    #t
                    INNER JOIN x ON #t.part_no = x.part_no
                    INNER JOIN #style s ON s.brand = #t.brand
                                           AND s.style = #t.style
            WHERE   ISNULL(s.[Sales M1-3], 0) <> 0;
-- select * From #t


-- Figure out forecast line

        DECLARE @sku VARCHAR(40) ,
            @mths_y1 INT ,
            @mths_y2 INT;

        SET @sku = ( SELECT MIN(part_no)
                     FROM   #t
                     WHERE  inv_Rank IN ( 'A', 'B', 'C' )
                   );
        WHILE @sku IS NOT NULL
            BEGIN
                SELECT  @mths_y1 = mths_left_y1 ,
                        @mths_y2 = mths_left_y2
                FROM    #t
                WHERE   part_no = @sku;

                IF ( @mths_y1 > 0 )
                    UPDATE  #t
                    SET     mth_demand_src = 'FCT' ,
                            mth_demand_mult = CASE WHEN mths_left_y1 <= 0
                                                   THEN 0
                                                   ELSE s_mult * mult
                                                        * ( sales_y1tg
                                                            * pct_of_style )
                                                        / mths_left_y1
                                              END
                    WHERE   sort_seq <= mths_left_y1
                            AND mth_demand_mult IS NULL
                            AND part_no = @sku;
                IF ( @mths_y2 > 0 )
                    UPDATE  #t
                    SET     mth_demand_src = 'FCT' ,
                            mth_demand_mult = CASE WHEN mths_left_y2 <= 0
                                                   THEN 0
                                                   ELSE s_mult * mult
                                                        * ( sales_y2tg
                                                            * pct_of_style )
                                                        / mths_left_y2
                                              END
                    WHERE   mth_demand_mult IS NULL
                            AND sort_seq + @mths_y1 <= mths_left_y2 + @mths_y1
                            AND part_no = @sku;
                UPDATE  #t
                SET     mth_demand_src = 'FCT' ,
                        mth_demand_mult = s_mult * mult
                        * ( CASE WHEN mth_since_rel > 3
                                 THEN ISNULL(p_e12_wu, 0) * 52 / 12
                                 ELSE ISNULL(p_e4_wu, 0) * 52 / 12
                            END )
                WHERE   /* mth_since_rel > 18 and */
                        mth_demand_mult IS NULL
                        AND part_no = @sku;
	
                SET @sku = ( SELECT MIN(part_no)
                             FROM   #t
                             WHERE  part_no > @sku
                                    AND inv_Rank IN ( 'A', 'B', 'C' )
                           );
            END;

-- select * from #t

        SELECT DISTINCT
                mth_demand_src AS LINE_TYPE ,
                #t.part_no sku ,
                #t.mm ,
                bucket = DATEADD(m, #t.sort_seq - 1, @asofdate) ,
                QOH = 0 ,
                atp = 0 ,
                ROUND(#t.mth_demand_mult, 0, 1) AS quantity ,
                #t.mult ,
                #t.s_mult ,
                #t.sort_seq
        INTO    #SKU
        FROM    #t
        WHERE   mth_demand_src <> 'xxx';

-- order by #t.part_no, sort_seq

-- add DRP data too

        INSERT  INTO #SKU
                SELECT  'DRP' AS LINE_TYPE ,
                        #t.part_no sku ,
                        #t.mm ,
                        bucket = DATEADD(m, #t.sort_seq - 1, @asofdate) ,
                        QOH = 0 ,
                        atp = 0 ,
                        quantity = ROUND(#dmd_mult.mult * #dmd_mult.s_mult
                                         * ( CASE WHEN DATEDIFF(mm,
                                                              ia.field_26,
                                                              @asofdate) > 3
                                                  THEN ISNULL(p_e12_wu, 0)
                                                       * 52 / 12
                                                  ELSE ISNULL(p_e4_wu, 0) * 52
                                                       / 12
                                             END ), 0, 1) ,
                        #t.mult ,
                        #t.s_mult ,
                        #t.sort_seq
                FROM    #t
                        INNER JOIN #dmd_mult ON #t.sort_seq = #dmd_mult.sort_seq
                        INNER JOIN inv_master_add ia ON ia.part_no = #t.part_no;

-- order by #t.part_no, sort_seq


-- GET PURCHASE ORDER LINES MAPPED OUT BY MONTH UNTIL THE ENDING DATE
        INSERT  INTO #SKU
                SELECT -- 
                        'PO' AS line_type ,
                        #t.part_no sku ,
                        #t.mm
--,bucket = case when MONTH(DATEADD(m,DATEDIFF(m,0,r.inhouse_date),0)) <= MONTH(@asofdate) 
--				AND YEAR(DATEADD(m,DATEDIFF(m,0,r.inhouse_date),0)) <= YEAR(@asofdate)
--		  THEN @asofdate -- if the po line is past due
--		  else DATEADD(m,DATEDIFF(m,0,r.inhouse_date), 0) END
                        ,
                        bucket = DATEADD(m, #t.sort_seq - 1, @asofdate) ,
                        QOH = 0 ,
                        atp = 0 ,
                        ROUND(SUM(ISNULL(r.quantity, 0))
                              - SUM(ISNULL(r.received, 0)), 1) quantity ,
                        #t.mult ,
--CASE	 WHEN MONTH(r.inhouse_date) < MONTH(@asofdate) AND YEAR(r.inhouse_date) <= YEAR(@asofdate) THEN 1
--		 when month(r.inhouse_date) < month(@asofdate) AND YEAR(r.inhouse_date) > YEAR(@asofdate)
--			then month(r.inhouse_date) - MONTH(@ASOFDATE) + 13
--		 ELSE month(r.inhouse_date) - MONTH(@ASOFDATE) + 1 
--		 END  as sort_seq
                        #t.s_mult ,
                        #t.sort_seq
                FROM    #t
                        INNER JOIN inv_master_add i ( NOLOCK ) ON i.part_no = #t.part_no
                        INNER JOIN inv_master inv ( NOLOCK ) ON inv.part_no = i.part_no
                        LEFT OUTER JOIN releases r ( NOLOCK ) ON #t.part_no = r.part_no
                                                              AND r.location = @loc
                WHERE   1 = 1
-- AND r.inhouse_date <= @pomdate 
--and  #t.mm = case when month(DATEADD(m,DATEDIFF(m,0,r.inhouse_date),0)) < month(@asofdate)
--					and YEAR(DATEADD(m,DATEDIFF(m,0,r.inhouse_date),0)) < YEAR(@asofdate)
                        AND #t.mm = CASE WHEN DATEADD(m,
                                                      DATEDIFF(m, 0,
                                                              r.inhouse_date),
                                                      0) < @asofdate
                                         THEN MONTH(@asofdate)
                                         ELSE MONTH(DATEADD(m,
                                                            DATEDIFF(m, 0,
                                                              r.inhouse_date),
                                                            0))
                                    END
                        AND type_code IN ( 'frame', 'sun', 'bruit' )
                        AND r.status = 'o'
                        AND r.part_type = 'p' -- and r.location = @loc
                        AND inv.void = 'N'
-- 10/6/2015 - make the outer range < not <= to avoid 13th bucket on report
-- AND DATEADD(m,DATEDIFF(m,0,r.inhouse_date),0) <= DATEADD(YEAR,1,@asofdate)
                        AND DATEADD(m, DATEDIFF(m, 0, r.inhouse_date), 0) < DATEADD(YEAR,
                                                              1, @asofdate)
                GROUP BY inv.category ,
                        i.field_2 ,
                        #t.part_no ,
                        DATEADD(m, DATEDIFF(m, 0, r.inhouse_date), 0) ,
                        MONTH(r.inhouse_date) ,
                        #t.mm ,
                        #t.mult ,
                        #t.s_mult ,
                        #t.sort_seq;

        IF @debug = 1
            SELECT  *
            FROM    #SKU
            WHERE   LINE_TYPE = 'po'
            ORDER BY sku ,
                    sort_seq;

-- select * From #t

-- 090314 - tag
-- get sales since the asof date, and use it to consume the demand line

        INSERT  INTO #SKU
                SELECT -- 
                        'SLS' AS line_type ,
                        #t.part_no sku ,
                        ISNULL(r.X_MONTH, MONTH(@asofdate)) mm ,
                        bucket = DATEADD(m, #t.sort_seq - 1, @asofdate) ,
                        QOH = 0 ,
                        atp = 0 ,
                        ROUND(SUM(ISNULL(r.qsales, 0) - ISNULL(r.qreturns, 0)),
                              0, 1) quantity ,
                        #t.mult ,
                        #t.s_mult ,
                        CASE WHEN ISNULL(r.X_MONTH, MONTH(@asofdate)) < MONTH(@asofdate)
                             THEN ISNULL(r.X_MONTH, MONTH(@asofdate))
                                  - MONTH(@asofdate) + 13
                             ELSE ISNULL(r.X_MONTH, MONTH(@asofdate))
                                  - MONTH(@asofdate) + 1
                        END AS sort_seq
                FROM    #t
                        INNER JOIN inv_master_add i ( NOLOCK ) ON i.part_no = #t.part_no
                        INNER JOIN inv_master inv ( NOLOCK ) ON inv.part_no = i.part_no
                        LEFT OUTER JOIN cvo_sbm_details r ( NOLOCK ) ON #t.part_no = r.part_no
                WHERE   r.yyyymmdd >= @asofdate 
-- and @pomdate 
                        AND r.X_MONTH = #t.mm
                        AND type_code IN ( 'frame', 'sun', 'bruit' )
-- and r.status = 'o' and r.part_type = 'p' and r.location = @loc
                        AND inv.void = 'N'
                GROUP BY inv.category ,
                        i.field_2 ,
                        #t.part_no ,
                        r.X_MONTH ,
                        #t.mult ,
                        #t.s_mult ,
                        #t.sort_seq;
-- select * From #SKU  order by sku, sort_seq
-- select * From #t

-- 06/17/2015 - add orders line

        INSERT  INTO #SKU
                SELECT -- 
                        'ORD' AS line_type ,
                        #t.part_no sku ,
                        rr.X_MONTH mm ,
                        bucket = DATEADD(m, #t.sort_seq - 1, @asofdate) ,
                        QOH = 0 ,
                        atp = 0 ,
                        ROUND(SUM(ISNULL(rr.open_qty, 0)), 0, 1) quantity ,
                        #t.mult ,
                        #t.s_mult ,
                        CASE WHEN rr.X_MONTH < MONTH(@asofdate)
                             THEN rr.X_MONTH - MONTH(@asofdate) + 13
                             ELSE rr.X_MONTH - MONTH(@asofdate) + 1
                        END AS sort_seq
                FROM    #t
                        INNER JOIN inv_master_add i ( NOLOCK ) ON i.part_no = #t.part_no
                        INNER JOIN inv_master inv ( NOLOCK ) ON inv.part_no = i.part_no
                        LEFT OUTER JOIN ( SELECT    ol.part_no ,
                                                    X_MONTH = CASE
                                                              WHEN o.sch_ship_date < @asofdate
                                                              THEN MONTH(@asofdate)
                                                              ELSE MONTH(o.sch_ship_date)
                                                              END ,
                                                    YYYYMMDD = CASE
                                                              WHEN o.sch_ship_date < @asofdate
                                                              THEN @asofdate
                                                              ELSE o.sch_ship_date
                                                              END ,
                                                    open_qty = SUM(ol.ordered
                                                              - ol.shipped
                                                              - ISNULL(ha.qty,
                                                              0))
                                          FROM      orders o ( NOLOCK )
                                                    INNER JOIN ord_list ol ( NOLOCK ) ON ol.order_no = o.order_no
                                                              AND ol.order_ext = o.ext
                                                    LEFT OUTER JOIN dbo.cvo_hard_allocated_vw ha ( NOLOCK ) ON ha.line_no = ol.line_no
                                                              AND ha.order_ext = ol.order_ext
                                                              AND ha.order_no = ol.order_no
                                                    LEFT OUTER JOIN cvo_soft_alloc_det sa ( NOLOCK ) ON sa.order_no = ol.order_no
                                                              AND sa.order_ext = ol.order_ext
                                                              AND sa.line_no = ol.line_no
                                                              AND sa.part_no = ol.part_no
                                          WHERE     o.status < 'r'
                                                    AND o.status <> 'c'  -- 07/29/2015 - dont include credit hold orders
                                                    AND o.type = 'i'
                                                    AND ol.ordered > ol.shipped
                                                    + ISNULL(ha.qty, 0)
                                                    AND ISNULL(sa.status, -3) = -3 -- future orders not yet soft allocated
                                                    AND ol.part_type = 'P'
                                                    AND ol.location = @loc
                                          GROUP BY  ol.part_no ,
                                                    MONTH(o.sch_ship_date) ,
                                                    o.sch_ship_date
                                        ) rr ON #t.part_no = rr.part_no
                WHERE   rr.YYYYMMDD >= @asofdate 
-- and @pomdate 
                        AND rr.X_MONTH = #t.mm
                        AND type_code IN ( 'frame', 'sun', 'bruit' )
-- and r.status = 'o' and r.part_type = 'p' and r.location = @loc
                        AND inv.void = 'N'
                GROUP BY inv.category ,
                        i.field_2 ,
                        #t.part_no ,
                        rr.X_MONTH ,
                        #t.mult ,
                        #t.s_mult ,
                        #t.sort_seq;
-- select * From #SKU  order by sku, sort_seq
-- select * From #t




-- figure out the running total inv available line
-- 11/19/14 - Change INV line calculation to consume the demand line using the greater of fct/drp or sls as the demand line
-- 7/20/15 - add avail to promise

        DECLARE @inv INT ,
            @last_inv INT ,
            @INV_AVL INT ,
            @fct INT ,
            @drp INT ,
            @sls INT ,
            @po INT ,
            @ord INT ,
            @atp INT;

        CREATE INDEX idx_f ON #SKU (sku ASC);

        SELECT  @sku = MIN(sku)
        FROM    #SKU;
-- 7/15/2016 - calc starting inventory with allocations if usage is on orders.
        SELECT  @last_inv = ISNULL(cia.in_stock, 0) + ISNULL(cia.QcQty2, 0)
                - CASE WHEN @usg_option = 'O' THEN 0
                       ELSE ISNULL(cia.SOF, 0) + ISNULL(cia.Allocated, 0)
                  END ,
                @atp = ISNULL(qty_avl, 0)
        FROM    cvo_item_avail_vw cia
        WHERE   cia.part_no = @sku
                AND cia.location = @loc;

        SELECT  @sort_seq = 0;
        SELECT  @INV_AVL = @last_inv;
        SELECT  @fct = SUM(ISNULL(quantity, 0))
        FROM    #SKU
        WHERE   sku = @sku
                AND LINE_TYPE = 'fct'
                AND sort_seq = @sort_seq + 1;
        SELECT  @drp = SUM(ISNULL(quantity, 0))
        FROM    #SKU
        WHERE   sku = @sku
                AND LINE_TYPE = 'drp'
                AND sort_seq = @sort_seq + 1;
        SELECT  @sls = SUM(ISNULL(quantity, 0))
        FROM    #SKU
        WHERE   sku = @sku
                AND LINE_TYPE = 'sls'
                AND sort_seq = @sort_seq + 1;
        SELECT  @po = SUM(ISNULL(quantity, 0))
        FROM    #SKU
        WHERE   sku = @sku
                AND LINE_TYPE = 'po'
                AND sort_seq = @sort_seq + 1;
        SELECT  @ord = SUM(ISNULL(quantity, 0))
        FROM    #SKU
        WHERE   sku = @sku
                AND LINE_TYPE = 'ord'
                AND sort_seq = @sort_seq + 1;

-- select * From cvo_item_avail_vw where part_no = 'etkatbur5018' and location = '001'


        WHILE @sku IS NOT NULL
            BEGIN
                UPDATE  #SKU
                SET     QOH = ISNULL(@last_inv, 0) ,
                        atp = ISNULL(@atp, 0)
                WHERE   sku = @sku;
                WHILE @sort_seq < 12
                    BEGIN
                        SELECT  @INV_AVL = @INV_AVL
                                - -- add option to run inventory line against forecast or drp
		( CASE WHEN EXISTS ( SELECT 1
                             FROM   #SKU
                             WHERE  sku = @sku
                                    AND LINE_TYPE = 'FCT' )
                    AND @UseDrp = 0 THEN CASE WHEN @fct < @sls THEN @sls
                                              ELSE @fct
                                         END
               ELSE CASE WHEN @drp < @sls THEN @sls
                         ELSE @drp
                    END
          END ) 
		-- add back sales after the as of date (consume the demand line)
                                + ISNULL(@sls, 0) + ISNULL(@po, 0)
                                - ISNULL(@ord, 0);

                        INSERT  #SKU
                                SELECT  'V' AS line_type ,
                                        sku = @sku ,
                                        mm = #t.mm ,
                                        bucket = DATEADD(m, @sort_seq,
                                                         @asofdate) ,
                                        QOH = ISNULL(@last_inv, 0) ,
                                        atp = ISNULL(@atp, 0) ,
                                        QUANTITY = ISNULL(@INV_AVL, 0) ,
                                        mult = #t.mult ,
                                        s_mult = #t.s_mult ,
                                        SORT_SEQ = #t.sort_seq
                                FROM    #t
                                WHERE   #t.part_no = @sku
                                        AND SORT_SEQ = @sort_seq + 1;

                        SELECT  @sort_seq = @sort_seq + 1;
                        SELECT  @fct = SUM(ISNULL(quantity, 0))
                        FROM    #SKU
                        WHERE   sku = @sku
                                AND LINE_TYPE = 'fct'
                                AND sort_seq = @sort_seq + 1;
                        SELECT  @drp = SUM(ISNULL(quantity, 0))
                        FROM    #SKU
                        WHERE   sku = @sku
                                AND LINE_TYPE = 'drp'
                                AND sort_seq = @sort_seq + 1;
                        SELECT  @sls = SUM(ISNULL(quantity, 0))
                        FROM    #SKU
                        WHERE   sku = @sku
                                AND LINE_TYPE = 'sls'
                                AND sort_seq = @sort_seq + 1;
                        SELECT  @po = SUM(ISNULL(quantity, 0))
                        FROM    #SKU
                        WHERE   sku = @sku
                                AND LINE_TYPE = 'po'
                                AND sort_seq = @sort_seq + 1;
                        SELECT  @ord = SUM(ISNULL(quantity, 0))
                        FROM    #SKU
                        WHERE   sku = @sku
                                AND LINE_TYPE = 'ord'
                                AND sort_seq = @sort_seq + 1;
                    END;
                SELECT  @sku = MIN(sku)
                FROM    #SKU
                WHERE   sku > @sku;
-- 7/15/2016 - calc starting inventory with allocations if usage is on orders.
                SELECT  @last_inv = ISNULL(cia.in_stock, 0)
                        + ISNULL(cia.QcQty2, 0)
                        - CASE WHEN @usg_option = 'O' THEN 0
                               ELSE ISNULL(cia.SOF, 0) + ISNULL(cia.Allocated,
                                                              0)
                          END ,
                        @atp = ISNULL(qty_avl, 0)
                FROM    cvo_item_avail_vw cia
                WHERE   cia.part_no = @sku
                        AND cia.location = @loc;
                SELECT  @sort_seq = 0;
                SELECT  @INV_AVL = @last_inv;
                SELECT  @fct = SUM(ISNULL(quantity, 0))
                FROM    #SKU
                WHERE   sku = @sku
                        AND LINE_TYPE = 'fct'
                        AND sort_seq = @sort_seq + 1;
                SELECT  @drp = SUM(ISNULL(quantity, 0))
                FROM    #SKU
                WHERE   sku = @sku
                        AND LINE_TYPE = 'drp'
                        AND sort_seq = @sort_seq + 1;
                SELECT  @sls = SUM(ISNULL(quantity, 0))
                FROM    #SKU
                WHERE   sku = @sku
                        AND LINE_TYPE = 'sls'
                        AND sort_seq = @sort_seq + 1;
                SELECT  @po = SUM(ISNULL(quantity, 0))
                FROM    #SKU
                WHERE   sku = @sku
                        AND LINE_TYPE = 'po'
                        AND sort_seq = @sort_seq + 1;
                SELECT  @ord = SUM(ISNULL(quantity, 0))
                FROM    #SKU
                WHERE   sku = @sku
                        AND LINE_TYPE = 'ord'
                        AND sort_seq = @sort_seq + 1;
            END;
-- final select


-- fixup
        SELECT DISTINCT
-- #style.*
                #style.brand ,
                #style.style ,
                specs.vendor ,
                specs.type_code ,
                specs.gender ,
                specs.material ,
                specs.moq ,
                specs.watch ,
                specs.sf ,
                rel_date = ( SELECT MIN(release_date)
                             FROM   cvo_inv_master_r2_vw
                             WHERE  Collection = i.category
                                    AND model = ia.field_2
                           ) ,
                CASE WHEN #style.pom_date = '1/1/1900' THEN NULL
                     ELSE #style.pom_date
                END AS pom_date ,
                #style.mth_since_rel ,
                #style.mths_left_y2 ,
                #style.mths_left_y1 ,
                #style.inv_rank ,
                #style.rank_24m_sales ,
                #style.rank_12m_sales ,
                #style.sales_y2tg ,
                #style.sales_y1tg ,
                #style.[Sales M1-3] s_sales_m1_3 ,
                #style.[Sales M1-12] s_sales_m1_12 ,
                #style.s_e4_wu ,
                #style.s_e12_wu ,
                #style.s_e52_wu ,
                #style.s_promo_w4 ,
                #style.s_promo_w12
-- , #SKU.*
                ,
                #SKU.LINE_TYPE ,
                #SKU.sku ,
                #SKU.mm ,
                CASE WHEN #style.rel_date <> ISNULL(ia.field_26,
                                                    #style.rel_date)
                     THEN ia.field_26
                END AS p_rel_date ,
                CASE WHEN #style.pom_date <> ISNULL(ia.field_28,
                                                    #style.pom_date)
                     THEN ia.field_28
                END AS p_pom_date ,
                ( SELECT    lead_time
                  FROM      inv_list il
                  WHERE     il.part_no = #SKU.sku
                            AND il.location = '001'
                ) lead_time ,
                #SKU.bucket ,
                #SKU.QOH ,
                #SKU.atp ,
                #SKU.quantity ,
                #SKU.mult ,
                #SKU.s_mult ,
                #SKU.sort_seq ,
                #t.pct_of_style ,
                #t.pct_first_po ,
                #t.pct_sales_style_m1_3 ,
                #t.p_e4_wu ,
                #t.p_e12_wu ,
                #t.p_e52_wu ,
                #t.p_subs_w4 ,
                #t.p_subs_w12 ,
                #t.s_mth_usg ,
                #t.p_mth_usg ,
                #t.s_mth_usg_mult ,
                #t.sales_y2tg_per_month ,
                #t.sales_y1tg_per_month ,
                #t.sales_y2tg p_sales_y2tg ,
                #t.sales_y1tg p_sales_y1tg ,
                p_po_qty_y1 = CASE WHEN #SKU.LINE_TYPE = 'V'
                                        AND #SKU.sort_seq = 1
                                   THEN ISNULL(( SELECT SUM(qty_ordered)
                                                 FROM   pur_list p ( NOLOCK )
                                                        INNER JOIN inv_master i ( NOLOCK ) ON i.part_no = p.part_no
                                                        INNER JOIN inv_master_add ia ( NOLOCK ) ON ia.part_no = i.part_no
                                                 WHERE  1 = 1
                                                        AND i.void = 'n'
                                                        AND p.part_no = #SKU.sku
                                                        AND p.rel_date <= DATEADD(yy,
                                                              1, ia.field_26)
                                                        AND p.type = 'p'
                                                        AND p.location = '001'
                                               ), 0)
                                   ELSE 0
                              END
        FROM    #SKU
                INNER JOIN inv_master i ( NOLOCK ) ON #SKU.sku = i.part_no
                INNER JOIN inv_master_add ia ( NOLOCK ) ON #SKU.sku = ia.part_no
                INNER JOIN #style ON #style.brand = i.category
                                     AND #style.style = ia.field_2
                INNER JOIN #t ON #t.part_no = #SKU.sku
                                 AND #t.mm = #SKU.mm
                                 AND #t.mult = #SKU.mult
                                 AND #t.sort_seq = #SKU.sort_seq
                INNER JOIN ( SELECT i.category brand ,
                                    ia.field_2 style ,
                                    i.vendor ,
                                    MAX(type_code) type_code ,
                                    MAX(category_2) gender ,
                                    MAX(i.cmdty_code) material ,
                                    MAX(ISNULL(ia.category_1, '')) watch ,
                                    ( SELECT TOP 1
                                                MOQ_info
                                      FROM      cvo_Vendor_MOQ
                                      WHERE     Vendor_Code = i.vendor
                                    ) moq ,
                                    MAX(ISNULL(ia.field_32, '')) sf
                             FROM   inv_master i
                                    INNER JOIN inv_master_add ia ON ia.part_no = i.part_no
                             WHERE  1 = 1
                                    AND i.type_code IN ( 'frame', 'sun',
                                                         'bruit' )
                                    AND i.void = 'n'
                                    AND ISNULL(ia.field_32, '') <> 'SpecialOrd' -- revo special order skus
GROUP BY                            i.category ,
                                    ia.field_2 ,
                                    i.vendor
                           ) AS specs ON specs.brand = #style.brand
                                         AND specs.style = #style.style;


    END;










GO

GRANT EXECUTE ON  [dbo].[cvo_matl_fcst_style_season_sp] TO [public]
GO
