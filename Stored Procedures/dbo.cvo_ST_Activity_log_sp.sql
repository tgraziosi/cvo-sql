SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_ST_Activity_log_sp]
    @startdate DATETIME,
    @enddate DATETIME,
    @Territory VARCHAR(1000) = NULL,
    @qualorder INT = 1, -- 1= qual, 0 = unqual, -1 = all
    @detail INT = 0     -- 0 = no, any other value = yes
AS
BEGIN

	SET NOCOUNT ON;

    -- add RMA figures - 6/19/2014
    -- 06/07/2016 - tag - per HK remove these qualifications for regular dstribution to Mark McCann

    -- exec cvo_ST_Activity_log_sp '02/01/2018','02/28/2018', '50505', -1 , 1

    /*
declare @startdate datetime, @enddate datetime
set @startdate = '06/10/2014'
set @enddate = '07/19/2014'

declare @territory varchar(20)
set @territory = '90614'
*/

    -- exec cvo_ST_Activity_log_sp '01/01/2015','02/28/2015', '20210'

    IF (OBJECT_ID('tempdb.dbo.#temp') IS NOT NULL)
        DROP TABLE #temp;

    IF (OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL)
        DROP TABLE #territory;

    IF (OBJECT_ID('tempdb.dbo.#finalselect') IS NOT NULL)
        DROP TABLE #finalselect;

    DECLARE @where VARCHAR(1024);

    CREATE TABLE #territory
    (
        territory VARCHAR(10) NOT NULL,
		region VARCHAR(10) NOT null
    );

    IF @Territory IS NULL
    BEGIN
        INSERT INTO #territory
        (
            territory,
			region
        )
        SELECT DISTINCT
            territory_code
			, dbo.calculate_region_fn(ar.territory_code)
        FROM dbo.armaster (NOLOCK) ar
        WHERE ar.territory_code IS NOT NULL;
    END;
    ELSE
    BEGIN
        INSERT INTO #territory
        (
            territory,
			region
        )
        SELECT distinct ListItem, dbo.calculate_region_fn(ListItem)
        FROM dbo.f_comma_list_to_table(@Territory);
    END;

	CREATE TABLE #temp
(
    order_no VARCHAR(10),
    ext VARCHAR(3),
    cust_code VARCHAR(10) null,
    ship_to VARCHAR(10) null,
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
    salesperson_name VARCHAR(60),
    Territory VARCHAR(10),
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
    date_sch_ship DATETIME,
    date_shipped DATETIME,
    status VARCHAR(1),
    status_desc VARCHAR(11),
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
    FramesRMA INT,
    net_rx DECIMAL(20, 8),
    net_sales DECIMAL(20, 8),
    back_ord_flag CHAR(1),
    Cust_type VARCHAR(40),
    HS_order_no VARCHAR(255),
    source VARCHAR(1)
);
	CREATE NONCLUSTERED INDEX idx_t_cust ON #temp (cust_code, ship_to);

	INSERT #temp
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
	    salesperson_name,
	    Territory,
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
	    FramesRMA,
	    net_rx,
	    net_sales,
	    back_ord_flag,
	    Cust_type,
	    HS_order_no,
	    source
	)
    SELECT o.order_no,
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
           SPACE(60) AS salesperson_name,
           o.Territory,
           o.total_amt_order,
           o.total_discount,
           o.total_tax,
           o.freight,
           o.qty_ordered,
           o.qty_shipped,
           o.total_invoice,
           o.invoice_no,
           o.doc_ctrl_num,
           o.date_invoice,
           o.date_sch_ship,
           o.date_shipped,
           o.status,
           CASE WHEN o.status IN ('A','H') THEN 'Hold'
                WHEN o.status IN ('B','C') THEN 'Credit Hold'
				WHEN O.STATUS IN ('E','M') THEN 'Other'
                WHEN o.status IN ('N')     THEN 'Received'
                WHEN o.status IN ('P') THEN
                   CASE
                       WHEN ISNULL(
                            (
                                SELECT TOP (1)
                                    c.status
                                FROM dbo.tdc_carton_tx c (NOLOCK)
                                WHERE o.order_no = c.order_no
                                      AND o.ext = c.order_ext
                                      AND
                                      (
                                          c.void = 0
                                          OR c.void IS NULL
                                      )
                                ORDER BY c.carton_no
                            ),
                            ''
                                  ) IN ( 'F', 'S', 'X' ) THEN
                           'Shipped'
                       ELSE
                           'Processing'
                   END
               WHEN o.status IN ('Q') THEN 'Processing'
               WHEN o.status in ('R','S','T') THEN 'Shipped'
               WHEN o.status in ('V','x') THEN 'Void'
               ELSE ''
           END AS status_desc,
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
           0 AS FramesRMA,
           CAST(0 AS DECIMAL(20, 8)) AS net_rx,
           CAST(0 AS DECIMAL(20, 8)) AS net_sales,
           o.back_ord_flag,
           o.Cust_type,
           o.HS_order_no,
           o.source

    FROM #territory AS t
		JOIN dbo.cvo_adord_vw AS o WITH (NOLOCK) 
            ON o.territory = t.Territory
    WHERE 1 = 1
          AND o.status <> 'V'
          AND (o.date_entered
          BETWEEN @startdate AND DATEADD(ms, -3, DATEADD(dd, DATEDIFF(dd, 0, @enddate) + 1, 0))
              )
          -- 06/07/2016 - tag - per HK remove these qualifications for regular dstribution to Mark McCann
          -- and o.date_sch_ship between @startdate and @enddate 
          -- and isnull(o.date_shipped,@enddate) <= @enddate
          AND o.who_entered <> 'BACKORDR'
          AND o.order_type LIKE 'ST%'
          -- AND RIGHT(o.order_type, 2)NOT IN ( 'RB', 'TB' ) -- count TBB's 02/20/2018
          AND 'RB' <> RIGHT(o.order_type, 2)  -- count TBB's 02/20/2018
          AND (o.total_amt_order - o.total_discount) > 0.00
          AND 0 < ISNULL(o.FramesOrdered, 0);

    -- tally up credit returns too

    INSERT INTO #temp
    SELECT DISTINCT

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
        SPACE(60) AS salesperson_name,
        o.ship_to_region AS Territory,
        total_amt_order = (CASE o.status
                               WHEN 'T' THEN
                                   o.gross_sales
                               ELSE
                                   o.total_amt_order
                           END
                          ) * -1,
        (CASE o.status
             WHEN 'T' THEN
                 o.total_discount
             ELSE
                 o.tot_ord_disc
         END
        ) * -1 AS total_discount,
        (CASE o.status
             WHEN 'T' THEN
                 o.total_tax
             ELSE
                 o.tot_ord_tax
         END
        ) * -1 AS total_tax,
        (CASE o.status
             WHEN 'T' THEN
                 o.freight
             ELSE
                 o.tot_ord_freight
         END
        ) * -1 AS freight,
        0 AS qty_ordered,
        0 AS qty_shipped,
        (CASE o.status
             WHEN 'T' THEN
                 o.total_invoice
             ELSE
        (o.total_amt_order - o.tot_ord_disc + o.tot_ord_tax + o.tot_ord_freight)
         END
        ) * -1 AS total_invoice,
        CONVERT(VARCHAR(10), o.invoice_no) invoice_no,
        oi.doc_ctrl_num,
        o.invoice_date date_invoice,
        o.sch_ship_date date_sch_ship,
        o.date_shipped,
        o.status,
           CASE WHEN o.status IN ('A','H') THEN 'Hold'
                WHEN o.status IN ('B','C') THEN 'Credit Hold'
				WHEN O.STATUS IN ('E','M') THEN 'Other'
                WHEN o.status IN ('N')     THEN 'Received'
                WHEN o.status IN ('P') THEN
                   CASE
                       WHEN ISNULL(
                            (
                                SELECT TOP (1)
                                    c.status
                                FROM dbo.tdc_carton_tx c (NOLOCK)
                                WHERE o.order_no = c.order_no
                                      AND o.ext = c.order_ext
                                      AND
                                      (
                                          c.void = 0
                                          OR c.void IS NULL
                                      )
                                ORDER BY c.carton_no
                            ),
                            ''
                                  ) IN ( 'F', 'S', 'X' ) THEN
                           'Shipped'
                       ELSE
                           'Processing'
                   END
               WHEN o.status IN ('Q') THEN 'Processing'
               WHEN o.status in ('R','S','T') THEN 'Shipped'
               WHEN o.status in ('V','x') THEN 'Void'
               ELSE ''
           END AS status_desc,
        o.who_entered,
        CASE WHEN o.status IN ('r','s','t') THEN 'Yes'
						ELSE 'No' END AS shipped_flag,
		o.hold_reason,
        o.orig_no,
        o.orig_ext,
        co.promo_id,
        co.promo_level,
        'ST' AS order_type,
        0 AS FramesOrdered,
        0 AS FramesShipped,
        ISNULL(
        (
            SELECT SUM(ol.cr_ordered)
            FROM ord_list ol (NOLOCK)
                JOIN inv_master i (NOLOCK)
                    ON ol.part_no = i.part_no
            WHERE o.order_no = ol.order_no
                  AND o.ext = ol.order_ext
                  AND i.type_code IN ( 'frame', 'sun' )
				  AND ol.return_code LIKE '06%' -- 02/26/2018
        ),
        0
              ) AS FramesRMA,
        0.0 AS net_rx,
        0.0 AS net_sales,
        o.back_ord_flag,
        ISNULL(ar.addr_sort1, '') AS Cust_type,
        ISNULL(o.user_def_fld4, '') AS HS_order_no,
        'C' AS source

    FROM orders o (NOLOCK)
        INNER JOIN #territory t
            ON t.territory = o.ship_to_region
        INNER JOIN #temp
            ON #temp.cust_code = o.cust_code
               AND #temp.ship_to = o.ship_to
        -- hs_order_no = isnull(o.user_def_fld4,'') -- only related to an order
        JOIN CVO_orders_all co (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
		JOIN armaster ar (nolock)
            ON ar.customer_code = o.cust_code
               AND ar.ship_to_code = o.ship_to
        LEFT OUTER JOIN orders_invoice oi (nolock)
            ON oi.order_no = o.order_no
               AND oi.order_ext = o.ext

    WHERE o.type = 'c'
          AND o.status <> 'v'
          AND o.date_entered
          BETWEEN @startdate AND DATEADD(ms, -3, DATEADD(dd, DATEDIFF(dd, 0, @enddate) + 1, 0))
          -- and o.hold_reason = isnull((select top 1 value_str from config where flag = 'CR_UPLOAD_HOLD_RES'),'xxx')
          AND EXISTS
    (
        SELECT 1
        FROM ord_list ol (NOLOCK)
        WHERE ol.order_no = o.order_no
              AND ol.order_ext = o.ext
              AND ol.return_code LIKE '06%'
    );

    -- create framework of rep. list in case covering a territory with no activity


    INSERT INTO #temp
    (
        Territory,
        salesperson,
        salesperson_name,
        cust_code,
        ship_to,
        ship_to_name,
        source,
        tax_id,
        status_desc,
        shipped_flag,
        Cust_type,
        HS_order_no,
        FramesOrdered,
        FramesShipped,
        FramesRMA,
        net_rx,
        net_sales,
        total_amt_order,
        total_discount
    )
    SELECT DISTINCT
        a.territory_code,
        a.salesperson_code,
        slp.salesperson_name,
        NULL,
        null,
        '',
        'T',
        '',
        '',
        '',
        '',
        '',
        0,
        0,
        0,
        ISNULL(tsr.Net_RX, 0.0) net_rx,
        ISNULL(tsr.Net_sales, 0.0) net_sales,
        0,
        0

    FROM #territory AS t 
		JOIN dbo.armaster (NOLOCK) a ON a.territory_code = t.territory
        INNER JOIN dbo.arsalesp slp (NOLOCK)
            ON slp.salesperson_code = a.salesperson_code
        LEFT OUTER JOIN
        (
            SELECT ar.territory_code,
                   SUM(   CASE
                              WHEN sd.user_category LIKE 'RX%' THEN sd.anet
                              ELSE
                                  0
                          END
                      ) Net_RX,
                   SUM(sd.anet) Net_sales
            FROM #territory AS t2 (NOLOCK)
			JOIN dbo.armaster ar (NOLOCK) ON ar.territory_code = t2.territory
			JOIN dbo.cvo_sbm_details AS sd (nolock) 
                    ON ar.customer_code = sd.customer
                       AND ar.ship_to_code = sd.ship_to
            WHERE sd.yyyymmdd
            BETWEEN @startdate AND @enddate
            GROUP BY ar.territory_code
        ) tsr
            ON tsr.territory_code = a.territory_code

    WHERE a.territory_code IS NOT NULL
          AND a.salesperson_code <> 'smithma'
          AND a.status_type = 1;

    -- active accounts only


    -- select * from #temp 

    -- Final Select 

    SELECT #temp.cust_code,
		   #temp.ship_to,
		   --ISNULL(cust_code, '') cust_code,
           --ship_to = ISNULL(#temp.ship_to, ''),
            CASE WHEN ca.door = 0 THEN
                                  ''
                              ELSE
                                  ISNULL(#temp.ship_to, '')
                          END AS ship_To_door,
           #temp.ship_to_name,
           -- salesperson,
           -- MAX(ISNULL(#temp.salesperson_name, salesperson)) salesperson_name,
		   slp.salesperson_code salesperson,
		   slp.salesperson_name,
           #temp.Territory,
           t.region region, -- 10/31/2013
           SUM(total_amt_order) total_amt_order,
           SUM(total_discount) total_discount,
           SUM(total_tax) total_tax,
           SUM(freight) freight,
           SUM(qty_ordered) qty_ordered,
           SUM(qty_shipped) qty_shipped,
           SUM(total_invoice) total_invoice,
           SUM(FramesOrdered) FramesOrdered,
           SUM(FramesShipped) FramesShipped,
           SUM(FramesRMA) FramesRMA,
           SUM(net_rx) net_rx,
           SUM(net_sales) net_sales
    --,Qual_order = case when ((isnull(framesordered,0) - isnull(framesrma,0)) > 4 
    --	and total_amt_order <> 0.0
    --	and date_sch_ship between @startdate and @enddate 
    --	and isnull(date_shipped,@enddate) <= @enddate) then 1 
    --	when source = 't' then 1 
    --	-- when framesrma <> 0 then 1
    --	else 0 end

    INTO #finalselect

    FROM #territory AS t
		JOIN #temp ON #temp.Territory = t.territory
        LEFT OUTER JOIN dbo.CVO_armaster_all ca (NOLOCK)
            ON ca.customer_code = #temp.cust_code
               AND ca.ship_to = #temp.ship_to
        --LEFT OUTER JOIN arsalesp slp (NOLOCK)
        --    ON slp.salesperson_code = #temp.salesperson
		LEFT OUTER JOIN dbo.arsalesp slp (nolock)
			ON slp.territory_code = #temp.Territory
    WHERE (
              ISNULL(FramesRMA, 0) > 0
              OR ISNULL(FramesOrdered, 0) > 0
              OR source = 'T'
          )
		  AND ISNULL(slp.status_type,1) = 1 -- active salesperson in the territory
		  
    GROUP  BY CASE WHEN ca.door = 0 THEN '' ELSE ISNULL(#temp.ship_to, '') END,
              cust_code,
              #temp.ship_to,
              ship_to_name,
              slp.salesperson_code,
              slp.salesperson_name,
              #temp.Territory,
              t.region

    -- , dbo.calculate_region_fn(Territory)

    --having
    --( (sum(isnull(framesordered,0)) - sum(isnull(framesrma,0)) ) > 4 
    --	and ( sum(total_amt_order) - sum(total_discount) ) <> 0.0 )
    --	or isnull(cust_code,'') = ''



    IF @qualorder = 1
        SELECT @where
            = '
    (framesordered - framesrma  > 4 
	 and  total_amt_order - total_discount <> 0.0)
	 or cust_code = '''' ';

    IF @qualorder = 0
        SELECT @where
            = '
    (framesordered - framesrma  <= 4 
	 and  total_amt_order - total_discount <> 0.0)
	 or cust_code = '''' ';

    -- 11/30/2017
    IF @qualorder = -1
        SELECT @where = ' 1 = 1';

    IF @detail = 0
        EXEC ('	select
	f.cust_code,
	f.ship_to ,
	ship_To_door,
	ship_to_name,
	salesperson,
	salesperson_name,
	Territory,
	region, -- 10/31/2013
	total_amt_order,
	total_discount ,
	total_tax,
	freight,
	qty_ordered,
	qty_shipped,
	total_invoice,
	FramesOrdered,
	FramesShipped,
	FramesRMA,
	isnull(net_rx,0.0) net_rx,
	isnull(net_sales,0.0) net_sales
	From #finalselect f
		  where ' + @where);
    ELSE
        EXEC ('	select order_no,
       ext,
       f.cust_code,
       f.ship_to,
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
       salesperson_name,
       Territory,
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
       FramesRMA,
	   isnull(net_rx,0.0) net_rx,
	   isnull(net_sales,0.0) net_sales,
       back_ord_flag,
       Cust_type,
       HS_order_no,
       source 
	From #temp f
	 where ' + @where);



END;









GO
GRANT EXECUTE ON  [dbo].[cvo_ST_Activity_log_sp] TO [public]
GO
