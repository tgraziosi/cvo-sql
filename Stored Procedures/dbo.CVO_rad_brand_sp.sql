SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tine Graziosi - CVO
-- Create date: 11/27/2012
-- Description:	Rolling Active Doors by Ship-to, Month/Year
-- update - added st and rx sales breakdown
-- update - 2/15/2013 - add sales returns fields
-- update - 06/10/2013 - fix duplicate records due to yyyymmdd grouping
-- update - 10/29/2013 - per EL, assign territory to the Door's account
-- update - 11/21/2013 - shift lookback months by one to fix r12 figures
-- =============================================
-- exec [dbo].[CVO_rad_brand_sp]
-- select * from cvo.dbo.cvo_rad_brand order by customer, ship_to, yyyymmdd
-- select * from cvo_rad_brand where door = 0
-- select sum(netsales) from cvo_sbm_details c
--inner join armaster ar on c.customer_code = ar.customer_code and c.ship_to_code = ar.ship_to_code
--and c.territory_code = ar.territory_code
-- select 
--customer, ship_to, 
--sum(netsales) from cvo_rad_brand where territory = 20201 and year = 2013 group by customer, ship_to
--select customer, c.ship_to, door, sum(anet) from cvo_sbm_details c
--inner join armaster ar (nolock) on c.customer = ar.customer_code and c.ship_to = ar.ship_to_code
--inner join cvo_armaster_all ca (nolock) on c.customer = ca.customer_code and c.ship_to = ca.ship_to
--where territory_code = 20201 and year = 2013 group by c.customer, c.ship_to, door

--select customer_code, ship_to_code, territory_code from armaster 
--where customer_code in ('028230','030774')
-- select * From tempdb.dbo.#rad

-- select sum(areturns), sum(aret_rx), sum(aret_st), sum(aret_rx)+sum(aret_st) from cvo_rad_brand

-- exec cvo_rad_brand_sp
-- select * from cvo_rad_brand where [year] = 2012 and territory is null
/*

 select distinct yyyymmdd From cvo_rad_brand  order by yyyymmdd
  select * From #rad_det where customer_code like '%11012' order by yyyymmdd
  
   select sum(asales), sum(areturns), sum(asales_rx), sum(asales_st) from cvo_rad_brand
  --select distinct x_month, year, yyyymmdd from cvo_rad_brand order by yyyymmdd
  select  sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_customer_sales_by_month

  --where customer = '010098'
  select right(customer,5) customer, sum(asales), sum(areturns), sum(asales_rx), sum(asales_st), s
  
  select * From cvo_rad_brand where customer like '%11012%'
and yyyymmdd between '1/1/2012' and '1/31/2013' 
order by yyyymmdd
*/

CREATE PROCEDURE [dbo].[CVO_rad_brand_sp]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    IF (OBJECT_ID('tempdb.dbo.#rad_det') IS NOT NULL)
        DROP TABLE #rad_det;

    CREATE TABLE #rad_det
    -- add brand for brand r12 analysis
    (
        brand VARCHAR(10),
        territory_code VARCHAR(10),
        customer_code VARCHAR(10),
        ship_to_code VARCHAR(10),
        door INT,
        x_month INT,
        year INT,
        netsales FLOAT,
        asales FLOAT,
        asales_rx FLOAT,
        asales_st FLOAT,
        areturns FLOAT,
        aret_rx FLOAT,
        aret_st FLOAT,
                     -- new 02/2013
        areturns_s FLOAT,
        aret_rx_s FLOAT,
        aret_st_s FLOAT,
        qsales INT,
        qsales_rx INT,
        qsales_st INT,
        qreturns INT,
        qret_rx INT,
        qret_st INT,
        qnet_frames INT,
        qnet_parts INT,
        qnet_cl INT, -- closeout sales
        anet_cl FLOAT
    );

    IF (OBJECT_ID('tempdb.dbo.#rad') IS NOT NULL)
        DROP TABLE #rad;

    CREATE TABLE #rad
    (
        brand VARCHAR(10),
        territory_code VARCHAR(10),
        customer_code VARCHAR(10),
        ship_to_code VARCHAR(10),
        door INT,
        date_opened DATETIME,
        x_month INT,
        year INT,
        yyyymmdd DATETIME,
        netsales FLOAT,
        asales FLOAT,
        asales_rx FLOAT,
        asales_st FLOAT,
        areturns FLOAT,
        aret_rx FLOAT,
        aret_st FLOAT,
        -- new 02/2013
        areturns_s FLOAT,
        aret_rx_s FLOAT,
        aret_st_s FLOAT,
        -- new 11/25/2013
        qsales INT,
        qsales_rx INT,
        qsales_st INT,
        qreturns INT,
        qret_rx INT,
        qret_st INT,
        qnet_frames INT,
        qnet_parts INT,
        qnet_cl INT,
        anet_cl FLOAT,
        rolling12net FLOAT,
        rolling12rx FLOAT,
        rolling12st FLOAT,
        rolling12ret FLOAT,
        -- new 02/13
        rolling12ret_s FLOAT,
        rolling12RR FLOAT,
        IsActiveDoor INT
            DEFAULT 1,
        IsNew INT
            DEFAULT 0,
        rolling12qnet INT,
        rolling12qrx INT,
        rolling12qst INT,
        rolling12qret INT,
        -- new 02/13
        rolling12qret_s INT
    );

    -- set up the sales data so that every customer/month/year combo exists.

    DECLARE @yy INT;
    DECLARE @mm INT;

    SET @yy = 2008;
    SET @mm = 1;

    WHILE @yy <= DATEPART(yy, GETDATE())
    BEGIN
        WHILE @mm < 13
        BEGIN
            INSERT INTO #rad_det
            (
                brand,
                territory_code,
                customer_code,
                ship_to_code,
                door,
                x_month,
                year,
                netsales,
                asales,
                asales_rx,
                asales_st,
                areturns,
                aret_rx,
                aret_st,
                areturns_s,
                aret_rx_s,
                aret_st_s,
                qsales,
                qsales_rx,
                qsales_st,
                qreturns,
                qret_rx,
                qret_st,
                qnet_frames,
                qnet_parts,
                qnet_cl,
                anet_cl
            )
            SELECT ISNULL(i.category, '') brand,
                   ar.territory_code,
                   CASE WHEN LEFT(ar.customer_code, 1) = '9' THEN '0' + RIGHT(LTRIM(RTRIM(ar.customer_code)), 5)ELSE
                                                                                                                    ar.customer_code
                   END AS customer_code,
                   -- collapse non-door ship-to's into the main customer
                   CASE WHEN ISNULL(ca.door, 0) = 0 AND ca.ship_to <> '' THEN '' ELSE ca.ship_to END AS ship_to,
                   CASE WHEN ISNULL(ca.door, 0) = 0 AND ca.ship_to <> '' THEN 1 ELSE ca.door END AS door,
                   --
                   @mm,
                   @yy,
                   ISNULL(anet, 0) AS netsales,
                   ISNULL(asales, 0) AS asales,
                   CASE WHEN ISNULL(xx.user_category, 'ST') LIKE 'RX%' THEN ISNULL(asales, 0) ELSE 0 END AS asales_rx,
                   CASE WHEN ISNULL(xx.user_category, 'ST') NOT LIKE 'RX%' THEN ISNULL(asales, 0) ELSE 0 END AS asales_st,
                   --isnull(asales_st, 0) as asales_st,
                   --isnull(asales_rx, 0) as asales_rx,
                   ISNULL(areturns, 0) AS areturns,
                   CASE WHEN ISNULL(xx.user_category, 'ST') LIKE 'RX%' THEN ISNULL(areturns, 0) ELSE 0 END AS aret_rx,
                   CASE WHEN ISNULL(xx.user_category, 'ST') NOT LIKE 'rx%' THEN ISNULL(areturns, 0) ELSE 0 END AS aret_st,
                   --isnull(aret_rx, 0) as aret_rx,
                   --isnull(aret_st, 0) as aret_st,
                   -- new 0213
                   CASE WHEN ISNULL(xx.return_code, '') = '' THEN ISNULL(areturns, 0) ELSE 0 END AS areturns_s,
                   CASE WHEN ISNULL(xx.return_code, '') = ''
                             AND ISNULL(xx.user_category, 'st') LIKE 'rx%' THEN ISNULL(areturns, 0) ELSE 0
                   END AS aret_rx_s,
                   CASE WHEN ISNULL(xx.return_code, '') = ''
                             AND ISNULL(xx.user_category, 'st') NOT LIKE 'rx%' THEN ISNULL(areturns, 0) ELSE 0
                   END AS aret_st_s,
                   --isnull(aret_rx_s, 0) as aret_rx_s,
                   --isnull(aret_st_s, 0) as aret_st_s
                   ISNULL(qsales, 0) AS qsales,
                   CASE WHEN ISNULL(xx.user_category, 'ST') LIKE 'RX%' THEN ISNULL(qsales, 0) ELSE 0 END AS qsales_rx,
                   CASE WHEN ISNULL(xx.user_category, 'ST') NOT LIKE 'RX%' THEN ISNULL(qsales, 0) ELSE 0 END AS qsales_st,
                   CASE WHEN ISNULL(xx.return_code, '') = '' THEN ISNULL(qreturns, 0) ELSE 0 END AS qreturns,
                   CASE WHEN ISNULL(xx.return_code, '') = ''
                             AND ISNULL(xx.user_category, 'st') LIKE 'rx%' THEN ISNULL(qreturns, 0) ELSE 0
                   END AS qret_rx,
                   CASE WHEN ISNULL(xx.return_code, '') = ''
                             AND ISNULL(xx.user_category, 'st') NOT LIKE 'rx%' THEN ISNULL(qreturns, 0) ELSE 0
                   END AS qret_st,
                   CASE WHEN i.type_code IN ( 'frame', 'sun' ) THEN qnet ELSE 0 END AS qnet_frames,
                   CASE WHEN i.type_code IN ( 'parts' ) THEN qnet ELSE 0 END AS qnet_parts,
                   CASE WHEN xx.user_category LIKE '%cl' THEN qnet ELSE 0 END AS qnet_cl,
                   CASE WHEN xx.user_category LIKE '%cl' THEN anet ELSE 0 END AS anet_cl
            FROM CVO_armaster_all ca (NOLOCK)
                INNER JOIN armaster ar (NOLOCK)
                    ON ar.customer_code = ca.customer_code
                       AND ar.ship_to_code = ca.ship_to
                LEFT OUTER JOIN cvo_sbm_details xx (NOLOCK)
                    ON xx.customer = ca.customer_code
                       AND xx.ship_to = ca.ship_to
                LEFT OUTER JOIN inv_master i (NOLOCK)
                    ON i.part_no = xx.part_no
            WHERE xx.X_MONTH = @mm
                  AND xx.year = @yy
                  AND i.type_code IN ( 'frame', 'sun', 'parts' );

            SET @mm = @mm + 1;
            IF @mm > DATEPART(mm, GETDATE())
               AND @yy = DATEPART(yy, GETDATE())
                BREAK;
            ELSE
                CONTINUE;
        END;
        SET @yy = @yy + 1;
        SET @mm = 1;
    END;

    CREATE INDEX idx_rad_det
    ON #rad_det
    (
    brand,
    territory_code,
    customer_code,
    ship_to_code
    )
    INCLUDE (netsales);

    -- summarize

    INSERT INTO #rad
    (
        brand,
        territory_code,
        customer_code,
        ship_to_code,
        door,
        date_opened,
        x_month,
        year,
        yyyymmdd,
        netsales,
        asales,
        asales_rx,
        asales_st,
        areturns,
        aret_rx,
        aret_st,
        areturns_s,
        aret_rx_s,
        aret_st_s,
        qsales,
        qsales_rx,
        qsales_st,
        qreturns,
        qret_rx,
        qret_st,
        qnet_frames,
        qnet_parts,
        qnet_cl,
        anet_cl
    )
    SELECT rd.brand,
           ar.territory_code,
           rd.customer_code,
           rd.ship_to_code,
           rd.door,
           -- getdate() as date_opened,
           '1/1/1900' AS date_opened,
           rd.x_month,
           rd.year,
           CAST((CAST(rd.x_month AS VARCHAR(2)) + '/01/' + CAST(rd.year AS VARCHAR(4))) AS DATETIME) AS yyyymmdd,
           SUM(netsales) AS netsales,
           SUM(asales) AS asales,
           SUM(asales_rx) AS asales_rx,
           SUM(asales_st) AS asales_st,
           SUM(areturns) AS areturns,
           SUM(aret_rx) AS aret_rx,
           SUM(aret_st) AS aret_st,
           SUM(areturns_s) AS areturns_s,
           SUM(aret_rx_s) AS aret_rx_s,
           SUM(aret_st_s) AS aret_st_s,
           SUM(qsales) AS qsales,
           SUM(qsales_rx) AS qsales_rx,
           SUM(qsales_st) AS qsales_st,
           SUM(qreturns) AS qreturns,
           SUM(qret_rx) AS qret_rx,
           SUM(qret_st) AS qret_st,
           SUM(qnet_frames) qnet_frames,
           SUM(qnet_parts) qnet_parts,
           SUM(qnet_cl) qnet_cl,
           SUM(anet_cl) anet_cl
    FROM #rad_det rd (NOLOCK)
        INNER JOIN armaster ar (NOLOCK)
            ON ar.customer_code = rd.customer_code
               AND ar.ship_to_code = rd.ship_to_code
    GROUP BY rd.brand,
             ar.territory_code,
             rd.customer_code,
             rd.ship_to_code,
             rd.door,
             x_month,
             year;

    --select cast ((cast(6 as varchar(2))+'/01/'+cast(2013 as varchar(4))) as datetime)
    -- update each customer/month/year record with the rolling 12 months net sales 

    -- select * from #rad where customer_code = '040388' and x_month=11 and year=2011
    -- select * From cvo_rad_brand where customer = '040388' and x_month=11 and year=2011

    CREATE INDEX idx_rad
    ON #rad
    (
    brand,
    territory_code,
    customer_code,
    ship_to_code,
    yyyymmdd
    )
    INCLUDE (netsales);


    UPDATE rad
    SET rolling12net =
        (
        SELECT SUM(ISNULL(rad12.netsales, 0))
        FROM #rad rad12 (NOLOCK)
        WHERE rad.customer_code = rad12.customer_code
              AND rad.ship_to_code = rad12.ship_to_code
              AND rad.territory_code = rad12.territory_code
              AND rad.brand = rad12.brand
              AND rad12.yyyymmdd
              BETWEEN DATEADD(mm, -11, rad.yyyymmdd) AND rad.yyyymmdd
        ),
        rolling12rx =
        (
        SELECT SUM(ISNULL(rad12.asales_rx, 0))
        FROM #rad rad12 (NOLOCK)
        WHERE rad.customer_code = rad12.customer_code
              AND rad.ship_to_code = rad12.ship_to_code
              AND rad.territory_code = rad12.territory_code
              AND rad.brand = rad12.brand
              AND rad12.yyyymmdd
              BETWEEN DATEADD(mm, -11, rad.yyyymmdd) AND rad.yyyymmdd
        ),
        rolling12st =
        (
        SELECT SUM(ISNULL(rad12.asales_st, 0))
        FROM #rad rad12 (NOLOCK)
        WHERE rad.customer_code = rad12.customer_code
              AND rad.ship_to_code = rad12.ship_to_code
              AND rad.territory_code = rad12.territory_code
              AND rad.brand = rad12.brand
              AND rad12.yyyymmdd
              BETWEEN DATEADD(mm, -11, rad.yyyymmdd) AND rad.yyyymmdd
        ),
        rolling12ret =
        (
        SELECT SUM(ISNULL(rad12.areturns, 0))
        FROM #rad rad12 (NOLOCK)
        WHERE rad.customer_code = rad12.customer_code
              AND rad.ship_to_code = rad12.ship_to_code
              AND rad.territory_code = rad12.territory_code
              AND rad.brand = rad12.brand
              AND rad12.yyyymmdd
              BETWEEN DATEADD(mm, -11, rad.yyyymmdd) AND rad.yyyymmdd
        ),
        rolling12ret_s =
        (
        SELECT SUM(ISNULL(rad12.areturns_s, 0))
        FROM #rad rad12 (NOLOCK)
        WHERE rad.customer_code = rad12.customer_code
              AND rad.ship_to_code = rad12.ship_to_code
              AND rad.territory_code = rad12.territory_code
              AND rad.brand = rad12.brand
              AND rad12.yyyymmdd
              BETWEEN DATEADD(mm, -11, rad.yyyymmdd) AND rad.yyyymmdd
        )
    FROM #rad rad;



    UPDATE rad
    SET rad.rolling12RR = CASE rad.rolling12net
                          WHEN 0 THEN CASE rad.rolling12ret_s WHEN 0 THEN 0 ELSE 1 END ELSE
                                                                                           rad.rolling12ret_s
                                                                                           / rad.rolling12net
                          END
    FROM #rad rad;

    --sum(isnull((case a.x_month when 1 then a.anet end), 0)) as jan,

    -- set the active door flag based on the minimum sales $
    -- at brand level active threshold is $250

    UPDATE #rad
    SET IsActiveDoor = 0
    --where rad.rolling12net >= 2400.00
    WHERE #rad.rolling12net < 250.00; --2400.00

    -- select * from #rad where date_opened = '1/1/1900'

    -- fill in date opened for ship-to's 

    UPDATE #rad
    SET date_opened = rr.date_opened
    FROM #rad
        INNER JOIN
        (
        SELECT r.customer_code,
               r.brand,
               MIN(ISNULL(yyyymmdd, '1/1/1950')) date_opened
        FROM cvo_sbm_details c (NOLOCK)
            INNER JOIN inv_master i (NOLOCK)
                ON i.part_no = c.part_no
            INNER JOIN
            (SELECT DISTINCT customer_code, brand FROM #rad) r
                ON c.customer = r.customer_code
                   AND r.brand = i.category
        WHERE c.user_category LIKE 'ST%'
        GROUP BY r.customer_code,
                 r.brand
        ) AS rr
            ON #rad.customer_code = rr.customer_code
               AND #rad.brand = rr.brand;

    --update rad set
    -- rad.date_opened = 
    --  convert(datetime,dateadd(d,
    --	isnull(ar.date_opened,dbo.adm_get_pltdate_f(ar.added_by_date))-711858,'1/1/1950'))
    --from 
    --#rad rad inner join armaster ar (nolock) on rad.customer_code = ar.customer_code
    --where address_type = 0 

    UPDATE #rad
    SET IsNew = 1
    WHERE MONTH(#rad.yyyymmdd) = MONTH(#rad.date_opened)
          AND YEAR(#rad.yyyymmdd) = YEAR(#rad.date_opened);


    -- select * from #rad where customer_code = '040388' and x_month=11 and year=2011

    --update rad set rad.territory_code = isnull(ar.territory_code,'')
    --from 
    --#rad rad inner join armaster ar (nolock) on rad.customer_code = ar.customer_code
    --and rad.ship_to_code = ar.ship_to_code
    --where rad.territory_code <> ar.territory_code

    -- where rad.date_opened is null

    -- select * from cvo_rad_brand where customer = '011111' and ship_to = '' order by yyyymmdd

    -- Create summary table by month

    --update armaster set date_opened = dbo.adm_get_pltdate_f(added_by_date) where date_opened = 0

    IF (OBJECT_ID('cvo.dbo.cvo_rad_brand') IS NOT NULL)
        DROP TABLE CVO.dbo.cvo_rad_brand;

    IF (OBJECT_ID('cvo.dbo.cvo_rad_brand') IS NULL)
    BEGIN
        CREATE TABLE dbo.cvo_rad_brand
        (
            brand VARCHAR(10),
            territory VARCHAR(10),
            customer VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
            ship_to VARCHAR(10),
            door INT,
            date_opened DATETIME,
            X_MONTH INT NULL,
            year INT NULL,
            yyyymmdd DATETIME,
            netsales FLOAT,
            asales FLOAT,
            asales_rx FLOAT,
            asales_st FLOAT,
            areturns FLOAT,
            aret_rx FLOAT,
            aret_st FLOAT,
            areturns_s FLOAT,
            aret_rx_s FLOAT,
            aret_st_s FLOAT,
            rolling12net FLOAT,
            rolling12rx FLOAT,
            rolling12st FLOAT,
            rolling12ret FLOAT,
            rolling12ret_s FLOAT,
            Rolling12RR FLOAT,
            IsActiveDoor INT,
            IsNew INT,
            qsales INT,
            qsales_rx INT,
            qsales_st INT,
            qreturns INT,
            qret_rx INT,
            qret_st INT,
            qnet_frames INT,
            qnet_parts INT,
            qnet_cl INT,
            anet_cl FLOAT
        ) ON [PRIMARY];

        GRANT SELECT ON dbo.cvo_rad_brand TO [public];

        CREATE NONCLUSTERED INDEX idx_cvo_rad_brand
        ON dbo.cvo_rad_brand
        (
        brand ASC,
        territory ASC,
        customer ASC,
        ship_to ASC,
        X_MONTH ASC,
        year ASC,
        yyyymmdd ASC
        )
        WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)
        ON [PRIMARY];
    END;

    /****** Object:  Index [idx_yyyymmdd_rad]    Script Date: 11/22/2013 15:27:28 ******/
    IF EXISTS
    (
    SELECT *
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[dbo].[cvo_rad_brand]')
          AND name = N'idx_yyyymmdd_rad'
    )
        DROP INDEX idx_yyyymmdd_rad_brand
        ON dbo.cvo_rad_brand
        WITH
        (   ONLINE = OFF);

    /****** Object:  Index [idx_yyyymmdd_rad]    Script Date: 11/22/2013 15:27:29 ******/
    CREATE NONCLUSTERED INDEX idx_yyyymmdd_rad
    ON dbo.cvo_rad_brand (yyyymmdd ASC)
    WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF,
          DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
         )
    ON [PRIMARY];


    INSERT cvo_rad_brand
    (
        brand,
        territory,
        customer,
        ship_to,
        door,
        date_opened,
        X_MONTH,
        year,
        yyyymmdd,
        netsales,
        asales,
        asales_rx,
        asales_st,
        areturns,
        aret_rx,
        aret_st,
        areturns_s,
        aret_rx_s,
        aret_st_s,
        rolling12net,
        rolling12rx,
        rolling12st,
        rolling12ret,
        rolling12ret_s,
        Rolling12RR,
        IsActiveDoor,
        IsNew,
        qsales,
        qsales_rx,
        qsales_st,
        qreturns,
        qret_rx,
        qret_st,
        qnet_frames,
        qnet_parts,
        qnet_cl,
        anet_cl
    )
    SELECT brand,
           territory_code,
           customer_code,
           ship_to_code,
           door,
           date_opened,
           x_month,
           year,
           yyyymmdd,
           netsales,
           asales,
           asales_rx,
           asales_st,
           areturns,
           aret_rx,
           aret_st,
           areturns_s,
           aret_rx_s,
           aret_st_s,
           ISNULL(rolling12net, 0),
           ISNULL(rolling12rx, 0),
           ISNULL(rolling12st, 0),
           ISNULL(rolling12ret, 0),
           ISNULL(rolling12ret_s, 0),
           ISNULL(rolling12RR, 0),
           IsActiveDoor,
           IsNew,
           qsales,
           qsales_rx,
           qsales_st,
           qreturns,
           qret_rx,
           qret_st,
           qnet_frames,
           qnet_parts,
           qnet_cl,
           anet_cl
    FROM #rad;

END;

GO
GRANT EXECUTE ON  [dbo].[CVO_rad_brand_sp] TO [public]
GO
