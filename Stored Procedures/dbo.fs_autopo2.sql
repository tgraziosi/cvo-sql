SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[fs_autopo2] @batch_id varchar(20), @who varchar(30)  AS
BEGIN


declare @no int, @x int, @vend varchar(12), @err int						-- mls 4/14/00 SCR 22710
declare @pn varchar(30), @po varchar(16), @uom char(2)
declare @conv real
declare	@loc	varchar(10)									-- skk 02/13/01 F6.1.4.1
declare @max_row int										-- skk 03/19/01 SCR 26340
declare @po_line int										-- mls 5/15/01 SCR 6603
declare @aprv_po_flag int, @approval_status char(1)

select @aprv_po_flag = aprv_po_flag from apco (nolock)
if isnull(@aprv_po_flag,2) not in (1,0)
  set @aprv_po_flag = 0

create table #temppn (vendorno varchar(12), partno varchar(30), pono varchar(10),		-- mls 4/14/00 SCR 22710
						location varchar(10) )											-- skk 02/13/01 F6.1.4.1
create table #temprpt 	(vendorno varchar(12), pono varchar(10), partno varchar(30), 		-- mls 4/14/00 SCR 22710
			rdate datetime, qty money, uom char(2) )

insert #temppn select distinct vendor_no, part_no,
						blanket_po_no, location											-- skk 02/13/01 F6.1.4.1
	from resource_demand_group															-- skk 02/13/01 F6.1.4.1
	where buy_flag='Y' and
			batch_id	= @batch_id and													-- skk 02/13/01 F6.1.4.1
			blanket_order_flag	= 'Y' and												-- skk 02/13/01 F6.1.4.1
			vendor_no			is NOT NULL												-- skk 02/13/01 F6.1.4.1


delete #temppn where not exists ( select * from adm_vend_all where vendor_code=#temppn.vendorno)

-- skk 02/13/01 F6.1.4.1 start
--******************************************************************************
--* The blanket order number to update is now referenced in resource_demand_group.
--* Make sure that it is an active blanket order for the demand location.
--******************************************************************************
DELETE	#temppn
WHERE NOT EXISTS(	SELECT * FROM purchase p, pur_list l
					WHERE	p.po_no		= l.po_no and
							p.po_no		= #temppn.pono and
							l.location	= #temppn.location and
							l.part_no	= #temppn.partno and
							p.vendor_no	= #temppn.vendorno and
							p.status	= 'O' and
							p.blanket	= 'Y' )
-- skk 02/13/01 F6.1.4.1 end

select @x=(select count(*) from #temppn)				-- skk 02/13/01 F6.1.4.1
while @x > 0
Begin

	set rowcount 1
	select @vend=vendorno, @pn=partno,
			@po = pono, @loc = location						-- skk 02/13/01 F6.1.4.1
	from #temppn
	set rowcount 0

	select @no=p.po_key,								-- skk 02/13/01 F6.1.4.1
       	@conv=pur_list.conv_factor, @uom=pur_list.unit_measure ,
        @po_line = pur_list.line,					-- mls 5/15/01 SCR 6603
		@approval_status = p.approval_status
	from purchase_all p, pur_list
	where p.po_no=pur_list.po_no
		 and p.po_no = @po							-- skk 02/13/01 F6.1.4.1

	select @max_row = IsNull((SELECT MAX(row_id) from releases), 0)				-- skk 03/19/01 SCR 26340

	BEGIN TRAN
	insert releases (po_no, part_no, location, part_type,
				release_date, quantity, received, status,
				confirm_date, confirmed, lb_tracking, conv_factor, 
				prev_qty,po_key, due_date, po_line) 	-- mls 5/15/01 SCR 6603
	select			-- skk 02/13/01 add due_date
	@po               , 
	@pn               , 
	@loc              , 
	'P'               , 
	demand_date       , 
	Ceiling(sum(qty)/@conv)          , 
	0                 , 
	'O'               , 
	demand_date       , 
	'N'               , 
	' '     	  , 		-- rev 6
	@conv             ,
	0                 ,
	@no               ,
	demand_date,
	@po_line							-- mls 5/15/01 SCR 6603
													-- skk 02/13/01 F6.1.4.1
	from resource_demand_group									-- skk 02/13/01 F6.1.4.1
	where location=@loc and @vend=vendor_no and buy_flag='Y' and part_no=@pn and
			batch_id = @batch_id and blanket_po_no = @po and 	-- skk 02/13/01 F6.1.4.1
			blanket_order_flag = 'Y'							-- skk 02/13/01 F6.1.4.1
	group by resource_demand_group.demand_date
	order by resource_demand_group.demand_date
	
	update releases set lb_tracking=i.lb_tracking
		from  inventory i
		where releases.po_no=@po and
		releases.part_no=i.part_no and
	    	releases.location=i.location	and 
		releases.row_id > @max_row and					-- skk 03/19/01 SCR 26340
	    @loc=releases.location
	    and releases.po_line = @po_line					-- mls 5/15/01 SCR 6603
	

	
	
	update 	releases
	set 	release_date = (release_date - i.dock_to_stock- i.lead_time ),	-- due_date minus lead_time
		due_date = (due_date - i.dock_to_stock),			-- minus dock_to_stock
		confirm_date = (due_date - i.dock_to_stock)			-- same as due_date
	from	inv_list i
	where	releases.po_no=@po and
		releases.part_no=i.part_no and
		releases.location=i.location and 
		releases.row_id > @max_row and					-- skk 03/19/01 SCR 26340
		@loc=releases.location
	        and releases.po_line = @po_line					-- mls 5/15/01 SCR 6603
	
	

	insert #temprpt select
	@vend             ,
	@po               , 
	@pn               , 
	demand_date       , 
	Ceiling(sum(qty)/@conv)          , 
	@uom
	from resource_demand_group									-- skk 02/13/01 F6.1.4.1
	where location=@loc and @vend=vendor_no and buy_flag='Y' and part_no=@pn and
			batch_id = @batch_id and blanket_po_no = @po and 	-- skk 02/13/01 F6.1.4.1
			blanket_order_flag = 'Y'							-- skk 02/13/01 F6.1.4.1
	group by demand_date
	order by demand_date

	delete resource_demand_group								-- skk 02/13/01 F6.1.4.1
	where location=@loc and vendor_no=@vend and part_no=@pn and buy_flag='Y' and
			batch_id = @batch_id and blanket_po_no = @po and 	-- skk 02/13/01 F6.1.4.1
			blanket_order_flag = 'Y'							-- skk 02/13/01 F6.1.4.1	

	-- skk 02/13/01 F6.1.4.1 start
	DELETE #temppn
	WHERE	vendorno	= @vend and
			partno		= @pn and
			pono		= @po and
			location	= @loc
	-- skk 02/13/01 F6.1.4.1 end
	
	
	exec fs_calculate_potax_wrap @po, 1
	
	COMMIT TRAN
	select @x=(select count(*) from #temppn)					-- skk 02/13/01 F6.1.4.1
End -- while @x > 0

select vendorno, v.vendor_name, pono, partno, i.description, rdate, qty, t.uom
from #temprpt t, adm_vend_all v, inv_master i
where t.vendorno=v.vendor_code and t.partno=i.part_no	
END
GO
GRANT EXECUTE ON  [dbo].[fs_autopo2] TO [public]
GO
