SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 7/1/2013
-- Description:	NEW Ranking Customer Door
-- EXEC RankCustDoor_sp '1/1/2015','11/30/2015','TRUE',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
-- EXEC RankCustDoor_terr_sp '1/1/2015','11/30/2015',null, null, 'TRUE'
-- EXEC RankCustDoor_sp '1/1/2013','6/30/2013','TRUE','IZOD','IZX',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
-- EXEC RankCustDoor_sp '1/1/2013','6/30/2013','TRUE'  -- This ONE
-- EXEC RankCustDoor_sp '7/1/2012','6/30/2013','TRUE','IZX','IZOD',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
-- =============================================


-- CUSTOMER RANKING
-------- CREATED BY *Elizabeth LaBarbera*  7/1/2013
-- updated 11/20/2014 - add multi-value lists for territory and collection

CREATE PROCEDURE [dbo].[RankCustDoor_terr_sp]
    @DateFrom DATETIME,
    @DateTo DATETIME,
    @Territory VARCHAR(1000) = NULL,
    @collection VARCHAR(1000) = NULL,
    @sf VARCHAR(5) = 'TRUE'
--,
--@col1 varchar(5) = NULL,
--@col2 varchar(5) = NULL,
--@col3 varchar(5) = NULL,
--@col4 varchar(5) = NULL,
--@col5 varchar(5) = NULL,
--@col6 varchar(5) = NULL,
--@col7 varchar(5) = NULL,
--@col8 varchar(5) = NULL,
--@col9 varchar(5) = NULL,
--@col10 varchar(5) = NULL


AS
BEGIN
    SET NOCOUNT ON;


    ----  DECLARES
    --DECLARE @DateFrom datetime                                    
    --DECLARE @DateTo datetime		
    DECLARE @DateFromLY DATETIME;
    DECLARE @DateToLY DATETIME;
    --DECLARE @sf  varchar(100)
    --DECLARE @col1 varchar(100)
    --DECLARE @col2 varchar(100)
    --DECLARE @col3 varchar(100)
    --DECLARE @col4 varchar(100)
    --DECLARE @col5 varchar(100)
    --DECLARE @col6 varchar(100)
    --DECLARE @col7 varchar(100)
    --DECLARE @col8 varchar(100)
    --DECLARE @col9 varchar(100)
    --DECLARE @col10 varchar(100)

    ----  SETS
    --SET @DateFrom = '7/1/2012'
    --SET @DateTo = '6/30/2013'
    SET @DateTo = DATEADD(DAY, 1, (DATEADD(SECOND, -1, @DateTo)));
    SET @DateFromLY = DATEADD(YEAR, -1, @DateFrom);
    SET @DateToLY = DATEADD(YEAR, -1, @DateTo);
    --SET @SF = 'TRUE' -- 'SF'
    --SET @col1 = NULL
    --SET @col2 = NULL
    --SET @col3 = NULL
    --SET @col4 = NULL
    --SET @col5 = NULL
    --SET @col6 = NULL
    --SET @col7 = NULL
    --SET @col8 = NULL
    --SET @col9 = NULL
    --SET @col10 = NULL
    --  select @dateFrom, @dateto, @datefromly, @datetoly, @Col1, @col2, @col3, @col4, @col5, @col6, @col7, @col8, @col9, @col10

    CREATE TABLE #territory
    (
        territory VARCHAR(10)
    );
    IF @Territory IS NULL
    BEGIN
        INSERT INTO #territory
        (
            territory
        )
        SELECT DISTINCT
               territory_code
        FROM armaster;
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

    CREATE TABLE #collection
    (
        collection VARCHAR(10)
    );

    IF ISNULL(@collection, '*ALL*') = '*ALL*'
    BEGIN
        INSERT INTO #collection
        (
            collection
        )
        SELECT DISTINCT
               kys
        FROM category;
    END;
    ELSE
    BEGIN
        INSERT INTO #collection
        (
            collection
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
    -- Select * from #Rank_Aff  

    -- Pull Customer INFO
    IF (OBJECT_ID('tempdb.dbo.#RankCusts_S1') IS NOT NULL)
        DROP TABLE dbo.#RankCusts_S1;
    SELECT CASE WHEN T2.door = 1 THEN 'Y' ELSE '' END AS Door,
           t1.customer_code,
           ship_to_code,
           territory_code AS Terr,
           address_name,
           addr2,
CASE WHEN addr3 LIKE '%, __ %' THEN '' ELSE addr3 END AS addr3,
CASE WHEN addr4 LIKE '%, __ %' THEN '' ELSE addr4 END AS addr4,
           city,
           state,
           postal_code,
           country_code,
           contact_name,
           contact_phone,
           tlx_twx,
CASE WHEN contact_email IS NULL THEN '' WHEN contact_email LIKE '%@cvoptical%' THEN '' ELSE contact_email END AS contact_email,
           addr_sort1 AS CustType
    INTO #RankCusts_S1
    FROM armaster t1 (NOLOCK)
        INNER JOIN #territory t
            ON t.territory = t1.territory_code
        LEFT OUTER JOIN CVO_armaster_all T2
            ON t1.customer_code = T2.customer_code
               AND t1.ship_to_code = T2.ship_to
    WHERE t1.address_type <> 9;
    -- select * from #RankCusts_S1

    -- Get Designation Codes, into one field  (Where Designations date range is in report date range
    IF (OBJECT_ID('tempdb.dbo.#RankCusts_S2A') IS NOT NULL)
        DROP TABLE dbo.#RankCusts_S2A;
    WITH C
    AS
    (
    SELECT customer_code,
           code
    FROM cvo_cust_designation_codes (NOLOCK)
    )
    SELECT DISTINCT
           customer_code,
           STUFF(
           (
           SELECT '; ' + code
           FROM cvo_cust_designation_codes (NOLOCK)
           WHERE customer_code = C.customer_code
                 AND
                 (
                 start_date IS NULL
                 OR start_date <= @DateTo
                 )
                 AND
                 (
                 end_date IS NULL
                 OR end_date >= @DateTo
                 )
           FOR XML PATH('')
           ),
           1,
           1,
           ''
                ) AS NEW
    INTO #RankCusts_s2A
    FROM C;

    -- Get Primary for each Customer
    IF (OBJECT_ID('tempdb.dbo.#Primary') IS NOT NULL)
        DROP TABLE dbo.#Primary;
    SELECT customer_code,
           code,
           start_date,
           end_date
    INTO #Primary
    FROM cvo_cust_designation_codes (NOLOCK)
    WHERE primary_flag = 1;
    -- select * from #Primary

    -- Add Designation & Primary to Customer Data
    IF (OBJECT_ID('tempdb.dbo.#RankCusts_S2B') IS NOT NULL)
        DROP TABLE dbo.#RankCusts_S2B;
    SELECT t1.*,
           ISNULL(t2.NEW, '') AS Designations,
           ISNULL(t3.code, '') AS PriDesig
    INTO #RankCusts_S2B
    FROM #RankCusts_S1 t1
        LEFT OUTER JOIN #RankCusts_s2A t2
            ON t1.customer_code = t2.customer_code
        LEFT OUTER JOIN #Primary t3
            ON t1.customer_code = t3.customer_code;
    --select * from #RankCusts_S2B

    --Add ReClassify for Affiliation 
    IF (OBJECT_ID('tempdb.dbo.#Rank_Aff_All') IS NOT NULL)
        DROP TABLE dbo.#Rank_Aff_All;
    SELECT X.*
    INTO #Rank_Aff_All
    FROM
    (
    SELECT from_cust AS CUST,
           'I' AS Code
    FROM #Rank_Aff
    UNION
    SELECT to_cust AS CUST,
           'A' Code
    FROM #Rank_Aff
    ) X;
    --SELECT * FROM #Rank_Aff_All 

    -- Add 0/9 Statu to Customer Data
    IF (OBJECT_ID('tempdb.dbo.#RankCusts_S3a') IS NOT NULL)
        DROP TABLE dbo.#RankCusts_S3a;
    SELECT ISNULL(   t2.Code,
           (
           SELECT CASE WHEN status_type = 1 THEN 'A' ELSE 'I' END
           FROM armaster (NOLOCK) t11
           WHERE t1.customer_code = t11.customer_code
                 AND t1.ship_to_code = t11.ship_to_code
           )
                 ) Status,
           RIGHT(customer_code, 5) AS MergeCust,
           t1.*
    INTO #RankCusts_S3a
    FROM #RankCusts_S2B t1
        FULL OUTER JOIN #Rank_Aff_All t2
            ON t1.customer_code = t2.CUST;
    -- select * from #RankCusts_S3a

    -- add in Parent &/or BG
    IF (OBJECT_ID('tempdb.dbo.#RankCusts_S3c') IS NOT NULL)
        DROP TABLE dbo.#RankCusts_S3c;
    SELECT t1.*,
           CASE WHEN t1.customer_code = t2.parent THEN '' ELSE t2.parent END AS Parent
    INTO #RankCusts_S3c
    FROM #RankCusts_S3a t1
        RIGHT OUTER JOIN artierrl (NOLOCK) t2
            ON t1.customer_code = t2.rel_cust
    WHERE t1.customer_code IS NOT NULL;
    -- select * from #RankCusts_S3c 

    -- CLEAN OUT EXTRA DUPLICATE 0 & 9
    IF (OBJECT_ID('tempdb.dbo.#RankCusts_S3') IS NOT NULL)
        DROP TABLE dbo.#RankCusts_S3;
    SELECT MIN(ISNULL(Status, '')) Status,
           MergeCust,
           MIN(ISNULL(Door, '')) Door,
           MIN(ISNULL(customer_code, '')) customer_code,
           ship_to_code,
           MIN(ISNULL(Terr, '')) terr,
           MIN(ISNULL(address_name, '')) Address_name,
           MIN(ISNULL(addr2, '')) addr2,
           MIN(ISNULL(addr3, '')) addr3,
           MIN(ISNULL(addr4, '')) addr4,
           MIN(ISNULL(city, '')) City,
           MIN(ISNULL(state, '')) State,
           MIN(ISNULL(postal_code, '')) Postal_code,
           MIN(ISNULL(country_code, '')) Country,
           MIN(ISNULL(contact_name, '')) contact_name,
           MIN(ISNULL(contact_phone, '')) contact_phone,
           MIN(ISNULL(tlx_twx, '')) tlx_twx,
           MIN(ISNULL(contact_email, '')) contact_email,
           MIN(ISNULL(Designations, '')) Designations,
           MIN(ISNULL(PriDesig, '')) PriDesig,
           MIN(ISNULL(Parent, '')) Parent,
           MIN(ISNULL(CustType, '')) CustType
    INTO #RankCusts_S3
    FROM #RankCusts_S3c
    GROUP BY MergeCust,
             ship_to_code
    ORDER BY MergeCust;
    -- select * from #RankCusts_S3

    -- SOURCE SALES
    IF (OBJECT_ID('tempdb.dbo.#SOURCE') IS NOT NULL)
        DROP TABLE dbo.#SOURCE;
    SELECT RIGHT(customer, 5) MergeCust,
           t2.*,
           CASE WHEN yyyymmdd BETWEEN @DateFrom AND @DateTo THEN 'TY' ELSE 'LY' END AS 'TYLY'
    INTO #SOURCE
    FROM cvo_sbm_details (NOLOCK) t2
        JOIN inv_master (NOLOCK) INV
            ON t2.part_no = INV.part_no
        INNER JOIN #collection c
            ON c.collection = INV.category
    WHERE (
          yyyymmdd
          BETWEEN @DateFrom AND @DateTo
          OR yyyymmdd
          BETWEEN @DateFromLY AND @DateToLY
          )
          AND
          (
          (
          @sf = 'TRUE'
          AND type_code LIKE ('%')
          )
          OR
          (
          @sf = 'SUN'
          AND type_code = ('SUN')
          )
          OR
          (
          @sf = 'FRAME'
          AND type_code = ('FRAME')
          )
          OR
          (
          @sf = 'SF'
          AND type_code IN ( 'SUN', 'FRAME' )
          )
          );
    --	AND ( (@col1 is null and category like '%') OR ( @col1 is not null and ( category = @col1 OR category = @col2 
    --OR category = @col3 OR category = @col4 OR category = @col5 OR category = @col6 OR category = @col7 OR category = @col8 OR category = @col9 OR category = @col10 ) ) )
    -- SELECT distinct customer, ship_to,TYLY, user_category, promo_id, return_code, sum(anet)NET FROM #SOURCE where Customer like '%18739' and yyyymmdd between '7/1/2012' and '6/30/2013' group by customer, ship_to,TYLY, user_category, promo_id, return_code
    -- SELECT sum(anet) FROM #SOURCE where Customer like '%18739' and TYLY = 'TY'

    -- DATA
    IF (OBJECT_ID('tempdb.dbo.#Data') IS NOT NULL)
        DROP TABLE dbo.#data;
    SELECT Status,
           t1.MergeCust AS Customer,
           ship_to_code AS ShipTo,
           terr,
           Door,
           Address_name,
           addr2,
           addr3,
           addr4,
           City,
           State,
           Postal_code,
           Country,
           contact_name,
           contact_phone,
           tlx_twx,
           contact_email,
           -- SALES
           CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(anet), 0) ELSE 0 END AS NetSTY,
           CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(anet), 0) ELSE 0 END AS NetSLY,
           CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(anet), 0) ELSE 0 END AS NetSRXTY,
           CASE WHEN TYLY <> 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(anet), 0) ELSE 0 END AS NetSRXLY,
           CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(anet), 0) ELSE 0 END AS NetSSTTY,
           CASE WHEN TYLY <> 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(anet), 0) ELSE 0 END AS NetSSTLY,
           CASE WHEN TYLY = 'TY' THEN -1 * ISNULL(SUM(areturns), 0) ELSE 0 END AS RetSTY,
           CASE WHEN TYLY <> 'TY' THEN -1 * ISNULL(SUM(areturns), 0) ELSE 0 END AS RetSLY,
           CASE WHEN TYLY = 'TY' AND return_code <> 'EXC' THEN -1 * ISNULL(SUM(areturns), 0) ELSE 0 END AS RetSRaTY,
           CASE WHEN TYLY <> 'TY' AND return_code <> 'EXC' THEN -1 * ISNULL(SUM(areturns), 0) ELSE 0 END AS RetSRaLY,
           CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN -1 * ISNULL(SUM(areturns), 0) ELSE 0 END AS RetSRXTY,
           CASE WHEN TYLY <> 'TY' AND user_category LIKE 'RX%' THEN -1 * ISNULL(SUM(areturns), 0) ELSE 0 END AS RetSRXLY,
           CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN -1 * ISNULL(SUM(areturns), 0) ELSE 0 END AS RetSSTTY,
           CASE WHEN TYLY <> 'TY' AND user_category NOT LIKE 'RX%' THEN -1 * ISNULL(SUM(areturns), 0) ELSE 0 END AS RetSSTLY,
           CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(asales), 0) ELSE 0 END AS GrossSTY,
           CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(asales), 0) ELSE 0 END AS GrossSLY,
           CASE WHEN TYLY = 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(asales), 0) ELSE 0 END AS GrossNoBepSTY,
           CASE WHEN TYLY <> 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(asales), 0) ELSE 0 END AS GrossNoBepSLY,
           -- UNITS
           CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(qnet), 0) ELSE 0 END AS NetUTY,
           CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(qnet), 0) ELSE 0 END AS NetULY,
           CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(qnet), 0) ELSE 0 END AS NetURXTY,
           CASE WHEN TYLY <> 'TY' AND user_category LIKE 'RX%' THEN ISNULL(SUM(qnet), 0) ELSE 0 END AS NetURXLY,
           CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(qnet), 0) ELSE 0 END AS NetUSTTY,
           CASE WHEN TYLY <> 'TY' AND user_category NOT LIKE 'RX%' THEN ISNULL(SUM(qnet), 0) ELSE 0 END AS NetUSTLY,
           CASE WHEN TYLY = 'TY' THEN -1 * ISNULL(SUM(qreturns), 0) ELSE 0 END AS RetUTY,
           CASE WHEN TYLY <> 'TY' THEN -1 * ISNULL(SUM(qreturns), 0) ELSE 0 END AS RetULY,
           CASE WHEN TYLY = 'TY' AND return_code <> 'EXC' THEN -1 * ISNULL(SUM(qreturns), 0) ELSE 0 END AS RetURaTY,
           CASE WHEN TYLY <> 'TY' AND return_code <> 'EXC' THEN -1 * ISNULL(SUM(qreturns), 0) ELSE 0 END AS RetURaLY,
           CASE WHEN TYLY = 'TY' AND user_category LIKE 'RX%' THEN -1 * ISNULL(SUM(qreturns), 0) ELSE 0 END AS RetURXTY,
           CASE WHEN TYLY <> 'TY' AND user_category LIKE 'RX%' THEN -1 * ISNULL(SUM(qreturns), 0) ELSE 0 END AS RetURXLY,
           CASE WHEN TYLY = 'TY' AND user_category NOT LIKE 'RX%' THEN -1 * ISNULL(SUM(qreturns), 0) ELSE 0 END AS RetUSTTY,
           CASE WHEN TYLY <> 'TY' AND user_category NOT LIKE 'RX%' THEN -1 * ISNULL(SUM(qreturns), 0) ELSE 0 END AS RetUSTLY,
           CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(qsales), 0) ELSE 0 END AS GrossUTY,
           CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(qsales), 0) ELSE 0 END AS GrossULY,
           CASE WHEN TYLY = 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(qsales), 0) ELSE 0 END AS GrossNoBepUTY,
           CASE WHEN TYLY <> 'TY' AND promo_id <> 'BEP' THEN ISNULL(SUM(qsales), 0) ELSE 0 END AS GrossNoBepULY,
           --
           ISNULL(Designations, '') ActiveDesignation,
           ISNULL(PriDesig, '') CurrentPrimary,
           ISNULL(Parent, '') PARENT,
           ISNULL(CustType, '') CustType
    INTO #DATA
    FROM #RankCusts_S3 t1
        LEFT OUTER JOIN #SOURCE t2
            ON t1.MergeCust = t2.MergeCust
               AND t1.ship_to_code = t2.ship_to
    GROUP BY Status,
             t1.MergeCust,
             ship_to_code,
             terr,
             Door,
             Address_name,
             addr2,
             addr3,
             addr4,
             City,
             State,
             Postal_code,
             Country,
             contact_name,
             contact_phone,
             tlx_twx,
             contact_email,
             Designations,
             PriDesig,
             PARENT,
             CustType,
             TYLY,
             user_category,
             promo_id,
             return_code;
    -- select * from #Data where Customer='18739' AND NETsTY <>0
    -- select * from #Data

    -- FINAL SELECT
    SELECT Status,
           Customer,
           ShipTo,
           terr,
           Door,
           Address_name,
           addr2,
           addr3,
           addr4,
           City,
           State,
           Postal_code,
           Country,
           contact_name,
           contact_phone,
           tlx_twx,
           contact_email,
           -- SALES
           CASE WHEN Door = 'y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetSTY), 0)
           WHEN Door <> 'y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetSTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetSTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetSTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetSLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetSLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetSLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetSLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetSRXTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetSRXTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetSRXTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetSRXTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetSRXLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetSRXLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetSRXLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetSRXLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetSSTTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetSSTTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetSSTTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetSSTTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetSSTLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetSSTLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetSSTLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetSSTLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetSTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetSTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetSTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetSTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetSLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetSLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetSLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetSLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetSRaTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetSRaTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetSRaTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetSRaTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetSRaLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetSRaLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetSRaLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetSRaLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetSRXTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetSRXTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetSRXTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetSRXTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetSRXLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetSRXLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetSRXLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetSRXLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetSSTTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetSSTTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetSSTTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetSSTTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetSSTLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetSSTLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetSSTLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetSSTLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(GrossSTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(GrossSTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(GrossSTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'GrossSTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(GrossSLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(GrossSLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(GrossSLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'GrossSLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(GrossNoBepSTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(GrossNoBepSTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(GrossNoBepSTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'GrossNoBepSTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(GrossNoBepSLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(GrossNoBepSLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(GrossNoBepSLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'GrossNoBepSLY',

           -- UNITS
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetUTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetUTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetUTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetUTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetULY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetULY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetULY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetULY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetURXTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetURXTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetURXTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetURXTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetURXLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetURXLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetURXLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetURXLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetUSTTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetUSTTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetUSTTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetUSTTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(NetUSTLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(NetUSTLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(NetUSTLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'NetUSTLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetUTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetUTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetUTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetUTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetULY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetULY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetULY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetULY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetURaTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetURaTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetURaTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetURaTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetURaLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetURaLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetURaLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetURaLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetURXTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetURXTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetURXTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetURXTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetURXLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetURXLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetURXLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetURXLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetUSTTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetUSTTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetUSTTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetUSTTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(RetUSTLY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(RetUSTLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(RetUSTLY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'RetUSTLY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(GrossUTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(GrossUTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(GrossUTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'GrossUTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(GrossULY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(GrossULY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(GrossULY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'GrossULY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(GrossNoBepUTY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(GrossNoBepUTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(GrossNoBepUTY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'GrossNoBepUTY',
           CASE WHEN Door = 'Y'
                     AND ShipTo <> '' THEN ISNULL(SUM(GrossNoBepULY), 0)
           WHEN Door <> 'Y'
                AND ShipTo <> '' THEN 0 ELSE (
           (
           SELECT ISNULL(SUM(GrossNoBepULY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door = 'Y'
                 AND T11.ShipTo = ''
           ) +
           (
           SELECT ISNULL(SUM(GrossNoBepULY), 0)
           FROM #DATA T11
           WHERE t1.Customer = T11.Customer
                 AND T11.Door <> 'Y'
                 AND T11.ShipTo <> ''
           )
                                             )
           END AS 'GrossNoBepULY',


           --ISNULL((select sum(asales) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and promo_id <> 'BEP'),0) GrossSNoBep_R12,
           --(-1*ISNULL((select sum(areturns) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and return_code <> 'EXC'),0)) RetSRa_R12,

           --ISNULL((select sum(Qsales) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and promo_id <> 'BEP'),0) GrossUNoBep_R12,
           --(-1*ISNULL((select sum(Qreturns) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and return_code <> 'EXC'),0)) RetURa_R12,

           ActiveDesignation,
           CurrentPrimary,
           RTRIM(LTRIM(PARENT)) Parent,
           CustType
    FROM #DATA T1
    WHERE Door = 'Y'
    GROUP BY Status,
             Customer,
             ShipTo,
             terr,
             Door,
             Address_name,
             addr2,
             addr3,
             addr4,
             City,
             State,
             Postal_code,
             Country,
             contact_name,
             contact_phone,
             tlx_twx,
             contact_email,
             ActiveDesignation,
             CurrentPrimary,
             Parent,
             CustType
    ORDER BY terr,
             SUM(NetSTY) DESC;
-- EXEC RankCustDoor_terr_sp '11/1/2014','11/30/2014','20201'

END;



GO
GRANT EXECUTE ON  [dbo].[RankCustDoor_terr_sp] TO [public]
GO
