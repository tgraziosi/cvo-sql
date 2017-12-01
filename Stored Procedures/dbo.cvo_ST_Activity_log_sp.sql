SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_ST_Activity_log_sp]
    @startdate DATETIME,
    @enddate DATETIME,
    @Territory VARCHAR(1000) = NULL,
    @qualorder INT = 1, -- 1= qual, 0 = unqual, -1 = all
    @detail INT = 0 -- 0 = no, any other value = yes
AS

-- add RMA figures - 6/19/2014
-- 06/07/2016 - tag - per HK remove these qualifications for regular dstribution to Mark McCann

-- exec cvo_ST_Activity_log_sp '11/01/2017','11/30/2017', null, -1

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
    territory VARCHAR(10)
);

IF @Territory IS NULL
BEGIN
    INSERT INTO #territory
    (
        territory
    )
    SELECT DISTINCT
        territory_code
    FROM armaster (NOLOCK);
END;
ELSE
BEGIN
    INSERT INTO #territory
    (
        territory
    )
    SELECT ListItem
    FROM dbo.f_comma_list_to_table(@Territory);
END;

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
       CASE o.status
           WHEN 'A' THEN
               'Hold'
           WHEN 'B' THEN
               'Credit Hold'
           WHEN 'C' THEN
               'Credit Hold'
           WHEN 'E' THEN
               'Other'
           WHEN 'H' THEN
               'Hold'
           WHEN 'M' THEN
               'Other'
           WHEN 'N' THEN
               'Received'
           WHEN 'P' THEN
               CASE
                   WHEN ISNULL(
                        (
                            SELECT TOP (1)
                                c.status
                            FROM tdc_carton_tx c (NOLOCK)
                            WHERE o.order_no = c.order_no
                                  AND o.ext = c.order_ext
                                  AND
                                  (
                                      c.void = 0
                                      OR c.void IS NULL
                                  )
                        ),
                        ''
                              ) IN ( 'F', 'S', 'X' ) THEN
                       'Shipped'
                   ELSE
                       'Processing'
               END
           WHEN 'Q' THEN
               'Processing'
           WHEN 'R' THEN
               'Shipped'
           WHEN 'S' THEN
               'Shipped'
           WHEN 'T' THEN
               'Shipped'
           WHEN 'V' THEN
               'Void'
           WHEN 'X' THEN
               'Void'
           ELSE
               ''
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
       o.back_ord_flag,
       o.Cust_type,
       o.HS_order_no,
       o.source

INTO #temp

FROM cvo_adord_vw AS o WITH (NOLOCK)
    INNER JOIN #territory t
        ON t.territory = o.Territory
WHERE 1 = 1
      AND o.status <> 'V'
      AND (o.date_entered
      BETWEEN @startdate AND DATEADD(ms, -3, DATEADD(dd, DATEDIFF(dd, 0, @enddate) + 1, 0))
          )
      -- 06/07/2016 - tag - per HK remove these qualifications for regular dstribution to Mark McCann
      -- and o.date_sch_ship between @startdate and @enddate 
      -- and isnull(o.date_shipped,@enddate) <= @enddate
      AND
      (
          (
              o.who_entered <> 'backordr'
              AND o.ext = 0
          )
          OR o.who_entered = 'outofstock'
      )
      AND o.order_type LIKE 'ST%'
      AND RIGHT(o.order_type, 2)NOT IN ( 'RB', 'TB' )
      AND (o.total_amt_order - o.total_discount) > 0.00
      AND 0 < ISNULL(FramesOrdered, 0);

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
    total_discount = (CASE o.status
                          WHEN 'T' THEN
                              o.total_discount
                          ELSE
                              o.tot_ord_disc
                      END
                     ) * -1,
    total_tax = (CASE o.status
                     WHEN 'T' THEN
                         o.total_tax
                     ELSE
                         o.tot_ord_tax
                 END
                ) * -1,
    freight = (CASE o.status
                   WHEN 'T' THEN
                       o.freight
                   ELSE
                       o.tot_ord_freight
               END
              ) * -1,
    0 AS qty_ordered,
    0 AS qty_shipped,
    total_invoice = (CASE o.status
                         WHEN 'T' THEN
                             o.total_invoice
                         ELSE
    (o.total_amt_order - o.tot_ord_disc + o.tot_ord_tax + o.tot_ord_freight)
                     END
                    ) * -1,
    CONVERT(VARCHAR(10), o.invoice_no) invoice_no,
    oi.doc_ctrl_num,
    date_invoice = o.invoice_date,
    date_sch_ship = o.sch_ship_date,
    o.date_shipped,
    o.status,
    CASE o.status
        WHEN 'A' THEN
            'Hold'
        WHEN 'B' THEN
            'Credit Hold'
        WHEN 'C' THEN
            'Credit Hold'
        WHEN 'E' THEN
            'Other'
        WHEN 'H' THEN
            'Hold'
        WHEN 'M' THEN
            'Other'
        WHEN 'N' THEN
            'Received'
        WHEN 'P' THEN
            CASE
                WHEN ISNULL(
                     (
                         SELECT TOP (1)
                             c.status
                         FROM tdc_carton_tx c (NOLOCK)
                         WHERE o.order_no = c.order_no
                               AND o.ext = c.order_ext
                               AND
                               (
                                   c.void = 0
                                   OR c.void IS NULL
                               )
                     ),
                     ''
                           ) IN ( 'F', 'S', 'X' ) THEN
                    'Shipped'
                ELSE
                    'Processing'
            END
        WHEN 'Q' THEN
            'Processing'
        WHEN 'R' THEN
            'Shipped'
        WHEN 'S' THEN
            'Shipped'
        WHEN 'T' THEN
            'Shipped'
        WHEN 'V' THEN
            'Void'
        WHEN 'X' THEN
            'Void'
        ELSE
            ''
    END AS status_desc,
    o.who_entered,
    shipped_flag = CASE o.status
                       WHEN 'A' THEN
                           'No'
                       WHEN 'B' THEN
                           'No'
                       WHEN 'C' THEN
                           'No'
                       WHEN 'E' THEN
                           'No'
                       WHEN 'H' THEN
                           'No'
                       WHEN 'M' THEN
                           'No'
                       WHEN 'N' THEN
                           'No'
                       WHEN 'P' THEN
                           'No'
                       WHEN 'Q' THEN
                           'No'
                       WHEN 'R' THEN
                           'Yes'
                       WHEN 'S' THEN
                           'Yes'
                       WHEN 'T' THEN
                           'Yes'
                       WHEN 'V' THEN
                           'No'
                       WHEN 'X' THEN
                           'No'
                       ELSE
                           ''
                   END,
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
            JOIN inv_master i
                ON ol.part_no = i.part_no
        WHERE o.order_no = ol.order_no
              AND o.ext = ol.order_ext
              AND i.type_code IN ( 'frame', 'sun' )
    ),
    0
          ) AS FramesRMA,
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
    JOIN CVO_orders_all co
        ON co.order_no = o.order_no
           AND co.ext = o.ext
    LEFT OUTER JOIN orders_invoice oi
        ON oi.order_no = o.order_no
           AND oi.order_ext = o.ext
    JOIN armaster ar
        ON ar.customer_code = o.cust_code
           AND ar.ship_to_code = o.ship_to
WHERE o.type = 'c'
      AND o.status <> 'v'
      AND o.date_entered
      BETWEEN @startdate AND DATEADD(ms, -3, DATEADD(dd, DATEDIFF(dd, 0, @enddate) + 1, 0))
      -- and o.hold_reason = isnull((select top 1 value_str from config where flag = 'CR_UPLOAD_HOLD_RES'),'xxx')
      AND EXISTS
(
    SELECT 1
    FROM ord_list ol
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
    FramesRMA
)
SELECT DISTINCT
    a.territory_code,
    a.salesperson_code,
    slp.salesperson_name,
    '',
    '',
    '',
    'T',
    '',
    '',
    '',
    '',
    '',
    0,
    0,
    0

FROM armaster (NOLOCK) a
    INNER JOIN #territory t
        ON t.territory = a.territory_code
    INNER JOIN arsalesp slp (NOLOCK)
        ON slp.salesperson_code = a.salesperson_code
WHERE a.territory_code IS NOT NULL
      AND a.salesperson_code <> 'smithma'
      AND a.status_type = 1;

-- active accounts only


-- select * from #temp 

-- Final Select 

SELECT ISNULL(cust_code, '') cust_code,
       ship_to = ISNULL(#temp.ship_to, ''),
       ship_To_door = CASE
                          WHEN ca.door = 0 THEN
                              ''
                          ELSE
                              ISNULL(#temp.ship_to, '')
                      END,
       ship_to_name,
       salesperson,
       MAX(ISNULL(#temp.salesperson_name, salesperson)) salesperson_name,
       Territory,
       dbo.calculate_region_fn(Territory) region, -- 10/31/2013
       SUM(total_amt_order) total_amt_order,
       SUM(total_discount) total_discount,
       SUM(total_tax) total_tax,
       SUM(freight) freight,
       SUM(qty_ordered) qty_ordered,
       SUM(qty_shipped) qty_shipped,
       SUM(total_invoice) total_invoice,
       SUM(FramesOrdered) FramesOrdered,
       SUM(FramesShipped) FramesShipped,
       SUM(FramesRMA) FramesRMA
--,Qual_order = case when ((isnull(framesordered,0) - isnull(framesrma,0)) > 4 
--	and total_amt_order <> 0.0
--	and date_sch_ship between @startdate and @enddate 
--	and isnull(date_shipped,@enddate) <= @enddate) then 1 
--	when source = 't' then 1 
--	-- when framesrma <> 0 then 1
--	else 0 end

INTO #finalselect

FROM #temp
    LEFT OUTER JOIN CVO_armaster_all ca (NOLOCK)
        ON ca.customer_code = #temp.cust_code
           AND ca.ship_to = #temp.ship_to
    LEFT OUTER JOIN arsalesp slp (NOLOCK)
        ON slp.salesperson_code = #temp.salesperson
WHERE (
          ISNULL(FramesRMA, 0) > 0
          OR ISNULL(FramesOrdered, 0) > 0
          OR source = 'T'
      )
GROUP BY ISNULL(cust_code, ''),
         ISNULL(#temp.ship_to, ''),
         CASE
             WHEN ca.door = 0 THEN
                 ''
             ELSE
                 ISNULL(#temp.ship_to, '')
         END,
         ship_to_name,
         salesperson,
         -- salesperson_name,
         Territory;

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
    SELECT @where = '1 = 1';

IF @detail = 0
    EXEC ('	select
	cust_code,
	ship_to ,
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
	FramesRMA
	From #finalselect where ' + @where);
ELSE
    EXEC ('	select order_no,
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
       back_ord_flag,
       Cust_type,
       HS_order_no,
       source 
	From #temp where ' + @where);
GO
GRANT EXECUTE ON  [dbo].[cvo_ST_Activity_log_sp] TO [public]
GO
