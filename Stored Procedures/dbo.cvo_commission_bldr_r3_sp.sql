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
		WHERE DateShipped between dbo.adm_get_pltdate_f('02/1/2017') AND dbo.adm_get_pltdate_f('02/28/2017') 
		and territory = 50532
		
	exec cvo_commission_bldr_r3_sp '30308', '12/01/2017','12/31/2017'
*/

-- order_no = 2645156
-- 46 sec 26052 rec
-- exec cvo_commission_bldr_r3_sp '40454,50505', '01/01/2017', '01/31/2017'
-- 34 sec 26053 rec
 
--ALTER VIEW [dbo].[cvo_commission_bldr_r3_vw]
--AS	

CREATE PROCEDURE [dbo].[cvo_commission_bldr_r3_sp]
    @terr VARCHAR(1024) = NULL ,
    @sdate DATETIME ,
    @edate DATETIME
AS 

	SET NOCOUNT ON;

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
                    ROUND(SUM(ipa.ExtPrice),2) ext_net_sales ,
                    ROUND(SUM(CASE WHEN ISNULL(ipa.no_commission, '') <> 1
                             THEN ipa.ExtPrice
                             ELSE 0
                        END), 2) ext_comm_sales
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
            CASE WHEN x.territory_code = slp.territory_code THEN draw_amount ELSE 0 END draw_amount -- draw counts for 'home' territory only
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
                    CASE WHEN x.territory_code = slp.territory_code THEN draw_amount ELSE 0 END draw_amount
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
                    CASE WHEN x.territory_code = slp.territory_code THEN slp.draw_amount ELSE 0 END draw_amount
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
                    Net_Sales = ROUND(clv.ext_net_sales * ISNULL(CAST(ai.installment_prc AS DECIMAL(20,8))
                                                           / 100.00, 1)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END , 2),
                    brand = ISNULL(clv.brand, 'CORE') ,
                    Amount = ROUND(ISNULL(clv.ext_comm_sales, 0)
                    * ISNULL(CAST(ai.installment_prc AS DECIMAL(20,8)) / 100.00, 1)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END, 2) , -- Issue #982
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
                                    * ISNULL(ai.installment_prc / 100.00, 1)
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
                                      END / 100.00, 2) ,
                    'Posted' AS Loc ,
                    salesperson_name ,
                    ISNULL(CONVERT(VARCHAR, date_of_hire, 101), '') AS HireDate ,
                    CASE WHEN x.territory_code = slp.territory_code THEN draw_amount ELSE 0 END draw_amount
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
                    ROUND(clv.ext_net_sales * ISNULL(CAST(ai.installment_prc AS DECIMAL(20,8)) / 100, 1)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END , 2) AS Net_Sales ,
                    brand = ISNULL(clv.brand, 'CORE') ,
                    ROUND( ISNULL(clv.ext_comm_sales, 0) * ISNULL(CAST(ai.installment_prc AS DECIMAL(20,8))
                                                           / 100, 1)
                    * CASE WHEN x.trx_type = 2031 THEN 1
                           ELSE -1
                      END ,2)
					  AS Amount , -- Issue #982 
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
                                    * ISNULL(CAST(ai.installment_prc AS DECIMAL(20,8)) / 100, 1)
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
                    CASE WHEN x.territory_code = slp.territory_code THEN draw_amount ELSE 0 END draw_amount
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


INSERT  INTO #report
-- ARPOSTED SPECIAL DEBIT PROMO CREDITS
SELECT  o.salesperson ,
        o.ship_to_region territory ,
        ar.customer_code cust_code ,
        '' AS Ship_to ,
        ar.address_name Name ,
        dp.order_no ,
        dp.ext ,
        SUBSTRING(art.doc_ctrl_num, 4, 8) Invoice_no ,
        art.date_applied AS InvoiceDate  --**--**--**
        ,
        art.date_applied AS DateShipped  --**--**--**
        ,
        o.user_category OrderType ,
        dh.debit_promo_id promo_id ,
        dh.debit_promo_level promo_level ,
        'Crd' AS Type ,
        SUM(dp.credit_amount) * -1 AS Net_sales ,
		brand = 'CORE',
		SUM(dp.credit_amount) * -1 AS Amount ,
		[Comm%] = CASE WHEN o2.commission_pct IS NULL
             THEN CASE t3.escalated_commissions
                    WHEN 1 THEN t3.commission
                    ELSE ( SELECT   commission_pct
                           FROM     cvo_comm_pclass (NOLOCK) XX
                                    JOIN armaster (NOLOCK) YY ON XX.price_code = YY.price_code
                                                              AND YY.customer_code = ar.customer_code
                                                              AND YY.address_type = 0
                         )
                  END
             ELSE o2.commission_pct
        END  ,
		[Comm$] = 
        CASE art.trx_type
          WHEN 2031
          THEN ( ( ISNULL(clv.extended_total, 0) )
                 * ( ( CASE WHEN o2.commission_pct IS NULL
                            THEN -- Issue #982  
                                 CASE t3.escalated_commissions
                                   WHEN 1 THEN t3.commission
                                   ELSE ( SELECT    commission_pct
                                          FROM      cvo_comm_pclass (NOLOCK) XX
                                                    JOIN armaster (NOLOCK) YY ON XX.price_code = YY.price_code
                                                              AND YY.customer_code = ar.customer_code
                                                              AND YY.address_type = 0
                                        )
                                 END
                            ELSE o2.commission_pct
                       END ) / 100 ) )
          ELSE ( ( ISNULL(clv.extended_total, 0) ) * -1 )
               * ( ( CASE WHEN o2.commission_pct IS NULL
                          THEN  -- Issue #982
                               CASE t3.escalated_commissions
                                 WHEN 1 THEN t3.commission
                                 ELSE ( SELECT  commission_pct
                                        FROM    cvo_comm_pclass (NOLOCK) XX
                                                JOIN armaster (NOLOCK) YY ON XX.price_code = YY.price_code
                                                              AND YY.customer_code = ar.customer_code
                                                              AND YY.address_type = 0
                                      )
                               END
                          ELSE o2.commission_pct
                     END ) / 100 )
        END  ,
        'Posted' AS Loc ,
        salesperson_name ,
        ISNULL(CONVERT(VARCHAR, date_of_hire, 101), '') AS HireDate ,
        CASE WHEN o.ship_to_region = t3.territory_code THEN draw_amount ELSE 0 END AS draw_amount
FROM    CVO_debit_promo_customer_det dp
        JOIN CVO_orders_all o2 ON dp.order_no = o2.order_no
                                  AND dp.ext = o2.ext
        INNER JOIN ord_list ol ON ol.order_no = dp.order_no
                                  AND ol.order_ext = dp.ext
                                  AND ol.line_no = dp.line_no
        INNER JOIN CVO_ord_list col ON col.order_no = dp.order_no
                                       AND col.order_ext = dp.ext
                                       AND col.line_no = dp.line_no
        INNER JOIN orders o ON o.order_no = ol.order_no
                               AND o.ext = ol.order_ext
        INNER JOIN armaster ar ON ar.customer_code = o.cust_code
                                  AND ar.ship_to_code = o.ship_to
        INNER JOIN #territory AS t ON t.territory = ar.territory_code
		INNER JOIN inv_master i ON i.part_no = ol.part_no
        INNER JOIN inv_master_add ia ON ia.part_no = ol.part_no
        LEFT OUTER JOIN artrxcdt arx ON dp.trx_ctrl_num = arx.trx_ctrl_num
        JOIN artrx art ON arx.doc_ctrl_num = art.doc_ctrl_num
        LEFT JOIN arsalesp (NOLOCK) t3 ON art.salesperson_code = t3.salesperson_code
        INNER JOIN CVO_debit_promo_customer_hdr dh ON dh.hdr_rec_id = dp.hdr_rec_id
        JOIN dbo.cvo_commission_line_sum_vw clv ON art.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982
WHERE   arx.gl_rev_acct LIKE '4530%'
        AND ARX.date_applied BETWEEN @sdateJ AND @edateJ

GROUP BY o.salesperson ,
        o.ship_to_region ,
        ar.customer_code ,
        ar.address_name ,
        dp.order_no ,
        dp.ext ,
        art.doc_ctrl_num ,
        art.date_applied ,
        o.user_category ,
        o2.commission_pct ,
        t3.escalated_commissions ,
        t3.commission ,
        art.trx_type ,
        clv.extended_total ,
        t3.salesperson_name ,
        t3.date_of_hire ,
        t3.draw_amount ,
		t3.territory_code,
        dh.debit_promo_id ,
        dh.debit_promo_level
		;      


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

			-- 12/20/2017
			CASE WHEN 	1 = ROW_NUMBER() OVER (PARTITION BY r.order_no, r.ext ORDER BY r.order_no, r.ext) 
			THEN ISNULL(o.framesshipped,0) ELSE 0 END  framesshipped,
			CASE WHEN 	1 = ROW_NUMBER() OVER (PARTITION BY r.order_no, r.ext ORDER BY r.order_no, r.ext) 
			AND ISNULL(r.Promo_id,'') <> '' 	THEN 1 ELSE 0 END  promo_cnt,

            r.type ,
            r.Net_Sales ,
            r.brand ,
            r.Amount ,
            r.[Comm%] Comm_pct,
            r.[Comm$] Comm_amt,
            r.Loc ,
            r.salesperson_name ,
            r.HireDate ,
            r.draw_amount,
			t.Region
		

    FROM    #report AS r
	JOIN #territory AS t ON t.territory = r.Territory
	LEFT OUTER JOIN
	(select ol.order_no, ol.order_ext, SUM(shipped)-sum(cr_shipped) framesshipped
		FROM inv_master i (NOLOCK) 
		JOIN ord_list ol (nolock) ON  ol.part_no = i.part_no
		JOIN orders o (NOLOCK) ON o.order_no = ol.order_no AND o.ext = ol.order_ext
		WHERE i.type_code in ('FRAME','SUN')  AND o.date_shipped >= @sdate
		GROUP BY ol.order_no,
                 ol.order_ext
			) o ON r.order_no = o.order_no and r.ext = o.order_ext
			;


GO
GRANT EXECUTE ON  [dbo].[cvo_commission_bldr_r3_sp] TO [public]
GO
