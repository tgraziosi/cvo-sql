SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		tgraziosi
-- Create date: 1/03/2019
-- Description:	Sun Presell ytd Tracker
-- 
-- switch to date ordered and summarize by level
-- 111017 - update programs for 2018 season
-- 110618 - tweeks for 2019 season
-- 12/2018 - revamp 
-- 01/2019 - use static hs info for orders and dates for 2018 season to track ytd more closely
-- =============================================

CREATE PROCEDURE [dbo].[cvo_sunps_tracker_ytd_sp]
    @asofdate DATETIME = NULL,
    @sdate DATETIME = NULL,
    @edate DATETIME = NULL,
    @debug INT = 0
AS
BEGIN

    -- exec cvo_sunps_tracker_ytd_sp '01/03/2019', '11/1/2018'

    SET NOCOUNT ON;

    IF @sdate IS NULL
        SET @sdate = '11/1/2018';
    IF @edate IS NULL
        SET @edate = DATEADD(dd, DATEDIFF(dd, 0,GETDATE()), 0);

    IF @asofdate IS NULL
        SET @asofdate = @sdate;

    -- SUN PRESELL 6 year Customer Tracker
    DECLARE @P1From DATETIME,
            @P1To DATETIME,
            @P2From DATETIME,
            @P2To DATETIME;

    -- Orders Entered
    SET @P1From = @sdate;

    SET @P1To = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @edate));

    -- Invoices Shipped
    SET @P2From = DATEADD(YEAR, -1, @P1From);
    SET @P2To = DATEADD(YEAR, -1, @P1To);

    -- -- --  select * from inv_master
    -- -- --

    ;
    WITH hs_sunps_2018
    AS (SELECT DISTINCT
               hosv.order_no,
               hs.hs_order_no,
               hs.order_date,
               hosv.cust_code,
               hosv.ship_to
        FROM cvo_sunps_2018_hs hs
            LEFT OUTER JOIN dbo.hs_order_status_vw AS hosv
                ON hosv.HS_order_no = hs.hs_order_no
            LEFT OUTER JOIN orders o
                ON o.order_no = hosv.order_no
                   AND o.who_entered <> 'backordr'
        WHERE hosv.status <> 'v'),

         sunps
    AS (SELECT o.cust_code,
               o.ship_to,
               o.type,
               o.order_no,
               CAST(invoice_no AS VARCHAR(15)) invoice_no,
               hs_sunps_2018.order_date date_entered,
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
               period = 2018,
                       (
            SELECT TOP(1) 1
            FROM dbo.cvo_promo_override_audit poa
            WHERE poa.order_no = o.order_no
                  AND poa.order_ext = o.ext
        ) AS qual

        FROM hs_sunps_2018
            JOIN orders_all (NOLOCK) o
                ON o.order_no = hs_sunps_2018.order_no
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
              AND o.who_entered <> 'backordr'
              AND hs_sunps_2018.order_date <= @P2To
              AND i.type_code IN ( 'frame', 'sun' )

        GROUP BY o.cust_code,
                 o.ship_to,
                 o.type,
                 o.order_no, o.ext,
                 invoice_no,
                 hs_sunps_2018.order_date,
                 date_shipped,
                 promo_id,
                 promo_level
        UNION ALL
        -- full 2018 orders
        SELECT o.cust_code,
               o.ship_to,
               o.type,
               o.order_no,
               CAST(invoice_no AS VARCHAR(15)) invoice_no,
               hs_sunps_2018.order_date date_entered,
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
               period = 0,
                       (
            SELECT TOP(1) 1
            FROM dbo.cvo_promo_override_audit poa
            WHERE poa.order_no = o.order_no
                  AND poa.order_ext = o.ext
        ) AS qual
        FROM hs_sunps_2018
            JOIN orders_all (NOLOCK) o
                ON o.order_no = hs_sunps_2018.order_no
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
              AND o.who_entered <> 'backordr'
              AND i.type_code IN ( 'frame', 'sun' )
        GROUP BY o.cust_code,
                 o.ship_to,
                 o.type,
                 o.order_no, o.ext,
                 invoice_no,
                 hs_sunps_2018.order_date,
                 date_shipped,
                 promo_id,
                 promo_level

        -- Current Year Open Orders
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
               2019 AS period,
        (
            SELECT TOP(1) 1
            FROM dbo.cvo_promo_override_audit poa
            WHERE poa.order_no = o.order_no
                  AND poa.order_ext = o.ext
        ) AS qual

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
              AND o.who_entered <> 'backordr'
              AND o.date_entered
              BETWEEN @P1From AND @P1To
              AND i.type_code IN ( 'sun', 'frame' )

        GROUP BY o.cust_code,
                 o.ship_to,
                 o.type,
                 o.order_no, o.ext, 
                 o.invoice_no,
                 o.date_entered,
                 o.date_shipped,
                 co.promo_id,
                 co.promo_level

        -- get the pricing renewal only customers
        UNION ALL
        SELECT cdc.customer_code,
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
               period = 2019,
               0 AS qual
        FROM dbo.cvo_cust_designation_codes AS cdc
        WHERE cdc.code LIKE 'sun19%'
              AND cdc.start_date >= @sdate
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
           slp.salesperson_name slp,
           ar.customer_code,
           ar.ship_to_code,
           CASE
               WHEN summ.promo_level = 'SUN' THEN
                   'OP'
               ELSE
                   summ.promo_level
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
           END AS Inv_qty,
           CASE WHEN summ.qual IS NULL OR summ.qual = 0 THEN 'Yes' ELSE 'No' END Qual_order
    FROM
    (
        SELECT cust_code,
               CASE
                   WHEN car.door = 0 THEN
                       ''
                   ELSE
                       s.ship_to
               END AS ship_to,
               s.promo_level,
               s.period,
               SUM(ISNULL(s.Cnt, 0)) Inv_cnt,
               SUM(ISNULL(s.OrdQty, 0) - ISNULL(s.CRQty, 0)) Inv_qty,
               s.qual
        FROM sunps s
            INNER JOIN dbo.CVO_armaster_all car (NOLOCK)
                ON car.customer_code = s.cust_code
                   AND car.ship_to = s.ship_to
        WHERE 1=1 -- s.period <> 0
        GROUP BY s.cust_code,
                 CASE
                     WHEN car.door = 0 THEN
                         ''
                     ELSE
                         s.ship_to
                 END,
                 s.promo_level,
                 s.period,
                 s.qual
        HAVING SUM(ISNULL(Cnt, 0)) >= 0
    ) AS summ
        INNER JOIN dbo.armaster ar (NOLOCK)
            ON ar.customer_code = summ.cust_code
               AND ar.ship_to_code = summ.ship_to
               JOIN arsalesp slp ON slp.salesperson_code = ar.salesperson_code
    WHERE (
              Inv_qty <> 0
              AND Inv_cnt <> 0
          )
          OR summ.promo_level LIKE 'sun19%';

          
END;











GO
GRANT EXECUTE ON  [dbo].[cvo_sunps_tracker_ytd_sp] TO [public]
GO
