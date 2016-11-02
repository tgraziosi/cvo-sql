SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


  
-- Author = TG - rewrite of cvo_commission_bldr_vw
-- 12/2015 - allow for multiple commission rates on an order/invoice
-- 10/2016 - add AR Only INvoice/Credits

-- 
/*
	SELECT c.*,ar.price_code, ar.price_level
	From cvo_commission_bldr_r3_vw c
	JOIN armaster ar ON ar.customer_code =  c.Cust_code AND ar.ship_to_code = c.Ship_to
	WHERE DateShipped between dbo.adm_get_pltdate_f('09/1/2016') AND dbo.adm_get_pltdate_f('09/30/2016') -- and brand <> 'core'
*/

-- order_no = 2645156
-- 46 sec 26052 rec
-- select * From cvo_commission_bldr_r3_vw where DateShipped between dbo.adm_get_pltdate_f('10/01/2016') AND dbo.adm_get_pltdate_f('10/30/2016') and loc = 'ar posted'
-- 34 sec 26053 rec
 
CREATE VIEW [dbo].[cvo_commission_bldr_r3_vw]
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
        [Comm%] = CASE WHEN clv.brand <> ('CORE') 
					   THEN DBO.f_get_order_commission_brand(O.ORDER_NO,O.EXT,CLV.BRAND)
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
                          END * CASE WHEN clv.brand <> ('CORE') 
			  					     THEN DBO.f_get_order_commission_brand(O.ORDER_NO,O.EXT,CLV.BRAND)
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
                    brand = CASE WHEN i.category IN ( 'REVO', 'BT', 'LS' )
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
          GROUP BY  CASE WHEN i.category IN ( 'REVO', 'BT', 'LS' ) THEN i.category
                         ELSE 'CORE'
                    END ,
                    a.trx_ctrl_num
        ) clv ON x.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982
 WHERE  x.trx_type IN ( 2031, 2032 )
        AND x.doc_desc NOT LIKE 'CONVERTED%'
        AND x.doc_desc NOT LIKE '%NONSALES%'
        AND x.doc_ctrl_num NOT LIKE 'CB%'
        AND x.doc_ctrl_num NOT LIKE 'FIN%'
		AND x.terms_code NOT LIKE 'INS%'
        AND x.order_ctrl_num <> ''
        AND x.void_flag = 0
        AND x.posted_flag = 1   
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
        [Comm%] = CASE WHEN clv.brand <> ('CORE') 
					   THEN DBO.f_get_order_commission_brand(O.ORDER_NO,O.EXT,CLV.BRAND)
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
                          END * CASE WHEN clv.brand <> ('CORE') 
									 THEN DBO.f_get_order_commission_brand(O.ORDER_NO,O.EXT,CLV.BRAND)
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
                                                              'BT', 'LS' )
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
                          GROUP BY  CASE WHEN i.category IN ( 'REVO', 'BT' , 'LS')
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
        AND x.order_ctrl_num <> ''
		AND x.terms_code NOT LIKE 'INS%'
   
-- AR Only Invoices
UNION ALL

select   
x.salesperson_code,
x.territory_code,
x.customer_code customer,
x.ship_to_code ship_to,
ar.address_name as name,
null as order_no,
null as ext,
substring(x.doc_ctrl_num,4,10) as invoice_no,
x.date_doc as invoicedate,
x.date_applied as dateshipped,
'ST' as ordertype,
'' as promo_id,
'' as level,
case when x.trx_type = 2031 then 'Inv' else 'Crd' end as type,
Net_sales = clv.ext_net_sales * case when x.trx_type = 2031 then 1 else -1 end,
brand  = isnull(clv.brand, 'CORE'),
Amount = isnull(clv.ext_comm_sales, 0) * case when x.trx_type = 2031 then 1 else -1 end,
[Comm%] = 0,
[Comm$] = 0,
'AR Posted' AS Loc ,
slp.salesperson_name ,
ISNULL(CONVERT(VARCHAR, slp.date_of_hire, 101), '') AS HireDate ,
slp.draw_amount

from artrx_all x (nolock)  
join artrxcdt d (nolock) on x.trx_ctrl_num = d.trx_ctrl_num  
JOIN armaster ar (nolock) on ar.customer_code = x.customer_code and ar.ship_to_code = x.ship_to_code
JOIN arsalesp slp (NOLOCK) ON slp.salesperson_code = x.salesperson_code

left outer join inv_master i on i.part_no = d.item_code
LEFT OUTER JOIN ( SELECT    a.trx_ctrl_num ,
                                    brand = CASE WHEN i.category IN ( 'REVO',
                                                              'BT', 'LS' )
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
                          GROUP BY  CASE WHEN i.category IN ( 'REVO', 'BT' , 'LS' )
                                         THEN i.category
                                         ELSE 'CORE'
                                    END ,
                                    a.trx_ctrl_num
				) clv ON clv.trx_ctrl_num = x.trx_ctrl_num -- Issue #982
where
not exists(select 1 from orders_invoice oi where oi.trx_ctrl_num =  x.trx_ctrl_num)
and x.trx_type in (2031,2032)  
and x.doc_ctrl_num not like 'FIN%' and x.doc_ctrl_num not like 'CB%'   
and x.doc_desc not like 'converted%' and x.doc_desc not like '%nonsales%' 
and x.terms_code not like 'ins%'
and (d.gl_rev_acct like '4000%' or 
     d.gl_rev_acct like '4500%' or
     -- d.gl_rev_acct like '4530%' or -- 022514 - tag - add account for debit promo's
     d.gl_rev_acct like '4600%' or 
     d.gl_rev_acct like '4999%')  
and x.void_flag <> 1     --v2.0  

-- *** INSTALLMENT INVOICES
-- AR POSTED  
 UNION ALL

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
        [Comm%] = CASE WHEN clv.brand <> ('CORE') 
					   THEN DBO.f_get_order_commission_brand(O.ORDER_NO,O.EXT,CLV.BRAND)
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
                          END * CASE WHEN clv.brand <> ('CORE') 
			  					     THEN DBO.f_get_order_commission_brand(O.ORDER_NO,O.EXT,CLV.BRAND)
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
                    brand = CASE WHEN i.category IN ( 'REVO', 'BT', 'LS' )
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
          GROUP BY  CASE WHEN i.category IN ( 'REVO', 'BT', 'LS' ) THEN i.category
                         ELSE 'CORE'
                    END ,
                    a.trx_ctrl_num
        ) clv ON x.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982
 WHERE  x.trx_type IN ( 2031, 2032 )
        AND x.doc_desc NOT LIKE 'CONVERTED%'
        AND x.doc_desc NOT LIKE '%NONSALES%'
        AND x.doc_ctrl_num NOT LIKE 'CB%'
        AND x.doc_ctrl_num NOT LIKE 'FIN%'
		AND x.terms_code LIKE 'INS%'
        AND x.order_ctrl_num <> ''
        AND x.void_flag = 0
        AND x.posted_flag = 1   
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
        [Comm%] = CASE WHEN clv.brand <> ('CORE') 
					   THEN DBO.f_get_order_commission_brand(O.ORDER_NO,O.EXT,CLV.BRAND)
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
                          END * CASE WHEN clv.brand <> ('CORE') 
									 THEN DBO.f_get_order_commission_brand(O.ORDER_NO,O.EXT,CLV.BRAND)
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
                                                              'BT', 'LS' )
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
                          GROUP BY  CASE WHEN i.category IN ( 'REVO', 'BT' , 'LS')
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
        AND x.order_ctrl_num <> ''
		AND x.terms_code LIKE 'INS%'


















GO
