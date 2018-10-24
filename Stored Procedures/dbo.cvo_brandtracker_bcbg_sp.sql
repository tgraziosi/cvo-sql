SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- 8/18/2015 - when calculating FirstOrder units, don't qualify on promo/level, only on promo

-- exec cvo_brandtracker_bcbg_sp '09/01/2018', null, 'bcbg', null, 'bcbg','new,current', 0


CREATE PROCEDURE [dbo].[cvo_brandtracker_bcbg_sp]
    @df DATETIME = NULL ,      -- fromdate
    @dto DATETIME = NULL ,     -- todate 
    @b VARCHAR(1024) = NULL ,  -- brand
    @t VARCHAR(1024) = NULL ,  -- territory
    @bp VARCHAR(1024) = NULL , -- buyin promo list
    @bl VARCHAR(1024) = NULL,  -- buyin levels
    @debug INT = 0
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @datefrom DATETIME ,
            @dateto DATETIME ,
            @brand VARCHAR(1024) ,
            @terr VARCHAR(1024) ,
            @bpromo_id VARCHAR(1024) ,
            @bpromo_level VARCHAR(1024);


    SELECT @datefrom = @df ,
           @dateto = @dto ,
           @brand = @b ,
           @terr = @t ,
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
            terr VARCHAR(10), region VARCHAR(10)
        );

    IF ( OBJECT_ID('tempdb.dbo.#bp') IS NOT NULL )
        DROP TABLE #bp;
    CREATE TABLE #bp
        (
            bp VARCHAR(20)
        );

    IF ( OBJECT_ID('tempdb.dbo.#bl') IS NOT NULL )
        DROP TABLE #bl;
    CREATE TABLE #bl
        (
            bl VARCHAR(30)
        );

    IF ( OBJECT_ID('tempdb.dbo.#t') IS NOT NULL )
        DROP TABLE #t;

    CREATE TABLE #t
    (
        territory_code   VARCHAR(10),
        customer_code    VARCHAR(10),
        ship_to_code     VARCHAR(10),
        customer_name    VARCHAR(40),
        contact_name     VARCHAR(40),
        contact_phone    VARCHAR(30),
        contact_email    VARCHAR(255),
        promo_id         VARCHAR(20),
        promo_level      VARCHAR(30),
        brand            VARCHAR(20),
        first_order_date DATETIME,
        first_order_ship DATETIME
    );

    IF ( OBJECT_ID('tempdb.dbo.#v') IS NOT NULL )
        DROP TABLE #v;

    CREATE TABLE #v
    (
        customer_code VARCHAR(10),
        ship_to_code  VARCHAR(10),
        NetUnits      integer,
        NetSales      DECIMAL(20,8),
        sale_type     VARCHAR(2),
        BUCKET        VARCHAR(4),
        mm            NVARCHAR(30)
    );

    IF @datefrom IS NULL
        SELECT @datefrom = '09/1/2018';
    IF @dateto IS NULL
        SELECT @dateto = GETDATE();
    -- if @brand is null select @brand = 'as'

    IF ISNULL(@brand, '') = ''
        BEGIN
            INSERT #brand ( brand )
                   SELECT DISTINCT kys
                   FROM   dbo.category
                   WHERE  void = 'n';
        END;
    ELSE
        BEGIN
            INSERT #brand ( brand )
                   SELECT DISTINCT ListItem
                   FROM   dbo.f_comma_list_to_table(@brand);
        END;

    IF ISNULL(@terr, '') = ''
        BEGIN
            INSERT #terr ( terr, region )
                   SELECT DISTINCT territory_code, dbo.calculate_region_fn(territory_code)
                   FROM   dbo.armaster ( NOLOCK )
                   WHERE  ISNULL(territory_code, '') > '';
        END;
    ELSE
        BEGIN
            INSERT #terr ( terr, region )
                   SELECT DISTINCT ListItem, dbo.calculate_region_fn(ListItem)
                   FROM   dbo.f_comma_list_to_table(@terr);
        END;

    IF ISNULL(@bpromo_id, '') = ''
        BEGIN
            INSERT #bp ( bp )
                   SELECT DISTINCT promo_id
                   FROM   dbo.CVO_promotions ( NOLOCK )
                   WHERE  ISNULL(promo_id, '') > ''
                          AND void <> 'v'
                   UNION ALL
                   SELECT '';
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
                   FROM   dbo.CVO_promotions ( NOLOCK )
                          JOIN #bp ON promo_id = bp
                   WHERE  ISNULL(promo_level, '') > ''
                   UNION ALL
                   SELECT '';
        END;
    ELSE
        BEGIN
            INSERT #bl ( bl )
                   SELECT DISTINCT ListItem
                   FROM   dbo.f_comma_list_to_table(@bpromo_level);
        END;


    -- get first order information based on buy-in promo list

    INSERT INTO #t
        (
            territory_code,
            customer_code,
            ship_to_code,
            customer_name,
            contact_name,
            contact_phone,
            contact_email,
            promo_id,
            promo_level,
            brand,
            first_order_date,
            first_order_ship
        )

    SELECT ar.territory_code ,
           ar.customer_code ,
           ar.ship_to_code, 
           ar.customer_name ,
           aa.contact_name ,
           aa.contact_phone ,
           aa.contact_email ,
           bb.promo_id ,
           bb.promo_level ,
           ISNULL(bb.brand,@brand) brand ,
           bb.first_order_date ,
           bb.first_order_ship 

    FROM   #terr
           INNER JOIN dbo.arcust ar ( NOLOCK ) ON terr = ar.territory_code
           LEFT OUTER JOIN dbo.adm_arcontacts AS aa (nolock) ON aa.customer_code = ar.customer_code AND aa.contact_code = 'AMB'

           LEFT OUTER  JOIN (   SELECT null brand, 
                                   sbm.customer ,
                                   MIN(ISNULL(sbm.promo_id, '')) promo_id ,
                                   MIN(ISNULL(sbm.promo_level, '')) promo_level ,
                                   MIN(sbm.DateOrdered) first_order_date ,
                                   MIN(sbm.yyyymmdd) first_order_ship

                          FROM     cvo_promotions p
                                   JOIN #bp ON bp = p.promo_id
                                   JOIN #bl ON bl = p.promo_level
                                   JOIN dbo.cvo_sbm_details sbm ON sbm.promo_id = p.promo_id AND sbm.promo_level = p.promo_level
                                   INNER JOIN dbo.inv_master i ON sbm.part_no = i.part_no
                                   
                          WHERE    1 = 1
                                   -- and i.type_code in ('frame','sun')
                                   -- and sbm.user_category like 'ST%' 
                                   AND ISNULL(RIGHT(sbm.user_category, 2),'') <> 'rb'
                                   AND ISNULL(sbm.promo_id, '') NOT IN ( 'pc' ,
                                                                         'ff' ,
                                                                         'style out' )
                                   -- and dateordered between @datefrom and @dateto
                                   AND ISNULL(sbm.yyyymmdd,@datefrom)
                                   BETWEEN ISNULL(p.promo_start_date,@datefrom) AND @dateto
                          GROUP BY sbm.customer ) 
                          AS bb ON bb.customer = ar.customer_code
                          WHERE (bb.first_order_date IS NOT NULL OR aa.contact_code = 'AMB');


    CREATE NONCLUSTERED INDEX idx_t ON #t (customer_code);

    -- get BI and re-order information

    INSERT INTO #v
    SELECT   #t.customer_code ,
             #t.ship_to_code,
             ISNULL(sbm.qnet, 0) NetUnits ,
             ISNULL(sbm.anet, 0.0) NetSales ,
             'BI' sale_type,
             '' BUCKET,
             '' mm
        FROM     #t
             INNER JOIN dbo.cvo_sbm_details sbm ON sbm.customer = #t.customer_code
                                               AND sbm.promo_id = #t.promo_id
                                               AND sbm.promo_level = #t.promo_level
             INNER JOIN cvo_promotions p on p.promo_id = #t.promo_id AND p.promo_level = #t.promo_level
             INNER JOIN inv_master i ON i.part_no = sbm.part_no

    WHERE    sbm.yyyymmdd BETWEEN p.promo_start_date AND @dateto
             AND (RIGHT(sbm.user_category, 2) <> 'rb' )
             AND i.type_code IN ('frame','sun')
    
    UNION ALL

    SELECT   #t.customer_code ,
             #t.ship_to_code,
             ISNULL(sbm.qnet, 0) NetUnits ,
             ISNULL(sbm.anet, 0.0) NetSales ,
             'RX'   sale_type,
             CASE WHEN datepart(WEEK,sbm.DateOrdered) = DATEPART(WEEK,@dateto)  THEN 'WEEK'
                    WHEN MONTH(SBM.DATEORDERED) = MONTH(@DATETO) THEN 'MTH'
                    WHEN SBM.DateOrdered BETWEEN @datefrom AND @DATETO THEN 'PGM'          
                ELSE '' 
             END AS BUCKET,
             DATENAME(month,SBM.dateordered) mm
    FROM     #t
             INNER JOIN dbo.inv_master i ON i.category = #t.brand
                                        -- AND i.type_code = #t.tc
             INNER JOIN dbo.inv_master_add ia ON ia.part_no = i.part_no
             INNER JOIN dbo.cvo_sbm_details sbm ON sbm.customer = #t.customer_code AND sbm.ship_to = #t.ship_to_code
                                               AND sbm.part_no = i.part_no
    WHERE    'RX' = LEFT(sbm.user_category,2)
             AND sbm.yyyymmdd BETWEEN @datefrom AND @dateto
             AND sbm.promo_id NOT IN ( 'pc', 'ff', 'style out' ) 
             AND (RIGHT(sbm.user_category, 2) <> 'rb' )
             AND i.type_code IN ('frame','sun')

    ;

    CREATE NONCLUSTERED INDEX idx_v ON #v (customer_code);

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

    WHILE @cust IS NOT NULL
        BEGIN
            -- get new/reactivated status
            INSERT INTO #newrea
            EXEC dbo.CVO_NewReaCust_SP @customer = @cust;

            SELECT @cust = MIN(customer_code)
            FROM   #t
            WHERE  customer_code > @cust;
        END;

    IF @debug <> 0 
    BEGIN
    SELECT * FROM #t AS t
    SELECT * FROM #v AS v
    END
    

    SELECT   DISTINCT #t.territory_code ,
             #t.customer_code ,
             #t.ship_to_code,
             #t.customer_name ,
             ISNULL(#t.contact_name,'No Ambassador') contact_name ,
             #t.contact_phone ,
             #t.contact_email ,
             #t.promo_id ,
             #t.promo_level ,
             #t.brand ,
             #t.first_order_date ,
             #t.first_order_ship ,
             v.netunits NetUnits ,
             v.netsales NetSales,
             v.sale_type ,
             ISNULL(newrea, '') newrea ,
             c.description brand_name ,
             #terr.region,
             CASE WHEN v.sale_type = 'BI' THEN 'BI' ELSE V.BUCKET END BUCKET,
             V.mm,
             slp.salesperson_name
    FROM     #t
             JOIN dbo.armaster ar ON ar.customer_code = #t.customer_code AND ar.ship_to_code = #t.ship_to_code
             JOIN dbo.arsalesp slp ON slp.salesperson_code = ar.salesperson_code
             JOIN #terr ON #terr.terr = #t.territory_code
             JOIN dbo.category AS c ON c.kys = #t.brand
             LEFT OUTER JOIN #newrea ON #t.customer_code = #newrea.customer_code
             LEFT OUTER JOIN 
             ( SELECT customer_code, sale_type, MM,  bucket, SUM(netunits) netunits, SUM(netsales) netsales
                FROM #v GROUP BY customer_code, bucket, MM, sale_type )
                v ON v.customer_code = #t.customer_code
    WHERE    1 = 1;
    

END;











GO
GRANT EXECUTE ON  [dbo].[cvo_brandtracker_bcbg_sp] TO [public]
GO
