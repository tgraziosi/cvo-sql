SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[fs_weekly_activity_sp] 
			@loc 		varchar(10), 
			@pn 		varchar(30), 
			@bdate 		datetime, 
			@edate 		datetime,
			@in_stock	float OUTPUT,
			@stock_in 	float OUTPUT,	
			@stock_out	float OUTPUT,	
			@balance	float OUTPUT,
			@balanced_stock_in float,
			@first_run	smallint	
AS

	-- atp data view
	CREATE TABLE #proyection
	(
		week_no		int,
		end_date	datetime,
		in_stock	decimal(20,8),
		stock_in	decimal(20,8),
		stock_out	decimal(20,8),
		balance		decimal(20,8),
		type		char(1),
		tran_no		varchar(16),
		ext		int
	)


	-- Inventory Temp Table
	CREATE TABLE #tempinv
	( 
		location 	varchar(10), 
		part_no 	varchar(30), 
		description 	varchar(45) NULL,
		begin_stock 	float, 
		in_stock 	float, 
		rec_sum 	float,
		ship_sum 	float, 
		sales_sum 	float, 
		xfer_sum_to 	float,
	 	xfer_sum_FROM 	float, 
		iss_sum 	float, 
		mfg_sum 	float, 
		used_sum 	float 
	)

	-- Produced Temp Table
	CREATE TABLE #tempmfg
	( 
		prod_no 	int, 
		prod_ext 	int, 
		location 	varchar(10), 
		part_no 	varchar(30),
	 	qty 		float,
		prod_date 	datetime, 
		status 		char(1) 
	)

	-- Received Temp Table
	CREATE TABLE #temprec
	( 
		po_no		varchar(16),
		location 	varchar(10), 
		part_no 	varchar(30),
		qty 		float, 
		recv_date 	datetime 
	)

	-- Shipment Temp Table
	CREATE TABLE #tempshp
	( 
		order_no 	int, 
		order_ext 	int, 
		location 	varchar(10), 
		part_no 	varchar(30),
		qty 		float, 
		date_shipped 	datetime 
	)

	-- Usage Temp Table
	CREATE TABLE #tempuse
	( 
		prod_no 	int, 
		prod_ext 	int, 
		location 	varchar(10), 
		part_no 	varchar(30),
		qty 		float, 
		prod_date 	datetime 
	)

	-- Transfer Out Temp Table
	CREATE TABLE #tempxfr
	( 
		xfer_no 	int, 
		FROM_loc 	varchar(10), 
		to_loc 		varchar(10), 
		part_no 	varchar(30),
		qty 		float, 
		date_shipped 	datetime 
	)

	-- Transfer In Temp Table
	CREATE TABLE #tempxfr2
	( 
		xfer_no 	int, 
		FROM_loc 	varchar(10), 
		to_loc 		varchar(10), 
		part_no 	varchar(30),
	 	qty 		float, 
		date_shipped 	datetime 
	)

	-- Custom Kit Production Temp Table								
	CREATE TABLE #tempckp
	( 
		order_no 	int, 
		order_ext 	int, 
		location 	varchar(10), 
		part_no 	varchar(30),
		qty 		float, 
		date_shipped 	datetime 
	)							

	CREATE INDEX inv1 ON #tempinv (part_no, location)

	Declare @week_no int 
	select @week_no = 0

	INSERT  #tempinv
	SELECT  location, part_no, SUBSTRING(description,1,45), 0, 
		(in_stock + hold_xfr), 0, 0, 0, 0, 0, 0, 0, 0		
	FROM    inventory ( nolock )
	WHERE   ( status in ( 'K','H','M','P','Q','C' ) ) AND	
          	( part_no like @pn ) AND
	        ( location like @loc )

	IF @first_run = 0
	BEGIN
		update #tempinv
		set in_stock = @balanced_stock_in
	END

	SET rowcount 0

	-- Transfers Out
	-- Include R (shipped), S (shipped received), P (picked), Q (open printed)		
	-- Exclude O (open), N (new), V (void)
	INSERT  #tempxfr
	SELECT  xfers.xfer_no, xfers.from_loc, xfers.to_loc,part_no,
        	( -1 * ( (xfer_list.ordered - xfer_list.shipped) * xfer_list.conv_factor ) ), 
		isnull(date_shipped,isnull(sch_ship_date,getdate()))
	FROM    xfers_all xfers ( nolock ), xfer_list ( nolock )
	WHERE   ( xfers.xfer_no = xfer_list.xfer_no ) 
	AND     ( xfers.status < 'R' ) 
	AND	( xfer_list.part_no like @pn ) 
	AND	( xfers.from_loc like @loc ) 
	AND	( xfer_list.ordered - xfer_list.shipped) <> 0

	-- Transfers In
	-- Include S (shipped received)
	-- Exclude O (open), N (new), P (picked), Q (open printed), R (shipped), V (void)
	INSERT   #tempxfr2
	SELECT   xfers.xfer_no,xfers.from_loc,xfers.to_loc,part_no,
		( case when xfers.status < 'R' then xfer_list.ordered
			else xfer_list.shipped end * xfer_list.conv_factor ),
		isnull( date_recvd, isnull(req_ship_date,getdate()))
	FROM    xfers_all xfers ( nolock ), xfer_list ( nolock )
	WHERE   ( xfers.xfer_no = xfer_list.xfer_no ) 
	AND     ( xfers.status < 'S' ) 
	AND   	( xfer_list.part_no like @pn ) 
	AND     ( xfers.to_loc like @loc ) 
	AND	( case when xfers.status < 'R' then xfer_list.ordered
			else xfer_list.shipped end ) <> 0

	-- Produced
	-- Include R (complete:qc hold) AND S (complete), P (open:picked), Q (open:printed)
	-- Exclude H (hold:edit job), N (open:new), V (void)
	INSERT  #tempmfg
	SELECT  p.prod_no, p.prod_ext, x.location, x.part_no, 
		case when prod_type = 'R' then ( x.plan_qty - x.used_qty ) else plan_qty - scrap_pcs end,
	           isnull(p.prod_date,getdate()), p.status
	FROM    produce_all p ( nolock ), prod_list x ( nolock )
	WHERE   ( p.prod_no = x.prod_no ) 
	AND     ( p.prod_ext = x.prod_ext ) 
	AND     ( x.direction = 1 ) 
	AND     ( x.part_no like @pn ) 
	AND     ( x.location like @loc ) 
	AND     ( p.status < 'R') 
	AND 	case when prod_type = 'R' then ( x.plan_qty - x.used_qty ) 
			else plan_qty - scrap_pcs end <> 0

	-- Used
	-- Include P (open:picked), Q (open:printed), R (complete:qc hold), S (complete)
	-- Exclude H (hold:edit job), N (open:new), V (void)
	-- Restrict to part type M (manufactured), P (purchase)
	-- Restrict to non-cell items 'constrain = 'N''
	INSERT #tempuse
	SELECT  x.prod_no, x.prod_ext, x.location, x.part_no, ( -1 * ( (x.plan_qty - x.used_qty) * x.conv_factor ) ),
		isnull(p.prod_date,getdate())
	FROM    produce_all p ( nolock ), prod_list x ( nolock )
	WHERE   ( p.prod_no = x.prod_no ) 
	AND     ( p.prod_ext = x.prod_ext ) 
	AND     ( x.direction = -1 ) 
	AND     ( x.part_no like @pn ) 
	AND     ( x.location like @loc ) 
	AND	( x.constrain = 'N' ) 
	AND	( p.status < 'R') 
	AND     ( x.part_type in ( 'M', 'P' ) ) 
	AND 		x.plan_qty - x.used_qty <> 0

	-- Used
	-- Include P (open:picked),Q (open:printed / qc), R (ready/posting), S (shipped), T (shipped:transferred)
	-- Exclude A (user defined hold), B (credit/price hold), C (credit hold)
	--		   E (EDI), H (price hold), M (blanket order), N (new/open)
	--         V (void), X (voided/cancelled quote)
	-- Restrict to part type P (inventory item)

	/*START: 07/21/2010, AMENDEZ, 68668-FOC-001 Custom Frame Build*/
	/*INSERT #tempshp												
	SELECT  x.order_no, x.order_ext, x.location, x.part_no, 
		( -1 * (((x.ordered - x.cr_ordered) - ( x.shipped - x.cr_shipped )) * x.conv_factor * qty_per) ),	
		isnull( p.date_shipped, isnull(sch_ship_date,getdate()) )
	FROM    orders_all p ( nolock ), ord_list_kit x ( nolock )
	WHERE   ( p.order_no = x.order_no ) 
	AND     ( p.ext = x.order_ext ) 
	AND     ( x.part_no like @pn ) 
	AND     ( x.location like @loc ) 
	AND     ( x.status < 'S' ) 
        and     ( p.status not in ('L','M'))								-- mls 10/13/05 SCR 35519
	AND	( x.part_type = 'P' ) 
	AND 	((x.ordered - x.cr_ordered) - ( x.shipped - x.cr_shipped ))  <> 0*/
	/*END: 07/21/2010, AMENDEZ, 68668-FOC-001 Custom Frame Build*/

	-- Received
	INSERT  #temprec
	SELECT  po_no, location,
	            CASE WHEN ( part_type = 'M' ) THEN '*PO MISC* ' + part_no
        	         ELSE part_no
            		END,( (quantity- received) * conv_factor ), due_date
	FROM    releases ( nolock )
	WHERE   ( part_no like @pn ) 
	AND	( location like @loc )
	AND 	status = 'O'
	AND 	(quantity - received) > 0


	-- The next SELECT FROM orders will pick up all orders that have
	-- caused the inv_sales.sales_qty_mtd to be changed except status 'T'.
	-- Pick up items FROM orders/ord_list
	-- Include P (open:picked), Q (open:printed), R (ready:posting), S (shipped)
	-- Exclude A (user defined hold), B (credit/price hold), C (credit hold),
	--         E (EDI), H (price hold), M (blanket order), N (new/open),
	--         T (shipped:transferred), V (void), X (voided/cancelled quote)
	INSERT #tempshp
	SELECT l.order_no, l.order_ext,  l.location, l.part_no,
		  ( -1 *(( l.ordered - l.cr_ordered) - (l.shipped - l.cr_shipped)) * l.conv_factor ),
			isnull( o.date_shipped, isnull(sch_ship_date,getdate()) )
	FROM ord_list l (nolock), orders_all o (nolock)
	WHERE ( l.order_no = o.order_no ) 
	AND   ( l.order_ext = o.ext ) 
	AND   ( o.status <'S' ) 
        and   ( o.status not in ('L','M'))								-- mls 10/13/05 SCR 35519
	AND   ( l.part_type in ('P','C') ) 
	AND   ( l.part_no like @pn ) 
	AND   ( l.location like @loc )
	AND   (( l.ordered - l.cr_ordered) - (l.shipped - l.cr_shipped)) <> 0

	--  Custom kits/ balancing entry to show production on the sales order	
	INSERT #tempckp
	SELECT l.order_no,l.order_ext, l.location,  l.part_no,			
		(-1 * (( l.ordered - l.cr_ordered) - (l.shipped - l.cr_shipped)) * l.conv_factor ),
		isnull( o.date_shipped, isnull(sch_ship_date,getdate()) )
	FROM ord_list l (nolock), orders_all o (nolock)
	WHERE ( l.order_no = o.order_no ) 
	AND   ( l.order_ext = o.ext ) 
	AND   ( o.status < 'S') 
        and   ( o.status not in ('L','M'))								-- mls 10/13/05 SCR 35519
	AND   ( l.part_type = 'C' ) 
	AND   ( l.part_no like @pn ) 
	AND   ( l.location like @loc )									-- mls 8/10/00 SCR 23833 end
	AND   (( l.ordered - l.cr_ordered) - (l.shipped - l.cr_shipped)) <> 0

	IF isnull(@edate,'1/1/2020') > getdate()
	BEGIN
		



		IF @first_run = 2
		BEGIN

		    -- Begin SCR 21366
			-- receipts
		       UPDATE #tempinv
			 SET	  in_stock = in_stock - isnull(( SELECT sum(qty)
							   FROM   #temprec
							   WHERE  #tempinv.part_no = #temprec.part_no
							   AND    #tempinv.location = #temprec.location
    							   AND    #temprec.recv_date > @edate),0)
		 	-- shipments
			 UPDATE #tempinv
			 SET	  in_stock = in_stock - isnull(( SELECT sum(qty)
							   FROM   #tempshp
							   WHERE  #tempinv.part_no = #tempshp.part_no
							   AND    #tempinv.location = #tempshp.location
    							   AND    #tempshp.date_shipped > @edate),0)
		 	-- transfers out
			 UPDATE #tempinv
			 SET	  in_stock = in_stock - isnull(( SELECT sum(qty)
							   FROM   #tempxfr
							   WHERE  #tempinv.part_no = #tempxfr.part_no
							   AND    #tempinv.location = #tempxfr.FROM_loc
    							   AND    #tempxfr.date_shipped > @edate),0)
			 -- transfers in
			 UPDATE #tempinv
			 SET	  in_stock = in_stock - isnull(( SELECT sum(qty)
							   FROM   #tempxfr2
							   WHERE  #tempinv.part_no = #tempxfr2.part_no
							   AND    #tempinv.location = #tempxfr2.to_loc
    							   AND    #tempxfr2.date_shipped > @edate),0)
			 -- production
			 UPDATE #tempinv
			 SET	  in_stock = in_stock - isnull(( SELECT sum(qty)
							   FROM   #tempmfg
							   WHERE  #tempinv.part_no = #tempmfg.part_no
							   AND    #tempinv.location = #tempmfg.location
    							   AND    #tempmfg.prod_date > @edate),0)
			 -- usage
			 UPDATE #tempinv
			 SET	  in_stock = in_stock - isnull(( SELECT sum(qty)
							   FROM   #tempuse
							   WHERE  #tempinv.part_no = #tempuse.part_no
							   AND    #tempinv.location = #tempuse.location
    							   AND    #tempuse.prod_date > @edate),0)

			 -- custom kit production									
			UPDATE #tempinv
	 		SET	  in_stock = in_stock - isnull(( SELECT sum(qty)
							   FROM   #tempckp
							   WHERE  #tempinv.part_no = #tempckp.part_no
							   AND    #tempinv.location = #tempckp.location
    							   AND    #tempckp.date_shipped > @edate),0)	
	
	END
	    -- Delete rows beyond ending date
		DELETE FROM #tempmfg  WHERE ( prod_date    > @edate ) OR ( prod_date      < @bdate )
		DELETE FROM #temprec  WHERE ( recv_date    > @edate ) OR ( recv_date      < @bdate )
		DELETE FROM #tempshp  WHERE ( date_shipped > @edate ) OR ( date_shipped   < @bdate )
		DELETE FROM #tempuse  WHERE ( prod_date    > @edate ) OR ( prod_date   	  < @bdate )
		DELETE FROM #tempxfr  WHERE ( date_shipped > @edate ) OR ( date_shipped   < @bdate )
		DELETE FROM #tempxfr2 WHERE ( date_shipped > @edate ) OR ( date_shipped   < @bdate )
		DELETE FROM #tempckp  WHERE ( date_shipped > @edate ) OR ( date_shipped   < @bdate )	-- mls 8/10/00 SCR 23883
	END

	-- UPDATE sum columns
	UPDATE  #tempinv
	SET     iss_sum = 0,
        	mfg_sum = isnull( ( SELECT sum( qty )
	                            FROM   #tempmfg
        	                    WHERE  ( a.part_no = #tempmfg.part_no ) AND
                	                   ( a.location = #tempmfg.location ) ), 0 ),
	        rec_sum = isnull( ( SELECT sum( qty )
	                            FROM   #temprec
                	            WHERE  ( a.part_no = #temprec.part_no ) AND
        	                           ( a.location = #temprec.location ) ), 0 ),
        	ship_sum = isnull( ( SELECT sum( qty )
	                             FROM   #tempshp
        	                     WHERE ( a.part_no=#tempshp.part_no ) AND
                	                   ( a.location=#tempshp.location ) ), 0 ) +
			   isnull( ( SELECT sum( qty )								-- mls 8/10/00 SCR 23883 start
                        	     FROM   #tempckp
                	             WHERE ( a.part_no=#tempckp.part_no ) AND
        	                           ( a.location=#tempckp.location ) ), 0 ),				-- mls 8/10/00 SCR 23883 end
        	used_sum = isnull( ( SELECT sum( qty )
                	             FROM   #tempuse
                        	     WHERE  ( a.part_no = #tempuse.part_no ) AND
                                	    ( a.location = #tempuse.location ) AND
		                            ( #tempuse.prod_date >= @bdate ) ), 0 ),
        	xfer_sum_FROM = isnull( ( SELECT sum( qty )
                	                  FROM   #tempxfr
                        	          WHERE ( a.part_no = #tempxfr.part_no ) AND
	                                ( a.location = #tempxfr.FROM_loc ) ), 0 ),
        	xfer_sum_to = isnull( ( SELECT sum( qty )
                                	FROM   #tempxfr2
	 	                        WHERE  ( a.part_no = #tempxfr2.part_no ) AND
                	                       ( a.location = #tempxfr2.to_loc ) ), 0 )
	FROM #tempinv a

	SELECT  @in_stock = in_stock,
--		@stock_in = ISNULL(in_stock + xfer_sum_to + mfg_sum + rec_sum, 0.0),
		@stock_in = ISNULL(xfer_sum_to + mfg_sum + rec_sum, 0.0),
		@stock_out = ISNULL(ship_sum + used_sum + xfer_sum_FROM, 0.0),
		@balance = ISNULL(@in_stock + @stock_in + @stock_out, 0)
	FROM #tempinv

 -- Transfer Out
	insert #proyection
	select @week_no, date_shipped, 0, 0, qty * -1, @balance, 'Y',xfer_no,0
	from #tempxfr 
	where ( FROM_loc like @loc ) and ( date_shipped <= @edate )

 -- Transfer In
	insert #proyection
	select @week_no, date_shipped, 0, qty, 0, @balance, 'X',xfer_no,0
	from #tempxfr2
	where ( to_loc like @loc ) and ( date_shipped <= @edate )

 -- Produced
	insert #proyection
	select @week_no, prod_date, 0, qty, 0, @balance, 'M',prod_no,prod_ext
	from #tempmfg
	where ( prod_date <= @edate )

 -- Recieved
	insert #proyection
	select @week_no, recv_date, 0,qty, 0, @balance, 'R',po_no,0
	from #temprec
	where ( recv_date <= @edate )

 -- Ship
	insert #proyection
	select @week_no, date_shipped, 0, 0, qty * -1, @balance, 'S',order_no,order_ext
	from #tempshp
	where ( date_shipped <= @edate ) and ( qty < 0 )

 -- Ship (credit)
	insert #proyection
	select @week_no, date_shipped, 0, qty, 0, @balance, 'T',order_no, order_ext
	from #tempshp
	where ( date_shipped <= @edate ) and ( qty > 0 )

 -- Ship (custom kit prod balancing entry)							-- mls 8/10/00 SCR 23883 start
	insert #proyection
	select @week_no, date_shipped, 0, qty, 0, @balance, 'C',order_no,order_ext
	from #tempckp
	where ( date_shipped <= @edate )							-- mls 8/10/00 SCR 23883 end

 -- Used
	insert #proyection
	select @week_no, prod_date, 0, 0, qty * -1, @balance, 'U',prod_no,prod_ext
	from #tempuse
	where ( prod_date <= @edate )

	select *
        from #proyection
        order by end_date, type, tran_no, ext

	DROP TABLE #tempinv
	DROP TABLE #tempmfg
	DROP TABLE #temprec
	DROP TABLE #tempshp
	DROP TABLE #tempuse
	DROP TABLE #tempxfr
	DROP TABLE #tempxfr2
	DROP TABLE #tempckp
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[fs_weekly_activity_sp] TO [public]
GO
