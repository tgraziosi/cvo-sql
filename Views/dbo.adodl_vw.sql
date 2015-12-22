SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

--select * from adodl_vw where ordered <> 1

CREATE view [dbo].[adodl_vw] as

-- tag - 060412 - Fix Pricing where promo pricing is based on list price, not customer price.
-- tag - 1/30/2013 - updated pricing calculation

select 
	ol.order_no ,
	ol.order_ext,
	ol.line_no ,
	ol.location ,
	ol.part_no ,
	ol.description,
	ol.part_type,
	part_type_desc = 
		CASE part_type
			WHEN 'A' THEN 'Adjust Price'
			WHEN 'E' THEN 'Estimate'
			WHEN 'J' THEN 'Job'
			WHEN 'M' THEN 'Miscellaneous'
			WHEN 'P' THEN 'Inventory Item'
			ELSE ''
		END, 
	ol.uom ,
	ol.ordered ,
	ol.shipped ,
	ol.price_type,
	price_type_desc =
		CASE price_type
			WHEN '1' THEN 'Price level 1'
			WHEN '2' THEN 'Price level 2'
			WHEN '3' THEN 'Price level 3'
			WHEN '4' THEN 'Price level 4'
			WHEN '5' THEN 'Price level 5'
			WHEN 'P' THEN 'Promotional Price'
			WHEN 'Q' THEN 'Quote Price'
			WHEN 'X' THEN 'Manual override on-hold'
			WHEN 'Y' THEN 'Manual override releases'
			ELSE ''
		END,
	
	--select * from ord_list ol, cvo_ord_list col where ol.order_no = col.order_no and 
	--ol.order_ext = col.order_ext and ol.line_no = col.line_no
	--and ol.order_no = 1715226
		
	-- tag - 060412 - fix where list price promo pricing not appearing correctly
	CASE isnull(col.is_amt_disc,'N')   
		WHEN 'Y' THEN round((ol.curr_price - isnull(col.amt_disc,0)), 2)		
		ELSE round(ol.curr_price - (ol.curr_price * (ol.discount / 100.00)),2)
	END as price,
	CASE isnull(col.is_amt_disc,'N')   
	WHEN 'Y' THEN	round(ol.ordered * ol.curr_price,2) -  
					round((ol.ordered * isnull(col.amt_disc,0)),2)		
			ELSE	round(ol.ordered * ol.curr_price,2) -   
					round(( (ol.ordered * ol.curr_price) * (ol.discount / 100.00)),2)
	END as Ext_Price,
	--case
	--	when col.is_amt_disc = 'Y' then col.list_price - col.amt_disc
	--	else ol.price
	--end as price,
	--case
	--	when col.is_amt_disc = 'Y' then (col.list_price-col.amt_disc) * ol.ordered
	--	else ol.price * ol.ordered 
	--end as ext_price,	
	ol.taxable,
	taxable_desc=
		CASE taxable
			WHEN 0 THEN 'Tax included in price'
			WHEN 1 THEN 'Tax NOT included in price'
			ELSE ''
		END, 
	ol.sales_comm,
	lb_tracking_desc=
		CASE lb_tracking
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
			ELSE ''
		END,
	ol.service_agreement_flag, 

	x_order_no=ol.order_no ,
	x_order_ext=ol.order_ext,
	x_line_no=ol.line_no ,
	x_ordered=ol.ordered ,
	x_shipped=ol.shipped ,
	x_price=ol.price,
	x_ext_price = ol.price * ol.ordered ,	
	x_sales_comm=ol.sales_comm

	

from ord_list ol (nolock)
INNER JOIN cvo_ord_list col (nolock)
on ol.order_no = col.order_no and ol.order_ext = col.order_ext and ol.line_no = col.line_no


GO
GRANT REFERENCES ON  [dbo].[adodl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adodl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adodl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adodl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adodl_vw] TO [public]
GO
