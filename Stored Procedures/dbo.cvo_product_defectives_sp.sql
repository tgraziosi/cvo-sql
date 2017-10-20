SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
select * from cvo_product_defectives_vw where brand = 'bcbg'
exec cvo_product_defectives_sp @brand=N'as', @vendor=N'actgrou',
@datefrom=N'07/01/2017 00:00', @dateto=N'12/31/2017 23:59'

exec cvo_product_defectives_sp '6/1/2017', '12/31/2017'

*/


CREATE PROCEDURE [dbo].[cvo_product_defectives_sp]
    --@brand varchar(1000),
    --@vendor varchar(1000),
    @DateFrom DATETIME ,
    @DateTo DATETIME

AS

    --declare @datefrom datetime
    --declare @dateto datetime
    --set @datefrom = '10/1/2012'
    --set @dateto = '12/31/2012'

    DECLARE @JDateFrom INT;
    DECLARE @JDateto INT;

    SET @JDateFrom = dbo.adm_get_pltdate_f(@DateFrom);
    SET @JDateto = dbo.adm_get_pltdate_f(@DateTo);

    --select @jdatefrom, @jdateto, @brand, @vendor, @datefrom, @dateto

    -- credits and sales first 

    SELECT i.vendor ,
           ap.address_name ,
           i.part_no ,
           i.category AS Brand ,
           ia.field_2 AS Model ,
           ia.field_28 AS POMDate ,
           i.type_code ,
           CONVERT(
               DATETIME ,
               DATEADD(d, ar.date_applied - 711858, '1/1/1950'),
               101) AS ShipDate ,
           a.return_code ,
           ISNULL((   SELECT return_desc
                      FROM   po_retcode p ( NOLOCK )
                      WHERE  a.return_code = p.return_code ) ,
                  'Sales') AS reason ,
           a.cr_shipped AS Qty_ret ,
           CASE WHEN LEFT(a.return_code, 2) = '04' THEN cr_shipped
                ELSE 0
           END AS qty_def ,
           a.cost ,
           CAST(( a.cr_shipped * a.cost ) AS DECIMAL(20, 8)) AS ext_cost_ret ,
           CASE WHEN LEFT(a.return_code, 2) = '04' THEN
                    CAST(( a.cr_shipped * a.cost ) AS DECIMAL(20, 8))
                ELSE 0
           END AS ext_cost_def ,
           0 AS rct_qty_hist ,
           CASE WHEN LEFT(b.user_category, 2) = 'rx' THEN shipped
                ELSE 0
           END AS Sales_rx_qty_hist ,
           CASE WHEN LEFT(b.user_category, 2) <> 'rx' THEN shipped
                ELSE 0
           END AS Sales_st_qty_hist ,
           a.order_no ,
           a.order_ext

    INTO   #temp

    FROM   ord_list a ( NOLOCK )
           INNER JOIN orders b ( NOLOCK ) ON a.order_no = b.order_no
                                             AND a.order_ext = b.ext
           INNER JOIN inv_master i ( NOLOCK ) ON a.part_no = i.part_no
           INNER JOIN inv_master_add ia ( NOLOCK ) ON i.part_no = ia.part_no
           LEFT OUTER JOIN apmaster ap ( NOLOCK ) ON i.vendor = ap.vendor_code
           INNER JOIN orders_invoice oi ON b.order_no = oi.order_no
                                           AND b.ext = oi.order_ext
           INNER JOIN artrx ar ON oi.trx_ctrl_num = ar.trx_ctrl_num
    WHERE  i.type_code IN ( 'frame', 'sun', 'parts' )
			AND b.type = 'I'
           AND b.status = 't'
		   and NOT (b.user_category LIKE '%RB')
           AND (   a.cr_shipped > 0
                   OR a.shipped > 0 )
           AND EXISTS (   SELECT *
                          FROM   inv_tran ( NOLOCK )
                          WHERE  a.order_no = tran_no
                                 AND a.order_ext = tran_ext
                                 AND a.line_no = tran_line )
           --and i.category in (@brand) 
           --and i.vendor = @vendor
           AND ( ar.date_applied
           BETWEEN @JDateFrom AND @JDateto );

INSERT INTO #temp	
    SELECT i.vendor ,
           ap.address_name ,
           i.part_no ,
           i.category AS Brand ,
           ia.field_2 AS Model ,
           ia.field_28 AS POMDate ,
           i.type_code ,
           CONVERT(
               DATETIME ,
               DATEADD(d, ar.date_applied - 711858, '1/1/1950'),
               101) AS ShipDate ,
           a.return_code ,
           ISNULL((   SELECT return_desc
                      FROM   po_retcode p ( NOLOCK )
                      WHERE  a.return_code = p.return_code ) ,
                  'Sales') AS reason ,
           a.cr_shipped AS Qty_ret ,
           CASE WHEN LEFT(a.return_code, 2) = '04' THEN cr_shipped
                ELSE 0
           END AS qty_def ,
           a.cost ,
           CAST(( a.cr_shipped * a.cost ) AS DECIMAL(20, 8)) AS ext_cost_ret ,
           CASE WHEN LEFT(a.return_code, 2) = '04' THEN
                    CAST(( a.cr_shipped * a.cost ) AS DECIMAL(20, 8))
                ELSE 0
           END AS ext_cost_def ,
           0 AS rct_qty_hist ,
           CASE WHEN LEFT(b.user_category, 2) = 'rx' THEN shipped
                ELSE 0
           END AS Sales_rx_qty_hist ,
           CASE WHEN LEFT(b.user_category, 2) <> 'rx' THEN shipped
                ELSE 0
           END AS Sales_st_qty_hist ,
           a.order_no ,
           a.order_ext

    FROM   ord_list a ( NOLOCK )
           INNER JOIN orders b ( NOLOCK ) ON a.order_no = b.order_no
                                             AND a.order_ext = b.ext
           INNER JOIN inv_master i ( NOLOCK ) ON a.part_no = i.part_no
           INNER JOIN inv_master_add ia ( NOLOCK ) ON i.part_no = ia.part_no
           LEFT OUTER JOIN apmaster ap ( NOLOCK ) ON i.vendor = ap.vendor_code
           INNER JOIN orders_invoice oi ON b.order_no = oi.order_no
                                           AND b.ext = oi.order_ext
           INNER JOIN artrx ar ON oi.trx_ctrl_num = ar.trx_ctrl_num
    WHERE  i.type_code IN ( 'frame', 'sun', 'parts' )
           AND b.status = 't'
		   AND b.type = 'c'
		   and NOT (b.user_category LIKE '%RB')
           AND (   a.cr_shipped > 0
                   OR a.shipped > 0 )
           --AND EXISTS (   SELECT *
           --               FROM   inv_tran ( NOLOCK )
           --               WHERE  a.order_no = tran_no
           --                      AND a.order_ext = tran_ext
           --                      AND a.line_no = tran_line )
           --and i.category in (@brand) 
           --and i.vendor = @vendor
           AND ( ar.date_applied
           BETWEEN @JDateFrom AND @JDateto );

	-- unposted orders and returns
    INSERT INTO #temp
                SELECT i.vendor ,
                       ap.address_name ,
                       i.part_no ,
                       i.category AS Brand ,
                       ia.field_2 AS Model ,
                       ia.field_28 AS pomdate ,
                       i.type_code ,
                       CONVERT(
                           VARCHAR ,
                           dbo.adm_format_pltdate_f(ar.date_applied),
                           101) AS ShipDate ,
                       a.return_code ,
                       ISNULL(
                       (   SELECT return_desc
                           FROM   po_retcode p ( NOLOCK )
                           WHERE  a.return_code = p.return_code ) ,
                       'Sales') AS reason ,
                       cr_shipped AS Qty_ret ,
                       CASE WHEN LEFT(a.return_code, 2) = '04' THEN
                                cr_shipped
                            ELSE 0
                       END AS qty_def ,
                       a.cost ,
                       CAST(( a.cr_shipped * a.cost ) AS DECIMAL(20, 8)) AS ext_cost_ret ,
                       CASE WHEN LEFT(a.return_code, 2) = '04' THEN
                                CAST(( a.cr_shipped * a.cost ) AS DECIMAL(20, 8))
                            ELSE 0
                       END AS ext_cost_def ,
                       0 AS rct_qty_hist ,
                       CASE WHEN LEFT(b.user_category, 2) = 'rx' THEN shipped
                            ELSE 0
                       END AS Sales_rx_qty_hist ,
                       CASE WHEN LEFT(b.user_category, 2) <> 'rx' THEN
                                shipped
                            ELSE 0
                       END AS Sales_st_qty_hist ,
                       a.order_no ,
                       a.order_ext
                FROM   ord_list a ( NOLOCK )
                       INNER JOIN orders b ( NOLOCK ) ON a.order_no = b.order_no
                                                         AND a.order_ext = b.ext
                       INNER JOIN inv_master i ( NOLOCK ) ON a.part_no = i.part_no
                       INNER JOIN inv_master_add ia ( NOLOCK ) ON i.part_no = ia.part_no
                       LEFT OUTER JOIN apmaster ap ( NOLOCK ) ON i.vendor = ap.vendor_code
                       INNER JOIN orders_invoice oi ON b.order_no = oi.order_no
                                                       AND b.ext = oi.order_ext
                       INNER JOIN arinpchg ar ON oi.trx_ctrl_num = ar.trx_ctrl_num

                WHERE  i.type_code IN ( 'frame', 'sun', 'parts' )
                       AND b.status = 't'
					   AND b.type = 'I'
					   and NOT (b.user_category LIKE '%RB')
                       AND (   a.cr_shipped > 0
                               OR a.shipped > 0 )
                       AND EXISTS (   SELECT *
                                      FROM   inv_tran ( NOLOCK )
                                      WHERE  a.order_no = tran_no
                                             AND a.order_ext = tran_ext
                                             AND a.line_no = tran_line )
                       --and i.category = @brand and i.vendor = @vendor
                       AND ( ar.date_applied
                       BETWEEN @JDateFrom AND @JDateto );

	    INSERT INTO #temp
                SELECT i.vendor ,
                       ap.address_name ,
                       i.part_no ,
                       i.category AS Brand ,
                       ia.field_2 AS Model ,
                       ia.field_28 AS pomdate ,
                       i.type_code ,
                       CONVERT(
                           VARCHAR ,
                           dbo.adm_format_pltdate_f(ar.date_applied),
                           101) AS ShipDate ,
                       a.return_code ,
                       ISNULL(
                       (   SELECT return_desc
                           FROM   po_retcode p ( NOLOCK )
                           WHERE  a.return_code = p.return_code ) ,
                       'Sales') AS reason ,
                       cr_shipped AS Qty_ret ,
                       CASE WHEN LEFT(a.return_code, 2) = '04' THEN
                                cr_shipped
                            ELSE 0
                       END AS qty_def ,
                       a.cost ,
                       CAST(( a.cr_shipped * a.cost ) AS DECIMAL(20, 8)) AS ext_cost_ret ,
                       CASE WHEN LEFT(a.return_code, 2) = '04' THEN
                                CAST(( a.cr_shipped * a.cost ) AS DECIMAL(20, 8))
                            ELSE 0
                       END AS ext_cost_def ,
                       0 AS rct_qty_hist ,
                       CASE WHEN LEFT(b.user_category, 2) = 'rx' THEN shipped
                            ELSE 0
                       END AS Sales_rx_qty_hist ,
                       CASE WHEN LEFT(b.user_category, 2) <> 'rx' THEN
                                shipped
                            ELSE 0
                       END AS Sales_st_qty_hist ,
                       a.order_no ,
                       a.order_ext
                FROM   ord_list a ( NOLOCK )
                       INNER JOIN orders b ( NOLOCK ) ON a.order_no = b.order_no
                                                         AND a.order_ext = b.ext
                       INNER JOIN inv_master i ( NOLOCK ) ON a.part_no = i.part_no
                       INNER JOIN inv_master_add ia ( NOLOCK ) ON i.part_no = ia.part_no
                       LEFT OUTER JOIN apmaster ap ( NOLOCK ) ON i.vendor = ap.vendor_code
                       INNER JOIN orders_invoice oi ON b.order_no = oi.order_no
                                                       AND b.ext = oi.order_ext
                       INNER JOIN arinpchg ar ON oi.trx_ctrl_num = ar.trx_ctrl_num

                WHERE  i.type_code IN ( 'frame', 'sun', 'parts' )
                       AND b.status = 't'
					   AND b.type = 'C'
					   and NOT (b.user_category LIKE '%RB')
                       AND (   a.cr_shipped > 0
                               OR a.shipped > 0 )
                       --AND EXISTS (   SELECT *
                       --               FROM   inv_tran ( NOLOCK )
                       --               WHERE  a.order_no = tran_no
                       --                      AND a.order_ext = tran_ext
                       --                      AND a.line_no = tran_line )
                       --and i.category = @brand and i.vendor = @vendor
                       AND ( ar.date_applied
                       BETWEEN @JDateFrom AND @JDateto );

	-- pre-epicor history (<2012)
    INSERT INTO #temp
                SELECT i.vendor ,
                       ap.address_name ,
                       i.part_no ,
                       i.category AS Brand ,
                       ia.field_2 AS Model ,
                       ia.field_28 AS pomdate ,
                       i.type_code ,
                       b.date_shipped AS ShipDate ,
                       ISNULL(a.return_code, '06-13') ,
                       ISNULL(
                       (   SELECT return_desc
                           FROM   po_retcode p ( NOLOCK )
                           WHERE  p.return_code = ISNULL(
                                                      a.return_code, '06-13')) ,
                       'Sales') AS reason ,
                       cr_shipped AS Qty_ret ,
                       CASE WHEN LEFT(ISNULL(a.return_code, '06-13'), 2) = '04' THEN
                                cr_shipped
                            ELSE 0
                       END AS qty_def ,
                       a.cost ,
                       CAST(( a.cr_shipped * a.cost ) AS DECIMAL(20, 8)) AS ext_cost_ret ,
                       CASE WHEN LEFT(a.return_code, 2) = '04' THEN
                                CAST(( a.cr_shipped * a.cost ) AS DECIMAL(20, 8))
                            ELSE 0
                       END AS ext_cost_def ,
                       0 AS rct_qty_hist ,
                       CASE WHEN LEFT(b.user_category, 2) = 'rx' THEN shipped
                            ELSE 0
                       END AS Sales_rx_qty_hist ,
                       CASE WHEN LEFT(b.user_category, 2) <> 'rx' THEN
                                shipped
                            ELSE 0
                       END AS Sales_st_qty_hist ,
                       a.order_no ,
                       a.order_ext
                FROM   cvo_ord_list_hist a ( NOLOCK )
                       INNER JOIN CVO_orders_all_Hist b ( NOLOCK ) ON a.order_no = b.order_no
                                                                      AND a.order_ext = b.ext
                       INNER JOIN inv_master i ( NOLOCK ) ON a.part_no = i.part_no
                       INNER JOIN inv_master_add ia ( NOLOCK ) ON i.part_no = ia.part_no
                       LEFT OUTER JOIN apmaster ap ( NOLOCK ) ON i.vendor = ap.vendor_code
                WHERE  i.type_code IN ( 'frame', 'sun', 'parts' )
                       AND b.status = 't'
                       AND (   a.cr_shipped > 0
                               OR a.shipped > 0 )
                       --and i.category = @brand and i.vendor = @vendor
                       AND ( b.date_shipped
                       BETWEEN @DateFrom AND @DateTo );



    --- receipts
    INSERT INTO #temp
                SELECT i.vendor ,
                       ap.address_name ,
                       i.part_no ,
                       i.category AS Brand ,
                       ia.field_2 AS Model ,
                       ia.field_28 AS POMDate ,
                       i.type_code ,
                       CONVERT(VARCHAR, recv_date, 101) AS ShipDate ,
                       '' AS return_code ,
                       reason = 'Receipt' ,
                       0 AS Qty_ret ,
                       0 AS qty_def ,
                       0 AS cost ,
                       0 AS ext_cost_ret ,
                       0 AS ext_cost_def ,
                       SUM(a.quantity) AS rct_qty_hist ,
                       0 AS Sales_rx_qty_hist ,
                       0 AS Sales_st_qty_hist ,
                       a.po_no AS order_no ,
                       0 AS order_ext
                --into #tag_test
                FROM   receipts a ( NOLOCK )
                       INNER JOIN inv_master i ( NOLOCK ) ON a.part_no = i.part_no
                       INNER JOIN inv_master_add ia ( NOLOCK ) ON i.part_no = ia.part_no
                       LEFT OUTER JOIN apmaster ap ( NOLOCK ) ON i.vendor = ap.vendor_code
                WHERE  i.type_code IN ( 'frame', 'sun', 'parts' )
                       AND a.quantity > 0
                       --and i.category = @brand and i.vendor = @vendor
                       AND ( a.recv_date
                       BETWEEN @DateFrom AND @DateTo )
				GROUP BY CONVERT(VARCHAR, recv_date, 101) ,
                         i.vendor ,
                         ap.address_name ,
                         i.part_no ,
                         i.category ,
                         ia.field_2 ,
                         ia.field_28 ,
                         i.type_code ,
                         a.po_no

    ;

    SELECT   vendor ,
             address_name ,
             cte.part_no ,
             Brand ,
             Model ,
             POMDate ,
             type_code ,
             ISNULL(return_code, '') return_code ,
             reason ,
             SUM(Qty_ret) qty_ret ,
             SUM(qty_def) QTY_DEF ,
             cost ,
             SUM(ext_cost_ret) ext_cost_Ret ,
             SUM(ext_cost_def) EXT_COST_DEF ,
             SUM(rct_qty_hist) rct_qty_hist ,
             SUM(Sales_rx_qty_hist) Sales_rx_qty_hist ,
             SUM(Sales_st_qty_hist) Sales_st_qty_hist
    FROM     (   SELECT DISTINCT part_no
                 FROM   #temp
                 WHERE  qty_def <> 0 ) cte
             JOIN #temp ON cte.part_no = #temp.part_no
    GROUP BY vendor ,
             address_name ,
             cte.part_no ,
             Brand ,
             Model ,
             POMDate ,
             type_code ,
             return_code ,
             reason ,
             cost;




GO
