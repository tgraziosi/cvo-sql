SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[fs_activity] @loc varchar(10), @pn varchar(30), @bdate datetime, @edate datetime,
 @type varchar(10) AS


-- Inventory Temp Table
create table #tempinv
	( location varchar(10), part_no varchar(30), description varchar(45) NULL,
	 begin_stock money, in_stock money, rec_sum money,
	 ship_sum money, sales_sum money, xfer_sum_to money,
	 xfer_sum_from money, iss_sum money, mfg_sum money, used_sum money )

-- Issues Temp Table
create table #tempiss
	( issue_no int, location varchar(10), part_no varchar(30),
	 qty money, issue_date datetime )

-- Produced Temp Table
create table #tempmfg
	( prod_no int, prod_ext int, location varchar(10), part_no varchar(30),
	 qty money, prod_date datetime, status char(1) )

-- Received Temp Table
create table #temprec
	( receipt_no int, location varchar(10), part_no varchar(30),
	 qty money, recv_date datetime )

-- Shipment Temp Table
create table #tempshp
	( order_no int, order_ext int, location varchar(10), part_no varchar(30),
	 qty money, date_shipped datetime )

-- Usage Temp Table
create table #tempuse
	( prod_no int, prod_ext int, location varchar(10), part_no varchar(30),
	 qty money, prod_date datetime )

-- Transfer Out Temp Table
create table #tempxfr
	( xfer_no int, from_loc varchar(10), to_loc varchar(10), part_no varchar(30),
	 qty money, date_shipped datetime )

-- Transfer In Temp Table
create table #tempxfr2
	( xfer_no int, from_loc varchar(10), to_loc varchar(10), part_no varchar(30),
	 qty money, date_shipped datetime )

-- Custom Kit Production Temp Table								-- mls 8/10/00 SCR 23883 start
create table #tempckp
	( order_no int, order_ext int, location varchar(10), part_no varchar(30),
	 qty money, date_shipped datetime )							-- mls 8/10/00 SCR 23883 end

create index inv1 on #tempinv (part_no, location)

-- Inventory Current Balance
-- Include K (AutoKit), H (Make Routed), M (Make), P (Purchase), Q (Purchase Outsource)
-- Exclude C (Custom Kit), R (Resource), V (Non Quantity Bearing)
-- Removed the hold quantitits from the in stock value as per Don.  Including
--   them throws off the starting number.  The only way to properly handle the
--   hold amounts would be to add a row for each hold amount to the report.
-- Include hold for xfr because it is stock that is between locations					-- mls 3/27/00 SCR 22691

insert   #tempinv
select   location, part_no, substring(description,1,45), 0, 
	(in_stock + hold_xfr), 0, 0, 0, 0, 0, 0, 0, 0		-- mls 3/27/00 SCR 22691
from     inventory ( nolock )
where    ( status in ( 'K','H','M','P','Q','C' ) ) and							-- mls 8/10/00 SCR 23883
         ( part_no like @pn ) and
         ( location like @loc )

set rowcount 0

-- Transfers Out
-- Include R (shipped), S (shipped received), P (picked), Q (open printed)		
-- Exclude O (open), N (new), V (void)
insert  #tempxfr
select  xfers.xfer_no, xfers.from_loc, xfers.to_loc,part_no,
        ( -1 * ( xfer_list.shipped * xfer_list.conv_factor ) ), 
   	case when xfers.status in ("R", "S") then date_shipped				
	else getdate() end
from    xfers ( nolock ), xfer_list ( nolock )
where   --( xfers.date_shipped >= @bdate ) and
	( xfers.xfer_no = xfer_list.xfer_no ) and
        ( xfers.status in ( 'P','Q','R','S' ) ) and					
        ( xfer_list.part_no like @pn ) and
        ( xfers.from_loc like @loc ) and
        ( xfer_list.shipped > 0 ) 						

delete from #tempxfr									-- mls 9/6/00 SCR 24077
where date_shipped < @bdate								-- mls 9/6/00 SCR 24077

-- Transfers In
-- Include S (shipped received)
-- Exclude O (open), N (new), P (picked), Q (open printed), R (shipped), V (void)
insert   #tempxfr2
select   xfers.xfer_no,xfers.from_loc,xfers.to_loc,part_no,
		( xfer_list.shipped * xfer_list.conv_factor ),
        isnull( xfers.date_recvd, xfers.date_shipped )
from    xfers ( nolock ), xfer_list ( nolock )
where   ( isnull( xfers.date_recvd, xfers.date_shipped ) >= @bdate ) and
        ( xfers.xfer_no = xfer_list.xfer_no ) and
        ( xfers.status = 'S' ) and
        ( xfer_list.part_no like @pn ) and
        ( xfers.to_loc like @loc ) and
        ( xfer_list.shipped > 0 )

-- Issued (gain)/(loss)
insert  #tempiss
select  issue_no, location_from, part_no, ( qty * direction ), issue_date
from    issues ( nolock )
where   ( issue_date >= @bdate ) and
        ( part_no like @pn ) and
        ( location_from like @loc )

-- Produced
-- Include R (complete:qc hold) and S (complete), P (open:picked), Q (open:printed)		-- mls 3/27/00 SCR 22691 
-- Exclude H (hold:edit job), N (open:new), V (void)
insert  #tempmfg
select  p.prod_no, p.prod_ext, x.location, x.part_no, ( x.used_qty - x.scrap_pcs ),
           p.prod_date, p.status
from    produce p ( nolock ), prod_list x ( nolock )
where   ( p.prod_no = x.prod_no ) and
        ( p.prod_ext = x.prod_ext ) and
        ( x.direction = 1 ) and
        ( p.prod_date >= @bdate ) and
        ( x.part_no like @pn ) and
        ( x.location like @loc ) and
        ( p.status in ( 'P','Q', 'R', 'S' ) ) and						-- mls 3/27/00 SCR 22691
        ( x.used_qty <> 0 )

-- Used
-- Include P (open:picked), Q (open:printed), R (complete:qc hold), S (complete)
-- Exclude H (hold:edit job), N (open:new), V (void)
-- Restrict to part type M (manufactured), P (purchase)
-- Restrict to non-cell items "constrain = 'N'"
insert #tempuse
select  x.prod_no, x.prod_ext, x.location, x.part_no, ( -1 * ( x.used_qty * x.conv_factor ) ),
            CASE WHEN ( p.status in ( 'P', 'Q' ) and p.prod_date < getdate() ) THEN p.prod_date
			     WHEN ( p.status in ( 'R', 'S' ) ) THEN p.prod_date
                 ELSE getdate()
            END
from    produce p ( nolock ), prod_list x ( nolock )
where   ( p.prod_no = x.prod_no ) and
        ( p.prod_ext = x.prod_ext ) and
        ( x.direction = -1 ) and
        ( x.part_no like @pn ) and
        ( x.location like @loc ) and
        ( x.constrain = 'N' ) and                             -- mls 7/21/99 SCR 70 19767
        ( p.status in ( 'P', 'Q', 'R', 'S' ) ) and
        ( x.used_qty <> 0 ) and
        ( x.part_type in ( 'M', 'P' ) ) and
        ( p.prod_date >= @bdate )

-- Used
-- Include P (open:picked),Q (open:printed / qc), R (ready/posting), S (shipped), T (shipped:transferred)
-- Exclude A (user defined hold), B (credit/price hold), C (credit hold)
--		   E (EDI), H (price hold), M (blanket order), N (new/open)
--         V (void), X (voided/cancelled quote)
-- Restrict to part type P (inventory item)
insert #tempshp												-- mls 3/27/00 SCR 22691
select  x.order_no, x.order_ext, x.location, x.part_no, 
	( -1 * ( ( x.shipped - x.cr_shipped ) * x.conv_factor * qty_per) ),				-- mls 5/11/00 SCR 22801 
isnull( p.date_shipped, getdate() )
from    orders p ( nolock ), ord_list_kit x ( nolock )
where   ( p.order_no = x.order_no ) and
        ( p.ext = x.order_ext ) and
        ( x.part_no like @pn ) and
        ( x.location like @loc ) and
        ( x.status in ( 'P', 'Q', 'R', 'S' ) ) and							-- mls 3/27/00 SCR 22691
        ( (x.shipped - x.cr_shipped) <> 0 ) and								-- mls 3/27/00 SCR 22691
        ( x.part_type = 'P' ) and
        ( isnull( p.date_shipped, getdate() ) >= @bdate )

-- Received
insert  #temprec
select  receipt_no, location,
            CASE WHEN ( part_type = 'M' ) THEN '*PO MISC* ' + part_no
                 ELSE part_no
            END,( quantity * conv_factor ), recv_date
from    receipts ( nolock )
where  ( recv_date >= @bdate ) and
--       ( qc_flag in ( 'N', 'F' ) ) and								-- mls 3/27/00 SCR 22691
       ( part_no like @pn ) and
       ( location like @loc )

-- Received												-- mls 3/27/00 SCR 22691 start
-- Backout qc hold receipts.  They were included to show that the receipt had been made.		
insert  #temprec
select  receipt_no, location,
            CASE WHEN ( part_type = 'M' ) THEN '*PO MISC* ' + part_no
                 ELSE part_no
            END,( quantity * conv_factor ) * -1, recv_date
from    receipts ( nolock )
where  ( recv_date >= @bdate ) and
       ( qc_flag = 'Y' ) and	
       ( part_no like @pn ) and
       ( location like @loc )										-- mls 3/27/00 SCR 22691 end

-- Shipped/Credit
-- Restrict to part types 'P', 'C', 'M', 'J' 								-- mls 3/27/00 SCR 22691
-- This select will include those orders/credit returns that have been moved to
-- order status 'T'.

insert #tempshp
select order_no,order_ext, location, 
       CASE WHEN part_type = "M" THEN "*OE MISC* " + part_no 						-- mls 3/27/00 SCR 22691
       WHEN part_type = "J" THEN "*OE JOB* " + part_no ELSE part_no END,				-- mls 3/27/00 SCR 22691
           ( ( cr_shipped - shipped ) * conv_factor ), date_shipped
from   shippers ( nolock )
where  ( part_type in( 'C', 'P', 'M', 'J' ) ) and							-- mls 3/27/00 SCR 22691
       ( date_shipped >= @bdate ) and
       ( part_no like @pn ) and
       ( location like @loc )

--  Custom kits/ balancing entry to show production on the sales order					-- mls 8/10/00 SCR 23883 start
insert #tempckp
select order_no,order_ext, location,  part_no,			
           ( ( cr_shipped - shipped ) * conv_factor * -1), date_shipped
from   shippers ( nolock )
where  ( part_type = 'C' ) and	
       ( date_shipped >= @bdate ) and
       ( part_no like @pn ) and ( location like @loc )							-- mls 8/10/00 SCR 23833 end

-- The next select from orders will pick up all orders that have
-- caused the inv_sales.sales_qty_mtd to be changed except status 'T'.
-- Pick up items from orders/ord_list
-- Include P (open:picked), Q (open:printed), R (ready:posting), S (shipped)
-- Exclude A (user defined hold), B (credit/price hold), C (credit hold),
--         E (EDI), H (price hold), M (blanket order), N (new/open),
--         T (shipped:transferred), V (void), X (voided/cancelled quote)
insert #tempshp
select l.order_no, l.order_ext,  l.location, l.part_no,
		  ( ( l.cr_shipped - l.shipped ) * l.conv_factor ), isnull( o.date_shipped, getdate() )
from ord_list l (nolock), orders o (nolock)
where ( l.order_no = o.order_no ) and
	  ( l.order_ext = o.ext ) and
	  ( o.status in ( 'P', 'Q', 'R', 'S' ) ) and
	  ( isnull( o.date_shipped, getdate() ) >= @bdate ) and
	  ( l.part_type in ('P','C') ) and								-- mls 8/10/00 SCR 23883
 	  ( l.part_no like @pn ) and
	  ( l.location like @loc )

--  Custom kits/ balancing entry to show production on the sales order					-- mls 8/10/00 SCR 23883 start
insert #tempckp
select l.order_no,l.order_ext, l.location,  l.part_no,			
           ( ( l.cr_shipped - l.shipped ) * l.conv_factor * -1), isnull(o.date_shipped, getdate())
from ord_list l (nolock), orders o (nolock)
where ( l.order_no = o.order_no ) and
	  ( l.order_ext = o.ext ) and
	  ( o.status in ( 'P', 'Q', 'R', 'S' ) ) and
	  ( isnull( o.date_shipped, getdate() ) >= @bdate ) and
	  ( l.part_type = 'C' ) and
 	  ( l.part_no like @pn ) and
	  ( l.location like @loc )									-- mls 8/10/00 SCR 23833 end

if ( @type = 'SUMMARY' ) AND ( @edate < getdate() )
Begin
    -- Begin SCR 21366
    -- Adjust in stock quantity based on end date
	 -- adjustments
	 update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempiss
							   where  #tempinv.part_no = #tempiss.part_no
							   and    #tempinv.location = #tempiss.location
    							   and    #tempiss.issue_date > @edate),0) 
	 -- receipts
       update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #temprec
							   where  #tempinv.part_no = #temprec.part_no
							   and    #tempinv.location = #temprec.location
    							   and    #temprec.recv_date > @edate),0)
	 -- shipments
	 update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempshp
							   where  #tempinv.part_no = #tempshp.part_no
							   and    #tempinv.location = #tempshp.location
    							   and    #tempshp.date_shipped > @edate),0)
	 -- transfers out
	 update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempxfr
							   where  #tempinv.part_no = #tempxfr.part_no
							   and    #tempinv.location = #tempxfr.from_loc
    							   and    #tempxfr.date_shipped > @edate),0)
	 -- transfers in
	 update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempxfr2
							   where  #tempinv.part_no = #tempxfr2.part_no
							   and    #tempinv.location = #tempxfr2.to_loc
    							   and    #tempxfr2.date_shipped > @edate),0)
	 -- production
	 update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempmfg
							   where  #tempinv.part_no = #tempmfg.part_no
							   and    #tempinv.location = #tempmfg.location
    							   and    #tempmfg.prod_date > @edate),0)
	 -- usage
	 update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempuse
							   where  #tempinv.part_no = #tempuse.part_no
							   and    #tempinv.location = #tempuse.location
    							   and    #tempuse.prod_date > @edate),0)
	 -- custom kit production									-- mls 8/10/00 SCR 23883 start
	 update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempckp
							   where  #tempinv.part_no = #tempckp.part_no
							   and    #tempinv.location = #tempckp.location
    							   and    #tempckp.date_shipped > @edate),0)	-- mls 8/10/00 SCR 23883 end
    -- END SCR 21366

    -- Delete rows beyond ending date
	delete from #tempiss  where ( issue_date   > @edate )
	delete from #tempmfg  where ( prod_date    > @edate )
	delete from #temprec  where ( recv_date    > @edate )
	delete from #tempshp  where ( date_shipped > @edate )
	delete from #tempuse  where ( prod_date    > @edate )
	delete from #tempxfr  where ( date_shipped > @edate )
	delete from #tempxfr2 where ( date_shipped > @edate )
	delete from #tempckp where ( date_shipped > @edate )					-- mls 8/10/00 SCR 23883
end

-- update sum columns
update  #tempinv
set     iss_sum = isnull( ( select sum( qty )
                            from   #tempiss
                            where  ( a.part_no = #tempiss.part_no ) and
                                   ( a.location = #tempiss.location ) ), 0 ),
        mfg_sum = isnull( ( select sum( qty )
                            from   #tempmfg
                            where  ( a.part_no = #tempmfg.part_no ) and
                                   ( a.location = #tempmfg.location ) ), 0 ),
        rec_sum = isnull( ( select sum( qty )
                            from   #temprec
                            where  ( a.part_no = #temprec.part_no ) and
                                   ( a.location = #temprec.location ) ), 0 ),
        ship_sum = isnull( ( select sum( qty )
                             from   #tempshp
                             where ( a.part_no=#tempshp.part_no ) and
                                   ( a.location=#tempshp.location ) ), 0 ) +
		   isnull( ( select sum( qty )								-- mls 8/10/00 SCR 23883 start
                             from   #tempckp
                             where ( a.part_no=#tempckp.part_no ) and
                                   ( a.location=#tempckp.location ) ), 0 ),				-- mls 8/10/00 SCR 23883 end
        used_sum = isnull( ( select sum( qty )
                             from   #tempuse
                             where  ( a.part_no = #tempuse.part_no ) and
                                    ( a.location = #tempuse.location ) and
	                            ( #tempuse.prod_date >= @bdate ) ), 0 ),
        xfer_sum_from = isnull( ( select sum( qty )
                                  from   #tempxfr
                                  where ( a.part_no = #tempxfr.part_no ) and
	                                ( a.location = #tempxfr.from_loc ) ), 0 ),
        xfer_sum_to = isnull( ( select sum( qty )
                                from   #tempxfr2
                                where  ( a.part_no = #tempxfr2.part_no ) and
                                       ( a.location = #tempxfr2.to_loc ) ), 0 )
from #tempinv a

-- Calculate beginning stock
update #tempinv
set    begin_stock = ( in_stock - ship_sum - xfer_sum_from - rec_sum -
                        used_sum - xfer_sum_to - iss_sum - mfg_sum )

if ( @type = 'SUMMARY' )
Begin
	select location, part_no, description, begin_stock, in_stock, rec_sum,
		ship_sum, sales_sum, xfer_sum_to, xfer_sum_from, iss_sum, mfg_sum, used_sum
	from #tempinv
	order by location, part_no
End

if ( @type = 'DETAIL' )
Begin
	create table #temptrn
	    ( tran_type char(1), tran_no int, tran_ext int,
	      location varchar(10), part_no varchar(30), description varchar(45) NULL,
	      qty money, direction int, tran_date datetime )

    -- Beginning Balance
	insert #temptrn
	select 'B', 0, 0, location, part_no, description, begin_stock, 1, @bdate
	from   #tempinv
	order by location, part_no

    -- Issue (gain)
	insert #temptrn
	select 'I', issue_no, 0, location, part_no, '', qty, +1, issue_date
	from   #tempiss
	where  ( issue_date <= @edate ) and
           ( qty > 0 )

    -- Issue (loss)
	insert #temptrn
	select 'J', issue_no, 0, location, part_no, '',qty, -1, issue_date
	from   #tempiss
	where  ( issue_date <= @edate ) and
           ( qty < 0 )

    -- Transfer Out
	insert #temptrn
	select 'Y', xfer_no, 0, from_loc, part_no, '', qty, -1, date_shipped
	from   #tempxfr
	where  ( from_loc like @loc ) and
           ( date_shipped <= @edate )

    -- Transfer In
	insert #temptrn
	select 'X', xfer_no, 0, to_loc, part_no, '', qty, +1, date_shipped
	from   #tempxfr2
	where  ( to_loc like @loc ) and
           ( date_shipped <= @edate )

    -- Produced
	insert #temptrn
	select 'M', prod_no, prod_ext, location, part_no, '', qty, +1, prod_date
	from   #tempmfg
	where  ( prod_date <= @edate )

    -- Recieved
	insert #temptrn
	select 'R', receipt_no, 0, location, part_no, '', qty, +1, recv_date
	from   #temprec
	where  ( recv_date <= @edate )

    -- Ship
	insert #temptrn
	select 'S', order_no, order_ext, location, part_no, '', qty, -1, date_shipped
	from   #tempshp
	where  ( date_shipped <= @edate ) and
           ( qty < 0 )

    -- Ship (credit)
	insert #temptrn
	select 'T', order_no, order_ext, location, part_no, '', qty, +1, date_shipped
	from   #tempshp
	where  ( date_shipped <= @edate ) and
           ( qty > 0 )

    -- Ship (custom kit prod balancing entry)							-- mls 8/10/00 SCR 23883 start
	insert #temptrn
	select 'C', order_no, order_ext, location, part_no, '', qty, 1, date_shipped
	from   #tempckp
	where  ( date_shipped <= @edate )							-- mls 8/10/00 SCR 23883 end

    -- Used
	insert #temptrn
	select 'U', prod_no, prod_ext, location, part_no, '', qty, -1, prod_date
	from   #tempuse
	where  ( prod_date <= @edate )

	select t.tran_type, t.tran_no, t.tran_ext, i.location, i.part_no, t.description,
	         t.qty, t.direction, t.tran_date
	from #temptrn t, #tempinv i								-- mls 10/20/00 SCR 24581
	where t.part_no = i.part_no and t.location = i.location					-- mls 10/20/00 SCR 24581
	order by i.location, i.part_no, convert( char(8), t.tran_date, 112 ), t.tran_type, t.tran_no, t.tran_ext
End


GO
GRANT EXECUTE ON  [dbo].[fs_activity] TO [public]
GO
