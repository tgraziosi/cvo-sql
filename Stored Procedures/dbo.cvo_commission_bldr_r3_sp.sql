SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


  
-- Author = TG - rewrite of cvo_commission_bldr_vw
-- 12/2015 - allow for multiple commission rates on an order/invoice
-- 10/2016 - add AR Only INvoice/Credits
-- 11/2016 - add installments to show correct category/brand

-- 
/*
	SELECT c.*	From cvo_commission_bldr_r2_vw c 
		WHERE DateShipped between dbo.adm_get_pltdate_f('09/1/2016') AND dbo.adm_get_pltdate_f('09/30/2016') 
		
	exec cvo_commission_bldr_r3_sp null, '09/01/2016', '09/30/2016'
*/

-- order_no = 2645156
-- 46 sec 26052 rec
-- exec cvo_commission_bldr_r3_sp null, '10/01/2016', '10/31/2016'
-- 34 sec 26053 rec
 
--ALTER VIEW [dbo].[cvo_commission_bldr_r3_vw]
--AS	

CREATE PROCEDURE [dbo].[cvo_commission_bldr_r3_sp]
    @terr VARCHAR(1024) = NULL ,
    @sdate DATETIME ,
    @edate DATETIME
AS 

--DECLARE @terr VARCHAR(1024) ,  @sdate DATETIME, @edate DATETIME
--SELECT @terr = NULL, @sdate = '10/1/2016', @edate = '10/31/2016'


    DECLARE @sdatej INT ,
        @edatej INT;

    SELECT  @sdatej = dbo.adm_get_pltdate_f(@sdate) ,
            @edatej = dbo.adm_get_pltdate_f(@edate);


    IF ( OBJECT_ID('tempdb.dbo.#temp') IS NOT NULL )
        DROP TABLE #temp;

	IF ( OBJECT_ID('tempdb.dbo.#report') IS NOT NULL )
        DROP TABLE #report;

    IF ( OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL )
        DROP TABLE #territory;
    CREATE TABLE #territory
        (
          territory VARCHAR(10) ,
          region VARCHAR(3) ,
          r_id INT ,
          t_id INT
        );

    IF @terr IS NULL
        BEGIN
            INSERT  #territory
                    SELECT DISTINCT
                            territory_code ,
                            dbo.calculate_region_fn(territory_code) region ,
                            0 ,
                            0
                    FROM    armaster
                    WHERE   territory_code IS NOT NULL
                    ORDER BY territory_code;
        END;
    ELSE
        BEGIN
            INSERT  INTO #territory
                    ( territory ,
                      region ,
                      r_id ,
                      t_id
                    )
                    SELECT DISTINCT
                            ListItem ,
                            dbo.calculate_region_fn(ListItem) region ,
                            0 ,
                            0
                    FROM    dbo.f_comma_list_to_table(@terr)
                    ORDER BY ListItem;
        END;

    UPDATE  t
    SET     t.r_id = r.r_id ,
            t.t_id = tr.t_id
-- SELECT * 
    FROM    #territory AS t
            JOIN ( SELECT DISTINCT
                            region ,
                            RANK() OVER ( ORDER BY region ) r_id
                   FROM     ( SELECT DISTINCT
                                        region
                              FROM      #territory
                            ) AS r
                 ) AS r ON t.region = r.region
            JOIN ( SELECT DISTINCT
                            territory ,
                            RANK() OVER ( PARTITION BY region ORDER BY territory ) t_id
                   FROM     ( SELECT DISTINCT
                                        region ,
                                        territory
                              FROM      #territory
                            ) AS tr
                 ) AS tr ON t.territory = tr.territory;

    IF ( OBJECT_ID('tempdb.dbo.#clv') IS NOT NULL )
        DROP TABLE #clv;


    SELECT  x.customer_code ,
            x.ship_to_code ,
            CASE WHEN x.order_ctrl_num <> '' THEN x.order_ctrl_num
                 ELSE x.trx_ctrl_num
            END order_ctrl_num ,
            brand = CASE WHEN i.category IN ( 'REVO', 'BT', 'LS' )
                         THEN i.category
                         ELSE 'CORE'
                    END ,
            SUM(a.extended_price) ext_net_sales ,
            SUM(CASE WHEN ISNULL(b.field_34, '') <> 1 THEN a.extended_price
                     ELSE 0
                END) ext_comm_sales
    INTO    #clv
    FROM    artrxcdt a ( NOLOCK )
            JOIN artrx x ( NOLOCK ) ON x.trx_ctrl_num = a.trx_ctrl_num
            LEFT JOIN inv_master i ( NOLOCK ) ON i.part_no = a.item_code
            LEFT JOIN inv_master_add b ( NOLOCK ) ON b.part_no = i.part_no
    WHERE   x.date_applied BETWEEN @sdatej AND @edatej
            AND x.terms_code NOT LIKE 'ins%'
    GROUP BY x.customer_code ,
            x.ship_to_code ,
            CASE WHEN x.order_ctrl_num <> '' THEN x.order_ctrl_num
                 ELSE x.trx_ctrl_num
            END ,
            CASE WHEN i.category IN ( 'REVO', 'BT', 'LS' ) THEN i.category
                 ELSE 'CORE'
            END;
        

    INSERT  INTO #clv
            SELECT  x.customer_code ,
                    x.ship_to_code ,
                    CASE WHEN x.order_ctrl_num <> '' THEN x.order_ctrl_num
                         ELSE x.trx_ctrl_num
                    END ,
                    brand = CASE WHEN i.category IN ( 'REVO', 'BT', 'LS' )
                                 THEN i.category
                                 ELSE 'CORE'
                            END ,
                    SUM(a.extended_price) ext_net_sales ,
                    SUM(CASE WHEN ISNULL(b.field_34, '') <> 1
                             THEN a.extended_price
                             ELSE 0
                        END) ext_comm_sales
            FROM    arinpcdt a ( NOLOCK )
                    JOIN dbo.arinpchg_all AS x ( NOLOCK ) ON x.trx_ctrl_num = a.trx_ctrl_num
                    LEFT JOIN inv_master i ( NOLOCK ) ON i.part_no = a.item_code
                    LEFT JOIN inv_master_add b ( NOLOCK ) ON b.part_no = i.part_no
            WHERE   x.date_applied BETWEEN @sdatej AND @edatej
                    AND x.terms_code NOT LIKE 'ins%'
            GROUP BY x.customer_code ,
                    x.ship_to_code ,
                    CASE WHEN x.order_ctrl_num <> '' THEN x.order_ctrl_num
                         ELSE x.trx_ctrl_num
                    END ,
                    CASE WHEN i.category IN ( 'REVO', 'BT', 'LS' )
                         THEN i.category
                         ELSE 'CORE'
                    END;



    CREATE INDEX idx_clv_ord ON #clv (order_ctrl_num);

    INSERT  INTO #clv
            SELECT  ipa.cust_code ,
                    ipa.ship_to ,
                    CASE WHEN ipa.order_ctrl_num <> '' THEN ipa.order_ctrl_num
                         ELSE ipa.doc_ctrl_num
                    END ,
                    brand = CASE WHEN ipa.category IN ( 'REVO', 'BT', 'LS' )
                                 THEN ipa.category
                                 ELSE 'CORE'
                            END ,
                    SUM(ipa.ExtPrice) ext_net_sales ,
                    SUM(CASE WHEN ISNULL(ipa.no_commission, '') <> 1
                             THEN ipa.ExtPrice
                             ELSE 0
                        END) ext_comm_sales
            FROM    dbo.cvo_item_pricing_analysis AS ipa ( NOLOCK )
            WHERE   ipa.date_applied BETWEEN @sdate AND @edate
                    AND ipa.terms LIKE 'ins%'
            GROUP BY ipa.cust_code ,
                    ipa.ship_to ,
                    CASE WHEN ipa.order_ctrl_num <> '' THEN ipa.order_ctrl_num
                         ELSE ipa.doc_ctrl_num
                    END ,
                    CASE WHEN ipa.category IN ( 'REVO', 'BT', 'LS' )
                         THEN ipa.category
                         ELSE 'CORE'
                    END;


    -- AR POSTED  
    SELECT  x.salesperson_code AS Salesperson ,
            x.territory_code AS Territory ,
            x.customer_code AS Cust_code ,
            x.ship_to_code AS Ship_to ,
            ar.address_name AS Name ,
            oi.order_no AS Order_no ,
            oi.order_ext AS Ext ,
            SUBSTRING(x.doc_ctrl_num, 4, 10) AS Invoice_no ,
            x.date_doc AS InvoiceDate ,
            x.date_applied AS DateShipped ,
            CASE WHEN ISNULL(o.user_category, '') = '' THEN 'ST'
                 ELSE o.user_category
            END AS OrderType ,
            ISNULL(promo_id, '') AS Promo_id ,
            ISNULL(promo_level, '') AS Level ,
            CASE WHEN x.trx_type = 2031 THEN 'Inv'
                 ELSE 'Crd'
            END AS type ,
            Net_Sales = clv.ext_net_sales * CASE WHEN x.trx_type = 2031 THEN 1
                                                 ELSE -1
                                            END ,
            brand = ISNULL(clv.brand, 'CORE') ,
            Amount = ISNULL(clv.ext_comm_sales, 0)
            * CASE WHEN x.trx_type = 2031 THEN 1
                   ELSE -1
              END , -- Issue #982
            [Comm%] = CASE WHEN clv.brand <> ( 'CORE' )
                           THEN dbo.f_get_order_commission_brand(o.order_no,
                                                              o.ext, clv.brand)
                           ELSE CASE WHEN co.commission_pct IS NULL
                                     THEN CASE slp.escalated_commissions
                                            WHEN 1 THEN slp.commission
                                            ELSE p.commission_pct
                                          END
                                     ELSE co.commission_pct
                                END
                      END ,
            [Comm$] = ROUND(ISNULL(clv.ext_comm_sales, 0)
                            * CASE WHEN x.trx_type = 2031 THEN 1
                                   ELSE -1
                              END
                            * CASE WHEN clv.brand <> ( 'CORE' )
                                   THEN dbo.f_get_order_commission_brand(o.order_no,
                                                              o.ext, clv.brand)
                                   ELSE CASE WHEN co.commission_pct IS NULL
                                             THEN CASE slp.escalated_commissions
                                                    WHEN 1 THEN slp.commission
                                                    ELSE p.commission_pct
                                                  END
                                             ELSE co.commission_pct
                                        END
                              END / 100, 2) ,
            CAST('Posted' AS VARCHAR(10)) AS Loc ,
            salesperson_name ,
            ISNULL(CONVERT(VARCHAR, date_of_hire, 101), '') AS HireDate ,
            draw_amount
		-- for testing
		--, clv.brand Brnd
		--, co.commission_pct comm_pct
		--, slp.escalated_commissions
		--, slp.commission
		--, p.commission_pct
    INTO    #report
    FROM    #territory AS t (nolock)
			INNER JOIN artrx x ( NOLOCK ) ON x.territory_code = t.territory
            LEFT OUTER JOIN orders_invoice oi ( NOLOCK ) ON oi.doc_ctrl_num = CASE
                                                              WHEN CHARINDEX('-',
                                                              x.doc_ctrl_num) > 0
                                                              THEN LEFT(x.doc_ctrl_num,
                                                              CHARINDEX('-',
                                                              x.doc_ctrl_num)
                                                              - 1)
                                                              ELSE x.doc_ctrl_num
                                                              END
            LEFT OUTER JOIN CVO_orders_all co ( NOLOCK ) ON co.order_no = oi.order_no
                                                            AND co.ext = oi.order_ext
            LEFT OUTER JOIN orders_all o ( NOLOCK ) ON o.order_no = co.order_no
                                                       AND o.ext = co.ext
            LEFT OUTER JOIN arsalesp slp ( NOLOCK ) ON x.salesperson_code = slp.salesperson_code
            LEFT OUTER JOIN armaster ar ( NOLOCK ) ON x.customer_code = ar.customer_code
                                                      AND x.ship_to_code = ar.ship_to_code
            LEFT OUTER JOIN arcust c ( NOLOCK ) ON c.customer_code = x.customer_code
            LEFT OUTER JOIN cvo_comm_pclass p ( NOLOCK ) ON p.price_code = c.price_code
            LEFT OUTER JOIN #clv clv ON clv.order_ctrl_num = x.order_ctrl_num
                                        AND clv.customer_code = ar.customer_code
                                        AND clv.ship_to_code = ar.ship_to_code
    WHERE   x.trx_type IN ( 2031, 2032 )
            AND x.date_applied BETWEEN @sdatej AND @edatej
            AND x.doc_desc NOT LIKE 'CONVERTED%'
            AND x.doc_desc NOT LIKE '%NONSALES%'
            AND x.doc_ctrl_num NOT LIKE 'CB%'
            AND x.doc_ctrl_num NOT LIKE 'FIN%'
            AND x.terms_code NOT LIKE 'INS%'
            AND x.order_ctrl_num <> ''
            AND x.void_flag = 0
            AND x.posted_flag = 1; 
--AR UNPOSTED  

-- tempdb..sp_help #report


    INSERT  INTO #report
            SELECT  x.salesperson_code ,
                    x.territory_code ,
                    x.customer_code ,
                    x.ship_to_code ,
                    ar.address_name AS Name ,
                    oi.order_no AS Order_no ,
                    oi.order_ext AS Ext ,
                    SUBSTRING(x.doc_ctrl_num, 4, 10) AS Invoice_no ,
                    x.date_doc AS InvoiceDate ,
                    x.date_applied AS DateShipped ,
                    CASE WHEN ISNULL(o.user_category, '') = '' THEN 'ST'
                         ELSE o.user_category
                    END AS OrderType ,
                    ISNULL(promo_id, '') AS Promo_id ,
                    ISNULL(promo_level, '') AS Level ,
                    CASE WHEN x.trx_type = 2031 THEN 'Inv'
                         ELSE 'Crd'
                    END AS type ,
                    clv.ext_net_sales * CASE WHEN x.trx_type = 2031 THEN 1
                                             ELSE -1
                                        END AS Net_Sales ,
                    brand = ISNULL(clv.brand, 'CORE') ,
                    ISNULL(clv.ext_comm_sales, 0)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END AS Amount , -- Issue #982 
                    [Comm%] = CASE WHEN clv.brand <> ( 'CORE' )
                                   THEN dbo.f_get_order_commission_brand(o.order_no,
                                                              o.ext, clv.brand)
                                   ELSE CASE WHEN co.commission_pct IS NULL
                                             THEN CASE slp.escalated_commissions
                                                    WHEN 1 THEN slp.commission
                                                    ELSE p.commission_pct
                                                  END
                                             ELSE co.commission_pct
                                        END
                              END ,
                    [Comm$] = ROUND(ISNULL(clv.ext_comm_sales, 0)
                                    * CASE WHEN x.trx_type = 2031 THEN 1
                                           ELSE -1
                                      END
                                    * CASE WHEN clv.brand <> ( 'CORE' )
                                           THEN dbo.f_get_order_commission_brand(o.order_no,
                                                              o.ext, clv.brand)
                                           ELSE CASE WHEN co.commission_pct IS NULL
                                                     THEN CASE slp.escalated_commissions
                                                            WHEN 1
                                                            THEN slp.commission
                                                            ELSE p.commission_pct
                                                          END
                                                     ELSE co.commission_pct
                                                END
                                      END / 100, 2) ,
                    'UnPosted' AS Loc ,
                    slp.salesperson_name ,
                    ISNULL(CONVERT(VARCHAR, slp.date_of_hire, 101), '') AS HireDate ,
                    draw_amount
				-- for testing
		--, clv.brand brnd
		--, co.commission_pct comm_pct
		--, slp.escalated_commissions
		--, slp.commission
		--, p.commission_pct
            FROM 
			#territory AS t (nolock)
			INNER JOIN dbo.arinpchg_all AS x ( NOLOCK ) ON x.territory_code = t.territory
		            LEFT OUTER JOIN orders_invoice oi ON oi.doc_ctrl_num = CASE
                                                              WHEN CHARINDEX('-',
                                                              x.doc_ctrl_num) > 0
                                                              THEN LEFT(x.doc_ctrl_num,
                                                              CHARINDEX('-',
                                                              x.doc_ctrl_num)
                                                              - 1)
                                                              ELSE x.doc_ctrl_num
                                                              END
                    LEFT OUTER JOIN CVO_orders_all co ON co.order_no = oi.order_no
                                                         AND co.ext = oi.order_ext
                    LEFT OUTER JOIN orders_all (NOLOCK) o ON o.order_no = co.order_no
                                                             AND o.ext = co.ext
                    LEFT JOIN arsalesp (NOLOCK) slp ON x.salesperson_code = slp.salesperson_code
                    LEFT OUTER JOIN armaster (NOLOCK) ar ON x.customer_code = ar.customer_code
                                                            AND x.ship_to_code = ar.ship_to_code
                    LEFT OUTER JOIN arcust c ( NOLOCK ) ON c.customer_code = x.customer_code
                    LEFT OUTER JOIN cvo_comm_pclass p ( NOLOCK ) ON p.price_code = c.price_code
-- LEFT JOIN dbo.cvo_commission_line_sum_up_vw clv ON x.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982
                    LEFT OUTER JOIN #clv clv ON clv.order_ctrl_num = x.order_ctrl_num
                                                AND clv.customer_code = ar.customer_code
                                                AND clv.ship_to_code = ar.ship_to_code
            WHERE   x.trx_type IN ( 2031, 2032 )
                    AND x.date_applied BETWEEN @sdatej AND @edatej
                    AND doc_desc NOT LIKE 'CONVERTED%'
                    AND x.doc_ctrl_num NOT LIKE 'CB%'
                    AND x.doc_ctrl_num NOT LIKE 'FIN%'
                    AND x.doc_desc NOT LIKE '%NONSALES%'
                    AND x.order_ctrl_num <> ''
                    AND x.terms_code NOT LIKE 'INS%';
   
-- AR Only Invoices

    INSERT  INTO #report
            SELECT  x.salesperson_code ,
                    x.territory_code ,
                    x.customer_code customer ,
                    x.ship_to_code ship_to ,
                    ar.address_name AS name ,
                    NULL AS order_no ,
                    NULL AS ext ,
                    SUBSTRING(x.doc_ctrl_num, 4, 10) AS invoice_no ,
                    x.date_doc AS invoicedate ,
                    x.date_applied AS dateshipped ,
                    'ST' AS ordertype ,
                    '' AS promo_id ,
                    '' AS level ,
                    CASE WHEN x.trx_type = 2031 THEN 'Inv'
                         ELSE 'Crd'
                    END AS type ,
                    Net_sales = ISNULL(clv.ext_net_sales, x.amt_net)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END ,
                    brand = ISNULL(clv.brand, 'CORE') ,
                    Amount = ISNULL(clv.ext_comm_sales, x.amt_net)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END ,
                    [Comm%] = 0 ,
                    [Comm$] = 0 ,
                    'AR Posted' AS Loc ,
                    slp.salesperson_name ,
                    ISNULL(CONVERT(VARCHAR, slp.date_of_hire, 101), '') AS HireDate ,
                    slp.draw_amount
            FROM    #territory AS t (nolock)
					INNER JOIN artrx x ( NOLOCK ) ON x.territory_code = t.territory	
                    JOIN artrxcdt d ( NOLOCK ) ON x.trx_ctrl_num = d.trx_ctrl_num
                    JOIN armaster ar ( NOLOCK ) ON ar.customer_code = x.customer_code
                                                   AND ar.ship_to_code = x.ship_to_code
                    JOIN arsalesp slp ( NOLOCK ) ON slp.salesperson_code = x.salesperson_code
                    LEFT OUTER JOIN inv_master i ON i.part_no = d.item_code
                    LEFT OUTER JOIN #clv clv ON clv.order_ctrl_num = x.order_ctrl_num
                                                AND clv.customer_code = ar.customer_code
                                                AND clv.ship_to_code = ar.ship_to_code
            WHERE   NOT EXISTS ( SELECT 1
                                 FROM   orders_invoice oi
                                 WHERE  oi.trx_ctrl_num = x.trx_ctrl_num )
                    AND x.trx_type IN ( 2031, 2032 )
                    AND x.date_applied BETWEEN @sdatej AND @edatej
                    AND x.doc_ctrl_num NOT LIKE 'FIN%'
                    AND x.doc_ctrl_num NOT LIKE 'CB%'
                    AND x.doc_desc NOT LIKE 'converted%'
                    AND x.doc_desc NOT LIKE '%nonsales%'
                    AND x.terms_code NOT LIKE 'ins%'
                    AND ( d.gl_rev_acct LIKE '4000%'
                          OR d.gl_rev_acct LIKE '4500%'
                          OR
     -- d.gl_rev_acct like '4530%' or -- 022514 - tag - add account for debit promo's
                          d.gl_rev_acct LIKE '4600%'
                          OR d.gl_rev_acct LIKE '4999%'
                        )
                    AND x.void_flag <> 1;     --v2.0  

-- *** INSTALLMENT INVOICES
-- AR POSTED  

    INSERT  INTO #report
            SELECT  x.salesperson_code AS Salesperson ,
                    x.territory_code AS Territory ,
                    x.customer_code AS Cust_code ,
                    x.ship_to_code AS Ship_to ,
                    ar.address_name AS Name ,
                    oi.order_no AS Order_no ,
                    oi.order_ext AS Ext ,
                    SUBSTRING(x.doc_ctrl_num, 4, 10) AS Invoice_no ,
                    x.date_doc AS InvoiceDate ,
                    x.date_applied AS DateShipped ,
                    CASE WHEN ISNULL(o.user_category, '') = '' THEN 'ST'
                         ELSE o.user_category
                    END AS OrderType ,
                    ISNULL(promo_id, '') AS Promo_id ,
                    ISNULL(promo_level, '') AS Level ,
                    CASE WHEN x.trx_type = 2031 THEN 'Inv'
                         ELSE 'Crd'
                    END AS type ,
                    Net_Sales = clv.ext_net_sales * ISNULL(ai.installment_prc
                                                           / 100, 1)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END ,
                    brand = ISNULL(clv.brand, 'CORE') ,
                    Amount = ISNULL(clv.ext_comm_sales, 0)
                    * ISNULL(ai.installment_prc / 100, 1)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END , -- Issue #982
                    [Comm%] = CASE WHEN clv.brand <> ( 'CORE' )
                                   THEN dbo.f_get_order_commission_brand(o.order_no,
                                                              o.ext, clv.brand)
                                   ELSE CASE WHEN co.commission_pct IS NULL
                                             THEN CASE slp.escalated_commissions
                                                    WHEN 1 THEN slp.commission
                                                    ELSE p.commission_pct
                                                  END
                                             ELSE co.commission_pct
                                        END
                              END ,
                    [Comm$] = ROUND(ISNULL(clv.ext_comm_sales, 0)
                                    * ISNULL(ai.installment_prc / 100, 1)
                                    * CASE WHEN x.trx_type = 2031 THEN 1
                                           ELSE -1
                                      END
                                    * CASE WHEN clv.brand <> ( 'CORE' )
                                           THEN dbo.f_get_order_commission_brand(o.order_no,
                                                              o.ext, clv.brand)
                                           ELSE CASE WHEN co.commission_pct IS NULL
                                                     THEN CASE slp.escalated_commissions
                                                            WHEN 1
                                                            THEN slp.commission
                                                            ELSE p.commission_pct
                                                          END
                                                     ELSE co.commission_pct
                                                END
                                      END / 100, 2) ,
                    'Posted' AS Loc ,
                    salesperson_name ,
                    ISNULL(CONVERT(VARCHAR, date_of_hire, 101), '') AS HireDate ,
                    draw_amount
		-- for testing
		--, clv.brand Brnd
		--, co.commission_pct comm_pct
		--, slp.escalated_commissions
		--, slp.commission
		--, p.commission_pct
            FROM    #territory AS t (nolock)
					INNER JOIN artrx x ( NOLOCK ) ON x.territory_code = t.territory
                    LEFT OUTER JOIN orders_invoice oi ( NOLOCK ) ON oi.doc_ctrl_num = CASE
                                                              WHEN CHARINDEX('-',
                                                              x.doc_ctrl_num) > 0
                                                              THEN LEFT(x.doc_ctrl_num,
                                                              CHARINDEX('-',
                                                              x.doc_ctrl_num)
                                                              - 1)
                                                              ELSE x.doc_ctrl_num
                                                              END
                    LEFT OUTER JOIN CVO_orders_all co ( NOLOCK ) ON co.order_no = oi.order_no
                                                              AND co.ext = oi.order_ext
                    LEFT OUTER JOIN orders_all o ( NOLOCK ) ON o.order_no = co.order_no
                                                              AND o.ext = co.ext
                    LEFT OUTER JOIN arsalesp slp ( NOLOCK ) ON x.salesperson_code = slp.salesperson_code
                    LEFT OUTER JOIN armaster ar ( NOLOCK ) ON x.customer_code = ar.customer_code
                                                              AND x.ship_to_code = ar.ship_to_code
                    LEFT OUTER JOIN arcust c ( NOLOCK ) ON c.customer_code = x.customer_code
                    LEFT OUTER JOIN cvo_comm_pclass p ( NOLOCK ) ON p.price_code = c.price_code
                    LEFT OUTER JOIN dbo.cvo_artermsd_installment AS ai ON ai.terms_code = x.terms_code
                                                              AND ai.sequence_id = CAST(REPLACE(RIGHT(x.doc_ctrl_num,
                                                              CHARINDEX('-',
                                                              REVERSE(x.doc_ctrl_num))),
                                                              '-', '') AS INT)
                    LEFT OUTER JOIN #clv clv ON clv.order_ctrl_num = x.order_ctrl_num
                                                AND clv.customer_code = ar.customer_code
                                                AND clv.ship_to_code = ar.ship_to_code
            WHERE   x.trx_type IN ( 2031, 2032 )
                    AND x.date_applied BETWEEN @sdatej AND @edatej
                    AND x.doc_desc NOT LIKE 'CONVERTED%'
                    AND x.doc_desc NOT LIKE '%NONSALES%'
                    AND x.doc_ctrl_num NOT LIKE 'CB%'
                    AND x.doc_ctrl_num NOT LIKE 'FIN%'
                    AND x.terms_code LIKE 'INS%'
                    AND x.order_ctrl_num <> ''
                    AND x.void_flag = 0
                    AND x.posted_flag = 1;  

    INSERT  INTO #report
--AR UNPOSTED  
            SELECT  x.salesperson_code ,
                    x.territory_code ,
                    x.customer_code ,
                    x.ship_to_code ,
                    ar.address_name AS Name ,
                    oi.order_no AS Order_no ,
                    oi.order_ext AS Ext ,
                    SUBSTRING(x.doc_ctrl_num, 4, 10) AS Invoice_no ,
                    x.date_doc AS InvoiceDate ,
                    x.date_applied AS DateShipped ,
                    CASE WHEN ISNULL(o.user_category, '') = '' THEN 'ST'
                         ELSE o.user_category
                    END AS OrderType ,
                    ISNULL(promo_id, '') AS Promo_id ,
                    ISNULL(promo_level, '') AS Level ,
                    CASE WHEN x.trx_type = 2031 THEN 'Inv'
                         ELSE 'Crd'
                    END AS type ,
                    clv.ext_net_sales * ISNULL(ai.installment_prc / 100, 1)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END AS Net_Sales ,
                    brand = ISNULL(clv.brand, 'CORE') ,
                    ISNULL(clv.ext_comm_sales, 0) * ISNULL(ai.installment_prc
                                                           / 100, 1)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END AS Amount , -- Issue #982 
                    [Comm%] = CASE WHEN clv.brand <> ( 'CORE' )
                                   THEN dbo.f_get_order_commission_brand(o.order_no,
                                                              o.ext, clv.brand)
                                   ELSE CASE WHEN co.commission_pct IS NULL
                                             THEN CASE slp.escalated_commissions
                                                    WHEN 1 THEN slp.commission
                                                    ELSE p.commission_pct
                                                  END
                                             ELSE co.commission_pct
                                        END
                              END ,
                    [Comm$] = ROUND(ISNULL(clv.ext_comm_sales, 0)
                                    * ISNULL(ai.installment_prc / 100, 1)
                                    * CASE WHEN x.trx_type = 2031 THEN 1
                                           ELSE -1
                                      END
                                    * CASE WHEN clv.brand <> ( 'CORE' )
                                           THEN dbo.f_get_order_commission_brand(o.order_no,
                                                              o.ext, clv.brand)
                                           ELSE CASE WHEN co.commission_pct IS NULL
                                                     THEN CASE slp.escalated_commissions
                                                            WHEN 1
                                                            THEN slp.commission
                                                            ELSE p.commission_pct
                                                          END
                                                     ELSE co.commission_pct
                                                END
                                      END / 100, 2) ,
                    'UnPosted' AS Loc ,
                    slp.salesperson_name ,
                    ISNULL(CONVERT(VARCHAR, slp.date_of_hire, 101), '') AS HireDate ,
                    draw_amount
				-- for testing
		--, clv.brand brnd
		--, co.commission_pct comm_pct
		--, slp.escalated_commissions
		--, slp.commission
		--, p.commission_pct
            FROM    #territory AS t (nolock)
					INNER JOIN dbo.arinpchg AS x ( NOLOCK ) ON x.territory_code = t.territory
                    LEFT OUTER JOIN orders_invoice oi ON oi.doc_ctrl_num = CASE
                                                              WHEN CHARINDEX('-',
                                                              x.doc_ctrl_num) > 0
                                                              THEN LEFT(x.doc_ctrl_num,
                                                              CHARINDEX('-',
                                                              x.doc_ctrl_num)
                                                              - 1)
                                                              ELSE x.doc_ctrl_num
                                                              END
                    LEFT OUTER JOIN CVO_orders_all co ON co.order_no = oi.order_no
                                                         AND co.ext = oi.order_ext
                    LEFT OUTER JOIN orders_all (NOLOCK) o ON o.order_no = co.order_no
                                                             AND o.ext = co.ext
                    LEFT JOIN arsalesp (NOLOCK) slp ON x.salesperson_code = slp.salesperson_code
                    LEFT OUTER JOIN armaster (NOLOCK) ar ON x.customer_code = ar.customer_code
                                                            AND x.ship_to_code = ar.ship_to_code
                    LEFT OUTER JOIN arcust c ( NOLOCK ) ON c.customer_code = x.customer_code
                    LEFT OUTER JOIN cvo_comm_pclass p ( NOLOCK ) ON p.price_code = c.price_code
-- LEFT JOIN dbo.cvo_commission_line_sum_up_vw clv ON x.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982
                    LEFT OUTER JOIN dbo.cvo_artermsd_installment AS ai ON ai.terms_code = x.terms_code
                                                              AND ai.sequence_id = CAST(REPLACE(RIGHT(x.doc_ctrl_num,
                                                              CHARINDEX('-',
                                                              REVERSE(x.doc_ctrl_num))),
                                                              '-', '') AS INT)
                    LEFT OUTER JOIN #clv clv ON clv.order_ctrl_num = x.order_ctrl_num
                                                AND clv.customer_code = ar.customer_code
                                                AND clv.ship_to_code = ar.ship_to_code
            WHERE   x.trx_type IN ( 2031, 2032 )
                    AND x.date_applied BETWEEN @sdatej AND @edatej
                    AND doc_desc NOT LIKE 'CONVERTED%'
                    AND x.doc_ctrl_num NOT LIKE 'CB%'
                    AND x.doc_ctrl_num NOT LIKE 'FIN%'
                    AND x.doc_desc NOT LIKE '%NONSALES%'
                    AND x.order_ctrl_num <> ''
                    AND x.terms_code LIKE 'INS%';


    SELECT  r.Salesperson ,
            r.Territory ,
            r.Cust_code ,
            r.Ship_to ,
            r.Name ,
            r.Order_no ,
            r.Ext ,
            r.Invoice_no ,
            dbo.adm_format_pltdate_f(r.InvoiceDate) InvoiceDate ,
            dbo.adm_format_pltdate_f(r.DateShipped) DateShipped ,
            r.OrderType ,
            r.Promo_id ,
            r.Level ,
            r.type ,
            r.Net_Sales ,
            r.brand ,
            r.Amount ,
            r.[Comm%] Comm_pct,
            r.[Comm$] Comm_amt,
            r.Loc ,
            r.salesperson_name ,
            r.HireDate ,
            r.draw_amount
    FROM    #report AS r;

GO
GRANT EXECUTE ON  [dbo].[cvo_commission_bldr_r3_sp] TO [public]
GO
