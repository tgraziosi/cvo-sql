SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_promotions_tracker_list_sp]
    @group_name VARCHAR(50),
    @terr VARCHAR(5000) = NULL

--@sdate DATETIME ,
--@edate DATETIME ,
--@Terr VARCHAR(1000) = NULL ,
--@Promo VARCHAR(5000) = NULL,
--@PromoLevel VARCHAR(5000) = NULL
AS
BEGIN

    -- exec cvo_promotions_tracker_list_sp 'SalesTeam', null

    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;

    DECLARE @sdate DATETIME,
            @edate DATETIME,
            @Promo VARCHAR(5000),
            @PromoLevel VARCHAR(5000),
            @seq INT,
            @id INT;

    DECLARE @sdately DATETIME,
            @edately DATETIME;

    SELECT @sdate = BeginDate,
           @edate = EndDate
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'rolling 12 ty';

    -- SET @edate = DATEADD(ms, -3, DATEADD(DAY, 1, @edate));
    SET @sdately = DATEADD(YEAR, -1, @sdate);
    SET @edately = DATEADD(ms, -1, @sdate);

    -- SELECT @sdate, @edate, @sdately, @edately


    CREATE TABLE #temptable
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
        salesperson VARCHAR(8),
        Territory VARCHAR(8),
        region VARCHAR(3),
        total_amt_order DECIMAL(20, 8),
        total_discount DECIMAL(20, 8),
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
        status_desc VARCHAR(13),
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
        return_date DATETIME,
        reason VARCHAR(40),
        return_amt DECIMAL(20, 8),
        return_qty INT,
        source VARCHAR(1),
        Qual_order INT,
        override_reason VARCHAR(2000),
        UC INT,
        wk_Begindate VARCHAR(30),
        wk_EndDate VARCHAR(30)
    );

    CREATE TABLE #final
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
        salesperson VARCHAR(8),
        Territory VARCHAR(8),
        region VARCHAR(3),
        total_amt_order DECIMAL(20, 8),
        total_discount DECIMAL(20, 8),
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
        status_desc VARCHAR(13),
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
        return_date DATETIME,
        reason VARCHAR(40),
        return_amt DECIMAL(20, 8),
        return_qty INT,
        source VARCHAR(1),
        Qual_order INT,
        override_reason VARCHAR(2000),
        UC INT,
        wk_Begindate VARCHAR(30),
        wk_EndDate VARCHAR(30),
        subscription_id INT,
        subs_promo VARCHAR(1024),
        subs_promoLevel VARCHAR(1024),
        sdate DATETIME,
        edate DATETIME
    );

    SELECT @id = MIN(id)
    FROM cvo_promo_tracker_subscription_list
    WHERE Group_Name = @group_name;


    WHILE @id IS NOT NULL
    BEGIN

        SELECT @Promo = promo_id,
               @PromoLevel = CASE
                                 WHEN promo_level = '' THEN
                                     NULL
                                 ELSE
                                     promo_level
                             END,
               -- @sdate = start_date ,
               -- @edate = ISNULL(end_date, GETDATE()),
               @seq = Seq_id
        FROM cvo_promo_tracker_subscription_list
        WHERE id = @id;

        -- SELECT @PROMO, @PromoLevel, @sdate, @edate

        INSERT INTO #temptable
        EXEC cvo_promotions_tracker_terr_sp @sdate,
                                            @edate,
                                            @terr,
                                            @Promo,
                                            @PromoLevel;

        INSERT INTO #final
        SELECT t.order_no,
               t.ext,
               t.cust_code,
               t.ship_to,
               t.ship_to_name,
               t.location,
               t.cust_po,
               t.routing,
               t.fob,
               t.attention,
               t.tax_id,
               t.terms,
               t.curr_key,
               t.salesperson,
               t.Territory,
               t.region,
               t.total_amt_order,
               t.total_discount,
               t.total_tax,
               t.freight,
               t.qty_ordered,
               t.qty_shipped,
               t.total_invoice,
               t.invoice_no,
               t.doc_ctrl_num,
               t.date_invoice,
               t.date_entered,
               t.date_sch_ship,
               t.date_shipped,
               t.status,
               t.status_desc,
               t.who_entered,
               t.shipped_flag,
               t.hold_reason,
               t.orig_no,
               t.orig_ext,
               t.promo_id,
               t.promo_level,
               t.order_type,
               t.FramesOrdered,
               t.FramesShipped,
               t.back_ord_flag,
               t.Cust_type,
               t.return_date,
               t.reason,
               t.return_amt,
               t.return_qty,
               t.source,
               t.Qual_order,
               t.override_reason,
               t.UC,
               t.wk_Begindate,
               t.wk_EndDate,
               @seq,
               @Promo,
               @PromoLevel,
               @sdate,
               @edate
        FROM #temptable AS t;

        TRUNCATE TABLE #temptable;

        SELECT @id = MIN(id)
        FROM cvo_promo_tracker_subscription_list
        WHERE Group_Name = @group_name
              AND id > @id;

    END;


    SELECT DISTINCT
           t.order_no,
           t.ext,
           t.cust_code,
           t.ship_to,
           t.ship_to_name,
           t.location,
           t.cust_po,
           t.routing,
           t.fob,
           t.attention,
           t.tax_id,
           t.terms,
           t.curr_key,
           t.salesperson,
           t.Territory,
           t.region,
           t.total_amt_order,
           t.total_discount,
           t.total_tax,
           t.freight,
           t.qty_ordered,
           t.qty_shipped,
           t.total_invoice,
           t.invoice_no,
           t.doc_ctrl_num,
           t.date_invoice,
           t.date_entered,
           t.date_sch_ship,
           t.date_shipped,
           t.status,
           t.status_desc,
           t.who_entered,
           t.shipped_flag,
           t.hold_reason,
           t.orig_no,
           t.orig_ext,
           t.promo_id,
           t.promo_level,
           t.order_type,
           t.FramesOrdered,
           t.FramesShipped,
           t.back_ord_flag,
           t.Cust_type,
           t.return_date,
           t.reason,
           t.return_amt,
           t.return_qty,
           t.source,
           t.Qual_order,
           t.override_reason,
           t.UC,
           t.wk_Begindate,
           t.wk_EndDate,
           t.subscription_id,
           t.subs_promo,
           t.subs_promoLevel,
           t.sdate,
           t.edate
    FROM #final AS t;

END;








GO
