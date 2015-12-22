SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_release_sched_process]
	(
	@sched_process_id	INT,
	@prod_no		INT	OUTPUT,
	@prod_ext		INT	OUTPUT,
	@who			VARCHAR(20)=NULL,
	@wrap_call		INT = 0						-- mls 7/9/01 SCR 27161
	)
AS
BEGIN
DECLARE	@source_flag		CHAR(1),
	@location		VARCHAR(10),
	@asm_no			VARCHAR(30),
	@asm_qty		decimal(20,8),					-- mls 8/16/99 SCR 70 20343
	@asm_qty_orig		decimal (20,8),		-- rev 1
	@asm_uom		CHAR(2),
	@asm_type		CHAR(1),
	@status			CHAR(1),
	@process_unit		decimal(20,8),					-- mls 8/16/99 SCR 70 20343
	@process_unit_orig	decimal(20,8),					-- mls 8/16/99 SCR 70 20343
	@work_datetime		DATETIME,
	@done_datetime		DATETIME,
	@sched_operation_id	INT,
	@prior_operation_id	INT,
	@line_id		INT,
	@cell_id		INT,
	@line_no		INT,
	@p_line			INT,
	@seq_no			VARCHAR(4),
	@part_no		VARCHAR(30),
	@ave_flat_qty		decimal(20,8),					-- mls 8/16/99 SCR 70 20343
	@ave_unit_qty		decimal(20,8),					-- mls 8/16/99 SCR 70 20343
	@ave_pool_qty		decimal(20,8),					-- mls 8/16/99 SCR 70 20343
	@part_uom		CHAR(2),
	@part_type		CHAR(1),
	@source			CHAR(1),
	@source_no		VARCHAR(20),
	@parent_ratio		decimal(20,8),					-- mls 8/16/99 SCR 70 20343
	@sch_flag		CHAR(1),
	@sched_product_id	INT,
	@constrain		CHAR(1),
	@obsolete		INT,
	@active         	CHAR(1),
	@eff_date       	DATETIME,
	@bom_rev        	VARCHAR(10)


-- ===========================================================
-- Temporary tables to determine production sources if an
-- outsourcing purchase order is necessary
-- ===========================================================

-- Determine the source of this purchase
CREATE TABLE #sched_item
	(
	sched_item_id		INT,
	part_no			VARCHAR(30),
	ratio			decimal(20,8)					-- mls 8/16/99 SCR 70 20343
	)

CREATE TABLE #sched_process
	(
	sched_process_id	INT,
	ratio			decimal(20,8)					-- mls 8/16/99 SCR 70 20343
	)

CREATE TABLE #sched_order
	(
	sched_order_id		INT,
	ratio			decimal(20,8)					-- mls 8/16/99 SCR 70 20343
	)

-- ===========================================================
-- Get on with the production release
-- ===========================================================

-- Determine what 'who' should be set to
IF @who IS NULL
	SELECT	@who='SCHEDULER'
ELSE IF NOT EXISTS (SELECT * FROM dbo.ewusers_vw SU WHERE SU.user_name = @who)			-- mls 5/30/00
	BEGIN
	if @wrap_call = 0							-- mls 7/9/01 SCR 27161
	RaisError 60110 'The user specified does not exist in Distribution Suite.'
	RETURN 60110								-- mls 7/9/01 SCR 27161
	END

-- This is an all of nothing transaction
BEGIN TRANSACTION

-- ===========================================================
-- Validate action and gather required information
-- ===========================================================

-- Make sure process exists
SELECT	@prod_no=SP.prod_no,
	@prod_ext=SP.prod_ext,
	@source_flag=SP.source_flag,
	@process_unit=SP.process_unit,
	@process_unit_orig=SP.process_unit_orig		-- rev 1

FROM	dbo.sched_process SP (HOLDLOCK)
WHERE	SP.sched_process_id = @sched_process_id

-- If scheduled production does not exist... STOP!!!
IF @@rowcount <> 1
	BEGIN
	ROLLBACK TRANSACTION
	if @wrap_call = 0							-- mls 7/9/01 SCR 27161
	RaisError 69111 'The planned production does not exist'
	RETURN 69111								-- mls 7/9/01 SCR 27161
	END

-- Make sure process is not already released

IF @source_flag = 'R' OR @prod_no IS NOT NULL
	BEGIN
	ROLLBACK TRANSACTION
	if @wrap_call = 0							-- mls 7/9/01 SCR 27161
	RaisError 69130 'The scheduled production has already been released'
	RETURN 69130								-- mls 7/9/01 SCR 27161
	END

-- Get the product information for this production
SELECT	@location=SPP.location,
	@asm_no=SPP.part_no,
	@asm_qty=SPP.uom_qty * @process_unit,
	@asm_qty_orig=SPP.uom_qty * @process_unit_orig,	-- rev 1
	@asm_uom=SPP.uom,
	@bom_rev=SPP.bom_rev
FROM	dbo.sched_process_product SPP
WHERE	SPP.sched_process_id = @sched_process_id
AND	SPP.usage_flag = 'P'

-- If no products could be found, we screwed up
IF @@rowcount <> 1
	BEGIN
	ROLLBACK TRANSACTION
	if @wrap_call = 0							-- mls 7/9/01 SCR 27161
	RaisError 69131 'The planned production did not have a single product defined'
	RETURN 69131								-- mls 7/9/01 SCR 27161
	END

-- Are they a discrete shop?
IF (SELECT C.value_str FROM dbo.config C WHERE C.flag = 'MFG_DISCRETE') = 'YES'
	-- Use the discrete flag
	SELECT	@sch_flag='D'
ELSE
	-- Use the produce flag
	SELECT	@sch_flag='P'

-- Assume that this is a make item
SELECT	@asm_type = 'M'

-- Get primary product information
SELECT	@status=IM.status,
	@obsolete = IM.obsolete
FROM	dbo.inv_master IM
WHERE	IM.part_no = @asm_no

IF @@rowcount = 1
	BEGIN
	-- Make sure that the part is not obsolete
	IF @obsolete = 1
		BEGIN
		ROLLBACK TRANSACTION
		if @wrap_call = 0							-- mls 7/9/01 SCR 27161
		RaisError 63143 'Can not release an item which is obsolete'
		RETURN 69143								-- mls 7/9/01 SCR 27161
		END

	-- If this is a make-routed item... the production should be non-discrete make-routed
	IF @status = 'H'
		SELECT	@asm_type = 'R',
			@sch_flag = 'P'
	END

-- Make sure that the part is in inventory
IF NOT EXISTS (SELECT * FROM dbo.inv_list IL WHERE IL.location = @location AND IL.part_no = @asm_no)
	BEGIN
	ROLLBACK TRANSACTION
	if @wrap_call = 0							-- mls 7/9/01 SCR 27161
	RaisError 69132 'The planned item does not exist at the production location'
	RETURN 69132								-- mls 7/9/01 SCR 27161
	END

-- Determine date range for production
SELECT	@work_datetime=MIN(SO.work_datetime),
	@done_datetime=MAX(SO.done_datetime)
FROM	dbo.sched_operation SO
WHERE	SO.sched_process_id = @sched_process_id

-- ===========================================================
-- Handle manufactured operations
-- ===========================================================

IF EXISTS (SELECT * FROM dbo.sched_operation SO WHERE SO.sched_process_id = @sched_process_id AND SO.operation_type <> 'O')
	BEGIN
	-- Get last production number
	SELECT	@prod_no = NPO.last_no + 1,
		@prod_ext = 0
	FROM	dbo.next_prod_no NPO (HOLDLOCK)

	IF @@rowcount <> 1
		BEGIN
		ROLLBACK TRANSACTION
		if @wrap_call = 0							-- mls 7/9/01 SCR 27161
		RaisError 60240 'Unable to obtain production number from ERA'
		RETURN 60240								-- mls 7/9/01 SCR 27161
		END

	-- Set next production number
	UPDATE	dbo.next_prod_no
	SET	last_no = @prod_no

	IF @@rowcount <> 1
		BEGIN
		ROLLBACK TRANSACTION
		if @wrap_call = 0							-- mls 7/9/01 SCR 27161
		RaisError 60241 'Unable to update production number in ERA'
		RETURN 60241								-- mls 7/9/01 SCR 27161
		END

	-- ===========================================================
	-- Generate production orders
	-- ===========================================================

	-- Insert the scheduled process into production
	INSERT	dbo.produce_all
		(
		prod_no,		-- int			NOT NULL
		prod_ext,		-- int			NOT NULL
		prod_date,		-- datetime		NOT NULL
		part_type,		-- varchar(10)		NOT NULL
		part_no,		-- varchar(30)		NOT NULL
		location,		-- varchar(10)		NULL
		qty,			-- decimal(20,8)	NOT NULL
		prod_type,		-- varchar(10)		NOT NULL
		sch_no,			-- int			NULL
		down_time,		-- int			NOT NULL
		shift,			-- char(1)		NULL
		who_entered,		-- varchar(20)		NOT NULL
		qty_scheduled,		-- decimal(20,8)	NULL
		qty_scheduled_orig,	-- decimal(20,8)	NULL	-- rev 1
		build_to_bom,		-- char(1)		NULL
		date_entered,		-- datetime		NULL
		status,			-- char(1)		NOT NULL
		project_key,		-- varchar(10)		NULL
		sch_flag,		-- char(1)		NULL
		staging_area,		-- varchar(12)		NULL
		sch_date,		-- datetime		NULL
		conv_factor,		-- decimal(20,8)	NULL
		uom,			-- char(2)		NULL
		printed,		-- char(1)		NULL
		void,			-- char(1)		NULL
		void_who,		-- varchar(20)		NULL
		void_date,		-- datetime		NULL
		note,			-- varchar(255)		NULL
		end_sch_date,		-- datetime		NULL
		tot_avg_cost,		-- decimal(20,8)	NOT NULL
		tot_direct_dolrs,	-- decimal(20,8)	NOT NULL
		tot_ovhd_dolrs,		-- decimal(20,8)	NOT NULL
		tot_util_dolrs,		-- decimal(20,8)	NOT NULL
		tot_labor,		-- decimal(20,8)	NOT NULL
		tot_prod_avg_cost,	-- decimal(20,8)	NOT NULL
		tot_prod_direct_dolrs,	-- decimal(20,8)	NOT NULL
		tot_prod_ovhd_dolrs,	-- decimal(20,8)	NOT NULL
		tot_prod_util_dolrs,	-- decimal(20,8)	NOT NULL
		tot_prod_labor,		-- decimal(20,8)	NOT NULL
		est_avg_cost,		-- decimal(20,8)	NOT NULL
		est_direct_dolrs,	-- decimal(20,8)	NOT NULL
		est_ovhd_dolrs,		-- decimal(20,8)	NOT NULL
		est_util_dolrs,		-- decimal(20,8)	NOT NULL
		est_labor,		-- decimal(20,8)	NOT NULL
		scrapped,		-- decimal(20,8)	NOT NULL
		cost_posted,		-- char(1)		NULL
		qc_flag,		-- char(1)		NULL
		order_no,		-- int			NULL
		est_no,			-- int			NULL
		description		-- varchar(255)		NULL
		)
	SELECT	@prod_no,					-- prod_no		int		NOT NULL
		@prod_ext,					-- prod_ext		int		NOT NULL
		IsNull(@work_datetime,getdate()),		-- prod_date		datetime	NOT NULL
		IM.type_code,					-- part_type		varchar(10)	NOT NULL
		@asm_no,					-- part_no		varchar(30)	NOT NULL
		@location,					-- location		varchar(10)	NULL
		0.0,						-- qty			decimal(20,8)	NOT NULL
		@asm_type,					-- prod_type		varchar(10)	NOT NULL
		NULL,						-- sch_no		int		NULL
		0,						-- down_time		int		NOT NULL
		NULL,						-- shift		char(1)		NULL
		@who,						-- who_entered		varchar(20)	NOT NULL
		@asm_qty,					-- qty_scheduled	decimal(20,8)	NULL
		@asm_qty_orig,					-- qty_scheduled_orig	decimal(20,8)	NULL
		'Y',						-- build_to_bom		char(1)		NULL
		getdate(),					-- date_entered		datetime	NULL
		'N',						-- status		char(1)		NOT NULL
		NULL,						-- project_key		varchar(10)	NULL
		@sch_flag,					-- sch_flag		char(1)		NULL
		NULL,						-- staging_area		varchar(12)	NULL
		@work_datetime,					-- sch_date		datetime	NULL
		1.0,						-- conv_factor		decimal(20,8)	NULL
		@asm_uom,					-- uom			char(2)		NULL
		'N',						-- printed		char(1)		NULL
		'N',						-- void			char(1)		NULL
		NULL,						-- void_who		varchar(20)	NULL
		NULL,						-- void_date		datetime	NULL
		IM.note,					-- note			varchar(255)	NULL	-- mls 1/22/04 SCR 32354
		@done_datetime,					-- end_sch_date		datetime	NULL
		0.0,						-- tot_avg_cost		decimal(20,8)	NOT NULL
		0.0,						-- tot_direct_dolrs	decimal(20,8)	NOT NULL
		0.0,						-- tot_ovhd_dolrs	decimal(20,8)	NOT NULL
		0.0,						-- tot_util_dolrs	decimal(20,8)	NOT NULL
		0.0,						-- tot_labor		decimal(20,8)	NOT NULL
		0.0,						-- tot_avg_cost		decimal(20,8)	NOT NULL
		0.0,						-- tot_direct_dolrs	decimal(20,8)	NOT NULL
		0.0,						-- tot_ovhd_dolrs	decimal(20,8)	NOT NULL
		0.0,						-- tot_util_dolrs	decimal(20,8)	NOT NULL
		0.0,						-- tot_labor		decimal(20,8)	NOT NULL
		0.0,						-- tot_avg_cost		decimal(20,8)	NOT NULL
		0.0,						-- tot_direct_dolrs	decimal(20,8)	NOT NULL
		0.0,						-- tot_ovhd_dolrs	decimal(20,8)	NOT NULL
		0.0,						-- tot_util_dolrs	decimal(20,8)	NOT NULL
		0.0,						-- tot_labor		decimal(20,8)	NOT NULL
		0.0,						-- scrapped		decimal(20,8)	NOT NULL
		NULL,						-- cost_posted		char(1)		NULL
		IM.qc_flag,					-- qc_flag		char(1)		NULL
		NULL,						-- order_no		int		NULL
		NULL,						-- est_no		int		NULL
		IM.description					-- description		varchar(255)	NULL	-- mls 8/30/06 SCR 36511
	FROM	dbo.inv_master IM
	WHERE	IM.part_no = @asm_no

	IF @@rowcount <= 0
		BEGIN
		ROLLBACK TRANSACTION
		if @wrap_call = 0							-- mls 7/9/01 SCR 27161
		RaisError 66040 'Unable to enter production in ERA'
		RETURN 66040								-- mls 7/9/01 SCR 27161
		END

	-- ===========================================================
	-- Generate production list products
	-- ===========================================================

	SELECT	@line_no = 1

	-- Get the PRIMARY product item
	SELECT	@sched_product_id = MIN(SPP.sched_process_product_id)
	FROM	dbo.sched_process_product SPP
	WHERE	SPP.sched_process_id = @sched_process_id
	AND	SPP.usage_flag = 'P'

	-- If there is one add it to the recipe
	IF @sched_product_id IS NOT NULL
		BEGIN
		INSERT	dbo.prod_list
			(
			prod_no,	-- int			NOT NULL
			prod_ext,	-- int			NOT NULL
			line_no,	-- int			NOT NULL
			seq_no,		-- varchar(4)		NOT NULL
			part_no,	-- varchar(30)		NOT NULL
			location,	-- varchar(10)		NOT NULL
			description,	-- varchar(255)		NULL
			plan_qty,	-- decimal(20,8)	NOT NULL
			used_qty,	-- decimal(20,8)	NOT NULL
			attrib,		-- decimal(20,8)	NULL
			uom,		-- char(2)		NULL
			conv_factor,	-- decimal(20,98)	NOT NULL
			who_entered,	-- varchar(20)		NULL
			note,		-- varchar(255)		NULL
			lb_tracking,	-- char(1)		NULL
			bench_stock,	-- char(1)		NULL
			status,		-- char(1)		NOT NULL
			constrain,	-- char(1)		NULL
			plan_pcs,	-- decimal(20,8)	NOT NULL
			pieces,		-- decimal(20,8)	NOT NULL
			scrap_pcs,	-- decimal(20,8)	NOT NULL
			part_type,	-- char(1)		NULL
			direction,	-- int			NULL
			cost_pct,	-- decimal(20,8)	NULL
			p_qty,		-- decimal(20,8)	NULL
			p_line,		-- int			NULL
			p_pcs		-- decimal(20,8)	NULL
			)
		SELECT	@prod_no,	-- prod_no	int		NOT NULL
			@prod_ext,	-- prod_ext	int		NOT NULL
			@line_no,	-- line_no	int		NOT NULL
			'',		-- seq_no	varchar(4)	NOT NULL
			SPP.part_no,	-- part_no	varchar(30)	NOT NULL
			SPP.location,	-- location	varchar(10)	NOT NULL
			IM.description,	-- description	varchar(255)	NULL
			SPP.uom_qty *	-- plan_qty	decimal(20,8)	NOT NULL
			@process_unit,
			0.0,		-- used_qty	decimal(20,8)	NOT NULL
			0.0,		-- attrib	decimal(20,8)	NULL
			SPP.uom,	-- uom		char(2)		NULL
			1.0,		-- conv_factor	decimal(20,98)	NOT NULL
			@who,		-- who_entered	varchar(20)	NULL
			NULL,		-- note		varchar(255)	NULL
			IM.lb_tracking,	-- lb_tracking	char(1)		NULL
			'N',		-- bench_stock	char(1)		NULL
			'N',		-- status	char(1)		NOT NULL
			'N',		-- constrain	char(1)		NULL
			SPP.uom_qty *	-- plan_pcs	decimal(20,8)	NOT NULL
			@process_unit,
			0.0,		-- pieces	decimal(20,8)	NOT NULL
			0.0,		-- scrap_pcs	decimal(20,8)	NOT NULL
			case when IM.status < 'N' then 'M'			-- mls 4/15/03 SCR 31001 start
			when IM.status = 'R' then 'R'				
                        else 'P' end,	-- part_type 	char(1)		NULL	-- mls 4/15/03 SCR 31001 end
			1,		-- direction	int		NULL
			SPP.cost_pct,	-- cost_pct	decimal(20,8)	NULL
			SPP.uom_qty,	-- p_qty	decimal(20,8)	NULL
			0,		-- p_line	int		NULL
			1.0		-- p_pcs	decimal(20,8)	NULL	-- rev 1
		FROM	dbo.sched_process_product SPP,
			dbo.inv_master IM
		WHERE	SPP.sched_process_product_id = @sched_product_id
		AND	IM.part_no = SPP.part_no

		SELECT	@line_no=@line_no+1
		END

	-- Now, look for by-products
	SELECT	@sched_product_id = MIN(SPP.sched_process_product_id)
	FROM	dbo.sched_process_product SPP
	WHERE	SPP.sched_process_id = @sched_process_id
	AND	SPP.usage_flag <> 'P'

	-- Process by-products	
	WHILE @sched_product_id IS NOT NULL
		BEGIN
		INSERT	dbo.prod_list
			(
			prod_no,	-- int			NOT NULL
			prod_ext,	-- int			NOT NULL
			line_no,	-- int			NOT NULL
			seq_no,		-- varchar(4)		NOT NULL
			part_no,	-- varchar(30)		NOT NULL
			location,	-- varchar(10)		NOT NULL
			description,	-- varchar(255)		NULL
			plan_qty,	-- decimal(20,8)	NOT NULL
			used_qty,	-- decimal(20,8)	NOT NULL
			attrib,		-- decimal(20,8)	NULL
			uom,		-- char(2)		NULL
			conv_factor,	-- decimal(20,98)	NOT NULL
			who_entered,	-- varchar(20)		NULL
			note,		-- varchar(255)		NULL
			lb_tracking,	-- char(1)		NULL
			bench_stock,	-- char(1)		NULL
			status,		-- char(1)		NOT NULL
			constrain,	-- char(1)		NULL
			plan_pcs,	-- decimal(20,8)	NOT NULL
			pieces,		-- decimal(20,8)	NOT NULL
			scrap_pcs,	-- decimal(20,8)	NOT NULL
			part_type,	-- char(1)		NULL
			direction,	-- int			NULL
			cost_pct,	-- decimal(20,8)	NULL
			p_qty,		-- decimal(20,8)	NULL
			p_line,		-- int			NULL
			p_pcs		-- decimal(20,8)	NULL
			)
		SELECT	@prod_no,	-- prod_no	int		NOT NULL
			@prod_ext,	-- prod_ext	int		NOT NULL
			@line_no,	-- line_no	int		NOT NULL
			'',		-- seq_no	varchar(4)	NOT NULL
			SPP.part_no,	-- part_no	varchar(30)	NOT NULL
			SPP.location,	-- location	varchar(10)	NOT NULL
			IM.description,	-- description	varchar(255)	NULL
			SPP.uom_qty *	-- plan_qty	decimal(20,8)	NOT NULL
			@process_unit,
			0.0,		-- used_qty	decimal(20,8)	NOT NULL
			0.0,		-- attrib	decimal(20,8)	NULL
			SPP.uom,	-- uom		char(2)		NULL
			1.0,		-- conv_factor	decimal(20,98)	NOT NULL
			@who,		-- who_entered	varchar(20)	NULL
			NULL,		-- note		varchar(255)	NULL
			IM.lb_tracking,	-- lb_tracking	char(1)		NULL
			'N',		-- bench_stock	char(1)		NULL
			'N',		-- status	char(1)		NOT NULL
			'N',		-- constrain	char(1)		NULL
			SPP.uom_qty *	-- plan_pcs	decimal(20,8)	NOT NULL
			@process_unit,
			0.0,		-- pieces	decimal(20,8)	NOT NULL
			0.0,		-- scrap_pcs	decimal(20,8)	NOT NULL
			case when IM.status < 'N' then 'M'			-- mls 4/15/03 SCR 31001 start
			when IM.status = 'R' then 'R'				
                        else 'P' end,	-- part_type 	char(1)		NULL	-- mls 4/15/03 SCR 31001 end
			1,		-- direction	int		NULL
			SPP.cost_pct,	-- cost_pct	decimal(20,8)	NULL
			SPP.uom_qty,	-- p_qty	decimal(20,8)	NULL
			0,		-- p_line	int		NULL
			0.0		-- p_pcs	decimal(20,8)	NULL
		FROM	dbo.sched_process_product SPP,
			dbo.inv_master IM
		WHERE	SPP.sched_process_product_id = @sched_product_id
		AND	IM.part_no = SPP.part_no

		SELECT	@line_no=@line_no+1
	
		SELECT	@sched_product_id = MIN(SPP.sched_process_product_id)
		FROM	dbo.sched_process_product SPP
		WHERE	SPP.sched_process_id = @sched_process_id
		AND	SPP.usage_flag <> 'P'
		AND	SPP.sched_process_product_id > @sched_product_id
		END

	-- ===========================================================
	-- Generate production list primary build plan
	-- ===========================================================

if @status = 'H' -- make/routed
	SELECT	@line_id = MIN(SOP.line_id)
	FROM	dbo.sched_operation SO
	JOIN	dbo.sched_operation_plan SOP on SOP.sched_operation_id = SO.sched_operation_id
	WHERE	SO.sched_process_id = @sched_process_id 
else
	SELECT	@line_id = MIN(SOP.line_id)
	FROM	dbo.sched_operation SO
	JOIN	dbo.sched_operation_plan SOP on SOP.sched_operation_id = SO.sched_operation_id
	WHERE	SO.sched_process_id = @sched_process_id AND SOP.line_no IS NULL AND SOP.cell_id IS NULL

	-- Determine first operation
	SELECT	@prior_operation_id=SOP.sched_operation_id
	FROM	dbo.sched_operation SO,
		dbo.sched_operation_plan SOP
	WHERE	SO.sched_process_id = @sched_process_id
	AND	SOP.sched_operation_id = SO.sched_operation_id
	AND	SOP.line_id = @line_id


	WHILE @line_id IS NOT NULL
		BEGIN
		-- Get the rest of the information
		SELECT	@sched_operation_id=SOP.sched_operation_id,
			@seq_no=SOP.seq_no,
			@part_no=SOP.part_no,
			@location=SO.location,
			@ave_flat_qty=SOP.ave_flat_qty,
			@ave_unit_qty=SOP.ave_unit_qty,
			@part_uom=SOP.uom,
			@part_type=SOP.status,
			@constrain=CASE WHEN SOP.status = 'C' THEN 'C' ELSE 'N' END,
			@ave_pool_qty=SOP.ave_pool_qty,
			@active = SOP.active,
			@eff_date = SOP.eff_date
		FROM	dbo.sched_operation SO,
			dbo.sched_operation_plan SOP
		WHERE	SO.sched_process_id = @sched_process_id
		AND	SOP.sched_operation_id = SO.sched_operation_id
		AND	SOP.line_id = @line_id

		-- If we have change operations, set the prior steps planned pierces and lag
		IF @sched_operation_id <> @prior_operation_id
			BEGIN
			UPDATE	dbo.prod_list
		--	SET	plan_pcs=SO.ave_flat_qty+SO.ave_unit_qty*@process_unit,
			SET     plan_pcs = SO.ave_unit_qty * @process_unit, -- Rev 5
				p_pcs = SO.ave_unit_qty		-- rev 1
			FROM	dbo.prod_list PL,
				dbo.sched_operation SO
			WHERE	SO.sched_operation_id = @prior_operation_id
			AND	PL.prod_no = @prod_no
			AND	PL.prod_ext = @prod_ext
			AND	PL.line_no = @line_no - 1

			SELECT	@prior_operation_id=@sched_operation_id
			END

		INSERT	dbo.prod_list
			(
			prod_no,	-- int			NOT NULL
			prod_ext,	-- int			NOT NULL
			line_no,	-- int			NOT NULL
			seq_no,		-- varchar(4)		NOT NULL
			part_no,	-- varchar(30)		NOT NULL
			location,	-- varchar(10)		NOT NULL
			description,	-- varchar(255)		NULL
			plan_qty,	-- decimal(20,8)	NOT NULL
			used_qty,	-- decimal(20,8)	NOT NULL
			attrib,		-- decimal(20,8)	NULL
			uom,		-- char(2)		NULL
			conv_factor,	-- decimal(20,98)	NOT NULL
			who_entered,	-- varchar(20)		NULL
			note,		-- varchar(255)		NULL
			lb_tracking,	-- char(1)		NULL
			bench_stock,	-- char(1)		NULL
			status,		-- char(1)		NOT NULL
			constrain,	-- char(1)		NULL
			plan_pcs,	-- decimal(20,8)	NOT NULL
			pieces,		-- decimal(20,8)	NOT NULL
			scrap_pcs,	-- decimal(20,8)	NOT NULL
			part_type,	-- char(1)		NULL
			direction,	-- int			NULL
			cost_pct,	-- decimal(20,8)	NULL
			p_qty,		-- decimal(20,8)	NULL
			p_line,		-- int			NULL
			p_pcs,		-- decimal(20,8)	NULL
			pool_qty,	-- decimal(20,8)	NULL
			active,
			eff_date
			)
		SELECT	@prod_no,	-- prod_no	int		NOT NULL
			@prod_ext,	-- prod_ext	int		NOT NULL
			@line_no,	-- line_no	int		NOT NULL
			@seq_no,
                        -- case when @constrain = 'C' then '****' else
			-- @seq_no end,	-- seq_no	varchar(4)	NOT NULL
			@part_no,	-- part_no	varchar(30)	NOT NULL
			@location,	-- location	varchar(10)	NOT NULL
			IM.description,	-- description	varchar(255)	NULL
			@ave_flat_qty +	-- plan_qty	decimal(20,8)	NOT NULL
			@ave_unit_qty
			* @asm_qty,
			0.0,		-- used_qty	decimal(20,8)	NOT NULL
			0.0,		-- attrib	decimal(20,8)	NULL
			@part_uom,	-- uom		char(2)		NULL
			1.0,		-- conv_factor	decimal(20,98)	NOT NULL
			@who,		-- who_entered	varchar(20)	NULL
			NULL,		-- note		varchar(255)	NULL
			IM.lb_tracking,	-- lb_tracking	char(1)		NULL
			'N',		-- bench_stock	char(1)		NULL
			'N',		-- status	char(1)		NOT NULL
			@constrain,	-- constrain	char(1)		NULL
			0.0,		-- plan_pcs	decimal(20,8)	NOT NULL
			0.0,		-- pieces	decimal(20,8)	NOT NULL
			0.0,		-- scrap_pcs	decimal(20,8)	NOT NULL
			case when @constrain = 'C' then 'C'			-- mls 4/15/03 SCR 31001 start
			when IM.status < 'N' then 'M'
			when IM.status = 'R' then 'R'				
                        else 'P' end,	-- part_type 	char(1)		NULL	-- mls 4/15/03 SCR 31001 end
			-1,		-- direction	int		NULL
			0.0,		-- cost_pct	decimal(20,8)	NULL
			@ave_unit_qty,	-- p_qty	decimal(20,8)	NULL
			case when @status = 'H' then @line_no else 0 end,		-- p_line	int		NULL
			0.0,		-- p_pcs	decimal(20,8)	NULL
			@ave_pool_qty,  	-- pool_qty	decimal(20,8)	NULL
			@active,
			@eff_date
		FROM	dbo.inv_master IM
		WHERE	IM.part_no = @part_no

		UPDATE	sched_operation_plan
		SET	line_no = @line_no
		WHERE	sched_operation_id=@sched_operation_id
		AND	seq_no=@seq_no
		AND	part_no=@part_no
		AND	line_id = @line_id		-- mls 4/15/03

		SELECT	@line_no=@line_no+1
	
if @status = 'H' -- make/routed
	SELECT	@line_id = MIN(SOP.line_id)
	FROM	dbo.sched_operation SO
	JOIN	dbo.sched_operation_plan SOP on SOP.sched_operation_id = SO.sched_operation_id
	WHERE	SO.sched_process_id = @sched_process_id AND SOP.line_id > @line_id
else
	SELECT	@line_id = MIN(SOP.line_id)
	FROM	dbo.sched_operation SO
	JOIN	dbo.sched_operation_plan SOP on SOP.sched_operation_id = SO.sched_operation_id
	WHERE	SO.sched_process_id = @sched_process_id AND SOP.line_no IS NULL AND SOP.cell_id IS NULL
	AND	SOP.line_id > @line_id

		END

	-- Set the last steps planned pieces and lag
	UPDATE	dbo.prod_list
	--SET	plan_pcs=SO.ave_flat_qty+SO.ave_unit_qty*@process_unit,
	SET	plan_pcs=SO.ave_unit_qty * @process_unit,
		p_pcs=SO.ave_unit_qty
	FROM	dbo.prod_list PL,
		dbo.sched_operation SO
	WHERE	SO.sched_operation_id = @prior_operation_id
	AND	PL.prod_no = @prod_no
	AND	PL.prod_ext = @prod_ext
	AND	PL.line_no = @line_no - 1

	-- ===========================================================
	-- Generate production list secondary (cell) build plan(s)
	-- ===========================================================

	-- Get first cell
if @status != 'H'	-- not make/routed
begin
	SELECT	@cell_id = MIN(SOP.line_id)
	FROM	dbo.sched_operation SO,
		dbo.sched_operation_plan SOP
	WHERE	SO.sched_process_id = @sched_process_id
	AND	SOP.sched_operation_id = SO.sched_operation_id
	AND	SOP.status = 'C'

	WHILE @cell_id IS NOT NULL
		BEGIN
		-- Get the rest of the information
		SELECT	@seq_no=SOP.seq_no,
			@part_no=SOP.part_no,
			@location=SO.location,
			@ave_flat_qty=SOP.ave_flat_qty,
			@ave_unit_qty=SOP.ave_unit_qty,
			@part_uom=SOP.uom,
			@part_type=SOP.status,
			@p_line=SOP.line_no,
			@active=SOP.active,
			@eff_date=SOP.eff_date
		FROM	dbo.sched_operation SO,
			dbo.sched_operation_plan SOP
		WHERE	SO.sched_process_id = @sched_process_id
		AND	SOP.sched_operation_id = SO.sched_operation_id
		AND	SOP.line_id = @cell_id

		-- Insert cell header
		INSERT	dbo.prod_list
			(
			prod_no,	-- int			NOT NULL
			prod_ext,	-- int			NOT NULL
			line_no,	-- int			NOT NULL
			seq_no,		-- varchar(4)		NOT NULL
			part_no,	-- varchar(30)		NOT NULL
			location,	-- varchar(10)		NOT NULL
			description,	-- varchar(255)		NULL
			plan_qty,	-- decimal(20,8)	NOT NULL
			used_qty,	-- decimal(20,8)	NOT NULL
			attrib,		-- decimal(20,8)	NULL
			uom,		-- char(2)		NULL
			conv_factor,	-- decimal(20,98)	NOT NULL
			who_entered,	-- varchar(20)		NULL
			note,		-- varchar(255)		NULL
			lb_tracking,	-- char(1)		NULL
			bench_stock,	-- char(1)		NULL
			status,		-- char(1)		NOT NULL
			constrain,	-- char(1)		NULL
			plan_pcs,	-- decimal(20,8)	NOT NULL
			pieces,		-- decimal(20,8)	NOT NULL
			scrap_pcs,	-- decimal(20,8)	NOT NULL
			part_type,	-- char(1)		NULL
			direction,	-- int			NULL
			cost_pct,	-- decimal(20,8)	NULL
			p_qty,		-- decimal(20,8)	NULL
			p_line,		-- int			NULL
			p_pcs,		-- decimal(20,8)	NULL
			active,
			eff_date
			)
		SELECT	@prod_no,	-- prod_no	int		NOT NULL
			@prod_ext,	-- prod_ext	int		NOT NULL
			@line_no,	-- line_no	int		NOT NULL
			'****',		-- seq_no	varchar(4)	NOT NULL
			@part_no,	-- part_no	varchar(30)	NOT NULL
			@location,	-- location	varchar(10)	NOT NULL
			IM.description,	-- description	varchar(255)	NULL
			@ave_flat_qty +	-- plan_qty	decimal(20,8)	NOT NULL
			@ave_unit_qty
			* @asm_qty,
			0.0,		-- used_qty	decimal(20,8)	NOT NULL
			0.0,		-- attrib	decimal(20,8)	NULL
			@part_uom,	-- uom		char(2)		NULL
			1.0,		-- conv_factor	decimal(20,98)	NOT NULL
			@who,		-- who_entered	varchar(20)	NULL
			NULL,		-- note		varchar(255)	NULL
			IM.lb_tracking,	-- lb_tracking	char(1)		NULL
			'N',		-- bench_stock	char(1)		NULL
			'N',		-- status	char(1)		NOT NULL
			'C',		-- constrain	char(1)		NULL
			0.0,		-- plan_pcs	decimal(20,8)	NOT NULL
			0.0,		-- pieces	decimal(20,8)	NOT NULL
			0.0,		-- scrap_pcs	decimal(20,8)	NOT NULL
			'C',		-- part_type	char(1)		NULL	-- mls 4/15/03 SCR 31001
			-1,		-- direction	int		NULL
			0.0,		-- cost_pct	decimal(20,8)	NULL
			@ave_unit_qty,	-- p_qty	decimal(20,8)	NULL
			@p_line,	-- p_line	int		NULL
			0.0,		-- p_pcs	decimal(20,8)	NULL
			@active,
			@eff_date
		FROM	dbo.inv_master IM
		WHERE	IM.part_no = @part_no

		SELECT	@line_no=@line_no+1

		-- Get first line in cell
		SELECT	@line_id = MIN(SOP.line_id)
		FROM	dbo.sched_operation SO,
			dbo.sched_operation_plan SOP
		WHERE	SO.sched_process_id = @sched_process_id
		AND	SOP.sched_operation_id = SO.sched_operation_id
		AND	SOP.line_no IS NULL
		AND	SOP.cell_id = @cell_id

		WHILE @line_id IS NOT NULL
			BEGIN
			-- Get the rest of the information
			SELECT	@seq_no=SOP.seq_no,
				@part_no=SOP.part_no,
				@location=SO.location,
				@ave_flat_qty=SOP.ave_flat_qty,
				@ave_unit_qty=SOP.ave_unit_qty,
				@part_uom=SOP.uom,
				@part_type=SOP.status,
				@active=SOP.active,
				@eff_date=SOP.eff_date,
				@constrain=CASE WHEN SOP.status = 'C' THEN 'C' ELSE 'N' END
			FROM	dbo.sched_operation SO,
				dbo.sched_operation_plan SOP
			WHERE	SO.sched_process_id = @sched_process_id
			AND	SOP.sched_operation_id = SO.sched_operation_id
			AND	SOP.line_id = @line_id

			INSERT	dbo.prod_list
				(
				prod_no,	-- int			NOT NULL
				prod_ext,	-- int			NOT NULL
				line_no,	-- int			NOT NULL
				seq_no,		-- varchar(4)		NOT NULL
				part_no,	-- varchar(30)		NOT NULL
				location,	-- varchar(10)		NOT NULL
				description,	-- varchar(255)		NULL
				plan_qty,	-- decimal(20,8)	NOT NULL
				used_qty,	-- decimal(20,8)	NOT NULL
				attrib,		-- decimal(20,8)	NULL
				uom,		-- char(2)		NULL
				conv_factor,	-- decimal(20,98)	NOT NULL
				who_entered,	-- varchar(20)		NULL
				note,		-- varchar(255)		NULL
				lb_tracking,	-- char(1)		NULL
				bench_stock,	-- char(1)		NULL
				status,		-- char(1)		NOT NULL
				constrain,	-- char(1)		NULL
				plan_pcs,	-- decimal(20,8)	NOT NULL
				pieces,		-- decimal(20,8)	NOT NULL
				scrap_pcs,	-- decimal(20,8)	NOT NULL
				part_type,	-- char(1)		NULL
				direction,	-- int			NULL
				cost_pct,	-- decimal(20,8)	NULL
				p_qty,		-- decimal(20,8)	NULL
				p_line,		-- int			NULL
				p_pcs,		-- decimal(20,8)	NULL
				active,
				eff_date
				)
			SELECT	@prod_no,	-- prod_no	int		NOT NULL
				@prod_ext,	-- prod_ext	int		NOT NULL
				@line_no,	-- line_no	int		NOT NULL
				@seq_no,	-- seq_no	varchar(4)	NOT NULL
				@part_no,	-- part_no	varchar(30)	NOT NULL
				@location,	-- location	varchar(10)	NOT NULL
				IM.description,	-- description	varchar(255)	NULL
				@ave_flat_qty +	-- plan_qty	decimal(20,8)	NOT NULL
				@ave_unit_qty
				* @asm_qty,
				0.0,		-- used_qty	decimal(20,8)	NOT NULL
				0.0,		-- attrib	decimal(20,8)	NULL
				@part_uom,	-- uom		char(2)		NULL
				1.0,		-- conv_factor	decimal(20,98)	NOT NULL
				@who,		-- who_entered	varchar(20)	NULL
				NULL,		-- note		varchar(255)	NULL
				IM.lb_tracking,	-- lb_tracking	char(1)		NULL
				'N',		-- bench_stock	char(1)		NULL
				'N',		-- status	char(1)		NOT NULL
				@constrain,	-- constrain	char(1)		NULL
				0.0,		-- plan_pcs	decimal(20,8)	NOT NULL
				0.0,		-- pieces	decimal(20,8)	NOT NULL
				0.0,		-- scrap_pcs	decimal(20,8)	NOT NULL
				case when @constrain = 'C' then 'C'			-- mls 4/15/03 SCR 31001 start
				when IM.status < 'N' then 'M'
				when IM.status = 'R' then 'R'				
                        	else 'P' end,	-- part_type 	char(1)		NULL	-- mls 4/15/03 SCR 31001 end
				-1,		-- direction	int		NULL
				0.0,		-- cost_pct	decimal(20,8)	NULL
				@ave_unit_qty,	-- p_qty	decimal(20,8)	NULL
				@p_line,	-- p_line	int		NULL
				0.0,		-- p_pcs	decimal(20,8)	NULL
				@active,
				@eff_date
			FROM	dbo.inv_master IM
			WHERE	IM.part_no = @part_no

			UPDATE	sched_operation_plan
			SET	line_no = @line_no
			WHERE	sched_operation_id=@sched_operation_id
			AND	seq_no=@seq_no
			AND	line_id = @line_id and cell_id = @cell_id		-- mls 5/17/02 SCR 28951
			AND	part_no=@part_no

			SELECT	@line_no=@line_no+1

			SELECT	@line_id = MIN(SOP.line_id)
			FROM	dbo.sched_operation SO,
				dbo.sched_operation_plan SOP
			WHERE	SO.sched_process_id = @sched_process_id
			AND	SOP.sched_operation_id = SO.sched_operation_id
			AND	SOP.line_no IS NULL
			AND	SOP.cell_id = @cell_id
			AND	SOP.line_id > @line_id
			END

		-- Get next cell
		SELECT	@cell_id = MIN(SOP.line_id)
		FROM	dbo.sched_operation SO,
			dbo.sched_operation_plan SOP
		WHERE	SO.sched_process_id = @sched_process_id
		AND	SOP.sched_operation_id = SO.sched_operation_id
		AND	SOP.status = 'C'
		AND	SOP.line_id > @cell_id
		END	
	END
end
-- ===========================================================
-- Production has been released, mark it so
-- ===========================================================

-- Mark the scheduled process as released
UPDATE	dbo.sched_process
SET	source_flag='R',
	prod_no=@prod_no,
	prod_ext=@prod_ext
WHERE	sched_process_id = @sched_process_id

IF @@rowcount <> 1
	BEGIN
	ROLLBACK TRANSACTION
	if @wrap_call = 0							-- mls 7/9/01 SCR 27161
	RaisError 69140 'Unable to update process as released'
	RETURN 69140								-- mls 7/9/01 SCR 27161
	END

-- If we got here... then all is well
COMMIT TRANSACTION

DROP TABLE #sched_order
DROP TABLE #sched_process
DROP TABLE #sched_item

RETURN 1
END
GO
GRANT EXECUTE ON  [dbo].[fs_release_sched_process] TO [public]
GO
