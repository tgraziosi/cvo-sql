SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[cvo_resalecert_vw] as 
select ar.customer_code, ar.ship_to_code, ar.address_name, 
ar.state as ship_to_state, cust.state as bill_to_state,
case when isnull(car.door,0) = 0 then 'No' else 'Yes' end as Door,
isnull(ar.resale_num,'') ReSaleCert , ar.territory_code, ar.salesperson_code, 
dbo.adm_format_pltdate_f(ar.date_opened) date_opened,
ar.added_by_date,
added_by_user_name = case when isnumeric(ar.added_by_user_name)=1 then
    (select top 1 [user_name] from smusers_vw
    where [user_id] =ar.added_by_user_name) 
    else ar.added_by_user_name 
    end ,    
ar.modified_by_date,
modified_by_user_name = case when isnumeric(ar.modified_by_user_name)=1 then
    (select top 1 [user_name] from smusers_vw
    where [user_id] = ar.modified_by_user_name) 
    else ar.modified_by_user_name 
    end 
from cvo..armaster ar inner join cvo..cvo_armaster_all car on ar.customer_code = car.customer_code and ar.ship_to_code = car.ship_to
join cvo..arcust cust on cust.customer_code = ar.customer_code
where ar.address_type <> 9

GO
GRANT REFERENCES ON  [dbo].[cvo_resalecert_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_resalecert_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_resalecert_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_resalecert_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_resalecert_vw] TO [public]
GO
