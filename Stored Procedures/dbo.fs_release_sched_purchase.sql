SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


-- Copyright (c) 2001 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_release_sched_purchase]
	(
	@sched_item_id	INT,
	@who		VARCHAR(20)=NULL
	)
AS
BEGIN
DECLARE	@rowcount		INT,
	@resource_demand_id	INT,
	@part_no		VARCHAR(30),
	@status			CHAR(1),
	@quantity		DECIMAL(20,8),
	@demand_date		DATETIME,
	@location		VARCHAR(10),
	@source_flag		CHAR(1),
	@source			CHAR(1),
	@source_no		VARCHAR(20),
	@parent_ratio		DECIMAL(20,8),
	@type_code		CHAR(1),
	@vendor			VARCHAR(12),					-- mls 1/23/02 SCR 28218
	@uom			CHAR(2),
	@prod_no		INT,
	@sched_operation_id   	INT,
	@sched_process_id	INT,
	@sp_source_flag		CHAR(1),
	@obsolete		INT,
        @currency               VARCHAR(8)

declare @unit_cost decimal(20,8), @home_curr varchar(8), @quote_price decimal(20,8), -- mls 8/2/01 SCR 27332
  @quote_qty decimal(20,8), @quote_found char(1), @quote_curr varchar(8)

-- ===========================================================
-- Temporary table for intermediate processing
-- ===========================================================

-- Determine the source of this purchase
CREATE TABLE #rsp_sched_item
	(
	sched_item_id		INT,
	part_no			VARCHAR(30),
	ratio			FLOAT
	)

CREATE TABLE #rsp_sched_process
	(
	sched_process_id	INT,
	ratio			FLOAT
	)

CREATE TABLE #rsp_sched_order
	(
	sched_order_id		INT,
	ratio			FLOAT
	)

-- ===========================================================
-- Get on with the production release
-- ===========================================================

-- Determine what 'who' should be set to
IF @who IS NULL
	SELECT	@who='SCHEDULER'
ELSE IF NOT EXISTS (SELECT * FROM dbo.ewusers_vw SU WHERE SU.user_name = @who)				-- mls 5/30/00
	BEGIN
	RaisError 60110 'The user specified does not exist in millenia.'
	RETURN
	END

-- This is an all or nothing transaction
BEGIN TRANSACTION

-- Get the schedule purchase information
SELECT	@location=SI.location,
	@demand_date=CONVERT(VARCHAR(10),SI.done_datetime,110),
	@part_no=SI.part_no,
	@quantity=SI.uom_qty,
	@uom=SI.uom,
	@source_flag=SI.source_flag
FROM	dbo.sched_item SI
WHERE	SI.sched_item_id = @sched_item_id

IF @@rowcount <> 1
	BEGIN
	ROLLBACK TRANSACTION
	RETURN
	END

-- Make sure the to-be-released purchase is planned (and not already released)
IF @source_flag	<> 'P'
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69430 'Cannot release a purchase order that is released or on order'
	RETURN
	END

-- Get the information for the part
SELECT	@obsolete = IM.obsolete,
	@type_code=IM.type_code,
	@status=IM.status,
	@vendor=IM.vendor
FROM	dbo.inv_master IM
WHERE	IM.part_no = @part_no

-- Is the part miscellaneous
IF @@rowcount = 0
	-- It is a miscellaneous part
	SELECT	@type_code = '',
		@vendor = NULL,
		@status = 'P',
		@uom = isnull(@uom,'')				-- mls 6/13/02 SCR 29064
ELSE	-- It is an inventory item
	BEGIN 
	-- Make sure that the part is valid for this location
	IF NOT EXISTS(SELECT * FROM dbo.inv_list IL WHERE IL.location = @location AND IL.part_no = @part_no)
		BEGIN
		ROLLBACK TRANSACTION
		RaisError 63141 'Unable to find part in location inventory'
		RETURN
		END

	-- Make sure this item can be purchased
	IF @status <> 'P'
		BEGIN
		ROLLBACK TRANSACTION
		RaisError 63142 'Only outsource or purchase items can be sent to purchasing'
		RETURN
		END

	-- Make sure that the part is not obsolete
	IF @obsolete = 1
		BEGIN
		ROLLBACK TRANSACTION
		RaisError 63143 'Cannot release an item which is obsolete'
		RETURN
		END
	END

-- Determine the currency code 
SELECT @currency = NULL

IF @vendor IS NOT NULL
    SELECT @currency = AP.nat_cur_code FROM dbo.adm_vend_all AP WHERE AP.vendor_code = @vendor

IF @currency IS NULL
    SELECT @currency = GL.home_currency FROM dbo.glco GL

-- Check to see if purchase is linked to a RELEASED JOB
SELECT	@prod_no = NULL

SELECT	@sched_operation_id = SOI.sched_operation_id 
FROM	dbo.sched_operation_item SOI
WHERE	SOI.sched_item_id = @sched_item_id

IF @@rowcount > 0
	BEGIN
	SELECT	@sched_process_id = SO.sched_process_id
	FROM	dbo.sched_operation SO
	WHERE	SO.sched_operation_id = @sched_operation_id
	
	IF @@rowcount > 0	
		BEGIN
		SELECT	@prod_no = SP.prod_no,
			@sp_source_flag = SP.source_flag
		FROM	dbo.sched_process SP
		WHERE	SP.sched_process_id = @sched_process_id

		IF @@rowcount > 0 AND @sp_source_flag = 'R'
			BEGIN
			IF NOT EXISTS (SELECT * FROM dbo.produce_all P 
				  WHERE P.prod_type = 'J' AND P.prod_no = @prod_no)

				BEGIN
				SELECT @prod_no = NULL			
				END
			END
		ELSE
			BEGIN
			SELECT @prod_no = NULL
			END
		END	
	END

-- Place seed in item table
INSERT #rsp_sched_item(sched_item_id,part_no,ratio) VALUES (@sched_item_id,@part_no,1.0)

-- Move down the build tree until we get all of the demand orders
WHILE EXISTS(SELECT * FROM #rsp_sched_item)
	BEGIN
	-- Determine order(s) for these items
	INSERT	#rsp_sched_order(sched_order_id,ratio)
	SELECT	SOI.sched_order_id,SI.ratio
	FROM	#rsp_sched_item SI,
		dbo.sched_order_item SOI
	WHERE	SOI.sched_item_id = SI.sched_item_id

	-- Get down-stream processes
	INSERT	#rsp_sched_process(sched_process_id,ratio)
	SELECT	SO.sched_process_id,SI.ratio*SOI.uom_qty
	FROM	#rsp_sched_item SI,
		dbo.sched_operation_item SOI ,
		dbo.sched_operation SO 
	WHERE	SOI.sched_item_id = SI.sched_item_id
	AND	SO.sched_operation_id = SOI.sched_operation_id

	-- Delete up-stream items
	DELETE	#rsp_sched_item

	-- Get down-stream items
	INSERT	#rsp_sched_item(sched_item_id,part_no,ratio)
	SELECT	SI.sched_item_id,SI.part_no,SP.ratio/SI.uom_qty
	FROM	#rsp_sched_process SP,
		dbo.sched_item SI
	WHERE	SI.sched_process_id = SP.sched_process_id

	-- Clear up-stream processes
	DELETE	#rsp_sched_process

	END

-- Determine number of demand orders...
IF EXISTS(SELECT * FROM #rsp_sched_order)	-- If there are any sources, fill in the blanks
	-- Get the important information for the demand
	-- NOTE: This is safe for multi-row result sets. The ORDER BY clause guarantees
	-- that we will get the earliest order
	SELECT	@source	= CASE SO2.source_flag
			WHEN 'C' THEN 'C'
			WHEN 'A' THEN 'M'
			WHEN 'M' THEN 'M'			-- mls 11/12/01 SCR 27837
			WHEN 'N' THEN 'M'			-- mls 11/12/01 SCR 27837
			ELSE 'S' END,
		@source_no = CASE SO2.source_flag
			WHEN 'C' THEN CONVERT(VARCHAR(20),SO2.order_no)
			ELSE '0' END,
		@parent_ratio = SO1.ratio
	FROM	#rsp_sched_order SO1,
		dbo.sched_order SO2
	WHERE	SO2.sched_order_id = SO1.sched_order_id
	ORDER BY SO2.done_datetime DESC
ELSE					-- If there were no sources for this purchase, clear
	SELECT	@source = '',
		@source_no='0',
		@parent_ratio = 0.0














-- Above were the old conditions under which we would sum to an existing resource_demand row instead of adding a new one.

SELECT	@resource_demand_id=RD.row_id
FROM	dbo.resource_demand_group RD
WHERE	RD.location = @location
AND	RD.part_no = @part_no
AND	RD.demand_date = @demand_date
AND	RD.batch_id = 'SCHEDULER'

-- If we found a match, then update  that row
IF @@rowcount > 0
	BEGIN
	UPDATE	dbo.resource_demand_group
	SET	qty = qty + @quantity
	WHERE	row_id = @resource_demand_id

	END

-- If we did not find a match... insert the record
ELSE	BEGIN
	-- Send the scheduled purchase to purchasing
	select @unit_cost = 0				-- mls 8/2/01 SCR 27332 start
	select @quote_found = 'N'

	select @home_curr = IsNull((SELECT home_currency FROM glco),'')

	DECLARE	quote_cursor CURSOR FOR
	SELECT	last_price,   
		curr_key,   
		qty  
	FROM	vendor_sku  
	WHERE	vendor_no	= @vendor and
		sku_no		= @part_no and  
		convert( char(8), last_recv_date, 112 ) >= getdate()
	ORDER BY qty, curr_key ASC   

	OPEN quote_cursor

	FETCH NEXT FROM quote_cursor
	INTO @quote_price, @quote_curr, @quote_qty

	WHILE @@FETCH_STATUS = 0
	begin
		if (@quote_qty is NULL or @quote_qty > @quantity) break

		select	@unit_cost = @quote_price,
			@currency = @quote_curr
		select @quote_found = 'Y'

		FETCH NEXT FROM quote_cursor
		INTO @quote_price, @quote_curr, @quote_qty
	end

	CLOSE quote_cursor
	DEALLOCATE quote_cursor

	--******************************************************************************
	--* Vendor quotes entered in the home currency when the vendor's natural 
	--* currency is other than home are stored with a curr_key value of '*HOME*'.
	--* We need to return the actual currency code to the calling procedure.
	--******************************************************************************
	if @currency = '*HOME*' select @currency = @home_curr

	if @quote_found = 'N'
	--******************************************************************************
	--* No quote was found so get the last price paid
	--******************************************************************************
	begin
		SELECT	@unit_cost	= cost			
		FROM	inventory
		WHERE	part_no		= @part_no and
			location	= @location

		select @currency = @home_curr
	end							-- MLS 8/2/01 SCR 27332

	INSERT	dbo.resource_demand_group
		(
                batch_id,                                       -- varchar(20)
                group_no,
		part_no,					-- varchar(30)
		qty,						-- DECIMAL(20,8)
		demand_date,					-- datetime
		location,					-- varchar(10)		NULL
		vendor_no,						-- varchar(12)		NULL
		buy_flag,					-- char(1)		NULL
	        uom,						-- char(2)		NULL
                unit_cost,                                      -- DECIMAL (20,8)       NOT NULL
                distinct_order_flag,                            -- char(1)
                blanket_order_flag,                             -- char(1)
                blanket_po_no,                                  -- varchar(10)
                xfer_order_flag,                                -- char(1)
                location_from,                                  -- varchar(10)
                curr_key
		)
	VALUES	(
                'SCHEDULER',
                NULL,
		@part_no,					-- part_no	varchar(30)
		@quantity,					-- qty		DECIMAL(20,8)
		@demand_date,					-- demand_date	datetime
		@location,					-- location	varchar(10)	NULL
	        @vendor,					-- vendor	varchar(12)	NULL 
                'N',						-- buy_flag	char(1)		NULL
	        @uom,						-- uom		char(2)		NULL
                @unit_cost,                                     -- unit cost  -- mls 8/2/01 SCR 27332
                'N',                                            -- distinct_order_flag
                'N',                                            -- blanket_order_flag
                NULL,                                           -- blanket_po_no
                'N',                                            -- xfr_order_flag
                NULL,                                           -- location from
	        @currency                                       -- vendor currency
		)

	SELECT	@rowcount=@@rowcount,
		@resource_demand_id = @@identity

	-- If we were not able to insert... we have problems
	IF @rowcount <= 0
		BEGIN
		ROLLBACK TRANSACTION
		RaisError 69341 'Database Error: Unable to send purchase order to purchasing'
		RETURN
		END

        UPDATE dbo.resource_demand_group SET group_no = CONVERT(varchar(20), @resource_demand_id) WHERE row_id = @resource_demand_id

	END


-- Mark the scheduled purchase as released
UPDATE	dbo.sched_item
SET	source_flag='R'
WHERE	sched_item_id = @sched_item_id

-- Record the resource demand that we used
-- mls 3/1/02 SCR 28459 start
if exists (select 1 from sched_purchase (nolock) where sched_item_id = @sched_item_id)
begin
UPDATE	dbo.sched_purchase
SET	resource_demand_id = @resource_demand_id
WHERE	sched_item_id = @sched_item_id
end
else
begin
insert sched_purchase (sched_item_id, lead_datetime, resource_demand_id)
values (@sched_item_id, @demand_date, @resource_demand_id)
end
-- mls 3/1/02 SCR 28459 end

exec fs_sched_resource_demand @resource_demand_id, @sched_item_id

-- If we got here... then all is well
COMMIT TRANSACTION

-- Clean up some of the tables
DROP TABLE #rsp_sched_item
DROP TABLE #rsp_sched_process
DROP TABLE #rsp_sched_order

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_release_sched_purchase] TO [public]
GO
