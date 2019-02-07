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

    -- exec cvo_sunps_tracker_ytd_sp '01/30/2019', '11/1/2018', '02/28/2019'

    --    DECLARE @asofdate DATETIME,
    --@sdate DATETIME ,
    --@edate DATETIME ,
    --@debug INT ;

    SET NOCOUNT ON;

    IF @sdate IS NULL
        SET @sdate = '11/1/2018';
    IF @edate IS NULL
        SET @edate = '2/28/2019';

    IF @asofdate IS NULL
        SET @asofdate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);

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
    -- SELECT @p1from, @p1to, @p2from, @P2To

    ;
    WITH hs_sunps_2018
    AS (SELECT DISTINCT
               hosv.order_no,
               hs.hs_order_no,
               hs.order_date,
               hosv.cust_code,
               hosv.ship_to,
               'I' type
        FROM cvo_sunps_2018_hs hs
            LEFT OUTER JOIN dbo.hs_order_status_vw AS hosv
                ON hosv.HS_order_no = hs.hs_order_no
            LEFT OUTER JOIN orders o
                ON o.order_no = hosv.order_no
                   AND o.who_entered <> 'backordr'
        WHERE hosv.status <> 'v'
              AND hs.order_date
              BETWEEN @P2From AND @P2To
              AND NOT EXISTS
        (
            SELECT 1
            FROM orders oo (NOLOCK)
                JOIN CVO_orders_all coo (NOLOCK)
                    ON coo.order_no = oo.order_no
                       AND coo.ext = oo.ext
            WHERE oo.type = 'c'
                  AND oo.status = 't'
                  AND oo.cust_po = o.cust_po
                  AND oo.date_entered > o.date_entered
                  AND oo.cust_code = o.cust_code
                  AND oo.ship_to = o.ship_to
                  AND NOT EXISTS
            (
                SELECT 1
                FROM ord_list ool (NOLOCK)
                WHERE ool.order_no = oo.order_no
                      AND ool.order_ext = oo.ext
                      AND ool.return_code LIKE '05-24%'
            )
        )),
         terrsales
    AS (SELECT arr.territory_code,
               arr.salesperson_code,
               SUM(   CASE
                          WHEN yyyymmdd >= @P1From THEN
                              anet
                          ELSE
                              0
                      END
                  ) ty_netsales,
               SUM(   CASE
                          WHEN yyyymmdd < @P2To THEN
                              anet
                          ELSE
                              0
                      END
                  ) ly_netsales
        FROM cvo_sbm_details sbm (NOLOCK)
            JOIN armaster arr (NOLOCK)
                ON arr.customer_code = sbm.customer
                   AND arr.ship_to_code = sbm.ship_to
        WHERE yyyymmdd
        BETWEEN @P2From AND @P1To
        GROUP BY arr.territory_code,
                 arr.salesperson_code),
         sunps
    AS (SELECT o.cust_code,
               o.ship_to,
               o.type,
               o.order_no,
               CAST(invoice_no AS VARCHAR(15)) invoice_no,
               hs_sunps_2018.order_date date_entered,
               o.date_shipped,
               UPPER(co.promo_id) promo_id,
               co.promo_level,
               SUM(   CASE
                          WHEN o.who_entered <> 'BACKORDR' THEN
                              ol.ordered
                          ELSE
                              0
                      END
                  ) OrdQty,
               SUM(ol.shipped) ShipQty,
               SUM(ol.cr_shipped) CRQty,
               CASE
                   WHEN o.type = 'I' THEN
                       1
                   ELSE
                       -1
               END AS Cnt,
               period = 2018,
               ISNULL(
               (
                   SELECT TOP (1)
                          0
                   FROM dbo.cvo_promo_override_audit poa
                   WHERE poa.order_no = o.order_no
                         AND poa.order_ext = o.ext
               ),
               1
                     ) AS qual
        FROM hs_sunps_2018
            JOIN dbo.orders_all (NOLOCK) o
                ON o.order_no = hs_sunps_2018.order_no
            JOIN dbo.ord_list (NOLOCK) ol
                ON o.order_no = ol.order_no
                   AND o.ext = ol.order_ext
            JOIN CVO_orders_all (NOLOCK) co
                ON o.order_no = co.order_no
                   AND o.ext = co.ext
            JOIN inv_master (NOLOCK) i
                ON ol.part_no = i.part_no
        WHERE o.status <> 'v'
              -- AND promo_id  LIKE '%SUNPS%'
              AND co.promo_id IN ( 'sunps' )
              AND co.promo_level IN ( '1', '2', '3', 'sun', 'suns1', 'suns2', 'renew1' )
              -- AND o.who_entered <> 'backordr'
              AND hs_sunps_2018.order_date <= DATEADD(YEAR, -1, @asofdate)
              AND i.type_code IN ( 'frame', 'sun' )
        GROUP BY o.cust_code,
                 o.ship_to,
                 o.type,
                 o.order_no,
                 o.ext,
                 invoice_no,
                 hs_sunps_2018.order_date,
                 o.date_shipped,
                 co.promo_id,
                 co.promo_level
        UNION ALL
        -- full 2018 orders
        SELECT o.cust_code,
               o.ship_to,
               o.type,
               o.order_no,
               CAST(invoice_no AS VARCHAR(15)) invoice_no,
               hs_sunps_2018.order_date date_entered,
               o.date_shipped,
               UPPER(co.promo_id) promo_id,
               co.promo_level,
               SUM(   CASE
                          WHEN o.who_entered <> 'BACKORDR' THEN
                              ol.ordered
                          ELSE
                              0
                      END
                  ) OrdQty,
               SUM(ol.shipped) ShipQty,
               SUM(cr_shipped) CRQty,
               CASE
                   WHEN o.type = 'I' THEN
                       1
                   ELSE
                       -1
               END AS Cnt,
               period = 0,
               ISNULL(
               (
                   SELECT TOP (1)
                          0
                   FROM dbo.cvo_promo_override_audit poa
                   WHERE poa.order_no = o.order_no
                         AND poa.order_ext = o.ext
               ),
               1
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
              AND co.promo_id IN ( 'sunps' )
              AND co.promo_level IN ( '1', '2', '3', 'sun', 'suns1', 'suns2', 'renew1' )
              -- AND o.who_entered <> 'backordr'
              AND i.type_code IN ( 'frame', 'sun' )
        GROUP BY o.cust_code,
                 o.ship_to,
                 o.type,
                 o.order_no,
                 o.ext,
                 invoice_no,
                 hs_sunps_2018.order_date,
                 date_shipped,
                 promo_id,
                 promo_level
        HAVING SUM(   CASE
                          WHEN o.who_entered = 'backordr' THEN
                              0
                          ELSE
                              ordered
                      END - cr_ordered
                  ) > 0

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
               SUM(   CASE
                          WHEN o.who_entered <> 'BACKORDR' THEN
                              ol.ordered
                          ELSE
                              0
                      END
                  ) OrdQty,
               SUM(shipped) ShipQty,
               SUM(cr_shipped) CRQty,
               CASE
                   WHEN type = 'I' THEN
                       1
                   ELSE
                       -1
               END AS Cnt,
               2019 AS period,
               ISNULL(
               (
                   SELECT TOP (1)
                          0
                   FROM dbo.cvo_promo_override_audit poa
                   WHERE poa.order_no = o.order_no
                         AND poa.order_ext = o.ext
               ),
               1
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
              AND co.promo_id IN ( 'sunps' )
              AND co.promo_level IN ( '1', '2', '3', 'sun', 'suns1', 'suns2', 'renew1' )
              -- AND o.who_entered <> 'backordr'
              AND o.date_entered
              BETWEEN @P1From AND @P1To
              AND i.type_code IN ( 'sun', 'frame' )
        GROUP BY o.cust_code,
                 o.ship_to,
                 o.type,
                 o.order_no,
                 o.ext,
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
               1 AS qual
        FROM dbo.cvo_cust_designation_codes AS cdc
        WHERE cdc.code LIKE 'sun19%'
              AND cdc.start_date >= @sdate
              AND NOT EXISTS
        (
            SELECT 1
            FROM orders oo
                JOIN CVO_orders_all coo
                    ON coo.order_no = oo.order_no
                       AND coo.ext = oo.ext
            WHERE oo.cust_code = cdc.customer_code
                  AND coo.promo_level = 'renew1'
        )),
         summ
    AS (SELECT ar.territory_code,
               ar.salesperson_code,
               s.cust_code,
               CASE
                   WHEN car.door = 0 THEN
                       ''
                   ELSE
                       s.ship_to
               END AS ship_to,
               -- s.ship_to,
               s.promo_level,
               s.period,
               SUM(ISNULL(s.Cnt, 0)) Inv_cnt,
               SUM(ISNULL(s.OrdQty, 0) - ISNULL(s.CRQty, 0)) Inv_qty,
               s.qual
        FROM sunps s
            INNER JOIN dbo.CVO_armaster_all car (NOLOCK)
                ON car.customer_code = s.cust_code
                   AND car.ship_to = s.ship_to
            INNER JOIN armaster ar (NOLOCK)
                ON ar.customer_code = car.customer_code
                   AND ar.ship_to_code = car.ship_to
        WHERE 1 = 1 -- s.period <> 0
        GROUP BY ar.territory_code,
                 ar.salesperson_code,
                 s.cust_code,
                 CASE
                     WHEN car.door = 0 THEN
                         ''
                     ELSE
                         s.ship_to
                 END,
                 -- s.ship_to,
                 s.promo_level,
                 s.period,
                 s.qual
        HAVING SUM(ISNULL(s.Cnt, 0)) > 0),
         -- Final Select
         finalselect
    AS (SELECT CASE
                   WHEN ISNULL(ar.status_type, '1') = '1' THEN
                       'Act'
                   WHEN ar.status_type = '2' THEN
                       'Inact'
                   ELSE
                       'NoNewBus'
               END status,
               ROW_NUMBER() OVER (PARTITION BY terrsales.territory_code
                                  ORDER BY terrsales.territory_code
                                 ) trank,
               terrsales.territory_code AS Terr,
               slp.salesperson_name slp,
               CASE WHEN slp.salesperson_code = terrsales.territory_code THEN 1 ELSE 0 END Empty_terr,
               ar.customer_code,
               ar.ship_to_code,
               CASE
                   WHEN summ.promo_level = 'SUN' THEN
                       'OP'
                   ELSE
                       summ.promo_level
               END PROMO_level, -- 11/16/2017
               ar.address_name,
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
               CASE WHEN ISNULL(summ.qual,1) = 1 THEN 'Yes' ELSE 'No' end Qual_order,
               terrsales.ty_netsales,
               terrsales.ly_netsales
        FROM terrsales
            INNER JOIN arsalesp slp
                ON slp.salesperson_code = terrsales.salesperson_code
            LEFT OUTER JOIN summ
                ON summ.territory_code = terrsales.territory_code
            LEFT OUTER JOIN dbo.armaster ar (NOLOCK)
                ON ar.customer_code = summ.cust_code
                   AND ar.ship_to_code = summ.ship_to
        WHERE 1=1
        -- AND slp.salesperson_code <> terrsales.territory_code
              AND
              (
                  (
                      summ.Inv_qty <> 0
                      AND summ.Inv_cnt <> 0
                  )
                  OR
                  (
                      terrsales.territory_code IS NOT NULL
                      AND summ.Inv_cnt IS NULL
                  )
                  OR summ.promo_level IN ( 'sun191', 'sun192', 'renew1' )
              ))

    -- SELECT * FROM sunps


    SELECT finalselect.status,
           finalselect.Terr,
           finalselect.slp,
           finalselect.Empty_terr,
           finalselect.customer_code,
           finalselect.ship_to_code,
           ISNULL(finalselect.PROMO_level, 'Terr info Only') PROMO_level,
           finalselect.address_name,
           ISNULL(finalselect.period, -1) period,
           finalselect.Inv_cnt,
           finalselect.Inv_qty,
           finalselect.Qual_order,
           CASE
               WHEN trank = 1 THEN
                   finalselect.ty_netsales
               ELSE
                   0
           END AS ty_netsales,
           CASE
               WHEN trank = 1 THEN
                   finalselect.ly_netsales
               ELSE
                   0
           END AS ly_netsales
    FROM finalselect;


--       
--SELECT *
--FROM terrsales;

END;






GO
GRANT EXECUTE ON  [dbo].[cvo_sunps_tracker_ytd_sp] TO [public]
GO
