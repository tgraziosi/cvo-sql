SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_build_process_plan_items]
	(
	@asm_no	VARCHAR(30),
	@location VARCHAR(10) = NULL
	)
 WITH ENCRYPTION 
AS
BEGIN

DECLARE	@asm_type	CHAR(1),	
	@operation_step	INT,
	@operation_type	CHAR(1),
	@ave_flat_time	FLOAT,
	@ave_unit_time	FLOAT,
	@part_id	INT,
	@seq_no		VARCHAR(4),
	@part_no	VARCHAR(30),
	@uom_qty	DECIMAL(20,8),
	@uom		CHAR(2),
	@fixed		CHAR(1),
	@cell_flag	CHAR(1),
	@status		CHAR(1),
	@part_type	CHAR(1),
	@resource_type	VARCHAR(10),
	@ave_pool_qty	FLOAT,
	@ave_flat_qty	FLOAT,
	@ave_unit_qty	FLOAT,
	@ave_plan_qty	FLOAT,
	@ave_wait_qty	FLOAT,
	@line_id	INT,
	@cell_id	INT









SELECT	@asm_type = IM.status
FROM	dbo.inv_master IM
WHERE	IM.part_no = @asm_no

IF @@rowcount <> 1
	BEGIN
		RaisError 63019 'Item does not exist in inventory master'
	RETURN
	END


IF NOT EXISTS(SELECT * FROM dbo.what_part WP WHERE WP.asm_no = @asm_no)
	BEGIN
		RaisError 62319 'Item does not have a build plan'
	RETURN
	END


IF @asm_type = 'V'
	BEGIN
		RaisError 63018 'Item is non-quantity bearing and has no build plan'
	RETURN
	END

CREATE TABLE #part
	(
	part_id		INT IDENTITY,
	seq_no		VARCHAR(4),
	part_no		VARCHAR(30),
	ave_pool_qty	FLOAT,
	uom_qty		FLOAT,
	uom		CHAR(2),
	fixed		CHAR(1),
	ave_plan_qty	FLOAT,
	ave_wait_qty	FLOAT,
	status		CHAR(1),
	type_code	VARCHAR(10),
	cell_flag	CHAR(1),
	cell_id		INT		NULL
	)


CREATE TABLE #operation
	(
	operation_step	INT,
	location	VARCHAR(10)	NULL,
	ave_flat_qty	FLOAT,
	ave_unit_qty	FLOAT,
	ave_wait_qty	FLOAT,
	ave_flat_time	FLOAT,
	ave_unit_time	FLOAT,
	operation_type	CHAR(1)
	)


CREATE TABLE #plan
	(
	line_id		INT		IDENTITY,
	cell_id		INT		NULL,
	operation_step	INT		NULL,
	seq_no		VARCHAR(4),
	part_no		VARCHAR(30),
	ave_pool_qty	FLOAT,
	ave_flat_qty	FLOAT,
	ave_unit_qty	FLOAT,
	uom		CHAR(2),
	part_type	CHAR(1)
	)


INSERT	#part
	(
	seq_no,			
	part_no,		
	ave_pool_qty,		
	uom_qty,		
	uom,			
	fixed,			
	ave_plan_qty,		
	ave_wait_qty,		
	status,			
	type_code,		
	cell_flag		
	)
SELECT	WP.seq_no,		
	WP.part_no,		
	IsNull(WP.pool_qty,1.0),
	WP.qty,			
	WP.uom,			
	WP.fixed,		
	IsNull(WP.plan_pcs,0.0),
	IsNull(WP.lag_qty,0.0),	
	IM.status,		
	IM.type_code,		
	WP.constrain		
FROM	dbo.what_part WP (NOLOCK),
	dbo.inv_master IM (NOLOCK)
WHERE	WP.asm_no = @asm_no
AND	WP.active = 'A'
AND	WP.location IN (@location,'ALL')
AND	IM.part_no = WP.part_no
AND	(	IM.void = 'N'
	OR	IM.void IS NULL)
ORDER BY WP.seq_no DESC


SELECT	@operation_step = 0,
	@operation_type = 'M',
	@ave_flat_time = 0.0,
	@ave_unit_time = 0.0


SELECT	@part_id=MAX(P.part_id)
FROM	#part P

WHILE @part_id IS NOT NULL
	BEGIN
	
	SELECT	@seq_no=P.seq_no,
		@part_no=P.part_no,
		@ave_pool_qty=P.ave_pool_qty,
		@uom_qty=P.uom_qty,
		@uom=P.uom,
		@fixed=P.fixed,
		@ave_plan_qty=P.ave_plan_qty,
		@ave_wait_qty=P.ave_wait_qty,
		@status=P.status,
		@resource_type=P.type_code,
		@cell_flag=P.cell_flag,
		@cell_id=P.cell_id
	FROM	#part P
	WHERE	P.part_id = @part_id

	
	IF @ave_pool_qty < 0.0
		SELECT	@ave_pool_qty = 0.0

	
	IF @fixed='Y'	SELECT	@ave_flat_qty=@uom_qty,
				@ave_unit_qty=0.0
	ELSE		SELECT	@ave_flat_qty=0.0,
				@ave_unit_qty=@uom_qty

	
	IF @cell_flag = 'Y'
		SELECT	@part_type='C'
	ELSE IF @resource_type = '#IGNORE'
		SELECT	@part_type='X'
	ELSE IF @status='R'
		SELECT	@part_type='R'
	ELSE
		SELECT	@part_type='P'  

	
	INSERT #plan
		(
		seq_no,
		part_no,
		ave_pool_qty,
		ave_flat_qty,
		ave_unit_qty,
		uom,
		part_type,
		cell_id
		)
	VALUES	(
		@seq_no,
		@part_no,
		@ave_pool_qty,
		@ave_flat_qty,
		@ave_unit_qty,
		@uom,
		@part_type,
		@cell_id
		)

	
	SELECT	@line_id=@@identity

	
	IF @status = 'Q'
		BEGIN
		
		SELECT	@operation_type = 'O',
			@ave_flat_time = 0.0,
			@ave_unit_time = 0.0

		
		
		SELECT	@ave_flat_time = 24.0 * I.lead_time
		FROM	dbo.inventory I
		WHERE	I.location = @location
		AND	I.part_no = @part_no
		END

	
	IF @part_type = 'R' AND @operation_type = 'M'
		BEGIN
		
		IF @ave_flat_time < @ave_flat_qty
			SELECT	@ave_flat_time = @ave_flat_qty
		IF @ave_unit_time < @ave_unit_qty
			SELECT	@ave_unit_time = @ave_unit_qty / @ave_pool_qty
		END

	
	IF @asm_type <> 'M' AND ((@ave_plan_qty > 0.0 AND @part_type = 'R') OR @status = 'Q')
		BEGIN
		
		SELECT	@operation_step=@operation_step+1

		
		IF @operation_type = 'M' AND @ave_unit_time > 0.0
			SELECT	@ave_flat_time = 0.0

		
		INSERT	#operation(operation_step,location,ave_flat_qty,ave_unit_qty,ave_wait_qty,ave_flat_time,ave_unit_time,operation_type)
		VALUES	(@operation_step,@location,0.0,@ave_plan_qty,@ave_wait_qty,@ave_flat_time,@ave_unit_time,@operation_type)

		
		UPDATE	#plan
		SET	operation_step = @operation_step
		WHERE	operation_step IS NULL

		
		SELECT	@operation_type = 'M',
			@ave_flat_time = 0.0,
			@ave_unit_time = 0.0
		END

	
	IF @cell_flag = 'Y'
		BEGIN
		INSERT	#part(
			seq_no,
			part_no,
			ave_pool_qty,
			uom_qty,
			uom,
			fixed,
			ave_plan_qty,
			ave_wait_qty,
			status,
			type_code,
			cell_flag,
			cell_id)
		SELECT	WP.seq_no,			
			WP.part_no,			
			IsNull(WP.pool_qty,1.0),	
			CASE WP.fixed				
			WHEN 'Y'
			THEN WP.qty
			ELSE WP.qty * @uom_qty END,
			WP.uom,				
			CASE @fixed			
			WHEN 'Y'
			THEN 'Y'
			ELSE WP.fixed END,
			IsNull(WP.plan_pcs,0.0),	
			IsNull(WP.lag_qty,0.0),		
			IM.status,			
			IM.type_code,			
			WP.constrain,			
			@line_id			
		FROM	dbo.what_part WP (NOLOCK),
			dbo.inv_master IM (NOLOCK)
		WHERE	WP.asm_no = @part_no
		AND	WP.active = 'A'
		AND	WP.location IN (@location,'ALL')
		AND	IM.part_no = WP.part_no
		AND	IM.void = 'N'
		ORDER BY WP.seq_no DESC
		END

	DELETE	#part
	WHERE	part_id=@part_id

	
	SELECT	@part_id=MAX(P.part_id)
	FROM	#part P
	END


BEGIN

SELECT	P.line_id,
	P.cell_id,
	P.operation_step,
	P.seq_no,
	P.part_no,
	P.ave_pool_qty,	
	P.ave_flat_qty,
	P.ave_unit_qty,
	P.uom,
	P.part_type
FROM	#plan P
END



DROP TABLE #plan
DROP TABLE #operation

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_build_process_plan_items] TO [public]
GO
