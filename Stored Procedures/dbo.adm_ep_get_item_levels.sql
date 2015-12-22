SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_ep_get_item_levels] 
@part_no varchar(30),					--required
@vendor_code varchar(12) = NULL			-- if null, look for part in inventory only
as
declare @rc int, @i_part_no varchar(30)

if exists (select 1 from inv_master (nolock) where part_no = @part_no)
  set @i_part_no = @part_no

if isnull(@vendor_code,'') != '' and @i_part_no is NULL
begin
  select @i_part_no = isnull((select Top 1 sku_no
  from vendor_sku (nolock) where vend_sku = @part_no and vendor_no = @vendor_code),NULL)
end

select 
  i.part_no part_no,
  i.location location,
  i.in_stock qty_on_hand,
  i.commit_ed + i.xfer_commit_ed committed,
  i.vendor,
  i.po_on_order
from inventory_unsecured_vw i (nolock)
where i.part_no = @i_part_no
and i.location not like 'DROP%'

return 1

GO
GRANT EXECUTE ON  [dbo].[adm_ep_get_item_levels] TO [public]
GO
