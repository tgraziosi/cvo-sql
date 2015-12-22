SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[fs_pick_lot_bin] @loc varchar(10), @pno varchar(30),
@from char(1), @tran int, @ext int, @uom char(2), @uqty decimal(20,8), 
@convfact decimal(20,8), @line int, @who varchar(30),
@apply_date datetime = NULL						-- mls 1/27/04 SCR 32295
AS 
BEGIN
declare @tuom decimal(20,8), @tqty decimal(20,8)
declare @ck_row int							-- mls 7/31/01 SCR 27322
declare @tobin varchar(50)					-- mls 12/10/09 SCR 051956



if @from = 'S'
BEGIN
  if exists (select 1 from lot_bin_ship
    where @pno=part_no and @loc=location and
      @tran=tran_no and @ext=tran_ext and @line=line_no) return -1
END
if @from = 'C'								-- mls 7/31/01 SCR 27322 start
BEGIN
  select @ck_row = @ext
  select @ext = order_ext from ord_list_kit 
    where order_no = @tran and line_no = @line and row_id = @ck_row

  if exists (select 1 from lot_bin_ship
    where @pno=part_no and @loc=location and
      @tran=tran_no and @ext=tran_ext and @line=line_no) return -1
END									-- mls 7/31/01 SCR 27322 end
if @from='P' 
BEGIN
	if exists (select 1 from lot_bin_prod
		where @pno=part_no and @loc=location and
		@tran=tran_no and @ext=tran_ext and @line=line_no) return -1
END
if @from='T' 
BEGIN
	if exists (select 1 from lot_bin_xfer
		where @pno=part_no and @loc=location and
		@tran=tran_no and @ext=tran_ext and @line=line_no) return -1

   SELECT @tobin = isnull((select dflt_recv_bin  			
   from xfers_all (nolock)
   join locations_all (nolock) on xfers_all.to_loc = locations_all.location
   where xfers_all.xfer_no = @tran),'IN TRANSIT')	-- mls 12/10/09 SCR 051956
END

declare @sq decimal(20,8), @lp int, @lot varchar(25), @bin varchar(12), 
@expdt datetime, @cost money, @qty decimal(20,8)
select @lp=1, @qty=(@uqty * @convfact)

if not exists (select 1 from lot_bin_stock 
	where @pno=part_no and @loc=location and bin_no != 'IN TRANSIT' and bin_no not like 'QC%') return 0

while @lp > 0
BEGIN
set rowcount 1
select @sq=qty, @lot=lot_ser, @bin=bin_no, @expdt=date_expires, @cost=cost
	from lot_bin_stock 
	where @pno=part_no and @loc=location and bin_no != 'IN TRANSIT' and bin_no not like 'QC%'
	order by date_expires
set rowcount 0


if @sq >= @qty 
BEGIN
select @lp=0
select @sq=@qty
END
if @from = 'S'
BEGIN
  insert into lot_bin_ship (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext, 
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who,
	qc_flag)
  select @loc, @pno, @bin, @lot, 'Q', @tran, @ext, getdate(),
	@expdt, @sq, -1, @cost, @uom, 
	round(@sq / @convfact,8,1) , 				-- mls 6/5/02 SCR 29009
	@convfact, @line, @who, 'N'
	select @qty=@qty - @sq
END
if @from ='C'								-- mls 7/31/01 SCR 27322 start
BEGIN
  insert into lot_bin_ship (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext, 
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who,
	qc_flag,kit_flag)
  select @loc, @pno, @bin, @lot, 'Q', @tran, @ext, getdate(),
	@expdt, @sq, -1, @cost, @uom, 
	round(@sq / @convfact,8,1) , 				-- mls 6/5/02 SCR 29009
	@convfact, @line, @who, 'N','Y'
	select @qty=@qty - @sq
END									-- mls 7/31/01 SCR 27322 end
if @from='P' BEGIN
  insert into lot_bin_prod (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext, 
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who,
	qc_flag)
  select @loc, @pno, @bin, @lot, 'Q', @tran, @ext, getdate(),
	@expdt, @sq, -1, @cost, @uom, 
	round(@sq / @convfact,8,1) , 				-- mls 6/5/02 SCR 29009
	@convfact, @line, @who, 'N'
	select @qty=@qty - @sq
END
if @from='T' BEGIN
  insert into lot_bin_xfer (location,part_no,bin_no,lot_ser,tran_code,tran_no,tran_ext, 
	date_tran,date_expires,qty,direction,cost,uom,uom_qty,conv_factor,line_no,who,
	to_bin)
  select @loc, @pno, @bin, @lot, 'Q', @tran, @ext, getdate(),
	@expdt, @sq, -1, @cost, @uom, 
	round(@sq / @convfact,8,1) , 				-- mls 6/5/02 SCR 29009
	@convfact, @line, @who, @tobin				-- mls 12/10/09 SCR 051956
	select @qty=@qty - @sq
END


if not exists (select * from lot_bin_stock 
	where @pno=part_no and @loc=location and bin_no != 'IN TRANSIT' and bin_no not like 'QC%') select @lp=0
END

if @from='S' 
BEGIN
  select @tuom= isnull((select sum(uom_qty) from lot_bin_ship
	where tran_no=@tran and line_no=@line and part_no=@pno and tran_ext=@ext and
	location=@loc),0)
  select @tqty= isnull((select sum(qty) from lot_bin_ship			-- mls 3/14/06 SCR 36306
	where tran_no=@tran and line_no=@line and part_no=@pno and tran_ext=@ext and
	location=@loc),0)
  select @tqty = round(@tqty / @convfact,8)					-- mls 3/14/06 SCR 36306 start
  update ord_list set status='P', shipped= @tqty,				-- mls 3/14/06 SCR 36306
    who_picked_id = @who, picked_dt = @apply_date
	from ord_list 
	where order_no=@tran and order_ext=@ext and line_no=@line

  if @tqty <> @tuom
  begin
    set rowcount 1
    update lot_bin_ship
    set uom_qty = uom_qty + (@tqty - @tuom)
    from lot_bin_ship where tran_no = @tran and tran_ext = @ext
    and line_no = @line and part_no = @pno and location = @loc
    set rowcount 0
  end										-- mls 3/14/06 SCR 36306 end
END
if @from='C' 									-- mls 7/31/01 SCR 27322 start
BEGIN
  select @tuom=isnull((select sum(uom_qty) from lot_bin_ship
	where tran_no=@tran and line_no=@line and part_no=@pno and tran_ext=@ext and
	location=@loc),0)
  select @tqty= isnull((select sum(qty) from lot_bin_ship			-- mls 3/14/06 SCR 36306
	where tran_no=@tran and line_no=@line and part_no=@pno and tran_ext=@ext and
	location=@loc),0)

  select @tqty = round(@tqty / @convfact,8)					-- mls 3/14/06 SCR 36306 start
  update ord_list_kit set status='P', 
  shipped=round(@tqty / qty_per,8,1)			-- mls 6/5/02 SCR 29009
  from ord_list_kit 
  where order_no=@tran and order_ext=@ext and line_no=@line and row_id = @ck_row

  if @tqty <> @tuom
  begin
    set rowcount 1
    update lot_bin_ship
    set uom_qty = uom_qty + (@tqty - @tuom)
    from lot_bin_ship where tran_no = @tran and tran_ext = @ext
    and line_no = @line and part_no = @pno and location = @loc
    set rowcount 0
  end										-- mls 3/14/06 SCR 36306 end

END										-- mls 7/31/01 SCR 27322 end
if @from='P' 
BEGIN
  select @tuom=isnull((select sum(uom_qty) from lot_bin_prod
	where tran_no=@tran and line_no=@line and part_no=@pno and tran_ext=@ext and
	location=@loc),0)
  select @tqty= isnull((select sum(qty) from lot_bin_prod			-- mls 3/14/06 SCR 36306
	where tran_no=@tran and line_no=@line and part_no=@pno and tran_ext=@ext and
	location=@loc),0)
  select @tqty = round(@tqty / @convfact,8)					-- mls 3/14/06 SCR 36306 start
  update prod_list set status='P', used_qty=@tqty, last_tran_date = @apply_date			-- mls 1/27/04 SCR 32295
  from prod_list where prod_no=@tran and line_no=@line and part_no=@pno and prod_ext = @ext	-- mls 7/26/99 SCR 70 20131

  if @tqty <> @tuom
  begin
    set rowcount 1
    update lot_bin_prod
    set uom_qty = uom_qty + (@tqty - @tuom)
    where tran_no = @tran and tran_ext = @ext
    and line_no = @line and part_no = @pno and location = @loc
    set rowcount 0
  end										-- mls 3/14/06 SCR 36306 end
END
if @from='T' 
BEGIN
select @tuom=isnull((select sum(uom_qty) from lot_bin_xfer
	where tran_no=@tran and line_no=@line and part_no=@pno and tran_ext=@ext and
	location=@loc) ,0)
  select @tqty= isnull((select sum(qty) from lot_bin_xfer			-- mls 3/14/06 SCR 36306
	where tran_no=@tran and line_no=@line and part_no=@pno and tran_ext=@ext and
	location=@loc),0)
  select @tqty = round(@tqty / @convfact,8)					-- mls 3/14/06 SCR 36306 start

  update xfer_list set status='P', shipped=@tqty,
    to_bin = @tobin											-- mls 12/10/09 SCR 051956
  from xfer_list 
  where xfer_no=@tran and line_no=@line and part_no=@pno

  if @tqty <> @tuom
  begin
    set rowcount 1
    update lot_bin_xfer
    set uom_qty = uom_qty + (@tqty - @tuom)
    where tran_no = @tran and tran_ext = @ext
    and line_no = @line and part_no = @pno and location = @loc
    set rowcount 0
  end										-- mls 3/14/06 SCR 36306 end

END
END
GO
GRANT EXECUTE ON  [dbo].[fs_pick_lot_bin] TO [public]
GO
