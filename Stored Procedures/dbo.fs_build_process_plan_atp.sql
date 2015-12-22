SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_build_process_plan_atp]
	(
	@asm_no	VARCHAR(30),
	@location VARCHAR(10) = NULL,
	@sched_id INT = NULL,
	@asm_qty FLOAT = 0.0,
	@sched_process_id INT = NULL OUT
	)
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
	@cell_id	INT,
	@build_plan_resource VARCHAR(30),
 	@build_plan_flat_time FLOAT,
 	@build_plan_unit_time FLOAT,
        @build_plan_fixed_flag CHAR(1),
        @operation_resource_flat_time FLOAT,
	@operation_resource_unit_time FLOAT,
	@operation_previous_resource VARCHAR(30),
	@active     CHAR(1),
	@eff_date   DATETIME,
	@bom_rev    VARCHAR(10)    



DECLARE @yield_pct	FLOAT,
	@adm_qty_adj_yield	FLOAT


declare @test_resource_type 	char (1),
	@test_resource 		char(30),
	@resource_new_code 	char(30),
	@test_step 		int





SELECT	@yield_pct = IM.yield_pct,	-- rev 1--add yield percent
	@asm_type = IM.status
FROM	dbo.inv_master IM
WHERE	IM.part_no = @asm_no

IF @@rowcount <> 1
	BEGIN
	IF @sched_id IS NOT NULL
		SELECT	@sched_process_id = NULL
	ELSE
		RaisError 63019 'Item does not exist in inventory master'
	RETURN
	END


SELECT @bom_rev = MAX(revision) 
FROM inv_revisions IR
WHERE IR.part_no = @asm_no


IF NOT EXISTS(SELECT * FROM dbo.what_part WP WHERE WP.asm_no = @asm_no)
	BEGIN
	IF @sched_id IS NOT NULL
		SELECT	@sched_process_id = NULL
	ELSE
		RaisError 62319 'Item does not have a build plan'
	RETURN
	END


IF @asm_type = 'V'
	BEGIN
	IF @sched_id IS NOT NULL
		SELECT	@sched_process_id = NULL
	ELSE
		RaisError 63018 'Item is non-quantity bearing and has no build plan'
	RETURN
	END

CREATE TABLE #product
	(
	location	VARCHAR(10)	NULL,
	part_no		VARCHAR(30),
	uom_qty		FLOAT,
	uom		CHAR(2),
	usage_flag	CHAR(1),
	cost_pct	FLOAT,
	bom_rev     VARCHAR(10) NULL
	)

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
	cell_id		INT		NULL,
	active      CHAR(1) NULL,     
	eff_date    DATETIME NULL 
	)


CREATE TABLE #operation_resources
        (
             resource_id VARCHAR(30),
             fixed_flag  CHAR(1),
             build_plan_flat_time FLOAT,
             build_plan_unit_time  FLOAT
	)

DECLARE c_operation_resources CURSOR FOR
	SELECT 	OPRES.resource_id,
		OPRES.fixed_flag,
		OPRES.build_plan_flat_time,
		OPRES.build_plan_unit_time
	FROM	#operation_resources OPRES
	ORDER BY OPRES.resource_id,
		 OPRES.fixed_flag
	


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
	part_type	CHAR(1),
	active      CHAR(1) NULL,    
	eff_date    DATETIME NULL   
	)


INSERT	#product(location,part_no,uom_qty,uom,usage_flag,cost_pct,bom_rev)
SELECT	@location,WP.part_no,WP.qty,WP.uom,'B',WP.cost_pct,@bom_rev
FROM	dbo.what_part WP (NOLOCK),
	dbo.inv_list IL (NOLOCK)
WHERE	WP.asm_no = @asm_no
AND	WP.active = 'M'
AND	WP.location IN (@location,'ALL')
AND	IL.location = @location
AND	IL.part_no = WP.part_no
AND	IL.void = 'N'

INSERT	#product(location,part_no,uom_qty,uom,usage_flag,cost_pct,bom_rev)
SELECT	@location,@asm_no,1.0,IM.uom,'P',100.0-IsNull((SELECT SUM(P.cost_pct) FROM #product P),0.0),@bom_rev
FROM	dbo.inv_master IM (NOLOCK)
WHERE	IM.part_no = @asm_no


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
	cell_flag,		
	active,      
	eff_date     
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
	WP.constrain,	
	WP.active,      
	WP.eff_date     
FROM	dbo.what_part WP (NOLOCK),
	dbo.inv_master IM (NOLOCK)
WHERE	WP.asm_no = @asm_no
AND ((WP.active = 'A') 
     OR ((WP.active = 'B') AND (getdate() < WP.eff_date))
     OR ((WP.active = 'U') AND (getdate() >= WP.eff_date)))
AND	WP.location IN (@location,'ALL')
AND	IM.part_no = WP.part_no
AND	(	IM.void = 'N'
	OR	IM.void IS NULL)
ORDER BY WP.seq_no DESC


SELECT	@operation_step = 0,
	@operation_type = 'M'


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
		@cell_id=P.cell_id,
		@active=P.active,
		@eff_date=P.eff_date
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
		cell_id,
		active,
		eff_date
		)
	VALUES	(
		@seq_no,
		@part_no,
		@ave_pool_qty,
		@ave_flat_qty,
		@ave_unit_qty,
		@uom,
		@part_type,
		@cell_id,
		@active,
		@eff_date
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
		-- Store resources for this operation.
                INSERT #operation_resources
                (
		resource_id,
          	fixed_flag,
	        build_plan_flat_time,
		build_plan_unit_time
		)
		VALUES
		(
		@part_no,
		@fixed,
		@ave_flat_qty,
		@ave_unit_qty
		)
		END

	
	IF @asm_type <> 'M' AND ((@ave_plan_qty > 0.0 AND @part_type = 'R') OR @status = 'Q')
		BEGIN
		
		SELECT	@operation_step=@operation_step+1
	        
                IF @status <> 'Q'
                BEGIN
	        
		OPEN c_operation_resources
	
		SELECT @operation_resource_flat_time = 0.0
		SELECT @operation_resource_unit_time = 0.0
		SELECT @ave_unit_time = 0.0  -- Operation unit run-time
		SELECT @ave_flat_time = 0.0  -- Operation flat run-time
 
		FETCH c_operation_resources into @build_plan_resource,@build_plan_fixed_flag,@build_plan_flat_time,@build_plan_unit_time
		SELECT @operation_previous_resource = @build_plan_resource

		WHILE @@fetch_status = 0
			BEGIN
			IF @build_plan_resource = @operation_previous_resource
				BEGIN
					IF @build_plan_fixed_flag = 'N'
					BEGIN
						IF @build_plan_unit_time > @operation_resource_unit_time
							SELECT @operation_resource_unit_time = @build_plan_unit_time
					END
					ELSE
					BEGIN
						IF @build_plan_flat_time > @operation_resource_flat_time
						SELECT @operation_resource_flat_time = @build_plan_flat_time
					END
				END
			ELSE
				BEGIN
					IF @operation_resource_unit_time = 0.0
						BEGIN
							IF @operation_resource_flat_time > @ave_flat_time
								SELECT @ave_flat_time = @operation_resource_flat_time 								 
						END
  
		                		SELECT @operation_resource_flat_time = 0.0
						SELECT @operation_resource_unit_time = 0.0
	
						IF @build_plan_fixed_flag = 'N'
							SELECT @operation_resource_unit_time = @build_plan_unit_time
						ELSE
							SELECT @operation_resource_flat_time = @build_plan_flat_time
	
				END
			-- For each non-fixed fetched, track the largest unit time.
			IF @build_plan_fixed_flag = 'N'
				BEGIN
					IF @build_plan_unit_time > @ave_unit_time
						SELECT @ave_unit_time = @build_plan_unit_time
				END

			SELECT @operation_previous_resource = @build_plan_resource
		   	FETCH c_operation_resources into @build_plan_resource,@build_plan_fixed_flag,@build_plan_flat_time,@build_plan_unit_time
		   	END  -- end of while loop

		IF @operation_resource_unit_time = 0.0
			BEGIN
				IF @operation_resource_flat_time > @ave_flat_time
					SELECT @ave_flat_time = @operation_resource_flat_time 								 
			END
  							 
        	CLOSE c_operation_resources
                DELETE #operation_resources
                END
		
		INSERT	#operation(operation_step,location,ave_flat_qty,ave_unit_qty,ave_wait_qty,ave_flat_time,ave_unit_time,operation_type)
		VALUES	(@operation_step,@location,0.0,@ave_plan_qty,@ave_wait_qty,@ave_flat_time,@ave_unit_time,@operation_type)

		
		UPDATE	#plan
		SET	operation_step = @operation_step
		WHERE	operation_step IS NULL

		
		SELECT	@operation_type = 'M'

		END  -- end of "if this is an operation wip point"


	
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
			AND ((WP.active = 'A') 
      		OR ((WP.active = 'B') AND (getdate() < WP.eff_date))
	 	OR ((WP.active = 'U') AND (getdate() >= WP.eff_date)))

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


IF EXISTS(SELECT * FROM #plan P WHERE P.operation_step IS NULL)
	BEGIN
	
	SELECT	@operation_step=@operation_step+1

	        
		OPEN c_operation_resources
	
		SELECT @operation_resource_flat_time = 0.0
		SELECT @operation_resource_unit_time = 0.0
		SELECT @ave_unit_time = 0.0  -- Operation unit run-time
		SELECT @ave_flat_time = 0.0  -- Operation flat run-time
 
		FETCH c_operation_resources into @build_plan_resource,@build_plan_fixed_flag,@build_plan_flat_time,@build_plan_unit_time
		SELECT @operation_previous_resource = @build_plan_resource

		WHILE @@fetch_status = 0
			BEGIN
			IF @build_plan_resource = @operation_previous_resource
				BEGIN
					IF @build_plan_fixed_flag = 'N'
					BEGIN
						IF @build_plan_unit_time > @operation_resource_unit_time
							SELECT @operation_resource_unit_time = @build_plan_unit_time
					END
					ELSE
					BEGIN
						IF @build_plan_flat_time > @operation_resource_flat_time
						SELECT @operation_resource_flat_time = @build_plan_flat_time
					END
				END
			ELSE
				BEGIN
					IF @operation_resource_unit_time = 0.0
						BEGIN
							IF @operation_resource_flat_time > @ave_flat_time
								SELECT @ave_flat_time = @operation_resource_flat_time 								 
						END
  
		                		SELECT @operation_resource_flat_time = 0.0
						SELECT @operation_resource_unit_time = 0.0
	
						IF @build_plan_fixed_flag = 'N'
							SELECT @operation_resource_unit_time = @build_plan_unit_time
						ELSE
							SELECT @operation_resource_flat_time = @build_plan_flat_time
	
				END
			-- For each non-fixed fetched, track the largest unit time.
			IF @build_plan_fixed_flag = 'N'
				BEGIN
					IF @build_plan_unit_time > @ave_unit_time
						SELECT @ave_unit_time = @build_plan_unit_time
				END

			SELECT @operation_previous_resource = @build_plan_resource
		   	FETCH c_operation_resources into @build_plan_resource,@build_plan_fixed_flag,@build_plan_flat_time,@build_plan_unit_time
		   	END  -- end of while loop

		IF @operation_resource_unit_time = 0.0
			BEGIN
				IF @operation_resource_flat_time > @ave_flat_time
					SELECT @ave_flat_time = @operation_resource_flat_time 								 
			END
  							 
        	CLOSE c_operation_resources
                DELETE #operation_resources	
	
	INSERT	#operation(operation_step,location,ave_flat_qty,ave_unit_qty,ave_wait_qty,ave_flat_time,ave_unit_time,operation_type)
	VALUES	(@operation_step,@location,0.0,0.0,0.0,@ave_flat_time,@ave_unit_time,@operation_type)

	
	UPDATE	#plan
	SET	operation_step = @operation_step
	WHERE	operation_step IS NULL
	END


IF NOT EXISTS(SELECT * FROM #operation)
	BEGIN
	IF @sched_id IS NULL
		RaisError 62318 'Build plan is invalid for this location'
	ELSE
		SELECT	@sched_process_id = NULL
	END
ELSE IF @sched_id IS NULL
	BEGIN
	
	SELECT	P.location,P.part_no,P.uom_qty,P.uom,P.usage_flag,P.cost_pct,bom_rev
	FROM	#product P,
		dbo.inv_master IM
	WHERE	IM.part_no = P.part_no

	
	SELECT	O.operation_step,
		O.location,
		O.ave_flat_qty,
		O.ave_unit_qty,
		O.ave_wait_qty,
		O.ave_flat_time,
		O.ave_unit_time,
		O.operation_type
	FROM	#operation O

	
	SELECT	P.line_id,
		P.cell_id,
		P.operation_step,
		P.seq_no,
		P.part_no,
		P.ave_pool_qty,		
		P.ave_flat_qty,
		P.ave_unit_qty,
		P.uom,
		P.part_type,
		P.active,
		P.eff_date
	FROM	#plan P
	END
ELSE
	BEGIN
	
	
	
	select @adm_qty_adj_yield = @asm_qty
	select @yield_pct = IsNull(@yield_pct, 0.00)
	if @yield_pct <> 0.00
	

	


	   begin
		select @adm_qty_adj_yield = ((100/@yield_pct) * @asm_qty)	-- apply yield percent
		select @adm_qty_adj_yield = CEILING(@adm_qty_adj_yield)			-- round up
	   end
	

	INSERT	dbo.sched_process(sched_id,process_unit,process_unit_orig,source_flag)	
	VALUES	(@sched_id,@adm_qty_adj_yield,@asm_qty,'P')		-- rev 1:  add process_unit_orig

	
	SELECT	@sched_process_id=@@identity
	
	INSERT	dbo.sched_process_product(sched_process_id,location,part_no,uom_qty,uom,usage_flag,cost_pct,bom_rev)
	SELECT	@sched_process_id,P.location,P.part_no,P.uom_qty,P.uom,P.usage_flag,P.cost_pct,@bom_rev
	FROM	#product P,
		dbo.inv_master IM
	WHERE	IM.part_no = P.part_no
	
	INSERT	dbo.sched_operation
		(
		sched_process_id,
		operation_step,
		location,
		ave_flat_qty,
		ave_unit_qty,
		ave_wait_qty,
		ave_flat_time,
		ave_unit_time,
		operation_type,
		operation_status
		)
	SELECT	@sched_process_id,	
		O.operation_step,	
		O.location,		
		O.ave_flat_qty,		
		O.ave_unit_qty,		
		O.ave_wait_qty,		
		O.ave_flat_time,	
		O.ave_unit_time,	
		O.operation_type,	
		'U'			
	FROM	#operation O

	


	DECLARE c_resource_test CURSOR FOR
	select 	P.part_type,
		P.part_no,
		P.operation_step
	FROM	#plan P,
		dbo.sched_operation SO
	WHERE	SO.sched_process_id = @sched_process_id
	AND	P.operation_step = SO.operation_step

	open c_resource_test
	fetch c_resource_test into @test_resource_type, @test_resource, @test_step

	while @@fetch_status = 0 begin
	   if (@test_resource_type = 'R') begin		--if it is a resource
		   if exists(select group_part_no from resource_group where group_part_no = @test_resource) begin
			select @resource_new_code = resource_part_no from resource_group
			where group_part_no = @test_resource and 
			use_order = (select min(use_order) from resource_group where group_part_no = @test_resource)

			if (@resource_new_code != @test_resource) begin
			   update #plan
			   set part_no = @resource_new_code
			   where operation_step = @test_step
			   AND part_no = @test_resource
			end
		   end
	   end
	   fetch c_resource_test into @test_resource_type, @test_resource, @test_step
	END -- end of while loop

	CLOSE c_resource_test
	DEALLOCATE c_resource_test



	INSERT	dbo.sched_operation_plan
		(
		sched_operation_id,
		line_id,
		cell_id,
		seq_no,
		part_no,
		ave_pool_qty,		
		ave_flat_qty,
		ave_unit_qty,
		uom,
		status
		)
	SELECT	SO.sched_operation_id,	
		P.line_id,		
		P.cell_id,		
		P.seq_no,		
		P.part_no,		
		P.ave_pool_qty,		
		P.ave_flat_qty,		
		P.ave_unit_qty,		
		P.uom,			
		P.part_type		
	FROM	#plan P,
		dbo.sched_operation SO
	WHERE	SO.sched_process_id = @sched_process_id
	AND	P.operation_step = SO.operation_step
	END


DROP TABLE #plan
DROP TABLE #operation
DEALLOCATE c_operation_resources
DROP TABLE #operation_resources


RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_build_process_plan_atp] TO [public]
GO
