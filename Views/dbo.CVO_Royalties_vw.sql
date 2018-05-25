SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

--select * From cvo_ord_list where amt_disc <> round(amt_disc,2) and is_amt_disc = 'y'
-- order by order_no desc

/*
select * From cvo_royalties_vw 
  where date_applied between dbo.adm_get_pltdate_f('10/01/2014') 
                         and dbo.adm_get_pltdate_f('10/31/2014')
						 and product_group = 'bcbg' and product_type in ('frame','sun')

                         and order_no = 2293115

                         
select * from cvo_ord_list where order_no = 2053146                   
                         
                         1532295.790000	951926.080000 - db03before
                         1532287.920000	951933.740000 - db02
*/

CREATE VIEW [dbo].[CVO_Royalties_vw]
AS
SELECT orders.order_no,
       orders.ext order_ext,
       ar.doc_ctrl_num Invoice, -- tag 082613
       ol.line_no,
       ol.part_no,
       ISNULL(co.promo_id, ' ') AS promo_id,
       ISNULL(co.promo_level, ' ') AS promo_level,
       arcust.addr_sort1 AS cust_type,
       orders.cust_code,
       arcust.customer_name,
       SUBSTRING(orders.ship_to_region, 1, 2) AS region,
       orders.ship_to_region AS territory,
       ar.territory_code AS ar_territory,
       orders.salesperson,
       orders.user_category AS order_type,
       orders.date_shipped,
       ar.date_applied,
       CASE orders.type
           WHEN 'I' THEN
               'Invoice'
           ELSE
               'Return'
       END AS doc_type,
       inv.category AS product_group,
       inv.type_code AS product_type,
       inva.field_2 AS product_style,
       inva.category_2 AS product_gender,
       CASE inv.obsolete
           WHEN 0 THEN
               'No'
           WHEN 1 THEN
               'Yes'
           ELSE
               ''
       END AS Obsolete,         -- tag 082613
       CASE ISNULL(armaster.country_code, ' ')
           WHEN 'US' THEN
               'Domestic'
           ELSE
               'Intnl'
       END AS dom_intl,
       ISNULL(armaster.country_code, ' ') AS country_code,
       ISNULL(armaster.state, ' ') AS state_code,
       CASE orders.type
           WHEN 'I' THEN
               ol.shipped
           ELSE
       (ol.cr_shipped * -1)
       END AS units_sold,
                                -- use original list price
       CASE orders.type
           WHEN 'I' THEN
               ol.shipped * ISNULL(   CASE
                                          WHEN ol.curr_price > col.orig_list_price THEN
                                              ol.curr_price
                                          WHEN col.orig_list_price > col.list_price THEN
                                              col.orig_list_price
                                          ELSE
                                              col.list_price
                                      END,
                                      0
                                  )
           ELSE
               ol.cr_shipped * ISNULL(   CASE
                                             WHEN ol.curr_price > col.orig_list_price THEN
                                                 ol.curr_price
                                             WHEN col.orig_list_price > col.list_price THEN
                                                 col.orig_list_price
                                             ELSE
                                                 col.list_price
                                         END,
                                         0
                                     ) * -1
       END AS list_price,
                                -- 10/21/2013 - FIX price calculation
                                /* 
CASE orders.type 
WHEN 'I' THEN 
    CASE (ISNULL(COL.is_amt_disc,'n'))
        when 'Y' THEN round((OL.SHIPPED * OL.CURR_PRICE) - 
            (OL.SHIPPED * round(ISNULL(CoL.AMT_DISC,0),2)),2)
       	ELSE
            round((OL.SHIPPED * OL.CURR_PRICE) - 
            ( (OL.SHIPPED * OL.CURR_PRICE) * (ol.discount/ 100.00)),2)
        end       			 
ELSE round(ol.cr_shipped * (ol.curr_price - (ol.curr_price * (ol.discount / 100))) * -1,2)
END as net_amt,
*/
                                -- 110714 - match pricing calc to #1504
       CASE orders.type
           WHEN 'I' THEN
               CASE (ISNULL(col.is_amt_disc, 'n'))
                   WHEN 'Y' THEN
                       ROUND((ol.shipped * ol.curr_price) - (ol.shipped * ROUND(ISNULL(col.amt_disc, 0), 2)), 2)
                   ELSE
                       ROUND((ol.shipped * ol.curr_price) - ((ol.shipped * ol.curr_price) * (ol.discount / 100.00)), 2)
               END -- v10.7
           ELSE
               CASE ol.discount
                   WHEN 0 THEN
                       ol.curr_price * -ol.cr_shipped
                   -- START v11.6
                   ELSE
                       CASE
                           WHEN col.orig_list_price = ol.curr_price THEN
                               -ol.cr_shipped
                               * ROUND(col.orig_list_price - ROUND((col.orig_list_price * ol.discount / 100), 2), 2)
                           ELSE
                               -ol.cr_shipped
                               * ROUND((ol.curr_price - ROUND(ol.curr_price * ol.discount / 100, 2)), 2, 1)
                       END
                   --ELSE ROUND((l.curr_price - ROUND(cv1.amt_disc,2)),2,1) -- v10.7
               -- END v11.6
               END
       END AS net_amt,

                                /*
CASE orders.type 
WHEN 'I' THEN
    case isnull(col.is_amt_disc,'n') 
    when 'y' then 
    round(ol.shipped * IsNull((case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end),0) -  ol.shipped * (ol.curr_price - round(isnull(col.amt_disc,0),2)),2)
    else
    round(ol.shipped * IsNull((case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end),0) - ol.shipped * (ol.curr_price - (ol.curr_price * (ol.discount / 100))),2)
	end
	ELSE round((ol.cr_shipped * IsNull((case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end),0) - (ol.cr_shipped * ol.curr_price - (ol.curr_price * (ol.discount / 100)))) * -1,2)
END as discount_amount,
*/
       CASE
           WHEN ol.curr_price > col.orig_list_price THEN
               0
           ELSE
               CASE orders.type
                   WHEN 'I' THEN
                       CASE ISNULL(col.is_amt_disc, 'n')
                           WHEN 'y' THEN
                               ROUND(
                                        ol.shipped * ISNULL(   (CASE
                                                                    WHEN col.list_price > col.orig_list_price THEN
                                                                        col.list_price
                                                                    ELSE
                                                                        col.orig_list_price
                                                                END
                                                               ),
                                                               0
                                                           ) - ol.shipped
                                        * (ol.curr_price - ROUND(ISNULL(col.amt_disc, 0), 2)),
                                        2
                                    )
                           ELSE
                               ROUND(
                                        ol.shipped * ISNULL(   (CASE
                                                                    WHEN col.list_price > col.orig_list_price THEN
                                                                        col.list_price
                                                                    ELSE
                                                                        col.orig_list_price
                                                                END
                                                               ),
                                                               0
                                                           ) - ol.shipped
                                        * (ol.curr_price - (ol.curr_price * (ol.discount / 100))),
                                        2
                                    )
                       END
                   ELSE
                       CASE ol.discount
                           WHEN 0 THEN
                               -ol.cr_shipped * ((CASE
                                                      WHEN col.list_price > col.orig_list_price THEN
                                                          col.list_price
                                                      ELSE
                                                          col.orig_list_price
                                                  END
                                                 ) - ol.curr_price
                                                )
                           -- START v11.6
                           ELSE
                               CASE
                                   WHEN col.orig_list_price = ol.curr_price THEN
                                       -ol.cr_shipped * ROUND(col.orig_list_price * ol.discount / 100, 2)
                                   ELSE
                                       -ol.cr_shipped
                                       * ROUND(
                                                  (((CASE
                                                         WHEN col.list_price > col.orig_list_price THEN
                                                             col.list_price
                                                         ELSE
                                                             col.orig_list_price
                                                     END
                                                    ) - ol.curr_price
                                                   ) + ROUND(ol.curr_price * ol.discount / 100, 2)
                                                  ),
                                                  2
                                              )
                               END
                       END
               --ELSE (col.list_price - ol.curr_price) + ROUND(col.amt_disc,2) END -- v10.7  
               -- END v11.6 
               END
       END AS discount_amount,  --v3.0 Total Discount 

       CASE
           WHEN ISNULL(col.orig_list_price, 0) = 0 THEN
               0
           ELSE
       --((CASE orders.type 
       --WHEN 'I' THEN 
       --    case isnull(col.is_amt_disc,'n') 
       --    when 'y' then 
       --    round(ol.shipped * IsNull(case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end,0) -  ol.shipped * (ol.curr_price - round(isnull(col.amt_disc,0),2)),2)
       --    else
       --    round(ol.shipped * IsNull(case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end,0) - ol.shipped * (ol.curr_price - (ol.curr_price * (ol.discount / 100))),2)
       --	end
       --	ELSE round((ol.cr_shipped * IsNull(col.orig_list_price,0) - (ol.cr_shipped * ol.curr_price - (ol.curr_price * (ol.discount / 100)))),2)
       --END)
       ((CASE
             WHEN ol.curr_price > col.orig_list_price THEN
                 0
             ELSE
                 CASE orders.type
                     WHEN 'I' THEN
                         CASE ISNULL(col.is_amt_disc, 'n')
                             WHEN 'y' THEN
                                 ROUND(
                                          ol.shipped * ISNULL(   CASE
                                                                     WHEN col.list_price > col.orig_list_price THEN
                                                                         col.list_price
                                                                     ELSE
                                                                         col.orig_list_price
                                                                 END,
                                                                 0
                                                             ) - ol.shipped
                                          * (ol.curr_price - ROUND(ISNULL(col.amt_disc, 0), 2)),
                                          2
                                      )
                             ELSE
                                 ROUND(
                                          ol.shipped * ISNULL(   CASE
                                                                     WHEN col.list_price > col.orig_list_price THEN
                                                                         col.list_price
                                                                     ELSE
                                                                         col.orig_list_price
                                                                 END,
                                                                 0
                                                             ) - ol.shipped
                                          * (ol.curr_price - (ol.curr_price * (ol.discount / 100))),
                                          2
                                      )
                         END
                     ELSE
                         CASE ol.discount
                             WHEN 0 THEN
                                 ol.cr_shipped * (CASE
                                                      WHEN col.list_price > col.orig_list_price THEN
                                                          col.list_price
                                                      ELSE
                                                          col.orig_list_price
                                                  END - ol.curr_price
                                                 )
                             -- START v11.6
                             ELSE
                                 CASE
                                     WHEN col.orig_list_price = ol.curr_price THEN
                                         ol.cr_shipped * ROUND(   CASE
                                                                      WHEN col.list_price > col.orig_list_price THEN
                                                                          col.list_price
                                                                      ELSE
                                                                          col.orig_list_price
                                                                  END * ol.discount / 100,
                                                                  2
                                                              )
                                     ELSE
                                         ol.cr_shipped
                                         * ROUND(
                                                    ((CASE
                                                          WHEN col.list_price > col.orig_list_price THEN
                                                              col.list_price
                                                          ELSE
                                                              col.orig_list_price
                                                      END - ol.curr_price
                                                     ) + ROUND(ol.curr_price * ol.discount / 100, 2)
                                                    ),
                                                    2
                                                )
                                 END
                         END
                 --ELSE (col.list_price - ol.curr_price) + ROUND(col.amt_disc,2) END -- v10.7  
                 -- END v11.6 
                 END
         END
        ) / (CASE orders.type
                 WHEN 'I' THEN
                     ol.shipped * ISNULL(   CASE
                                                WHEN col.list_price > col.orig_list_price THEN
                                                    col.list_price
                                                ELSE
                                                    col.orig_list_price
                                            END,
                                            0
                                        )
                 ELSE
                     ol.cr_shipped * ISNULL(   CASE
                                                   WHEN col.list_price > col.orig_list_price THEN
                                                       col.list_price
                                                   ELSE
                                                       col.orig_list_price
                                               END,
                                               0
                                           )
             END
            )
       ) * 100
       END AS DISCOUNT_PCT,



       ol.return_code,          -- 12/27/2012 - tag
       orders.cust_po,          -- 12/30/2015 - tag for LM

       x_date_shipped = dbo.adm_get_pltdate_f(orders.date_shipped)

FROM ord_list ol (NOLOCK)
    INNER JOIN orders (nolock)
        ON orders.order_no = ol.order_no
           AND orders.ext = ol.order_ext
    LEFT OUTER JOIN dbo.CVO_orders_all co (NOLOCK)
        ON orders.order_no = co.order_no
           AND orders.ext = co.ext
    --LEFT OUTER JOIN dbo.orders AS o (NOLOCK)
    --    ON o.order_no = ol.order_no
    --       AND o.ext = ol.order_ext
    LEFT OUTER JOIN CVO_ord_list col (NOLOCK)
        ON ol.order_no = col.order_no
           AND ol.order_ext = col.order_ext
           AND ol.line_no = col.line_no
    INNER JOIN inv_master inv (NOLOCK)
        ON ol.part_no = inv.part_no
    INNER JOIN inv_master_add inva (NOLOCK)
        ON ol.part_no = inva.part_no
    INNER JOIN arcust (NOLOCK)
        ON orders.cust_code = arcust.customer_code
    INNER JOIN armaster (NOLOCK)
        ON orders.cust_code = armaster.customer_code
           AND orders.ship_to = armaster.ship_to_code
    LEFT OUTER JOIN arsalesp (NOLOCK)
        ON orders.salesperson = arsalesp.salesperson_code
    -- get date applied from AR 
    LEFT OUTER JOIN orders_invoice oi (NOLOCK)
        ON orders.order_no = oi.order_no
           AND orders.ext = oi.order_ext
    LEFT OUTER JOIN artrx ar (NOLOCK)
        ON ar.trx_ctrl_num = oi.trx_ctrl_num
WHERE (
          ol.shipped <> 0
          OR ol.cr_shipped <> 0
      )
      AND orders.status = 't'; --

-- 8/1/2016 - don't include debit promo activity any longer -as per LM and MR
-- TAG 031114
--UNION ALL

---- DEBIT PROMOS - TREAT LIKE A DISCOUNT
--SELECT 
--dp.order_no    
--,dp.ext
--,arx.doc_ctrl_num Invoice         
--,dp.line_no     
--,ol.part_no                        
--,dh.debit_promo_id promo_id
--,dh.debit_promo_level promo_level                    
--,ar.addr_sort1 cust_type                                
--,ar.customer_code cust_code  
--,ar.address_name customer_name                            
--,SUBSTRING(O.ship_to_region,1,2) AS region
--,o.ship_to_region territory
--,ar.territory_code ar_territory
--,o.salesperson 
--,o.user_category order_type 
--,o.date_shipped            
--,arx.date_applied 
--,'Credit' AS doc_type 
--,i.category product_group 
--,i.type_code product_type 
--,ia.field_2 product_style                            
--,ia.category_2 product_gender  
--,CASE i.obsolete WHEN 0 THEN 'No' 
--    WHEN 1 THEN 'Yes'
--    ELSE '' END AS Obsolete, -- tag 082613
--CASE ISNULL(ar.country_code,' ')
--WHEN 'US' THEN 'Domestic' ELSE 'Intnl' END AS dom_intl,
--ISNULL(ar.country_code,' ') AS country_code,
--ISNULL(ar.state,' ') AS state_code,
---- CASE o.type WHEN 'I' THEN ol.shipped ELSE (ol.cr_shipped*-1) END as units_sold, 
--0 AS units_sold,
--CASE o.type WHEN 'I' THEN ol.shipped * ISNULL(col.orig_list_price,0) * -1
--				 ELSE ol.cr_shipped * ISNULL(col.orig_list_price,0)  
--	END AS list_price,
---- 10/21/2013 - FIX price calculation
--CASE o.type 
--WHEN 'I' THEN 
--    CASE (ISNULL(COL.is_amt_disc,'n'))
--        WHEN 'Y' THEN (ROUND(OL.SHIPPED * OL.CURR_PRICE,2) - 
--            ROUND((OL.SHIPPED * ISNULL(CoL.AMT_DISC,0)),2)) * -1
--       	ELSE
--            (ROUND(OL.SHIPPED * OL.CURR_PRICE,2) - 
--            ROUND(( (OL.SHIPPED * OL.CURR_PRICE) * (ol.discount/ 100.00)),2) ) * -1
--        END       			 
--ELSE (ol.cr_shipped * ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2)) 
--END AS net_amt,

--CASE o.type 
--WHEN 'I' THEN
--    CASE ISNULL(col.is_amt_disc,'n') 
--    WHEN 'y' THEN 
--    (ol.shipped * ISNULL(col.orig_list_price,0) -  ol.shipped * ROUND(ol.curr_price - ISNULL(col.amt_disc,0),2)) * -1
--    ELSE
--    (ol.shipped * ISNULL(col.orig_list_price,0) - (ol.shipped * ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2))) * -1
--	END
--	ELSE (ol.cr_shipped * ISNULL(col.orig_list_price,0) - (ol.cr_shipped * ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2))) 
--END AS discount_amount
--,
--CASE WHEN col.orig_list_price = 0 THEN 0 ELSE
--ROUND((1 - 
--(CASE o.type 
--WHEN 'I' THEN 
--    CASE (ISNULL(COL.is_amt_disc,'n'))
--        WHEN 'Y' THEN (ROUND(OL.SHIPPED * OL.CURR_PRICE,2) - 
--            ROUND((OL.SHIPPED * ISNULL(CoL.AMT_DISC,0)),2)) * -1
--       	ELSE
--            (ROUND(OL.SHIPPED * OL.CURR_PRICE,2) - 
--            ROUND(( (OL.SHIPPED * OL.CURR_PRICE) * (ol.discount/ 100.00)),2) ) * -1
--        END       			 
--ELSE (ol.cr_shipped * ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2)) 
--END)/
--(
--CASE o.type WHEN 'I' THEN ol.shipped * ISNULL(col.orig_list_price,0) * -1
--				 ELSE ol.cr_shipped * ISNULL(col.orig_list_price,0)  
--	END
--))*100, 2) END AS DISCOUNT_PCT
--,ol.return_code ,
--o.cust_po	-- 12/30/2015 - tag for LM
--,dbo.adm_get_pltdate_f(o.date_shipped) x_date_shipped
--FROM 
--cvo_debit_promo_customer_det dp
--INNER JOIN ord_list ol ON ol.order_no = dp.order_no AND ol.order_ext = dp.ext AND ol.line_no = dp.line_no
--INNER JOIN cvo_ord_list col ON col.order_no = dp.order_no AND col.order_ext = dp.ext AND col.line_no = dp.line_no
--INNER JOIN orders o ON o.order_no = ol.order_no AND o.ext = ol.order_ext
--INNER JOIN armaster ar ON ar.customer_code = o.cust_code AND ar.ship_To_code = o.ship_to
--INNER JOIN inv_master i ON i.part_no = ol.part_no
--INNER JOIN inv_master_add ia ON ia.part_no = ol.part_no
--LEFT OUTER JOIN artrxcdt arx ON dp.trx_ctrl_num = arx.trx_ctrl_num
--INNER JOIN cvo_debit_promo_customer_hdr dh ON dh.hdr_rec_id = dp.hdr_rec_id
--WHERE arx.gl_rev_acct LIKE '4530%' 
--AND (ol.shipped <> 0 OR ol.cr_shipped <> 0) AND O.status ='t'

GO

GRANT REFERENCES ON  [dbo].[CVO_Royalties_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_Royalties_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_Royalties_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_Royalties_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_Royalties_vw] TO [public]
GO
