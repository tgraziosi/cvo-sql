SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_pick_stock_avail] @pno varchar(30), @loc varchar(10), @uqty decimal(20,8),
  @im_status char(1), @from char(1), @avail_qty decimal(20,8) out, @type char(1) out as
BEGIN
  declare @wp_part varchar(30), @wp_qty decimal(20,8), 
    @wp_fixed char(1), @wp_needed decimal(20,8), @wp_avail decimal(20,8),
    @wp_filled decimal(20,8)

  declare @allow_overship char(1)				-- mls 6/5/02 SCR 29037 start

  select @allow_overship = isnull((select 'Y' from config (nolock)
    where flag = 'INV_SO_OVERSHIP' and upper(value_str) like 'Y%'),'N')	-- mls 6/5/02 SCR 29037 end

  select @type = 'S', @wp_filled = 0

  select @avail_qty = isnull((select i.in_stock
  from inventory i where i.part_no = @pno and i.location = @loc),@uqty) 

  If @avail_qty >= @uqty select @type = 'S' -- Ship full qty
  Else select @type = 'A' -- Ship quantity available

  if @type = 'A' and @im_status = 'K'
  begin

    select @type = 'S'
    select @uqty = @uqty - @avail_qty
    select @wp_filled = @uqty

    DECLARE wp_cursor CURSOR LOCAL FOR					
      select wp.part_no, wp.qty, wp.fixed
      from   what_part wp
      join inv_master im (nolock) on im.part_no = wp.part_no
    where  wp.asm_no = @pno and (wp.location = 'ALL' or wp.location = @loc) and 
      wp.active < 'C' and im.status not in ('V','R')

    OPEN wp_cursor
    FETCH NEXT FROM wp_cursor into @wp_part, @wp_qty, @wp_fixed

    While @@FETCH_STATUS = 0 and @wp_filled > 0
    begin									
      select @wp_needed = case @wp_fixed when 'N' then @wp_qty * @uqty else @wp_qty end

      if @allow_overship = 'Y'				-- mls 6/5/02 SCR 29037 start
      begin
        select @wp_avail = isnull((select i.in_stock
        from inventory i where i.part_no = @wp_part and i.location = @loc
        and i.lb_tracking = 'Y'),@wp_needed) 		
      end
      else
      begin
        select @wp_avail = isnull((select i.in_stock
        from inventory i where i.part_no = @wp_part and i.location = @loc),@wp_needed) 		
      end						-- mls 6/5/02 SCR 29037 end

      if @wp_avail < 0	select @wp_avail = 0

      If @wp_avail >= @wp_needed 
      begin
        select @type = 'S' -- Ship full qty
      end
      Else 
      begin
        select @type = 'A' -- Ship quantity available
        select @wp_needed = case @wp_fixed when 'N' then floor(@wp_avail / @wp_qty) else 0 end
        if @wp_filled > @wp_needed    select @wp_filled = @wp_needed
      end

      FETCH NEXT FROM wp_cursor into @wp_part, @wp_qty, @wp_fixed
    END -- fetch_status = 0

    close wp_cursor
    deallocate wp_cursor

    select @avail_qty = @avail_qty + @wp_filled 
  end

  if @avail_qty < 0   select @avail_qty = 0			-- mls 12/14/01 SCR 28067
END
GO
GRANT EXECUTE ON  [dbo].[fs_pick_stock_avail] TO [public]
GO
