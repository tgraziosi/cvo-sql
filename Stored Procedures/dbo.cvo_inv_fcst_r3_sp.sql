SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_inv_fcst_r3_sp]

    -- re-write for y1 figures not pulling enough history to properly generate
    -- 3/21/2017 - pull out the ranking features; clean up; multi-location reporting; RA %
    -- 8/31/2017 - switch to get usage by location and collection to correctly fill in items with 0 usage
    -- 9/5/17 - fix PO line where there was a past due open po.  it did not total the current month total open po correctly.  was only showing the past due qty

    @asofdate DATETIME,
    @location VARCHAR(1000),
    @endrel DATETIME = NULL, -- ending release date
    @current INT = 1,
    @collection VARCHAR(1000) = NULL,
    @Style VARCHAR(8000) = NULL,
    @SpecFit VARCHAR(1000) = NULL,
    @gender VARCHAR(1000) = NULL,
    @ResType VARCHAR(1000) = NULL,
    @usg_option CHAR(1) = 'O',
    @Season_start INT = NULL,
    @Season_end INT = NULL,
    @Season_mult DECIMAL(20, 8) = NULL,
    @spread VARCHAR(10) = NULL,
                             -- 7/11/17
    @WksOnHandGTLT CHAR(5) = 'ALL',
    @WksOnHand INT = 0,
    @debug INT = 0
--
/*
exec cvo_inv_fcst_r3_t_sp

@asofdate = '01/01/2018', 
@endrel = '01/01/2018', 
@current = 0, 
@collection = 'dd', 
@style = null, 
@specfit = null,
@usg_option = 'o',
@debug = 0, -- debug
@location = '001',
@restype = 'frame,sun',
@WKSONHANDGTLT = 'all',
@WKSONHAND = 0

select * From cvo_ifp_rank
SELECT * fROM RELEASES WHERE PART_NO LIKE 'RE1014%'

*/
-- 090314 - tag
-- get sales since the asof date, and use it to consume the demand line
-- 10/29/2014 - ADD additional info to match DRP
-- 1/9/2015 - update sales PCT for demand multipliers per BL schedule
-- 2/11/2015 - fix po line not picking up po's for suns

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
-- 07/15/2016 - calc starting inventory with allocations if usage is on orders, and without if usage is on shipments.
-- 12/2016 - misc updates to add additional info like pricing shape materials
-- 01/2018 - fix/update for multiple attributes on an item.

AS
BEGIN

    SET NOCOUNT ON;

    SET ANSI_WARNINGS OFF;


    DECLARE @startdate DATETIME,
            @enddate DATETIME,
            @pomdate DATETIME;

    /* for testing

--, @asofdate datetime
--, @current int
*/

    SET @pomdate = @asofdate;
    SET @startdate = '01/01/1949';
    SET @enddate = ISNULL(@endrel, @asofdate);

    DECLARE @coll_list VARCHAR(1000),
            @style_list VARCHAR(8000),
            @sf VARCHAR(1000),
            @gndr VARCHAR(1000),
            @type_code VARCHAR(1000),
            @s_start INT,
            @s_end INT,
            @s_mult DECIMAL(20, 8),
            @sku VARCHAR(40),
            @loc VARCHAR(1000);

    SELECT @coll_list = @collection,
           @style_list = @Style,
           @sf = @SpecFit,
           @gndr = @gender,
           @type_code = @ResType,
           @s_start = ISNULL(@Season_start, 1),
           @s_end = ISNULL(@Season_end, 12),
           @s_mult = ISNULL(@Season_mult, 1),
           @loc = @location;

    -- select @style_list

    DECLARE @coll_tbl TABLE
    (
        coll VARCHAR(20) NOT NULL
    );

    IF @coll_list IS NULL
    BEGIN
        INSERT INTO @coll_tbl
        SELECT DISTINCT
               kys
        FROM dbo.category
        WHERE void = 'n';
    END;
    ELSE
    BEGIN
        INSERT INTO @coll_tbl
        (
            coll
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@coll_list);
    END;

    DECLARE @style_list_tbl TABLE
    (
        style VARCHAR(40) NULL
    );

    IF @style_list IS NULL
       OR @style_list LIKE '%*ALL*%'
    BEGIN
        INSERT INTO @style_list_tbl
        SELECT DISTINCT
               ia.field_2
        FROM @coll_tbl c
			INNER JOIN dbo.inv_master i (NOLOCK)
				ON i.category = c.coll
			JOIN dbo.inv_master_add ia (NOLOCK)
                ON i.part_no = ia.part_no
        WHERE i.void = 'n';
    END;
    ELSE
    BEGIN
        INSERT INTO @style_list_tbl
        (
            style
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@style_list);
    END;

    DECLARE @sf_tbl TABLE
    (
        sf VARCHAR(20) NOT NULL
    );

    IF @sf IS NULL
       OR @sf LIKE '%*ALL*%'
    BEGIN
        INSERT INTO @sf_tbl
        (
            sf
        )
        VALUES
        ('' );

        INSERT INTO @sf_tbl
        (
            sf
        )
        SELECT DISTINCT
               kys
        FROM dbo.cvo_specialty_fit
        WHERE void = 'n';
    END;
    ELSE
    BEGIN
        INSERT INTO @sf_tbl
        (
            sf
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@sf);
    END;

    DECLARE @loc_tbl TABLE
    (
        location VARCHAR(10) NOT NULL
    );

    IF @loc IS NULL
       OR @loc LIKE '%*ALL*%'
    BEGIN
        INSERT INTO @loc_tbl
        (
            location
        )
        VALUES
        ('' );

        INSERT INTO @loc_tbl
        (
            location
        )
        SELECT DISTINCT
               la.location
        FROM dbo.locations_all AS la
        WHERE la.void = 'n';
    END;
    ELSE
    BEGIN
        INSERT INTO @loc_tbl
        (
            location
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@loc);
    END;

    IF @loc = 'CASES'
       AND @type_code = 'CASE'
    BEGIN
        INSERT INTO @loc_tbl
        (
            location
        )
        SELECT DISTINCT
               L.location
        FROM dbo.inv_master I
            JOIN dbo.cvo_inventory2 AS L
                ON L.part_no = I.part_no
        WHERE I.type_code = 'CASE'
              AND I.void <> 'V'
              AND L.cvo_in_stock <> 0;

        DELETE FROM @loc_tbl
        WHERE location = 'CASES';
    END;

    IF @debug > 0
        SELECT l.location
        FROM @loc_tbl AS l;

    -- get gender selections

    DECLARE @gender_tbl TABLE
    (
        gender VARCHAR(20) NOT NULL
    );

    IF @gndr IS NULL
       OR @gndr LIKE '%*ALL*%'
    BEGIN
        INSERT INTO @gender_tbl
        (
            gender
        )
        VALUES
        ('' );

        INSERT INTO @gender_tbl
        (
            gender
        )
        SELECT DISTINCT
               kys
        FROM dbo.CVO_Gender
        WHERE void = 'n';
    END;
    ELSE
    BEGIN
        INSERT INTO @gender_tbl
        (
            gender
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@gndr);
    END;

    DECLARE @type_tbl TABLE
    (
        type_code VARCHAR(10)
    );

    IF @type_code IS NULL
    BEGIN
        INSERT INTO @type_tbl
        SELECT DISTINCT
               type_code
        FROM dbo.inv_master AS i;
    END;
    ELSE
    BEGIN
        INSERT INTO @type_tbl
        (
            type_code
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@type_code);
    END;

    DECLARE @dmd_mult_tbl TABLE
    (
        mm INT NOT NULL,
        pct_sales DECIMAL(20, 8) NOT NULL,
        mult DECIMAL(20, 8) NOT NULL,
        s_mult DECIMAL(20, 8) NOT NULL,
        sort_seq INT NOT NULL
    );


    -- 8/17/2016
    SET @spread = ISNULL(@spread, 'CORE');

    INSERT INTO @dmd_mult_tbl
    SELECT mm,
           pct_sales,
           0,
           0,
           0
    FROM dbo.cvo_dmd_mult
    WHERE obs_date IS NULL
          AND asofdate = (
                         SELECT MAX(asofdate)
                         FROM dbo.cvo_dmd_mult
                         WHERE asofdate <= GETDATE()
                               AND spread = @spread
                         )
          -- alternate spread %'s
          AND spread = @spread;

    -- select sum(pct_sales) from @dmd_mult_tbl -- 1.0001 for 2015
    -- 0.99980000 for 2/2015

    UPDATE @dmd_mult_tbl
    SET sort_seq = CASE WHEN mm < MONTH(@asofdate) THEN mm - MONTH(@asofdate) + 13 ELSE mm - MONTH(@asofdate) + 1 END;

    DECLARE @sort_seq INT,
            @base_pct FLOAT,
            @flatten DECIMAL(20, 8);

    SET @base_pct = (
                    SELECT AVG(pct_sales) FROM @dmd_mult_tbl WHERE sort_seq IN ( 10, 11, 12 )/*(11,12,1)*/
                    );
    -- last 3 months sales %
    -- the multiplier s/b the average of the 3 months prior to the asofdate

    SET @sort_seq = 1;

    WHILE @sort_seq <= 12
    BEGIN
        UPDATE d
        SET mult = ROUND(1 + ((pct_sales - @base_pct) / @base_pct), 4),
            s_mult = CASE WHEN @sort_seq BETWEEN @s_start AND @s_end THEN @s_mult ELSE 1.0 END
        FROM @dmd_mult_tbl d
        WHERE sort_seq = @sort_seq;

        SET @sort_seq = @sort_seq + 1;
    END;


    SELECT @flatten = SUM(mult)
    FROM @dmd_mult_tbl;

    UPDATE @dmd_mult_tbl
    SET mult = mult * (12 / @flatten);

    --END

    -- select * From @dmd_mult_tbl

    IF (OBJECT_ID('tempdb.dbo.#sls_det') IS NOT NULL) DROP TABLE #sls_det;

    IF (OBJECT_ID('tempdb.dbo.#cte') IS NOT NULL)     DROP TABLE #cte;

    IF (OBJECT_ID('tempdb.dbo.#style') IS NOT NULL)   DROP TABLE #style;

    IF (OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL)     DROP TABLE #tmp;

    IF (OBJECT_ID('tempdb.dbo.#t') IS NOT NULL)       DROP TABLE #t;

    IF (OBJECT_ID('tempdb.dbo.#usage') IS NOT NULL)   DROP TABLE #usage;

    IF (OBJECT_ID('tempdb.dbo.#sku_tbl') IS NOT NULL)   DROP TABLE #sku_tbl;


    create table #sku_tbl 
    (
        LINE_TYPE VARCHAR(3) null,
        sku VARCHAR(30) null,
        location VARCHAR(12) NULL,
        mm INT NULL, 
        bucket DATETIME NULL,
        QOH INT NULL,
        atp INT NULL,
        reserve_qty INT NULL,
        quantity INT NULL,
        mult DECIMAL(20, 8) NULL,
        s_mult DECIMAL(20, 8) NULL,
        sort_seq INT NULL,
        alloc_qty INT NULL,
        non_alloc_qty INT NULL -- 5/18/2017
    );


    -- get weekly usage

    CREATE TABLE #usage
    (
        location VARCHAR(12)  NULL,
        part_no VARCHAR(40) NULL,
        usg_option CHAR(1) NULL,
        asofdate DATETIME NULL,
        e4_wu INT NULL,
        e12_wu INT NULL,
        e26_wu INT NULL,
        e52_wu INT NULL,
        subs_w4 INT NULL,
        subs_w12 INT NULL,
        promo_w4 INT NULL,
        promo_w12 INT NULL,
        rx_w4 INT NULL,
        rx_w12 INT NULL, -- 12/5/2016
        ret_w4 INT NULL,
        ret_w12 INT NULL,
        wty_w4 INT NULL,
        wty_w12 INT NULL,
        gross_w4 INT NULL,
        gross_w12 INT NULL
    );

    -- 10/24/2016 - switch over to usage by collection/ type for performance

    DECLARE @co VARCHAR(20),
            @lo VARCHAR(10),
            @t CHAR(1);

    IF @loc = 'CASES'
       AND @type_code = 'CASE'
        SELECT @co = 'CASE',
               @t  = 'T';
    ELSE
        SELECT @co = MIN(coll),
               @t  = 'C'
        FROM @coll_tbl AS c;

    SELECT @lo = MIN(location)
    FROM @loc_tbl AS l;

    WHILE @co IS NOT NULL
    BEGIN

        WHILE @lo IS NOT NULL
        BEGIN
            INSERT INTO #usage
            (
                location,
                part_no,
                usg_option,
                asofdate,
                e4_wu,
                e12_wu,
                e26_wu,
                e52_wu,
                subs_w4,
                subs_w12,
                promo_w4,
                promo_w12,
                rx_w4,
                rx_w12,
                ret_w4,
                ret_w12,
                wty_w4,
                wty_w12,
                gross_w4,
                gross_w12
            )
            SELECT location,
                   part_no,
                   usg_option,
                   ASofdate,
                   e4_wu,
                   e12_wu,
                   e26_wu,
                   e52_wu,
                   subs_w4,
                   subs_w12,
                   promo_w4,
                   promo_w12,
                   rx_w4,
                   rx_w12,
                   ret_w4,
                   ret_w12,
                   wty_w4,
                   wty_w12,
                   gross_w4,
                   gross_w12
            FROM dbo.f_cvo_calc_weekly_usage_loc(@usg_option, @t, @co, @lo);

            SELECT @lo = MIN(location)
            FROM @loc_tbl
            WHERE location > @lo;
        END;


        IF @loc = 'CASES'
           AND @type_code = 'CASE'
            SELECT @co = NULL,
                   @t  = 'T';
        ELSE
            SELECT @co = MIN(coll),
                   @t  = 'C'
            FROM @coll_tbl AS c
            WHERE coll > @co;

        IF @co IS NULL
            SELECT @lo = NULL;
        ELSE
            SELECT @lo = MIN(location)
            FROM @loc_tbl AS l;

    END;

    IF @debug = 5
        SELECT *
        FROM #usage AS u;

    -- get sales history
    SELECT i.category brand,
           ia.field_2 style,
           il.location,
           i.part_no,
           i.type_code,
           ISNULL(ia.field_28, '1/1/1900') pom_date,
           ia.field_26 rel_date,
           DATEDIFF(m, ia.field_26, ISNULL(s.yyyymmdd, @asofdate)) AS rel_month,
           SUM(   CASE WHEN ISNULL(s.yyyymmdd, @asofdate) < DATEADD(mm, 12, ia.field_26) THEN
                           ISNULL(s.qsales, 0) - ISNULL(s.qreturns, 0) ELSE 0
                  END
              ) yr1_net_qty,
           SUM(   CASE WHEN ISNULL(s.yyyymmdd, @asofdate) < @asofdate
                            AND DATEDIFF(m, ia.field_26, ISNULL(s.yyyymmdd, @asofdate)) <= 12 THEN
                           ISNULL(s.qsales, 0) - ISNULL(s.qreturns, 0) ELSE 0
                  END
              ) yr1_net_qty_b4_asof,
           SUM(   CASE WHEN ISNULL(s.yyyymmdd, @asofdate) < @asofdate
                            AND DATEDIFF(m, ia.field_26, ISNULL(s.yyyymmdd, @asofdate))
                            BETWEEN 12 AND 24 THEN ISNULL(s.qsales, 0) - ISNULL(s.qreturns, 0) ELSE 0
                  END
              ) yr2_net_qty_b4_asof,
           SUM(ISNULL(s.qsales, 0)) AS sales_qty,
           SUM(ISNULL(s.qreturns, 0)) AS ret_qty

    INTO #sls_det

    FROM @coll_tbl c
        JOIN dbo.inv_master i (NOLOCK)
            ON i.category = c.coll
        INNER JOIN @type_tbl t
            ON t.type_code = i.type_code
        INNER JOIN dbo.inv_master_add ia (NOLOCK)
            ON i.part_no = ia.part_no
        INNER JOIN @style_list_tbl st
            ON st.style = ia.field_2
        INNER JOIN dbo.inv_list il
            ON il.part_no = i.part_no
        INNER JOIN @loc_tbl l
            ON l.location = il.location
        LEFT OUTER JOIN dbo.cvo_sbm_details s (NOLOCK)
            ON s.part_no = i.part_no
               AND s.location = l.location
    -- left outer join armaster a (nolock) on a.customer_code = s.customer and a.ship_to_code = s.ship_to
    WHERE 1 = 1
          AND ia.field_26 >= @startdate
          AND i.void = 'N'
          -- AND EXISTS (SELECT 1 FROM @sf_tbl WHERE @sf_tbl.sf = ISNULL(ia.field_32,''))
          AND (
              EXISTS (
                     SELECT 1
                     FROM @sf_tbl sf
                         JOIN dbo.cvo_part_attributes pa
                             ON pa.part_no = ia.part_no
                                AND pa.attribute = sf.sf
                     )
              OR EXISTS (
                        SELECT 1 FROM @sf_tbl sf WHERE sf.sf = ISNULL(ia.field_32, '')
                        )
              )

          AND EXISTS (
                     SELECT 1 FROM @gender_tbl g WHERE g.gender = ISNULL(ia.category_2, '')
                     )
          -- AND EXISTS (select 1 FROM @loc_tbl WHERE @loc_tbl.location = ISNULL(s.location,@loc_tbl.location))

          AND ISNULL(s.customer, '') NOT IN ( '045733', '019482', '045217' ) -- stanton and insight and costco
          AND ISNULL(s.return_code, '') = ''
          AND ISNULL(s.isCL, 0) = 0 -- no closeouts
    -- and isnull(s.location,@loc) = @loc

    GROUP BY ia.field_26,
             ia.field_28,
             i.category,
             ia.field_2,
             i.part_no,
             i.type_code,
             il.location,
             s.yyyymmdd; -- end cte

    IF @debug = 1
        SELECT '#sls_det',
               *
        FROM #sls_det;

    SELECT sls.brand,
           sls.style,
           MAX(type_code) type_code,
           ISNULL(tt.style_pom, MIN(sls.pom_date)) pom_date,
           MIN(rel_date) rel_date,
           sls.rel_month,
           SUM(yr1_net_qty) yr1_net_qty,
           SUM(yr1_net_qty_b4_asof) yr1_net_qty_b4_asof,
           SUM(yr2_net_qty_b4_asof) yr2_net_qty_b4_asof,
           SUM(sales_qty) AS sales_qty,
           SUM(ret_qty) AS ret_qty
    INTO #cte
    FROM #sls_det sls
        LEFT OUTER JOIN
        (
        SELECT t.Collection brand,
               t.model style,
               MAX(t.pom_date) style_pom
        FROM dbo.cvo_inv_master_r2_vw t
            JOIN #sls_det s
                ON s.brand = t.Collection
                   AND s.style = t.model
        GROUP BY t.Collection,
                 t.model
        HAVING COUNT(t.part_no) = COUNT(t.pom_date) -- fully pom'd style
        ) AS tt
            ON tt.brand = sls.brand
               AND tt.style = sls.style
    GROUP BY sls.brand,
             sls.style,
             sls.rel_month,
             tt.style_pom;

    IF @debug = 1
        SELECT ' cte ' cte,
               *
        FROM #cte;

    -- where style = '185' order by style, rel_month

    -- Create style summary list

    SELECT cte.brand,
           cte.style,
           '' AS part_no,
           drp.location,
           MIN(cte.pom_date) pom_date,
           MIN(cte.rel_date) rel_date,
           MAX(cte.rel_month) mth_since_rel,
           SUM(CASE WHEN cte.rel_month <= 3 THEN cte.sales_qty ELSE 0 END) [Sales M1-3],
           SUM(CASE WHEN cte.rel_month <= 12 THEN cte.sales_qty ELSE 0 END) [Sales M1-12],
           ISNULL(drp.s_e4_wu, 0) s_e4_wu,
           ISNULL(drp.s_e12_wu, 0) s_e12_wu,
           ISNULL(drp.s_e52_wu, 0) s_e52_wu,
           ISNULL(drp.s_promo_w4, 0) s_promo_w4,
           ISNULL(drp.s_promo_w12, 0) s_promo_w12,
           ISNULL(drp.s_rx_w4, 0) s_rx_w4,
           ISNULL(drp.s_rx_w12, 0) s_rx_w12,
           ISNULL(drp.s_ret_w4, 0) s_ret_w4,
           ISNULL(drp.s_ret_w12, 0) s_ret_w12,
           ISNULL(drp.s_wty_w4, 0) s_wty_w4,
           ISNULL(drp.s_wty_w12, 0) s_wty_w12,
           ISNULL(drp.s_gross_w4, 0) s_gross_w4,
           ISNULL(drp.s_gross_w12, 0) s_gross_w12


    INTO #style -- tally up style level information
    FROM #cte cte


        LEFT OUTER JOIN
        (
        SELECT -- usage info
            i.category collection,
            ia.field_2 style,
            drp.location,
            SUM(ISNULL(drp.e4_wu, 0)) s_e4_wu,
            SUM(ISNULL(drp.e12_wu, 0)) s_e12_wu,
            SUM(ISNULL(drp.e52_wu, 0)) s_e52_wu,
            SUM(ISNULL(drp.promo_w4, 0)) s_promo_w4,
            SUM(ISNULL(drp.promo_w12, 0)) s_promo_w12,
            SUM(ISNULL(drp.rx_w4, 0)) s_rx_w4,
            SUM(ISNULL(drp.rx_w12, 0)) s_rx_w12,
            SUM(ISNULL(drp.ret_w4, 0)) s_ret_w4,
            SUM(ISNULL(drp.ret_w12, 0)) s_ret_w12,
            SUM(ISNULL(drp.wty_w4, 0)) s_wty_w4,
            SUM(ISNULL(drp.wty_w12, 0)) s_wty_w12,
            SUM(ISNULL(drp.gross_w4, 0)) s_gross_w4,
            SUM(ISNULL(drp.gross_w12, 0)) s_gross_w12
        FROM dbo.inv_master i (NOLOCK)
            LEFT OUTER JOIN #usage drp (NOLOCK)
                ON i.part_no = drp.part_no
            INNER JOIN dbo.inv_master_add ia (NOLOCK)
                ON ia.part_no = i.part_no
        WHERE i.void = 'N'
        GROUP BY i.category,
                 ia.field_2,
                 drp.location
        ) AS drp
            ON drp.collection = cte.brand
               AND drp.style = cte.style

    GROUP BY cte.brand,
             cte.style,
             drp.location,
             drp.s_e4_wu,
             drp.s_e12_wu,
             drp.s_e52_wu,
             drp.s_promo_w4,
             drp.s_promo_w12,
             drp.s_rx_w4,
             drp.s_rx_w12,
             drp.s_ret_w4,
             drp.s_ret_w12,
             drp.s_wty_w4,
             drp.s_wty_w12,
             drp.s_gross_w4,
             drp.s_gross_w12
    ORDER BY cte.brand,
             cte.style;

    -- select * from #style where style = '185'

    -- Check for current styles

    IF @debug = 1
        SELECT *
        FROM #style;

    -- select * From #style where style = 'clarissa'

    -- summarize further and start adding part level information

    SELECT s.brand,
           s.style,
           s.location,
           i.part_no,
           s.rel_date,
           s.pom_date,
           s.mth_since_rel,
           ISNULL(s.s_e4_wu, 0) s_e4_wu,
           ISNULL(s.s_e12_wu, 0) s_e12_wu,
           ISNULL(s.s_e52_wu, 0) s_e52_wu,
           ISNULL(s.s_promo_w4, 0) s_promo_w4,
           ISNULL(s.s_promo_w12, 0) s_promo_w12,
           ISNULL(s.s_rx_w4, 0) s_rx_w4,
           ISNULL(s.s_rx_w12, 0) s_rx_w12,
           ISNULL(s.s_ret_w4, 0) s_ret_w4,
           ISNULL(s.s_ret_w12, 0) s_ret_w12,
           ISNULL(s.s_wty_w4, 0) s_wty_w4,
           ISNULL(s.s_wty_w12, 0) s_wty_w12,
           ISNULL(s.s_gross_w4, 0) s_gross_w4,
           ISNULL(s.s_gross_w12, 0) s_gross_w12

    ,
           ISNULL(drp.p_e4_wu, 0) p_e4_wu,
           ISNULL(drp.p_e12_wu, 0) p_e12_wu,
           ISNULL(drp.p_e52_wu, 0) p_e52_wu,
           ISNULL(drp.p_subs_w4, 0) p_subs_w4,
           ISNULL(drp.p_subs_w12, 0) p_subs_w12,
           ISNULL(drp.p_rx_w4, 0) p_rx_w4,
           ISNULL(drp.p_rx_w12, 0) p_rx_w12,
           ISNULL(drp.p_ret_w4, 0) p_ret_w4,
           ISNULL(drp.p_ret_w12, 0) p_ret_w12,
           ISNULL(drp.p_wty_w4, 0) p_wty_w4,
           ISNULL(drp.p_wty_w12, 0) p_wty_w12,
           ISNULL(drp.p_gross_w4, 0) p_gross_w4,
           ISNULL(drp.p_gross_w12, 0) p_gross_w12

    ,
           ROUND(
                    (CASE WHEN s.mth_since_rel <= 3 THEN ISNULL(s.s_e4_wu, 0) * 52 / 12 ELSE
                                                                                          ISNULL(s.s_e12_wu, 0) * 52 / 12 END
                    ),
                    0,
                    1
                ) s_mth_usg,
           ROUND(
                    (CASE WHEN s.mth_since_rel <= 3 THEN ISNULL(drp.p_e4_wu, 0) * 52 / 12 ELSE
                                                                                          ISNULL(drp.p_e12_wu, 0) * 52 / 12 END
                    ),
                    0,
                    1
                ) p_mth_usg,
           ROUND(
                    ((CASE WHEN s.mth_since_rel <= 3 THEN ISNULL(s.s_e4_wu, 0) * 52 / 12 ELSE
                                                                                            ISNULL(s.s_e12_wu, 0) * 52
                                                                                            / 12 END
                     ) * dmd.mult
                    ),
                    0,
                    1
                ) s_mth_usg_mult,
           ROUND(
                    ((CASE WHEN s.mth_since_rel <= 3 THEN ISNULL(drp.p_e4_wu, 0) * 52 / 12 ELSE
                                                                                               ISNULL(drp.p_e12_wu, 0)
                                                                                               * 52 / 12 END
                     )
                     * dmd.mult
                    ),
                    0,
                    1
                ) p_mth_usg_mult,
           ROUND(
                    (CASE WHEN ISNULL(CAST(s.s_e12_wu AS DECIMAL), 0.00) <> 0.00 THEN
                              ISNULL(CAST(drp.p_e12_wu AS DECIMAL), 0.00) / ISNULL(CAST(s.s_e12_wu AS DECIMAL), 0) ELSE
                                                                                                                       0.00
                     END
                    ),
                    4
                ) pct_of_style,
           ISNULL((
                  SELECT TOP (1)
                         quantity
                  FROM dbo.releases
                  WHERE part_no = i.part_no
                        AND location = '001'
                        AND part_type = 'p'
                        AND status = 'c'
                  ORDER BY release_date
                  ),
                  0
                 ) first_po,
           CAST(0 AS FLOAT) pct_first_po, -- calculate this later
           0 p_sales_m1_3,
           CAST(0 AS FLOAT) pct_sales_style_m1_3,
           dmd.mm,
           dmd.mult,
           dmd.s_mult,
           dmd.sort_seq,                  -- stuff from @dmd_mult_tbl
           'xxx' mth_demand_src,
           NULL mth_demand_mult,
           CAST(0 AS FLOAT) p_po_qty_y1

    INTO #t

    FROM dbo.inv_master i (NOLOCK)
        JOIN @type_tbl t
            ON t.type_code = i.type_code
        INNER JOIN dbo.inv_master_add ia (NOLOCK)
            ON i.part_no = ia.part_no
        INNER JOIN #style s
            ON s.brand = i.category
               AND s.style = ia.field_2
               -- and ia.field_26 between @startdate and @enddate
               AND ia.field_26 >= @startdate
        LEFT OUTER JOIN
        (
        SELECT -- drp info by part
            drp.location,
            drp.part_no,
            SUM(ISNULL(drp.e4_wu, 0)) p_e4_wu,
            SUM(ISNULL(drp.e12_wu, 0)) p_e12_wu,
            SUM(ISNULL(drp.e52_wu, 0)) p_e52_wu,
            SUM(ISNULL(drp.subs_w4, 0)) p_subs_w4,
            SUM(ISNULL(drp.subs_w12, 0)) p_subs_w12,
            SUM(ISNULL(drp.rx_w4, 0)) p_rx_w4,
            SUM(ISNULL(drp.rx_w12, 0)) p_rx_w12,
            SUM(ISNULL(drp.ret_w4, 0)) p_ret_w4,
            SUM(ISNULL(drp.ret_w12, 0)) p_ret_w12,
            SUM(ISNULL(drp.wty_w4, 0)) p_wty_w4,
            SUM(ISNULL(drp.wty_w12, 0)) p_wty_w12,
            SUM(ISNULL(drp.gross_w4, 0)) p_gross_w4,
            SUM(ISNULL(drp.gross_w12, 0)) p_gross_w12
        FROM #usage drp (NOLOCK)
            JOIN dbo.inv_master i
                ON i.part_no = drp.part_no
            JOIN @type_tbl t
                ON t.type_code = i.type_code
        GROUP BY drp.location,
                 drp.part_no
        ) AS drp
            ON drp.part_no = i.part_no
               AND drp.location = s.location


        CROSS JOIN @dmd_mult_tbl dmd
    -- where i.type_code in ('FRAME','sun','BRUIT','PARTS') -- 11/1/16 - ADD PARTS
    WHERE 1 = 1
          AND i.void = 'n';

    CREATE NONCLUSTERED INDEX idx_t ON #t (part_no ASC);

    WITH x
    AS (SELECT DISTINCT
               sku.brand,
               sku.style,
               sku.part_no,
               sku.first_po,
               (
               SELECT SUM(ISNULL(tt.first_po, 0))
               FROM
               (
               SELECT DISTINCT
                      t.part_no,
                      t.first_po
               FROM #t t
                   JOIN dbo.inv_master i
                       ON i.part_no = t.part_no
               WHERE t.style = sku.style
                     AND t.brand = sku.brand
                     AND i.type_code IN ( 'frame', 'sun', 'bruit' )
                     AND t.location > ''
               ) AS tt
               ) style_first_po
        FROM #t sku
            JOIN dbo.inv_master ii
                ON ii.part_no = sku.part_no
    -- WHERE i.type_code IN ('frame','sun','bruit')
    )
    UPDATE t
    SET pct_first_po = ROUND(
                                (CASE WHEN ISNULL(x.style_first_po, 0.00) = 0.00 THEN 0.00 ELSE
                                                                                               CAST(ISNULL(
                                                                                                              x.first_po,
                                                                                                              0.00
                                                                                                          )
                                                                                                    / ISNULL(
                                                                                                                x.style_first_po,
                                                                                                                1
                                                                                                            ) AS FLOAT)
                                 END
                                ),
                                4
                            )
    FROM #t t
        INNER JOIN x
            ON t.part_no = x.part_no
    WHERE ISNULL(x.style_first_po, 0.00) <> 0.00;


    IF @current = 1 -- if reporting current styles/skus only remove any pom skus 
    BEGIN
        DELETE FROM #t
        WHERE EXISTS (
                     SELECT 1
                     FROM dbo.inv_master_add
                     WHERE part_no = #t.part_no
                           AND field_28 IS NOT NULL
                           AND field_28 < @asofdate
                     );
    END;

    -- remove any skus after the ending release date (full styles only)


    DELETE FROM #t
    WHERE EXISTS (
                 SELECT 1
                 FROM
                 (
                 SELECT brand,
                        style,
                        COUNT(DISTINCT rel_date) rel_date_cnt
                 FROM #t
                 GROUP BY brand,
                          style
                 HAVING COUNT(DISTINCT rel_date) = 1
                        AND MAX(rel_date) > @endrel
                 ) future_releases
                 WHERE #t.brand = future_releases.brand
                       AND #t.style = future_releases.style
                 );

    IF @debug = 1
        SELECT 'after future_releases removed',
               *
        FROM #t AS t;

    WITH x
    AS (SELECT s.part_no,
               SUM(s.sales_qty) p_sales_m1_3
        FROM #sls_det s
        WHERE s.rel_month <= 3
              AND s.location > ''
        GROUP BY part_no
    --order by part_no
    )
    UPDATE t
    SET t.p_sales_m1_3 = x.p_sales_m1_3,
        t.pct_sales_style_m1_3 = ROUND(x.p_sales_m1_3 / ISNULL(s.[Sales M1-3], 0), 4)
    FROM #t t
        INNER JOIN x
            ON t.part_no = x.part_no
        INNER JOIN #style s
            ON s.brand = t.brand
               AND s.style = t.style
               AND s.location > ''
    WHERE ISNULL(s.[Sales M1-3], 0) <> 0;

    -- select * From #t

    IF @debug = 4
    BEGIN
        SELECT s.part_no,
               SUM(s.sales_qty) p_sales_m1_3
        FROM #sls_det s
        WHERE s.rel_month <= 3
              AND s.location > ''
        GROUP BY part_no;
    --order by part_no
    END;

    INSERT INTO #sku_tbl
    SELECT DISTINCT
           mth_demand_src AS LINE_TYPE,
           t.part_no sku,
           t.location,
           t.mm,
           DATEADD(m, t.sort_seq - 1, @asofdate) bucket,
           0 QOH,
           0 atp,
           0 reserve_qty,
           ROUND(t.mth_demand_mult, 0, 1) AS quantity,
           t.mult,
           t.s_mult,
           t.sort_seq,
           0 alloc_qty,
           0 non_alloc_qty

    -- into #sku_tbl
    FROM #t t
    WHERE t.mth_demand_src <> 'xxx';

    -- order by #t.part_no, sort_seq

    -- add DRP data too


    INSERT INTO #sku_tbl
    SELECT 'DRP' AS LINE_TYPE,
           t.part_no sku,
           t.location,
           t.mm,
           DATEADD(m, t.sort_seq - 1, @asofdate) bucket,
           0 QOH,
           0 atp,
           0 reserve_qty,
           ROUND(
                    dmd.mult * dmd.s_mult
                    * (CASE WHEN DATEDIFF(mm, ia.field_26, @asofdate) > 3 THEN ISNULL(t.p_e12_wu, 0) * 52 / 12 ELSE
                                                                                                                     ISNULL(
                                                                                                                               t.p_e4_wu,
                                                                                                                               0
                                                                                                                           )
                                                                                                                     * 52
                                                                                                                     / 12
                       END
                      ),
                    0,
                    1
                ) quantity,
           t.mult,
           t.s_mult,
           t.sort_seq,
           0 alloc_qty,
           0 non_alloc_qty

    FROM #t t
        INNER JOIN @dmd_mult_tbl dmd
            ON t.sort_seq = dmd.sort_seq
        INNER JOIN dbo.inv_master_add ia
            ON ia.part_no = t.part_no;

    -- order by #t.part_no, sort_seq


    -- GET PURCHASE ORDER LINES MAPPED OUT BY MONTH UNTIL THE ENDING DATE
    INSERT INTO #sku_tbl
    SELECT -- 
        'PO' AS line_type

    ,
        t.part_no sku,
        t.location,
        CASE WHEN DATEADD(m, DATEDIFF(m, 0, r.inhouse_date), 0) < @asofdate THEN MONTH(@asofdate) ELSE
                                                                                                      MONTH(DATEADD(
                                                                                                                       m,
                                                                                                                       DATEDIFF(
                                                                                                                                   m,
                                                                                                                                   0,
                                                                                                                                   r.inhouse_date
                                                                                                                               ),
                                                                                                                       0
                                                                                                                   )
                                                                                                           )
        END,
        -- ,#t.mm
        DATEADD(m, t.sort_seq - 1, @asofdate) bucket,
        0 QOH,
        0 atp,
        0 reserve_qty,
        ROUND(SUM(ISNULL(r.quantity, 0)) - SUM(ISNULL(r.received, 0)), 1) quantity,
        t.mult,
        t.s_mult,
        t.sort_seq,
        0 alloc_qty, 
        0 non_alloc_qty
    FROM #t t
        -- 9/15/2017 - SUPPORT FOR OUTSOURCING
        INNER JOIN inv_master_add i (NOLOCK)
            ON i.part_no = t.part_no
               OR i.part_no = t.part_no + '-MAKE'
        INNER JOIN dbo.inv_master inv (NOLOCK)
            ON inv.part_no = i.part_no
        -- inner join @type_tbl t on t.type_code = inv.type_code 
        LEFT OUTER JOIN dbo.releases r (NOLOCK)
            ON i.part_no = r.part_no
               AND t.location = CASE WHEN i.part_no LIKE '%-make' THEN '001' ELSE r.location END
    WHERE 1 = 1
          AND EXISTS (
                     SELECT 1
                     FROM @type_tbl t
                     WHERE inv.type_code = t.type_code
                           OR inv.type_code = 'OUT'
                     )
          AND t.mm = CASE WHEN DATEADD(m, DATEDIFF(m, 0, r.inhouse_date), 0) < @asofdate THEN MONTH(@asofdate) ELSE
                                                                                                                    MONTH(DATEADD(
                                                                                                                                     m,
                                                                                                                                     DATEDIFF(
                                                                                                                                                 m,
                                                                                                                                                 0,
                                                                                                                                                 r.inhouse_date
                                                                                                                                             ),
                                                                                                                                     0
                                                                                                                                 )
                                                                                                                         )
                      END
          AND r.status = 'o'
          AND r.part_type = 'p' -- and r.location = @loc
          AND inv.void = 'N'
          AND DATEADD(m, DATEDIFF(m, 0, r.inhouse_date), 0) < DATEADD(YEAR, 1, @asofdate)
    GROUP BY
        -- inv.category, i.field_2, 
        t.part_no,
        t.location,
        -- , DATEADD(m,DATEDIFF(m,0,r.inhouse_date),0)
        CASE WHEN DATEADD(m, DATEDIFF(m, 0, r.inhouse_date), 0) < @asofdate THEN MONTH(@asofdate) ELSE
                                                                                                      MONTH(DATEADD(
                                                                                                                       m,
                                                                                                                       DATEDIFF(
                                                                                                                                   m,
                                                                                                                                   0,
                                                                                                                                   r.inhouse_date
                                                                                                                               ),
                                                                                                                       0
                                                                                                                   )
                                                                                                           )
        END,
        -- , MONTH(r.inhouse_date), #t.mm
        t.mult,
        t.s_mult,
        t.sort_seq;

    IF @debug = 1
        SELECT *
        FROM #sku_tbl
        WHERE LINE_TYPE = 'po'
        ORDER BY sku,
                 sort_seq;

    -- select * From #t

    -- 090314 - tag
    -- get sales since the asof date, and use it to consume the demand line

    INSERT INTO #sku_tbl
    SELECT -- 
        'SLS' AS line_type

    ,
        t.part_no sku,
        t.location,
        ISNULL(r.X_MONTH, MONTH(@asofdate)) mm,
        DATEADD(m, t.sort_seq - 1, @asofdate) bucket,
        0 QOH,
        0 atp,
        0 reserve_qty,
        ROUND(SUM(ISNULL(r.qsales, 0) - ISNULL(r.qreturns, 0)), 0, 1) quantity,
        t.mult,
        t.s_mult,
        CASE WHEN ISNULL(r.X_MONTH, MONTH(@asofdate)) < MONTH(@asofdate) THEN
                 ISNULL(r.X_MONTH, MONTH(@asofdate)) - MONTH(@asofdate) + 13 ELSE
                                                                                 ISNULL(r.X_MONTH, MONTH(@asofdate))
                                                                                 - MONTH(@asofdate) + 1
        END AS sort_seq,
        0 alloc_qty,
        0 non_alloc_qty

    FROM #t t
        INNER JOIN dbo.inv_master_add i (NOLOCK)
            ON i.part_no = t.part_no
        INNER JOIN dbo.inv_master inv (NOLOCK)
            ON inv.part_no = i.part_no
        LEFT OUTER JOIN dbo.cvo_sbm_details r (NOLOCK)
            ON t.part_no = r.part_no
               AND t.location = r.location
               AND r.X_MONTH = t.mm
    WHERE r.yyyymmdd >= @asofdate
          -- and @pomdate 
          AND inv.void = 'N'
    GROUP BY ISNULL(r.X_MONTH, MONTH(@asofdate)),
             DATEADD(m, t.sort_seq - 1, @asofdate),
             CASE WHEN ISNULL(r.X_MONTH, MONTH(@asofdate)) < MONTH(@asofdate) THEN
                      ISNULL(r.X_MONTH, MONTH(@asofdate)) - MONTH(@asofdate) + 13 ELSE
                                                                                      ISNULL(
                                                                                                r.X_MONTH,
                                                                                                MONTH(@asofdate)
                                                                                            ) - MONTH(@asofdate) + 1
             END,
             t.part_no,
             t.location,
             t.mult,
             t.s_mult;

    -- inv.category, i.field_2, #t.part_no, #t.location, r.x_month, #t.mult, #t.s_mult, #t.sort_seq
    -- select * From #sku_tbl  order by sku, sort_seq
    -- select * From #t

    -- 06/17/2015 - add orders line

    INSERT INTO #sku_tbl
    SELECT -- 
        'ORD' AS line_type

    ,
        t.part_no sku,
        t.location,
        rr.X_MONTH mm,
        DATEADD(m, t.sort_seq - 1, @asofdate) bucket,
        0 QOH,
        0 atp,
        0 reserve_qty,
        ROUND(SUM(ISNULL(rr.open_qty, 0)), 0, 1) quantity,
        t.mult,
        t.s_mult,
        CASE WHEN rr.X_MONTH < MONTH(@asofdate) THEN rr.X_MONTH - MONTH(@asofdate) + 13 ELSE
                                                                                            rr.X_MONTH
                                                                                            - MONTH(@asofdate) + 1 END AS sort_seq,
        0 alloc_qty,
        0 non_alloc_qty

    FROM #t t
        INNER JOIN dbo.inv_master_add i (NOLOCK)
            ON i.part_no = t.part_no
        INNER JOIN dbo.inv_master inv (NOLOCK)
            ON inv.part_no = i.part_no
        LEFT OUTER JOIN
        (
        SELECT ol.part_no,
               ol.location,
               CASE WHEN o.sch_ship_date < @asofdate THEN MONTH(@asofdate) ELSE MONTH(o.sch_ship_date) END X_MONTH,
               CASE WHEN o.sch_ship_date < @asofdate THEN @asofdate ELSE o.sch_ship_date END YYYYMMDD,
               SUM(ol.ordered - ol.shipped - ISNULL(ha.qty, 0)) open_qty
        FROM dbo.orders o (NOLOCK)
            INNER JOIN dbo.ord_list ol (NOLOCK)
                ON ol.order_no = o.order_no
                   AND ol.order_ext = o.ext
            LEFT OUTER JOIN dbo.cvo_hard_allocated_vw ha (NOLOCK)
                ON ha.line_no = ol.line_no
                   AND ha.order_ext = ol.order_ext
                   AND ha.order_no = ol.order_no
            LEFT OUTER JOIN dbo.cvo_soft_alloc_det sa (NOLOCK)
                ON sa.order_no = ol.order_no
                   AND sa.order_ext = ol.order_ext
                   AND sa.line_no = ol.line_no
                   AND sa.part_no = ol.part_no
        WHERE o.status < 'r'
              AND o.status <> 'c' -- 07/29/2015 - dont include credit hold orders
              AND o.type = 'i'
              AND ol.ordered > ol.shipped + ISNULL(ha.qty, 0)
              AND ISNULL(sa.status, -3) = -3 -- future orders not yet soft allocated
              AND ol.part_type = 'P'
        GROUP BY ol.part_no,
                 ol.location,
                 MONTH(o.sch_ship_date),
                 o.sch_ship_date
        ) rr
            ON t.part_no = rr.part_no
               AND t.location = rr.location
               AND rr.X_MONTH = t.mm
    WHERE rr.YYYYMMDD >= @asofdate
          -- and @pomdate 
          -- and inv.type_code in ('FRAME','sun','BRUIT','PARTS') -- 11/1/16 - ADD PARTS
          -- and r.status = 'o' and r.part_type = 'p' and r.location = @loc
          AND inv.void = 'N'
    GROUP BY DATEADD(m, t.sort_seq - 1, @asofdate),
             CASE WHEN rr.X_MONTH < MONTH(@asofdate) THEN rr.X_MONTH - MONTH(@asofdate) + 13 ELSE
                                                                                                 rr.X_MONTH
                                                                                                 - MONTH(@asofdate) + 1 END,
             t.part_no,
             t.location,
             rr.X_MONTH,
             t.mult,
             t.s_mult;

    --inv.category, i.field_2, #t.part_no, #t.location, rr.x_month, #t.mult, #t.s_mult, #t.sort_seq
    -- select * From #sku_tbl  order by sku, sort_seq
    -- select * From #t

    -- figure out the running total inv available line
    -- 11/19/14 - Change INV line calculation to consume the demand line using the greater of fct/drp or sls as the demand line
    -- 7/20/15 - add avail to promise

    DECLARE @inv INT,
            @last_inv INT,
            @last_loc VARCHAR(10),
            @INV_AVL INT,
            @drp INT,
            @sls INT,
            @po INT,
            @ord INT,
            @atp INT,
            @reserve_inv INT,
            @qty_ord INT,
            @alloc_qty INT,
            @non_alloc_qty INT;

     CREATE INDEX idx_f ON #sku_tbl (sku ASC, location ASC);

    CREATE INDEX idx_sku_line_sort
    ON #sku_tbl
    (
    sku ASC,
    LINE_TYPE ASC,
    sort_seq ASC,
    location ASC
    );

    SELECT @sku = MIN(sku)
    FROM #sku_tbl;

    SELECT @last_loc = MIN(s.location)
    FROM #sku_tbl s
    WHERE s.sku = @sku;

    IF @sku IS NOT NULL
       AND @last_loc IS NOT NULL
    BEGIN

        -- 7/15/2016 - calc starting inventory with allocations if usage is on orders.
        SELECT @last_inv = 0,
               @atp = 0,
               @reserve_inv = 0,
               @qty_ord = 0,
               @alloc_qty = 0,
               @non_alloc_qty = 0;

        SELECT @last_inv = ISNULL(cia.in_stock, 0) + ISNULL(cia.QcQty2, 0),
               -- CASE WHEN @usg_option = 'O' THEN 0 else isnull(cia.sof,0) + isnull(cia.allocated,0) end 
               @qty_ord = ISNULL(cia.SOF, 0) + ISNULL(cia.Allocated, 0),
               @atp = ISNULL(qty_avl, 0),
               @reserve_inv = ISNULL(cia.ReserveQty, 0),
               @alloc_qty = ISNULL(cia.SOF, 0) + ISNULL(cia.Allocated, 0),
               @non_alloc_qty
                   = ISNULL(cia.Quarantine, 0) + ISNULL(cia.Non_alloc, 0) - ISNULL(cia.ReserveQty, 0)
                     + ISNULL(cia.QcQty2, 0)
        -- 12/5/2016
        FROM dbo.cvo_item_avail_vw cia
        WHERE cia.part_no = @sku
              AND cia.location = @last_loc;

        IF @debug = 1
            SELECT @sku,
                   @last_inv,
                   @atp,
                   @reserve_inv,
                   @qty_ord,
                   @alloc_qty,
                   @non_alloc_qty;

        -- SELECT * FROM dbo.cvo_item_avail_vw AS iav WHERE iav.Part_no = 'smchipbla5218' AND location = '001'

        IF EXISTS (
                  SELECT 1
                  FROM #sku_tbl
                  WHERE LINE_TYPE = 'ord'
                        AND sort_seq = 1
                        AND location = @last_loc
                        AND sku = @sku
                  )
            UPDATE #sku_tbl
            SET quantity = quantity + @qty_ord
            WHERE sku = @sku
                  AND LINE_TYPE = 'ord'
                  AND sort_seq = 1
                  AND location = @last_loc;
        ELSE
            INSERT INTO #sku_tbl
            SELECT -- 
                'ORD' AS line_type,
                @sku sku,
                @last_loc,
                t.mm,
                DATEADD(m, t.sort_seq - 1, @asofdate) bucket,
                0 QOH,
                0 atp,
                0 reserve_qty,
                @qty_ord,
                t.mult,
                t.s_mult,
                t.sort_seq,
                0 alloc_qty,
                0 non_alloc_qty
            FROM #t t
            WHERE t.part_no = @sku
                  AND t.location = @last_loc
                  AND t.sort_seq = 1;



        SELECT @sort_seq = 0;

        SELECT @INV_AVL = @last_inv;

        SELECT @drp = SUM(ISNULL(quantity, 0))
        FROM #sku_tbl
        WHERE sku = @sku
              AND LINE_TYPE = 'drp'
              AND sort_seq = @sort_seq + 1
              AND location = @last_loc;

        SELECT @sls = SUM(ISNULL(quantity, 0))
        FROM #sku_tbl
        WHERE sku = @sku
              AND LINE_TYPE = 'sls'
              AND sort_seq = @sort_seq + 1
              AND location = @last_loc;

        SELECT @po = SUM(ISNULL(quantity, 0))
        FROM #sku_tbl
        WHERE sku = @sku
              AND LINE_TYPE = 'po'
              AND sort_seq = @sort_seq + 1
              AND location = @last_loc;

        SELECT @ord = SUM(ISNULL(quantity, 0))
        FROM #sku_tbl
        WHERE sku = @sku
              AND LINE_TYPE = 'ord'
              AND sort_seq = @sort_seq + 1
              AND location = @last_loc;


    END;

    -- select * From cvo_item_avail_vw where part_no = 'etkatbur5018' and location = '001'

    IF @debug = 2
    BEGIN
        SELECT *
        FROM #t AS t;

        SELECT @sku,
               @last_loc,
               @last_inv,
               @sort_seq;
    END;

    WHILE @sku IS NOT NULL
    BEGIN -- sku loop

        IF @debug = 2
            SELECT 'SKU LOOP' TAG,
                   @sku,
                   @last_loc,
                   @last_inv,
                   @sort_seq;

        WHILE @last_loc IS NOT NULL
        BEGIN

            IF @debug = 2
                SELECT 'LOC LOOP' TAG,
                       @sku,
                       @last_loc,
                       @last_inv,
                       @sort_seq;

            --IF @debug = 1 
            --	BEGIN
            --	 SELECT @sku, @last_inv, @atp, @reserve_inv
            --	 SELECT * FROM dbo.cvo_item_avail_vw AS iav WHERE iav.part_no = @sku AND iav.location = @loc
            --	END


            UPDATE #sku_tbl
            SET QOH = ISNULL(@last_inv, 0),
                atp = ISNULL(@atp, 0),
                reserve_qty = ISNULL(@reserve_inv, 0),
                alloc_qty = ISNULL(@alloc_qty, 0),
                non_alloc_qty = ISNULL(@non_alloc_qty, 0)
            WHERE sku = @sku
                  AND location = @last_loc;

            WHILE @sort_seq < 12
            BEGIN

                IF @debug = 2
                    SELECT 'SORT SEQ LOOP' TAG,
                           @sku,
                           @last_loc,
                           @last_inv,
                           @sort_seq;

                SELECT @INV_AVL = @INV_AVL - CASE WHEN @drp < @sls THEN @sls ELSE @drp END
                                  -- add back sales after the as of date (consume the demand line)
                                  + ISNULL(@sls, 0) + ISNULL(@po, 0) - ISNULL(@ord, 0);

                IF @debug = 2
                    SELECT 'V' AS line_type,
                           @sku sku,
                           t.location,
                           t.mm mm,
                           DATEADD(m, @sort_seq, @asofdate) bucket,
                           ISNULL(@last_inv, 0) qoh,
                           ISNULL(@atp, 0) atp,
                           ISNULL(@reserve_inv, 0) reserve_qty,
                           ISNULL(@INV_AVL, 0) QUANTITY,
                           t.mult,
                           t.s_mult,
                           t.sort_seq
                    FROM #t t
                    WHERE t.part_no = @sku
                          AND t.location = @last_loc
                          AND SORT_SEQ = @sort_seq + 1;

                INSERT #sku_tbl
                SELECT 'V' AS line_type,
                       @sku sku,
                       t.location,
                       t.mm,
                       DATEADD(m, @sort_seq, @asofdate) bucket,
                       ISNULL(@last_inv, 0) qoh,
                       ISNULL(@atp, 0) atp,
                       ISNULL(@reserve_inv, 0) reserve_qty,
                       ISNULL(@INV_AVL, 0) quantity,
                       t.mult,
                       t.s_mult,
                       t.sort_seq,
                       @alloc_qty alloc_qty,
                       @non_alloc_qty non_alloc_qty
                FROM #t t
                WHERE t.part_no = @sku
                      AND t.location = @last_loc
                      AND t.SORT_SEQ = @sort_seq + 1;

                SELECT @sort_seq = @sort_seq + 1;

                SELECT @drp = SUM(ISNULL(quantity, 0))
                FROM #sku_tbl s
                WHERE s.sku = @sku
                      AND s.LINE_TYPE = 'drp'
                      AND s.sort_seq = @sort_seq + 1
                      AND s.location = @last_loc;

                SELECT @sls = SUM(ISNULL(quantity, 0))
                FROM #sku_tbl
                WHERE sku = @sku
                      AND LINE_TYPE = 'sls'
                      AND sort_seq = @sort_seq + 1
                      AND location = @last_loc;

                SELECT @po = SUM(ISNULL(quantity, 0))
                FROM #sku_tbl
                WHERE sku = @sku
                      AND LINE_TYPE = 'po'
                      AND sort_seq = @sort_seq + 1
                      AND location = @last_loc;

                SELECT @ord = SUM(ISNULL(quantity, 0))
                FROM #sku_tbl
                WHERE sku = @sku
                      AND LINE_TYPE = 'ord'
                      AND sort_seq = @sort_seq + 1
                      AND location = @last_loc;
            END; -- monthly buckets

            SELECT @last_loc = MIN(location)
            FROM #sku_tbl
            WHERE sku = @sku
                  AND location > @last_loc;

            IF @last_loc IS NOT NULL
               AND @sku IS NOT NULL
            BEGIN
                -- 7/15/2016 - calc starting inventory with allocations if usage is on orders.
                SELECT @last_inv = 0,
                       @atp = 0,
                       @reserve_inv = 0,
                       @qty_ord = 0,
                       @alloc_qty = 0,
                       @non_alloc_qty = 0;

                SELECT @last_inv = ISNULL(cia.in_stock, 0) + ISNULL(cia.QcQty2, 0),
                       -- CASE WHEN @usg_option = 'O' THEN 0 else isnull(cia.sof,0) + isnull(cia.allocated,0) end 
                       @qty_ord = ISNULL(cia.SOF, 0) + ISNULL(cia.Allocated, 0),
                       @atp = ISNULL(qty_avl, 0),
                       @reserve_inv = ISNULL(cia.ReserveQty, 0),
                       @alloc_qty = ISNULL(cia.SOF, 0) + ISNULL(cia.Allocated, 0),
                       @non_alloc_qty
                           = ISNULL(cia.Quarantine, 0) + ISNULL(cia.Non_alloc, 0) - ISNULL(cia.ReserveQty, 0)
                FROM dbo.cvo_item_avail_vw cia
                WHERE cia.part_no = @sku
                      AND cia.location = @last_loc;


                IF EXISTS (
                          SELECT 1
                          FROM #sku_tbl
                          WHERE LINE_TYPE = 'ord'
                                AND sort_seq = 1
                                AND location = @last_loc
                                AND sku = @sku
                          )
                    UPDATE #sku_tbl
                    SET quantity = quantity + @qty_ord
                    WHERE sku = @sku
                          AND LINE_TYPE = 'ord'
                          AND sort_seq = 1
                          AND location = @last_loc;
                ELSE
                    INSERT INTO #sku_tbl
                    SELECT -- 
                        'ORD' AS line_type,
                        @sku sku,
                        @last_loc,
                        t.mm,
                        DATEADD(m, t.sort_seq - 1, @asofdate) bucket,
                        0 QOH,
                        0 atp,
                        0 reserve_qty,
                        @qty_ord,
                        t.mult,
                        t.s_mult,
                        t.sort_seq,
                        0 alloc_qty,
                        0 non_alloc_qty
                    FROM #t t
                    WHERE t.part_no = @sku
                          AND t.location = @last_loc
                          AND t.sort_seq = 1;

                SELECT @sort_seq = 0;

                SELECT @INV_AVL = @last_inv;

                SELECT @drp = SUM(ISNULL(quantity, 0))
                FROM #sku_tbl
                WHERE sku = @sku
                      AND LINE_TYPE = 'drp'
                      AND sort_seq = @sort_seq + 1
                      AND location = @last_loc;

                SELECT @sls = SUM(ISNULL(quantity, 0))
                FROM #sku_tbl
                WHERE sku = @sku
                      AND LINE_TYPE = 'sls'
                      AND sort_seq = @sort_seq + 1
                      AND location = @last_loc;

                SELECT @po = SUM(ISNULL(quantity, 0))
                FROM #sku_tbl
                WHERE sku = @sku
                      AND LINE_TYPE = 'po'
                      AND sort_seq = @sort_seq + 1
                      AND location = @last_loc;

                SELECT @ord = SUM(ISNULL(quantity, 0))
                FROM #sku_tbl
                WHERE sku = @sku
                      AND LINE_TYPE = 'ord'
                      AND sort_seq = @sort_seq + 1
                      AND location = @last_loc;
            END;
        END; -- location  loop

        SELECT @sku = MIN(sku)
        FROM #sku_tbl
        WHERE sku > @sku;

        SELECT @last_loc = MIN(location)
        FROM #sku_tbl
        WHERE sku = @sku;

        IF (@sku IS NOT NULL AND @last_loc IS NOT NULL)
        BEGIN
            -- 7/15/2016 - calc starting inventory with allocations if usage is on orders.
            SELECT @last_inv = 0,
                   @atp = 0,
                   @reserve_inv = 0,
                   @qty_ord = 0,
                   @alloc_qty = 0,
                   @non_alloc_qty = 0;

            ;

            SELECT @last_inv = ISNULL(cia.in_stock, 0) + ISNULL(cia.QcQty2, 0),
                   -- CASE WHEN @usg_option = 'O' THEN 0 else isnull(cia.sof,0) + isnull(cia.allocated,0) end 
                   @qty_ord = ISNULL(cia.SOF, 0) + ISNULL(cia.Allocated, 0),
                   @atp = ISNULL(qty_avl, 0),
                   @reserve_inv = ISNULL(cia.ReserveQty, 0),
                   @alloc_qty = ISNULL(cia.SOF, 0) + ISNULL(cia.Allocated, 0),
                   @non_alloc_qty = ISNULL(cia.Quarantine, 0) + ISNULL(cia.Non_alloc, 0) - ISNULL(cia.ReserveQty, 0)
            FROM dbo.cvo_item_avail_vw cia
            WHERE cia.part_no = @sku
                  AND cia.location = @last_loc;

            IF EXISTS (
                      SELECT 1
                      FROM #sku_tbl
                      WHERE LINE_TYPE = 'ord'
                            AND sort_seq = 1
                            AND location = @last_loc
                            AND sku = @sku
                      )
                UPDATE #sku_tbl
                SET quantity = quantity + @qty_ord
                WHERE sku = @sku
                      AND LINE_TYPE = 'ord'
                      AND sort_seq = 1
                      AND location = @last_loc;
            ELSE
                INSERT INTO #sku_tbl
                SELECT -- 
                    'ORD' AS line_type,
                    @sku sku,
                    @last_loc,
                    t.mm,
                    DATEADD(m, t.sort_seq - 1, @asofdate) bucket,
                    0 QOH,
                    0 atp,
                    0 reserve_qty,
                    @qty_ord,
                    t.mult,
                    t.s_mult,
                    t.sort_seq,
                    0 alloc_qty,
                    0 non_alloc_qty
                FROM #t t
                WHERE t.part_no = @sku
                      AND t.location = @last_loc
                      AND t.sort_seq = 1;

            SELECT @sort_seq = 0;

            SELECT @INV_AVL = @last_inv;

            SELECT @drp = SUM(ISNULL(quantity, 0))
            FROM #sku_tbl
            WHERE sku = @sku
                  AND LINE_TYPE = 'drp'
                  AND sort_seq = @sort_seq + 1
                  AND location = @last_loc;

            SELECT @sls = SUM(ISNULL(quantity, 0))
            FROM #sku_tbl
            WHERE sku = @sku
                  AND LINE_TYPE = 'sls'
                  AND sort_seq = @sort_seq + 1
                  AND location = @last_loc;

            SELECT @po = SUM(ISNULL(quantity, 0))
            FROM #sku_tbl
            WHERE sku = @sku
                  AND LINE_TYPE = 'po'
                  AND sort_seq = @sort_seq + 1
                  AND location = @last_loc;

            SELECT @ord = SUM(ISNULL(quantity, 0))
            FROM #sku_tbl
            WHERE sku = @sku
                  AND LINE_TYPE = 'ord'
                  AND sort_seq = @sort_seq + 1
                  AND location = @last_loc;
        END;
    END;

    -- sku loop

    -- final select

    IF @debug = 1
    BEGIN
        SELECT 'sku' sku,
               *
        FROM #sku_tbl;

        SELECT '#t' t,
               *
        FROM #t;
    END;


    -- IF @loc = 'cases'
    -- BEGIN
    DELETE FROM #sku_tbl
    WHERE sku + location IN (
                            SELECT sku + location s_key
                            FROM #sku_tbl
                            WHERE location <> '001'
                            GROUP BY sku + location
                            HAVING SUM(quantity) = 0
                            );

    -- END


    --=iif(Parameters!WksOnHandGTLT.Value="ALL",true,iif(Parameters!WksOnHandGTLT.Value=">=",
    --iif(Fields!p_e12_wu.Value<= 0,Parameters!WksOnHand.Value+1,Fields!qoh.Value/Fields!p_e12_wu.Value) >= Parameters!WksOnHand.Value,
    --iif(Fields!p_e12_wu.Value<= 0,Parameters!WksOnHand.Value+1,Fields!qoh.Value/Fields!p_e12_wu.Value) <= Parameters!WksOnHand.Value)
    --)
    -- GET WEEKS ON HAND FOR FILTER

    SELECT t.brand,
           t.style,
           t.location,
           t.p_e12_wu,
           sku.QOH,
           CASE WHEN t.p_e12_wu <= 0 THEN 999 WHEN t.p_e12_wu <> 0 THEN sku.QOH / t.p_e12_wu ELSE 0 END WOH
    INTO #WOH
    FROM #t t
        JOIN #sku_tbl sku
            ON sku.location = t.location
               AND sku.sku = t.part_no;

    IF @debug = 5
        SELECT *
        FROM #WOH AS w;

    UPDATE #WOH
    SET WOH = 9999
    WHERE (
          WOH >= @WksOnHand
          AND @WksOnHandGTLT = '>='
          )
          OR (
             WOH <= @WksOnHand
             AND @WksOnHandGTLT = '<='
             )
          OR @WksOnHandGTLT = 'ALL';

    IF @debug = 5
        SELECT *
        FROM #WOH AS w;


    -- fixup
    SELECT DISTINCT
           s.brand,
           s.style,
           specs.vendor,
           specs.type_code,
           specs.gender,
           specs.material,
           specs.moq,
           specs.watch,
           specs.sf,
           CASE WHEN specs.rel_date = '1/1/1900' THEN NULL ELSE specs.rel_date END AS rel_date,
                                    --= (select min(release_date) From cvo_inv_master_r2_vw where collection = i.category
                                    --	and model = ia.field_2)
           CASE WHEN s.pom_date = '1/1/1900' THEN NULL ELSE s.pom_date END AS pom_date,
           s.mth_since_rel,
           s.[Sales M1-3] s_sales_m1_3,
           s.[Sales M1-12] s_sales_m1_12,
           s.s_e4_wu,
           s.s_e12_wu,
           s.s_e52_wu,
           s.s_promo_w4,
           s.s_promo_w12,
           s.s_gross_w4,
           s.s_gross_w12,
                                    -- , #sku_tbl.*
           sku.LINE_TYPE,
           sku.sku,
           sku.location,
           sku.mm,
           CASE WHEN s.rel_date <> ISNULL(ia.field_26, s.rel_date) THEN ia.field_26 END AS p_rel_date,
           CASE WHEN s.pom_date <> ISNULL(ia.field_28, s.pom_date) THEN ia.field_28 END AS p_pom_date,
           (
           SELECT TOP (1)
                  lead_time
           FROM dbo.inv_list il
           WHERE il.part_no = sku.sku
                 AND il.location = '001'
           ORDER BY il.part_no
           ) lead_time,
           sku.bucket,
           sku.QOH,
           sku.atp,
           sku.reserve_qty,
           sku.quantity,
           sku.mult,
           sku.s_mult,
           sku.sort_seq,
           sku.alloc_qty,
           sku.non_alloc_qty,
           t.pct_of_style,
           t.pct_first_po,
           t.pct_sales_style_m1_3,
           t.p_e4_wu,
           t.p_e12_wu,
           t.p_e52_wu,
           t.p_subs_w4,
           t.p_subs_w12,
           t.s_mth_usg,
           t.p_mth_usg,
           t.s_mth_usg_mult,
           t.p_sales_m1_3,
           CASE WHEN sku.LINE_TYPE = 'V'
                     AND sku.sort_seq = 1 THEN ISNULL((
                                                      SELECT SUM(p.qty_ordered)
                                                      FROM dbo.pur_list p (NOLOCK)
                                                          INNER JOIN dbo.inv_master i (NOLOCK)
                                                              ON i.part_no = p.part_no
                                                          INNER JOIN dbo.inv_master_add ia (NOLOCK)
                                                              ON ia.part_no = i.part_no
                                                      WHERE 1 = 1
                                                            AND i.void = 'n'
                                                            AND p.void <> 'V' -- 8/3/2016
                                                            AND p.part_no = sku.sku
                                                            AND p.rel_date <= DATEADD(yy, 1, ia.field_26)
                                                            AND p.type = 'p'
                                                            AND p.location = '001'
                                                      ),
                                                      0
                                                     ) ELSE 0
           END AS p_po_qty_y1,
           CASE WHEN s.pom_date IS NULL
                     OR s.pom_date = '1/1/1900' THEN r.ORDER_THRU_DATE
               WHEN s.pom_date < r.ORDER_THRU_DATE THEN s.pom_date ELSE r.ORDER_THRU_DATE
           END AS ORDER_THRU_DATE,
           r.TIER,                  -- 7/8/2016
           i.type_code p_type_code, -- res type of sku, not style - 11/1/2016
           t.s_rx_w4,               -- 12/5/2016
           t.s_rx_w12,
           t.p_rx_w4,
           t.p_rx_w12,
           t.s_ret_w4,
           t.s_ret_w12,
           t.p_ret_w4,
           t.p_ret_w12,
           t.s_wty_w4,
           t.s_wty_w12,
           t.p_wty_w4,
           t.p_wty_w12,
           t.p_gross_w4,
           t.p_gross_w12,
           specs.price,
           specs.frame_type
    FROM #sku_tbl sku
        INNER JOIN #t t
            ON t.part_no = sku.sku
               AND t.mm = sku.mm
               AND t.location = sku.location
               AND t.mult = sku.mult
               AND t.sort_seq = sku.sort_seq
        INNER JOIN dbo.inv_list IL
            ON IL.location = t.location
               AND IL.part_no = t.part_no
        INNER JOIN dbo.inv_master i (NOLOCK)
            ON sku.sku = i.part_no
        INNER JOIN dbo.inv_master_add ia (NOLOCK)
            ON sku.sku = ia.part_no
        INNER JOIN #style s
            ON s.brand = i.category
               AND s.style = ia.field_2
               AND s.location = sku.location
        LEFT OUTER JOIN
        (
        SELECT i.category brand,
               ia.field_2 style,
               i.vendor,
               MAX(i.type_code) type_code,
               MAX(ia.category_2) gender,
                                                                -- MAX(i.cmdty_code) material ,
               MAX(ISNULL(ia.field_10, i.cmdty_code)) material, -- 12/12/2016
               MAX(ISNULL(ia.field_11, 'UNKNOWN')) frame_type,
               MAX(ISNULL(ia.category_1, '')) watch,
               (
               SELECT TOP (1)
                      MOQ_info
               FROM dbo.cvo_Vendor_MOQ
               WHERE Vendor_Code = i.vendor
               ORDER BY Vendor_Code
               ) moq,
                                                                -- MAX(ISNULL(ia.field_32, '')) sf,
               MAX(ISNULL(pa.attribute, '')) sf,
               MIN(ISNULL(ia.field_26, '1/1/1900')) rel_date,
               MAX(pp.price_a) price
        FROM dbo.inv_master i (NOLOCK)
            JOIN @type_tbl AS t
                ON t.type_code = i.type_code
            INNER JOIN dbo.inv_master_add ia (NOLOCK)
                ON ia.part_no = i.part_no
            INNER JOIN dbo.part_price pp (NOLOCK)
                ON pp.part_no = i.part_no
            LEFT OUTER JOIN
            (
            SELECT c.part_no,
                   STUFF((
                         SELECT '; ' + attribute
                         FROM dbo.cvo_part_attributes pa2 (NOLOCK)
                         WHERE pa2.part_no = c.part_no
                         FOR XML PATH('')
                         ),
                         1,
                         1,
                         ''
                        ) attribute
            FROM dbo.cvo_part_attributes c
            ) AS pa
                ON pa.part_no = i.part_no
        WHERE 1 = 1
        GROUP BY i.category,
                 ia.field_2,
                 i.vendor
        ) AS specs
            ON specs.brand = s.brand
               AND specs.style = s.style
        INNER JOIN
        (SELECT DISTINCT brand, style FROM #WOH WHERE WOH = 9999) WOH
            ON WOH.brand = s.brand
               AND WOH.style = s.style
        LEFT OUTER JOIN dbo.cvo_ifp_rank r
            ON r.brand = s.brand
               AND r.style = s.style;

END;


GO
