SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

  
-- Author = E.L.  
-- 071812 - TAG - updated to EV  
-- 092112 - tag - updated joins to use orders_invoice  
-- 120312 - CB - Issue #982 - No Commission
-- 031314 - EL update for DEBIT PROMO CREDITS
-- 120715 - tg - make join for commissions view left join
  
CREATE VIEW [dbo].[cvo_commission_bldr_vw] AS  
---- Commissions Pull (3/20/12 ELaBarbera)  
--use cvo   
---- SETUP DATE VARIABLES  
--DECLARE @DateFrom datetime  
--DECLARE @DateTo datetime  
--SET @DateFrom = '7/1/2012'  
--SET @DateTo = '7/31/2012'  
--SELECT @DateTo = DATEADD(mi, 59,(DATEADD(hh, 23, @DateTo)))  
--   
--declare @date1 datetime  
--declare @JDateFrom int  
--set @date1=@DateFrom  
--select @JDateFrom = datediff(day,'1/1/1950',convert(datetime,  
--  convert(varchar( 8), (year(@date1) * 10000) + (month(@date1) * 100) + day(@date1)))  ) + 711858  
--   
--declare @date2 datetime  
--declare @JDateTo int  
--set @date2=@DateTo  
--select @JDateTo = datediff(day,'1/1/1950',convert(datetime,  
--  convert(varchar( 8), (year(@date2) * 10000) + (month(@date2) * 100) + day(@date2)))  ) + 711858  
   
-- AR POSTED  
 SELECT t1.salesperson_code AS Salesperson,   
t1.territory_code AS Territory,   
t1.customer_code AS Cust_code,   
t1.ship_to_code AS Ship_to,   
A.address_name AS Name,  
O1.ORDER_NO AS Order_no,  
O1.EXT AS Ext,  
SUBSTRING(t1.doc_ctrl_num,4,10) AS Invoice_no,  
--convert(varchar,dateadd(d,date_doc-711858,'1/1/1950'),101) AS InvoiceDate,  
--convert(varchar,dateadd(d,t1.DATE_APPLIED-711858,'1/1/1950'),101) AS DateShipped,  
t1.date_doc AS InvoiceDate,  
t1.date_applied AS DateShipped,  
CASE WHEN o1.user_category IS NULL THEN 'ST'  
  WHEN o1.user_category ='' THEN 'ST'  
  ELSE o1.user_category END AS OrderType,  
ISNULL(Promo_id, '' ) AS Promo_id,   
ISNULL(Promo_level, '' ) AS Level,  
CASE WHEN t1.trx_type = '2031' THEN 'Inv' ELSE 'Crd' END AS type,  
CASE WHEN t1.trx_type = 2031 THEN ns.extended_total ELSE ns.extended_total * -1 END AS Net_Sales,
CASE WHEN t1.trx_type = '2031' THEN (ISNULL(clv.extended_total,0)) ELSE (ISNULL(clv.extended_total,0) * -1)  END AS Amount, -- Issue #982
CASE WHEN O2.commission_pct IS NULL THEN   
  CASE T3.ESCALATED_COMMISSIONS WHEN '1' THEN T3.COMMISSION ELSE (SELECT COMMISSION_PCT   
                  FROM cvo_comm_pclass (NOLOCK) XX   
                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
                  AND YY.CUSTOMER_CODE = A.CUSTOMER_CODE  
                  AND YY.ADDRESS_TYPE='0') END  
   ELSE O2.commission_pct END AS 'Comm%',  
CASE t1.trx_type WHEN '2031' THEN ((ISNULL(clv.extended_total,0)) * ((CASE WHEN O2.commission_pct IS NULL THEN -- Issue #982  
  CASE T3.ESCALATED_COMMISSIONS WHEN '1' THEN T3.COMMISSION ELSE (SELECT COMMISSION_PCT   
                  FROM cvo_comm_pclass (NOLOCK) XX   
                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
                  AND YY.CUSTOMER_CODE = A.CUSTOMER_CODE  
                  AND YY.ADDRESS_TYPE='0') END ELSE O2.commission_pct END) /100))  
    ELSE ((ISNULL(clv.extended_total,0)) * -1) * ((CASE WHEN O2.commission_pct IS NULL THEN  -- Issue #982
  CASE T3.ESCALATED_COMMISSIONS WHEN '1' THEN T3.COMMISSION ELSE (SELECT COMMISSION_PCT   
                  FROM cvo_comm_pclass (NOLOCK) XX   
                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
                  AND YY.CUSTOMER_CODE = A.CUSTOMER_CODE  
                  AND YY.ADDRESS_TYPE='0') END ELSE O2.commission_pct END) /100)  
    END AS Comm$,  
'Posted' AS Loc,  
salesperson_name,   
ISNULL(CONVERT(VARCHAR,date_of_hire,101), '' ) AS HireDate,  
 draw_amount  
--*******************************  
--update below to use orders-invoice  
-- FROM artrx t1(nolock)  
---- tag - 092112  
--left outer join orders_invoice oi (nolock) on t1.trx_ctrl_num = oi.trx_ctrl_num  
--left outer join cvo_orders_all (nolock) o2 on o2.order_no = oi.order_no and o2.ext = oi.order_ext  
--left outer join orders_all (nolock) o1 on o1.order_no = o2.order_no and o1.ext = o2.ext   
  
      FROM artrx t1(NOLOCK)
LEFT OUTER JOIN cvo_orders_all O2 (NOLOCK) ON O2.order_no=
(CASE WHEN LEN(order_ctrl_num)=10 THEN REVERSE(RIGHT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))+4))
	WHEN LEN(order_ctrl_num)=9 THEN REVERSE(RIGHT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))+5))	
	WHEN LEN(order_ctrl_num)=7 THEN REVERSE(RIGHT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))+3))
	ELSE REVERSE(RIGHT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))-1)) END)
	AND O2.ext=
(CASE WHEN LEN(order_ctrl_num)=10 THEN REVERSE(LEFT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))-1))
	WHEN LEN(order_ctrl_num)=9 THEN REVERSE(LEFT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))-1))
	WHEN LEN(order_ctrl_num)=7 THEN REVERSE(LEFT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))-1))
	ELSE REVERSE(LEFT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))-1)) END)        
----LEFT OUTER JOIN CVO_ORDERS_ALL (NOLOCK) O2 ON CASE WHEN LEN(t1.order_ctrl_num) <4 THEN left(t1.order_ctrl_num,1)   
----                                                                              WHEN LEN(t1.order_ctrl_num) <9 THEN left(t1.order_ctrl_num,5)   
----                                                  WHEN LEN(t1.order_ctrl_num) =0 THEN ''   
----                                                                   ELSE left(t1.order_ctrl_num,7) END=O2.order_no AND right(t1.order_ctrl_num,1)=O2.EXT  
LEFT OUTER JOIN orders_all (NOLOCK) o1 ON o1.order_no = o2.order_no AND o1.ext = o2.ext   
--LEFT OUTER JOIN CVO_ORDERS_ALL (NOLOCK) O2 ON CASE WHEN LEN(t1.order_ctrl_num) <9 THEN left(t1.order_ctrl_num,5)   
--           WHEN LEN(t1.order_ctrl_num) =0 THEN ''   
--            ELSE left(t1.order_ctrl_num,7) END=O2.order_no AND right(t1.order_ctrl_num,1)=O2.EXT  
--LEFT OUTER JOIN ORDERS_ALL (NOLOCK) O1 ON  
--  (t1.order_ctrl_num = rtrim(ltrim(convert(varchar,o1.order_no) + '-' + convert(varchar,o1.ext))) )   
LEFT JOIN arsalesp (NOLOCK) t3 ON t1.salesperson_code = t3.salesperson_code  
LEFT OUTER JOIN armaster (NOLOCK) A ON t1.customer_code=A.customer_code AND t1.ship_to_code=A.ship_to_code  
LEFT JOIN cvo_comm_pclass (NOLOCK) P ON A.price_code=P.price_code  
LEFT JOIN dbo.cvo_commission_line_sum_vw clv ON t1.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982
JOIN (SELECT trx_ctrl_num, SUM(extended_price) extended_total
FROM artrxcdt (NOLOCK)
GROUP BY trx_ctrl_num) ns ON ns.trx_ctrl_num = t1.trx_ctrl_num

 WHERE t1.trx_type IN ('2031','2032')  
AND t1.DOC_DESC NOT LIKE 'CONVERTED%'  
--and t1.DATE_APPLIED between @JDateFrom and @JDateTo  
AND t1.doc_desc NOT LIKE '%NONSALES%'  
AND t1.doc_ctrl_num NOT LIKE 'CB%'  
AND t1.doc_ctrl_num NOT LIKE 'FIN%'  
AND t1.order_ctrl_num <> ''
AND t1.void_flag = 0  
AND t1.posted_flag = 1  
 
UNION ALL
-- ARPOSTED SPECIAL DEBIT PROMO CREDITS
SELECT  
o.salesperson 
,o.ship_to_region territory
,ar.customer_code cust_code 
,'' AS Ship_to
,ar.address_name Name
,dp.order_no    
,dp.ext
,SUBSTRING(arx.doc_ctrl_num,4,8) Invoice_no
,art.Date_entered AS InvoiceDate  --**--**--**
,art.Date_entered AS DateShipped  --**--**--**
,o.user_category OrderType
,dh.debit_promo_id promo_id
,dh.debit_promo_level promo_level                    
,'Crd' AS Type
, SUM(dp.credit_amount)* -1 AS Net_sales
,SUM(dp.credit_amount)*-1 AS Amount
,CASE WHEN O2.commission_pct IS NULL THEN   
  CASE T3.ESCALATED_COMMISSIONS WHEN 1 THEN T3.COMMISSION ELSE (SELECT COMMISSION_PCT   
                  FROM cvo_comm_pclass (NOLOCK) XX   
                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
                  AND YY.CUSTOMER_CODE = ar.CUSTOMER_CODE  
                  AND YY.ADDRESS_TYPE=0) END  
   ELSE O2.commission_pct END AS 'Comm%'
,CASE art.trx_type WHEN '2031' THEN ((ISNULL(clv.extended_total,0)) * ((CASE WHEN O2.commission_pct IS NULL THEN -- Issue #982  
  CASE T3.ESCALATED_COMMISSIONS WHEN 1 THEN T3.COMMISSION ELSE (SELECT COMMISSION_PCT   
                  FROM cvo_comm_pclass (NOLOCK) XX   
                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
                  AND YY.CUSTOMER_CODE = ar.CUSTOMER_CODE  
                  AND YY.ADDRESS_TYPE=0) END ELSE O2.commission_pct END) /100))  
    ELSE ((ISNULL(clv.extended_total,0)) * -1) * ((CASE WHEN O2.commission_pct IS NULL THEN  -- Issue #982
  CASE T3.ESCALATED_COMMISSIONS WHEN 1 THEN T3.COMMISSION ELSE (SELECT COMMISSION_PCT   
                  FROM cvo_comm_pclass (NOLOCK) XX   
                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
                  AND YY.CUSTOMER_CODE = ar.CUSTOMER_CODE  
                  AND YY.ADDRESS_TYPE=0) END ELSE O2.commission_pct END) /100)  
    END AS Comm$  
,'Posted' AS Loc
,salesperson_name   
,ISNULL(CONVERT(VARCHAR,date_of_hire,101), '' ) AS HireDate
,draw_amount  
FROM 
cvo_debit_promo_customer_det dp
JOIN cvo_orders_all o2 ON dp.order_no=o2.order_no AND dp.ext=o2.ext
INNER JOIN ord_list ol ON ol.order_no = dp.order_no AND ol.order_ext = dp.ext AND ol.line_no = dp.line_no
INNER JOIN cvo_ord_list col ON col.order_no = dp.order_no AND col.order_ext = dp.ext AND col.line_no = dp.line_no
INNER JOIN orders o ON o.order_no = ol.order_no AND o.ext = ol.order_ext
INNER JOIN armaster ar ON ar.customer_code = o.cust_code AND ar.ship_To_code = o.ship_to
INNER JOIN inv_master i ON i.part_no = ol.part_no
INNER JOIN inv_master_add ia ON ia.part_no = ol.part_no
LEFT OUTER JOIN artrxcdt arx ON dp.trx_ctrl_num = arx.trx_ctrl_num
JOIN artrx art ON arx.doc_ctrl_num=art.doc_ctrl_num
LEFT JOIN arsalesp (NOLOCK) t3 ON art.salesperson_code = t3.salesperson_code  
INNER JOIN cvo_debit_promo_customer_hdr dh ON dh.hdr_rec_id = dp.hdr_rec_id
JOIN dbo.cvo_commission_line_sum_vw clv ON art.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982

WHERE arx.gl_rev_acct LIKE '4530%' 
GROUP BY o.salesperson ,o.ship_to_region,ar.customer_code,ar.address_name,dp.order_no,dp.ext,arx.doc_ctrl_num,art.date_entered
,o.user_category,O2.commission_pct,T3.ESCALATED_COMMISSIONS,T3.commission,art.trx_type,clv.extended_total,t3.salesperson_name
,t3.date_of_hire,t3.draw_amount,dh.debit_promo_id,dh.debit_promo_level      

UNION ALL  
--AR UNPOSTED  
 SELECT t1.salesperson_code,  
t1.TERRITORY_CODE,  
t1.CUSTOMER_CODE,  
t1.SHIP_TO_CODE,  
A.address_name AS Name,  
O1.ORDER_NO AS Order_no,  
O1.EXT AS Ext,  
--right(t1.doc_ctrl_num,9) as Invoice_no,  
SUBSTRING(t1.doc_ctrl_num,4,10) AS Invoice_no,  
--convert(varchar,dateadd(d,t1.date_doc-711858,'1/1/1950'),101) AS InvoiceDate,  
--convert(varchar,dateadd(d,t1.DATE_APPLIED-711858,'1/1/1950'),101) AS DateShipped,  
t1.date_doc AS InvoiceDate,  
t1.date_applied AS DateShipped,  
CASE WHEN o1.user_category IS NULL THEN 'ST'  
  WHEN o1.user_category ='' THEN 'ST'  
  ELSE o1.user_category END AS OrderType,  
ISNULL(Promo_id, '' ) AS Promo_id,   
ISNULL(Promo_level, '' ) AS Level,  
CASE WHEN t1.trx_type = '2031' THEN 'Inv' ELSE 'Crd' END AS type,  
CASE WHEN t1.trx_type = 2031 THEN ns.extended_total ELSE ns.extended_total * -1 END AS Net_Sales,
CASE WHEN t1.trx_type = '2031' THEN (ISNULL(clv.extended_total,0)) ELSE (ISNULL(clv.extended_total,0)) * -1 END AS Amount, -- Issue #982 
CASE WHEN O2.commission_pct IS NULL THEN   
  CASE T3.ESCALATED_COMMISSIONS WHEN 1 THEN T3.COMMISSION ELSE (SELECT COMMISSION_PCT   
                  FROM cvo_comm_pclass (NOLOCK) XX   
                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
                  AND YY.CUSTOMER_CODE = A.CUSTOMER_CODE  
                  AND YY.ADDRESS_TYPE=0) END  
  ELSE O2.commission_pct END AS 'Comm%',  
CASE t1.trx_type WHEN '2031' THEN ((ISNULL(clv.extended_total,0)) * ((CASE WHEN O2.commission_pct IS NULL THEN  -- Issue #982
  CASE T3.ESCALATED_COMMISSIONS WHEN 1 THEN T3.COMMISSION ELSE (SELECT COMMISSION_PCT   
                  FROM cvo_comm_pclass (NOLOCK) XX   
                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
                  AND YY.CUSTOMER_CODE = A.CUSTOMER_CODE  
                  AND YY.ADDRESS_TYPE=0) END ELSE O2.commission_pct END) /100))  
    ELSE ((ISNULL(clv.extended_total,0)) * -1) * ((CASE WHEN O2.commission_pct IS NULL THEN  -- Issue #982
  CASE T3.ESCALATED_COMMISSIONS WHEN 1 THEN T3.COMMISSION ELSE (SELECT COMMISSION_PCT   
                  FROM cvo_comm_pclass (NOLOCK) XX   
                  JOIN ARMASTER (NOLOCK) YY ON XX.PRICE_CODE = YY.PRICE_CODE  
                  AND YY.CUSTOMER_CODE = A.CUSTOMER_CODE  
                  AND YY.ADDRESS_TYPE=0) END ELSE O2.commission_pct END) /100)  
    END AS Comm$,  
'UnPosted' AS Loc,  
salesperson_name,   
ISNULL(CONVERT(VARCHAR,date_of_hire,101), '' ) AS HireDate,  
 draw_amount  
 FROM ARINPCHG t1(NOLOCK)  
LEFT OUTER JOIN cvo_orders_all O2 (NOLOCK) ON O2.order_no=
(CASE WHEN LEN(order_ctrl_num)=10 THEN REVERSE(RIGHT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))+4))
	WHEN LEN(order_ctrl_num)=9 THEN REVERSE(RIGHT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))+5))	
	WHEN LEN(order_ctrl_num)=7 THEN REVERSE(RIGHT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))+3))
	ELSE REVERSE(RIGHT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))-1)) END)
	AND O2.ext=
(CASE WHEN LEN(order_ctrl_num)=10 THEN REVERSE(LEFT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))-1))
	WHEN LEN(order_ctrl_num)=9 THEN REVERSE(LEFT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))-1))
	WHEN LEN(order_ctrl_num)=7 THEN REVERSE(LEFT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))-1))
	ELSE REVERSE(LEFT(REVERSE(order_ctrl_num),CHARINDEX('-', REVERSE(order_ctrl_num))-1)) END)        

----LEFT OUTER JOIN CVO_ORDERS_ALL (NOLOCK) O2 ON CASE WHEN LEN(t1.order_ctrl_num) <4 THEN left(t1.order_ctrl_num,1)   
----                                                                              WHEN LEN(t1.order_ctrl_num) <9 THEN left(t1.order_ctrl_num,5)   
----                                        WHEN LEN(t1.order_ctrl_num) =0 THEN ''   
----                                                                   ELSE left(t1.order_ctrl_num,7) END=O2.order_no AND right(t1.order_ctrl_num,1)=O2.EXT  
LEFT OUTER JOIN orders_all (NOLOCK) o1 ON o1.order_no = o2.order_no AND o1.ext = o2.ext   
  
-- tag - 092112  
--left outer join orders_invoice oi (nolock) on t1.trx_ctrl_num = oi.trx_ctrl_num  
--left outer join cvo_orders_all (nolock) o2 on o2.order_no = oi.order_no and o2.ext = oi.order_ext  
--left outer join orders_all (nolock) o1 on o1.order_no = o2.order_no and o1.ext = o2.ext   
--  
--LEFT OUTER JOIN CVO_ORDERS_ALL (NOLOCK) O2 ON CASE WHEN LEN(t1.order_ctrl_num) <9 THEN left(t1.order_ctrl_num,5)   
--           WHEN LEN(t1.order_ctrl_num) =0 THEN ''   
--            ELSE left(t1.order_ctrl_num,7) END=O2.order_no AND right(t1.order_ctrl_num,1)=O2.EXT  
--LEFT OUTER JOIN ORDERS_ALL (NOLOCK) O1 ON  
--  (t1.order_ctrl_num = rtrim(ltrim(convert(varchar,o1.order_no) + '-' + convert(varchar,o1.ext))) )   
LEFT JOIN arsalesp (NOLOCK) t3 ON t1.salesperson_code = t3.salesperson_code  
LEFT OUTER JOIN armaster (NOLOCK) A ON t1.customer_code=A.customer_code AND t1.ship_to_code=A.ship_to_code  
LEFT JOIN cvo_comm_pclass (NOLOCK) P ON A.price_code=P.price_code  
LEFT JOIN dbo.cvo_commission_line_sum_up_vw clv ON t1.trx_ctrl_num = clv.trx_ctrl_num -- Issue #982
JOIN (SELECT trx_ctrl_num, SUM(extended_price) extended_total
FROM arinpcdt (NOLOCK)
GROUP BY trx_ctrl_num) ns ON ns.trx_ctrl_num = t1.trx_ctrl_num

 WHERE t1.trx_type IN ('2031','2032')  
AND DOC_DESC NOT LIKE 'CONVERTED%'  
--and t1.DATE_APPLIED between @JDateFrom and @JDateTo  
AND t1.doc_ctrl_num NOT LIKE 'CB%'  
AND t1.doc_ctrl_num NOT LIKE 'FIN%'  
AND t1.doc_desc NOT LIKE '%NONSALES%'  
AND t1.order_ctrl_num <> ''
   
-- ORDER BY t1.salesperson_code, InvoiceDate  









GO
GRANT SELECT ON  [dbo].[cvo_commission_bldr_vw] TO [public]
GO
