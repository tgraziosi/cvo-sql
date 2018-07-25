SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--  EXEC SSRS_Territory_Planner_terr_sp '7/1/2017','06/30/2018', '70721'

CREATE PROCEDURE [dbo].[SSRS_Territory_Planner_terr_sp]
    @DF DATETIME = NULL,
    @DT DATETIME = NULL,
    @Terr VARCHAR(1024) = NULL,
    @coll VARCHAR(1024) = NULL
AS
BEGIN

    -- TERITORY PLANNER
    -------- CREATED BY *Elizabeth LaBarbera*  9/24/12
    -- rewrite 040115 tag

    ---- for testing
    --DECLARE @DF datetime, @DT datetime, @terr varchar(1024)
    --select @terr = null, @dt = getdate(), @df = dateadd(yy, datediff(yy,0, getdate()), 0)	
    ----

    DECLARE @DateFromLY DATETIME,
            @DateToLY DATETIME,
            @datefrom DATETIME,
            @dateto DATETIME;

    DECLARE @Territory VARCHAR(1024),
            @collection VARCHAR(1024);

    SELECT @Territory = @Terr,
           @datefrom = @DF,
           @dateto = @DT,
           @DateFromLY = DATEADD(yy, -1, @DF),
           @DateToLY = DATEADD(yy, -1, @DT),
           @collection = @coll;


    IF (OBJECT_ID('tempdb.dbo.#Territory') IS NOT NULL)
        DROP TABLE dbo.#Territory;

    --declare @Territory varchar(1000)
    --select  @Territory = null

    CREATE TABLE #territory
    (
        territory VARCHAR(8)
    );

    IF @Territory IS NULL
    BEGIN
        INSERT INTO #territory
        (
            territory
        )
        SELECT DISTINCT
               territory_code
        FROM armaster (NOLOCK)
        WHERE address_type <> 9;
    END;
    ELSE
    BEGIN
        INSERT INTO #territory
        (
            territory
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@Territory);
    END;

    CREATE TABLE #coll
    (
        coll VARCHAR(12)
    );

    IF @collection IS NULL
    BEGIN
        INSERT INTO #coll
        (
            coll
        )
        SELECT DISTINCT
               kys
        FROM category (NOLOCK)
        WHERE void = 'N';
    END;
    ELSE
    BEGIN
        INSERT INTO #coll
        (
            coll
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@collection);
    END;


    -- Lookup 0 & 9 affiliated Accounts
    IF (OBJECT_ID('tempdb.dbo.#Rank_Aff') IS NOT NULL)
        DROP TABLE #Rank_Aff;
    SELECT a.customer_code AS from_cust,
           a.ship_to_code AS shipto,
           a.affiliated_cust_code AS to_cust
    INTO #Rank_Aff
    FROM armaster a (NOLOCK)
        INNER JOIN armaster b (NOLOCK)
            ON a.affiliated_cust_code = b.customer_code
               AND a.ship_to_code = b.ship_to_code
    WHERE a.status_type <> 1
          AND a.address_type <> 9
          AND a.affiliated_cust_code <> ''
          AND a.affiliated_cust_code IS NOT NULL
          AND b.status_type = 1
          AND b.address_type <> 9;
    --select @@rowcount
    --select * from #Rank_Aff

    --Add ReClassify for Affiliation 
    IF (OBJECT_ID('tempdb.dbo.#Rank_Aff_All') IS NOT NULL)
        DROP TABLE dbo.#Rank_Aff_All;
    SELECT X.CUST,
           X.Code
    INTO #Rank_Aff_All
    FROM
    (
    SELECT from_cust AS CUST,
           'I' AS Code
    FROM #Rank_Aff
    UNION ALL
    SELECT to_cust AS CUST,
           'A' Code
    FROM #Rank_Aff
    ) X;
    --SELECT * FROM #Rank_Aff_All 


    IF (OBJECT_ID('tempdb.dbo.#OldestOrderDate') IS NOT NULL)
        DROP TABLE dbo.#OldestOrderDate;
    SELECT customer_code,
           ship_to_code,
           (
           SELECT TOP 1
                  T1.date_entered
           FROM orders_all (NOLOCK) T1
               JOIN ord_list (NOLOCK) T2
                   ON T1.order_no = T2.order_no
                      AND T1.ext = T2.order_ext
               JOIN inv_master (NOLOCK) t3
                   ON T2.part_no = t3.part_no
           WHERE T1.cust_code = ar.customer_code
                 AND T1.ship_to = ar.ship_to_code
                 AND T1.status = 't'
                 AND T1.type = 'i'
                 AND T1.who_entered <> 'backordr'
                 AND t3.type_code IN ( 'frame', 'sun' )
                 AND T1.date_entered
                 BETWEEN DATEADD(DAY, 1, DATEADD(YEAR, -1, @dateto)) AND @dateto
                 AND T1.user_category NOT LIKE 'rx%'
           GROUP BY T1.cust_code,
                    T1.ship_to,
                    date_entered
           HAVING COUNT(T2.ordered) >= 5
           ORDER BY cust_code,
                    T1.ship_to,
                    date_entered DESC
           ) AS OldestSTOrdDate
    INTO #OldestOrderDate
    FROM armaster AR (NOLOCK)
    ORDER BY customer_code,
             ship_to_code;

    -- Get Customer#, Shipto#, Name, Addr, City, State, Zip, Phone, Fax, Contact
    -- Add 0/9 Status to Customer Data
    -- add in Parent &/or BG
    IF (OBJECT_ID('tempdb.dbo.#custinfo') IS NOT NULL)
        DROP TABLE dbo.#custinfo;

    SELECT RIGHT(ar.customer_code, 5) customer_code,
           ar.ship_to_code,
           ar.territory_code,
           MAX(car.door) door,
           MIN(ISNULL(t3.Code, 'A')) Status,
           MIN(ISNULL(ar.address_name, '')) address_name,
           MIN(ISNULL(ar.addr2, '')) addr2,
           MIN(ISNULL(ar.city, '')) city,
           MIN(ISNULL(ar.state, '')) state,
           MIN(ISNULL(ar.postal_code, '')) postal_code,
           MIN(ISNULL(ar.contact_phone, '')) contact_phone,
           MIN(ISNULL(ar.tlx_twx, '')) tlx_twx,
           MIN(ISNULL(ar.contact_email, '')) contact_email,
           MIN(ISNULL(ar.contact_name, '')) contact_name,
           MIN(ISNULL(CASE WHEN ar.customer_code = art.parent THEN '' ELSE art.parent END, '')) AS Parent,
           MIN(ISNULL(arm.address_name, '')) AS m_address,
           MIN(ISNULL(arm.addr2, '')) AS m_addr2,
           MIN(ISNULL(arm.city, '')) AS m_city,
           MIN(ISNULL(arm.state, '')) AS m_state,
           MIN(ISNULL(arm.postal_code, '')) AS m_postal_code,
           MIN(ISNULL(arm.contact_phone, '')) AS m_contact_phone,
           MIN(ISNULL(arm.tlx_twx, '')) AS m_tlx_twx,
           MIN(ISNULL(arm.contact_email, '')) AS m_contact_email,
           MIN(ISNULL(arm.contact_name, '')) AS m_contact_name,
           MIN(ISNULL(carm.door, '')) AS m_door,
           oldeststorddate =
           (
           SELECT MIN(OldestSTOrdDate)
           FROM #OldestOrderDate o
           WHERE RIGHT(o.customer_code, 5) = RIGHT(ar.customer_code, 5)
                 AND ar.ship_to_code = o.ship_to_code
           ),
           m_oldeststorddate =
           (
           SELECT MIN(OldestSTOrdDate)
           FROM #OldestOrderDate o
           WHERE RIGHT(o.customer_code, 5) = RIGHT(ar.customer_code, 5)
           )
    INTO #custinfo
    FROM #territory t
        INNER JOIN armaster ar (NOLOCK)
            ON t.territory = ar.territory_code
        INNER JOIN CVO_armaster_all car (NOLOCK)
            ON ar.customer_code = car.customer_code
               AND ar.ship_to_code = car.ship_to
        FULL OUTER JOIN #Rank_Aff_All t3 (NOLOCK)
            ON ar.customer_code = t3.CUST
        LEFT OUTER JOIN artierrl (NOLOCK) art
            ON art.rel_cust = ar.customer_code
        -- for master customer info
        LEFT OUTER JOIN armaster arm (NOLOCK)
            ON arm.customer_code = ar.customer_code
               AND arm.ship_to_code = ''
        LEFT OUTER JOIN CVO_armaster_all carm (NOLOCK)
            ON carm.customer_code = arm.customer_code
               AND carm.ship_to = arm.ship_to_code
    WHERE ar.address_type <> 9
    GROUP BY RIGHT(ar.customer_code, 5),
             ar.ship_to_code,
             ar.territory_code;

    -- select * from #custinfo where customer_code like '%41407'

    -- Select Net Sales

    IF (OBJECT_ID('tempdb.dbo.#netsales') IS NOT NULL)
        DROP TABLE dbo.#netsales;

    SELECT DISTINCT
           ar.territory_code,
           RIGHT(ar.customer_code, 5) customer_code,
           ar.ship_to_code,
           sbm.TYLY,
           sbm.ordertype,
           brand,
           demographic,
           itemtype,
           anet,
           areturns,
           qnet,
           qreturns,
           promo_flg = CASE WHEN sbm.promo_id > '' AND EXISTS (SELECT 1 FROM #coll WHERE coll = sbm.brand) THEN 'Y' ELSE
'' END
    INTO #netsales
    FROM #territory t
        INNER JOIN armaster ar (NOLOCK)
            ON t.territory = ar.territory_code
        INNER JOIN
        (
        SELECT RIGHT(customer, 5) customer,
               ship_to,
               i.category brand,
               demographic = CASE WHEN ia.category_2 LIKE '%child%' THEN 'Kids' ELSE 'Adult' END,
               itemtype = i.type_code,
               ordertype = CASE WHEN LEFT(sbm.user_category, 2) = 'rx' THEN 'RX' ELSE 'ST' END,
               TYLY = CASE WHEN yyyymmdd >= @datefrom THEN 'TY' ELSE 'LY' END,
               -- , TYLY = case when yyyymmdd >= '01/01/2015' then 'TY' else 'LY' end 
               SUM(anet) anet,
               SUM(CASE WHEN return_code = '' THEN areturns ELSE 0 END) areturns,
               SUM(qnet) qnet,
               SUM(CASE WHEN return_code = '' THEN qreturns ELSE 0 END) qreturns,
               MAX(ISNULL(sbm.promo_id, '')) promo_id
        FROM inv_master i
            INNER JOIN inv_master_add ia
                ON ia.part_no = i.part_no
            INNER JOIN cvo_sbm_details sbm
                ON i.part_no = sbm.part_no
        WHERE (
              yyyymmdd
              BETWEEN @DateFromLY AND @DateToLY
              OR yyyymmdd
              BETWEEN @datefrom AND @dateto
              )
              -- where yyyymmdd between '01/01/2014' and '03/31/2015'
              -- and return_code in ( '', 'WTY')
              AND i.type_code IN ( 'frame', 'sun', 'parts' )
        GROUP BY RIGHT(customer, 5),
                 ship_to,
                 i.category,
                 CASE WHEN ia.category_2 LIKE '%child%' THEN 'Kids' ELSE 'Adult' END,
                 i.type_code,
                 CASE WHEN LEFT(sbm.user_category, 2) = 'rx' THEN 'RX' ELSE 'ST' END,
                 CASE WHEN yyyymmdd >= @datefrom THEN 'TY' ELSE 'LY' END
        -- , case when yyyymmdd >= '01/01/2015' then 'TY' else 'LY' end 
        ) sbm
            ON sbm.customer = RIGHT(ar.customer_code, 5)
               AND sbm.ship_to = ar.ship_to_code;

    -- select * from #netsales where customer_code like '%41407' 

    INSERT #netsales
    SELECT territory_code,
           customer_code,
           ship_to_code,
           'ST',
           'TY',
           brand,
           demographic,
           itemtype,
           0,
           0,
           0,
           0,
           ''
    FROM(
    (
    SELECT DISTINCT
           territory_code,
           RIGHT(customer_code, 5) customer_code,
           ship_to_code
    FROM #netsales
    ) c
        CROSS JOIN
        (SELECT DISTINCT brand, demographic, itemtype FROM #netsales) b );

    -- select * from #netsales where customer_code like '%41407' -- and item_code in ('!','!LENS','M') order by item_code

    -- IF(OBJECT_ID('tempdb.dbo.#SSRS_Territory_Planner') is not null) drop table dbo.#SSRS_Territory_Planner

    CREATE INDEX ns_idx ON #netsales (customer_code ASC, ship_to_code ASC);
    CREATE INDEX ci_idx ON #custinfo (customer_code ASC, ship_to_code ASC);


    -- Customer /Ship To ONly Sales
    SELECT ISNULL(custstat.status_type,'A') Status,
           ISNULL(rnk.rank, 9999) rank,
           ci.territory_code,
           ci.door,
           ci.customer_code,
           ci.ship_to_code,
           ISNULL(ns_summ.column_group, '') column_group,
           ISNULL(ns_summ.column_label, '') column_label,
           ISNULL(ns_summ.cg_special, '') cg_special,
           ISNULL(ns_summ.cl_special, '') cl_special,
           ISNULL(ns_summ.anet_TY, 0) anet_ty,
           ISNULL(ns_summ.anet_LY, 0) anet_ly,
           ISNULL(ns_summ.areturns_TY, 0) areturns_ty,
           ISNULL(ns_summ.RX_TY, 0) rx_ty,
           ci.address_name,
           ci.addr2,
           ci.city,
           ci.state,
           ci.postal_code,
           ci.contact_phone,
           ci.tlx_twx,
           ci.contact_email,
           ci.contact_name,
           ci.oldeststorddate,
           ci.m_address,
           ci.m_addr2,
           ci.m_city,
           ci.m_state,
           ci.m_postal_code,
           ci.m_contact_phone,
           ci.m_tlx_twx,
           ci.m_contact_email,
           ci.m_contact_name,
           ci.m_oldeststorddate,
           ci.m_door,
           ISNULL(active_ty.active, 0) active,
           ISNULL(active_ly.active, 0) active_ly,
           ISNULL(ns_ty, 0) ns_ty,
           ISNULL(ns_summ.promo_flg, '') promo_flg
    FROM #custinfo ci
        -- left outer join #netsales ns on ns.Customer_code=ci.Customer_code and ns.ship_to_code=ci.ship_to_code
        LEFT OUTER JOIN
        (
        SELECT territory_code,
               customer_code,
               ship_to_code,
               rank = RANK() OVER (PARTITION BY territory_code ORDER BY SUM(anet) DESC)
        FROM #netsales
        GROUP BY territory_code,
                 customer_code,
                 ship_to_code
        ) rnk
            ON rnk.customer_code = ci.customer_code
               AND rnk.ship_to_code = ci.ship_to_code
        LEFT OUTER JOIN
        (
        SELECT ns.customer_code,
               ns.ship_to_code,
               -- 10/28/15 - remove CH, add REVO
               column_group = CASE WHEN ISNULL(ns.brand, '') IN ( 'as', 'bcbg', 'et', 'me', 'revo' ) THEN '1 Premium'
                              WHEN ISNULL(ns.brand, '') IN ( 'dd', 'fp', 'di', 'ko', 'rr', 'un', 'ch' ) THEN '' ELSE
                                                                                                                    '2 Core'
                              END,
               column_label = CASE WHEN ISNULL(ns.brand, '') NOT IN ( 'ch', 'dd', 'fp', 'di', 'ko' ) THEN
ISNULL(ns.brand, '') ELSE '' END,
               cg_special = CASE WHEN ISNULL(ns.itemtype, '') = 'SUN' THEN '4 Suns'
                            WHEN ISNULL(ns.demographic, '') = 'Kids' THEN '3 Kids' ELSE ''
                            END,
               cl_special = CASE WHEN ISNULL(ns.itemtype, '') = 'SUN' THEN 'Suns'
                            WHEN ISNULL(ns.brand, '') IN ( 'dd', 'fp' ) THEN 'Pediatric'
                            WHEN ISNULL(ns.demographic, '') = 'Kids' THEN 'Kids' ELSE ''
                            END,
               SUM(CASE WHEN ns.TYLY = 'ty' THEN ns.anet ELSE 0 END) anet_TY,
               SUM(CASE WHEN ns.TYLY = 'ly' THEN ns.anet ELSE 0 END) anet_LY,
               SUM(CASE WHEN ns.TYLY = 'ty' THEN ns.areturns ELSE 0 END) areturns_TY,
               SUM(CASE WHEN ns.TYLY = 'ty' AND ns.ordertype = 'rx' THEN ns.anet ELSE 0 END) RX_TY,
               ns.promo_flg promo_flg
        FROM #netsales ns
        GROUP BY CASE WHEN ISNULL(ns.brand, '') IN ( 'as', 'bcbg', 'et', 'me', 'revo' ) THEN '1 Premium'
                 WHEN ISNULL(ns.brand, '') IN ( 'dd', 'fp', 'di', 'ko', 'rr', 'un', 'ch' ) THEN '' ELSE '2 Core'
                 END,
                 CASE WHEN ISNULL(ns.brand, '') NOT IN ( 'ch', 'dd', 'fp', 'di', 'ko' ) THEN ISNULL(ns.brand, '') ELSE
'' END  ,
                 CASE WHEN ISNULL(ns.itemtype, '') = 'SUN' THEN '4 Suns'
                 WHEN ISNULL(ns.demographic, '') = 'Kids' THEN '3 Kids' ELSE ''
                 END,
                 CASE WHEN ISNULL(ns.itemtype, '') = 'SUN' THEN 'Suns'
                 WHEN ISNULL(ns.brand, '') IN ( 'dd', 'fp' ) THEN 'Pediatric'
                 WHEN ISNULL(ns.demographic, '') = 'Kids' THEN 'Kids' ELSE ''
                 END,
                 ns.customer_code,
                 ns.ship_to_code,
                 ns.promo_flg
        ) ns_summ
            ON ns_summ.customer_code = ci.customer_code
               AND ns_summ.ship_to_code = ci.ship_to_code
        LEFT OUTER JOIN
        (
        SELECT ns.customer_code,
               1 AS active
        FROM #netsales ns
        WHERE ns.TYLY = 'ty'
        GROUP BY ns.customer_code
        HAVING SUM(anet) >= 2400
        ) active_ty
            ON active_ty.customer_code = ci.customer_code
        LEFT OUTER JOIN
        (
        SELECT ns.customer_code,
               1 AS active
        FROM #netsales ns
        WHERE ns.TYLY = 'ly'
        GROUP BY ns.customer_code
        HAVING SUM(anet) >= 2400
        ) active_ly
            ON active_ly.customer_code = ci.customer_code
        LEFT OUTER JOIN
        (
        SELECT ns.customer_code,
               SUM(anet) ns_ty
        FROM #netsales ns
        WHERE ns.TYLY = 'ty'
        GROUP BY ns.customer_code
        ) ns_ty
            ON ns_ty.customer_code = ci.customer_code
		-- 071818 - tag - use the real customer status for report 
		LEFT OUTER JOIN
		(
		SELECT distinct RIGHT(customer_code,5) customer_code, ship_to_code, CASE WHEN status_Type = 1 THEN 'A' ELSE 'I' END AS status_type
		FROM armaster ar (nolock))	custstat ON custstat.customer_code = ci.customer_code AND custstat.ship_to_code = ci.ship_to_code
		;

END;



GO
