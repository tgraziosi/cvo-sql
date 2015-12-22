SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_dh_pt_program_tracker_sp] as 
begin
set nocount on

-- Author - Tine Graziosi
-- 8/27/2014
-- Tallies of Program incentives for DH and PT Fall 2014 - 9/2/14 - 11/3/14

/*
 exec cvo_dh_pt_program_tracker_sp
*/

IF(OBJECT_ID('tempdb.dbo.#summary') is not null)    drop table dbo.#summary

declare @promo_id varchar(20), @promo_level varchar(30), 
	    @program_start_date datetime, @rolling12date datetime

select @rolling12date = dateadd(yy, -1, datediff(dd,0,getdate()))

-- Tally up of DH

select @promo_id = 'cvo', @promo_level = '%display%'
select top 1 @program_start_date = promo_start_date 
	from cvo_promotions where promo_id = @promo_id and promo_level like @promo_level
-- details

select ar.territory_code, ar.salesperson_code, 
	car.door, car.customer_code, car.ship_to, 
	@program_start_date prog_start, o.date_entered Sale_Date,
	case when o.date_entered < @program_start_date then 1 else 0 end as qual_cust,
	case when o.date_entered >= @program_start_date then 1 else 0 end as new_cust,
	co.promo_id, co.promo_level, r12.rolling12net
	,o.order_no, o.total_invoice
into #summary
from orders o join cvo_orders_all co on o.order_no = co.order_no and o.ext = co.ext
join cvo_armaster_all car on car.customer_code = o.cust_code and car.ship_to = o.ship_to
join armaster ar on car.customer_code = ar.customer_code and car.ship_to = ar.ship_to_code
left outer join
(select customer, ship_to, sum(anet) rolling12net 
from cvo_sbm_details where yyyymmdd >=  @rolling12date
group by customer, ship_to) as r12 on r12.customer = ar.customer_code and r12.ship_to = ar.ship_to_code
where 1=1
and co.promo_id = @promo_id and co.promo_level like @promo_level
and o.who_entered <> 'backordr' and o.status = 't' and o.type='i'
--and not exists (select 1 from cvo_promo_override_audit poa (nolock)
--	where poa.order_no = o.order_no and poa.order_ext = o.ext
--	and poa.override_date < @program_start_date)
group by ar.territory_code, ar.salesperson_code, car.door, car.customer_code , 
car.ship_to, o.date_entered, co.promo_id, co.promo_level, rolling12net, o.order_no, o.total_invoice

-- Puriti - DON'T CARE ABOUT THE LEVEL ON THIS PROGRAM

select @promo_id = 'PURITI', @promo_level = '%%'
select top 1 @program_start_date = promo_start_date 
	from cvo_promotions where promo_id = @promo_id and promo_level like @promo_level

insert into #summary
select ar.territory_code, ar.salesperson_code, 
	car.door, car.customer_code, car.ship_to, 
	@program_start_date prog_start, o.date_entered Sale_Date,
	case when o.date_entered < @program_start_date then 1 else 0 end as qual_cust,
	case when o.date_entered >= @program_start_date then 1 else 0 end as new_cust,
	co.promo_id, co.promo_level, r12.rolling12net
	,o.order_no, o.total_invoice
from orders o join cvo_orders_all co on o.order_no = co.order_no and o.ext = co.ext
join cvo_armaster_all car on car.customer_code = o.cust_code and car.ship_to = o.ship_to
join armaster ar on car.customer_code = ar.customer_code and car.ship_to = ar.ship_to_code
left outer join
(select customer, ship_to, sum(anet) rolling12net 
from cvo_sbm_details where yyyymmdd >=  @rolling12date
group by customer, ship_to) as r12 on r12.customer = ar.customer_code and r12.ship_to = ar.ship_to_code
where 1=1
and co.promo_id = @promo_id and co.promo_level like @promo_level
and o.who_entered <> 'backordr' and o.status = 't' and o.type = 'i'
--and not exists (select 1 from cvo_promo_override_audit poa (nolock)
--	where poa.order_no = o.order_no and poa.order_ext = o.ext
--	and poa.override_date < @program_start_date)
group by ar.territory_code, ar.salesperson_code, car.door, car.customer_code , 
car.ship_to, o.date_entered, co.promo_id, co.promo_level, rolling12net, o.order_no, o.total_invoice

-- find returns and disqualify those found

select o.orig_no order_no, o.orig_ext ext,
	return_date = o.date_entered, 
	reason = min(rc.return_desc),
	return_amt =  o.total_invoice,
	return_qty = sum(cr_shipped) 
into #r
from #summary t inner join  orders o (nolock) on t.order_no = o.orig_no -- and t.ext = o.orig_ext
 inner join ord_list ol (nolock) on   ol.order_no = o.order_no and ol.order_ext = o.ext
 INNER JOIN inv_master i(nolock) ON ol.part_no = i.part_no 
 INNER JOIN po_retcode rc(nolock) ON ol.return_code = rc.return_code
 WHERE 1=1
  AND o.status = 't' and o.type = 'c' 
  and o.total_invoice = t.total_invoice
group by o.orig_no, o.orig_ext, o.date_entered, o.total_invoice

update t set qual_cust = 0
from #r , #summary t where #r.order_no = t.order_no -- and #r.ext = t.ext

-- disquality accounts previously sold the program as new accounts

update sa set new_cust = 0
from #summary sa
where exists (select 1 from #summary sp where qual_cust = 1 and sp.customer_code = sa.customer_code
and sp.ship_to = sa.ship_to and sa.promo_id = sp.promo_id)
and sa.new_cust = 1

;with s as 
(select distinct s.territory_code, s.salesperson_code, s.promo_id program,
right(s.customer_code,5) cust, s.ship_to, ar.address_name, s.qual_cust, s.new_cust, s.order_no 
from #summary s
join armaster ar on ar.customer_code = s.customer_code and ar.ship_to_code = s.ship_To
)
select dbo.calculate_region_fn(s.territory_code) region, s.territory_code, 
slp = isnull((select top 1 sp.salesperson_code from arsalesp sp (nolock) 
		where sp.territory_code = s.territory_code and sp.status_type = 1), 'Unknown'),
program = case when program = 'cvo' then 'Durahinge' else Program end , 
sum(qual_cust) cust, sum(new_cust) new_cust, 
incentive_level_attained = case when sum(new_cust) < 5 then 'No'
				  --when sum(new_cust) + sum(qual_cust) >=54 then 'Level 3/54'
				  --when sum(new_cust) + sum(qual_cust) >=36 then 'Level 2/36'
				  --when sum(new_cust) + sum(qual_cust) >=18 then 'Level 1/18'
				  else 'Yes'
				  end
from s
group by s.territory_code, program 

end
GO
GRANT EXECUTE ON  [dbo].[cvo_dh_pt_program_tracker_sp] TO [public]
GO
