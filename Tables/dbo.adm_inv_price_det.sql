CREATE TABLE [dbo].[adm_inv_price_det]
(
[timestamp] [timestamp] NOT NULL,
[inv_price_id] [int] NOT NULL,
[p_level] [int] NOT NULL,
[price] [decimal] (20, 8) NOT NULL,
[qty] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700deladm_inv_pr_det] ON [dbo].[adm_inv_price_det] FOR delete AS 
BEGIN

DECLARE @d_inv_price_id int, @d_p_level int, @d_price decimal(20,8),
@d_qty decimal(20,8)

declare @curr_key varchar(8), @part_no varchar(30)

DECLARE t700deladm__cursor CURSOR LOCAL STATIC FOR
SELECT i.inv_price_id, i.p_level, i.price, i.qty
from deleted i

OPEN t700deladm__cursor

if @@cursor_rows = 0
begin
CLOSE t700deladm__cursor
DEALLOCATE t700deladm__cursor
return
end

FETCH NEXT FROM t700deladm__cursor into @d_inv_price_id, @d_p_level, @d_price, @d_qty
While @@FETCH_STATUS = 0
begin
  select @part_no = isnull((select part_no from adm_inv_price where inv_price_id = @d_inv_price_id),'')

  if @part_no != ''
  begin  
    select @curr_key = isnull((select pc.curr_key from adm_price_catalog pc, adm_inv_price ip where ip.inv_price_id = @d_inv_price_id and
      ip.catalog_id = pc.catalog_id and pc.type = 0 and ip.org_level = 0),'')

    if @curr_key != ''
    begin
      if exists (select 1 from part_price (nolock) where part_no = @part_no and curr_key = @curr_key)
      begin
        update part_price 
        set 
          qty_a = case when @d_p_level = 1 then 0 else qty_a end,
          qty_b = case when @d_p_level = 2 then 0 else qty_b end,
          qty_c = case when @d_p_level = 3 then 0 else qty_c end,
          qty_d = case when @d_p_level = 4 then 0 else qty_d end,
          qty_e = case when @d_p_level = 5 then 0 else qty_e end,
          qty_f = case when @d_p_level = 6 then 0 else qty_f end,
          price_a = case when @d_p_level = 1 then 0 else price_a end,
          price_b = case when @d_p_level = 2 then 0 else price_b end,
          price_c = case when @d_p_level = 3 then 0 else price_c end,
          price_d = case when @d_p_level = 4 then 0 else price_d end,
          price_e = case when @d_p_level = 5 then 0 else price_e end,
          price_f = case when @d_p_level = 6 then 0 else price_f end,
          last_system_upd_date = getdate()
        where part_no = @part_no and curr_key = @curr_key
      end
    end
  end


FETCH NEXT FROM t700deladm__cursor into @d_inv_price_id, @d_p_level, @d_price, @d_qty
end -- while

CLOSE t700deladm__cursor
DEALLOCATE t700deladm__cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700iuadm_inv_pr_det] ON [dbo].[adm_inv_price_det] FOR insert, update AS 
BEGIN

DECLARE @i_inv_price_id int, @i_p_level int, @i_price decimal(20,8),
@i_qty decimal(20,8),
@d_inv_price_id int, @d_p_level int, @d_price decimal(20,8),
@d_qty decimal(20,8)

declare @curr_key varchar(8), @part_no varchar(30)

DECLARE t700updadm__cursor CURSOR LOCAL STATIC FOR
SELECT i.inv_price_id, i.p_level, i.price, i.qty
from inserted i

OPEN t700updadm__cursor

if @@cursor_rows = 0
begin
CLOSE t700updadm__cursor
DEALLOCATE t700updadm__cursor
return
end

FETCH NEXT FROM t700updadm__cursor into @i_inv_price_id, @i_p_level, @i_price, @i_qty
While @@FETCH_STATUS = 0
begin
  select @part_no = isnull((select part_no from adm_inv_price where inv_price_id = @i_inv_price_id),'')

  if @part_no != ''
  begin  
    select @curr_key = isnull((select pc.curr_key from adm_price_catalog pc, adm_inv_price ip where ip.inv_price_id = @i_inv_price_id and
      ip.catalog_id = pc.catalog_id and pc.type = 0 and ip.org_level = 0),'')

    if @curr_key != ''
    begin
      if exists (select 1 from part_price (nolock) where part_no = @part_no and curr_key = @curr_key)
      begin
        update part_price 
        set 
          qty_a = case when @i_p_level = 1 then @i_qty else qty_a end,
          qty_b = case when @i_p_level = 2 then @i_qty else qty_b end,
          qty_c = case when @i_p_level = 3 then @i_qty else qty_c end,
          qty_d = case when @i_p_level = 4 then @i_qty else qty_d end,
          qty_e = case when @i_p_level = 5 then @i_qty else qty_e end,
          qty_f = case when @i_p_level = 6 then @i_qty else qty_f end,
          price_a = case when @i_p_level = 1 then @i_price else price_a end,
          price_b = case when @i_p_level = 2 then @i_price else price_b end,
          price_c = case when @i_p_level = 3 then @i_price else price_c end,
          price_d = case when @i_p_level = 4 then @i_price else price_d end,
          price_e = case when @i_p_level = 5 then @i_price else price_e end,
          price_f = case when @i_p_level = 6 then @i_price else price_f end,
      	  last_system_upd_date = getdate()
        where part_no = @part_no and curr_key = @curr_key
      end
      else
      begin
        insert part_price (part_no, curr_key, promo_type, promo_rate, promo_date_expires, promo_start_date, promo_date_entered, last_system_upd_date,
          qty_a, qty_b, qty_c, qty_d, qty_e, qty_f, price_a, price_b, price_c, price_d, price_e, price_f)
        select @part_no, @curr_key, NULL, NULL, NULL, NULL, NULL, getdate(),
           case when @i_p_level = 1 then @i_qty else 0 end,
           case when @i_p_level = 2 then @i_qty else 0 end,
           case when @i_p_level = 3 then @i_qty else 0 end,
           case when @i_p_level = 4 then @i_qty else 0 end,
           case when @i_p_level = 5 then @i_qty else 0 end,
           case when @i_p_level = 6 then @i_qty else 0 end,
           case when @i_p_level = 1 then @i_price else 0 end,
           case when @i_p_level = 2 then @i_price else 0 end,
           case when @i_p_level = 3 then @i_price else 0 end,
           case when @i_p_level = 4 then @i_price else 0 end,
           case when @i_p_level = 5 then @i_price else 0 end,
           case when @i_p_level = 6 then @i_price else 0 end
      end        
    end
  end


FETCH NEXT FROM t700updadm__cursor into @i_inv_price_id, @i_p_level, @i_price, @i_qty
end -- while

CLOSE t700updadm__cursor
DEALLOCATE t700updadm__cursor

END
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_inv_price_det_0] ON [dbo].[adm_inv_price_det] ([inv_price_id], [p_level]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_inv_price_det] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_inv_price_det] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_inv_price_det] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_inv_price_det] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_inv_price_det] TO [public]
GO
