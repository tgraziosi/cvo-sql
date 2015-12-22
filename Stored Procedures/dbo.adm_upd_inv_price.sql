SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_upd_inv_price] 
@part_no varchar(30), @org_level int, @loc_org_id varchar(30), @promo_type char(1), @promo_rate decimal(20,8),
@promo_start datetime, @promo_end datetime, @p_level int, @p_qty decimal(20,8), @p_price decimal(20,8),
@catalog_id int OUT, @inv_price_id int OUT, @curr_key varchar(8), @active_ind int, @promo_entered datetime,
@msg varchar(255) OUT, @upd_type int, @dup_part varchar(30) = ''
as
begin
select @msg = ''

if @upd_type = 2	-- duplcate 
begin
    update new
    set promo_type = o.promo_type,
      promo_rate = o.promo_rate,
      promo_date_expires = o.promo_date_expires , 
      promo_date_entered = o.promo_date_entered , 
      promo_start_date = o.promo_start_date , 
      active_ind = o.active_ind
    from adm_inv_price new, adm_inv_price o
    where new.part_no = @part_no and o.part_no = @dup_part
    and new.org_level = o.org_level and new.loc_org_id = o.loc_org_id
    and new.catalog_id = o.catalog_id

    insert adm_inv_price (part_no, org_level, loc_org_id, catalog_id, promo_type, promo_rate, promo_date_expires, promo_date_entered, promo_start_date, active_ind)
    select @part_no, org_level, loc_org_id, catalog_id, promo_type, promo_rate, promo_date_expires, promo_date_entered, promo_start_date, active_ind
    from adm_inv_price p
    where p.part_no = @dup_part
    and not exists (select 1 from adm_inv_price n where n.part_no = p.part_no and n.org_level = p.org_level
      and n.loc_org_id = p.loc_org_id and n.catalog_id = p.catalog_id)


    delete det
    from adm_inv_price p, adm_inv_price det
    where p.inv_price_id = det.inv_price_id
      and p.part_no = @part_no

    insert adm_inv_price_det (inv_price_id, p_level, price, qty)
    select n.inv_price_id, d.p_level, d.price, d.qty
    from adm_inv_price n, adm_inv_price o, adm_inv_price_det d
    where n.part_no = @part_no and o.part_no = @dup_part
    and n.org_level = o.org_level and n.loc_org_id = o.loc_org_id
    and n.catalog_id = o.catalog_id and d.inv_price_id = o.inv_price_id

  return 1
end

if isnull(@curr_key,'') = ''
begin
  select @msg = 'Currency Code not Entered'
  return -1
end
if isnull(@part_no,'') = ''
begin
  select @msg = 'Part Number not Entered'
  return -2
end

set @catalog_id = isnull(@catalog_id,-1)
set @org_level = isnull(@org_level,0)
set @loc_org_id = case when @org_level = 0 then '' else isnull(@loc_org_id,'') end
set @org_level = case when @loc_org_id = '' then 0 else @org_level end
set @active_ind = isnull(@active_ind,1)

if @p_level > 0
begin
  if @upd_type = 1
    update part_price
    set last_system_upd_date = NULL
    where part_no = @part_no and curr_key = @curr_key

  if not exists (select 1 from adm_price_catalog where catalog_id = @catalog_id and active_ind = 1)
  begin
    select @catalog_id = isnull((select catalog_id from adm_price_catalog where curr_key = @curr_key and type = 0),-1)
    if @catalog_id = -1
    begin
      insert adm_price_catalog (catalog_cd, curr_key, active_ind, type, start_date, end_date)
      select @curr_key, @curr_key, 1, 0, NULL, NULL
  
      select @catalog_id = @@identity
    end
  end

  if @inv_price_id = -1
    select @inv_price_id = isnull((select p.inv_price_id from adm_inv_price p where part_no = @part_no and catalog_id = @catalog_id and org_level = @org_level
      and loc_org_id = @loc_org_id),-1)

  if @inv_price_id = -1
  begin
    insert adm_inv_price (part_no, org_level, loc_org_id, catalog_id, promo_type, promo_rate, promo_date_expires, promo_date_entered, promo_start_date, active_ind)
    select @part_no, @org_level, @loc_org_id, @catalog_id, @promo_type, @promo_rate, @promo_end, @promo_entered, @promo_start, @active_ind

    select @inv_price_id = @@identity
  end
  else
  begin
    update adm_inv_price
    set catalog_id = @catalog_id,
      promo_type = @promo_type,
      promo_rate = @promo_rate,
      promo_date_expires = @promo_end,
      promo_start_date = @promo_start,
      promo_date_entered = @promo_entered,
      active_ind = @active_ind
    where inv_price_id = @inv_price_id
  end
end

if @p_level < 1 
begin
  if @catalog_id = -1
    select @catalog_id = isnull((select catalog_id from adm_price_catalog where curr_key = @curr_key and type = 0),-1)
  if @inv_price_id = -1
    select @inv_price_id = isnull((select inv_price_id from adm_inv_price where part_no = @part_no and org_level = 0 and catalog_id = @catalog_id),-1)

  if @inv_price_id != -1
  begin
    delete from adm_inv_price_det
    where inv_price_id = @inv_price_id

    delete from adm_inv_price
    where inv_price_id = @inv_price_id
  end

  return 1
end

if not exists (select 1 from adm_inv_price_det where inv_price_id = @inv_price_id and p_level = @p_level)
begin
  if @p_level = 1 or (@p_price != 0 or @p_qty != 0)
    insert adm_inv_price_det (inv_price_id, p_level, price, qty)
    select @inv_price_id, @p_level, @p_price, case when @p_level = 1 then 0 else @p_qty end
end
else
begin
  if @p_level = 1 or (@p_price != 0 or @p_qty != 0)
    update adm_inv_price_det
    set price = @p_price,
      qty = case when @p_level = 1 then 0 else @p_qty end
    where inv_price_id = @inv_price_id and p_level = @p_level
  else
    delete adm_inv_price_det
    where inv_price_id = @inv_price_id and p_level = @p_level
end

return 1
end
GO
GRANT EXECUTE ON  [dbo].[adm_upd_inv_price] TO [public]
GO
