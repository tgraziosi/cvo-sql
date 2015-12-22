SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
-- Author = TG - rewrite of cvo_commission_bldr_vw
-- 12/2015 - allow for multiple commission rates on an order/invoice
-- select * From cvo_commission_bldr_r2_vw where DateShipped between dbo.adm_get_pltdate_f('12/1/2015') AND dbo.adm_get_pltdate_f('12/21/2015') -- and brand <> 'core'

-- order_no = 2645156
-- 46 sec 26052 rec
-- select * From cvo_commission_bldr_vw where DateShipped between dbo.adm_get_pltdate_f('12/1/2015') AND dbo.adm_get_pltdate_f('12/21/2015')
-- 34 sec 26053 rec
 
CREATE VIEW [dbo].[cvo_commission_bldr_r2_vw]
AS
    -- AR POSTED  
 SELECT x.salesperson_code AS Salesperson ,
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
        [Comm%] = CASE WHEN clv.brand = 'REVO' THEN 12
                       WHEN clv.brand = 'BT' THEN 15
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
                          END * CASE WHEN clv.brand = 'REVO' THEN 12
                                     WHEN clv.brand = 'BT' THEN 15
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
 FROM   artrx x ( NOLOCK )
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
        LEFT OUTER JOIN -- was cvo_commission_line_sum_up_vw
        ( SELECT    a.trx_ctrl_num ,
                    brand = CASE WHEN i.category IN ( 'REVO', 'BT' )
                                 THEN i.category
                                 ELSE 'CORE'
                            END ,
                    SUM(a.extended_price) ext_net_sales ,
                    SUM(CASE WHEN ISNULL(b.field_34, '') <> 1
                             THEN a.extended_price
                             ELSE 0
                        END) ext_comm_sales
          FROM      artrxcdt a ( NOLOCK )
                    LEFT JOIN inv_master i ( NOLOCK ) ON i.part_no = a.item_code
                    LEFT JOIN inv_master_add b ( NOLOCK ) ON b.part_no = i.part_no
          GROUP BY  CASE WHEN i.category IN ( 'REVO', 'BT' ) THEN i.category
                         ELSE 'CORE'
                    END ,
                    a.trx_ctrl_num
        ) clv ON x.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982
 WHERE  x.trx_type IN ( 2031, 2032 )
        AND x.doc_desc NOT LIKE 'CONVERTED%'
        AND x.doc_desc NOT LIKE '%NONSALES%'
        AND x.doc_ctrl_num NOT LIKE 'CB%'
        AND x.doc_ctrl_num NOT LIKE 'FIN%'
        AND x.order_ctrl_num <> ''
        AND x.void_flag = 0
        AND x.posted_flag = 1  
 
--UNION ALL
---- ARPOSTED SPECIAL DEBIT PROMO CREDITS
--SELECT  
--o.salesperson 
--,o.ship_to_region territory
--,ar.customer_code cust_code 
--,'' AS Ship_to
--,ar.address_name Name
--,dp.order_no    
--,dp.ext
--,SUBSTRING(arx.doc_ctrl_num,4,8) Invoice_no
--,art.Date_entered AS InvoiceDate  --**--**--**
--,art.Date_entered AS DateShipped  --**--**--**
--,o.user_category OrderType
--,dh.debit_promo_id promo_id
--,dh.debit_promo_level promo_level                    
--,'Crd' AS Type
--, SUM(dp.credit_amount)* -1 AS Net_sales
--,SUM(dp.credit_amount)*-1 AS Amount
--,CASE WHEN co.commission_pct IS NULL THEN   
--  CASE slp.ESCALATED_COMMISSIONS WHEN 1 THEN slp.COMMISSION ELSE (SELECT COMMISSION_PCT   
--                  FROM cvo_comm_pclass (NOLOCK) XX   
--                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
--                  AND YY.CUSTOMER_CODE = ar.CUSTOMER_CODE  
--                  AND YY.ADDRESS_TYPE=0) END  
--   ELSE co.commission_pct END AS 'Comm%'
--,CASE art.trx_type WHEN '2031' THEN ((ISNULL(clv.extended_total,0)) * ((CASE WHEN co.commission_pct IS NULL THEN -- Issue #982  
--  CASE slp.ESCALATED_COMMISSIONS WHEN 1 THEN slp.COMMISSION ELSE (SELECT COMMISSION_PCT   
--                  FROM cvo_comm_pclass (NOLOCK) XX   
--                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
--                  AND YY.CUSTOMER_CODE = ar.CUSTOMER_CODE  
--                  AND YY.ADDRESS_TYPE=0) END ELSE co.commission_pct END) /100))  
--    ELSE ((ISNULL(clv.extended_total,0)) * -1) * ((CASE WHEN co.commission_pct IS NULL THEN  -- Issue #982
--  CASE slp.ESCALATED_COMMISSIONS WHEN 1 THEN slp.COMMISSION ELSE (SELECT COMMISSION_PCT   
--                  FROM cvo_comm_pclass (NOLOCK) XX   
--                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
--                  AND YY.CUSTOMER_CODE = ar.CUSTOMER_CODE  
--                  AND YY.ADDRESS_TYPE=0) END ELSE co.commission_pct END) /100)  
--    END AS Comm$  
--,'Posted' AS Loc
--,salesperson_name   
--,ISNULL(CONVERT(VARCHAR,date_of_hire,101), '' ) AS HireDate
--,draw_amount  
--FROM 
--cvo_debit_promo_customer_det dp
--JOIN cvo_orders_all o2 ON dp.order_no=co.order_no AND dp.ext=co.ext
--INNER JOIN ord_list ol ON ol.order_no = dp.order_no AND ol.order_ext = dp.ext AND ol.line_no = dp.line_no
--INNER JOIN cvo_ord_list col ON col.order_no = dp.order_no AND col.order_ext = dp.ext AND col.line_no = dp.line_no
--INNER JOIN orders o ON o.order_no = ol.order_no AND o.ext = ol.order_ext
--INNER JOIN armaster ar ON ar.customer_code = o.cust_code AND ar.ship_To_code = o.ship_to
--INNER JOIN inv_master i ON i.part_no = ol.part_no
--INNER JOIN inv_master_add ia ON ia.part_no = ol.part_no
--LEFT OUTER JOIN artrxcdt arx ON dp.trx_ctrl_num = arx.trx_ctrl_num
--JOIN artrx art ON arx.doc_ctrl_num=art.doc_ctrl_num
--LEFT JOIN arsalesp (NOLOCK) slp ON art.salesperson_code = slp.salesperson_code  
--INNER JOIN cvo_debit_promo_customer_hdr dh ON dh.hdr_rec_id = dp.hdr_rec_id
--JOIN dbo.cvo_commission_line_sum_vw clv ON art.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982

--WHERE arx.gl_rev_acct LIKE '4530%' 
--GROUP BY o.salesperson ,o.ship_to_region,ar.customer_code,ar.address_name,dp.order_no,dp.ext,arx.doc_ctrl_num,art.date_entered
--,o.user_category,co.commission_pct,slp.ESCALATED_COMMISSIONS,slp.commission,art.trx_type,clv.extended_total,slp.salesperson_name
--,slp.date_of_hire,slp.draw_amount,dh.debit_promo_id,dh.debit_promo_level      
 UNION ALL  
--AR UNPOSTED  
 SELECT x.salesperson_code ,
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
        ISNULL(clv.ext_comm_sales, 0) * CASE WHEN x.trx_type = 2031 THEN 1
                                             ELSE -1
                                        END AS Amount , -- Issue #982 
        [Comm%] = CASE WHEN clv.brand = 'REVO' THEN 12
                       WHEN clv.brand = 'BT' THEN 15
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
                          END * CASE WHEN clv.brand = 'REVO' THEN 12
                                     WHEN clv.brand = 'BT' THEN 15
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
 FROM   arinpchg x ( NOLOCK )
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
        LEFT OUTER JOIN ( SELECT    a.trx_ctrl_num ,
                                    brand = CASE WHEN i.category IN ( 'REVO',
                                                              'BT' )
                                                 THEN i.category
                                                 ELSE 'CORE'
                                            END ,
                                    SUM(a.extended_price) ext_net_sales ,
                                    SUM(CASE WHEN ISNULL(b.field_34, '') <> 1
                                             THEN a.extended_price
                                             ELSE 0
                                        END) ext_comm_sales
                          FROM      arinpcdt a ( NOLOCK )
                                    LEFT JOIN inv_master i ( NOLOCK ) ON i.part_no = a.item_code
                                    LEFT JOIN inv_master_add b ( NOLOCK ) ON b.part_no = i.part_no
                          GROUP BY  CASE WHEN i.category IN ( 'REVO', 'BT' )
                                         THEN i.category
                                         ELSE 'CORE'
                                    END ,
                                    a.trx_ctrl_num
                        ) clv ON x.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982
 WHERE  x.trx_type IN ( 2031, 2032 )
        AND doc_desc NOT LIKE 'CONVERTED%'
        AND x.doc_ctrl_num NOT LIKE 'CB%'
        AND x.doc_ctrl_num NOT LIKE 'FIN%'
        AND x.doc_desc NOT LIKE '%NONSALES%'
        AND x.order_ctrl_num <> '';
   












GO
