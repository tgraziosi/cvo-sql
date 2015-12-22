SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_pick_stock] @from char(1), @tran int, @ext int , @who varchar(30),
@apply_date datetime = NULL,
@process_ctrl_num varchar(32) = NULL,						-- mls 4.1.1 4/9/04
@p_loc varchar(10) = '',
@p_org_id varchar(30) = '',
@p_pick_dt datetime = NULL,
@online_call int = 0
  AS 										-- mls 1/27/04 SCR 32295
BEGIN

declare @pno varchar(30), @loc varchar(10), @uom varchar(2)
declare @t varchar(30), @ptype char(1)
declare @convfact decimal(20,8), @uqty decimal(20,8), @avail_qty decimal(20,8)
declare @line int, @rcnt int , @cnt int, @xlp int
declare @AutoPick char(3), @type char(1)
declare @AutoKitPick char(1)							-- mls 4/21/00 SCR 70 21699
declare @OverPick char(1)							-- mls 8/10/00 SCR 23884
declare @ck_row int, @part_type char(1)						-- mls 7/31/01 SCR 27322
declare @im_status char(1)							-- mls 10/5/01 SCR 27723
declare @lb_mode varchar(10)							-- mls 2/8/02 SCR 28326

declare @result int, @err int

if isnull(@p_loc,'') = ''
  select @p_loc = '%'
if isnull(@p_org_id,'') = ''
  select @p_org_id = '%'
if @p_pick_dt is NULL
  select @p_pick_dt = GetDate()

select @AutoPick = 'YES', @AutoKitPick = 'N'					-- mls 4/21/00 SCR 70 21699

select @process_ctrl_num = isnull(@process_ctrl_num,'')				-- mls 12/16/04 SCR 34006

if exists ( select 1 from config (nolock)					-- mls 4/21/00 SCR 70 21699 start
  where upper(flag)='PICK_AUTOKITS' and upper(value_str) like 'Y%' ) 
  select @AutoKitPick = 'Y'							-- mls 4/21/00 SCR 70 21699 end

select @OverPick = 'Y'								-- mls 8/10/00 SCR 23884 start
if exists ( select 1 from config (nolock)
  where upper(flag) = 'INV_SO_OVERPICK' and upper(value_str) like 'N%')
begin
  select @OverPick = 'N'							
end										-- mls 8/10/00 SCR 23884 end
select @lb_mode = isnull((select upper(value_str) 				-- mls 2/8/02 SCR 28326
  from config (nolock) where flag = 'INV_LOT_BIN'),'N')

select @line=0, @cnt=0
if @from='S' 
BEGIN
  if exists ( select 1 from config (nolock) where flag='SHIP_BARCODE' and value_str='YES' ) 
    select @AutoPick = 'NO'
  if @AutoPick = 'YES' 
  begin
	DECLARE ol_lb CURSOR LOCAL FOR					
	select o.location, o.part_no, o.ordered, o.conv_factor, o.line_no, o.uom
        from ord_list o
        join locations l on l.location = o.location and l.organization_id like @p_org_id
        where o.order_no=@tran and o.order_ext=@ext and o.lb_tracking='Y' and o.status < 'P' 
          and o.location like @p_loc and o.printed_dt is null
          and o.location not like 'DROP%' and o.create_po_flag != 1			-- mls 4/5/04 SCR 32604

	OPEN ol_lb
	FETCH NEXT FROM ol_lb into @loc, @pno, @uqty, @convfact, @line, @uom

	While @@FETCH_STATUS = 0
	begin									
          exec fs_pick_lot_bin @loc, @pno, @from, @tran, @ext, @uom, 
            @uqty, @convfact, @line, @who, @p_pick_dt
	  FETCH NEXT FROM ol_lb into @loc, @pno, @uqty, @convfact, @line, @uom
	END

	close ol_lb
	deallocate ol_lb

	DECLARE olk_lb CURSOR LOCAL FOR					-- mls 7/31/01 SCR 27322 start
	select o.location, o.part_no, o.ordered * o.qty_per, o.conv_factor, o.row_id, o.line_no, o.uom
        from ord_list_kit o
	join ord_list ol (nolock) on ol.order_no = o.order_no and ol.order_ext = o.order_ext and ol.line_no = o.line_no and ol.printed_dt is null
        join locations l on l.location = o.location and l.organization_id like @p_org_id
        where o.order_no=@tran and o.order_ext=@ext and o.lb_tracking='Y' and o.status < 'P' 
          and o.location like @p_loc and o.location not like 'DROP%'

	OPEN olk_lb
	FETCH NEXT FROM olk_lb into @loc, @pno, @uqty, @convfact, @ck_row, @line, @uom

	While @@FETCH_STATUS = 0
	begin									
          exec fs_pick_lot_bin @loc, @pno, 'C', @tran, @ck_row, @uom, 
	    @uqty, @convfact, @line, @who, @p_pick_dt
  	  FETCH NEXT FROM olk_lb into @loc, @pno, @uqty, @convfact, @ck_row, @line, @uom
	END									-- mls 7/31/01 SCR 27322 end

	close olk_lb
 	deallocate olk_lb
  END -- if @AutoPick
END	

if @from='P' 
BEGIN
  if exists ( select 1 from config (nolock) where flag='MFG_BARCODE' and value_str='YES' ) 
    select @AutoPick = 'NO'

  select @t=isnull((select value_str from config (nolock) where flag='MFG_PICK_RES'),'YES')

  -- if 'routed' then don't pick anything'
  select @ptype= isnull((select prod_type from produce_all where prod_no=@tran and prod_ext=@ext),'M')

  if @ptype in ('R','J')
    select @t = 'NONE'

  if not (@t in ('NO','NONE'))
    select @t = 'YES'

  if @AutoPick = 'YES' and @t != 'NONE'
  Begin
	DECLARE pl_lb CURSOR LOCAL FOR					
	select location, part_no, plan_qty, conv_factor, line_no, uom
        from prod_list
        where prod_no=@tran and prod_ext=@ext and lb_tracking='Y' and status < 'P' and 
          constrain='N' and direction < 0

	OPEN pl_lb
	FETCH NEXT FROM pl_lb into @loc, @pno, @uqty, @convfact, @line, @uom	-- mls 11/14/01 SCR 27909

	While @@FETCH_STATUS = 0
	begin									
          begin tran								-- mls 1/27/04 SCR 32295
          exec fs_pick_lot_bin @loc, @pno, @from, @tran, @ext, @uom, 
            @uqty, @convfact, @line, @who, @apply_date
          commit tran								-- mls 1/27/04 SCR 32295
	  FETCH NEXT FROM pl_lb into @loc, @pno, @uqty, @convfact, @line, @uom
	END

	close pl_lb
	deallocate pl_lb
  End
END	

if @from='T' 
BEGIN
  if exists ( select 1 from config where flag='XFER_BARCODE' and value_str='YES' ) 
    select @AutoPick = 'NO'

  if @AutoPick = 'YES'  and @lb_mode like 'Y%'				-- mls 2/8/02 SCR 28326
  begin
	DECLARE xl_lb CURSOR LOCAL FOR					
	select from_loc, part_no, ordered, conv_factor,line_no, uom
        from xfer_list
	where xfer_no=@tran and lb_tracking='Y' and status < 'P'

	OPEN xl_lb
	FETCH NEXT FROM xl_lb into @loc, @pno, @uqty, @convfact, @line, @uom

	While @@FETCH_STATUS = 0
	begin									
          exec fs_pick_lot_bin @loc, @pno, @from, @tran, @ext, @uom, 
            @uqty, @convfact, @line, @who
	  FETCH NEXT FROM xl_lb into @loc, @pno, @uqty, @convfact,@line, @uom
	END

	close xl_lb
	deallocate xl_lb
  END -- if @AutoPick 
END

if @from='S' 
BEGIN
  if @AutoPick = 'YES' 
  BEGIN
    -- only pick what is available in inventory
    DECLARE olk_nlb CURSOR LOCAL FOR					
      select olk.ordered * olk.qty_per * olk.conv_factor,olk.line_no,olk.part_no, olk.location, 
        olk.row_id, olk.part_type, im.status
      from   ord_list_kit olk
      join ord_list ol (nolock) on ol.order_no = olk.order_no and ol.order_ext = olk.order_ext and ol.line_no = olk.line_no and ol.printed_dt is null
      join locations l on l.location = olk.location and l.organization_id like @p_org_id
      left outer join inv_master im (nolock) on im.part_no = olk.part_no
    where  olk.order_no = @tran  and olk.order_ext = @ext and olk.lb_tracking != 'Y' and olk.status = 'N'
      and olk.location like @p_loc and olk.location not like 'DROP%' 

    OPEN olk_nlb
    FETCH NEXT FROM olk_nlb into @uqty, @line, @pno, @loc, @ck_row, @part_type, @im_status

    While @@FETCH_STATUS = 0
    begin									
      select @type = 'S'

      if (@OverPick = 'N' and @part_type = 'P' and isnull(@im_status,'') != 'V') 
         or isnull(@im_status,'') = 'K'							-- mls 10/5/01 SCR 27723
											-- mls 8/10/00 SCR 23884
      begin
	exec fs_pick_stock_avail @pno, @loc, @uqty, @im_status, @from, @avail_qty out, @type out
      end       

      -- Ship appropriate quantity
      update ord_list_kit
      set status = 'P',
        shipped = 
          case when isnull(@im_status,'A') = 'K' and @AutoKitPick = 'N'  then shipped
          when isnull(@im_status,'V') = 'V' then ordered
          else
            CASE @type
            WHEN 'S' THEN ordered
            WHEN 'A' THEN @avail_qty / (qty_per * conv_factor)
            END
          end
        from   ord_list_kit
        where order_no = @tran  and order_ext = @ext and line_no = @line and ord_list_kit.row_id = @ck_row

      FETCH NEXT FROM olk_nlb into @uqty, @line, @pno, @loc, @ck_row, @part_type, @im_status
    END -- fetch_status = 0

    close olk_nlb
    deallocate olk_nlb

    DECLARE ol_nlb CURSOR LOCAL FOR					
      select ol.ordered * ol.conv_factor,ol.line_no,ol.part_no, ol.location, ol.part_type, im.status
      from   ord_list ol
      join locations l on l.location = ol.location and l.organization_id like @p_org_id
      left outer join inv_master im on im.part_no = ol.part_no and ol.part_type = 'P'
      where  ol.order_no = @tran  and ol.order_ext = @ext and ol.lb_tracking != 'Y'			-- mls 1/15/02 SCR 28183
      and ol.location like @p_loc  and ol.printed_dt is null
      and ol.location not like 'DROP%' and ol.create_po_flag != 1			-- mls 4/5/04 SCR 32604
										-- mls 2/19/02 SCR 28398

    OPEN ol_nlb
    FETCH NEXT FROM ol_nlb into @uqty, @line, @pno, @loc, @part_type, @im_status

    While @@FETCH_STATUS = 0
    begin
      select @type = 'S'
      if @part_type = 'C'
      begin
        if exists (select 1 from ord_list_kit where order_no = @tran and order_ext = @ext
        and line_no = @line and ordered <> shipped)
        begin
          select @type = 'N'
            
          delete lot_bin_ship where tran_no = @tran and tran_ext = @ext and line_no = @line

          update ord_list_kit
          set shipped = 0 where order_no = @tran and order_ext = @ext and line_no = @line
        end
      end
      else
      begin            			
        if (@OverPick = 'N' and @part_type = 'P' and isnull(@im_status,'') != 'V') or 
          isnull(@im_status,'') = 'K'							-- mls 10/5/01 SCR 27723
											-- mls 8/10/00 SCR 23884
        begin
          -- Determine available quantity
          exec fs_pick_stock_avail @pno, @loc, @uqty, @im_status, @from, @avail_qty out, @type out
        end
      end  	  	

      select @avail_qty = isnull(@avail_qty,0)
      -- Ship appropriate quantity

      update ord_list
      set status = 
          case when ord_list.status > 'N' then ord_list.status
          else
            case when (isnull(@im_status,'A') = 'K' and @AutoKitPick = 'N')
              then case when shipped > 0 then 'P' else 'N' end
            when part_type = 'C' then 
              case @type when 'S' then 'P' else 'N' end
	    when part_type = 'M' then 'P'		
	    when part_type = 'V' then 'P'		
            when isnull(@im_status,'V') = 'V' then 'P'	
            else
              CASE @type
              WHEN 'S' THEN 'P'
              WHEN 'A' THEN case when @avail_qty > 0 then 'P' else 'N' end
              END
            end
          end,  							-- mls 7/24/00 SCR 23641
        shipped = 
          case when ord_list.status > 'N' then shipped			-- mls 7/24/00 SCR 23641
          else
            case when isnull(@im_status,'A') = 'K' and @AutoKitPick = 'N'	-- mls 6/27/00 SCR 21699
              then shipped
            when part_type = 'C' then 
              case @type when 'S' then ordered else 0 end		-- mls 11/1/01 SCR 27322
	    when part_type = 'M' then ordered				-- mls 11/13/01 SCR 27907
	    when part_type = 'V' then ordered				-- mls 11/13/01 SCR 27907
            when isnull(@im_status,'V') = 'V' then shipped		-- mls 7/24/00 SCR 23641
            else
              CASE @type
              WHEN 'S' THEN ordered
              WHEN 'A' THEN @avail_qty / conv_factor
              END
            end
          end,  							-- mls 7/24/00 SCR 23641
	who_picked_id = @who,
	picked_dt = @p_pick_dt
      from   ord_list
      where  order_no = @tran  and order_ext = @ext and line_no = @line
    
      FETCH NEXT FROM ol_nlb into @uqty, @line, @pno, @loc, @part_type, @im_status
    END -- end while @cnt < @rcnt

    close ol_nlb
    deallocate ol_nlb
    -- END SCR 22494 Changes
  END

  if exists (select 1 from ord_list where order_no = @tran and order_ext = @ext
    and status > 'N')
  begin
    update orders_all set printed='P',status='P'
    where order_no=@tran and @ext=ext and status = 'N'

    update orders_all set sopick_ctrl_num = @process_ctrl_num
    where order_no=@tran and @ext=ext
  end
  else
    update orders_all set printed='N',status='N'
    where order_no=@tran and @ext=ext and status = 'N'

  EXEC @result = fs_calculate_oetax_wrap @tran, @ext, 0, 1
  EXEC @result = fs_updordtots @tran, @ext  		  
END

if @from='T' 
BEGIN
	if @AutoPick = 'YES'
	BEGIN
		update xfer_list set shipped=ordered, status='P'
		from xfer_list
		where xfer_no=@tran and status < 'P'
		and (lb_tracking != 'Y' or @lb_mode = 'RELAXED')	-- mls 2/8/02 SCR 28326
	END
	update xfers_from set status='P' where xfer_no=@tran and status < 'P'
	update xfers_from set pick_ctrl_num = @process_ctrl_num where xfer_no = @tran
END
if @from='P' 
BEGIN
     update prod_list set status='P'
     where prod_no=@tran and prod_ext=@ext and status < 'P' and direction > 0
     if @t = 'YES'
     Begin
        update prod_list set used_qty=plan_qty, status='P', last_tran_date = @apply_date		-- mls 1/27/04 SCR 32295
        from  prod_list p, inv_master i
        where prod_no=@tran and prod_ext=@ext and p.part_no=i.part_no and
              i.lb_tracking != 'Y' and i.status='R'and
              p.status < 'P' and direction < 0 -- pick resources 

	if @AutoPick = 'YES'
	Begin
	        update prod_list set used_qty=plan_qty, status='P', last_tran_date = @apply_date	-- mls 1/27/04 SCR 32295
	        from  prod_list p, inv_master i
	        where prod_no=@tran and prod_ext=@ext and p.part_no=i.part_no and
	              i.lb_tracking != 'Y' and i.status<>'Q'and
	              p.status < 'P' and direction < 0
	End -- if @AutoPick 

     End
     if @AutoPick = 'YES' and @t = 'NO'
     Begin
        update prod_list set used_qty=plan_qty, status='P', last_tran_date = @apply_date		-- mls 1/27/04 SCR 32295
        from  prod_list p, inv_master i
        where prod_no=@tran and prod_ext=@ext and p.part_no=i.part_no and
              i.lb_tracking != 'Y' and i.status<>'Q' and i.status<>'R' and
              p.status < 'P' and direction < 0

     End
     update produce_all set status='P' where prod_no=@tran and prod_ext=@ext and status < 'P'

     update produce_all set wopick_ctrl_num = @process_ctrl_num 
	where prod_no=@tran and prod_ext=@ext
   END
END

if @online_call = 1
  select 1
GO
GRANT EXECUTE ON  [dbo].[fs_pick_stock] TO [public]
GO
