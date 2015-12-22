SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create procedure [dbo].[adm_po_sales_order_update] @a_po_no varchar(16),
  @a_part_no varchar(30), @a_release_date datetime, @a_po_line int,
  @a_d_quantity decimal(20,8), @a_d_received decimal(20,8), @a_d_status char(1),
  @a_msg varchar(255) out,  @a_order_no int = 0
as

begin

declare @qty_chg int, @rcvd_chg int, @status_chg int,
  @po_void char(1), @r_status char(1), @r_location varchar(10), @r_ord_line int,
  @r_quantity decimal(20,8),  @r_received decimal(20,8),  @r_conv_factor decimal(20,8),
  @ordno int, @line_no int, @oap_status char(1), @oap_row_id int,
  @ol_location varchar(10),
  @ordext int, @o_back_ord_flag char(1),@ord_shipped decimal(20,8), @o_status char(1),
  @o_special_order int,								-- mls 3/31/03 SCR 30749
  @srecvd varchar(22), @sorder varchar(22),					
  @snote varchar(255), @sreturn varchar(10), @olnote varchar(255), @oldnote int	,

  @new_ordered decimal(20,8), @o_conv_factor decimal(20,8), @new_shipped decimal(20,8),
  @old_ordered decimal(20,8), @l_shipped decimal(20,8),
  @po_so_upd int, @r_po_so_upd int,
  @lb_ind char(1)

declare @ol_lb_tracking char(1)
select @sreturn = '
'							-- NOTE:  Do not change this select.  It is used to put a 
							-- return in the ord_list note. mls 1/19/01 SCR 22307

select @qty_chg = 0, @rcvd_chg = 0, @r_status = ''
select @lb_ind = left(isnull((select upper(value_str) from config where flag = 'INV_LOT_BIN'),'N'),1)

if @a_order_no = 0
begin
  select @po_void = void from purchase_all (nolock) where po_no = @a_po_no

  if @@rowcount = 0
  begin
    select @a_msg = 'Purchase Order ' + @a_po_no + ' not found.'
    return -1
  end

  select @r_status = status,
    @r_location = location,
    @r_ord_line = ord_line,
    @r_quantity = quantity,
    @r_received = received,
    @r_conv_factor = conv_factor,
    @r_po_so_upd = isnull(receipt_batch_no,1)
  from releases (nolock)
  where po_no = @a_po_no and po_line = @a_po_line and part_no = @a_part_no and release_date = @a_release_date

  if @@rowcount = 0
  begin
    select @a_msg = 'Release not found.'
    return -2
  end

  select @status_chg = case when @r_status != @a_d_status then 1 else 0 end,
    @qty_chg = case when @r_quantity != @a_d_quantity then 1 else 0 end,
    @rcvd_chg = case when @r_received != @a_d_received then 1 else 0 end

  if @po_void = 'V' and @status_chg = 1 and @r_status = 'O' and @r_location like 'DROP%'		-- mls 3/19/02
  begin
    select @a_msg = 'You Can Not Reopen A Voided Drop PO!'
    return -3
  end

  select @ordno= order_no, @line_no= line_no, @oap_status = status, @oap_row_id = row_id
  from orders_auto_po (updlock)
  where @a_po_no = po_no and @a_part_no = part_no and isnull(@r_ord_line,-1) = line_no

  if @@rowcount = 0
  begin
    if @r_location like 'DROP%' and @a_d_status != 'C'	-- mls 4/6/04 PRR 4.1.1
    begin
      select @a_msg = 'Drop Order not found.'
      return -4
    end
    else
      return 1
  end -- @@rowcount = 0

  select @ordext=(select max(order_ext) from ord_list (nolock) where order_no=@ordno and line_no = @line_no)

  if @r_location not like 'DROP%'
  begin
    if not exists (select 1 from ord_list (nolock)
      where order_no = @ordno and line_no = @line_no and part_no = @a_part_no and order_ext = @ordext and create_po_flag = 1)
      return 1
  end 
end -- @a_order_no = 0
else
begin
  select @ordno = @a_order_no, @line_no = @a_po_line, @o_special_order = 1
  select @ordext=(select max(order_ext) from ord_list (nolock) where order_no=@ordno and line_no = @line_no)
end










if --@oap_status = 'P' and 
(@qty_chg = 1 or @rcvd_chg = 1 or @r_status = 'C')
begin
  select
    @o_back_ord_flag = isnull(back_ord_flag,'0'),	
    @o_status = status					
  from orders_all (nolock)
  where order_no = @ordno and ext = @ordext

  if @o_status > 'R'
  begin
    select @a_msg = 'Order is closed and not available to be updated'
    return -7
  end 	

  select @o_special_order = case when @r_location like 'DROP%' then 0 else 1 end -- mls 3/31/03 SCR 30749

  select @po_so_upd = 
    case isnull((select upper(left(value_str,1)) from config (nolock) where upper(flag) = 'PUR_SO_UPD'),'Y')
      when 'Y' then 1
      when 'N' then 0
      when 'A' then @r_po_so_upd end					-- mls 1/15/05 SCR 34080

  select @ord_shipped = isnull((select sum(shipped) from ord_list
  where order_no = @ordno and line_no = @line_no and order_ext < @ordext 
    and (upper(location) like 'DROP%' or isnull(create_po_flag,0) = 1)),0)

  
  update orders_auto_po 
  set status='M' 
  where po_no=@a_po_no and part_no=@a_part_no and line_no = @line_no

  if (@o_status < 'N') and									
    ((@r_status = 'C' and isnull(@po_void,'N') != 'V') or @r_received != @a_d_received)	
  begin
    select @a_msg = 'You Can Not Receive or Close an Order on Hold'
    return -6
  end												

  if @o_status = 'N' and ((isnull(@po_void,'N') != 'V') or @r_received != @a_d_received)	
  begin
    update orders_all 
    set status='P', printed = 'P'					
    where ext=@ordext and order_no=@ordno and status = 'N'
  end										
										
  select @srecvd = convert(varchar(22),@r_received), 					-- mls 1/19/01 SCR 22307 start
    @sorder = convert(varchar(22),@r_quantity)

  while substring(@srecvd,datalength(@srecvd),1) = '0' and substring(@srecvd,datalength(@srecvd) -1,1) != '.'
  begin
    select @srecvd = substring(@srecvd,1,datalength(@srecvd) -1)
  end

  while substring(@sorder,datalength(@sorder),1) = '0' and substring(@sorder,datalength(@sorder) -1,1) != '.'
  begin
    select @sorder = substring(@sorder,1,datalength(@sorder) -1)
  end										

  select @snote = '>' + convert(varchar(8),getdate(),1) + 
    case when @r_status = 'C' then ' - Closed By Auto PO - Recvd='+ @srecvd + '<'
      else ' - Update    Auto PO - Ordered='+ @sorder +'  Recvd='+ @srecvd + '<' end	

  select @olnote = isnull(note,''),
    @ol_location = location,
    @new_ordered = case when @o_special_order = 0 or @po_so_upd = 1
      then ((@r_quantity * @r_conv_factor) / conv_factor) - @ord_shipped
      else ordered end ,		-- mls 9/10/01 SCR 27578
    @o_conv_factor = conv_factor,
    @l_shipped = shipped,
    @ol_lb_tracking = lb_tracking
  from ord_list ol (updlock)
  where ol.order_ext=@ordext and ol.order_no=@ordno and ol.line_no=@line_no and status <= 'R'

  if @@rowcount = 0
  begin
    select @a_msg = 'Line ' + convert(varchar(10),@line_no) + ' on order ' + convert(varchar(10),@ordno) + '-' + 
      convert(varchar(10),@ordext) + ' was not found.'
    return -10
  end

  if @o_special_order = 0 
  begin												-- mls 1/24/06 SCR 36077
    select @new_shipped = ((@r_received * @r_conv_factor) / @o_conv_factor) - @ord_shipped

    if @ol_lb_tracking = 'Y' and @lb_ind = 'Y'
      select @new_shipped = isnull((select sum(qty) from lot_bin_ship (nolock)
        where tran_no = @ordno and tran_ext = @ordext and line_no = @line_no),0) / @o_conv_factor
  end
  else
  begin
    select @new_shipped = @l_shipped +
      (((@r_received - @a_d_received) * @r_conv_factor) / @o_conv_factor) 
    if @new_shipped > @new_ordered 
      select @new_shipped = @new_ordered
  end 

  if (@new_shipped < 0 or @new_ordered <= 0)
  begin
    select @a_msg = 'You Can Not alter an order to a negative shipped or ordered amount!'
    return -5
  end

  if @ol_location != @r_location
  begin
    select @a_msg = 'Location ' + @ol_location + ' on line ' + convert(varchar(10),@line_no) + ' of order ' + 
      convert(varchar(10),@ordno) + '-' + convert(varchar(10),@ordext) + ' is not the same as location ' +
      @r_location + ' on the PO.'
    return -11
  end 

  if @olnote != ''
  begin
    select @oldnote = patindex('%>__/__/__ - _________ Auto PO - %<',@olnote)
    if @oldnote = 1 select @olnote = @snote
    if @oldnote > 1 select @olnote = substring(@olnote, 1, @oldnote - 1) + @snote
    if @oldnote = 0 select @olnote = @olnote + @sreturn + @snote
  end										  -- mls 1/19/01 SCR 22307 end
  else
  begin
    select @olnote = @snote
  end

  if @r_status = 'C'
  begin
    update ord_list set 
      status= case 
        when @o_back_ord_flag = '0' and @o_special_order = 0 and @new_shipped != 0 then 'R' 			-- mls 3/31/03 SCR 30749
        else status end,								-- mls 9/24/01 SCR 27636
      printed= case when @o_special_order = 1 then printed else 'V' end, 		-- mls 3/31/03 SCR 30749
      ordered= @new_ordered,
      shipped= @new_shipped,
      note= @olnote,								  	-- mls 1/19/01 SCR 22307
      back_ord_flag = case 
        when @po_void = 'V' and @r_received != 0 and @o_special_order = 0 then '2' 	-- mls 3/31/03 SCR 30749
        else '0' end									-- mls 3/19/02 -- mls 9/24/01 SCR 27636 -- mls 03/24/00 SCR 70 22693
    where order_ext=@ordext and order_no=@ordno and line_no=@line_no and status <='R' 
    and not (status= case 
        when @o_back_ord_flag = '0' and @o_special_order = 0 and @new_shipped != 0 then 'R'
        else status end and
      printed= case when @o_special_order = 1 then printed else 'V' end and
      ordered= @new_ordered and
      shipped= @new_shipped and
      note= @olnote and
      back_ord_flag = case 
        when @po_void = 'V' and @r_received != 0 and @o_special_order = 0 then '2' 	
        else '0' end)

    if @o_special_order = 0								-- mls 3/31/03 SCR 30749
    begin
      if @o_back_ord_flag = '0' 							-- mls 9/24/01 SCR 27636
      begin
        if exists (select 1 from ord_list (nolock) where order_no = @ordno and order_ext = @ordext and shipped != 0)
        begin
          update orders_all set status='R', date_shipped=getdate(), back_ord_flag = '0' 
            where ext=@ordext and order_no=@ordno and status < 'R' 
        end
      end
      else
      begin
        if not exists (select 1 from ord_list (nolock) where order_no = @ordno and order_ext = @ordext
          and ordered > shipped)
        begin
          update orders_all set status='R', date_shipped=getdate()
            where ext=@ordext and order_no=@ordno and status < 'R' 
        end
      end
    end	-- @o_special_order = 0

    if @po_void = 'V' 								-- mls 3/19/02
    begin
      if @r_received = 0 or @o_special_order = 1				-- mls 3/31/03 SCR 30749
      begin
        update orders_all
        set status = @o_status,printed = @o_status
        where ext = @ordext and order_no = @ordno and status != @o_status and status <= 'R'
	    and not (status = @o_status and printed = @o_status)

        if not exists (select 1 from orders_auto_po 
          where po_no is NULL and part_no=@a_part_no and line_no = @line_no and order_no = @ordno)								
          update orders_auto_po set status='N', po_no = NULL
          where po_no = @a_po_no and part_no=@a_part_no and status='M' and line_no = @line_no									
        else
          delete orders_auto_po
          where po_no = @a_po_no and part_no=@a_part_no and status='M' and line_no = @line_no									
      end
      else
      begin
        if not exists (select 1 from ord_list (nolock) where order_no = @ordno and order_ext = @ordext and 
        (shipped != 0 or (location not like 'DROP%' and create_po_flag = 0))) and	
        not exists (select 1 from orders_auto_po (nolock) 
        where order_no = @ordno and row_id != @oap_row_id and status < 'R')	
        begin
          update orders_all 
          set status='V',printed='V', void = 'V', void_who = 'autopo',void_date = getdate()
          where ext=@ordext and order_no=@ordno and status <='R' 
        end											
      end
    end -- @po_void = 'V'
        
    if @r_status = 'C' and @r_received != 0
    begin
      update orders_auto_po 
      set status='R', qty= case @o_special_order when 1 then 0 else @r_quantity end
      where po_no=@a_po_no and part_no=@a_part_no and status='M' and 
       line_no = @line_no					-- mls 5/3/01 SCR 19502
    end
    if @r_status = 'C' and @r_received = 0
    begin
      update orders_auto_po 
      set status='N', po_no = NULL
      where po_no=@a_po_no and part_no=@a_part_no and status='M' and 
       line_no = @line_no					
    end
  end -- @r_status = 'C'
  else
  begin
    update ord_list set 										-- mls 7/26/99 SCR 70 19958 start
      ordered= @new_ordered,
      shipped = @new_shipped,
      printed = status,
      note= @olnote	
    from ord_list ol
    where ol.order_ext=@ordext and ol.order_no=@ordno and ol.line_no=@line_no and ol.status <='R' -- mls 1/19/01 SCR 22307
	and not (      ordered= @new_ordered and
      shipped = @new_shipped and
      printed = status and
      note= @olnote	)

    update orders_auto_po 
    set status='P', qty= case @o_special_order when 1 then (@r_quantity - @r_received) else @r_quantity end
    where  po_no=@a_po_no and part_no=@a_part_no and status='M'  
      and line_no = @line_no			-- mls 5/3/01 SCR 19502
  end	-- @r_status != 'C'

  if @o_status = 'N' and not exists (select 1 from ord_list where order_no = @ordno and order_ext = @ordext and shipped != 0)	-- mls 4/22/04 SCR 32660
  begin
    update orders_all 
    set status='N', printed = 'N'					
    where ext=@ordext and order_no=@ordno and status = 'P'
  end										

  exec fs_calculate_oetax_wrap @ordno, @ordext, 0, 1	-- mls 2/5/07 SCR 37455
  exec fs_updordtots @ordno, @ordext			-- mls 2/5/07 SCR 37455
end -- (@qty_chg = 1 or @rcvd_chg = 1 or @r_status = 'C')

if @o_special_order = 1 and ((@qty_chg = 1 or @rcvd_chg = 1 or @r_status = 'C') or @a_order_no != 0)
  and @po_so_upd = 0
begin
  select @new_ordered = isnull((select sum(qty) from orders_auto_po where order_no = @ordno
    and line_no = @line_no and location not like 'DROP%' and status != 'N'),0)
  select @old_ordered = isnull((select ((ordered - shipped) * conv_factor) from ord_list where
    order_no = @ordno and line_no = @line_no and part_no = @a_part_no 
    and location not like 'DROP%' and status < 'S' and order_ext = @ordext),0)

  if @new_ordered < @old_ordered
  begin
    update orders_auto_po
    set qty = (@old_ordered - @new_ordered)
    where order_no = @ordno and line_no = @line_no and status = 'N'

    if @@rowcount = 0
    begin
      insert orders_auto_po (location, part_no, order_no, line_no, qty, status, req_ship_date, part_type)
      select l.location, l.part_no, l.order_no, l.line_no,	
        (@old_ordered - @new_ordered), 'N', o.req_ship_date, l.part_type
      from orders_all o (nolock)
      join ord_list l (nolock) on l.order_no = o.order_no and l.order_ext = o.ext and l.line_no = @line_no
        and part_no = @a_part_no
      where o.order_no = @ordno and o.ext = @ordext
    end
  end
end -- @o_special_order = 1

return 1
end
GO
GRANT EXECUTE ON  [dbo].[adm_po_sales_order_update] TO [public]
GO
