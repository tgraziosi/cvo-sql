SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_openordersonhold_sp]
    @ToDate DATETIME = NULL, @FutShip INT = 0, @refresh_temp_tbl INT = 0
AS
BEGIN

	SET NOCOUNT ON;

    --declare @ToDate datetime
    --select  @ToDate = getdate()
    -- exec cvo_openordersonhold_sp '07/25/2017', 0, 1

    IF @ToDate IS NULL
        SELECT @ToDate = BeginDate
        FROM dbo.cvo_date_range_vw AS drv
        WHERE Period = 'yesterday'
        ;

    IF (OBJECT_ID('tempdb.dbo.#ooh') IS NOT NULL)
        DROP TABLE #ooh
        ;


    SELECT
        oo.order_no,
        oo.ext,
        oo.cust_code,
        oo.ship_to,
        oo.ship_to_name,
        oo.location,
        oo.cust_po,
        oo.routing,
        oo.fob,
        oo.attention,
        oo.tax_id,
        oo.terms,
        oo.curr_key,
        oo.salesperson,
        oo.Territory,
        oo.total_amt_order,
        oo.total_discount,
        oo.Net_Sale_Amount,
        oo.total_tax,
        oo.freight,
        oo.qty_ordered,
        oo.qty_shipped,
        oo.total_invoice,
        oo.invoice_no,
        oo.doc_ctrl_num,
        oo.date_invoice,
        oo.date_entered,
        oo.date_sch_ship,
        oo.date_shipped,
        oo.status,
        oo.status_desc,
        oo.who_entered,
        oo.shipped_flag,
        oo.hold_reason,
        oo.orig_no,
        oo.orig_ext,
        oo.promo_id,
        oo.promo_level,
        oo.order_type,
        oo.FramesOrdered,
        oo.FramesShipped,
        oo.back_ord_flag,
        oo.Cust_type,
        oo.HS_order_no,
        oo.allocation_date,
        oo.x_date_invoice,
        oo.x_date_entered,
        oo.x_date_sch_ship,
        oo.x_date_shipped,
        oo.source,
        dbo.calculate_region_fn(oo.Territory) AS Region,
        CASE oo.hold_reason
            WHEN 'pd' THEN
                'Past Due'
            WHEN 'CL' THEN
                'Credit Limit'
            ELSE
                ccs.status_desc
        END AS hold_descr,
        h.hold_reason adm_hold_reason,
        CASE
            WHEN oo.date_sch_ship > @ToDate
                 AND ISNULL(h.hold_reason, '') = '' THEN
                'Future Ship'
            ELSE
                ISNULL(ch.hold_dept, 'Other')
        END AS hold_dept,
        ar.addr_sort1 AS CustomerType,
        C.OpenAR,
        DaysToShip = CASE
                         WHEN DATEDIFF(DAY, oo.date_sch_ship, @ToDate) > 28 THEN
                             'Past Due: over 4 wks'
                         WHEN DATEDIFF(DAY, oo.date_sch_ship, @ToDate) > 14 THEN
                             'Past Due: 2 - 4 wks'
                         WHEN DATEDIFF(DAY, oo.date_sch_ship, @ToDate) > 0 THEN
                             'Past Due: < 2 wks'
                         WHEN DATEDIFF(DAY, oo.date_sch_ship, @ToDate) < -28 THEN
                             'Future: over 4 wks'
                         WHEN DATEDIFF(DAY, oo.date_sch_ship, @ToDate) < -14 THEN
                             'Future: 2  - 4 wks'
                         WHEN DATEDIFF(DAY, oo.date_sch_ship, @ToDate) < 0 THEN
                             'Future: < 2 wks'
                         WHEN DATEDIFF(DAY, oo.date_sch_ship, @ToDate) = 0 THEN
                             'Today'
                     END,
        r12.net_sales
    INTO #ooh
    FROM
        cvo_adord_vw oo (NOLOCK)
        INNER JOIN armaster ar (NOLOCK)
            ON oo.cust_code = ar.customer_code
               AND oo.ship_to = ar.ship_to_code
        LEFT OUTER JOIN cc_status_codes ccs (NOLOCK)
            ON oo.hold_reason = ccs.status_code
        LEFT OUTER JOIN adm_oehold h (NOLOCK)
            ON oo.hold_reason = h.hold_code
        LEFT OUTER JOIN cvo_adm_oehold ch (NOLOCK)
            ON oo.hold_reason = ch.hold_code
        LEFT OUTER JOIN -- AR open balance
        (
            SELECT
                customer_code, SUM(amount) AS OpenAR
            FROM artrxage (NOLOCK)
            GROUP BY customer_code
        ) AS C
            ON oo.cust_code = C.customer_code
        LEFT OUTER JOIN -- r12sales
        (
            SELECT
                sd.customer, ROUND(SUM(anet), 0) net_sales
            FROM dbo.cvo_sbm_details AS sd
            WHERE
                yyyymmdd
            BETWEEN DATEADD(YEAR, -1, DATEDIFF(dd, 0, @ToDate)) AND DATEDIFF(dd, 0, @ToDate)
            GROUP BY sd.customer
        ) AS r12
            ON r12.customer = oo.cust_code
    WHERE
        oo.status IN ( 'a', 'b', 'c' )
        AND who_entered <> 'BACKORDR'
        AND (
                (oo.date_sch_ship < DATEADD(d, 1, @ToDate))
                OR (
                       @FutShip = 1
                       AND oo.date_sch_ship > @ToDate
                   )
            )
    ;

    IF @refresh_temp_tbl = 0
    BEGIN
        SELECT
            o.order_no,
            o.ext,
            o.cust_code,
            o.ship_to,
            o.ship_to_name,
            o.location,
            o.cust_po,
            o.routing,
            o.fob,
            o.attention,
            o.tax_id,
            o.terms,
            o.curr_key,
            o.salesperson,
            o.Territory,
            o.total_amt_order,
            o.total_discount,
            o.Net_Sale_Amount,
            o.total_tax,
            o.freight,
            o.qty_ordered,
            o.qty_shipped,
            o.total_invoice,
            o.invoice_no,
            o.doc_ctrl_num,
            o.date_invoice,
            o.date_entered,
            o.date_sch_ship,
            o.date_shipped,
            o.status,
            o.status_desc,
            o.who_entered,
            o.shipped_flag,
            o.hold_reason,
            o.orig_no,
            o.orig_ext,
            o.promo_id,
            o.promo_level,
            o.order_type,
            o.FramesOrdered,
            o.FramesShipped,
            o.back_ord_flag,
            o.Cust_type,
            o.HS_order_no,
            o.allocation_date,
            o.x_date_invoice,
            o.x_date_entered,
            o.x_date_sch_ship,
            o.x_date_shipped,
            o.source,
            o.Region,
            o.hold_descr,
            o.adm_hold_reason,
            o.hold_dept,
            o.CustomerType,
            o.OpenAR,
            o.DaysToShip,
            o.net_sales
        FROM #ooh AS o
        ;
    END
    ;
    ELSE
    BEGIN

        IF (OBJECT_ID('dbo.cvo_openordersonhold_tbl') IS NULL)
        BEGIN
            CREATE TABLE dbo.cvo_openordersonhold_tbl
            (
                order_no INT,
                ext INT,
                cust_code VARCHAR(10),
                ship_to VARCHAR(10),
                ship_to_name VARCHAR(40),
                location VARCHAR(10),
                cust_po VARCHAR(20),
                routing VARCHAR(20),
                fob VARCHAR(10),
                attention VARCHAR(40),
                tax_id VARCHAR(10),
                terms VARCHAR(10),
                curr_key VARCHAR(10),
                salesperson VARCHAR(10),
                Territory VARCHAR(10),
                total_amt_order DECIMAL(20, 8),
                total_discount DECIMAL(20, 8),
                Net_Sale_Amount DECIMAL(21, 8),
                total_tax DECIMAL(20, 8),
                freight DECIMAL(20, 8),
                qty_ordered DECIMAL(38, 8),
                qty_shipped DECIMAL(38, 8),
                total_invoice DECIMAL(23, 8),
                invoice_no VARCHAR(10),
                doc_ctrl_num VARCHAR(16),
                date_invoice DATETIME,
                date_entered DATETIME,
                date_sch_ship DATETIME,
                date_shipped DATETIME,
                status VARCHAR(1),
                status_desc VARCHAR(28),
                who_entered VARCHAR(20),
                shipped_flag VARCHAR(3),
                hold_reason VARCHAR(10),
                orig_no INT,
                orig_ext INT,
                promo_id VARCHAR(255),
                promo_level VARCHAR(255),
                order_type VARCHAR(10),
                FramesOrdered DECIMAL(38, 8),
                FramesShipped DECIMAL(38, 8),
                back_ord_flag CHAR(1),
                Cust_type VARCHAR(40),
                HS_order_no VARCHAR(255),
                allocation_date DATETIME,
                x_date_invoice INT,
                x_date_entered INT,
                x_date_sch_ship INT,
                x_date_shipped INT,
                source VARCHAR(1),
                Region VARCHAR(3),
                hold_descr VARCHAR(65),
                adm_hold_reason VARCHAR(40),
                hold_dept VARCHAR(40),
                CustomerType VARCHAR(40),
                OpenAR FLOAT(8),
                DaysToShip VARCHAR(20),
                net_sales FLOAT(8),
                salesperson_name VARCHAR(40),
                action_rep TINYINT,
                action_cus TINYINT,
                note VARCHAR(1024)
            )
            ;
            CREATE CLUSTERED INDEX idx_pr
            ON dbo.cvo_openordersonhold_tbl
            (
                order_no,
                ext
            )
            ;
            GRANT SELECT
            ON cvo_openordersonhold_tbl
            TO  PUBLIC
            ;
        END
        ;

        TRUNCATE TABLE dbo.cvo_openordersonhold_tbl
        ;

        INSERT cvo_openordersonhold_tbl
        SELECT
            o.order_no,
            o.ext,
            o.cust_code,
            o.ship_to,
            o.ship_to_name,
            o.location,
            o.cust_po,
            o.routing,
            o.fob,
            o.attention,
            o.tax_id,
            o.terms,
            o.curr_key,
            o.salesperson,
            o.Territory,
            o.total_amt_order,
            o.total_discount,
            o.Net_Sale_Amount,
            o.total_tax,
            o.freight,
            o.qty_ordered,
            o.qty_shipped,
            o.total_invoice,
            o.invoice_no,
            o.doc_ctrl_num,
            o.date_invoice,
            o.date_entered,
            o.date_sch_ship,
            o.date_shipped,
            o.status,
            o.status_desc,
            o.who_entered,
            o.shipped_flag,
            o.hold_reason,
            o.orig_no,
            o.orig_ext,
            o.promo_id,
            o.promo_level,
            o.order_type,
            o.FramesOrdered,
            o.FramesShipped,
            o.back_ord_flag,
            o.Cust_type,
            o.HS_order_no,
            o.allocation_date,
            o.x_date_invoice,
            o.x_date_entered,
            o.x_date_sch_ship,
            o.x_date_shipped,
            o.source,
            o.Region,
            o.hold_descr,
            o.adm_hold_reason,
            o.hold_dept,
            o.CustomerType,
            o.OpenAR,
            o.DaysToShip,
            o.net_sales,
            slp.salesperson_name,
            notes.action_rep,
            notes.action_cus,
            notes.note
        FROM
            #ooh AS o
            LEFT OUTER JOIN arsalesp slp
                ON slp.salesperson_code = o.salesperson
            LEFT OUTER JOIN
            (
                SELECT
                    bn.order_num, bn.ext, bn.action_rep, bn.action_cus, bn.note
                FROM
                    cvo_openorder_notes bn
                    JOIN
                    (
                        SELECT
                            order_num, ext, MAX(NOtetime) max_time
                        FROM dbo.cvo_openorder_notes AS bn
                        GROUP BY
                            bn.order_num, bn.ext
                    ) mt
                        ON mt.order_num = bn.order_num
                           AND mt.ext = bn.ext
                WHERE max_time = bn.notetime
            ) notes
                ON notes.order_num = o.order_no
                   AND notes.ext = o.ext
        ;



    END
    ;

END
;





GO
GRANT EXECUTE ON  [dbo].[cvo_openordersonhold_sp] TO [public]
GO
