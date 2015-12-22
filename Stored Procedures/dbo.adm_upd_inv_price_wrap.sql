SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_upd_inv_price_wrap] 
@part_no varchar(30), @org_level int, @loc_org_id varchar(30), @promo_type char(1), @promo_rate decimal(20,8),
@promo_start datetime, @promo_end datetime, @p_level int, @p_qty decimal(20,8), @p_price decimal(20,8),
@catalog_id int, @inv_price_id int, @curr_key varchar(8), @active_ind int, @promo_entered datetime,
@upd_type int = 0, @dup_part varchar(30) = ''
as
begin
declare @msg varchar(255), @rc int

exec @rc = adm_upd_inv_price @part_no, @org_level, @loc_org_id, @promo_type, @promo_rate,
  @promo_start, @promo_end, @p_level, @p_qty, @p_price,
  @catalog_id OUT, @inv_price_id OUT, @curr_key, @active_ind, @promo_entered, @msg OUT, @upd_type,
  @dup_part

select @rc, @msg, @inv_price_id, @catalog_id
end
GO
GRANT EXECUTE ON  [dbo].[adm_upd_inv_price_wrap] TO [public]
GO
