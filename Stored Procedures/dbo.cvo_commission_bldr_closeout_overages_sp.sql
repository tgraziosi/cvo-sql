SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_commission_bldr_closeout_overages_sp]
(
    @startdate DATETIME = NULL,
    @enddate DATETIME = NULL
)
AS
BEGIN 

-- exec cvo_commission_bldr_closeout_overages_sp '9/1/2018', '9/30/2018'

    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;

    IF @startdate IS NULL
       OR @enddate IS NULL
        SELECT @startdate = BeginDate,
               @enddate = EndDate
        FROM dbo.cvo_date_range_vw AS drv
        WHERE Period = 'Last Month';


    IF (OBJECT_ID('tempdb.dbo.#cb') IS NOT NULL)
        DROP TABLE #cb;

    CREATE TABLE #cb
    (
        Salesperson VARCHAR(8),
        Territory VARCHAR(8),
        Cust_code VARCHAR(8),
        Ship_to VARCHAR(8),
        Name VARCHAR(40),
        Order_no INT,
        Ext INT,
        Invoice_no VARCHAR(10),
        InvoiceDate DATETIME,
        DateShipped DATETIME,
        OrderType VARCHAR(10),
        Promo_id VARCHAR(20),
        Level VARCHAR(30),
        framesshipped DECIMAL(38, 8),
        promo_cnt INT,
        type VARCHAR(3),
        Net_Sales FLOAT(8),
        brand VARCHAR(10),
        Amount FLOAT(8),
        Comm_pct DECIMAL(5, 2),
        Comm_amt FLOAT(8),
        Loc VARCHAR(10),
        salesperson_name VARCHAR(40),
        HireDate VARCHAR(30),
        draw_amount DECIMAL(14, 2),
        Region VARCHAR(3)
    );

    INSERT INTO #cb
    EXEC dbo.cvo_commission_bldr_r3_sp @terr = NULL,        -- varchar(1024)
                                       @sdate = @startdate, -- datetime
                                       @edate = @enddate;   -- datetime


    DELETE FROM #cb
    WHERE Promo_id NOT IN ( 'EOR', 'EOS', 'QOP' );

    WITH PROMO
    AS
    (
    SELECT P.promo_id,
           P.promo_level,
           P.commission,
           oq.min_qty,
           ld.price,
           CASE ld.promo_ID WHEN 'EOR' THEN 4.99 WHEN 'EOS' THEN 14.99 WHEN 'QOP' THEN 9.49 ELSE 0 END strike_price1,
           CASE ld.promo_ID WHEN 'EOR' THEN 5.99 WHEN 'EOS' THEN 17.99 WHEN 'QOP' THEN 11.99 ELSE 0 END strike_price2,
           CASE ld.promo_ID WHEN 'EOR' THEN 6 WHEN 'EOS' THEN 18 WHEN 'EOR' THEN 12 ELSE 0 END strike_price3,
           22.5 strike1_comm_pct,
           27.5 strike2_comm_pct,
           32.5 strike3_comm_pct
    FROM CVO_promotions P (NOLOCK)
        LEFT OUTER JOIN dbo.CVO_order_qualifications AS oq (NOLOCK)
            ON oq.promo_ID = P.promo_id
               AND oq.promo_level = P.promo_level
        LEFT OUTER JOIN dbo.CVO_line_discounts AS ld (NOLOCK)
            ON ld.promo_ID = P.promo_id
               AND ld.promo_level = oq.promo_level
    WHERE P.promo_id IN ( 'EOR', 'EOS', 'QOP' )
          AND oq.min_qty IS NOT NULL
          AND ld.price_override = 'Y'
    ),
         qualord
    AS
    (
    SELECT ipa.order_no,
           ipa.order_ext,
           ipa.promo_id,
           ipa.promo_level,
           SUM(ipa.ExtPrice) extprice,
           SUM(Shipped) shipped,
           SUM(ipa.ordered) ordered,
           --CASE WHEN SUM(ordered) <> 0 THEN SUM(ExtPrice) / SUM(ordered) ELSE 0 END net_price_calc
           -- 10/8/2018 - use shipped qty, as the exprice is based on shipped qty too
           CASE WHEN SUM(shipped) <> 0 THEN SUM(ExtPrice) / SUM(shipped) ELSE 0 END net_price_calc
    FROM
    (SELECT DISTINCT Order_no, Ext FROM #cb) ord
        JOIN dbo.cvo_item_pricing_analysis AS ipa
            ON ord.Order_no = ipa.order_no
               AND ord.Ext = ipa.order_ext
    WHERE ipa.source = 'POSTED'
          AND ipa.type_code IN ( 'FRAME', 'SUN' )
    GROUP BY ipa.order_no,
             ipa.order_ext,
             ipa.promo_id,
             ipa.promo_level
    )
    SELECT cb.Salesperson,
           cb.Territory,
           cb.Cust_code,
           cb.Ship_to,
           cb.Name,
           qualord.order_no,
           qualord.order_ext,
           cb.Invoice_no,
           cb.InvoiceDate,
           cb.DateShipped,
           cb.OrderType,
           qualord.promo_id,
           qualord.promo_level,
           cb.type,
           cb.Net_Sales,
           cb.brand,
           cb.Amount,
           cb.Comm_pct,
           cb.Comm_amt,
           ROUND(PROMO.price, 2) promo_price,
           ROUND(qualord.net_price_calc, 2) actual_price,
           qualord.ordered qty_ordered,
           qualord.shipped qty_shipped,
           -- CASE WHEN qualord.net_price_calc > promo.price THEN 'OverPrice' ELSE '' END overprice,
           CASE
           -- WHEN qualord.net_price_calc <= PROMO.strike_price1 THEN PROMO.strike1_comm_pct
           WHEN qualord.net_price_calc <= PROMO.strike_price2 AND qualord.ordered >= promo.min_qty THEN PROMO.strike2_comm_pct
           WHEN qualord.net_price_calc >= PROMO.strike_price3 AND qualord.ordered >= promo.min_qty THEN PROMO.strike3_comm_pct ELSE 0
           END AS OVERAGE_comm_pct,
           ROUND(case
                    WHEN qualord.net_price_calc <= PROMO.strike_price2 AND qualord.ordered >= promo.min_qty THEN
                    (PROMO.strike2_comm_pct / 100 * cb.Amount) - cb.Comm_amt
                    WHEN qualord.net_price_calc >= PROMO.strike_price3 AND qualord.ordered >= promo.min_qty THEN
                    (PROMO.strike3_comm_pct / 100 * cb.Amount) - cb.Comm_amt ELSE 0
                    END,
                    2
                ) AS OVERAGE_COMM_AMT,
           cb.Loc,
           cb.salesperson_name,
           cb.HireDate,
           cb.draw_amount
    FROM qualord
        JOIN PROMO
            ON PROMO.promo_id = qualord.promo_id
               AND PROMO.promo_level = qualord.promo_level
        JOIN #cb cb
            ON cb.Order_no = qualord.order_no
               AND cb.Ext = qualord.order_ext
     WHERE qualord.net_price_calc > PROMO.strike_price1;

END;

GRANT EXECUTE ON cvo_commission_bldr_closeout_overages_sp TO PUBLIC;



GO
GRANT EXECUTE ON  [dbo].[cvo_commission_bldr_closeout_overages_sp] TO [public]
GO
