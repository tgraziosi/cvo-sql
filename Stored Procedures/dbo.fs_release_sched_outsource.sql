SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_release_sched_outsource]
	(
	@sched_process_id	INT=NULL,
	@sched_item_id		INT=NULL,
	@who			VARCHAR(20)=NULL
	)
AS
BEGIN
DECLARE	@rowcount		INT,
	@resource_demand_id	INT,
	@part_no		VARCHAR(30),
	@quantity		DECIMAL(20,8),
	@demand_date		DATETIME,
	@location		VARCHAR(10),
	@source_flag		CHAR(1),
	@source			CHAR(1),
	@source_no		VARCHAR(20),
	@parent_ratio		DECIMAL(20,8),
	@type_code		CHAR(1),
	@status			CHAR(1),
	@vendor			VARCHAR(12),					-- mls 1/23/02 SCR 28218
	@prod_no		INT,
	@prod_ext		INT,
	@uom			CHAR(2),
        @currency              VARCHAR(8)

declare @unit_cost decimal(20,8), @home_curr varchar(8), @quote_price decimal(20,8), -- mls 8/2/01 SCR 27332
  @quote_qty decimal(20,8), @quote_found char(1), @quote_curr varchar(8)





CREATE TABLE #sched_purchase
	(
	sched_item_id		INT,
	type_code		varCHAR(10)		NULL,
	status			CHAR(1)		NULL,
	vendor			VARCHAR(12)	NULL				-- mls 1/23/02 SCR 28218
	)

CREATE TABLE #sched_item
	(
	sched_item_id		INT,
	part_no			VARCHAR(30),
	ratio			FLOAT
	)

CREATE TABLE #sched_process
	(
	sched_process_id	INT,
	ratio			FLOAT
	)

CREATE TABLE #sched_order
	(
	sched_order_id		INT,
	ratio			FLOAT
	)


BEGIN TRANSACTION







IF @sched_process_id IS NOT NULL
	BEGIN
	INSERT 	#sched_purchase(sched_item_id,type_code,vendor,status)
	SELECT	SI.sched_item_id,IM.type_code,IM.vendor,IM.status
	FROM	dbo.sched_operation SO,
		dbo.sched_operation_item SOI,
		dbo.sched_item SI,
		dbo.inv_master IM
	WHERE	SO.sched_process_id = @sched_process_id
	AND	SO.operation_type = 'O'
	AND	SOI.sched_operation_id = SO.sched_operation_id
	AND	SI.sched_item_id = SOI.sched_item_id
	AND	IM.part_no = SI.part_no
	AND	IM.status = 'Q'
	END
ELSE IF @sched_item_id IS NOT NULL
	BEGIN
	
	SELECT	@sched_process_id=SO.sched_process_id
	FROM	dbo.sched_operation_item SOI,
		dbo.sched_operation SO
	WHERE	SOI.sched_item_id = @sched_item_id
	AND	SO.sched_operation_id = SOI.sched_operation_id

	
	INSERT 	#sched_purchase(sched_item_id,type_code,vendor,status)
	SELECT	SI.sched_item_id,IM.type_code,IM.vendor,IM.status
	FROM	dbo.sched_item SI,
		dbo.inv_master IM
	WHERE	SI.sched_item_id = @sched_item_id
	AND	IM.part_no = SI.part_no
	AND	IM.status = 'Q'

	END
ELSE
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69100 'No processes or purchases defined to release'
	RETURN
	END


IF NOT EXISTS (SELECT * FROM #sched_purchase)
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69300 'No outsource purchases exists for purchase/process'
	RETURN
	END


DELETE	#sched_purchase
FROM	#sched_purchase SP,
	dbo.sched_item SI
WHERE	SI.sched_item_id = SP.sched_item_id
AND	SI.source_flag <> 'P'


IF NOT EXISTS (SELECT * FROM #sched_purchase)
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69310 'Can not release a outsource purchase order that is released or on order'
	RETURN
	END




SELECT	@source_flag=SP.source_flag
FROM	dbo.sched_process SP
WHERE	SP.sched_process_id = @sched_process_id

IF @@rowcount <> 1
	BEGIN
	ROLLBACK TRANSACTION
	RaisError 69101 'Unable to find planned process for outsourced operations'
	RETURN
	END

IF @source_flag <> 'R'
	EXECUTE fs_release_sched_process @sched_process_id = @sched_process_id,@prod_no = @prod_no OUT,@prod_ext = @prod_ext OUT,@who = @who






INSERT INTO #sched_process(sched_process_id,ratio) VALUES (@sched_process_id,1.0)


WHILE EXISTS(SELECT * FROM #sched_process)
	BEGIN
	
	INSERT INTO #sched_item(sched_item_id,part_no,ratio)
	SELECT	SI.sched_item_id,SI.part_no,SP.ratio/SI.uom_qty
	FROM	#sched_process SP,
		dbo.sched_item SI
	WHERE	SI.sched_process_id = SP.sched_process_id

	
	DELETE	#sched_process

	
	INSERT INTO #sched_order(sched_order_id,ratio)
	SELECT	SOI.sched_order_id,SI.ratio
	FROM	#sched_item SI,
		dbo.sched_order_item SOI
	WHERE	SOI.sched_item_id = SI.sched_item_id

	
	INSERT INTO #sched_process(sched_process_id,ratio)
	SELECT	SP.sched_process_id,SI.ratio*SOI.uom_qty
	FROM	#sched_item SI,
		dbo.sched_operation_item SOI,
		dbo.sched_operation SO,
		dbo.sched_process SP
	WHERE	SOI.sched_item_id = SI.sched_item_id
	AND	SO.sched_operation_id = SOI.sched_operation_id
	AND	SP.sched_process_id = SO.sched_process_id
	
	
	DELETE	#sched_item
	END


IF EXISTS(SELECT * FROM #sched_order)	
	
	
	
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
	FROM	#sched_order SO1,
		dbo.sched_order SO2
	WHERE	SO2.sched_order_id = SO1.sched_order_id
	ORDER BY SO2.done_datetime DESC
ELSE					
	SELECT	@source = '',
		@source_no='0',
		@parent_ratio = 0.0






SELECT	@sched_item_id=MIN(SP.sched_item_id)
FROM	#sched_purchase SP

WHILE @sched_item_id IS NOT NULL
	BEGIN
	
	SELECT	@type_code=SP.type_code,
		@vendor=SP.vendor,
		@status=SP.status
	FROM	#sched_purchase SP
	WHERE	SP.sched_item_id = @sched_item_id

        SELECT @currency = NULL
        IF @vendor IS NOT NULL
            SELECT @currency = AP.nat_cur_code FROM dbo.adm_vend_all AP WHERE AP.vendor_code = @vendor

        IF @currency IS NULL
            SELECT @currency = GL.home_currency FROM dbo.glco GL

	
	SELECT	@location=SI.location,
		@demand_date=CONVERT(VARCHAR(10),SI.done_datetime,110),
		@part_no=SI.part_no,
		@quantity=SI.uom_qty,
		@uom=SI.uom,
		@source_flag=SI.source_flag
	FROM	dbo.sched_item SI
	WHERE	SI.sched_item_id = @sched_item_id

	IF @@rowcount > 0
		BEGIN
		
		SELECT	@resource_demand_id=RD.row_id
		FROM	dbo.resource_demand_group RD			-- mls 6/25/01 SCR 26678
		WHERE	RD.location = @location
		AND	RD.part_no = @part_no
		AND	RD.demand_date = @demand_date
		AND	RD.batch_id = 'SCHEDULER'			-- mls 6/25/01 SCR 26678

		
		IF @@rowcount > 0
			BEGIN
			UPDATE	dbo.resource_demand_group
			SET	qty = qty + @quantity
			WHERE	row_id = @resource_demand_id

			exec fs_sched_resource_demand @resource_demand_id, @sched_item_id
			END

		
		ELSE	BEGIN
			
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
			end							-- MLS 8/2/01 SCR 27332 end

			BEGIN TRAN

			if not exists (select 1 from resource_batch where batch_id = 'SCHEDULER')
                          insert resource_batch(batch_id, batch_date, time_fence_end_date)
			  values ('SCHEDULER', getdate(), getdate())

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
                                @unit_cost,                                      -- unit cost  -- mls 8/2/01 SCR 27332
                                'N',                                            -- distinct_order_flag
                                'N',                                            -- blanket_order_flag
                                NULL,                                           -- blanket_po_no
                                'N',                                            -- xfr_order_flag
                                NULL,                                           -- location from
	                        @currency                                       -- vendor currency
		                )

			SELECT	@rowcount=@@rowcount,
				@resource_demand_id = @@identity

			
			IF @rowcount <= 0
				BEGIN
				ROLLBACK TRANSACTION
				RaisError 69341 'Database Error: Unable to send purchase order to purchasing'
				RETURN
				END
			END

                        UPDATE dbo.resource_demand_group SET group_no = CONVERT(varchar(20), @resource_demand_id) WHERE row_id = @resource_demand_id

		
		UPDATE	dbo.sched_item
		SET	source_flag='R'
		WHERE	sched_item_id = @sched_item_id

		
		UPDATE	dbo.sched_purchase
		SET	resource_demand_id = @resource_demand_id
		WHERE	sched_item_id = @sched_item_id

		exec fs_sched_resource_demand @resource_demand_id, @sched_item_id

		COMMIT TRAN
		END

	
	SELECT	@sched_item_id=MIN(SP.sched_item_id)
	FROM	#sched_purchase SP
	WHERE	SP.sched_item_id > @sched_item_id
	END





COMMIT TRANSACTION


DROP TABLE #sched_item
DROP TABLE #sched_process
DROP TABLE #sched_order
DROP TABLE #sched_purchase

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_release_sched_outsource] TO [public]
GO
