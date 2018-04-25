SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


  
CREATE VIEW [dbo].[CVO_BGLog_source_vw] AS  
-- select  * From cvo_bglog_source_vw where DOC_CTRL_NUM = 'inv0388976'
-- select * From cvo_bglog_source_vw where inv_date between '08/26/2017' and '09/25/2017'
-- v2.0 TM 04/27/2012 - Ignore AR Records that are Voided  
-- tag - 072712 - ar only credit's - dont qualify on the terms, as it doesn't matter  
-- tag - 1/3/2012 - fix so that mixed discount orders dont merge  
-- v2.1 CT 13/02/2013 - Change to return additional field of ndd containing credit return fees
-- v2.2 CB 26/02/2013 - View not including tax and freight only credits
-- v2.3 CB 21/03/2013 - Freight and tax not showing on std AR credit memo
-- v2.4 CT 21/03/2013 - Remove ndd filed, stop credit return fee lines being included in data returned

-- v2.5 CB 10/07/2013 - Issue #927 - Buying Group Switching
-- v2.6 CB 18/09/2013 - Issue #927 - Buying Group Switching - RB Orders set to and from BGs
-- v2.7 CHANGES MADE BY CVO
-- v2.8	CT 20/10/2014 - Issue #1367 - For Sales Orders and Credit Returns, if net price > list price, set list = net and discount = 0 and disc_perc = 0
-- v2.9 CB 12/03/2015 - Issue #1469 - Deal with finance and late charges and chargebacks
-- vTAG - 030518 - performance.  Dont use get_buying_group_name function. remove arnarel from joins - don't need. re-arrange joins
-- v3.0 CB 10/04/2018 - Issue #1663 - Invoice Option for Contract Pricing
-- v3.1 CB 20/04/2018 - Issue #1663 - Use view for Invoice Option for Contract Pricing
-- v3.2 CB 25/04/2018 - Add in view for promo discount list and override

-- 1 -- order h  - freight and tax
-- tag - don't even look for detail lines... dont need them
SELECT   
-- v2.6 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,   
-- v2.6 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name, 
cv.buying_group parent, -- v2.6  
bg.customer_name parent_name,
-- dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v2.6 
h.cust_code,  
b.customer_name AS customer_name,  
i.doc_ctrl_num,  
t.days_due AS trm,  
'Invoice' AS type,
--case when h.type = 'I' then 'Invoice' else 'Credit' end as type,  
CONVERT(VARCHAR(12),DATEADD(d,x.date_doc-639906,'1/1/1753'),101) AS inv_date,
-- convert(varchar(12), h.date_shipped, 101) as inv_date,  
ROUND((h.total_tax  + h.freight),2) AS inv_tot,  
0 AS mer_tot,  
0 AS net_amt,  
h.freight AS freight,  
h.total_tax AS tax,  
0 AS mer_disc,  
 ROUND((h.total_tax  + h.freight),2) AS inv_due,  
0 AS disc_perc,  
CASE WHEN x.date_due <> 0 THEN
RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,x.date_due-639906,'1/1/1753'),101),4)    
+ '/'+  
LEFT(CONVERT(VARCHAR(12),DATEADD(dd,x.date_due-639906,'1/1/1753'),101),2)  
ELSE CONVERT(VARCHAR(4),DATEPART(YEAR,GETDATE()))+'/'+CONVERT(VARCHAR(2), DATEPART(MONTH,GETDATE()))
END
AS due_year_month,  
x.date_doc AS xinv_date
-- convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date
--,NULL as ndd -- v2.1   -- v2.4

FROM dbo.cvo_orders_all cv (NOLOCK) -- v2.6
JOIN dbo.orders h (NOLOCK)  ON   h.order_no = cv.order_no  -- v2.6
	AND  h.ext = cv.ext   -- v2.6
JOIN dbo.orders_invoice i (NOLOCK) ON h.order_no =i.order_no AND h.ext = i.order_ext  
--join artrx x (nolock) on i.doc_ctrl_num = x.doc_ctrl_num  
JOIN dbo.artrx x (NOLOCK) ON i.trx_ctrl_num = x.trx_ctrl_num  
--left join dbo.arnarel r (nolock) on h.cust_code = r.child  
--left join dbo.arcust m (nolock)on r.parent = m.customer_code  
LEFT JOIN arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
JOIN dbo.arcust B (NOLOCK)ON h.cust_code = b.customer_code  
--join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
--join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
--join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
JOIN dbo.arterms t (NOLOCK) ON  h.terms = t.terms_code  
--join CVO_min_display_vw z (nolock) on z.order_no = d.order_no and h.ext = z.order_ext and d.display_line = z.min_line
 

WHERE (h.freight <> 0 OR h.total_tax <> 0)  
AND h.type = 'I'  
AND h.terms NOT LIKE 'INS%'   
AND x.void_flag <> 1     --v2.0  
AND cv.buying_group > '' -- v2.6
-- v2.6 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5


UNION  ALL
  
-- 2 -- order lines  
SELECT   
cv.buying_group parent, -- v2.6  
bg.customer_name parent_name,
h.cust_code,  
b.customer_name AS customer_name,  
i.doc_ctrl_num,  
t.days_due AS trm,  
'Invoice' AS type,
CONVERT(VARCHAR(12),DATEADD(dd,(x.date_doc)-639906,'1/1/1753'),101) AS inv_date,
-- v3.1 Start
CASE WHEN (MAX(ISNULL(ld.list,0)) = 0) THEN -- v3.2
CASE WHEN MAX(ISNULL(qv.net_only,'N')) = 'N' THEN
	SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) 
	ELSE
	SUM(ROUND(d.curr_price * d.shipped,2)) END
ELSE -- v3.2
SUM(d.Shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2)) -- v3.2
END -- v3.2
AS inv_tot, 
CASE WHEN (MAX(ISNULL(ld.list,0)) = 0) THEN -- v3.2
CASE WHEN MAX(ISNULL(qv.net_only,'N')) = 'N' THEN
	SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) 
	ELSE
	SUM(ROUND(d.curr_price * d.shipped,2)) END
ELSE -- v3.2
SUM(d.Shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2)) -- v3.2
END -- v3.2
AS mer_tot,
-- v3.1 End
0 AS net_amt,  
0 AS freight,  
0 AS tax,  
SUM(d.Shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2)) AS mer_disc, 
SUM(d.Shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2)) AS inv_due,   
-- v3.1 Start
CASE WHEN (MAX(ISNULL(ld.list,0)) = 0) THEN -- v3.2
	CASE WHEN ISNULL(qv.net_only,'N') = 'N' THEN 
	CASE 	WHEN SUM(CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) = 0 THEN 0
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 THEN -- two levels of discount in play
			ROUND(1 - (SUM(d.shipped*ROUND(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) END)/100)),2)) 
			/
			SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) ), 2)
		WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
			(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 
		ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END
	ELSE 0 END 
ELSE 0 END -- v3.2
-- v3.1 End
AS disc_perc,  
RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),4)    
+ '/'+  
LEFT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),2)  
AS due_year_month,  
x.date_doc AS xinv_date
FROM 
cvo_orders_all cv (NOLOCK) -- v2.6
JOIN orders h (NOLOCK)  
ON   h.order_no = cv.order_no  -- v2.6
AND  h.ext = cv.ext   -- v2.6 
JOIN orders_invoice i (NOLOCK) ON h.order_no =i.order_no AND h.ext = i.order_ext  
JOIN arterms t (NOLOCK) ON h.terms = t.terms_code  
JOIN artrx x (NOLOCK) ON i.doc_ctrl_num = x.doc_ctrl_num  
LEFT JOIN arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
JOIN arcust B (NOLOCK)ON h.cust_code = b.customer_code  
JOIN ord_list d (NOLOCK) ON h.order_no = d.order_no AND h.ext = d.order_ext  
JOIN Cvo_ord_list c (NOLOCK) ON  d.order_no =c.order_no AND d.order_ext = c.order_ext AND d.line_no = c.line_no  
JOIN CVO_disc_percent p (NOLOCK) ON d.order_no = p.order_no AND d.order_ext = p.order_ext AND d.line_no = p.line_no 
LEFT JOIN dbo.cvo_bg_contact_pricing_check_vw qv ON h.cust_code = qv.customer_key AND d.part_no = qv.part_no -- v3.1
LEFT JOIN dbo.cvo_promo_discount_vw ld (NOLOCK) ON cv.promo_id = ld.promo_id AND cv.promo_level = ld.promo_level -- v3.2
WHERE 
cv.buying_group > '' -- v2.6
AND d.shipped > 0  
AND h.type = 'I'  
AND h.terms NOT LIKE 'INS%'   
AND x.void_flag <> 1     --v2.0  
GROUP BY cv.buying_group, bg.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, -- v2.6
t.days_due, h.type, x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) 
,qv.net_only
 
  
UNION   ALL
  
-- 3 -- cr order header  - tax and freight portion
SELECT   
-- v2.6 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,       
-- v2.6 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name, 
cv.buying_group parent, -- v2.6  
-- dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v2.6 
bg.customer_name parent_name,
h.cust_code,  
b.customer_name AS customer_name,  
i.doc_ctrl_num,  
t.days_due AS trm,  
'Credit' AS type,
--case when h.type = 'I' then 'Invoice' else 'Credit' end as type,  
CONVERT(VARCHAR(12),DATEADD(dd,(x.date_doc)-639906,'1/1/1753'),101) AS inv_date,
-- convert(varchar(12), h.date_shipped, 101) as inv_date,  
ROUND((h.total_tax  + h.freight)  ,2) * -1  AS inv_tot,  
0 AS mer_tot,  
0 AS net_amt,  
h.freight * -1 AS freight,  
h.total_tax * -1 AS tax,  
0 AS mer_disc,  
ROUND(h.total_tax  + h.freight ,2) * -1 AS inv_due,  
0 AS disc_perc,  
RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_due)-639906,'1/1/1753'),101),4)    
+ '/' +  
LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_due)-639906,'1/1/1753'),101),2)  
AS due_year_month,  
x.date_doc AS xinv_date
-- convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date
-- ,NULL as ndd -- v2.1    -- v2.4
FROM
cvo_orders_all cv (NOLOCK) -- v2.6

JOIN orders h (NOLOCK) 
ON   h.order_no = cv.order_no  -- v2.6
AND  h.ext = cv.ext   -- v2.6 
JOIN orders_invoice i (NOLOCK) ON h.order_no =i.order_no AND h.ext = i.order_ext  
JOIN artrx x (NOLOCK) ON i.doc_ctrl_num = x.doc_ctrl_num AND x.trx_type = 2032  
--join ord_list d (nolock) on h.order_no = d.order_no and h.ext = d.order_ext  
--left join arnarel r (nolock) on h.cust_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
JOIN arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
JOIN arcust B (NOLOCK)ON h.cust_code = b.customer_code  
--join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no  
--join CVO_disc_percent p (nolock) on d.order_no = p.order_no and d.order_ext = p.order_ext and d.line_no = p.line_no  
JOIN arterms t (NOLOCK) ON h.terms = t.terms_code  
--join CVO_min_display_vw z (nolock) on z.order_no = d.order_no and z.order_ext = d.order_ext and d.display_line = z.min_line  

WHERE cv.buying_group > '' -- v2.6
AND (h.freight <> 0 OR h.total_tax <> 0)  
AND h.type = 'C'  
AND h.terms NOT LIKE 'INS%'   
AND x.void_flag <> 1     --v2.0  

-- v2.6 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5
 
--and x.date_doc between dbo.adm_get_pltdate_f('04/01/2013') and dbo.adm_get_pltdate_F('04/10/2013')
 
  
UNION  ALL
  --  4 -- cr order lines  
SELECT   
-- v2.6 dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,        
-- v2.6 dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name,   
cv.buying_group parent, -- v2.6  
-- dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v2.6 
bg.customer_name parent_name,
h.cust_code,  
b.customer_name AS customer_name,  
i.doc_ctrl_num,  
t.days_due AS trm,  
'Credit' AS type,
--case when h.type = 'I' then 'Invoice' else 'Credit' end as type,  
--datediff(dd,'1/1/1753',h.invoice_date) + 639906 as inv_date,  
--convert(varchar(12), h.date_shipped, 101)  as inv_date,  
CONVERT(VARCHAR(12),DATEADD(dd,(x.date_doc)-639906,'1/1/1753'),101) AS inv_date,
-- START v2.8
SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) * -1 AS inv_tot, 
--sum(round((c.list_price * d.cr_shipped),2)) * -1 as inv_tot,
-- END v2.8  
--sum(round((curr_price * d.cr_shipped),2)) * -1 as inv_tot,  
-- START v2.8
SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) * -1 AS mer_tot,  
--sum(round((c.list_price * d.cr_shipped),2)) * -1 as mer_tot,  
--sum(round((curr_price * d.cr_shipped),2)) * -1 as mer_tot,  
0 AS net_amt,  
0 AS freight,  
0 AS tax,  
--sum(round(((d.curr_price*(1-(d.discount/100)) * d.cr_shipped)),2)) * -1 as mer_disc,  
--sum(round(((d.curr_price*(1-(d.discount/100)) * d.cr_shipped)),2))  * -1 as inv_due,
-- START v2.8  
SUM(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1 AS mer_disc,  
--sum(d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1 as mer_disc,  
SUM(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1 AS inv_due,  
--sum(d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1 as inv_due,  
-- END v2.8
-- p.disc_perc,  
--disc_perc = CASE WHEN max(d.discount) > 0 THEN max(d.discount/100) ELSE p.disc_perc END,  
-- START v2.8
CASE WHEN SUM(CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) = 0 THEN 0 
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 THEN -- two levels of discount in play
		ROUND(1 - (SUM(d.cr_shipped*ROUND(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) END)/100)),2)) 
		/
		SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) ), 2)
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
		(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) /100 
	ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END
	AS disc_perc,    
/*
disc_perc = CASE WHEN sum(c.list_price) = 0 then 0 
	when d.discount > 0 and p.disc_perc <> 0 then -- two levels of discount in play
		round(1 - (sum(d.cr_shipped*round(curr_price-(curr_price*(d.discount/100)),2)) 
		/
		sum(round((c.list_price * d.cr_shipped),2)) ), 2)
	WHEN D.DISCOUNT > 0 AND P.DISC_PERC = 0 THEN 
		d.discount/100 
	ELSE p.disc_perc END,    
*/
-- END v2.8
--right(convert(varchar(12), dateadd(dd, datediff(dd, '1/1/1753', h.date_shipped) + 639906 + convert(int,right(t.days_due,2)) - 639906, '1/1/1753'),101) ,4)  
--+ '/'+  
--left(convert(varchar(12), dateadd(dd, datediff(dd, '1/1/1753', h.date_shipped) + 639906 + convert(int,right(t.days_due,2)) - 639906, '1/1/1753'),101) ,2)  
RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),4)    
+ '/'+  
LEFT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),2)  
AS due_year_month, 
x.date_doc AS xinv_date
--convert(int,datediff(dd,'1/1/1753',h.date_shipped) + 639906) as xinv_date
-- ,SUM(CASE d.part_no WHEN 'Credit Return Fee' THEN (d.cr_shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) ELSE 0 END) * -1 AS ndd -- v2.1  -- v2.4
FROM 
cvo_orders_all cv (NOLOCK) -- v2.6

JOIN orders h (NOLOCK)  
ON   h.order_no = cv.order_no  -- v2.6
AND  h.ext = cv.ext   -- v2.6
JOIN orders_invoice i (NOLOCK) ON h.order_no =i.order_no AND h.ext = i.order_ext  
JOIN artrx x (NOLOCK) ON i.doc_ctrl_num = x.doc_ctrl_num AND x.trx_type = 2032  
--left join arnarel r (nolock) on h.cust_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code
JOIN arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group  
JOIN arcust B (NOLOCK)ON h.cust_code = b.customer_code  
JOIN ord_list d (NOLOCK) ON h.order_no = d.order_no AND h.ext = d.order_ext  
JOIN Cvo_ord_list c (NOLOCK) ON  d.order_no =c.order_no AND d.order_ext = c.order_ext AND d.line_no = c.line_no  
JOIN CVO_disc_percent p (NOLOCK) ON d.order_no = p.order_no AND d.order_ext = p.order_ext AND d.line_no = p.line_no  
JOIN arterms t (NOLOCK) ON h.terms = t.terms_code  

WHERE cv.buying_group > '' -- v2.6
AND d.cr_shipped > 0  
--and (d.display_line  <> 1 or (h.freight = 0 and h.total_tax = 0))  
AND h.type = 'C'  
AND h.terms NOT LIKE 'INS%'   
AND x.void_flag <> 1     --v2.0 
AND d.part_no <> 'Credit Return Fee' -- v2.4 

-- v2.6 AND dbo.f_cvo_get_buying_group(h.cust_code, CONVERT(varchar(10),DATEADD(DAY, x.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5

GROUP BY cv.buying_group, bg.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, t.days_due, x.date_due, h.type, -- v2.6 
-- START v2.8
x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)  
--x.date_doc, d.discount, disc_perc 
-- END v2.8
  
UNION  ALL
  
-- 5 -- AR only records invoice  
SELECT   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,       
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name, 
h.customer_code,  
b.customer_name AS customer_name,  
h.doc_ctrl_num,  
t.days_due AS trm,  
'Invoice' AS type,
--case when h.trx_type = 2031 then 'Invoice' else 'Credit' end as type,  
--h.date_doc as inv_date,  
CONVERT(VARCHAR(12),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101) AS inv_date,  
CASE WHEN d.sequence_id = 1 THEN ROUND((d.unit_price * d.qty_shipped) + h.amt_tax  + h.amt_freight  ,2)
      ELSE ROUND((d.unit_price * d.qty_shipped),2)  
END AS inv_tot,  
ROUND((d.unit_price * d.qty_shipped),2) AS mer_tot,  
0 AS net_amt,  
CASE WHEN d.sequence_id  = 1 THEN h.amt_freight ELSE 0  END AS freight,  
CASE WHEN d.sequence_id  = 1 THEN h.amt_tax   ELSE 0  END AS tax,  
(d.unit_price * d.qty_shipped)- d.discount_amt AS mer_disc,  
CASE WHEN d.sequence_id = 1 THEN ROUND((d.unit_price * d.qty_shipped)- d.discount_amt + h.amt_tax  + h.amt_freight  ,2)  
      ELSE ROUND((d.unit_price * d.qty_shipped)-d.discount_amt,2)  
END AS inv_due,  
-- d.discount_prc,  
d.discount_prc/100,  
SUBSTRING(CONVERT(VARCHAR(12),DATEADD(dd,h.date_due - 639906,'1/1/1753'),101),7,4)  
+ '/'+  
SUBSTRING(CONVERT(VARCHAR(12),DATEADD(dd,h.date_due - 639906,'1/1/1753'),101),1,2)  
AS due_year_month,  
h.date_doc AS xinv_date
-- ,NULL as ndd -- v2.1    -- v2.4
FROM artrx_all h (NOLOCK)  
JOIN artrxcdt d (NOLOCK) ON h.trx_ctrl_num = d.trx_ctrl_num  
--left join arnarel r (nolock) on h.customer_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
JOIN arcust B (NOLOCK)ON h.customer_code = b.customer_code  
JOIN arterms t (NOLOCK) ON h.terms_code = t.terms_code  
WHERE (h.order_ctrl_num = '' OR LEFT(h.doc_desc,3) NOT IN ('SO:', 'CM:'))  
AND h.trx_type IN (2031)  
AND h.doc_ctrl_num NOT LIKE 'FIN%'   
AND h.doc_ctrl_num NOT LIKE 'CB%'   
AND h.terms_code NOT LIKE 'INS%'   
AND h.void_flag <> 1     --v2.0  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5

  
UNION  ALL
  
-- 6 -- AR only records credit  
SELECT   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
-- v2.5 r.parent,          
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
-- v2.5 m.customer_name as parent_name, 
h.customer_code,  
b.customer_name AS customer_name,  
h.doc_ctrl_num,  
t.days_due AS trm,  
'Credit' AS type,
--case when h.trx_type = 2031 then 'Invoice' else 'Credit' end as type,  
--h.date_doc as inv_date,  
CONVERT(VARCHAR(12),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101) AS inv_date,  
CASE WHEN d.sequence_id = 1 THEN CASE WHEN h.recurring_flag = 2 THEN h.amt_tax*-1  
          WHEN h.recurring_flag = 3 THEN h.amt_freight*-1  
          WHEN h.recurring_flag = 4 THEN ROUND(h.amt_tax + h.amt_freight,2)*-1  
          ELSE ROUND((d.unit_price * d.qty_returned) + h.amt_tax  + h.amt_freight  ,2)*-1 END  
            
      ELSE ROUND((d.unit_price * d.qty_returned),2)*-1  
--case when d.sequence_id = 1 then round((d.unit_price * d.qty_returned) + h.amt_tax  + h.amt_freight  ,2)*-1  
--      else round((d.unit_price * d.qty_returned),2)*-1  
END AS inv_tot,  
CASE WHEN h.recurring_flag < 2 THEN ROUND((d.unit_price * d.qty_returned),2)*-1   
  ELSE 0.0 END AS mer_tot,  
--round((d.unit_price * d.qty_returned),2)*-1 as mer_tot,  
0 AS net_amt,  
CASE   
WHEN d.sequence_id  = 1 AND h.recurring_flag IN (1,3,4) THEN h.amt_freight *-1  -- v2.3 add recurring_flag 1 
ELSE 0  
END AS freight,  
CASE   
WHEN d.sequence_id  = 1 AND h.recurring_flag IN (1,2,4) THEN h.amt_tax*-1   -- v2.3 add recurring_flag 1
ELSE 0  
END AS tax,  
CASE WHEN h.recurring_flag < 2 THEN ((d.unit_price * d.qty_returned)-d.discount_amt)*-1   
  ELSE 0.0 END AS mer_disc,  
--((d.unit_price * d.qty_returned)-d.discount_amt)*-1 as mer_disc,  
CASE WHEN d.sequence_id = 1 THEN CASE WHEN h.recurring_flag = 2 THEN h.amt_tax*-1  
          WHEN h.recurring_flag = 3 THEN h.amt_freight*-1  
          WHEN h.recurring_flag = 4 THEN ROUND(h.amt_tax + h.amt_freight,2)*-1  
          ELSE ROUND((d.unit_price * d.qty_returned)-d.discount_amt + h.amt_tax  + h.amt_freight  ,2)*-1 END  
      ELSE ROUND((d.unit_price * d.qty_returned)-d.discount_amt,2)*-1  
--case when d.sequence_id = 1 then round((d.unit_price * d.qty_returned)-d.discount_amt + h.amt_tax  + h.amt_freight  ,2)*-1  
--      else round((d.unit_price * d.qty_returned)-d.discount_amt,2)*-1  
END AS inv_due,  
-- d.discount_prc,  
d.discount_prc/100,  
CASE h.date_due WHEN 0 THEN  
 SUBSTRING(CONVERT(VARCHAR(10),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101),7,4)  
 +'/'+ SUBSTRING(CONVERT(VARCHAR(10),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101),1,2)  
ELSE SUBSTRING(CONVERT(VARCHAR(10),DATEADD(dd,h.date_due - 639906,'1/1/1753'),101),7,4)  
 +'/'+ SUBSTRING(CONVERT(VARCHAR(10),DATEADD(dd,h.date_due - 639906,'1/1/1753'),101),1,2)  
END AS due_year_month,  
h.date_doc AS xinv_date
--,NULL as ndd -- v2.1    -- v2.4
FROM artrx_all h (NOLOCK)  
JOIN artrxcdt d (NOLOCK) ON h.trx_ctrl_num = d.trx_ctrl_num  
--left join arnarel r (nolock) on h.customer_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
JOIN arcust B (NOLOCK)ON h.customer_code = b.customer_code  
LEFT JOIN arterms t (NOLOCK) ON b.terms_code = t.terms_code    --v3.0 Use Customer Terms as CM does not have terms code  
WHERE LEFT(h.doc_desc,3) NOT IN ('SO:', 'CM:')  
AND h.trx_type IN (2032)  
AND h.doc_ctrl_num NOT LIKE 'FIN%'   
AND h.doc_ctrl_num NOT LIKE 'CB%'   
-- and h.terms_code not like 'INS%' -- tag - don't care about terms on a credit memo  
AND h.void_flag <> 1     --v2.0  
AND ((recurring_flag < 2) OR (recurring_flag > 1 AND d.sequence_id = 1))  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' -- v2.5
-- START v2.7
AND NOT EXISTS (SELECT 1 FROM cvo_debit_promo_customer_det WHERE trx_ctrl_num = h.trx_ctrl_num)
-- END v2.7

UNION  ALL
  
-- 6 AR Split only records  *** NEW ***  
SELECT   
parent,     
parent_name,                                
cust_code,    
customer_name,                              
doc_ctrl_num,   
trm,  
type,      
inv_date,       
inv_tot,                                   
mer_tot,                                   
net_amt,       
freight,                                   
tax,                                       
mer_disc,                                  
inv_due,                                   
disc_perc,                                 
due_year_month,   
xinv_date
-- ,NULL as ndd -- v2.1      -- v2.4
FROM CVO_BGLog_installment_source_vw (NOLOCK)  
  
-- START v2.7
UNION ALL

-- 8 -- cr debit promo tax line  
SELECT   
cv.buying_group parent, -- v1.2  
--dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2  
bg.customer_name parent_name,
b.customer_code cust_code,  
b.customer_name AS customer_name,  
x.doc_ctrl_num,  
t.days_due AS trm,  
'Credit' AS type, 
CONVERT(VARCHAR(12),DATEADD(d,x.date_doc-639906,'1/1/1753'),101) AS inv_date,
ROUND((x.amt_tax)  ,2) * -1  AS inv_tot,  
0 AS mer_tot,  
0 AS net_amt,  
0 AS freight,  
x.amt_tax * -1 AS tax,  
0 AS mer_disc,  
ROUND(x.amt_tax ,2) * -1 AS inv_due,  
0 AS disc_perc,  CASE   x.date_due WHEN 0 THEN
	RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_due)-639906,'1/1/1753'),101),2) 
END
AS due_year_month,  
x.date_doc AS xinv_date
-- ,3 as rec_type -- v1.0

FROM 
(SELECT DISTINCT dd.trx_ctrl_num, co.order_no, co.ext, buying_group FROM  cvo_debit_promo_customer_det dd INNER JOIN  cvo_orders_all co ON dd.order_no = co.order_no AND dd.ext = co.ext) cv 
JOIN artrx x (NOLOCK) ON cv.trx_ctrl_num = x.trx_ctrl_num
-- left join arnarel r (nolock) on r.child = x.customer_code
JOIN arcust B (NOLOCK) ON b.customer_code  = x.customer_code
JOIN arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
JOIN arterms t (NOLOCK) ON b.terms_code = t.terms_code  
WHERE (x.amt_tax <> 0) 
AND x.trx_type = 2032
AND x.terms_code NOT LIKE 'INS%'   
AND x.void_flag <> 1     
AND cv.buying_group > '' -- v1.2

  
UNION  ALL
  
--  4 -- cr order lines - debit promos 
SELECT   
cv.buying_group parent, -- v1.2  
-- dbo.f_cvo_get_buying_group_name	(cv.buying_group) parent_name, -- v1.2   
bg.customer_name parent_name,
h.cust_code,  
b.customer_name AS customer_name,  
xx.doc_ctrl_num,  
t.days_due AS trm,  
'Credit' AS type,  
CONVERT(VARCHAR(12),DATEADD(d,x.date_doc-639906,'1/1/1753'),101) AS inv_date,
--convert(varchar(12), h.date_shipped, 101)  as inv_date, 
-- START v2.8 
SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) * -1 AS inv_tot,  
--sum(round((c.list_price * d.shipped),2)) * -1 as inv_tot,  
SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) * -1 AS mer_tot,  
--sum(round((c.list_price * d.shipped),2)) * -1 as mer_tot,  
-- END v2.8
0 AS net_amt,  
0 AS freight,  
0 AS tax,  
-- START v2.8
CASE WHEN SUM(dd.credit_amount) <= SUM(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1))
THEN SUM(dd.credit_amount) * -1
ELSE
    SUM(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1
END AS mer_disc,  
/*
case when sum(dd.credit_amount) <= sum(d.shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1))
then sum(dd.credit_amount) * -1
else
    sum(d.shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1
end as mer_disc, 
*/
CASE WHEN SUM(dd.credit_amount) <= SUM(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) 
THEN SUM(dd.credit_amount) * -1
ELSE
SUM(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1
END AS inv_due,  
/*
case when sum(dd.credit_amount) <= sum(d.shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) 
then sum(dd.credit_amount) * -1
else
sum(d.shipped * ROUND(curr_price -(curr_price * (d.discount / 100)),2,1)) * -1
end as inv_due,  
*/
CASE 	WHEN SUM(CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) = 0 THEN 0
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 THEN -- two levels of discount in play
		ROUND(1 - (SUM(d.shipped*ROUND(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100)),2)) 
		/
		SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) ), 2)
	WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
		(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 
	ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END
	AS disc_perc,
/*
disc_perc = CASE 	when suM(c.list_price) = 0 then 0
	WHEN d.discount > 0 and p.disc_perc <> 0 then -- two levels of discount in play
		round(1 - (sum(d.shipped*round(curr_price-(curr_price*(d.discount/100)),2)) 
		/
		sum(round((c.list_price * d.shipped),2)) ), 2)
	WHEN D.DISCOUNT > 0 AND P.DISC_PERC = 0 THEN 
		d.discount/100 
	ELSE p.disc_perc END, 
*/
-- END v2.8
CASE MAX(x.date_due) WHEN 0 THEN
	RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	LEFT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	LEFT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),2) 
END
-- END v1.0 
AS due_year_month,  
x.date_doc AS xinv_date
-- ,3 as rec_type -- v1.0
FROM
cvo_debit_promo_customer_det dd 
INNER JOIN ord_list d (NOLOCK) ON d.order_no = dd.order_no AND d.order_ext = dd.ext AND d.line_no = dd.line_no

INNER JOIN orders h (NOLOCK)  ON h.order_no = dd.order_no AND h.ext = dd.ext
JOIN cvo_orders_all cv (NOLOCK) -- v1.2
ON   h.order_no = cv.order_no  -- v1.2
AND  h.ext = cv.ext   -- v1.2
JOIN artrx xx ON dd.trx_ctrl_num = xx.trx_ctrl_num
JOIN orders_invoice i (NOLOCK) ON h.order_no =i.order_no AND h.ext = i.order_ext  
JOIN artrx x (NOLOCK) ON i.trx_ctrl_num = x.trx_ctrl_num   
--left join arnarel r (nolock) on h.cust_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
JOIN arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
JOIN arcust B (NOLOCK)ON h.cust_code = b.customer_code  
JOIN Cvo_ord_list c (NOLOCK) ON  d.order_no =c.order_no AND d.order_ext = c.order_ext AND d.line_no = c.line_no  
JOIN CVO_disc_percent p (NOLOCK) ON d.order_no = p.order_no AND d.order_ext = p.order_ext AND d.line_no = p.line_no  
JOIN arterms t (NOLOCK) ON h.terms = t.terms_code  

WHERE cv.buying_group > '' -- v1.2 
AND d.shipped > 0  
AND h.terms NOT LIKE 'INS%'   
AND x.void_flag <> 1     


GROUP BY cv.buying_group, bg.customer_name, h.cust_code, b.customer_name, xx.doc_ctrl_num, t.days_due, x.date_due, h.type, -- v1.2
-- START v2.8
x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END)  
--x.date_doc, d.discount, disc_perc  
-- END v2.8
-- END v2.7

-- v2.9 Start
UNION ALL

SELECT   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1  
h.customer_code,  
b.customer_name AS customer_name,  
h.doc_ctrl_num,  
0 AS trm,  
CASE WHEN h.trx_type = 2061 THEN 'Finance Charge' WHEN h.trx_type = 2071 THEN 'Late Charge' ELSE '' END AS type,   
CONVERT(VARCHAR(12),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101) AS inv_date,  
h.amt_tot_chg inv_tot,  
h.amt_tot_chg AS mer_tot,  
0 AS net_amt,  
0 AS freight,  
0 tax,  
0 AS mer_disc,  
h.amt_tot_chg AS inv_due,  
0, 
CASE   h.date_due WHEN 0 THEN
	RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_due)-639906,'1/1/1753'),101),2) 
END
AS due_year_month,  
h.date_doc AS xinv_date
FROM artrx_all h (NOLOCK)  
--left join arnarel r (nolock) on h.customer_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
JOIN arcust B (NOLOCK)ON h.customer_code = b.customer_code  
WHERE h.trx_type IN (2061,2071)  
AND h.doc_ctrl_num NOT LIKE 'CB%'   
AND h.terms_code NOT LIKE 'INS%'   
AND h.void_flag <> 1  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' 

UNION ALL

SELECT   
dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) parent, -- v1.1
dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v1.1  
h.customer_code,  
b.customer_name AS customer_name,  
h.doc_ctrl_num,  
0 AS trm,  
CASE WHEN h.trx_type = 2061 THEN 'Finance Charge' WHEN h.trx_type = 2071 THEN 'Late Charge' ELSE '' END AS type,   
CONVERT(VARCHAR(12),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101) AS inv_date,  
h.amt_tot_chg inv_tot,  
h.amt_tot_chg AS mer_tot,  
0 AS net_amt,  
0 AS freight,  
0 tax,  
0 AS mer_disc,  
h.amt_tot_chg AS inv_due,  
0, 
CASE   h.date_due WHEN 0 THEN
	RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_doc)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_doc)-639906,'1/1/1753'),101),2) 
ELSE  
	RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_due)-639906,'1/1/1753'),101),4)      
	+ '/'+    
	LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_due)-639906,'1/1/1753'),101),2) 
END
AS due_year_month,  
h.date_doc AS xinv_date
FROM artrx_all h (NOLOCK)  
--left join arnarel r (nolock) on h.customer_code = r.child  
--left join arcust m (nolock)on r.parent = m.customer_code  
JOIN arcust B (NOLOCK)ON h.customer_code = b.customer_code  
WHERE h.trx_ctrl_num LIKE 'CB%'   
AND h.terms_code NOT LIKE 'INS%'   
AND h.void_flag <> 1  
AND dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' 
-- v2.9 End




GO
GRANT REFERENCES ON  [dbo].[CVO_BGLog_source_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_BGLog_source_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_BGLog_source_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_BGLog_source_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_BGLog_source_vw] TO [public]
GO
