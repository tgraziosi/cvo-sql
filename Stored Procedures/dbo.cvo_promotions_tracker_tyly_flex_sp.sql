SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cvo_promotions_tracker_tyly_flex_sp]
    @sdatety DATETIME,
    @edatety DATETIME,
    @sdately DATETIME,
    @edately DATETIME,
    @Terr VARCHAR(1000) = NULL,
    @Promo VARCHAR(5000) = NULL,
    @PromoLevel VARCHAR(5000) = NULL
AS
BEGIN

    -- exec cvo_promotions_tracker_tyly_flex_sp '05/01/2018','05/31/2018', '01/01/2015','04/30/2018',  '30310,30311,30312' , 'revo', '18,24,36,48'
    -- 2/17/2017 - add active cust count for LM request

    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;


    --    DECLARE @sdately DATETIME ,
    --@edately DATETIME;

    SET @edatety = DATEADD(ms, -3, DATEADD(DAY, 1, @edatety));
    --      set  @sdately = DATEADD(YEAR, -1, @sdate)
    --SET  @edately = DATEADD(ms, -1, @sdate)

    -- SELECT @sdatety, @edatety, @sdately, @edately


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
        wk_EndDate VARCHAR(30),
        yy CHAR(2) NULL,
        id INT IDENTITY(1, 1)
    );

    INSERT INTO #temptable
    (
        order_no,
        ext,
        cust_code,
        ship_to,
        ship_to_name,
        location,
        cust_po,
        routing,
        fob,
        attention,
        tax_id,
        terms,
        curr_key,
        salesperson,
        Territory,
        region,
        total_amt_order,
        total_discount,
        total_tax,
        freight,
        qty_ordered,
        qty_shipped,
        total_invoice,
        invoice_no,
        doc_ctrl_num,
        date_invoice,
        date_entered,
        date_sch_ship,
        date_shipped,
        status,
        status_desc,
        who_entered,
        shipped_flag,
        hold_reason,
        orig_no,
        orig_ext,
        promo_id,
        promo_level,
        order_type,
        FramesOrdered,
        FramesShipped,
        back_ord_flag,
        Cust_type,
        return_date,
        reason,
        return_amt,
        return_qty,
        source,
        Qual_order,
        override_reason,
        UC,
        wk_Begindate,
        wk_EndDate
    )
    EXEC cvo_promotions_tracker_terr_sp @sdatety,
                                        @edatety,
                                        @Terr,
                                        @Promo,
                                        @PromoLevel;

    --                 EXEC cvo_promotions_tracker_terr_sp '1/1/2016','8/22/2016', '50505','aspire','1,3,launch,new,vew'
    --				   EXEC cvo_promotions_tracker_tyly_sp '1/1/2016','8/22/2016', '50505','aspire','1,3,launch,new,vew'

    --SELECT * FROM #temptable AS t

    UPDATE #temptable
    SET yy = 'TY'; -- DATEPART(YEAR, @sdate)


    INSERT INTO #temptable
    (
        order_no,
        ext,
        cust_code,
        ship_to,
        ship_to_name,
        location,
        cust_po,
        routing,
        fob,
        attention,
        tax_id,
        terms,
        curr_key,
        salesperson,
        Territory,
        region,
        total_amt_order,
        total_discount,
        total_tax,
        freight,
        qty_ordered,
        qty_shipped,
        total_invoice,
        invoice_no,
        doc_ctrl_num,
        date_invoice,
        date_entered,
        date_sch_ship,
        date_shipped,
        status,
        status_desc,
        who_entered,
        shipped_flag,
        hold_reason,
        orig_no,
        orig_ext,
        promo_id,
        promo_level,
        order_type,
        FramesOrdered,
        FramesShipped,
        back_ord_flag,
        Cust_type,
        return_date,
        reason,
        return_amt,
        return_qty,
        source,
        Qual_order,
        override_reason,
        UC,
        wk_Begindate,
        wk_EndDate
    )
    EXEC cvo_promotions_tracker_terr_sp @sdately,
                                        @edately,
                                        @Terr,
                                        @Promo,
                                        @PromoLevel;

    UPDATE #temptable
    SET yy = 'LY'
    WHERE yy IS NULL; -- DATEPART(YEAR, @sdately) WHERE yy IS NULL	
    -- now get the active door count

    DECLARE @datefrom DATETIME,
            @dateto DATETIME,
            @datefromly DATETIME,
            @datetoly DATETIME;
    SELECT @datefrom = BeginDate,
           @dateto = EndDate
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'LAST YEAR';
    SELECT @datefromly = DATEADD(YEAR, -1, @datefrom),
           @datetoly = DATEADD(YEAR, -1, @dateto);

    -- SELECT * FROM dbo.cvo_date_range_vw AS drv WHERE period = 'last year'

    SELECT ar.territory_code terr,
           ar.customer_code customer,
           ship_to_code = CASE WHEN car.door = 0 THEN '' ELSE ar.ship_to_code END,
           SUM(CASE WHEN sbm.yyyymmdd >= @datefrom THEN ISNULL(sbm.anet, 0) ELSE 0 END) net_sales_ty,
           SUM(CASE WHEN sbm.yyyymmdd <= @datetoly THEN ISNULL(sbm.anet, 0) ELSE 0 END) net_sales_ly
    INTO #salesdata
    FROM
    (SELECT DISTINCT Territory FROM #temptable) t
        INNER JOIN armaster ar
        (NOLOCK)
            ON ar.territory_code = t.Territory
        INNER JOIN CVO_armaster_all car
        (NOLOCK)
            ON car.customer_code = ar.customer_code
               AND car.ship_to = ar.ship_to_code
        INNER JOIN cvo_sbm_details sbm
        (NOLOCK)
            ON sbm.customer = ar.customer_code
               AND sbm.ship_to = ar.ship_to_code
        INNER JOIN inv_master i
        (NOLOCK)
            ON i.part_no = sbm.part_no
        INNER JOIN inv_master_add ia
        (NOLOCK)
            ON ia.part_no = i.part_no
    WHERE 1 = 1
          AND
          (
          sbm.yyyymmdd
          BETWEEN @datefrom AND @dateto
          OR sbm.yyyymmdd
          BETWEEN @datefromly AND @datetoly
          )
    GROUP BY ar.territory_code,
             ar.customer_code,
             CASE WHEN car.door = 0 THEN '' ELSE ar.ship_to_code END,
             i.category;

    -- get rid of any rolled up customers not in this territory (i.e. 030774)
    UPDATE s
    SET terr = ar.territory_code
    FROM #salesdata s
        INNER JOIN armaster ar
        (NOLOCK)
            ON ar.customer_code = s.customer
               AND ar.ship_to_code = s.ship_to_code;

    DELETE FROM #salesdata
    WHERE NOT EXISTS
    (
    SELECT 1 FROM #temptable WHERE Territory = #salesdata.terr
    );

	-- fill in any missing TY records
    INSERT #temptable
    (
        salesperson,
        Territory,
        region,
        promo_id,
        promo_level,
        FramesOrdered,
        FramesShipped,
        Qual_order,
        UC,
        yy
    )
    SELECT DISTINCT ttt.salesperson,
           ttt.Territory,
           ttt.region,
           ttt.promo_id,
           ttt.promo_level,
           0 FramesOrdered,
           0 FramesShipped,
           0 Qual_order,
           0 UC,
           'TY' yy
    FROM #temptable AS ttt
    WHERE ttt.yy = 'LY'
          AND NOT EXISTS
    (
    SELECT 1
    FROM #temptable x
    WHERE x.Territory = ttt.Territory
		  AND x.salesperson = ttt.salesperson
          AND x.promo_id = ttt.promo_id
          AND x.promo_level = ttt.promo_level
          AND x.yy = 'TY'
    );


    -- select * from #salesdata

    SELECT t.salesperson,
           t.Territory,
           t.region,
           CASE WHEN t.id =
                (
                SELECT MIN(t2.id) FROM #temptable AS t2 WHERE t.Territory = t2.Territory
                ) THEN ISNULL(door.Num_ActiveCust, 0) ELSE 0
           END AS ActiveCustCntLY,
           t.promo_id,
           t.promo_level,
           SUM(t.FramesOrdered * t.Qual_order) FramesOrdered,
           SUM(t.FramesShipped * t.Qual_order) FramesShipped,
           SUM(t.Qual_order) Qual_order,
           SUM(t.order_count) Tot_order,
           SUM(t.UC) UC,
           t.yy
    FROM
    (
    SELECT slp.salesperson_code salesperson,
           Territory,
           region,
           promo_id,
           promo_level,
           FramesOrdered,
           FramesShipped,
           Qual_order,
           CASE WHEN source = 'E' THEN 1 ELSE 0 END AS order_count,
           UC,
           yy,
           id
    FROM #temptable
        JOIN arsalesp slp
            ON slp.salesperson_code = #temptable.salesperson
    ) AS t
        LEFT OUTER JOIN
        (
        SELECT terr,
               COUNT(DISTINCT active.customer + active.ship_to_code) Num_ActiveCust
        FROM
        (
        SELECT terr,
               RIGHT(customer, 5) customer,
               ship_to_code,
               SUM(net_sales_ty) net_sales,
               SUM(net_sales_ly) net_sales_ly
        FROM #salesdata
        GROUP BY terr,
                 RIGHT(customer, 5),
                 ship_to_code
        HAVING (
               SUM(net_sales_ty) > 2400
               AND SUM(net_sales_ty) > 0
               )
        --OR ( SUM(net_sales_ly) > 2400
        --     AND SUM(net_sales_ly) > 0
        --   )
        ) active
        GROUP BY active.terr
        ) door
            ON door.terr = t.Territory
    GROUP BY t.salesperson,
             t.Territory,
             t.region,
             door.Num_ActiveCust,
             t.promo_id,
             t.promo_level,
             t.yy,
             t.id;

-- SELECT * FROM #temptable AS t -- WHERE t.Territory IN ('40454','70780','30338')

END;














GO
