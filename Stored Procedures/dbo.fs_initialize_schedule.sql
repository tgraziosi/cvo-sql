SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




-- Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_initialize_schedule]
	(
	@sched_id	INT
	)
AS
BEGIN
-- Local variables
DECLARE	@rowcount		INT,
	@sched_item_id		INT,
	@order_usage_mode	CHAR(1),
	@location		VARCHAR(10),
	@part_no		VARCHAR(30),
	@done_datetime		DATETIME,
	@uom_qty		DECIMAL(20,8),
	@uom			CHAR(2),
	@order_priority_id	INT,
	@part_type		char(1),						-- mls 6/21/99 SCR 19809
	@vendor_key		VARCHAR(12),
	@po_no			VARCHAR(16),						-- mls 2/28/03 SCR 30781
	@release_id		INT,
	@xfer_no		INT,
	@xfer_line		INT,
	@lead_time		INT,
	@dock_to_stock		INT,
	@lead_datetime 		DATETIME,
	@purchase_lead_flag	CHAR(1)
DECLARE @po_line 		int							-- mls 5/10/01 #6
declare @include_orders         int,						-- mls 4/26/02 SCR 28832 start
        @include_xfer_demand    int,							
        @include_xfer_supply    int						-- mls 4/26/02 SCR 28832 end

-- If they did not set the option, retrieve the existing option
SELECT	@include_orders = case when SM.order_usage_mode = 'U' then 1 else 0 end,	-- mls 4/26/02 SCR 28832 start
@include_xfer_demand = case when SM.transfer_demand_mode = 'U' then 1 else 0 end,
@include_xfer_supply = case when SM.transfer_supply_mode = 'U' then 1 else 0 end,	-- mls 4/26/02 SCR 28832 end
  @purchase_lead_flag = SM.purchase_lead_flag
FROM	dbo.sched_model SM
WHERE	SM.sched_id=@sched_id
    
-- Did model exists?
IF @@rowcount <> 1
	BEGIN
	RaisError 69010 'Model to initialize does not exist.'
	RETURN
	END

-- Clear all previous data
EXEC adm_set_sched_item 'DA',@sched_id  
EXEC adm_set_sched_process 'DA',NULL,@sched_id  
EXEC adm_set_sched_order 'DA',@sched_id  

DELETE	dbo.sched_resource	WHERE	sched_id = @sched_id
DELETE  dbo.sched_transfer      WHERE   sched_id = @sched_id			-- mls 4/26/02 SCR 28832

-- Look up default order priority
SELECT	@order_priority_id=OP.order_priority_id
FROM	dbo.order_priority OP
WHERE	OP.usage_flag = 'D'

-- ================================================
-- Load resources
-- ================================================

-- Copy the resources from standard resources
INSERT	dbo.sched_resource
	(
	sched_id,
	location,
	resource_type_id,
	resource_id,
	source_flag
	)
SELECT	@sched_id,
	R.location,
	R.resource_type_id,
	R.resource_id,
	'R'
FROM	dbo.sched_location SL,
	dbo.resource R
WHERE	SL.sched_id = @sched_id
AND	R.location = SL.location

-- ================================================
-- Load orders (orders, ord_list)
-- ================================================

-- If they don't want orders, don't copy the orders
-- IF @order_usage_mode = 'U'
IF @include_orders = 1									-- mls 4/26/02 SCR 28832
	BEGIN
	-- Load customer orders
	INSERT	dbo.sched_order
		(
		sched_id,
		location,
		done_datetime,
		part_no,
		uom_qty,
		uom,
		order_priority_id,
		source_flag,
		order_no,
		order_ext,
		order_line,
		action_flag	-- debug pyh

		)
	SELECT	@sched_id,					-- sched_id
		OL.location,					-- location
		IsNull(O.sch_ship_date,O.req_ship_date),	-- done_datetime
		OL.part_no,					-- part_no
		(OL.ordered - OL.shipped) * OL.conv_factor,	-- uom_qty
		IM.uom,						-- uom
		@order_priority_id,				-- order_priority_id
		'C',						-- source_flag
		OL.order_no,					-- order_no
		OL.order_ext,					-- order_ext
		OL.line_no,					-- order_line
		'?'						-- action flag	-- rev 1

	FROM	dbo.sched_location SL,
		dbo.orders_all O,
		dbo.ord_list OL,
		dbo.inv_master IM
	WHERE	SL.sched_id = @sched_id
	AND    (OL.status in ('N','P','Q')							-- mls 4/5/01 SCR 26567
	 OR     (OL.status in ('R','S') and O.back_ord_flag = '0' and OL.back_ord_flag = '0'))	-- mls 4/5/01 SCR 26567
	AND	O.type = 'I'
	AND	OL.location = SL.location
	AND	OL.order_no = O.order_no
	AND	OL.order_ext = O.ext
	AND	OL.ordered > OL.shipped
	AND	OL.part_type = 'P'
	AND	IM.part_no = OL.part_no

	-- Load customer jobs
	INSERT	dbo.sched_order
		(
		sched_id,
		location,
		done_datetime,
		uom_qty,
		uom,
		order_priority_id,
		source_flag,
		order_no,
		order_ext,
		order_line,
		prod_no,
		prod_ext,
		action_flag
		)
	SELECT	@sched_id,					-- sched_id
		OL.location,					-- location
		IsNull(O.sch_ship_date,O.req_ship_date),	-- done_datetime
		(OL.ordered - OL.shipped) * OL.conv_factor,	-- uom_qty
		OL.uom,						-- uom
		@order_priority_id,				-- order_priority_id
		'J',						-- source_flag
		OL.order_no,					-- order_no
		OL.order_ext,					-- order_ext
		OL.line_no,					-- order_line
		CONVERT(int,OL.part_no),			-- prod_no
		0,						-- prod_ext
		'?'						-- action_flag		-- rev 1

	FROM	dbo.sched_location SL,
		dbo.orders_all O,
		dbo.ord_list OL
	WHERE	SL.sched_id = @sched_id
	AND    (OL.status in ('N','P','Q')							-- mls 4/5/01 SCR 26567
	 OR     (OL.status in ('R','S') and O.back_ord_flag = '0' and OL.back_ord_flag = '0'))	-- mls 4/5/01 SCR 26567
	AND	O.type = 'I'
	AND	OL.location = SL.location
	AND	OL.order_no = O.order_no
	AND	OL.order_ext = O.ext
	AND	OL.ordered > OL.shipped
	AND	OL.part_type = 'J'

	-- Load customer configurable kits
	INSERT	dbo.sched_order
		(
		sched_id,
		location,
		done_datetime,
		part_no,
		uom_qty,
		uom,
		order_priority_id,
		source_flag,
		order_no,
		order_ext,
		order_line,
		order_line_kit,
		action_flag
		)
	SELECT	@sched_id,					-- sched_id
		OLK.location,					-- location
		IsNull(O.sch_ship_date,O.req_ship_date),	-- done_datetime
		OLK.part_no,					-- part_no
						-- uom_qty
		(OLK.ordered - OLK.shipped) * OLK.conv_factor * OLK.qty_per,

		IM.uom,						-- uom
		@order_priority_id,				-- order_priority_id
		'C',						-- source_flag
		OLK.order_no,					-- order_no
		OLK.order_ext,					-- order_ext
		OLK.line_no,					-- order_line
		OLK.row_id,					-- order_line_kit
		'?'						-- action_flag		-- rev 1
	FROM	dbo.sched_location SL,
		dbo.orders_all O,
		dbo.ord_list_kit OLK,
		dbo.ord_list OL,							
		dbo.inv_master IM
	WHERE	SL.sched_id = @sched_id
	AND    (OL.status in ('N','P','Q')							-- mls 4/5/01 SCR 26567
	 OR     (OL.status in ('R','S') and O.back_ord_flag = '0' and OL.back_ord_flag = '0'))	-- mls 4/5/01 SCR 26567
	AND	O.type = 'I'
	AND	OLK.location = SL.location
	AND	OLK.order_no = O.order_no
	AND	OLK.order_ext = O.ext
	and 	OL.order_no = O.order_no							-- mls 4/5/01 SCR 26567 start
	and 	OL.order_ext = O.ext
	and 	OL.line_no = OLK.line_no							-- mls 4/5/01 SCR 26567 end
	AND	OLK.ordered > OLK.shipped
	AND	OLK.part_type = 'P'
	AND	IM.part_no = OLK.part_no

	END

-- ================================================
-- Load orders (xfers, xfer_list)
-- ================================================

-- Load tranfer orders
IF @include_xfer_demand = 1							-- mls 4/26/02 SCR 28832
begin
INSERT	dbo.sched_order
	(
	sched_id,
	location,
	done_datetime,
	part_no,
	uom_qty,
	uom,
	order_priority_id,
	source_flag,
	order_no,
	order_line,
	action_flag
	)
SELECT	@sched_id,		-- sched_id
	X.from_loc,		-- location
	X.sch_ship_date,	-- done_datetime
	XL.part_no,		-- part_no
	XL.ordered,		-- uom_qty
	XL.uom,			-- uom
	@order_priority_id,	-- order_priority_id
	'T',			-- source_flag
	XL.xfer_no,		-- order_no
	XL.line_no,		-- order_line
	'?'			-- action_flag		-- rev 1

FROM	dbo.xfers_all X,
	dbo.xfer_list XL
WHERE	X.status IN ('O','N','P','Q')
AND	XL.xfer_no = X.xfer_no
AND	X.from_loc IN (SELECT SL1.location FROM dbo.sched_location SL1 WHERE SL1.sched_id = @sched_id)
AND	X.to_loc NOT IN (SELECT SL2.location FROM dbo.sched_location SL2 WHERE SL2.sched_id = @sched_id)
end
-- =================================================
-- Load processes
-- =================================================

EXECUTE fs_build_sched_process @sched_id=@sched_id

-- =================================================
-- Load time-phase inventory
-- =================================================

-- Load the initial inventory

INSERT	dbo.sched_item
	(
	sched_id,
	location,
	part_no,
	done_datetime,
	uom_qty,
	uom,
	source_flag
	)
SELECT	SL.sched_id,	-- sched_id
	I.location,	-- location
	I.part_no,	-- part_no
	getdate(),	-- done_datetime
	I.in_stock, 						-- mls 9/27/02
	I.uom,		-- uom
	'I'		-- source_flag
FROM	dbo.sched_location SL,
	dbo.inventory I
WHERE	SL.sched_id = @sched_id
AND	I.location = SL.location

AND	I.status <= 'Q'
AND	I.void = 'N'

-- =================================================
-- Load time-phase inventory plus purchases
-- =================================================

-- Get first release for this scenario
SELECT	@release_id = MIN(PR.row_id)
FROM	dbo.sched_location SL,
	dbo.releases PR
WHERE	SL.sched_id = @sched_id
AND	PR.location = SL.location
AND	PR.part_type IN ('P','M')
AND	(	(	PR.status = 'O'
		AND	PR.quantity > PR.received )
	OR	EXISTS (SELECT	*
			FROM	dbo.receipts_all R2
			WHERE	R2.po_no = PR.po_no
			AND	R2.part_no = PR.part_no
			AND	R2.po_line = case when isnull(PR.po_line,0)=0 then R2.po_line else PR.po_line end -- mls 5/10/01 #6
			AND	R2.release_date = PR.release_date
			AND	R2.qc_flag = 'Y'))

-- While there are more releases to process
WHILE @release_id IS NOT NULL
	BEGIN
	-- Get the rest of the information
	SELECT	@location = PR.location,
		@part_no = PR.part_no,
		@part_type = PR.part_type,						-- mls 6/21/99 SCR 19809
		@done_datetime = CASE PR.confirmed
					WHEN 'Y' THEN PR.confirm_date
					ELSE PR.due_date	-- rev 4
					END,
		@uom_qty = ( PR.quantity
				- CASE	WHEN PR.received > PR.quantity
					THEN PR.quantity
					ELSE PR.received END
				+ IsNull((	SELECT	SUM(R1.quantity)
						FROM	dbo.receipts_all R1
						WHERE	R1.po_no = PR.po_no
						AND	R1.part_no = PR.part_no
						AND	R1.po_line = case when isnull(PR.po_line,0)=0 
							then R1.po_line else PR.po_line end -- mls 5/10/01 #6
						AND	R1.release_date = PR.release_date
						AND	R1.qc_flag = 'Y'),0.0)) * PR.conv_factor,
		@po_no = PR.po_no,
		@po_line = PR.po_line							-- mls 5/10/01 #6
	FROM	dbo.sched_location SL,
		dbo.releases PR
	WHERE	SL.sched_id = @sched_id
	AND	PR.location = SL.location
	AND	PR.part_type IN ('P','M')
	AND	PR.row_id = @release_id

	-- What was the unit of measure
	
	select @uom = NULL								-- mls 6/21/99 SCR 19809
	if @part_type = 'P'								-- mls 6/21/99 SCR 19809
	begin										-- mls 6/21/99 SCR 19809
	  SELECT	@uom = IM.uom
	  FROM	dbo.inv_master IM
	  WHERE	IM.part_no = @part_no
	end										-- mls 6/21/99 SCR 19809
	if @uom is NULL									-- mls 6/21/99 SCR 19809
	begin										-- mls 6/21/99 SCR 19809
	  SELECT @uom = isnull((select PL.unit_measure					-- mls 6/21/99 SCR 19809
	  FROM	dbo.pur_list PL								-- mls 6/21/99 SCR 19809
	  WHERE	PL.po_no = @po_no and 
		PL.line = case when isnull(@po_line,0)=0 then PL.line else @po_line end -- mls 5/10/01 #6
		and PL.part_no = @part_no),'EA')						-- mls 6/21/99 SCR 19809
	end										-- mls 6/21/99 SCR 19809

	-- Who was the vendor
	SELECT	@vendor_key = P.vendor_no
	FROM	dbo.purchase_all P
	WHERE	P.po_no = @po_no

	-- Compute the lead_datetime to so that when confirmed receipt dates change,
	-- we will have a way to know that something changed.  If ignoring vendor lead times
	-- or undefined lead_time or dock_to_stock days, 
	-- set the lead datetime = the completion time (assume we can get it with zero lead time)

	-- Rev 4 Add dock_to_stock to confirm/due date to get done_datetime; Subtract dock_to_stock
	-- and lead_time to get lead_datetime
	SELECT @lead_datetime = @done_datetime

	IF (@purchase_lead_flag = 'S')
	BEGIN
		SELECT @lead_time = I.lead_time, @dock_to_stock = I.dock_to_stock
		FROM dbo.inv_list I					-- mls 9/27/02
		WHERE I.part_no = @part_no AND
			I.location = @location
		
		Select @lead_time = IsNull(@lead_time,0), @dock_to_stock = IsNull(@dock_to_stock,0)
 		BEGIN
			Select @done_datetime = DateAdd (d, @dock_to_stock, @done_datetime)
			SELECT @lead_datetime = DateAdd (d,(-1 * (@lead_time + @dock_to_stock)),@done_datetime)
		END
		
	END
	
	-- Schedule the inventory arrival of the materials
	INSERT	dbo.sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
	VALUES	(@sched_id,@location,@part_no,@done_datetime,@uom_qty,@uom,'O')

	-- Grab the scheduled item id
	SELECT	@sched_item_id=@@identity

	-- Save the important vendor information
	IF EXISTS(SELECT * FROM dbo.adm_vend_all A WHERE A.vendor_code = @vendor_key)
		INSERT	dbo.sched_purchase(sched_item_id,lead_datetime,vendor_key,po_no,release_id)
		VALUES	(@sched_item_id,@lead_datetime,@vendor_key,@po_no,@release_id)

	-- Get next release for this scenario
	SELECT	@release_id = MIN(PR.row_id)
	FROM	dbo.sched_location SL,
		dbo.releases PR
	WHERE	SL.sched_id = @sched_id
	AND	PR.location = SL.location
	AND	PR.part_type IN ('P','M')
	AND	(	(	PR.status = 'O'
			AND	PR.quantity > PR.received )
		OR	EXISTS (SELECT	*
				FROM	dbo.receipts_all R2
				WHERE	R2.po_no = PR.po_no
				AND	R2.part_no = PR.part_no
				AND	R2.po_line = case when isnull(PR.po_line,0)=0 
					then R2.po_line else PR.po_line end -- mls 5/10/01 #6
				AND	R2.release_date = PR.release_date
				AND	R2.qc_flag = 'Y'))
	AND	PR.row_id > @release_id
	END

-- ================================================
-- Load purchases (xfers, xfer_list)
-- ================================================

IF @include_xfer_supply = 1							-- mls 4/26/02 SCR 28832
begin
DECLARE c_purchase CURSOR FOR
SELECT	X.to_loc,
	XL.part_no,
	X.req_ship_date,
	XL.ordered,
	XL.uom,
	XL.xfer_no,
	XL.line_no
FROM	dbo.xfers_all X,
	dbo.xfer_list XL
WHERE	X.status IN ('O','N','P','Q')
AND	XL.xfer_no = X.xfer_no
AND	X.to_loc IN (SELECT SL2.location FROM dbo.sched_location SL2 WHERE SL2.sched_id = @sched_id)
AND	X.from_loc NOT IN (SELECT SL1.location FROM dbo.sched_location SL1 WHERE SL1.sched_id = @sched_id)

OPEN c_purchase

-- Get first row
FETCH c_purchase INTO @location,@part_no,@done_datetime,@uom_qty,@uom,@xfer_no,@xfer_line

WHILE @@fetch_status = 0
	BEGIN
	-- Schedule the inventory arrival of the materials
	INSERT	dbo.sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
	VALUES(@sched_id,@location,@part_no,@done_datetime,@uom_qty,@uom,'T')

	-- Grab the scheduled item id
	SELECT	@sched_item_id=@@identity

	-- Create additional purchase information
	INSERT	dbo.sched_purchase(sched_item_id,xfer_no,xfer_line)
	VALUES(@sched_item_id,@xfer_no,@xfer_line)

	-- Get next row
	FETCH c_purchase INTO @location,@part_no,@done_datetime,@uom_qty,@uom,@xfer_no,@xfer_line
	END

CLOSE c_purchase

DEALLOCATE c_purchase
end
-- =================================================
-- Load time-phase inventory plus transfers
-- =================================================

-- Load transfers
if @include_xfer_demand = 1 and @include_xfer_supply = 1
begin
INSERT	dbo.sched_transfer(sched_id,location,move_datetime,source_flag,xfer_no,xfer_line)
SELECT	@sched_id,XL.from_loc,X.sch_ship_date,'R',X.xfer_no,XL.line_no
FROM	dbo.sched_location SL1,
	dbo.sched_location SL2,
	dbo.xfers_all X,
	dbo.xfer_list XL
WHERE	SL1.sched_id = @sched_id
AND	SL2.sched_id = @sched_id
AND	X.status IN ('O','N','P','Q')
AND	X.to_loc = SL1.location
AND	X.from_loc = SL2.location
AND	XL.xfer_no = X.xfer_no

-- Generate transferred inventory
INSERT	dbo.sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag,sched_transfer_id)
SELECT	@sched_id,X.to_loc,XL.part_no,X.req_ship_date,XL.ordered,XL.uom,'X',ST.sched_transfer_id
FROM	dbo.sched_transfer ST,
	dbo.xfers_all X,
	dbo.xfer_list XL
WHERE	ST.sched_id = @sched_id
AND	X.xfer_no = ST.xfer_no
AND	X.status IN ('O','N','P','Q')
AND	XL.xfer_no = X.xfer_no
AND	XL.xfer_no = ST.xfer_no
AND	XL.line_no = ST.xfer_line
end

-- Set action codes
EXECUTE dbo.fs_check_schedule @sched_id=@sched_id

RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_initialize_schedule] TO [public]
GO
