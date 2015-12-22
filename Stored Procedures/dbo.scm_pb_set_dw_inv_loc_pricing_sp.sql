SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[scm_pb_set_dw_inv_loc_pricing_sp] 
@typ char(1), @part_no varchar(30), @org_level integer, @loc_org_id varchar(30)
, @catalog_id integer, @promo_type char(1), @promo_rate decimal(20,8)
, @promo_date_expires datetime, @promo_date_entered datetime
, @promo_start_date datetime, @inv_price_id integer, @qty_a decimal(20,8)
, @qty_b decimal(20,8), @qty_c decimal(20,8), @qty_d decimal(20,8)
, @qty_e decimal(20,8), @qty_f decimal(20,8), @price_a decimal(20,8)
, @price_b decimal(20,8), @price_c decimal(20,8), @price_d decimal(20,8)
, @price_e decimal(20,8), @price_f decimal(20,8), @curr_key varchar(8)
, @active_ind integer, @timestamp varchar(20)
 AS
BEGIN
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
Insert into part_loc_price_vw (part_loc_price_vw.part_no, part_loc_price_vw.org_level
, part_loc_price_vw.loc_org_id, part_loc_price_vw.catalog_id
, part_loc_price_vw.promo_type, part_loc_price_vw.promo_rate
, part_loc_price_vw.promo_date_expires, part_loc_price_vw.promo_date_entered
, part_loc_price_vw.promo_start_date
)
values (@part_no, @org_level, @loc_org_id, @catalog_id, @promo_type, @promo_rate
, @promo_date_expires, @promo_date_entered, @promo_start_date
)
end
if @typ = 'U'
begin
update part_loc_price_vw set
part_loc_price_vw.loc_org_id= @loc_org_id
, part_loc_price_vw.catalog_id= @catalog_id
, part_loc_price_vw.promo_type= @promo_type
, part_loc_price_vw.promo_rate= @promo_rate
, part_loc_price_vw.promo_date_expires= @promo_date_expires
, part_loc_price_vw.promo_date_entered= @promo_date_entered
, part_loc_price_vw.promo_start_date= @promo_start_date
where part_loc_price_vw.part_no= @part_no
 and part_loc_price_vw.org_level= @org_level
 and part_loc_price_vw.timestamp= @ts
 and part_loc_price_vw.inv_price_id = @inv_price_id
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Row changed between retrieve and update'
  RETURN 
end
end
if @typ = 'D'
begin
delete from part_loc_price_vw
where part_loc_price_vw.part_no= @part_no
 and part_loc_price_vw.org_level= @org_level

if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Error Deleting Row'
  RETURN 
end
end

return
end

grant execute on scm_pb_set_dw_inv_loc_pricing_sp to public
GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_inv_loc_pricing_sp] TO [public]
GO
