SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_open_sales_orders_sp]
AS 

BEGIN

SET NOCOUNT ON
SET ANSI_WARNINGS OFF


IF OBJECT_ID('tempdb..#openorders') IS NOT NULL
    DROP TABLE #openorders
    ;

CREATE TABLE #openorders
(
    order_no VARCHAR(10),
    ext VARCHAR(3),
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
    source VARCHAR(1),
    rec_id INT IDENTITY(1, 1)
)
;


IF OBJECT_ID('tempdb..#exclusions') IS NOT NULL
    DROP TABLE #exclusions
    ;

CREATE TABLE #exclusions
(
    order_no INT,
    order_ext INT,
    has_line_exc INT NULL,
    perc_available DECIMAL(20, 8)
)
; -- v1.3

INSERT #openorders
SELECT av.order_no,
       av.ext,
       av.cust_code,
       av.ship_to,
       av.ship_to_name,
       av.location,
       av.cust_po,
       av.routing,
       av.fob,
       av.attention,
       av.tax_id,
       av.terms,
       av.curr_key,
       av.salesperson,
       av.Territory,
       av.total_amt_order,
       av.total_discount,
       av.Net_Sale_Amount,
       av.total_tax,
       av.freight,
       av.qty_ordered,
       av.qty_shipped,
       av.total_invoice,
       av.invoice_no,
       av.doc_ctrl_num,
       av.date_invoice,
       av.date_entered,
       av.date_sch_ship,
       av.date_shipped,
       av.status,
       av.status_desc,
       av.who_entered,
       av.shipped_flag,
       av.hold_reason,
       av.orig_no,
       av.orig_ext,
       av.promo_id,
       av.promo_level,
       av.order_type,
       av.FramesOrdered,
       av.FramesShipped,
       av.back_ord_flag,
       av.Cust_type,
       av.HS_order_no,
       av.allocation_date,
       av.source
FROM dbo.cvo_adord_vw AS av
WHERE status < 't'
;

DECLARE
    @id INT, @order_no INT, @ext INT
;

SELECT @id = MIN(rec_id)
FROM #openorders AS f
;

WHILE @id IS NOT NULL
BEGIN

    SELECT
        @order_no = order_no, @ext = ext
    FROM #openorders
    WHERE rec_id = @id
    ;

    EXEC dbo.cvo_check_fl_stock_pre_allocation_sp
        @order_no_in = @order_no, @order_ext_in = @ext
    ;

    SELECT @id = MIN(rec_id)
    FROM #openorders
    WHERE rec_id > @id
    ;

END
;

SELECT
	e.perc_available,
	status,
	status_desc,
	hold_reason,
	FramesOrdered,
	FramesShipped,
	who_entered,
    #openorders.order_no,
    #openorders.ext,
    #openorders.cust_code,
    #openorders.ship_to,
    #openorders.ship_to_name,
    #openorders.location,
    #openorders.cust_po,
    #openorders.routing,
    #openorders.fob,
    #openorders.attention,
    #openorders.tax_id,
    #openorders.terms,
    #openorders.curr_key,
    #openorders.salesperson,
    #openorders.Territory,
    #openorders.total_amt_order,
    #openorders.total_discount,
    #openorders.Net_Sale_Amount,
    #openorders.total_tax,
    #openorders.freight,
    #openorders.qty_ordered,
    #openorders.qty_shipped,
    #openorders.total_invoice,
    #openorders.invoice_no,
    #openorders.doc_ctrl_num,
    #openorders.date_invoice,
    #openorders.date_entered,
    #openorders.date_sch_ship,
    #openorders.date_shipped,
    #openorders.shipped_flag,
    #openorders.orig_no,
    #openorders.orig_ext,
    #openorders.promo_id,
    #openorders.promo_level,
    #openorders.order_type,
    #openorders.back_ord_flag,
    #openorders.Cust_type,
    #openorders.HS_order_no,
    #openorders.allocation_date,
    #openorders.source
	FROM
    #openorders
    JOIN #exclusions AS e
        ON e.order_no = #openorders.order_no
           AND e.order_ext = #openorders.ext
;

END

GO
GRANT EXECUTE ON  [dbo].[cvo_open_sales_orders_sp] TO [public]
GO
