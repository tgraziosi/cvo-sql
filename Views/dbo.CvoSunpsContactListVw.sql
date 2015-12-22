SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[CvoSunpsContactListVw] 
as

-- select * from cvosunpscontactlistvw

select max(yyyymmdd) last_sunps_sale, ar.territory_code, ar.salesperson_code, ar.customer_code, ar.ship_to_code, ar.address_name, ar.contact_name, ar.contact_phone, ar.contact_email 
from cvo_sbm_details sbm inner join armaster ar (nolock) on ar.customer_code = sbm.customer 
and ar.ship_to_code = sbm.ship_to
inner join cvo_armaster_all car (nolock) on car.customer_code = ar.customer_code and car.ship_to = ar.ship_to_code
inner join cvo_promotions p (nolock) on p.promo_id = sbm.promo_id and p.promo_level = sbm.promo_level
where sbm.promo_id = 'sunps'
and car.door = 1 and ar.status_type = 1
and not exists 
(
select * from orders o inner join cvo_orders_all co 
 on co.order_no = o.order_no and  co.ext = o.ext
 where isnull(co.promo_id,'') = 'sunps'
 and o.status <> 'v'
 and o.date_entered >= p.promo_start_date
 and o.cust_code = sbm.customer and o.ship_to= sbm.ship_to
)
group by ar.territory_code, ar.salesperson_code, ar.customer_code, ar.ship_to_code, ar.address_name, ar.contact_name, ar.contact_phone, ar.contact_email, p.promo_start_date
having max(yyyymmdd) < p.promo_start_date -- '11/1/2013'



GO
GRANT REFERENCES ON  [dbo].[CvoSunpsContactListVw] TO [public]
GO
GRANT SELECT ON  [dbo].[CvoSunpsContactListVw] TO [public]
GO
GRANT INSERT ON  [dbo].[CvoSunpsContactListVw] TO [public]
GO
GRANT DELETE ON  [dbo].[CvoSunpsContactListVw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CvoSunpsContactListVw] TO [public]
GO
