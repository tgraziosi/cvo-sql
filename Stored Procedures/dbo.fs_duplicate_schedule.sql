SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_duplicate_schedule]
	(
	@sched_id	INT OUTPUT,
	@sched_name	VARCHAR(16) = NULL,
	@wrap_call      INT = 0						-- mls 7/9/01 SCR 27161
	)
AS
BEGIN
-- Local variables
DECLARE	@rowcount		INT,
	@source_id		INT,

	@sched_index		INT,
	@seek_index             INT,					-- mls 7/9/01 SCR 27161
	@seek_name              varchar(16),				-- mls 7/9/01 SCR 27161

	@sched_resource_id	INT,
	@sched_order_id		INT,
	@sched_transfer_id	INT,
	@sched_process_id	INT,
	@sched_operation_id	INT,
	@sched_item_id		INT,

	@location		VARCHAR(10),
	@part_no		VARCHAR(30),
	@done_datetime		DATETIME,
	@work_datetime		DATETIME,
	@uom_qty		FLOAT,
	@uom			CHAR(2),
	@source_flag		CHAR(1),

	@ave_flat_qty		FLOAT,
	@ave_unit_qty		FLOAT,
	@ave_wait_qty		FLOAT,
	@ave_flat_time		FLOAT,
	@ave_unit_time		FLOAT,

	@resource_id		INT,
	@resource_type_id	INT,
	@calendar_id		INT,

	@order_priority_id	INT,
	@order_no		INT,
	@order_ext		INT,
	@order_line		INT,

	@xfer_no		INT,
	@xfer_line		INT,

	@process_id		INT,
	@process_unit		FLOAT,
	@process_unit_orig	FLOAT,	--rev 1
	@prod_no		INT,
	@prod_ext		INT,

	@operation_step		INT,
	@operation_type		CHAR(1),
	@operation_status	CHAR(1),

	@so_prod_no		int,
	@so_prod_ext		int

-- Save the source id
SELECT	@source_id = @sched_id

-- Create transaction for securing new schedule model
BEGIN TRANSACTION

-- Was a schedule scenario name provieded
IF @sched_name IS NULL OR @sched_name = ''				-- mls 7/9/01 SCR 27161 start
  SELECT @sched_name = isnull((select sched_name 
    from sched_model
    where sched_id = @sched_id),'New Model')				

SELECT	@seek_name=@sched_name,
	@seek_index=1

WHILE EXISTS (SELECT * FROM dbo.sched_model SM (TABLOCKX) WHERE SM.sched_name = @seek_name)
BEGIN
  SELECT	@seek_index = @seek_index+1
  SELECT	@seek_name = substring(@sched_name,1,16 - datalength(' ('+CONVERT(VARCHAR(8),@seek_index)+')'))
		 + ' ('+CONVERT(VARCHAR(8),@seek_index)+')'
END

SELECT	@sched_name = @seek_name					-- mls 7/9/01 SCR 27161 end

-- Yes... Is name unique?
IF EXISTS(SELECT * FROM dbo.sched_model WHERE sched_name = @sched_name)
	BEGIN
	ROLLBACK TRANSACTION
	if @wrap_call = 0						-- mls 7/9/01 SCR 27161
	RaisError 69011 'A schedule scenario already exists with that name.'
	RETURN 69011							-- mls 7/9/01 SCR 27161
	END

-- Create the initial model
INSERT	dbo.sched_model
	(
	sched_name,
	process_datetime,
	process_mode,
	beg_date,
	end_date,
	purchase_lead_flag,
	process_group_mode,
	process_batch_mode,
	process_order_mode,
	stock_level_mode,
	order_usage_mode,
	batch_flag,
	check_schedule_flag,
	check_datetime,
	mfg_lead_time_mode,					-- mls 5/2/02 SCR 28862 start
	late_order_sched_mode,
	tolerance_days_early,
	tolerance_days_late,
	planning_time_fence,
	operation_compl_mode,
	forecast_resync_flag,
	forecast_delete_past_flag,
	forecast_horizon,					-- mls 5/2/02 SCR 28862 end
        transfer_demand_mode,					-- mls 4/29/02 SCR 28832
        transfer_supply_mode					-- mls 4/29/02 SCR 28832
	)
SELECT	@sched_name,
	process_datetime,
	process_mode,
	beg_date,
	end_date,
	purchase_lead_flag,
	process_group_mode,
	process_batch_mode,
	process_order_mode,
	stock_level_mode,
	order_usage_mode,
	batch_flag,
	check_schedule_flag,
	check_datetime,
	mfg_lead_time_mode,					-- mls 5/2/02 SCR 28862 start
	late_order_sched_mode,
	tolerance_days_early,
	tolerance_days_late,
	planning_time_fence,
	operation_compl_mode,
	forecast_resync_flag,
	forecast_delete_past_flag,
	forecast_horizon,					-- mls 5/2/02 SCR 28862 end
        transfer_demand_mode,					-- mls 4/29/02 SCR 28832
        transfer_supply_mode					-- mls 4/29/02 SCR 28832
FROM	dbo.sched_model
WHERE	sched_id = @source_id

-- Save the sched_id
SELECT	@sched_id = @@identity,
	@rowcount = @@RowCount

-- Did we succeed???
IF @rowcount <> 1
	BEGIN

	ROLLBACK TRANSACTION
	if @wrap_call = 0						-- mls 7/9/01 SCR 27161
	RaisError 69041 'Problem creating new schedule encountered.'
	RETURN 69041							-- mls 7/9/01 SCR 27161
	END

COMMIT TRANSACTION

-- =================================================
-- Copy locations
-- =================================================

-- Set up model location
INSERT	dbo.sched_location(sched_id,location)
SELECT	@sched_id,SL.location
FROM	dbo.sched_location SL
WHERE	SL.sched_id=@source_id

-- Did we succeed???
IF @rowcount <> 1
	BEGIN
	if @wrap_call = 0						-- mls 7/9/01 SCR 27161
	RaisError 69042 'Problem creating new schedule encountered.'
	RETURN 69042							-- mls 7/9/01 SCR 27161
	END

-- =================================================
-- Copy resources
-- =================================================

-- Table to track old-to-new resources
CREATE TABLE #resource (old_id INT NOT NULL,new_id INT NOT NULL)

DECLARE	c_resource CURSOR FOR
SELECT	sched_resource_id,location,resource_type_id,resource_id,source_flag,calendar_id
FROM	dbo.sched_resource
WHERE	sched_id = @source_id
FOR READ ONLY

OPEN c_resource

FETCH c_resource INTO @sched_resource_id,@location,@resource_type_id,@resource_id,@source_flag,@calendar_id

WHILE @@fetch_status = 0
	BEGIN
	-- WARNING: Do not insert any SQL statements between the following two
	-- statements. This may corrupt the @@identity value before it can be
	-- captured in the #resource cross-reference table. You have been warned
	INSERT	dbo.sched_resource(sched_id,location,resource_type_id,resource_id,source_flag,calendar_id)
	VALUES	(@sched_id,@location,@resource_type_id,@resource_id,@source_flag,@calendar_id)

	INSERT	#resource(old_id,new_id) VALUES (@sched_resource_id,@@identity)

	FETCH c_resource INTO @sched_resource_id,@location,@resource_type_id,@resource_id,@source_flag,@calendar_id
	END

CLOSE c_resource

DEALLOCATE c_resource

-- =================================================
-- Copy orders
-- =================================================

-- Table to track old-to-new orders
CREATE TABLE #order (old_id INT NOT NULL,new_id INT NOT NULL)

DECLARE	c_order CURSOR FOR
SELECT	sched_order_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,source_flag,order_no,order_ext,order_line,
prod_no, prod_ext
FROM	dbo.sched_order
WHERE	sched_id = @source_id
FOR READ ONLY

OPEN c_order

FETCH c_order INTO @sched_order_id,@location,@done_datetime,@part_no,@uom_qty,@uom,@order_priority_id,@source_flag,@order_no,@order_ext,@order_line,
@so_prod_no, @so_prod_ext

WHILE @@fetch_status = 0
	BEGIN
	-- WARNING: Do not insert any SQL statements between the following two
	-- statements. This may corrupt the @@identity value before it can be
	-- captured in the #order cross-reference table. You have been warned.
	INSERT	dbo.sched_order(sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,source_flag,order_no,order_ext,order_line,
	prod_no, prod_ext)
	VALUES	(@sched_id,@location,@done_datetime,@part_no,@uom_qty,@uom,@order_priority_id,@source_flag,@order_no,@order_ext,@order_line,
	@so_prod_no, @so_prod_ext)

	INSERT	#order(old_id,new_id) VALUES (@sched_order_id,@@identity)

	FETCH c_order INTO @sched_order_id,@location,@done_datetime,@part_no,@uom_qty,@uom,@order_priority_id,@source_flag,@order_no,@order_ext,@order_line,
	@so_prod_no, @so_prod_ext
	END

CLOSE c_order

DEALLOCATE c_order

-- =================================================
-- Copy transfers
-- =================================================

-- Table to track old-to-new transfers
CREATE TABLE #transfer (old_id INT NOT NULL,new_id INT NOT NULL)

DECLARE	c_transfer CURSOR FOR
SELECT	ST.sched_transfer_id,ST.location,ST.move_datetime,ST.source_flag,ST.xfer_no,ST.xfer_line
FROM	dbo.sched_transfer ST
WHERE	ST.sched_id = @source_id
FOR READ ONLY

OPEN c_transfer

FETCH c_transfer INTO @sched_transfer_id,@location,@done_datetime,@source_flag,@xfer_no,@xfer_line

WHILE @@fetch_status = 0
	BEGIN
	-- WARNING: Do not insert any SQL statements between the following two
	-- statements. This may corrupt the @@identity value before it can be
	-- captured in the #process cross-reference table. You have been warned.
	INSERT	dbo.sched_transfer(sched_id,location,move_datetime,source_flag,xfer_no,xfer_line)
	VALUES	(@sched_id,@location,@done_datetime,@source_flag,@xfer_no,@xfer_line)

	INSERT	#transfer(old_id,new_id) VALUES (@sched_transfer_id,@@identity)

	FETCH c_transfer INTO @sched_transfer_id,@location,@done_datetime,@source_flag,@xfer_no,@xfer_line
	END

CLOSE c_transfer

DEALLOCATE c_transfer

-- =================================================
-- Copy processes
-- =================================================

-- Table to track old-to-new processes
CREATE TABLE #process (old_id INT NOT NULL,new_id INT NOT NULL)

DECLARE	c_process CURSOR FOR
SELECT	SP.sched_process_id,SP.source_flag,SP.prod_no,SP.prod_ext,SP.process_unit,SP.process_unit_orig
FROM	dbo.sched_process SP
WHERE	SP.sched_id = @source_id
FOR READ ONLY

OPEN c_process

FETCH c_process INTO @sched_process_id,@source_flag,@prod_no,@prod_ext,@process_unit,@process_unit_orig

WHILE @@fetch_status = 0
	BEGIN
	-- WARNING: Do not insert any SQL statements between the following two
	-- statements. This may corrupt the @@identity value before it can be
	-- captured in the #process cross-reference table. You have been warned.
	INSERT	dbo.sched_process(sched_id,source_flag,prod_no,prod_ext,process_unit,process_unit_orig)
	VALUES	(@sched_id,@source_flag,@prod_no,@prod_ext,@process_unit,@process_unit_orig)

	INSERT	#process(old_id,new_id) VALUES (@sched_process_id,@@identity)

	FETCH c_process INTO @sched_process_id,@source_flag,@prod_no,@prod_ext,@process_unit,@process_unit_orig
	END

CLOSE c_process

DEALLOCATE c_process

-- =================================================
-- Copy process products
-- =================================================

INSERT	dbo.sched_process_product
	(
	sched_process_id,
	location,
	part_no,
	uom_qty,
	uom,
	usage_flag,
	cost_pct,
	bom_rev
	)
SELECT	P.new_id,
	SPP.location,
	SPP.part_no,
	SPP.uom_qty,
	SPP.uom,
	SPP.usage_flag,
	SPP.cost_pct,
	SPP.bom_rev
FROM	dbo.sched_process_product SPP,
	#process P
WHERE	SPP.sched_process_id = P.old_id

-- =================================================
-- Copy operations
-- =================================================

-- Table to track old-to-new operations
CREATE TABLE #operation (old_id INT NOT NULL,new_id INT NOT NULL)

DECLARE	c_operation CURSOR FOR
SELECT	SO.sched_operation_id,
	P.new_id,
	SO.operation_step,
	SO.location,
	SO.ave_flat_qty,
	SO.ave_unit_qty,
	SO.ave_wait_qty,
	SO.ave_flat_time,
	SO.ave_unit_time,
	SO.operation_type,
	SO.operation_status,
	SO.work_datetime,
	SO.done_datetime
FROM	#process P,
	dbo.sched_operation SO
WHERE	SO.sched_process_id = P.old_id
FOR READ ONLY

OPEN c_operation

FETCH c_operation INTO @sched_operation_id,@sched_process_id,@operation_step,@location,@ave_flat_qty,@ave_unit_qty,@ave_wait_qty,@ave_flat_time,@ave_unit_time,@operation_type,@operation_status,@work_datetime,@done_datetime

WHILE @@fetch_status = 0
	BEGIN
	-- WARNING: Do not insert any SQL statements between the following two
	-- statements. This may corrupt the @@identity value before it can be
	-- captured in the #operation cross-reference table. You have been warned
	INSERT	dbo.sched_operation(sched_process_id,operation_step,location,ave_flat_qty,ave_unit_qty,ave_wait_qty,ave_flat_time,ave_unit_time,operation_type,operation_status,work_datetime,done_datetime)
	VALUES	(@sched_process_id,@operation_step,@location,@ave_flat_qty,@ave_unit_qty,@ave_wait_qty,@ave_flat_time,@ave_unit_time,@operation_type,@operation_status,@work_datetime,@done_datetime)

	INSERT	#operation(old_id,new_id) VALUES (@sched_operation_id,@@identity)

	FETCH c_operation INTO @sched_operation_id,@sched_process_id,@operation_step,@location,@ave_flat_qty,@ave_unit_qty,@ave_wait_qty,@ave_flat_time,@ave_unit_time,@operation_type,@operation_status,@work_datetime,@done_datetime
	END

CLOSE c_operation

DEALLOCATE c_operation

-- =================================================
-- Copy operation plan
-- =================================================

INSERT	dbo.sched_operation_plan
	(
	sched_operation_id,
	line_no,
	line_id,
	cell_id,
	seq_no,
	part_no,
	usage_qty,
	ave_pool_qty,
	ave_flat_qty,
	ave_unit_qty,
	uom,
	status,
	active,
	eff_date
	)
SELECT	O.new_id,
	SOP.line_no,
	SOP.line_id,
	SOP.cell_id,
	SOP.seq_no,
	SOP.part_no,
	SOP.usage_qty,
	SOP.ave_pool_qty,
	SOP.ave_flat_qty,
	SOP.ave_unit_qty,
	SOP.uom,
	SOP.status,
	SOP.active,
	SOP.eff_date
FROM	dbo.sched_operation_plan SOP,
	#operation O
WHERE	SOP.sched_operation_id = O.old_id

-- =================================================
-- Copy operation resources
-- =================================================

INSERT	dbo.sched_operation_resource
	(
	sched_operation_id,
	sched_resource_id,
	setup_datetime,
	pool_qty
	)
SELECT	O.new_id,
	R.new_id,
	SOR.setup_datetime,
	SOR.pool_qty
FROM	dbo.sched_operation_resource SOR,
	#operation O,
	#resource R
WHERE	SOR.sched_operation_id = O.old_id
AND	SOR.sched_resource_id = R.old_id

-- =================================================
-- Copy time-phased inventory
-- =================================================

-- Table to track old-to-new items
CREATE TABLE #item (old_id INT NOT NULL,new_id INT NOT NULL)

DECLARE	c_item CURSOR FOR
SELECT	SI.sched_item_id,
	SI.location,
	SI.part_no,
	SI.done_datetime,
	SI.uom_qty,
	SI.uom,
	SI.source_flag,
	SI.sched_process_id,
	SI.sched_transfer_id
FROM	dbo.sched_item SI
WHERE	SI.sched_id = @source_id
FOR READ ONLY

OPEN c_item

FETCH c_item INTO @sched_item_id,@location,@part_no,@done_datetime,@uom_qty,@uom,@source_flag,@sched_process_id,@sched_transfer_id

WHILE @@fetch_status = 0
	BEGIN
	IF @sched_process_id IS NOT NULL
		SELECT	@sched_process_id=P.new_id
		FROM	#process P
		WHERE	P.old_id = @sched_process_id

	IF @sched_transfer_id IS NOT NULL
		SELECT	@sched_transfer_id=T.new_id
		FROM	#transfer T
		WHERE	T.old_id = @sched_transfer_id

	-- WARNING: Do not insert any SQL statements between the following two
	-- statements. This may corrupt the @@identity value before it can be
	-- captured in the #item cross-reference table. You have been warned.
	INSERT	dbo.sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag,sched_process_id,sched_transfer_id)
	VALUES	(@sched_id,@location,@part_no,@done_datetime,@uom_qty,@uom,@source_flag,@sched_process_id,@sched_transfer_id)

	INSERT	#item(old_id,new_id) VALUES (@sched_item_id,@@identity)

	FETCH c_item INTO @sched_item_id,@location,@part_no,@done_datetime,@uom_qty,@uom,@source_flag,@sched_process_id,@sched_transfer_id
	END

CLOSE c_item

DEALLOCATE c_item

-- =================================================
-- Copy purchases
-- =================================================

INSERT	dbo.sched_purchase
	(
	sched_item_id,
	lead_datetime,
	vendor_key,
	po_no,
	release_id,
	xfer_no,
	xfer_line
	)
SELECT	I.new_id,
	SP.lead_datetime,
	SP.vendor_key,
	SP.po_no,
	SP.release_id,
	SP.xfer_no,
	SP.xfer_line
FROM	dbo.sched_purchase SP,
	#item I
WHERE	SP.sched_item_id = I.old_id

-- =================================================
-- Copy order inventory
-- =================================================

INSERT	dbo.sched_order_item
	(
	sched_order_id,
	sched_item_id,
	uom_qty,
	uom
	)
SELECT	O.new_id,
	I.new_id,
	SOI.uom_qty,
	SOI.uom
FROM	dbo.sched_order_item SOI,
	#order O,
	#item I
WHERE	SOI.sched_order_id = O.old_id
AND	SOI.sched_item_id = I.old_id

-- =================================================
-- Copy transfer inventory
-- =================================================

INSERT	dbo.sched_transfer_item
	(
	sched_transfer_id,
	sched_item_id,
	uom_qty,
	uom
	)
SELECT	T.new_id,
	I.new_id,
	STI.uom_qty,
	STI.uom
FROM	dbo.sched_transfer_item STI,
	#transfer T,
	#item I
WHERE	STI.sched_transfer_id = T.old_id
AND	STI.sched_item_id = I.old_id

-- =================================================
-- Copy operation inventory
-- =================================================

INSERT	dbo.sched_operation_item
	(
	sched_operation_id,
	sched_item_id,
	uom_qty,
	uom
	)
SELECT	O.new_id,
	I.new_id,
	SOI.uom_qty,
	SOI.uom
FROM	dbo.sched_operation_item SOI,
	#operation O,
	#item I
WHERE	SOI.sched_operation_id = O.old_id
AND	SOI.sched_item_id = I.old_id

DROP TABLE #item
DROP TABLE #operation
DROP TABLE #process
DROP TABLE #transfer
DROP TABLE #order
DROP TABLE #resource

RETURN 1
END

GO
GRANT EXECUTE ON  [dbo].[fs_duplicate_schedule] TO [public]
GO
