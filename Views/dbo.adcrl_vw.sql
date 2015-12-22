SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[adcrl_vw]
as
select 
	order_no ,
	line_no ,
	location ,
	part_no ,
	description,
	part_type,
	part_type_desc = 
		CASE part_type
			WHEN 'A' THEN 'Adjust Price'
			WHEN 'E' THEN 'Estimate'
			WHEN 'J' THEN 'Job'
			WHEN 'M' THEN 'Miscellaneous'
			WHEN 'P' THEN 'Inventory Item'
			ELSE ''
		END, 
	uom ,
	cr_ordered ,
	cr_shipped ,
	price_type,
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
	price,
	ext_price = price * cr_ordered ,	
	taxable,
	taxable_desc=
		CASE taxable
			WHEN 0 THEN 'Tax included in price'
			WHEN 1 THEN 'Tax NOT included in price'
			ELSE ''
		END, 
	sales_comm,
	lb_tracking_desc=
		CASE lb_tracking
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
			ELSE ''
		END, 
	order_ext,
	x_cr_ordered=cr_ordered ,
	x_cr_shipped=cr_shipped ,
	x_price=price,
	x_ext_price = price * cr_ordered ,	
	x_sales_comm=sales_comm
FROM
	ord_list
UNION
select 
	order_no ,
	line_no ,
	location ,
	part_no ,
	description,
	part_type,
	part_type_desc = 
		CASE part_type
			WHEN 'A' THEN 'Adjust Price'
			WHEN 'E' THEN 'Estimate'
			WHEN 'J' THEN 'Job'
			WHEN 'M' THEN 'Miscellaneous'
			WHEN 'P' THEN 'Inventory Item'
			ELSE ''
		END, 
	uom ,
	ordered ,
	shipped ,
	price_type,
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
	price,
	ext_price = price * ordered ,	
	taxable,
	taxable_desc=
		CASE taxable
			WHEN 0 THEN 'Tax included in price'
			WHEN 1 THEN 'Tax NOT included in price'
			ELSE ''
		END, 
	sales_comm,
	lb_tracking_desc=
		CASE lb_tracking
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
			ELSE ''
		END, 
	0,
	x_cr_ordered = ordered ,
	x_cr_shipped = shipped ,
	x_price = price,
	x_ext_price = price * ordered ,	
	x_sales_comm = sales_comm
FROM
	cvo_ord_list_hist

GO
GRANT REFERENCES ON  [dbo].[adcrl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adcrl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adcrl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adcrl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adcrl_vw] TO [public]
GO
