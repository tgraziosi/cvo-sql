SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		tgraziosi
-- Create date: 1/20/2015
-- Description:	Sun Presell 5 Yr Tracker
-- exec SSRS_SunPreSell_v2_sp
-- switch to date ordered and summarize by level
-- 111017 - update programs for 2018 season
-- 110618 - tweeks for 2019 season
-- 12/2018 - revamp 
-- =============================================

CREATE PROCEDURE [dbo].[cvo_sunps_tracker_sp]
    @asofdate DATETIME = NULL,
    @sdate DATETIME = NULL,
    @edate DATETIME = NULL,
    @debug INT = 0
AS
BEGIN

    -- exec cvo_sunps_tracker_sp '11/06/2018', '11/1/2018', '10/31/2019', 0

    -- EXEC dbo.SSRS_SunPreSell_v2_sp '11/06/2018', '11/1/2018', '10/31/2019', 0

    SET NOCOUNT ON;

    IF @sdate IS NULL
        SET @sdate = '11/1/2018';
    IF @edate IS NULL
        SET @edate = '10/31/2019';

    IF @asofdate IS NULL
        SET @asofdate = @sdate;

    -- SUN PRESELL 6 year Customer Tracker
    DECLARE @P1From DATETIME,
            @P1To DATETIME,
            @P2From DATETIME,
            @P2To DATETIME,
            @P3From DATETIME,
            @P3To DATETIME,
            @P4From DATETIME,
            @P4To DATETIME,
            @P5From DATETIME,
            @P5To DATETIME,
            @P6From DATETIME,
            @P6To DATETIME;

    -- Orders Entered
    SET @P1From = @sdate;
   
    SET @P1To = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @edate));

    -- Invoices Shipped
    SET @P2From = DATEADD(YEAR, -1, @P1From);
    SET @P2To = DATEADD(YEAR, -1, @P1To);
    SET @P3From = DATEADD(YEAR, -2, @P1From);
    SET @P3To = DATEADD(YEAR, -2, @P1To);
    SET @P4From = DATEADD(YEAR, -3, @P1From);
    SET @P4To = DATEADD(YEAR, -3, @P1To);
    SET @P5From = DATEADD(YEAR, -4, @P1From);
    SET @P5To = DATEADD(YEAR, -4, @P1To);
    SET @P6From = DATEADD(YEAR, -5, @P1From);
    SET @P6To = DATEADD(YEAR, -5, @P1To);

    -- -- --  select * from inv_master
    -- -- --

    ;WITH sunps AS
    (
    SELECT cust_code,
           o.ship_to,
           o.type,
           o.order_no,
           CAST(invoice_no AS VARCHAR(15)) invoice_no,
           date_entered,
           date_shipped,
           UPPER(promo_id) promo_id,
           promo_level,
           SUM(ordered) OrdQty,
           SUM(shipped) ShipQty,
           SUM(cr_shipped) CRQty,
           CASE
               WHEN type = 'I' THEN
                   1
               ELSE
                   -1
           END AS Cnt,
           period = CASE
                        WHEN o.date_entered
                             BETWEEN @P2From AND @P2To THEN
                            DATEPART(YEAR, @P2To)
                        WHEN o.date_entered
                             BETWEEN @P3From AND @P3To THEN
                            DATEPART(YEAR, @P3To)
                        WHEN o.date_entered
                             BETWEEN @P4From AND @P4To THEN
                            DATEPART(YEAR, @P4To)
                        WHEN o.date_entered
                             BETWEEN @P5From AND @P5To THEN
                            DATEPART(YEAR, @P5To)
                        WHEN o.date_entered
                             BETWEEN @P6From AND @P6To THEN
                            DATEPART(YEAR, @P6To)
                        ELSE
                            0
                    END
    FROM orders_all (NOLOCK) o
        JOIN ord_list (NOLOCK) ol
            ON o.order_no = ol.order_no
               AND o.ext = ol.order_ext
        JOIN CVO_orders_all (NOLOCK) co
            ON o.order_no = co.order_no
               AND o.ext = co.ext
        JOIN inv_master (NOLOCK) i
            ON ol.part_no = i.part_no
    WHERE o.status <> 'v'
          -- AND promo_id  LIKE '%SUNPS%'
          AND promo_id IN ( 'sunps', 'op', 'selldown' )
          AND promo_level IN ( '1', '2', '3', 'sun', 'suns1', 'suns2' )


          -- AND co.promo_level IN ('1','2','3') -- 11/3/2016
          -- and (o.ext=0 OR (o.ext>0 and o.who_entered='OutOfStock'))
          AND o.who_entered <> 'backordr'
          AND o.date_entered
          BETWEEN @P6From AND @P2To
          AND i.type_code IN ( 'frame', 'sun' )
          -- and right(o.user_category,2) not in ('rb','tb')
          AND NOT EXISTS
    (
        SELECT 1
        FROM cvo_promo_override_audit poa
        WHERE poa.order_no = o.order_no
              AND poa.order_ext = o.ext
    )
    GROUP BY cust_code,
             o.ship_to,
             o.type,
             o.order_no,
             invoice_no,
             date_entered,
             date_shipped,
             promo_id,
             promo_level

    -- Current Year Orders
    UNION ALL
    SELECT cust_code,
           o.ship_to,
           type,
           o.order_no,
           CAST(invoice_no AS VARCHAR(12)),
           date_entered,
           date_shipped,
           UPPER(promo_id) promo_id,
           promo_level,
           SUM(ordered) OrdQty,
           SUM(shipped) ShipQty,
           SUM(cr_shipped) CRQty,
           CASE
               WHEN type = 'I' THEN
                   1
               ELSE
                   -1
           END AS Cnt,
           period = DATEPART(YEAR, @edate)
    FROM dbo.orders_all (NOLOCK) o
        JOIN dbo.ord_list (NOLOCK) ol
            ON o.order_no = ol.order_no
               AND o.ext = ol.order_ext
        JOIN dbo.CVO_orders_all (NOLOCK) co
            ON o.order_no = co.order_no
               AND o.ext = co.ext
        JOIN dbo.inv_master (NOLOCK) i
            ON ol.part_no = i.part_no
    WHERE o.status <> 'v'
          -- AND promo_id LIKE '%SUNPS%'
          AND co.promo_id IN ( 'sunps', 'op', 'selldown' )
          AND co.promo_level IN ( '1', '2', '3', 'sun', 'suns1', 'suns2' )
          -- and (o.ext='0' OR (o.ext>0 and o.who_entered='OutOfStock'))
          AND o.who_entered <> 'backordr'
          AND o.date_entered
          BETWEEN @P1From AND @P1To
          AND i.type_code IN ( 'sun', 'frame' )
          -- and right(o.user_category,2) not in ('rb','tb')
          AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.cvo_promo_override_audit poa
        WHERE poa.order_no = o.order_no
              AND poa.order_ext = o.ext
    )
    GROUP BY o.cust_code,
             o.ship_to,
             o.type,
             o.order_no,
             o.invoice_no,
             o.date_entered,
             o.date_shipped,
             co.promo_id,
             co.promo_level
             
   -- get the pricing renewal only customers and fill-in order info if found (1/11/2019)
    UNION ALL
    
        SELECT CDC.customer_code,
           '' ship_to,
           '' type,
           '' order_no,
           'PRICE RENEWL',
           cdc.start_date,
           cdc.start_date,
           cdc.code promo_id,
           cdc.code PROMO_LEVEL,
           0 OrdQty,
           0 ShipQty,
           0 CRQty,
           1 Cnt,
           period = DATEPART(YEAR, @edate)
    FROM dbo.cvo_cust_designation_codes AS cdc
    WHERE cdc.code LIKE 'sun19%'
          AND cdc.start_date >= @sdate

    --SELECT DISTINCT CDC.customer_code,
    --       ISNULL(ord.ship_to,'') ship_to,
    --       ISNULL(ord.type,'') type,
    --       ISNULL(ord.order_no,'') order_no,
    --       ISNULL(ord.invoice_no,'PRICE RENEWL') invoice_no,
    --       ISNULL(ord.date_entered,cdc.start_date) date_entered,
    --       ISNULL(ord.date_shipped,cdc.start_date) date_shipped,
    --       cdc.code promo_id,
    --       ISNULL(ord.promo_level,cdc.code) PROMO_LEVEL,
    --       ISNULL(ord.OrdQty,0) OrdQty,
    --       ISNULL(ord.ShipQty,0) ShipQty,
    --       ISNULL(ord.CRQty,0) CRQty,
    --       ISNULL(ord.Cnt,1) Cnt,
    --       period = DATEPART(YEAR, @edate)
    --FROM dbo.cvo_cust_designation_codes AS cdc
    --LEFT OUTER JOIN
    --(
    --SELECT cust_code,
    --       o.ship_to,
    --       type,
    --       o.order_no,
    --       CAST(invoice_no AS VARCHAR(12)) invoice_no,
    --       date_entered,
    --       date_shipped,
    --       UPPER(promo_id) promo_id,
    --       promo_level,
    --       SUM(ordered) OrdQty,
    --       SUM(shipped) ShipQty,
    --       SUM(cr_shipped) CRQty,
    --       CASE
    --           WHEN type = 'I' THEN
    --               1
    --           ELSE
    --               -1
    --       END AS Cnt,
    --       period = DATEPART(YEAR, @edate)
    --FROM dbo.orders_all (NOLOCK) o
    --    JOIN dbo.ord_list (NOLOCK) ol
    --        ON o.order_no = ol.order_no
    --           AND o.ext = ol.order_ext
    --    JOIN dbo.CVO_orders_all (NOLOCK) co
    --        ON o.order_no = co.order_no
    --           AND o.ext = co.ext
    --    JOIN dbo.inv_master (NOLOCK) i
    --        ON ol.part_no = i.part_no
    --WHERE o.status <> 'v'
    --      -- AND promo_id LIKE '%SUNPS%'
    --      AND co.promo_id IN ( 'sunps' ) AND co.promo_level IN ( 'renew1')
    --      -- and (o.ext='0' OR (o.ext>0 and o.who_entered='OutOfStock'))
    --      AND o.who_entered <> 'backordr'
    --      AND o.date_entered
    --      BETWEEN @P1From AND @P1To
    --      AND i.type_code IN ( 'sun', 'frame' )
    --      -- and right(o.user_category,2) not in ('rb','tb')
    --      AND NOT EXISTS
    --(
    --    SELECT 1
    --    FROM dbo.cvo_promo_override_audit poa
    --    WHERE poa.order_no = o.order_no
    --          AND poa.order_ext = o.ext
    --)
    --GROUP BY o.cust_code,
    --         o.ship_to,
    --         o.type,
    --         o.order_no,
    --         o.invoice_no,
    --         o.date_entered,
    --         o.date_shipped,
    --         co.promo_id,
    --         co.promo_level
    --) ord ON ord.cust_code = cdc.customer_code

    --WHERE cdc.code LIKE 'sun19%'
    --      AND cdc.start_date >= @sdate

)

-- SELECT * FROM sunps


    -- Final Select

    SELECT CASE
               WHEN ar.status_type = '1' THEN
                   'Act'
               WHEN ar.status_type = '2' THEN
                   'Inact'
               ELSE
                   'NoNewBus'
           END status,
           ar.territory_code AS Terr,
           ar.customer_code,
           ar.ship_to_code,
           CASE
               WHEN summ.Promo_level = 'SUN' THEN
                   'OP'
               ELSE
                   summ.Promo_level
           END PROMO_level, -- 11/16/2017
           ar.address_name,
           ar.addr2,
           CASE
               WHEN ar.addr3 LIKE '%, __ %' THEN
                   ''
               ELSE
                   ar.addr3
           END AS addr3,
           ar.city,
           ar.state,
           ar.postal_code,
           ar.country_code,
           ar.contact_phone,
           ar.tlx_twx,
           CASE
               WHEN ar.contact_email IS NULL
                    OR ar.contact_email LIKE '%@CVOPTICAL.COM'
                    OR ar.contact_email = 'REFUSED' THEN
                   ''
               ELSE
                   LOWER(ar.contact_email)
           END AS contact_email,
           summ.period,
           CASE
               WHEN summ.Inv_cnt < 0 THEN
                   0
               ELSE
                   summ.Inv_cnt
           END AS Inv_cnt,
           CASE
               WHEN summ.Inv_cnt < 0 THEN
                   0
               ELSE
                   summ.Inv_qty
           END AS Inv_qty
    FROM
    (
        SELECT cust_code,
               CASE
                   WHEN car.door = 0 THEN
                       ''
                   ELSE
                       s.ship_to
               END AS ship_to,
               s.Promo_level,
               s.period,
               SUM(ISNULL(s.Cnt, 0)) Inv_cnt,
               SUM(ISNULL(s.OrdQty, 0) - ISNULL(s.CRQty, 0)) Inv_qty
        FROM sunps s
            INNER JOIN dbo.CVO_armaster_all car (NOLOCK)
                ON car.customer_code = s.cust_code
                   AND car.ship_to = s.ship_to
        WHERE s.period <> 0
        GROUP BY s.cust_code,
                 CASE
                     WHEN car.door = 0 THEN
                         ''
                     ELSE
                         s.ship_to
                 END,
                 s.Promo_level,
                 s.period
        HAVING SUM(ISNULL(Cnt, 0)) >= 0
    ) AS summ
        INNER JOIN dbo.armaster ar (NOLOCK)
            ON ar.customer_code = summ.cust_code
               AND ar.ship_to_code = summ.ship_to
    WHERE (Inv_qty <> 0
          AND Inv_cnt <> 0)
          OR summ.promo_level LIKE 'sun19%'
          
    ;


END;











GO
GRANT EXECUTE ON  [dbo].[cvo_sunps_tracker_sp] TO [public]
GO
