SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_oe_margin] @stat char(1),@cust varchar(10), @loc varchar(10),
		@bdate datetime, @edate datetime, @margin int  AS

declare @x money
select @x = @margin / 100.0000
create table #tmargin ( cust_code varchar(10), customer_name varchar(40) NULL, order_no int,
			order_ext int, part_no varchar(30), location varchar(10), 
			description varchar(50) NULL, uom char(2), 
			shipped money, price_type char(1) NULL,
			price money, cost money, salesperson varchar(10) NULL, date_shipped datetime,
			who_entered varchar(30) NULL, status char(1), margin float, multiple char(1) )	--skk 05/30/00

if @stat='A' begin
	INSERT #tmargin
	SELECT  o.cust_code, a.customer_name, o.order_no, o.ext, l.part_no,
		l.location, l.description, l.uom, l.ordered, l.price_type, l.price, 
		(l.cost+l.direct_dolrs+l.ovhd_dolrs+l.util_dolrs), 
		o.salesperson, o.sch_ship_date, o.who_entered, o.status, 0, o.multiple_flag		--skk 05/30/00
	FROM  orders_all o, ord_list l, adm_cust_all a
	WHERE o.order_no=l.order_no AND o.ext=l.order_ext AND 
		o.cust_code=a.customer_code AND o.cust_code like @cust AND
		l.location like @loc AND
		(o.sch_ship_date>=@bdate and o.sch_ship_date<=@edate) AND
		o.status<='R' and o.type='I'

	UPDATE #tmargin
	SET    cost=(i.avg_cost+i.avg_direct_dolrs+i.avg_ovhd_dolrs+i.avg_util_dolrs)
	FROM  inventory i
	WHERE #tmargin.part_no=i.part_no AND #tmargin.location=i.location and i.inv_cost_method<>'S'

	UPDATE #tmargin
	SET    cost=(i.std_cost+i.std_direct_dolrs+i.std_ovhd_dolrs+i.std_util_dolrs)
	FROM  inventory i
	WHERE #tmargin.part_no=i.part_no AND #tmargin.location=i.location and i.inv_cost_method='S'

	INSERT #tmargin
	SELECT  o.cust_code, a.customer_name, o.order_no, o.ext, l.part_no,
		l.location, l.description, l.uom, l.shipped, l.price_type, l.price, 
		(l.cost+l.direct_dolrs+l.ovhd_dolrs+l.util_dolrs),  
		o.salesperson, o.date_shipped, o.who_entered, o.status, 0, o.multiple_flag		--skk 05/30/00
	FROM  orders_all o, ord_list l, adm_cust_all a
	WHERE o.order_no=l.order_no AND o.ext=l.order_ext AND 
		o.cust_code=a.customer_code AND o.cust_code like @cust AND
		l.location like @loc AND
		(o.date_shipped>=@bdate and o.date_shipped<=@edate) AND
		(o.status>'R' AND o.status<'V') and o.type='I'
end

if @stat='N' begin
	INSERT #tmargin
	SELECT  o.cust_code, a.customer_name, o.order_no, o.ext, l.part_no,
		l.location, l.description, l.uom, l.ordered, l.price_type, l.price, 
		(l.cost+l.direct_dolrs+l.ovhd_dolrs+l.util_dolrs), 
		o.salesperson, o.sch_ship_date, o.who_entered, o.status, 0, o.multiple_flag		--skk 05/30/00
	FROM  orders_all o, ord_list l, adm_cust_all a
	WHERE o.order_no=l.order_no AND o.ext=l.order_ext AND 
		o.cust_code=a.customer_code AND o.cust_code like @cust AND
		l.location like @loc AND
		(o.sch_ship_date>=@bdate and o.sch_ship_date<=@edate) AND
		o.status<'R' and o.type='I'

	UPDATE #tmargin
	SET    cost=(i.avg_cost+i.avg_direct_dolrs+i.avg_ovhd_dolrs+i.avg_util_dolrs)
	FROM  inventory i
	WHERE #tmargin.part_no=i.part_no AND #tmargin.location=i.location and i.inv_cost_method<>'S'

	UPDATE #tmargin
	SET    cost=(i.std_cost+i.std_direct_dolrs+i.std_ovhd_dolrs+i.std_util_dolrs)
	FROM  inventory i
	WHERE #tmargin.part_no=i.part_no AND #tmargin.location=i.location and i.inv_cost_method='S'


end

if @stat='S' begin
	INSERT #tmargin
	SELECT  o.cust_code, a.customer_name, o.order_no, o.ext, l.part_no,
		l.location, l.description, l.uom, l.ordered, l.price_type, l.price, 
		(l.cost+l.direct_dolrs+l.ovhd_dolrs+l.util_dolrs), 
		o.salesperson, o.sch_ship_date, o.who_entered, o.status, 0, o.multiple_flag		--skk 05/30/00
	FROM  orders_all o, ord_list l, adm_cust_all a
	WHERE o.order_no=l.order_no AND o.ext=l.order_ext AND 
		o.cust_code=a.customer_code AND o.cust_code like @cust AND
		l.location like @loc AND
		(o.sch_ship_date>=@bdate and o.sch_ship_date<=@edate) AND
		o.status='R' and o.type='I'

	UPDATE #tmargin
	SET    cost=(i.avg_cost+i.avg_direct_dolrs+i.avg_ovhd_dolrs+i.avg_util_dolrs)
	FROM  inventory i
	WHERE #tmargin.part_no=i.part_no AND #tmargin.location=i.location and i.inv_cost_method<>'S'

	UPDATE #tmargin
	SET    cost=(i.std_cost+i.std_direct_dolrs+i.std_ovhd_dolrs+i.std_util_dolrs)
	FROM  inventory i
	WHERE #tmargin.part_no=i.part_no AND #tmargin.location=i.location and i.inv_cost_method='S'

	INSERT #tmargin
	SELECT  o.cust_code, a.customer_name, o.order_no, o.ext, l.part_no,
		l.location, l.description, l.uom, l.shipped, l.price_type, l.price,  
		(l.cost+l.direct_dolrs+l.ovhd_dolrs+l.util_dolrs),  
		o.salesperson, o.date_shipped, o.who_entered, o.status, 0, o.multiple_flag		--skk 05/30/00

	FROM  orders_all o, ord_list l, adm_cust_all a
	WHERE o.order_no=l.order_no AND o.ext=l.order_ext AND 
		o.cust_code=a.customer_code AND o.cust_code like @cust AND
		l.location like @loc AND
		(o.date_shipped>=@bdate and o.date_shipped<=@edate) AND
		(o.status>'R' AND o.status<'V') and o.type='I'
end
UPDATE #tmargin
SET    margin=( ( price - cost ) / price )
WHERE  price<>0

-- skk 05/30/00 start
-- Do not include any lines from a multiple-shipto parent order in the report.
DELETE FROM #tmargin
WHERE	order_ext = 0 and multiple = 'Y'
-- skk 05/30/00 end

SELECT  cust_code, customer_name, order_no, order_ext, part_no, location,
	description, uom, shipped, price_type, price, (cost), 
	salesperson, date_shipped, who_entered, status, margin, 
	@stat, @cust, @loc, @bdate, @edate, @margin
FROM  #tmargin
WHERE margin<=@x
ORDER BY customer_name, date_shipped, order_no, order_ext, part_no



GO
GRANT EXECUTE ON  [dbo].[fs_oe_margin] TO [public]
GO
