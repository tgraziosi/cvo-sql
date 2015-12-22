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
SELECT  
orders.order_no,
orders.ext order_ext,
ar.doc_ctrl_num Invoice, -- tag 082613
ol.line_no,
ol.part_no,   
IsNull(co.promo_id,' ') as promo_id,
IsNull(co.promo_level,' ') as promo_level,
arcust.addr_sort1 as cust_type,
orders.cust_code,
arcust.customer_name,
Substring(orders.ship_to_region,1,2) as region,
orders.ship_to_region as territory,
ar.territory_code as ar_territory,
orders.salesperson,
orders.user_category as order_type,
orders.date_shipped, 
ar.date_applied,
CASE orders.type WHEN 'I' THEN 'Invoice' ELSE 'Return' END as doc_type,
inv.category as product_group,
inv.type_code as product_type,
inva.field_2 as product_style,
inva.category_2 as product_gender,
case inv.obsolete when 0 then 'No' 
    when 1 then 'Yes'
    else '' end as Obsolete, -- tag 082613
CASE IsNull(armaster.country_code,' ')
WHEN 'US' THEN 'Domestic' ELSE 'Intnl' END as dom_intl,
IsNull(armaster.country_code,' ') as country_code,
IsNull(armaster.state,' ') as state_code,
CASE orders.type WHEN 'I' THEN ol.shipped ELSE (ol.cr_shipped*-1) END as units_sold, 
-- use original list price
CASE orders.type WHEN 'I' THEN ol.shipped * 
		IsNull(case when ol.curr_price > col.orig_list_price then ol.curr_price
					when col.orig_list_price > col.list_price then col.orig_list_price 
					else col.list_price end,0)
		ELSE ol.cr_shipped * IsNull(case when ol.curr_price > col.orig_list_price then ol.curr_price
										 when col.orig_list_price > col.list_price then col.orig_list_price 
										 else col.list_price end,0) * -1 
END as list_price,
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
WHEN 'I' THEN CASE (ISNULL(COL.is_amt_disc,'n'))
        when 'Y' THEN round((OL.SHIPPED * OL.CURR_PRICE) - 
            (OL.SHIPPED * round(ISNULL(CoL.AMT_DISC,0),2)),2)
       	ELSE
            round((OL.SHIPPED * OL.CURR_PRICE) - 
            ( (OL.SHIPPED * OL.CURR_PRICE) * (ol.discount/ 100.00)),2)
        end       			  -- v10.7
   ELSE CASE ol.discount WHEN 0 THEN ol.curr_price * -ol.cr_shipped 
   -- START v11.6
   ELSE CASE WHEN col.orig_list_price = ol.curr_price THEN -ol.cr_shipped * 
		ROUND(col.orig_list_price - round((col.orig_list_price * ol.discount/100),2),2 )
      ELSE -ol.cr_shipped * ROUND((ol.curr_price - ROUND(ol.curr_price * ol.discount/100,2)),2,1) 
	  END
   --ELSE ROUND((l.curr_price - ROUND(cv1.amt_disc,2)),2,1) -- v10.7
   -- END v11.6
END END as net_amt,  

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
CASE WHEN ol.curr_price > col.orig_list_price THEN 0 ELSE
	CASE orders.type WHEN 'I' 
		THEN     
		case isnull(col.is_amt_disc,'n') 
    when 'y' then 
    round(ol.shipped * IsNull((case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end),0) -  ol.shipped * (ol.curr_price - round(isnull(col.amt_disc,0),2)),2)
    else
    round(ol.shipped * IsNull((case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end),0) - ol.shipped * (ol.curr_price - (ol.curr_price * (ol.discount / 100))),2)
	end
	ELSE CASE ol.discount WHEN 0 THEN -ol.cr_shipped * ((case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end) - ol.curr_price) 
	-- START v11.6
	ELSE CASE WHEN col.orig_list_price = ol.curr_price THEN 
	-ol.cr_shipped * ROUND(col.orig_list_price * ol.discount/100,2)
	ELSE -ol.cr_shipped * 
	round((((case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end)
	 - ol.curr_price) + ROUND(ol.curr_price * ol.discount/100,2)), 2) END END
	--ELSE (col.list_price - ol.curr_price) + ROUND(col.amt_disc,2) END -- v10.7  
	-- END v11.6 
	END 
END as discount_amount,      --v3.0 Total Discount 

case when isnull(col.orig_list_price,0) = 0 then 0 else
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
((
CASE WHEN ol.curr_price > col.orig_list_price THEN 0 ELSE
	CASE orders.type WHEN 'I' THEN 
	 case isnull(col.is_amt_disc,'n') 
     when 'y' then 
     round(ol.shipped * IsNull(case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end,0) -  ol.shipped * (ol.curr_price - round(isnull(col.amt_disc,0),2)),2)
     else
     round(ol.shipped * IsNull(case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end,0) - ol.shipped * (ol.curr_price - (ol.curr_price * (ol.discount / 100))),2)
	 end
	ELSE CASE ol.discount WHEN 0 THEN ol.cr_shipped * (case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end - ol.curr_price) 
	-- START v11.6
	ELSE CASE WHEN col.orig_list_price = ol.curr_price THEN ol.cr_shipped * ROUND(case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end * ol.discount/100,2) 
	ELSE ol.cr_shipped * round(((case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end - ol.curr_price) + ROUND(ol.curr_price * ol.discount/100,2)),2) END END
	--ELSE (col.list_price - ol.curr_price) + ROUND(col.amt_disc,2) END -- v10.7  
	-- END v11.6 
	END 
END
)
/
(CASE orders.type 
WHEN 'I' THEN ol.shipped * IsNull(case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end,0) 
				 ELSE ol.cr_shipped * IsNull(case when col.list_price > col.orig_list_price then col.list_price else col.orig_list_price end,0)  
END)
)*100 end AS DISCOUNT_PCT,



ol.return_code, -- 12/27/2012 - tag

x_date_shipped = dbo.adm_get_pltdate_f(orders.date_shipped)

FROM
ord_list ol (nolock) inner join orders on orders.order_no = ol.order_no and orders.ext = ol.order_ext
LEFT OUTER JOIN dbo.cvo_orders_all co  (nolock) ON orders.order_no = co.order_no AND 
orders.ext = co.ext
LEFT OUTER JOIN cvo_ord_list col (nolock) ON OL.order_no = col.order_no AND OL.order_ext = col.order_ext AND OL.line_no = col.line_no	
	INNER JOIN inv_master inv (nolock) ON OL.part_no = inv.part_no
	INNER JOIN inv_master_add inva (nolock) ON OL.part_no = inva.part_no
    INNER JOIN arcust (nolock) ON ORDERS.cust_code = arcust.customer_code
    INNER JOIN armaster (nolock) ON ORDERS.cust_code = armaster.customer_code and orders.ship_to = armaster.ship_to_code
	LEFT OUTER JOIN arsalesp (nolock) ON orders.salesperson = arsalesp.salesperson_code
	-- get date applied from AR 
	left outer join orders_invoice oi (nolock) on  ORDERS.order_no = oi.order_no AND ORDERS.ext = oi.order_ext 
	left outer join artrx ar (nolock) on ar.trx_ctrl_num = oi.trx_ctrl_num
where (ol.shipped <> 0 or ol.cr_shipped <> 0) and orders.status ='t'

-- TAG 031114
UNION ALL

-- DEBIT PROMOS - TREAT LIKE A DISCOUNT
select 
dp.order_no    
,dp.ext
,arx.doc_ctrl_num Invoice         
,dp.line_no     
,ol.part_no                        
,dh.debit_promo_id promo_id
,dh.debit_promo_level promo_level                    
,ar.addr_sort1 cust_type                                
,ar.customer_code cust_code  
,ar.address_name customer_name                            
,Substring(O.ship_to_region,1,2) as region
,o.ship_to_region territory
,ar.territory_code ar_territory
,o.salesperson 
,o.user_category order_type 
,o.date_shipped            
,arx.date_applied 
,'Credit' as doc_type 
,i.category product_group 
,i.type_code product_type 
,ia.field_2 product_style                            
,ia.category_2 product_gender  
,case i.obsolete when 0 then 'No' 
    when 1 then 'Yes'
    else '' end as Obsolete, -- tag 082613
CASE IsNull(ar.country_code,' ')
WHEN 'US' THEN 'Domestic' ELSE 'Intnl' END as dom_intl,
IsNull(ar.country_code,' ') as country_code,
IsNull(ar.state,' ') as state_code,
-- CASE o.type WHEN 'I' THEN ol.shipped ELSE (ol.cr_shipped*-1) END as units_sold, 
0 as units_sold,
CASE o.type WHEN 'I' THEN ol.shipped * IsNull(col.orig_list_price,0) * -1
				 ELSE ol.cr_shipped * IsNull(col.orig_list_price,0)  
	END as list_price,
-- 10/21/2013 - FIX price calculation
CASE o.type 
WHEN 'I' THEN 
    CASE (ISNULL(COL.is_amt_disc,'n'))
        when 'Y' THEN (ROUND(OL.SHIPPED * OL.CURR_PRICE,2) - 
            ROUND((OL.SHIPPED * ISNULL(CoL.AMT_DISC,0)),2)) * -1
       	ELSE
            (ROUND(OL.SHIPPED * OL.CURR_PRICE,2) - 
            ROUND(( (OL.SHIPPED * OL.CURR_PRICE) * (ol.discount/ 100.00)),2) ) * -1
        end       			 
ELSE (ol.cr_shipped * ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2)) 
END as net_amt,

CASE o.type 
WHEN 'I' THEN
    case isnull(col.is_amt_disc,'n') 
    when 'y' then 
    (ol.shipped * IsNull(col.orig_list_price,0) -  ol.shipped * round(ol.curr_price - isnull(col.amt_disc,0),2)) * -1
    else
    (ol.shipped * IsNull(col.orig_list_price,0) - (ol.shipped * ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2))) * -1
	end
	ELSE (ol.cr_shipped * IsNull(col.orig_list_price,0) - (ol.cr_shipped * ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2))) 
END as discount_amount
,
case when col.orig_list_price = 0 then 0 else
round((1 - 
(CASE o.type 
WHEN 'I' THEN 
    CASE (ISNULL(COL.is_amt_disc,'n'))
        when 'Y' THEN (ROUND(OL.SHIPPED * OL.CURR_PRICE,2) - 
            ROUND((OL.SHIPPED * ISNULL(CoL.AMT_DISC,0)),2)) * -1
       	ELSE
            (ROUND(OL.SHIPPED * OL.CURR_PRICE,2) - 
            ROUND(( (OL.SHIPPED * OL.CURR_PRICE) * (ol.discount/ 100.00)),2) ) * -1
        end       			 
ELSE (ol.cr_shipped * ROUND(ol.curr_price - (ol.curr_price * (ol.discount / 100)),2)) 
END)/
(
CASE o.type WHEN 'I' THEN ol.shipped * IsNull(col.orig_list_price,0) * -1
				 ELSE ol.cr_shipped * IsNull(col.orig_list_price,0)  
	END
))*100, 2) end AS DISCOUNT_PCT
,ol.return_code 
,dbo.adm_get_pltdate_f(o.date_shipped) x_date_shipped
From 
cvo_debit_promo_customer_det dp
inner join ord_list ol on ol.order_no = dp.order_no and ol.order_ext = dp.ext and ol.line_no = dp.line_no
inner join cvo_ord_list col on col.order_no = dp.order_no and col.order_ext = dp.ext and col.line_no = dp.line_no
inner join orders o on o.order_no = ol.order_no and o.ext = ol.order_ext
inner join armaster ar on ar.customer_code = o.cust_code and ar.ship_To_code = o.ship_to
inner join inv_master i on i.part_no = ol.part_no
inner join inv_master_add ia on ia.part_no = ol.part_no
left outer join artrxcdt arx on dp.trx_ctrl_num = arx.trx_ctrl_num
inner join cvo_debit_promo_customer_hdr dh on dh.hdr_rec_id = dp.hdr_rec_id
where arx.gl_rev_acct like '4530%' 
AND (ol.shipped <> 0 or ol.cr_shipped <> 0) and O.status ='t'














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
