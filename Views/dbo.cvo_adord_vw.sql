SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- select * From cvo_adord_vw where territory = '50505' and date_entered BETWEEN '2/1/2018' AND '2/28/2018'
-- select * --into #t 
--From cvo_adord_vw where territory like '%20205%' and status = 'v'
--tempdb..sp_help #t - char(1)
--drop table #t
-- 2/5/2013 - tag - updated order totals on open orders to properly include discounts

CREATE VIEW [dbo].[cvo_adord_vw]
AS
SELECT CONVERT(VARCHAR(10), orders.order_no) order_no,
       CONVERT(VARCHAR(3), orders.ext) ext,
       orders.cust_code,
       orders.ship_to,
       orders.ship_to_name,
       orders.location,
       orders.cust_po,
       orders.routing,
       orders.fob,
       orders.attention,
       orders.tax_id,
       orders.terms,
       orders.curr_key,
       orders.salesperson,                       -- T McGrady NOV.29.2010        
       orders.ship_to_region AS Territory,       -- T McGrady NOV.29.2010        

       CASE orders.status WHEN 'T' THEN orders.gross_sales ELSE orders.total_amt_order END total_amt_order,
                                                 -- orders.total_amt_order ,        

       CASE orders.status WHEN 'T' THEN total_discount ELSE orders.tot_ord_disc END total_discount,
                                                 -- 020514 - per LM request 

       CASE orders.status
           WHEN 'T' THEN orders.gross_sales - orders.total_discount ELSE orders.total_amt_order - orders.tot_ord_disc
       END Net_Sale_Amount,

       CASE orders.status WHEN 'T' THEN total_tax ELSE orders.tot_ord_tax END total_tax,

       CASE orders.status WHEN 'T' THEN freight ELSE orders.tot_ord_freight END freight,
                                                 -- tag - 5/21/2012 - add qty ordered and shipped per KM request
       qtys.qty_ordered qty_ordered,
       qtys.qty_shipped qty_shipped,

                                                 --orders.total_invoice , 

       CASE orders.status
           WHEN 'T' THEN total_invoice ELSE
       (orders.total_amt_order - orders.tot_ord_disc + orders.tot_ord_tax + orders.tot_ord_freight)
       END total_invoice,
       CONVERT(VARCHAR(10), orders.invoice_no) invoice_no,
       orders_invoice.doc_ctrl_num,
       orders.invoice_date date_invoice,
       orders.date_entered,
       orders.sch_ship_date date_sch_ship,
       orders.date_shipped,
       CAST(orders.status AS VARCHAR(1)) status,

       CASE orders.status
           WHEN 'A' THEN 'Hold for Quote'
           WHEN 'B' THEN 'Both a credit and price hold'
           WHEN 'C' THEN 'Credit Hold'
           WHEN 'E' THEN 'EDI'
           WHEN 'H' THEN 'Price Hold'
           WHEN 'M' THEN 'Blanket Order(parent)'
           WHEN 'N' THEN 'New'
           WHEN 'P' THEN 'Open/Picked'
           WHEN 'Q' THEN 'Open/Printed'
           WHEN 'R' THEN 'Ready/Posting'
           WHEN 'S' THEN 'Shipped/Posted'
           WHEN 'T' THEN 'Shipped/Transferred'
           WHEN 'V' THEN 'Void'
           WHEN 'X' THEN 'Voided/Cancel Quote' ELSE ''
       END status_desc,
       orders.who_entered,
                                                 -- orders.blanket,        
                                                 -- blanket_desc=        
                                                 --   CASE orders.blanket        
                                                 --   WHEN 'N' THEN 'No'        
                                                 --   WHEN 'Y' THEN 'Yes'        
                                                 --   ELSE ''        
                                                 --  END,        

       CASE WHEN orders.status IN ( 'R', 'S', 'T' ) THEN 'Yes' ELSE 'No' END shipped_flag,
       orders.hold_reason,                       -- T McGrady NOV.29.2010        
       orders.orig_no,
       orders.orig_ext,
                                                 -- CASE multiple_flag         
                                                 --  WHEN 'Y' THEN 'Yes'         
                                                 --  WHEN 'N' THEN 'No'         
                                                 --  ELSE 'No' END multiple_ship_to,        
                                                 --  Ctel_Order_Num = ISNULL(EAI_ord_xref.FO_order_no, ' '),  
       cvo.promo_id,                             -- tag - add promos  
       cvo.promo_level,
       orders.user_category AS order_type,       -- tag 01/25/2012       
                                                 -- convert(varchar(10),orders.user_def_fld4) user_def_fld4, --fzambada add Megasys orders      
                                                 -- 080212 - TAG
                                                 -- 082312 - tag - only tally up frames and suns

       ISNULL(qtys.framesordered, 0) AS FramesOrdered,
       ISNULL(qtys.framesshipped, 0) AS FramesShipped,

       orders.back_ord_flag,
       ISNULL(ar.addr_sort1, '') AS Cust_type,
       ISNULL(user_def_fld4, '') AS HS_order_no, -- 101613 - as per HK
       cvo.allocation_date allocation_date,
       orders.freight_allow_type, -- 11/28/2018 - jb request

       dbo.adm_get_pltdate_f(orders.invoice_date) x_date_invoice,
       dbo.adm_get_pltdate_f(orders.date_entered) x_date_entered,
       dbo.adm_get_pltdate_f(orders.sch_ship_date) x_date_sch_ship,
       dbo.adm_get_pltdate_f(orders.date_shipped) x_date_shipped,
       source = 'E'                              -- tag  

FROM dbo.orders orders (NOLOCK)
    LEFT OUTER JOIN dbo.orders_invoice orders_invoice (NOLOCK)
        ON (
           orders.order_no = orders_invoice.order_no
           AND orders.ext = orders_invoice.order_ext
           )
    --        LEFT OUTER JOIN EAI_ord_xref EAI_ord_xref (nolock)       
    --        ON ( orders.order_no = EAI_ord_xref.BO_order_no  )   
    LEFT JOIN dbo.CVO_orders_all cvo (NOLOCK)
        ON (
           orders.order_no = cvo.order_no
           AND orders.ext = cvo.ext
           ) -- tag = add promos       
    LEFT OUTER JOIN dbo.armaster ar (NOLOCK)
        ON orders.cust_code = ar.customer_code
           AND orders.ship_to = ar.ship_to_code
    LEFT OUTER JOIN
    (
    SELECT order_no,
           order_ext,
           SUM(ISNULL(ordered, 0) - ISNULL(cr_ordered, 0)) qty_ordered,
           SUM(ISNULL(shipped, 0) - ISNULL(cr_shipped, 0)) qty_shipped,
           SUM(CASE WHEN I.type_code IN ( 'frame', 'sun' ) THEN ordered ELSE 0 END) framesordered,
           SUM(CASE WHEN I.type_code IN ( 'frame', 'sun' ) THEN shipped ELSE 0 END) framesshipped
    FROM dbo.ord_list OL (NOLOCK)
        JOIN dbo.inv_master I (NOLOCK)
            ON OL.part_no = I.part_no
    GROUP BY order_no,
             order_ext
    ) qtys
        ON qtys.order_no = orders.order_no
           AND qtys.order_ext = orders.ext

WHERE orders.type = 'I'
-- and orders.status<>'V'  and orders.status<>'X'  

UNION ALL
SELECT CONVERT(VARCHAR(10), t1.order_no) order_no,
       CONVERT(VARCHAR(3), t1.ext) ext,
       t1.cust_code,
       t1.ship_to,
       t1.ship_to_name,
       t1.location,
       t1.cust_po,
       t1.routing,
       t1.fob,
       t1.attention,
       t1.tax_id,
       t1.terms,
       t1.curr_key,
       t1.salesperson,                              -- T McGrady NOV.29.2010        
       t1.ship_to_region AS Territory,              -- T McGrady NOV.29.2010        
       t1.total_amt_order,
       t1.discount total_discount,
       t1.total_amt_order - t1.discount AS Net_Sales_Amount,
       t1.total_tax,
       t1.freight,
                                                    --t1.total_invoice ,        
                                                    -- (t1.total_amt_order+t1.tot_ord_tax+t1.tot_ord_freight) AS total_invoice,
                                                    -- tag - 5/21/2012 - add qty ordered and shipped per KM request
       (
       SELECT SUM(ISNULL(ordered, 0))
       FROM dbo.cvo_ord_list_hist ol (NOLOCK)
       WHERE t1.order_no = ol.order_no
             AND t1.ext = ol.order_ext
       ) qty_ordered,
       (
       SELECT SUM(ISNULL(shipped, 0))
       FROM dbo.cvo_ord_list_hist ol (NOLOCK)
       WHERE t1.order_no = ol.order_no
             AND t1.ext = ol.order_ext
       ) qty_shipped,

       (t1.total_amt_order + t1.total_tax + t1.freight) AS total_invoice,
       CONVERT(VARCHAR(10), t1.invoice_no) invoice_no,
       '' AS doc_ctrl_num,
       t1.invoice_date date_invoice,
       t1.date_entered,
       t1.sch_ship_date date_sch_ship,
       t1.date_shipped,
       t1.status,

       CASE t1.status
           WHEN 'A' THEN 'Hold for Quote'
           WHEN 'B' THEN 'Both a credit and price hold'
           WHEN 'C' THEN 'Credit Hold'
           WHEN 'E' THEN 'EDI'
           WHEN 'H' THEN 'Price Hold'
           WHEN 'M' THEN 'Blanket Order(parent)'
           WHEN 'N' THEN 'New'
           WHEN 'P' THEN 'Open/Picked'
           WHEN 'Q' THEN 'Open/Printed'
           WHEN 'R' THEN 'Ready/Posting'
           WHEN 'S' THEN 'Shipped/Posted'
           WHEN 'T' THEN 'Shipped/Transferred'
           WHEN 'V' THEN 'Void'
           WHEN 'X' THEN 'Voided/Cancel Quote' ELSE ''
       END status_desc,
       t1.who_entered,
                                                    -- t1.blanket,        
                                                    -- blanket_desc=        
                                                    --   CASE t1.blanket        
                                                    --   WHEN 'N' THEN 'No'        
                                                    --   WHEN 'Y' THEN 'Yes'        
                                                    --   ELSE ''        
                                                    --  END,        
       CASE WHEN t1.status IN ( 'R', 'S', 'T' ) THEN 'Yes' ELSE 'No' END shipped_flag,
       t1.hold_reason,                              -- T McGrady NOV.29.2010        
       t1.orig_no,
       t1.orig_ext,
                                                    -- CASE multiple_flag         
                                                    --  WHEN 'Y' THEN 'Yes'         
                                                    --  WHEN 'N' THEN 'No'         
                                                    --  ELSE 'No' END multiple_ship_to,        
                                                    --  '' as Ctel_Order_Num,  
       t1.user_def_fld3,                            -- tag - add promos  
       t1.user_def_fld9,
       t1.user_category AS order_type,              -- tag 01/25/2012     

                                                    -- convert(varchar(10),t1.user_def_fld4) user_def_fld4, --fzambada add Megasys orders      
       ISNULL(col.FramesOrdered, 0) FramesOrdered,
                                                    --ISNULL((select sum(ordered) 
                                                    -- from CVO_ord_list_HIST ol (nolock)
                                                    -- inner join inv_master i (nolock) on ol.part_no = i.part_no
                                                    -- where T1.order_no = ol.order_no and T1.ext = ol.order_ext
                                                    --	and i.type_code in ('FRAME','SUN','PARTS') ), 0) as FramesOrdered, 
       ISNULL(col.FramesShipped, 0) FramesShipped,
                                                    --ISNULL((select sum(shipped) 
                                                    -- from CVO_ord_list_HIST ol (nolock)
                                                    -- inner join inv_master i (nolock) on ol.part_no = i.part_no
                                                    -- where T1.order_no = ol.order_no and T1.ext = ol.order_ext
                                                    --	and i.type_code in ('FRAME','SUN','PARTS') ), 0) as FramesShipped,  
       t1.back_ord_flag,
       ISNULL(ar.addr_sort1, '') AS Cust_type,
       ISNULL(t1.user_def_fld4, '') AS HS_order_no, -- 101613 - as per HK
       GETDATE() allocation_date,
       '' freight_allow_type, -- 11/28/2018 - jb request

       dbo.adm_get_pltdate_f(t1.invoice_date) x_date_invoice,
       dbo.adm_get_pltdate_f(t1.date_entered) x_date_entered,
       dbo.adm_get_pltdate_f(t1.sch_ship_date) x_date_sch_ship,
       dbo.adm_get_pltdate_f(t1.date_shipped) x_date_shipped,
       source = 'M'                                 -- tag   
FROM dbo.CVO_orders_all_Hist t1 (NOLOCK)
    LEFT OUTER JOIN
    (
    SELECT SUM(ordered) FramesOrdered,
           SUM(shipped) FramesShipped,
           order_no,
           order_ext
    FROM dbo.cvo_ord_list_hist ol (NOLOCK)
        INNER JOIN dbo.inv_master i (NOLOCK)
            ON ol.part_no = i.part_no
    WHERE i.type_code IN ( 'frame', 'sun', 'parts' )
    GROUP BY ol.order_no,
             ol.order_ext

    ) col
        ON col.order_no = t1.order_no
           AND col.order_ext = t1.ext

    LEFT OUTER JOIN dbo.armaster ar (NOLOCK)
        ON t1.cust_code = ar.customer_code
           AND t1.ship_to = ar.ship_to_code

WHERE t1.type = 'I';


GO


GRANT REFERENCES ON  [dbo].[cvo_adord_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_adord_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_adord_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_adord_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_adord_vw] TO [public]
GO
