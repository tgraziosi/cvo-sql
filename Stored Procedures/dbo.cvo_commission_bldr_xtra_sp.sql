SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_commission_bldr_xtra_sp]
    @terr VARCHAR(1024) = NULL,
    @sdate DATETIME,
    @edate DATETIME
AS
BEGIN

	-- exec cvo_commission_bldr_xtra_sp '20215,20220', '10/01/2018','10/30/2018'
		-- exec cvo_commission_bldr_r3_sp '20215,20220', '10/01/2018','10/30/2018'

    SET NOCOUNT ON;

    IF (OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL)
        DROP TABLE #territory;
    CREATE TABLE #territory
    (
        territory VARCHAR(10)
    );

    IF @terr IS NULL
    BEGIN
        INSERT #territory
        SELECT DISTINCT
               territory_code
        FROM dbo.armaster
        WHERE territory_code IS NOT NULL
        ORDER BY territory_code;
    END;
    ELSE
    BEGIN
        INSERT INTO #territory
        (
            territory
        )
        SELECT DISTINCT
               ListItem
        FROM dbo.f_comma_list_to_table(@terr)
        ORDER BY ListItem;
    END;


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
    Net_Sales DECIMAL(20,8),
    brand VARCHAR(10),
    Amount DECIMAL(20,8),
    Comm_pct DECIMAL(5, 2),
    Comm_amt DECIMAL(20,8),
    Loc VARCHAR(10),
    salesperson_name VARCHAR(40),
    HireDate VARCHAR(30),
    draw_amount DECIMAL(20,8),
    Region VARCHAR(3)
    );
    INSERT INTO #cb
    (
        Salesperson,
        Territory,
        Cust_code,
        Ship_to,
        Name,
        Order_no,
        Ext,
        Invoice_no,
        InvoiceDate,
        DateShipped,
        OrderType,
        Promo_id,
        Level,
        framesshipped,
        promo_cnt,
        type,
        Net_Sales,
        brand,
        Amount,
        Comm_pct,
        Comm_amt,
        Loc,
        salesperson_name,
        HireDate,
        draw_amount,
        Region
    )
    EXEC cvo_commission_bldr_r3_sp @terr, @sdate, @edate;


    SELECT cb.Salesperson,
           cb.Territory,
           cb.Cust_code,
           cb.Ship_to,
           cb.Name,
           cb.Order_no,
           cb.Ext,
           cb.Invoice_no,
           cb.InvoiceDate,
           cb.DateShipped,
           cb.OrderType,
           cb.Promo_id,
           cb.Level,
           cb.framesshipped,
           cb.promo_cnt,
           cb.type,
           cb.Net_Sales,
           cb.brand,
           cb.Amount,
           cb.Comm_pct,
           cb.Comm_amt,
           cb.Loc,
           cb.salesperson_name,
           cb.HireDate,
           cb.draw_amount,
           cb.Region,
           CASE WHEN ISNULL(co.commission_override,0) = 1 THEN co.commission_pct ELSE NULL end order_comm_pct,
		   CASE WHEN ISNULL(pr.commissionable,0) = 1 THEN pr.commission ELSE NULL end promo_comm_pct,
		   CASE WHEN ISNULL(aa.commissionable,0) = 1 THEN aa.commission ELSE NULL END cust_comm_pct,
           CASE WHEN ISNULL(slp.escalated_commissions,0) = 1 THEN slp.commission ELSE NULL end slp_commission_pct,
		   p.price_code,
           p.commission_pct pc_sommission_pct,
		   CASE WHEN ar.territory_code <> cb.Territory THEN ar.territory_code ELSE NULL end cust_territory,
		   aa.commissionable, aa.commission

    FROM #cb cb
        LEFT OUTER JOIN CVO_orders_all co (NOLOCK)
            ON co.order_no = cb.Order_no
               AND co.ext = cb.ext
        LEFT OUTER JOIN orders_all (NOLOCK) o
            ON o.order_no = co.order_no
               AND o.ext = co.ext
        LEFT JOIN arsalesp (NOLOCK) slp
            ON slp.salesperson_code = cb.Salesperson
        LEFT OUTER JOIN armaster (NOLOCK) ar
            ON ar.customer_code = cb.Cust_code AND ar.ship_to_code = cb.Ship_to
        LEFT OUTER JOIN arcust c (NOLOCK)
            ON c.customer_code = cb.Cust_code
		LEFT OUTER JOIN dbo.CVO_armaster_all (NOLOCK) AS aa
			ON aa.customer_code = c.customer_code AND aa.ship_to = c.ship_to_code
        LEFT OUTER JOIN cvo_comm_pclass p (NOLOCK)
            ON p.price_code = c.price_code
		LEFT OUTER JOIN cvo_promotions pr (nolock) 
			ON pr.promo_id = cb.promo_id AND pr.promo_level = cb.Level
END;

GRANT EXECUTE on dbo.cvo_commission_bldr_xtra_sp TO public


GO
GRANT EXECUTE ON  [dbo].[cvo_commission_bldr_xtra_sp] TO [public]
GO
