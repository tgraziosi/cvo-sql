SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adprc_vw] as
select 
  part_no,
  curr_key,
  price_a base_price,
  qty_a   base_quantity,
  price_b level2_price,
  qty_b   level2_quantity,
  price_c level3_price,
  qty_c   level3_quantity,
  price_d level4_price,
  qty_d   level4_quantity,
  price_e level5_price,
  qty_e   level5_quantity,
  case promo_type
  when 'D' then 'Discount'
  when 'P' then 'Price'
  when 'N' then 'None'
  end         promotion_type,
  promo_rate  promotion_rate,
 promo_date_expires promotion_expire,

 price_a x_base_price,
 qty_a x_base_quantity,
 price_b x_level2_price,
 qty_b x_level2_quantity,
 price_c x_level3_price,
 qty_c x_level3_quantity,
 price_d x_level4_price,
 qty_d x_level4_quantity,
 price_e x_level5_price,
 qty_e x_level5_quantity,
 promo_rate x_promotion_rate,
 promo_date_expires x_promotion_expire

from part_price

GO
GRANT REFERENCES ON  [dbo].[adprc_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adprc_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adprc_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adprc_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adprc_vw] TO [public]
GO
