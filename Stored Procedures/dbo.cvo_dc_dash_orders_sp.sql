SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dash_orders_sp] 
AS 
BEGIN

-- SELECT * FROM dbo.cvo_dc_dash_orders_tbl AS ddot where order_no = 3475766

-- SELECT * FROM dbo.cvo_dc_dash_orders_tbl AS ddot WHERE ddot.ordertype = 'pc'

--SELECT * FROM orders WHERE order_no = 3475766

-- SELECT * FROM dbo.cvo_cart_scan_orders AS cso

IF ( OBJECT_ID('dbo.cvo_dc_dash_orders_tbl') IS NULL )
begin
CREATE TABLE dbo.cvo_dc_dash_orders_tbl
    (
        cust_code     VARCHAR(10),
        order_no      VARCHAR(10),
        EXT           VARCHAR(3),
        date_entered  DATETIME,
        who_entered   VARCHAR(20),
        status_DESC   VARCHAR(16),
        date_shipped  DATETIME,
        ordertype     VARCHAR(4),
        FramesOrdered DECIMAL(38, 8),
        date_sch_ship DATETIME,
        Cust_type     VARCHAR(40),
        timeslot      VARCHAR(10),
        asofdate      DATETIME  
    );
    GRANT ALL ON dbo.cvo_dc_dash_orders_tbl TO PUBLIC;
    CREATE INDEX idx_dash_ord ON dbo.cvo_dc_dash_orders_tbl (ordertype, status_DESC);

END;
TRUNCATE TABLE dbo.cvo_dc_dash_orders_tbl;


;WITH ords AS
(
SELECT CONVERT(VARCHAR(10), o.order_no) order_no,
       CONVERT(VARCHAR(3), o.ext) ext,
       o.cust_code,
       o.ship_to,
       o.ship_to_name,
       o.location,
       o.routing,
       o.salesperson,                       -- T McGrady NOV.29.2010        
       o.ship_to_region AS Territory,       -- T McGrady NOV.29.2010        
       CASE o.status WHEN 'T' THEN o.gross_sales ELSE o.total_amt_order END total_amt_order,
       CASE o.status WHEN 'T' THEN total_discount ELSE o.tot_ord_disc END total_discount,
       CASE o.status
           WHEN 'T' THEN o.gross_sales - o.total_discount ELSE o.total_amt_order - o.tot_ord_disc
       END Net_Sale_Amount,
       CASE o.status WHEN 'T' THEN total_tax ELSE o.tot_ord_tax END total_tax,
       CASE o.status WHEN 'T' THEN freight ELSE o.tot_ord_freight END freight,
       qtys.qty_ordered qty_ordered,
       qtys.qty_shipped qty_shipped,
       CASE o.status
           WHEN 'T' THEN total_invoice ELSE
       (o.total_amt_order - o.tot_ord_disc + o.tot_ord_tax + o.tot_ord_freight)
       END total_invoice,
       CONVERT(VARCHAR(10), o.invoice_no) invoice_no,
       orders_invoice.doc_ctrl_num,
       o.invoice_date date_invoice,
       o.date_entered,
       o.sch_ship_date date_sch_ship,
       o.date_shipped,
       CAST(o.status AS VARCHAR(1)) status,
       CASE WHEN o.status < 'N' THEN 'New-UnableToShip'
            WHEN o.status = 'N' THEN 'New'
            WHEN (o.status IN ('r','s','t') 
                OR (o.status = 'p' AND EXISTS (SELECT 1 FROM tdc_carton_tx x WHERE x.order_no = o.order_no AND x.order_ext = o.ext
                and x.status <> 'O' ))) THEN 'Shipped'
            WHEN o.status = 'P' AND cso.order_no IS NOT NULL THEN 'PC'
            WHEN o.status = 'P' THEN 'Open/Pick'
            WHEN o.status = 'Q' THEN 'Open/Print'
            ELSE '' END status_desc,
       o.who_entered,
       CASE WHEN o.status IN ( 'R', 'S', 'T' ) THEN 'Yes' ELSE 'No' END shipped_flag,
       o.hold_reason,                       -- T McGrady NOV.29.2010        
       cvo.promo_id,                             -- tag - add promos  
       cvo.promo_level,
       CASE WHEN o.who_entered IN ('backordr','outofstock')  THEN 'BO'
            WHEN cvo.must_go_today = 1 THEN 'MGT'
            WHEN ar.addr_sort1 = 'key account' THEN 'KEY'
            WHEN ar.addr_sort1 = 'intl retailer' THEN 'INTL'
            WHEN LEFT(o.user_category,2)='RX' THEN 'RX' ELSE 'ST' end AS order_type,           
       ISNULL(qtys.framesordered, 0) AS FramesOrdered,
       ISNULL(qtys.framesshipped, 0) AS FramesShipped,
       o.back_ord_flag,
       ISNULL(ar.addr_sort1, '') AS Cust_type,
       ISNULL(user_def_fld4, '') AS HS_order_no, -- 101613 - as per HK
       cvo.allocation_date allocation_date
FROM dbo.orders o (NOLOCK)
    LEFT OUTER JOIN dbo.cvo_cart_scan_orders AS cso ON cso.order_no = (CAST(o.order_no AS VARCHAR(7)) + '-' + CAST(o.ext AS CHAR(1)))
    LEFT OUTER JOIN dbo.orders_invoice orders_invoice (NOLOCK)
        ON (
           o.order_no = orders_invoice.order_no
           AND o.ext = orders_invoice.order_ext
           )
    LEFT JOIN dbo.CVO_orders_all cvo (NOLOCK)
        ON (
           o.order_no = cvo.order_no
           AND o.ext = cvo.ext
           ) -- tag = add promos       
    LEFT OUTER JOIN dbo.armaster ar (NOLOCK)
        ON o.cust_code = ar.customer_code
           AND o.ship_to = ar.ship_to_code
    LEFT OUTER JOIN
    (
    SELECT order_no,
           order_ext,
           SUM(ISNULL(ordered, 0) - ISNULL(cr_ordered, 0)) qty_ordered,
           SUM(ISNULL(shipped, 0) - ISNULL(cr_shipped, 0)) qty_shipped,
           SUM(CASE WHEN I.type_code IN ( 'frame', 'sun' ) THEN ordered ELSE 0 END) framesordered,
           SUM(CASE WHEN I.type_code IN ( 'frame', 'sun' ) THEN shipped ELSE 0 END) framesshipped
    FROM dbo.ord_list OL (NOLOCK)
        JOIN dbo.inv_master I (NOLOCK)
            ON OL.part_no = I.part_no
    GROUP BY order_no,
             order_ext
    ) qtys
        ON qtys.order_no = o.order_no
           AND qtys.order_ext = o.ext
WHERE o.type = 'I' AND o.STATUS <> 'V'
AND sch_ship_date <= GETDATE()

)
, xfers AS
(-- Transfers
SELECT CONVERT(VARCHAR(10), x.xfer_no) order_no,
       CONVERT(VARCHAR(3), 0) ext,
       x.to_loc cust_code,
       '' ship_to,
       '' ship_to_name,
       x.to_loc_name location,
       x.routing,
       '' salesperson,                      
       '' Territory,       
       0 total_amt_order,
       0 total_discount,
     0 Net_Sale_Amount,
      0  total_tax,
       0  freight,
       xqtys.ordered qty_ordered,
       xqtys.shipped qty_shipped,
      0 total_invoice,
       ''  invoice_no,
       '' doc_ctrl_num,
       x.date_shipped date_invoice,
       x.date_entered,
       x.sch_ship_date date_sch_ship,
       x.date_shipped,
       CAST(x.status AS CHAR(1)) status,
       CASE WHEN x.status = 'N' THEN 'New'
            WHEN (x.status IN ('r','s') 
                OR (status = 'Q' AND EXISTS (SELECT 1 FROM tdc_carton_tx xx WHERE xx.order_no = x.xfer_no 
                and xx.status <> 'O' ))) THEN 'Shipped'
            WHEN x.status = 'Q' AND EXISTS ( SELECT 1 FROM dbo.cvo_cart_scan_orders AS cso WHERE cso.order_no = CAST(x.xfer_no AS VARCHAR(6))+'-0' ) THEN 'PC'
            WHEN x.status = 'Q' AND xqtys.shipped <> 0 THEN 'Open/Pick'
            WHEN x.status = 'Q' AND xqtys.shipped = 0 THEN 'Open/Print'
            WHEN (x.status IN ('r','s') 
                OR (status = 'Q' AND EXISTS (SELECT 1 FROM tdc_carton_tx xx WHERE xx.order_no = x.xfer_no 
                            and x.status <> 'O' ))) THEN 'Shipped'
            ELSE '' END status_desc,
       x.who_entered,
       CASE WHEN x.status IN ( 'R', 'S') THEN 'Yes' ELSE 'No' END shipped_flag,
       '' hold_reason,        
       '' promo_id,                             -- tag - add promos  
       '' promo_level,
       'XFER' order_type,           
       ISNULL(xqtys.framesordered, 0) AS FramesOrdered,
       ISNULL(xqtys.framesshipped, 0) AS FramesShipped,
       x.back_ord_flag,
       ''  Cust_type,
       '' HS_order_no, -- 101613 - as per HK
       x.date_entered allocation_date
FROM dbo.xfers_all AS x (NOLOCK)
    LEFT OUTER JOIN
    (
    SELECT xfer_no order_no,
           0 order_ext,
           SUM(ISNULL(ordered, 0)) ordered,
           SUM(ISNULL(shipped, 0)) shipped,
           SUM(CASE WHEN I.type_code IN ( 'frame', 'sun' ) THEN ordered ELSE 0 END) framesordered,
           SUM(CASE WHEN I.type_code IN ( 'frame', 'sun' ) THEN shipped ELSE 0 END) framesshipped
    FROM dbo.xfer_list OL (NOLOCK)
        JOIN dbo.inv_master I (NOLOCK)
            ON OL.part_no = I.part_no
    GROUP BY OL.xfer_no
    ) xqtys
        ON xqtys.order_no = x.xfer_no
WHERE x.STATUS < 'S' AND sch_ship_date <= GETDATE() AND x.to_loc <> '001'
)
-- 
INSERT INTO dbo.cvo_dc_dash_orders_tbl
    (
        cust_code,
        order_no,
        EXT,
        date_entered,
        who_entered,
        status_DESC,
        date_shipped,
        ordertype,
        FramesOrdered,
        date_sch_ship,
        Cust_type,
        timeslot,
        asofdate
    )
SELECT
    cust_code,
    order_no,
    EXT,
    date_entered,
    who_entered,
    status_DESC,
    date_shipped,
    order_type                                         AS ordertype,
    ords.FramesOrdered,
    date_sch_ship,
    Cust_type,
    CASE WHEN ords.who_entered IN ('BACKORDR','OUTOFSTOCK') THEN 'BEFORE3'
        WHEN CONVERT(VARCHAR(10), date_entered, 108) <= '16:00:00'
            THEN
            'BEFORE3'
        WHEN CONVERT(VARCHAR(10), date_entered, 108) > '16:00:00'
            THEN
            'AFTER3'
        ELSE
            CONVERT(VARCHAR(10), date_entered, 108)
    END                                                AS timeslot,
    GETDATE() asofdate
FROM
    ords
WHERE
    ords.status >='N'
    AND 
    ((ORDS.ORDER_TYPE <> 'BO' AND  date_entered >=  DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
    OR 
    (ords.order_type IN ('BO','MGT') AND ( ords.status BETWEEN 'p' AND 's' OR (ords.status ='n' AND EXISTS (SELECT 1 FROM dbo.tdc_soft_alloc_tbl AS tsat WHERE TSAT.order_no = ORDS.order_no AND TSAT.order_ext = ORDS.EXT)))))
UNION ALL
SELECT
    cust_code,
    order_no,
    EXT,
    date_entered,
    who_entered,
    status_DESC,
    date_shipped,
    order_type                                         AS ordertype,
    FramesOrdered,
    date_sch_ship,
    Cust_type,
    'BEFORE3' AS timeslot,
    GETDATE() asofdate
FROM xfers

END



GO
