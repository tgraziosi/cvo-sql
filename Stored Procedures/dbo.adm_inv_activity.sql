SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_inv_activity] 
@range varchar(8000) = '0=0',
@type varchar(50) = 'DETAIL'
as

declare @range1 varchar(8000), @range2 varchar(8000)

declare @fld varchar(20), @cnt int, @start varchar(30), @end varchar(30)
declare @part1 varchar(30), @part2 varchar(30), @part_ind char(1),
  @loc1 varchar(10), @loc2 varchar(10), @loc_ind char(1),
  @date1 datetime, @date2 datetime, @date_ind char(1)

select @cnt = 1, @part_ind = 'N', @loc_ind = 'N', @date_ind = 'N',
  @date1 = getdate(), @date2 = getdate(),
  @part1 = '', @part2 = '', @loc1 = '', @loc2 = ''

-- includes current date - 1 = yes current date in range else 0 no current date not in range
create table #daterange (curr_ind int)

-- Inventory Temp Table
create table #tempinv
	( location varchar(10), part_no varchar(30), description varchar(45) NULL,
	 begin_stock money, in_stock money, rec_sum money,
	 ship_sum money, sales_sum money, xfer_sum_to money,
	 xfer_sum_from money, iss_sum money, mfg_sum money, used_sum money )

-- Issues Temp Table
create table #tempiss
	( issue_no int, location varchar(10), part_no varchar(30),
	 qty money, tdate datetime )

-- Produced Temp Table
create table #tempmfg
	( prod_no int, prod_ext int, location varchar(10), part_no varchar(30),
	 qty money, tdate datetime, status char(1) )

-- Received Temp Table
create table #temprec
	( receipt_no int, location varchar(10), part_no varchar(30),
	 qty money, tdate datetime )

-- Shipment Temp Table
create table #tempshp
	( order_no int, order_ext int, location varchar(10), part_no varchar(30),
	 qty money, tdate datetime )

-- Custom Kit Production Temp Table								-- mls 8/9/00 SCR 23883 start
create table #tempckp
	( order_no int, order_ext int, location varchar(10), part_no varchar(30),
	 qty money, tdate datetime )							-- mls 8/9/00 SCR 23883 end

-- Usage Temp Table
create table #tempuse
	( prod_no int, prod_ext int, location varchar(10), part_no varchar(30),
	 qty money, tdate datetime )

-- Transfer Out Temp Table
create table #tempxfrt
	( xfer_no int, from_loc varchar(10), to_loc varchar(10), part_no varchar(30),
	 qty money, tdate datetime )

create table #tempxfr
	( xfer_no int, from_loc varchar(10), to_loc varchar(10), part_no varchar(30),
	 qty money, tdate datetime )

-- Transfer In Temp Table
create table #tempxfr2
	( xfer_no int, from_loc varchar(10), to_loc varchar(10), part_no varchar(30),
	 qty money, tdate datetime )

create index inv1 on #tempinv (part_no, location)

select @range = replace(@range,'i.part_no','Upper(i.part_no)')
select @range = replace(@range,'i.location','Upper(i.location)')

-- Inventory Current Balance
-- Include K (AutoKit), H (Make Routed), M (Make), P (Purchase), Q (Purchase Outsource)
-- Exclude C (Custom Kit), R (Resource), V (Non Quantity Bearing)
-- Removed the hold quantitits from the in stock value as per Don.  Including
--   them throws off the starting number.  The only way to properly handle the
--   hold amounts would be to add a row for each hold amount to the report.
-- Include hold for xfr because it is stock that is between locations					-- mls 3/27/00 SCR 22691


select @range1 = replace(@range,'t.tdate','0=0 or 0')
select @range1 = replace(@range1,'"','''')

exec ('insert   #tempinv
select  distinct  i.location, i.part_no, substring(i.description,1,45), 0, 						-- mls 5/9/00
	(i.in_stock + i.hold_xfr), 0, 0, 0, 0, 0, 0, 0, 0		-- mls 3/27/00 SCR 22691
from     inventory i ( nolock ), locations l (nolock), region_vw r (nolock)
where    ( status in ( ''K'',''H'',''M'',''P'',''Q'',''C'' ) ) and 
   l.location = i.location and l.organization_id = r.org_id and ' + @range1)

-- Transfers Out
-- Include R (shipped), S (shipped received), P (picked), Q (open printed)		
-- Exclude O (open), N (new), V (void)

select @range1 = replace(@range,'t.tdate','0=0 or 0')
select @range1 = replace(@range1,'i.location','x.from_loc')
select @range1 = replace(@range1,'"','''')

exec ('insert  #tempxfrt
select distinct x.xfer_no, x.from_loc, x.to_loc,i.part_no,
        ( -1 * ( i.shipped * i.conv_factor ) ), 
   	case when x.status in (''R'', ''S'') then x.date_shipped		
	else getdate() end
from    xfers_all x ( nolock ), xfer_list i ( nolock ), locations l (nolock), region_vw r (nolock)
where   ( x.xfer_no = i.xfer_no ) and
        ( i.shipped > 0 ) and 						
        ( x.status in ( ''P'',''Q'',''R'',''S'' ) ) and 
		l.location = x.from_loc and l.organization_id = r.org_id and ' + @range1)

-- Transfers Out - include backout transaction for picked and open printed transfers	-- mls 11/12/01 SCR 27893
-- Include P (picked), Q (open printed)		
-- Exclude O (open), N (new), V (void), R (shipped), S (shipped received), 
exec ('insert  #tempxfrt
select  distinct x.xfer_no, x.from_loc, x.to_loc,i.part_no,
        ( ( i.shipped * i.conv_factor ) ), 
	getdate()
from    xfers_all x ( nolock ), xfer_list i ( nolock ), locations l (nolock), region_vw r (nolock)
where   ( x.xfer_no = i.xfer_no ) and
        ( x.status in ( ''P'',''Q'') ) and				
        ( i.shipped > 0 ) and 
		l.location = x.from_loc and l.organization_id = r.org_id and ' + @range1)

select @range1 = @range

if charindex('t.tdate',@range1) > 0
begin
  select @range1 = replace(@range1,'and t.tdate <=','or t.tdate >=')
  select @range1 = replace(@range1,'t.tdate',' datediff(day,"01/01/1900",tdate) + 693596 ')
end
select @range1 = replace(@range1,'Upper(i.location)','0=0 or ''a''')
select @range1 = replace(@range1,'Upper(i.part_no)','0=0 or ''a''')
select @range1 = replace(@range1,'l.organization_id','0=0 or ''a''')
select @range1 = replace(@range1,'r.region_id','0=0 or ''a''')
select @range1 = replace(@range1,'"','''')

exec ('insert #tempxfr	
select * from #tempxfrt i
where ' + @range1)

truncate table #tempxfrt

select @range1 = replace(@range,'and t.tdate <=','or t.tdate >')
select @range1 = replace(@range1,'t.tdate',' datediff(day,"01/01/1900",isnull( x.date_recvd, x.date_shipped )) + 693596 ')
select @range1 = replace(@range1,'i.location','x.to_loc')
select @range1 = replace(@range1,'"','''')

-- Transfers In
-- Include R (shipped), S (shipped received)
-- Exclude O (open), N (new), P (picked), Q (open printed), V (void)
-- mls 2/12/04 SCR 32429 - changed to use qty_rcvd if status = S

exec ('insert   #tempxfr2
select   distinct x.xfer_no,x.from_loc,x.to_loc,i.part_no,
		case when x.status = ''R'' then ( i.shipped * i.conv_factor ) else ( i.qty_rcvd * i.conv_factor) end ,
        isnull( x.date_recvd, x.date_shipped )
from    xfers_all x ( nolock ), xfer_list i( nolock ), locations l (nolock), region_vw r (nolock)
where   ( x.xfer_no = i.xfer_no ) and
        ( x.status in (''R'',''S'') ) and	
				l.location = x.to_loc and l.organization_id = r.org_id and
        ( case when x.status = ''R'' then ( i.shipped * i.conv_factor ) else ( i.qty_rcvd * i.conv_factor) end <> 0 ) and ' + @range1)

-- Transfers In - backout transfers in shipped status that have not made it to the to location -- mls 11/12/01 SCR 27893 start
-- Include R (shipped)
-- Exclude O (open), N (new), P (picked), Q (open printed), V (void), S (shipped received)
exec ('insert   #tempxfr2
select   distinct x.xfer_no,x.from_loc,x.to_loc,part_no,
		(( i.shipped * i.conv_factor ) * -1),
        isnull( x.date_recvd, x.date_shipped )
from    xfers_all x ( nolock ), xfer_list i ( nolock ), locations l (nolock), region_vw r (nolock)
where   ( x.xfer_no = i.xfer_no ) and
        ( x.status = ''R'' ) and
				l.location = x.to_loc and l.organization_id = r.org_id and
        ( i.shipped > 0 ) and ' + @range1)

select @range1 = replace(@range,'and t.tdate <=','or t.tdate >')
select @range1 = replace(@range1,'t.tdate',' datediff(day,"01/01/1900",issue_date) + 693596 ')
select @range1 = replace(@range1,'i.location','i.location_from')
select @range1 = replace(@range1,'"','''')

-- Issued (gain)/(loss)
exec ('insert  #tempiss
select distinct issue_no, location_from, part_no, ( qty * direction ), issue_date
from    issues_all i ( nolock ), locations l (nolock), region_vw r (nolock)
where status = ''S'' and 
l.location = i.location_from and l.organization_id = r.org_id and ' + @range1)

select @range1 = replace(@range,'and t.tdate <=','or t.tdate >')
select @range1 = replace(@range1,'t.tdate',' datediff(day,"01/01/1900",p.prod_date) + 693596 ')
select @range1 = replace(@range1,'i.part_no','x.part_no')
select @range1 = replace(@range1,'i.location','x.location')
select @range1 = replace(@range1,'"','''')

-- Produced
-- Include R (complete:qc hold) and S (complete), P (open:picked), Q (open:printed)		-- mls 3/27/00 SCR 22691 
-- Exclude H (hold:edit job), N (open:new), V (void)
exec('insert  #tempmfg
select distinct p.prod_no, p.prod_ext, x.location, x.part_no, ( x.used_qty - x.scrap_pcs ),
           p.prod_date, p.status
from    produce_all p ( nolock ), prod_list x ( nolock ), locations l (nolock), region_vw r (nolock)
where   ( p.prod_no = x.prod_no ) and
        ( p.prod_ext = x.prod_ext ) and
				l.location = x.location and l.organization_id = r.org_id and
        ( x.direction = 1 ) and
        (( p.status in (''P'',''Q'',''R'') and p.prod_type = ''R'') or
        ( p.status = ''S'') ) and
        ( x.used_qty <> 0 ) and ' + @range1)

-- Used
-- Include P (open:picked), Q (open:printed), R (complete:qc hold), S (complete)
-- Exclude H (hold:edit job), N (open:new), V (void)
-- Restrict to part type M (manufactured), P (purchase)
-- Restrict to non-cell items ''constrain = ''N''''
exec( 'insert #tempuse
select distinct x.prod_no, x.prod_ext, x.location, x.part_no, ( -1 * ( x.used_qty * x.conv_factor ) ),
            CASE WHEN ( p.status in ( ''P'', ''Q'' ) and p.prod_date < getdate() ) THEN p.prod_date
			     WHEN ( p.status in ( ''R'', ''S'' ) ) THEN p.prod_date
                 ELSE getdate()
            END
from    produce_all p ( nolock ), prod_list x ( nolock ), locations l (nolock), region_vw r (nolock)
where   ( p.prod_no = x.prod_no ) and
        ( p.prod_ext = x.prod_ext ) and
				l.location = x.location and l.organization_id = r.org_id and
        ( x.direction = -1 ) and
        ( x.constrain = ''N'' ) and                             -- mls 7/21/99 SCR 70 19767
        ( p.status in ( ''P'', ''Q'', ''R'', ''S'' ) ) and
        ( x.used_qty <> 0 ) and
        ( x.part_type in ( ''M'', ''P'' ) ) and ' + @range1)


select @range1 = replace(@range,'and t.tdate <=','or t.tdate >')
select @range1 = replace(@range1,'t.tdate',' datediff(day,"01/01/1900",isnull( p.date_shipped, getdate() )) + 693596 ')
select @range1 = replace(@range1,'i.part_no','x.part_no')
select @range1 = replace(@range1,'i.location','x.location')
select @range1 = replace(@range1,'"','''')

-- Used
-- Include P (open:picked),Q (open:printed / qc), R (ready/posting), S (shipped), T (shipped:transferred)
-- Exclude A (user defined hold), B (credit/price hold), C (credit hold)
--		   E (EDI), H (price hold), M (blanket order), N (new/open)
--         V (void), X (voided/cancelled quote)
-- Restrict to part type P (inventory item)
exec('insert #tempshp					
select distinct x.order_no, x.order_ext, x.location, x.part_no, 
( -1 * ( ( x.shipped - x.cr_shipped ) * x.conv_factor * x.qty_per) ), 
isnull( p.date_shipped, getdate() )
from    orders_all p ( nolock ), ord_list_kit x ( nolock ), locations l (nolock), region_vw r (nolock)
where   ( p.order_no = x.order_no ) and
        ( p.ext = x.order_ext ) and
				l.location = x.location and l.organization_id = r.org_id and
        ( x.status in ( ''P'', ''Q'', ''R'', ''S'' ) ) and	
        ( (x.shipped - x.cr_shipped) <> 0 ) and	
        ( x.part_type = ''P'' ) and ' + @range1)

select @range1 = replace(@range,'and t.tdate <=','or t.tdate >')
select @range1 = replace(@range1,'t.tdate',' datediff(day,"01/01/1900",a.recv_date) + 693596 ')
select @range1 = replace(@range1,'i.part_no','a.part_no')
select @range1 = replace(@range1,'i.location','a.location')
select @range1 = replace(@range1,'"','''')
-- Received
exec('insert  #temprec
select distinct a.receipt_no, a.location,
            CASE WHEN ( a.part_type = ''M'' ) THEN ''*PO MISC* '' + convert(varchar(20),a.part_no)		-- mls 9/10/01 SCR 27571
                 ELSE a.part_no
            END,( a.quantity * a.conv_factor ), a.recv_date
from    receipts_all a ( nolock ), locations l (nolock), region_vw r (nolock)
where  				l.location = a.location and l.organization_id = r.org_id and ' + @range1)

-- Received												-- mls 3/27/00 SCR 22691 start
-- Backout qc hold receipts.  They were included to show that the receipt had been made.		
exec('insert  #temprec
select distinct a.receipt_no, a.location,
            CASE WHEN ( a.part_type = ''M'' ) THEN ''*PO MISC* '' + convert(varchar(20),a.part_no)		-- mls 9/10/01 SCR 27571
                 ELSE a.part_no
            END,( a.quantity * a.conv_factor ) * -1, a.recv_date
from    receipts_all a ( nolock ), locations l (nolock), region_vw r (nolock)
where  ( qc_flag = ''Y'' ) and 
l.location = a.location and l.organization_id = r.org_id and ' + @range1)

-- Shipped/Credit
-- Restrict to part types 'P', 'C', 'M', 'J' 								-- mls 3/27/00 SCR 22691
-- This select will include those orders/credit returns that have been moved to
-- order status 'T'.

select @range1 = replace(@range,'and t.tdate <=','or t.tdate >')
select @range1 = replace(@range1,'t.tdate',' datediff(day,"01/01/1900",s.date_shipped) + 693596 ')
select @range1 = replace(@range1,'i.part_no','s.part_no')
select @range1 = replace(@range1,'i.location','s.location')
select @range1 = replace(@range1,'"','''')

exec('insert #tempshp
select distinct s.order_no,s.order_ext, s.location, 
       CASE WHEN s.part_type = ''M'' THEN ''*OE MISC* '' + convert(varchar(20),s.part_no)		
       WHEN s.part_type = ''J'' THEN ''*OE JOB* '' + convert(varchar(21),s.part_no) ELSE s.part_no END,
           ( ( s.cr_shipped - s.shipped ) * s.conv_factor ), s.date_shipped
from   shippers s ( nolock ), locations l (nolock), region_vw r (nolock)
where  ( s.part_type in( ''C'', ''P'', ''M'', ''J'' ) ) and 
l.location = s.location and l.organization_id = r.org_id and ' + @range1)
       
--  Custom kits/ balancing entry to show production on the sales order					-- mls 8/9/00 SCR 23883 start
exec('insert #tempckp
select distinct s.order_no,s.order_ext, s.location,  s.part_no,			
           ( ( s.cr_shipped - s.shipped ) * s.conv_factor * -1), s.date_shipped
from   shippers s ( nolock ), locations l (nolock), region_vw r (nolock)
where  ( s.part_type = ''C'' ) and 
l.location = s.location and l.organization_id = r.org_id and ' + @range1)

-- The next select from orders will pick up all orders that have
-- caused the inv_sales.sales_qty_mtd to be changed except status 'T'.
-- Pick up items from orders/ord_list
-- Include P (open:picked), Q (open:printed), R (ready:posting), S (shipped)
-- Exclude A (user defined hold), B (credit/price hold), C (credit hold),
--         E (EDI), H (price hold), M (blanket order), N (new/open),
--         T (shipped:transferred), V (void), X (voided/cancelled quote)

select @range1 = replace(@range,'and t.tdate <=','or t.tdate >')
select @range1 = replace(@range1,'t.tdate',' datediff(day,"01/01/1900",isnull( o.date_shipped, getdate() )) + 693596 ')
select @range1 = replace(@range1,'i.part_no','x.part_no')
select @range1 = replace(@range1,'i.location','x.location')
select @range1 = replace(@range1,'"','''')

exec('insert #tempshp
select distinct x.order_no, x.order_ext,  x.location, x.part_no,
		  ( ( x.cr_shipped - x.shipped ) * x.conv_factor ), isnull( o.date_shipped, getdate() )
from ord_list x (nolock), orders_all o (nolock), locations l (nolock), region_vw r (nolock)
where ( x.order_no = o.order_no ) and
	  ( x.order_ext = o.ext ) and
	  ( o.status in ( ''P'', ''Q'', ''R'', ''S'' ) ) and
	  ( x.part_type in (''P'',''C'') ) and	l.location = x.location and l.organization_id = r.org_id and ' + @range1)

--  Custom kits/ balancing entry to show production on the sales order					-- mls 8/9/00 SCR 23883 start
exec('insert #tempckp
select distinct x.order_no,x.order_ext, x.location,  x.part_no,			
           ( ( x.cr_shipped - x.shipped ) * x.conv_factor * -1), isnull(o.date_shipped, getdate())
from ord_list x (nolock), orders_all o (nolock), locations l (nolock), region_vw r (nolock)
where ( x.order_no = o.order_no ) and
	  ( x.order_ext = o.ext ) and
	  ( o.status in ( ''P'', ''Q'', ''R'', ''S'' ) ) and
	  ( x.part_type = ''C'' ) and l.location = x.location and l.organization_id = r.org_id and ' + @range1)

select @range1 = replace(@range,'t.tdate',' datediff(day,"01/01/1900",getdate() ) + 693596 ')
select @range1 = replace(@range1,'Upper(i.part_no)','0=0 or "a"')
select @range1 = replace(@range1,'Upper(i.location)','0=0 or "a"')
select @range1 = replace(@range1,'l.organization_id','0=0 or "a"')
select @range1 = replace(@range1,'r.region_id','0=0 or "a"')
select @range1 = replace(@range1,'"','''')

exec ('insert #daterange select case when ' + @range1 + ' then 1 else 0 end')

select @range1 = replace(@range,' or ',' and ')
select @range1 = replace(@range1,'Upper(i.part_no)','0=0 or "a"')
select @range1 = replace(@range1,'Upper(i.location)','0=0 or "a"')
select @range1 = replace(@range1,'l.organization_id','0=0 or "a"')
select @range1 = replace(@range1,'r.region_id','0=0 or "a"')
select @range1 = replace(@range1,'t.tdate <=','t.tdate >')
select @range1 = replace(@range1,'t.tdate',' datediff(day,"01/01/1900",t.tdate) + 693596 ')
select @range1 = replace(@range1,'"','''')

if ( upper(@type) = 'SUMMARY' ) AND (select curr_ind from #daterange) = 0
Begin
    -- Begin SCR 21366
    -- Adjust in stock quantity based on end date
	 -- adjustments
  select @range1 = replace(@range1,'t.tdate','tdate')

  exec(' update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempiss
							   where  #tempinv.part_no = #tempiss.part_no
							   and    #tempinv.location = #tempiss.location 
  and ' + @range1 + '),0)')
  exec('delete from #tempiss  where ' + @range1)

 	 -- receipts
  exec(' update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #temprec
							   where  #tempinv.part_no = #temprec.part_no
							   and    #tempinv.location = #temprec.location
  and ' + @range1 + '),0)')
  exec('delete from #temprec  where ' + @range1)

	 -- shipments
  exec(' update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempshp
							   where  #tempinv.part_no = #tempshp.part_no
							   and    #tempinv.location = #tempshp.location
  and ' + @range1 + '),0)')
  exec('delete from #tempshp  where ' + @range1)

	 -- custom kit production									-- mls 8/9/00 SCR 23883 start
  exec(' update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempckp
							   where  #tempinv.part_no = #tempckp.part_no
							   and    #tempinv.location = #tempckp.location
  and ' + @range1 + '),0)')
  exec('delete from #tempckp  where ' + @range1)

	 -- transfers out
  exec(' update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempxfr
							   where  #tempinv.part_no = #tempxfr.part_no
							   and    #tempinv.location = #tempxfr.from_loc
  and ' + @range1 + '),0)')
  exec('delete from #tempxfr  where ' + @range1)

	 -- transfers in
  exec(' update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempxfr2
							   where  #tempinv.part_no = #tempxfr2.part_no
							   and    #tempinv.location = #tempxfr2.to_loc
  and ' + @range1 + '),0)')
  exec('delete from #tempxfr2 where ' + @range1)

	 -- production
  exec(' update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempmfg
							   where  #tempinv.part_no = #tempmfg.part_no
							   and    #tempinv.location = #tempmfg.location
  and ' + @range1 + '),0)')
  exec('delete from #tempmfg  where ' + @range1)

	 -- usage
  exec(' update #tempinv
	 set	  in_stock = in_stock - isnull(( select sum(qty)
							   from   #tempuse
							   where  #tempinv.part_no = #tempuse.part_no
							   and    #tempinv.location = #tempuse.location
  and ' + @range1 + '),0)')
  exec('delete from #tempuse  where ' + @range1)

    -- END SCR 21366
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
        used_sum = isnull( ( select sum( qty )
                             from   #tempuse
                             where  ( a.part_no = #tempuse.part_no ) and
                                    ( a.location = #tempuse.location ) ), 0 ),
        rec_sum = isnull( ( select sum( qty )
                            from   #temprec
                            where  ( a.part_no = #temprec.part_no ) and
                                   ( a.location = #temprec.location ) ), 0 ),
        ship_sum = isnull( ( select sum( qty )
                             from   #tempshp
                             where ( a.part_no=#tempshp.part_no ) and
                                   ( a.location=#tempshp.location ) ), 0 ) +
		   isnull( ( select sum( qty )								-- mls 8/9/00 SCR 23883 start
                             from   #tempckp
                             where ( a.part_no=#tempckp.part_no ) and
                                   ( a.location=#tempckp.location ) ), 0 ),				-- mls 8/9/00 SCR 23883 end
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

if ( upper(@type) = 'SUMMARY' )
Begin
	select location, part_no, description, begin_stock, in_stock, rec_sum,
		ship_sum, sales_sum, xfer_sum_to, xfer_sum_from, iss_sum, mfg_sum, used_sum
	from #tempinv
	order by location, part_no
End

if ( upper(@type) = 'DETAIL' )
Begin
  select @range1 = replace(@range,'Upper(i.part_no)','0=0 or "a"')
  select @range1 = replace(@range1,'t.tdate',' datediff(day,"01/01/1900",tdate) + 693596 ')
  select @range1 = replace(@range1,'l.organization_id','0=0 or "a"')
  select @range1 = replace(@range1,'r.region_id','0=0 or "a"')
  select @range1 = replace(@range1,'"','''')

	create table #temptrn
	    ( tran_type char(20), tran_num int, tran_ext int, tran_no char(20),
	      location varchar(10), part_no varchar(30), description varchar(255) NULL,
	      qty decimal(20,8), tran_date datetime NULL)

    -- Beginning Balance
	insert #temptrn
	select 'Begin', 0,0,'', location, part_no, description, begin_stock, NULL
	from   #tempinv
	order by location, part_no

    -- Transfer Out
  select @range2 = replace(@range1,'i.location','from_loc')
  exec('insert #temptrn
	select ''Xfer Out'', xfer_no, 0, xfer_no, from_loc, part_no, '''', qty , tdate
	from   #tempxfr where qty < 0 and ' + @range2)

    -- Transfer Picked										-- mls 11/12/01 SCR 27893 start
  exec('insert #temptrn
	select ''Xfer Pick'', xfer_no, 0, xfer_no, from_loc, part_no, '''', qty , tdate
	from   #tempxfr where  qty > 0 and ' + @range2)						-- mls 11/12/01 SCR 27893 end

    -- Transfer In
  select @range2 = replace(@range1,'i.location','to_loc')
  exec('insert #temptrn
	select ''Xfer In'', xfer_no, 0, xfer_no, to_loc, part_no, '''', qty, tdate
	from   #tempxfr2 where qty > 0 and ' + @range2)

    -- Transfer In Transit									-- mls 11/12/01 SCR 27893 start
  exec('insert #temptrn
	select ''Xfer In Transit'', xfer_no, 0, xfer_no, to_loc, part_no, '''', qty, tdate
	from   #tempxfr2 where qty < 0 and ' + @range2)						-- mls 11/12/01 SCR 27893 end

    -- Issue (gain)
  select @range2 = replace(@range2,'Upper(to_loc)','0=0 or ''a''')
  exec('insert #temptrn
	select ''Issue (gain)'', issue_no, 0, issue_no, location, part_no, '''', qty, tdate
	from   #tempiss where qty > 0 and ' + @range2)

    -- Issue (loss)
  exec('insert #temptrn
	select ''Issue (loss)'', issue_no, 0, issue_no, location, part_no, '''',qty, tdate
	from   #tempiss where qty < 0 and ' + @range2)

    -- Produced
  exec('insert #temptrn
	select ''Produced'', prod_no, prod_ext, convert(varchar(10),prod_no) + ''-'' + convert(varchar(10),prod_ext), location, part_no, '''', qty, tdate
	from   #tempmfg where ' + @range2)

    -- Used
  exec('insert #temptrn
	select ''Used'', prod_no, prod_ext, convert(varchar(10),prod_no) + ''-'' + convert(varchar(10),prod_ext), location, part_no, '''', qty , tdate
	from   #tempuse where ' + @range2)
    -- Recieved
  exec('insert #temptrn
	select ''Received'', receipt_no, 0, receipt_no, location, part_no, '''', qty, tdate
	from   #temprec where ' + @range2)

    -- Ship
  exec('insert #temptrn
	select ''Shipped'', order_no, 0, convert(varchar(10),order_no) + ''-'' + convert(varchar(10),order_ext), location, part_no, '''', qty , tdate
	from   #tempshp where qty < 0 and ' + @range2)

    -- Ship (credit)
  exec('insert #temptrn
	select ''Shipped (credit)'', order_no, 0, convert(varchar(10),order_no) + ''-'' + convert(varchar(10),order_ext), location, part_no, '''', qty, tdate
	from   #tempshp where qty > 0 and ' + @range2)

    -- Ship (custom kit prod balancing entry)							-- mls 8/9/00 SCR 23883 start
  exec('insert #temptrn
	select ''Custom Kitted'', order_no, 0, convert(varchar(10),order_no) + ''-'' + convert(varchar(10),order_ext), location, part_no, '''', qty, tdate
	from   #tempckp where ' + @range2)


	select t.tran_type, t.tran_no, i.location, i.part_no, t.description,
	         t.qty, t.tran_date
	from #temptrn t, #tempinv i								-- mls 10/13/00 SCR 24581
	where t.part_no = i.part_no and t.location = i.location					-- mls 10/13/00 SCR 24581
	order by i.location, i.part_no, convert( char(8), t.tran_date, 112 ), t.tran_type, t.tran_num, t.tran_ext

End

GO
GRANT EXECUTE ON  [dbo].[adm_inv_activity] TO [public]
GO
