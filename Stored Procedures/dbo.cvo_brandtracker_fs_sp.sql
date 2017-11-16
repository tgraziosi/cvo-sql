SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- 8/18/2015 - when calculating FirstOrder units, don't qualify on promo/level, only on promo

-- exec cvo_brandtracker_fs_sp '1/1/2015', null, 'op', 'sun', null, 'op,sunps', 'suns,op', null, null, 0

CREATE PROCEDURE [dbo].[cvo_brandtracker_fs_sp]
    @df DATETIME = NULL ,      -- fromdate
    @dto DATETIME = NULL ,     -- todate
    @b VARCHAR(1024) = NULL ,  -- brand
    @a VARCHAR(1024) = NULL ,  -- type_code
    @t VARCHAR(1024) = NULL ,  -- territory
    @bp VARCHAR(1024) = NULL , -- buyin promo list
    @bl VARCHAR(1024) = NULL , -- buyin levels
    @p VARCHAR(1024) = NULL ,  -- highlight promo
    @l VARCHAR(1024) = NULL ,  -- highlight level
    @debug INT = 0
AS

    SET NOCOUNT ON;

    DECLARE @datefrom DATETIME ,
            @dateto DATETIME ,
            @brand VARCHAR(1024) ,
            @tc VARCHAR(1024) ,
            @terr VARCHAR(1024) ,
            @fpromo_id VARCHAR(1024) ,
            @fpromo_level VARCHAR(1024) ,
            @bpromo_id VARCHAR(1024) ,
            @bpromo_level VARCHAR(1024);


    SELECT @datefrom = @df ,
           @dateto = @dto ,
           @brand = @b ,
           @terr = @t ,
           @tc = @a ,
           @fpromo_id = @p ,
           @fpromo_level = @l ,
           @bpromo_id = @bp ,
           @bpromo_level = @bl;
    -- select @tc = null

    IF ( OBJECT_ID('tempdb.dbo.#brand') IS NOT NULL )
        DROP TABLE #brand;
    CREATE TABLE #brand
        (
            brand VARCHAR(20)
        );

    IF ( OBJECT_ID('tempdb.dbo.#terr') IS NOT NULL )
        DROP TABLE #terr;
    CREATE TABLE #terr
        (
            terr VARCHAR(10)
        );

    IF ( OBJECT_ID('tempdb.dbo.#tc') IS NOT NULL )
        DROP TABLE #tc;
    CREATE TABLE #tc
        (
            tc VARCHAR(20)
        );

    IF ( OBJECT_ID('tempdb.dbo.#bp') IS NOT NULL )
        DROP TABLE #bp;
    CREATE TABLE #bp
        (
            bp VARCHAR(10)
        );

    IF ( OBJECT_ID('tempdb.dbo.#bl') IS NOT NULL )
        DROP TABLE #bl;
    CREATE TABLE #bl
        (
            bl VARCHAR(10)
        );

    IF ( OBJECT_ID('tempdb.dbo.#fp') IS NOT NULL )
        DROP TABLE #fp;
    CREATE TABLE #fp
        (
            fp VARCHAR(10)
        );

    IF ( OBJECT_ID('tempdb.dbo.#fl') IS NOT NULL )
        DROP TABLE #fl;
    CREATE TABLE #fl
        (
            fl VARCHAR(10)
        );

    IF ( OBJECT_ID('tempdb.dbo.#t') IS NOT NULL )
        DROP TABLE #t;

    IF @datefrom IS NULL
        SELECT @datefrom = '1/1/2015';
    IF @dateto IS NULL
        SELECT @dateto = GETDATE();
    -- if @brand is null select @brand = 'as'

    IF ISNULL(@brand, '') = ''
        BEGIN
            INSERT #brand ( brand )
                   SELECT DISTINCT kys
                   FROM   category
                   WHERE  void = 'n';
        END;
    ELSE
        BEGIN
            INSERT #brand ( brand )
                   SELECT DISTINCT ListItem
                   FROM   dbo.f_comma_list_to_table(@brand);
        END;

    IF ISNULL(@tc, '') = ''
        BEGIN
            INSERT #tc ( tc )
                   SELECT DISTINCT type_code
                   FROM   inv_master;
        -- insert #tc (tc) values ('')
        END;
    ELSE
        BEGIN
            INSERT #tc ( tc )
                   SELECT DISTINCT ListItem
                   FROM   dbo.f_comma_list_to_table(@tc);
        END;

    IF ISNULL(@terr, '') = ''
        BEGIN
            INSERT #terr ( terr )
                   SELECT DISTINCT territory_code
                   FROM   armaster ( NOLOCK )
                   WHERE  ISNULL(territory_code, '') > '';
        END;
    ELSE
        BEGIN
            INSERT #terr ( terr )
                   SELECT DISTINCT ListItem
                   FROM   dbo.f_comma_list_to_table(@terr);
        END;

    IF ISNULL(@bpromo_id, '') = ''
        BEGIN
            INSERT #bp ( bp )
                   SELECT DISTINCT promo_id
                   FROM   CVO_promotions ( NOLOCK )
                   WHERE  ISNULL(promo_id, '') > ''
                          AND void <> 'v';
        END;
    ELSE
        BEGIN
            INSERT #bp ( bp )
                   SELECT DISTINCT ListItem
                   FROM   dbo.f_comma_list_to_table(@bpromo_id);
        END;

    IF ISNULL(@bpromo_level, '') = ''
        BEGIN
            INSERT #bl ( bl )
                   SELECT DISTINCT promo_id
                   FROM   CVO_promotions ( NOLOCK )
                          JOIN #bp ON promo_id = #bp.bp
                   WHERE  ISNULL(promo_level, '') > '';
        END;
    ELSE
        BEGIN
            INSERT #bl ( bl )
                   SELECT DISTINCT ListItem
                   FROM   dbo.f_comma_list_to_table(@bpromo_level);
        END;


    IF ISNULL(@fpromo_id, '') = ''
        BEGIN
            INSERT #fp ( fp )
                   SELECT DISTINCT promo_id
                   FROM   CVO_promotions ( NOLOCK )
                   WHERE  ISNULL(promo_id, '') > ''
                          AND void <> 'v';
        END;
    ELSE
        BEGIN
            INSERT #fp ( fp )
                   SELECT DISTINCT ListItem
                   FROM   dbo.f_comma_list_to_table(@fpromo_id);
        END;

    IF ISNULL(@fpromo_level, '') = ''
        BEGIN
            INSERT #fl ( fl )
                   SELECT DISTINCT promo_id
                   FROM   CVO_promotions ( NOLOCK )
                          JOIN #fp ON promo_id = #fp.fp
                   WHERE  ISNULL(promo_level, '') > '';
        END;
    ELSE
        BEGIN
            INSERT #fl ( fl )
                   SELECT DISTINCT ListItem
                   FROM   dbo.f_comma_list_to_table(@fpromo_level);
        END;


    -- get first order information based on buy-in promo list

    SELECT ar.territory_code ,
           ar.customer_code ,
           ar.customer_name ,
           ar.contact_name ,
           ar.contact_phone ,
           ar.contact_email ,
           bb.promo_id ,
           bb.promo_level ,
           bb.brand ,
           bb.type_code ,
           bb.first_order_date ,
           bb.first_order_ship ,
           CAST(NULL AS DATETIME) AS highlight_ship_date

    INTO   #t

    FROM   #terr
           INNER JOIN arcust ar ( NOLOCK ) ON #terr.terr = ar.territory_code

           INNER JOIN (   SELECT   b.brand ,
                                   i.type_code ,
                                   customer ,
                                   MIN(ISNULL(sbm.promo_id, '')) promo_id ,
                                   MIN(ISNULL(sbm.promo_level, '')) promo_level ,
                                   MIN(sbm.DateOrdered) first_order_date ,
                                   MIN(sbm.yyyymmdd) first_order_ship

                          FROM     #brand b
                                   INNER JOIN inv_master i ON b.brand = i.category
                                   INNER JOIN inv_master_add ia ON ia.part_no = i.part_no
                                   INNER JOIN #tc a ON a.tc = i.type_code
                                   INNER JOIN cvo_sbm_details sbm ON sbm.part_no = i.part_no
                                   INNER JOIN #bp ON #bp.bp = sbm.promo_id
                                   INNER JOIN #bl ON #bl.bl = sbm.promo_level
                          WHERE    1 = 1
                                   -- and i.type_code in ('frame','sun')
                                   -- and sbm.user_category like 'ST%' 
                                   AND RIGHT(sbm.user_category, 2) <> 'rb'
                                   AND ISNULL(sbm.promo_id, '') NOT IN ( 'pc' ,
                                                                         'ff' ,
                                                                         'style out' )
                                   -- and dateordered between @datefrom and @dateto
                                   AND sbm.yyyymmdd
                                   BETWEEN @datefrom AND @dateto
                          GROUP BY b.brand ,
                                   i.type_code ,
                                   customer ) AS bb ON bb.customer = ar.customer_code;

    IF @debug = 1
        SELECT *
        FROM   #t
        WHERE  customer_code = '045455';

    SELECT   #t.customer_code ,
             #t.type_code ,
             SUM(ISNULL(qnet, 0)) units ,
             'BI' sale_type
    INTO     #v
    FROM     #t
             INNER JOIN inv_master i ON i.category = #t.brand
                                        AND i.type_code = #t.type_code
             INNER JOIN inv_master_add ia ON ia.part_no = i.part_no
             INNER JOIN #tc a ON a.tc = i.type_code
             INNER JOIN cvo_sbm_details sbm ON sbm.customer = #t.customer_code
                                               AND sbm.part_no = i.part_no
             INNER JOIN #bp ON #bp.bp = sbm.promo_id
             INNER JOIN #bl ON #bl.bl = sbm.promo_level
    WHERE    1 = 1
             AND ISNULL(sbm.promo_id, '') NOT IN ( 'pc', 'ff', 'style out' )
             AND RIGHT(sbm.user_category, 2) <> 'rb'
             AND sbm.DateOrdered = #t.first_order_date
    GROUP BY #t.customer_code ,
             #t.type_code;


    INSERT INTO #v
                SELECT   #t.customer_code ,
                         #t.type_code ,
                         SUM(ISNULL(qnet, 0)) units ,
                         'RX' sale_type
                FROM     #t
                         INNER JOIN inv_master i ON i.category = #t.brand
                                                    AND i.type_code = #t.type_code
                         INNER JOIN inv_master_add ia ON ia.part_no = i.part_no
                         INNER JOIN #tc a ON a.tc = i.type_code
                         INNER JOIN cvo_sbm_details sbm ON sbm.customer = #t.customer_code
                                                           AND sbm.part_no = i.part_no
                WHERE    1 = 1
                         AND ISNULL(sbm.promo_id, '') NOT IN ( 'pc', 'ff' ,
                                                               'style out' )
                         AND LEFT(sbm.user_category, 2) IN ( 'rx' )
                         AND RIGHT(sbm.user_category, 2) <> 'rb'
                         AND sbm.yyyymmdd
                         BETWEEN DATEADD(dd, 1, #t.first_order_ship) AND @dateto
                GROUP BY #t.customer_code ,
                         #t.type_code;

    INSERT INTO #v
                SELECT   #t.customer_code ,
                         #t.type_code ,
                         SUM(ISNULL(qnet, 0)) units ,
                         'PC' sale_type
                FROM     #t
                         INNER JOIN inv_master i ON i.category = #t.brand
                                                    AND i.type_code = #t.type_code
                         INNER JOIN inv_master_add ia ON ia.part_no = i.part_no
                         INNER JOIN #tc a ON a.tc = i.type_code
                         INNER JOIN cvo_sbm_details sbm ON sbm.customer = #t.customer_code
                                                           AND sbm.part_no = i.part_no
                WHERE    1 = 1
                         AND ISNULL(sbm.promo_id, '') IN ( 'pc', 'ff' ,
                                                           'style out' )
                         AND RIGHT(sbm.user_category, 2) <> 'rb'
                         -- AND sbm.return_code <> 'exc'
                         -- and sbm.DateOrdered between DATEADD(dd,1,#t.first_order_date) and @dateto
                         AND sbm.yyyymmdd
                         BETWEEN @datefrom AND @dateto
                GROUP BY #t.customer_code ,
                         #t.type_code;

    INSERT INTO #v
                SELECT   #t.customer_code ,
                         #t.type_code ,
                         SUM(ISNULL(qnet, 0)) units ,
                         'ST' sale_type
                FROM     #t
                         INNER JOIN inv_master i ON i.category = #t.brand
                                                    AND i.type_code = #t.type_code
                         INNER JOIN inv_master_add ia ON ia.part_no = i.part_no
                         INNER JOIN #tc a ON a.tc = i.type_code
                         INNER JOIN cvo_sbm_details sbm ON sbm.customer = #t.customer_code
                                                           AND sbm.part_no = i.part_no
                WHERE    1 = 1
                         AND ISNULL(sbm.promo_id, '') NOT IN ( 'pc', 'ff' ,
                                                               'style out' )
                         AND LEFT(sbm.user_category, 2) IN ( 'ST', '' )
                         AND RIGHT(sbm.user_category, 2) <> 'rb'
                         -- AND sbm.return_code <> 'exc'
                         AND sbm.yyyymmdd
                         BETWEEN DATEADD(dd, 1, #t.first_order_ship) AND @dateto
                GROUP BY #t.customer_code ,
                         #t.type_code;

    IF @debug = 1
        SELECT *
        FROM   #v
        WHERE  customer_code = '026595';

    IF ( OBJECT_ID('tempdb.dbo.#newrea') IS NOT NULL )
        DROP TABLE #newrea;

    CREATE TABLE #newrea
        (
            newrea VARCHAR(3) ,
            customer_code VARCHAR(10) ,
            ship_to_code VARCHAR(8) ,
            firstst_new DATETIME ,
            prevst_new DATETIME
        );

    DECLARE @cust VARCHAR(10);

    SELECT @cust = MIN(customer_code)
    FROM   #t;

    IF @debug = 1
        SELECT *
        FROM   #t
        WHERE  customer_code = @cust;

    WHILE @cust IS NOT NULL
        BEGIN
            -- get new/reactivated status
            INSERT INTO #newrea
            EXEC CVO_NewReaCust_SP @cust;

            SELECT @cust = MIN(customer_code)
            FROM   #t
            WHERE  customer_code > @cust;
        END;


    IF EXISTS (   SELECT 1 fp
                  FROM   #fp ) -- @promo_id IS NOT NULL AND @promo_level IS NOT NULL
        BEGIN
            UPDATE #t
            SET    highlight_ship_date = s.h_date
            FROM   #t
                   INNER JOIN (   SELECT   customer ,
                                           MIN(yyyymmdd) h_date
                                  FROM     dbo.cvo_sbm_details sbm
                                           INNER JOIN #fp ON #fp.fp = sbm.promo_id
                                           INNER JOIN #fl ON #fl.fl = sbm.promo_level

                                  WHERE    1 = 1
                                           -- promo_id = @promo_id AND promo_level = @promo_level
                                           AND sbm.yyyymmdd
                                           BETWEEN @datefrom AND @dateto
                                           AND user_category LIKE 'ST%'
                                           AND RIGHT(user_category, 2) <> 'rb'
                                  -- AND sbm.return_code <> 'exc'
                                  GROUP BY customer ) AS s ON #t.customer_code = s.customer;
        END;

    SELECT   DISTINCT #t.territory_code ,
             #t.customer_code ,
             #t.customer_name ,
             #t.contact_name ,
             #t.contact_phone ,
             #t.contact_email ,
             #t.promo_id ,
             #t.promo_level ,
             #t.brand ,
             #t.type_code ,
             #t.first_order_date ,
             #t.first_order_ship ,
             #t.highlight_ship_date ,
             #v.units ,
             #v.sale_type ,
             ISNULL(#newrea.newrea, '') newrea ,
             c.description brand_name ,
             dbo.calculate_region_fn(#t.territory_code) region
    FROM     #t
             LEFT OUTER JOIN #newrea ON #t.customer_code = #newrea.customer_code
             INNER JOIN category c ON c.kys = #t.brand
             LEFT OUTER JOIN #v ON #v.customer_code = #t.customer_code
                                   AND #v.type_code = #t.type_code
    WHERE    1 = 1
    ORDER BY customer_code;




GO
