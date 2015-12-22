SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[part_org_price_vw] as
select ip.part_no, pc.curr_key, ip.org_level, ip.loc_org_id, ip.catalog_id,ip.inv_price_id,
  pd.price_a, pd.price_b, pd.price_c, pd.price_d, pd.price_e, pd.price_f , 
  pd.qty_a, pd.qty_b, pd.qty_c, pd.qty_d, pd.qty_e, pd.qty_f, 
  promo_type, promo_rate, promo_date_expires, promo_date_entered, promo_start_date, ip.active_ind,
  ip.timestamp
from adm_inv_price ip, adm_price_catalog pc ,
(select inv_price_id, 
sum(case when p_level = 1 then price else 0 end),
sum(case when p_level = 2 then price else 0 end),
sum(case when p_level = 3 then price else 0 end),
sum(case when p_level = 4 then price else 0 end),
sum(case when p_level = 5 then price else 0 end),
sum(case when p_level = 6 then price else 0 end),
sum(case when p_level = 1 then qty else 0 end),
sum(case when p_level = 2 then qty else 0 end),
sum(case when p_level = 3 then qty else 0 end),
sum(case when p_level = 4 then qty else 0 end),
sum(case when p_level = 5 then qty else 0 end),
sum(case when p_level = 6 then qty else 0 end)
from adm_inv_price_det group by inv_price_id) as pd(inv_price_id, price_a, price_b, price_c, price_d, price_e,price_f, qty_a, qty_b, qty_c, qty_d, qty_e, qty_f) 
where pc.catalog_id = ip.catalog_id and
pd.inv_price_id = ip.inv_price_id
and ip.org_level < 2 -- part or org level
and pc.type = 0 -- system base catalog
and pc.active_ind = 1
GO
GRANT REFERENCES ON  [dbo].[part_org_price_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[part_org_price_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[part_org_price_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[part_org_price_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[part_org_price_vw] TO [public]
GO
