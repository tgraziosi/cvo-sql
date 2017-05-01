SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_update_schedule]
	(
	@sched_id		INT,
	@object_flag		CHAR(1),
	@status_flag		CHAR(1),
	@location		VARCHAR(10)	= NULL,
	@resource_id		INT		= NULL,
	@sched_resource_id	INT		= NULL,
	@part_no		VARCHAR(30)	= NULL,
	@sched_order_id		INT		= NULL,
	@order_no		INT		= NULL,
	@order_ext		INT		= NULL,
	@order_line		INT		= NULL,
	@order_line_kit		INT		= NULL,
	@sched_process_id	INT		= NULL,
	@sched_operation_id	INT		= NULL,	
	@prod_no		INT		= NULL,
	@prod_ext		INT		= NULL,
	@prod_line		INT		= NULL,	
	@sched_item_id		INT		= NULL,
	@po_no			VARCHAR(16)	= NULL,					-- mls 2/28/03 SCR 30781
	@release_id		INT		= NULL,
	@sched_transfer_id	INT		= NULL,
	@transfer_id		INT		= NULL,
	@transfer_line		INT		= NULL,
	@resource_demand_id	INT		= NULL,
        @forecast_demand_date    DATETIME       = NULL,
        @forecast_qty            FLOAT          = NULL,
        @forecast_uom           VARCHAR(2)      = NULL,
	@order_priority_id	INT		= NULL,
	@purch_lead_flag	Char(1)		= NULL
	)
--WITH ENCRYPTION
AS
BEGIN
SET NOCOUNT ON





DECLARE	@rowcount		INT,
	@vendor_no		VARCHAR(12),				-- mls  1/23/02 SCR 28218	
	@done_datetime		DATETIME,
	@part_type		CHAR(1),
	@qty			DECIMAL(20,8),
	@uom			CHAR(2),
	@beg_location		VARCHAR(10),
	@end_location		VARCHAR(10),
	@beg_datetime		DATETIME,
	@end_datetime		DATETIME,
	@lead_time		INT,
	@dock_to_stock		INT,
	@lead_datetime 		DATETIME,
	@purchase_lead_flag	CHAR(1)

DECLARE @po_line		int					-- mls 5/15/01 SCR 6603


IF @object_flag = 'R'		
	BEGIN
	IF @status_flag = 'N'	
		BEGIN
		
		INSERT 	sched_resource(sched_id,location,resource_type_id,resource_id,calendar_id,source_flag)
		SELECT	@sched_id,@location,R.resource_type_id,R.resource_id,R.calendar_id,'R'
		FROM	resource R
		WHERE	R.resource_id = @resource_id
					
		SELECT	@sched_resource_id=@@identity
		END

	ELSE IF @status_flag = 'O'	
		BEGIN
		
                if (@@version like '%7.0%')
                  delete sched_operation_resource where sched_resource_id = @sched_resource_id

		DELETE sched_resource
		WHERE sched_resource_id = @sched_resource_id
		END

	ELSE	RaisError 69081 'Illegal status code passed'
	END

ELSE IF @object_flag = 'D'		
	BEGIN
	
	if @order_priority_id is NULL
	begin
	SELECT	@order_priority_id=OP.order_priority_id
	FROM	order_priority OP
	WHERE	OP.usage_flag = 'D'

	IF @@rowcount <> 1
		BEGIN
		RaisError 64049 'Unable to determine default order priority'
		RETURN
		END
	end

	IF @status_flag = 'N'	
		BEGIN
		
		
		INSERT	sched_order(sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,
                          source_flag,order_no,order_ext,order_line, prod_no, prod_ext)
		SELECT	@sched_id,OL.location,IsNull(O.sch_ship_date,O.req_ship_date),
		  case when OL.part_type in ('P','M') then OL.part_no else NULL end,
                  (OL.ordered - OL.shipped) * OL.conv_factor,IsNull(IM.uom,OL.uom),@order_priority_id,
		  case when OL.part_type = 'J' then 'J' else 'C' end,
                  OL.order_no,OL.order_ext,OL.line_no,
                  case when OL.part_type = 'J' then CONVERT(int,OL.part_no) else NULL end,
                  case when OL.part_type = 'J' then 0 else NULL end
		FROM	orders_all O
		JOIN	ord_list OL on OL.order_no = O.order_no and OL.order_ext = O.ext 
                        AND OL.part_type IN ('P','M','J') AND OL.ordered > OL.shipped
		JOIN	sched_location SL on SL.location = OL.location and SL.sched_id = @sched_id
		LEFT OUTER JOIN inv_master IM on IM.part_no = OL.part_no
		WHERE	O.order_no = @order_no
		AND	O.ext = @order_ext


		
		INSERT	sched_order
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
			order_line_kit
			)
		SELECT	@sched_id,					
			OLK.location,					
			IsNull(O.sch_ship_date,O.req_ship_date),	
			OLK.part_no,					
							
			(OLK.ordered - OLK.shipped) * OLK.conv_factor * OLK.qty_per,	

			IM.uom,						
			@order_priority_id,				
			'C',						
			OLK.order_no,					
			OLK.order_ext,					
			OLK.line_no,					
			OLK.row_id					
		FROM	orders_all O
		join	ord_list_kit OLK on OLK.order_no = O.order_no and OLK.order_ext = O.ext
			 AND OLK.part_type = 'P' AND OLK.ordered > OLK.shipped
		join 	sched_location SL on SL.location = OLK.location and SL.sched_id = @sched_id
		join	inv_master IM on IM.part_no = OLK.part_no
		WHERE	O.order_no = @order_no
		AND	O.ext = @order_ext
		END

	ELSE IF @status_flag = 'A'	
		BEGIN
--		SELECT	@part_type=OL.part_type
--		FROM	ord_list OL
--		WHERE	OL.order_no = @order_no
--		AND	OL.order_ext = @order_ext
--		AND	OL.line_no = @order_line

--		IF @part_type IN ('P','M','J')
--		begin
			INSERT	sched_order(sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,
				source_flag,order_no,order_ext,order_line, prod_no, prod_ext)
			SELECT	@sched_id,OL.location,IsNull(O.sch_ship_date,O.req_ship_date),
			  case when OL.part_type in ('P','M') then OL.part_no else NULL end,
                	  (OL.ordered - OL.shipped) * OL.conv_factor,IsNull(IM.uom,OL.uom),@order_priority_id,
			  case when OL.part_type = 'J' then 'J' else 'C' end,
	                  OL.order_no,OL.order_ext,OL.line_no,
        	          case when OL.part_type = 'J' then CONVERT(int,OL.part_no) else NULL end,
                	  case when OL.part_type = 'J' then 0 else NULL end
			FROM	ord_list OL
			JOIN	orders_all O on O.order_no = OL.order_no and O.ext = OL.order_ext 
			LEFT OUTER JOIN inv_master IM on IM.part_no = OL.part_no
			WHERE	OL.order_no = @order_no
			AND	OL.order_ext = @order_ext
			and 	OL.line_no = @order_line
	                AND 	OL.ordered > OL.shipped 
--		end

--		IF @part_type = 'C'
--		begin
--			INSERT	sched_order(sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,source_flag,order_no,order_ext,order_line,order_line_kit)
--			SELECT	@sched_id,OLK.location,O.sch_ship_date,OLK.part_no,(OLK.ordered - OLK.shipped) * OLK.conv_factor * OLK.qty_per,OLK.uom,@order_priority_id,'C',OLK.order_no,OLK.order_ext,OLK.line_no,OLK.row_id
--			FROM	ord_list_kit OLK
--			JOIN	orders_all O on O.order_no = OLK.order_no and O.ext = OLK.order_ext 
--			WHERE	OLK.order_no = @order_no
--			AND	OLK.order_ext = @order_ext
--			and 	OLK.line_no = @order_line
--			AND 	OLK.ordered > OLK.shipped
--		end
		END -- status flag = A
	ELSE IF @status_flag = 'D'	
		BEGIN
			INSERT	sched_order(sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,source_flag,order_no,order_ext,order_line,order_line_kit)
			SELECT	@sched_id,OLK.location,O.sch_ship_date,OLK.part_no,(OLK.ordered - OLK.shipped) * OLK.conv_factor * OLK.qty_per,OLK.uom,@order_priority_id,'C',OLK.order_no,OLK.order_ext,OLK.line_no,OLK.row_id
			FROM	ord_list_kit OLK
			JOIN	orders_all O on O.order_no = OLK.order_no and O.ext = OLK.order_ext 
			WHERE	OLK.order_no = @order_no
			AND	OLK.order_ext = @order_ext
			and 	OLK.line_no = @order_line
			AND 	OLK.ordered > OLK.shipped
		END -- status flag = D

	ELSE IF @status_flag = 'B'	
		BEGIN
		INSERT	sched_order(sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,source_flag,order_no,order_ext,order_line,order_line_kit)

		SELECT	@sched_id,OLK.location,O.sch_ship_date,OLK.part_no,(OLK.ordered - OLK.shipped) * OLK.conv_factor * OLK.qty_per,OLK.uom,@order_priority_id,'C',OLK.order_no,OLK.order_ext,OLK.line_no,OLK.row_id

		FROM	ord_list_kit OLK
		JOIN	orders_all O on O.order_no = OLK.order_no and O.ext = OLK.order_ext
		WHERE	OLK.order_no = @order_no
		AND	OLK.order_ext = @order_ext
		AND	OLK.line_no = @order_line
		AND	OLK.row_id = @order_line_kit
		AND	OLK.ordered > OLK.shipped
		END

	ELSE IF @status_flag = 'O'	
		BEGIN
		
		 EXEC adm_set_sched_order 'D',NULL,@sched_order_id  
		END

	ELSE IF @status_flag = 'C' 
		BEGIN
		UPDATE	sched_order
		SET	done_datetime	= O.sch_ship_date,
			part_no		= OL.part_no,
			uom_qty		= (OL.ordered - OL.shipped) * OL.conv_factor,
			uom		= IsNull(IM.uom,OL.uom),
                        location        = OL.location
		FROM sched_order SO
		join orders_all O (nolock) on O.order_no = @order_no AND O.ext = @order_ext
		join ord_list OL (nolock) on OL.order_no = O.order_no and OL.order_ext = O.ext
			AND OL.line_no = @order_line
		left outer join inv_master IM (nolock) on IM.part_no = OL.part_no
		WHERE	SO.sched_order_id = @sched_order_id
		END

	ELSE IF @status_flag = 'K' 
		BEGIN
		UPDATE	sched_order
		SET	done_datetime	= O.sch_ship_date,
			part_no		= OLK.part_no,

			uom_qty		= (OLK.ordered - OLK.shipped) * OLK.conv_factor * OLK.qty_per,

			uom		= IM.uom
		FROM	sched_order SO,
			orders_all O,
			ord_list_kit OLK,
			inv_master IM
		WHERE	SO.sched_order_id = @sched_order_id
		AND	O.order_no = @order_no
		AND	O.ext = @order_ext
		AND	OLK.order_no = @order_no
		AND	OLK.order_ext = @order_ext
		AND	OLK.line_no = @order_line
		AND	OLK.row_id = @order_line_kit
		AND	IM.part_no = OLK.part_no
		END

	ELSE	RaisError 69082 'Illegal status code passed'
	END

ELSE IF @object_flag = 'P'		
	BEGIN
	IF @status_flag = 'N'	
		BEGIN
		EXECUTE fs_build_sched_process @sched_id=@sched_id,@prod_no=@prod_no,@prod_ext=@prod_ext,
                  @qc_no = @transfer_id
		END

	ELSE IF @status_flag = 'C'	
		BEGIN
		EXECUTE fs_build_sched_process @sched_process_id=@sched_process_id, @qc_no = @transfer_id
		END

	ELSE IF @status_flag = 'O'	
		BEGIN
		
		 EXEC adm_set_sched_process 'D',@sched_process_id  
		END

	ELSE IF @status_flag = 'P'	 
		BEGIN
		UPDATE	sched_operation
		SET	complete_qty = PL.pieces,
			discard_qty = PL.scrap_pcs,
			operation_status = CASE PL.oper_status 
			WHEN 'X' THEN 'X'    
			WHEN 'S' THEN 'X' 
			ELSE SO.operation_status 
			END
		FROM	sched_operation SO,
			prod_list PL
		WHERE	SO.sched_operation_id = @sched_operation_id
		AND	PL.prod_no = @prod_no
		AND	PL.prod_ext = @prod_ext
		AND	PL.line_no = @prod_line
                AND     PL.qc_no = @transfer_id

		UPDATE	sched_operation_plan
		SET	usage_qty = CASE PL.plan_qty
                        WHEN 0.0 THEN 0.0
                        ELSE PL.used_qty / PL.plan_qty
			END
		FROM	sched_operation_plan SOP,
			prod_list PL,
                        produce_all P
		WHERE	SOP.sched_operation_id = @sched_operation_id
		AND	SOP.line_no = @prod_line
		AND	PL.prod_no = @prod_no
		AND	PL.prod_ext = @prod_ext
		AND	PL.line_no = @prod_line
                AND     PL.qc_no = @transfer_id

		
		exec fs_calculate_opn_completion @sched_id, @prod_no, @prod_ext, 0, @transfer_id

		END

	ELSE	RaisError 69083 'Illegal status code passed'
	END

ELSE IF @object_flag = 'I'		
	BEGIN
	IF @status_flag = 'N'	
		BEGIN
		INSERT	sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
		SELECT	@sched_id,		
			I.location,		
			I.part_no,		
			getdate(),		
			I.in_stock, 					-- mls 11/5/01 SCR 27837
			-- mls 11/5/01 SCR 27837
--			I.in_stock + I.hold_mfg,
			I.uom,			
			'I'			
		FROM	inventory I
		WHERE	I.location = @location
		AND	I.part_no = @part_no
		END

	ELSE IF @status_flag = 'C'	
		BEGIN
		UPDATE	sched_item
		SET	done_datetime = getdate(),
			uom_qty = I.in_stock 					-- mls 11/5/01 SCR 27837
 			-- mls 11/5/01 SCR 27837
--			uom_qty = I.in_stock + I.hold_mfg
		FROM	sched_item SI,
			inventory I
		WHERE	SI.sched_item_id = @sched_item_id
		AND	I.location = SI.location
		AND	I.part_no = SI.part_no
		END

	ELSE IF @status_flag = 'O'	
		BEGIN
		 EXEC adm_set_sched_item 'D',NULL,@sched_item_id  
		END

	ELSE	RaisError 69084 'Illegal status code passed'

	END

ELSE IF @object_flag = 'O'		
	BEGIN

	IF @status_flag = 'N'	
		BEGIN
		SELECT	@vendor_no=P.vendor_no
		FROM	purchase_all P
		WHERE	P.po_no = @po_no

		if isnull(@purch_lead_flag,'') = ''
		begin
			SELECT	@purchase_lead_flag = SM.purchase_lead_flag
			FROM	sched_model SM
			WHERE	SM.sched_id=@sched_id
		end

		DECLARE schedrel CURSOR LOCAL FOR					
		SELECT	PR.location, PR.part_no,
			CASE PR.confirmed WHEN 'Y' THEN PR.confirm_date ELSE PR.due_date END,
			( PR.quantity
				- CASE	WHEN PR.received > PR.quantity THEN PR.quantity ELSE PR.received END
				+ IsNull((SELECT SUM(R1.quantity) FROM	receipts_all R1
					WHERE	R1.po_no = PR.po_no
					AND	R1.po_line = case when isnull(PR.po_line,0)=0 then R1.po_line else PR.po_line end 	-- mls 5/15/01 SCR 6603
					AND	R1.part_no = PR.part_no AND R1.release_date = PR.release_date
					AND	R1.qc_flag = 'Y'),0.0)) * PR.conv_factor,
			PR.part_type, PR.po_line,					-- mls 5/15/01 SCR 6603
			case when PR.part_type = 'M' then PL.unit_measure else IM.uom end,
			PR.row_id
		FROM	releases PR
		JOIN	pur_list PL on PL.po_no = @po_no and PL.part_no = PR.part_no 
			and PL.line = case when isnull(PR.po_line,0)=0 then PL.line else PR.po_line end 
		LEFT OUTER JOIN inv_master IM on IM.part_no = PR.part_no
		WHERE	PR.po_no = @po_no
		AND	PR.part_type IN ('P','M')
		AND	(	(	PR.status = 'O'
				AND	PR.quantity > PR.received )
			OR	EXISTS (SELECT	1
					FROM	receipts_all R2
					WHERE	R2.po_no = PR.po_no
					AND	R2.po_line = case when isnull(PR.po_line,0)=0 then R2.po_line else PR.po_line end 	-- mls 5/15/01 SCR 6603
					AND	R2.part_no = PR.part_no
					AND	R2.release_date = PR.release_date
					AND	R2.qc_flag = 'Y'))

		OPEN schedrel
		FETCH NEXT FROM schedrel into @location, @part_no, @done_datetime, @qty, @part_type, @po_line, @uom, @release_id

		While @@FETCH_STATUS = 0
		begin									
			-- Compute the lead_datetime to so that when confirmed receipt dates change,
			-- we will have a way to know that something changed.
			SELECT @lead_datetime = @done_datetime
			select @lead_time = 0, @dock_to_stock = 0		-- #12 start
			if @part_type != 'M'
			begin
			  SELECT @lead_time = I.lead_time, @dock_to_stock = I.dock_to_stock, @lead_datetime = NULL
			  FROM inv_list I
			  WHERE I.part_no = @part_no AND I.location = @location
			end
			SELECT @done_datetime = DateAdd (d,(1 * isnull(@dock_to_stock,0)), @done_datetime)
			SELECT @lead_datetime = DateAdd (d,(-1 * isnull(@dock_to_stock,0)),@done_datetime)
			IF @purchase_lead_flag = 'S'
			BEGIN
  			  select @lead_time = IsNull(@lead_time, 0)
			  -- rev 4:  add dock_to_stock to @done_datetime, 
			  --	   subtract lead_time and d_to_s to get lead_timedate
			  SELECT @lead_datetime = DateAdd (d,(-1 * @lead_time),@done_datetime)
			END							-- #12 end
			
			INSERT	sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
			VALUES(@sched_id,@location,@part_no,@done_datetime,@qty,IsNull(@uom,''),'O')

			SELECT	@sched_item_id=@@identity

			
			INSERT	sched_purchase(sched_item_id,lead_datetime,vendor_key,po_no,release_id)	
			VALUES(@sched_item_id,@lead_datetime,@vendor_no,@po_no,@release_id)

			
			FETCH NEXT FROM schedrel into @location, @part_no, @done_datetime, @qty, @part_type, @po_line, @uom, @release_id
		END -- fetch status = 0

		CLOSE schedrel
		deallocate schedrel
		END

	ELSE IF @status_flag = 'A'	
		BEGIN

		SELECT	@location = PR.location, @part_no = PR.part_no,
			@done_datetime = CASE PR.confirmed WHEN 'Y' THEN PR.confirm_date ELSE PR.due_date END,
			@qty = ( PR.quantity
				- CASE	WHEN PR.received > PR.quantity THEN PR.quantity ELSE PR.received END
				+ IsNull((SELECT SUM(R1.quantity) FROM	receipts_all R1
					WHERE	R1.po_no = PR.po_no
					AND	R1.po_line = case when isnull(PR.po_line,0)=0 then R1.po_line else PR.po_line end 	-- mls 5/15/01 SCR 6603
					AND	R1.part_no = PR.part_no AND R1.release_date = PR.release_date
					AND	R1.qc_flag = 'Y'),0.0)) * PR.conv_factor,
			@part_type = PR.part_type, @po_line = PR.po_line,				-- mls 5/15/01 SCR 6603
			@uom = case when PR.part_type = 'M' then PL.unit_measure else IM.uom end,
			@release_id = PR.row_id
		FROM	releases PR
		JOIN	pur_list PL on PL.po_no = @po_no and PL.part_no = PR.part_no 
			and PL.line = case when isnull(PR.po_line,0)=0 then PL.line else PR.po_line end 
			and PL.type in ('P','M')
		LEFT OUTER JOIN inv_master IM on IM.part_no = PR.part_no
		WHERE	PR.po_no = @po_no and PR.part_no = @part_no 
		AND	PR.part_type IN ('P','M') AND PR.row_id = @release_id
		AND	(	(	PR.status = 'O'
				AND	PR.quantity > PR.received )
			OR	EXISTS (SELECT	1
					FROM	dbo.receipts_all R2
					WHERE	R2.po_no = PR.po_no
					AND	R2.po_line = case when isnull(PR.po_line,0)=0 then R2.po_line else PR.po_line end 	-- mls 5/15/01 SCR 6603
					AND	R2.part_no = PR.part_no
					AND	R2.release_date = PR.release_date
					AND	R2.qc_flag = 'Y'))

		if @@rowcount <> 0
		begin
			if isnull(@purch_lead_flag,'') = ''
			begin
				SELECT	@purchase_lead_flag = SM.purchase_lead_flag
				FROM	sched_model SM
				WHERE	SM.sched_id=@sched_id
			end

			SELECT @lead_datetime = @done_datetime
			select @lead_time = 0, @dock_to_stock = 0		-- #12 start
			if @part_type != 'M'
			begin
			  SELECT @lead_time = I.lead_time, @dock_to_stock = I.dock_to_stock, @lead_datetime = NULL
			  FROM inv_list I
			  WHERE I.part_no = @part_no AND I.location = @location
			end
			SELECT @done_datetime = DateAdd (d,(1 * isnull(@dock_to_stock,0)), @done_datetime)
			SELECT @lead_datetime = DateAdd (d,(-1 * isnull(@dock_to_stock,0)),@done_datetime)
			IF @purchase_lead_flag = 'S'
			BEGIN
  			  select @lead_time = IsNull(@lead_time, 0)
			  -- rev 4:  add dock_to_stock to @done_datetime, 
			  --	   subtract lead_time and d_to_s to get lead_timedate
			  SELECT @lead_datetime = DateAdd (d,(-1 * @lead_time),@done_datetime)
			END							-- #12 end
			INSERT	sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
			VALUES(@sched_id,@location,@part_no,@done_datetime,@qty,IsNull(@uom,''),'O')

		SELECT	@rowcount=@@rowcount,
			@sched_item_id=@@identity
			
		IF @rowcount > 0		
			INSERT	sched_purchase(sched_item_id,vendor_key,po_no,release_id,lead_datetime)
			SELECT	@sched_item_id,		
				P.vendor_no,		
				@po_no,			
				@release_id,
			        @lead_datetime
			FROM	dbo.purchase_all AS P
			WHERE	P.po_no = @po_no
		end -- @@rowcount <> 0
		END

	ELSE IF @status_flag = 'C'	
		BEGIN
		SELECT	@location = PR.location, @part_no = PR.part_no,
			@done_datetime = CASE PR.confirmed WHEN 'Y' THEN PR.confirm_date ELSE PR.due_date END,
			@qty = ( PR.quantity
				- CASE	WHEN PR.received > PR.quantity THEN PR.quantity ELSE PR.received END
				+ IsNull((SELECT SUM(R1.quantity) FROM	receipts_all R1
					WHERE	R1.po_no = PR.po_no
					AND	R1.po_line = case when isnull(PR.po_line,0)=0 then R1.po_line else PR.po_line end 	-- mls 5/15/01 SCR 6603
					AND	R1.part_no = PR.part_no AND R1.release_date = PR.release_date
					AND	R1.qc_flag = 'Y'),0.0)) * PR.conv_factor,
			@part_type = PR.part_type, @po_line = PR.po_line,				-- mls 5/15/01 SCR 6603
			@uom = case when PR.part_type = 'M' then PL.unit_measure else IM.uom end,
			@release_id = PR.row_id,
			@vendor_no = P.vendor_no
		FROM	releases PR
		JOIN	pur_list PL on PL.po_no = @po_no and PL.part_no = PR.part_no 
			and PL.line = case when isnull(PR.po_line,0)=0 then PL.line else PR.po_line end 
			and PL.type in ('P','M')
		JOIN	purchase_all P on P.po_no = PR.po_no
		LEFT OUTER JOIN inv_master IM on IM.part_no = PR.part_no
		WHERE	PR.po_no = @po_no
		AND	PR.part_no = @part_no
		AND	PR.part_type IN ('P','M')
		AND	PR.row_id = @release_id

		if @@rowcount > 0 
		begin
			if isnull(@purch_lead_flag,'') = ''
			begin
				SELECT	@purchase_lead_flag = SM.purchase_lead_flag
				FROM	sched_model SM
				WHERE	SM.sched_id=@sched_id
			end

			SELECT @lead_datetime = @done_datetime
			select @lead_time = 0, @dock_to_stock = 0		-- #12 start
			if @part_type != 'M'
			begin
			  SELECT @lead_time = I.lead_time, @dock_to_stock = I.dock_to_stock, @lead_datetime = NULL
			  FROM inv_list I
			  WHERE I.part_no = @part_no AND I.location = @location
			end
			SELECT @done_datetime = DateAdd (d,(1 * isnull(@dock_to_stock,0)), @done_datetime)
			SELECT @lead_datetime = DateAdd (d,(-1 * isnull(@dock_to_stock,0)),@done_datetime)
			IF @purchase_lead_flag = 'S'
			BEGIN
  			  select @lead_time = IsNull(@lead_time, 0)
			  -- rev 4:  add dock_to_stock to @done_datetime, 
			  --	   subtract lead_time and d_to_s to get lead_timedate
			  SELECT @lead_datetime = DateAdd (d,(-1 * @lead_time),@done_datetime)
			END							-- #12 end

		UPDATE	sched_item
		SET	done_datetime =	@done_datetime,
			uom_qty = 	@qty
		WHERE	sched_item_id = @sched_item_id
		AND	((done_datetime <> @done_datetime)
			OR	(uom_qty <> @qty))

		UPDATE	SP
		SET	vendor_key = @vendor_no,
			lead_datetime = @lead_datetime
		FROM	sched_item SI, sched_purchase SP
		WHERE	SI.sched_item_id = @sched_item_id 
		and	SP.sched_item_id = SI.sched_item_id
		AND	(SP.vendor_key <> @vendor_no or
			SP.lead_datetime <> @lead_datetime)
		end
		END

	ELSE IF @status_flag = 'R'	
		BEGIN
		INSERT	sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
		SELECT	@sched_id,			
			RD.location,			
			RD.part_no,			
			RD.demand_date,			
			RD.qty,				
			RD.uom,				
			'R'				
		FROM	resource_demand_group RD
		WHERE	RD.row_id = @resource_demand_id

		SELECT	@sched_item_id=@@identity
					
		INSERT	sched_purchase(sched_item_id,resource_demand_id)
		VALUES (@sched_item_id,@resource_demand_id)

		END

	ELSE IF @status_flag = 'O'	
		BEGIN
		 EXEC adm_set_sched_item 'D',NULL,@sched_item_id  
		END

	ELSE	RaisError 69085 'Illegal status code passed'
	END

ELSE IF @object_flag = 'X'		
	BEGIN -- BEGIN 1
	
	if @order_priority_id is NULL
	begin
	SELECT	@order_priority_id=OP.order_priority_id
	FROM	order_priority OP
	WHERE	OP.usage_flag = 'D'
	end

	IF @status_flag = 'N'	
		BEGIN -- BEGIN 2
		
		SELECT	@beg_location = case when X.status between 'N' and 'Q' then X.from_loc else '' end,
			@end_location = case when X.status between 'N' and 'R' then X.to_loc else '' end,
			@beg_datetime = X.sch_ship_date,
			@end_datetime = X.req_ship_date
		FROM	xfers_all X
		WHERE	X.xfer_no = @transfer_id


		
		IF EXISTS(SELECT 1 FROM sched_location SL WHERE SL.sched_id = @sched_id AND SL.location = @beg_location)
			BEGIN -- BEGIN 3
			
			
			IF EXISTS(SELECT 1 FROM sched_location SL WHERE SL.sched_id = @sched_id AND SL.location = @end_location)
				BEGIN -- BEGIN 4
				
				INSERT	sched_transfer(sched_id,location,move_datetime,source_flag,xfer_no,xfer_line)
				SELECT	@sched_id,@beg_location,@beg_datetime,'R',@transfer_id,XL.line_no
				FROM	xfer_list XL
				WHERE	XL.xfer_no = @transfer_id

				
				INSERT	sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag,sched_transfer_id)
				SELECT	@sched_id,@end_location,XL.part_no,@end_datetime,XL.ordered,XL.uom,'X',ST.sched_transfer_id
				FROM	sched_transfer ST
				JOIN	xfer_list XL on XL.xfer_no = ST.xfer_no and XL.line_no = ST.xfer_line
				WHERE	ST.sched_id = @sched_id AND ST.xfer_no = @transfer_id

				INSERT	sched_order
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
					order_line
					)
				SELECT	@sched_id,		
					@beg_location,		
					@beg_datetime,		
					XL.part_no,		
					XL.ordered,		
					XL.uom,			
					@order_priority_id,	
					'T',			
					XL.xfer_no,		
					XL.line_no		
				FROM	xfer_list XL
				WHERE	XL.xfer_no = @transfer_id

				DECLARE c_purchase CURSOR FOR
				SELECT	XL.part_no,
					XL.ordered,
					XL.uom,
					XL.line_no
				FROM	xfer_list XL
				WHERE	XL.xfer_no = @transfer_id

				OPEN c_purchase

				FETCH c_purchase INTO @part_no,@qty,@uom,@transfer_line
				WHILE @@fetch_status = 0
					BEGIN -- BEGIN 8
					
					INSERT	sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
					VALUES(@sched_id,@end_location,@part_no,@end_datetime,@qty,@uom,'T')

					
					SELECT	@sched_item_id=@@identity

					
					INSERT	sched_purchase(sched_item_id,xfer_no,xfer_line)
					VALUES(@sched_item_id,@transfer_id,@transfer_line)

					
					FETCH c_purchase INTO @part_no,@qty,@uom,@transfer_line
					END -- END 8

				CLOSE c_purchase
				DEALLOCATE c_purchase
				END -- END 4
			ELSE
				BEGIN -- BEGIN 5
				
				
				INSERT	sched_order
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
					order_line
					)
				SELECT	@sched_id,		
					@beg_location,		
					@beg_datetime,		
					XL.part_no,		
					XL.ordered,		
					XL.uom,			
					@order_priority_id,	
					'T',			
					XL.xfer_no,		
					XL.line_no		
				FROM	xfer_list XL
				WHERE	XL.xfer_no = @transfer_id
				END -- END 5
			END -- END 3
		ELSE
			BEGIN -- BEGIN 6
			
			
			IF EXISTS(SELECT * FROM sched_location SL WHERE SL.sched_id = @sched_id AND SL.location = @end_location)
				BEGIN -- BEGIN 7
				
				DECLARE c_purchase CURSOR FOR
				SELECT	XL.part_no,
					case when XL.status between 'N' and 'Q' then XL.ordered else XL.shipped end,
					XL.uom,
					XL.line_no
				FROM	xfer_list XL
				WHERE	XL.xfer_no = @transfer_id

				OPEN c_purchase

				
				FETCH c_purchase INTO @part_no,@qty,@uom,@transfer_line

				WHILE @@fetch_status = 0
					BEGIN -- BEGIN 8
					
					INSERT	sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
					VALUES(@sched_id,@end_location,@part_no,@end_datetime,@qty,@uom,'T')

					
					SELECT	@sched_item_id=@@identity

					
					INSERT	sched_purchase(sched_item_id,xfer_no,xfer_line)
					VALUES(@sched_item_id,@transfer_id,@transfer_line)

					
					FETCH c_purchase INTO @part_no,@qty,@uom,@transfer_line
					END -- END 8

				CLOSE c_purchase

				DEALLOCATE c_purchase
				END -- END 7
			ELSE
				BEGIN -- BEGIN 9
				
				RaisError 69431 'Transfer does not affect scenario. It neither leaves or enters this scenario.'
				END -- END 9
			END -- END 6
		END -- END 2
	ELSE IF @status_flag IN ('A','C','O')	
		BEGIN -- BEGIN 10
		IF @status_flag IN ('C','O')	
			BEGIN -- BEGIN 11
			
			IF @sched_order_id != 0
			   EXEC adm_set_sched_order 'DT',NULL,@sched_order_id  
			
			IF @sched_item_id != 0
			   EXEC adm_set_sched_item 'DT',NULL,@sched_item_id  
			
			IF @sched_transfer_id != 0
			begin
			   EXEC adm_set_sched_item 'DU',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@sched_transfer_id  

			  if (@@version like '%7.0%')
                            DELETE sched_transfer_item where sched_transfer_id = @sched_transfer_id

			  DELETE sched_transfer WHERE sched_transfer_id = @sched_transfer_id
			end
			END -- END 11

		IF @status_flag IN ('A','C')	
			BEGIN -- BEGIN 12
			
			SELECT	@beg_location = case when X.status between 'N' and 'Q' then X.from_loc else '' end,
				@end_location = case when X.status between 'N' and 'R' then X.to_loc else '' end,
			        @beg_datetime = X.sch_ship_date,
			        @end_datetime = X.req_ship_date
        		FROM	xfers_all X
	        	WHERE	X.xfer_no = @transfer_id

			SELECT	@part_no=XL.part_no,
				@qty=case when XL.status between 'N' and 'Q' then XL.ordered else XL.shipped end,
				@uom=XL.uom
			FROM	xfer_list XL
			WHERE	XL.xfer_no = @transfer_id and XL.line_no = @transfer_line

			
			IF EXISTS(SELECT * FROM sched_location SL WHERE SL.sched_id = @sched_id AND SL.location = @beg_location)
				BEGIN -- BEGIN 13
				
				
				IF EXISTS(SELECT * FROM sched_location SL WHERE SL.sched_id = @sched_id AND SL.location = @end_location)
					BEGIN -- BEGIN 14
					
					INSERT	sched_transfer(sched_id,location,move_datetime,source_flag,xfer_no,xfer_line)
					VALUES	(@sched_id,@beg_location,@beg_datetime,'R',@transfer_id,@transfer_line)
	
					
					SELECT	@sched_transfer_id=@@identity
	
					
					INSERT	sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag,sched_transfer_id)
					VALUES	(@sched_id,@end_location,@part_no,@end_datetime,@qty,@uom,'X',@sched_transfer_id)

					INSERT	sched_order
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
						order_line
						)
					VALUES	(
						@sched_id,		
						@beg_location,		
						@beg_datetime,		
						@part_no,		
						@qty,			
						@uom,			
						@order_priority_id,	
						'T',			
						@transfer_id,		
						@transfer_line		
						)

					INSERT	sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
					VALUES	(@sched_id,@end_location,@part_no,@end_datetime,@qty,@uom,'T')
	
					
					SELECT	@sched_item_id=@@identity
	
					
					INSERT	sched_purchase(sched_item_id,xfer_no,xfer_line)
					VALUES(@sched_item_id,@transfer_id,@transfer_line)

					END -- END 14
				ELSE
					BEGIN -- BEGIN 15
					
					
					INSERT	sched_order
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
						order_line
						)
					VALUES	(
						@sched_id,		
						@beg_location,		
						@beg_datetime,		
						@part_no,		
						@qty,			
						@uom,			
						@order_priority_id,	
						'T',			
						@transfer_id,		
						@transfer_line		
						)
					END -- END 15
				END -- END 13
			ELSE
				BEGIN -- BEGIN 16
				
				
				IF EXISTS(SELECT * FROM sched_location SL WHERE SL.sched_id = @sched_id AND SL.location = @end_location)
					BEGIN -- BEGIN 17
					
					
					INSERT	sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
					VALUES	(@sched_id,@end_location,@part_no,@end_datetime,@qty,@uom,'T')
	
					
					SELECT	@sched_item_id=@@identity
	
					
					INSERT	sched_purchase(sched_item_id,xfer_no,xfer_line)
					VALUES(@sched_item_id,@transfer_id,@transfer_line)
					END -- END 17
				ELSE
					BEGIN -- BEGIN 18
					
					RaisError 69432 'Transfer does not affect scenario. It neither leaves or enters this scenario.'
					END -- END 18
				END -- END 16
			END -- END 10
		END -- END 12
       ELSE	RaisError 69086 'Illegal status code passed'
   END -- END 1
ELSE IF @object_flag = 'F'
        BEGIN
        IF @status_flag = 'X'   -- Deleted or past-due forecast to be removed
	   EXEC adm_set_sched_order 'D',NULL,@sched_order_id  
        ELSE IF @status_flag = 'C' -- Forecast quantity changed
            UPDATE sched_order SET uom_qty = @forecast_qty WHERE sched_order_id = @sched_order_id AND part_no = @part_no AND location = @location AND done_datetime = @forecast_demand_date AND source_flag = 'F'       
            ELSE IF @status_flag = 'N' -- New forecast
                BEGIN
		if @order_priority_id is NULL
		begin
                SELECT	@order_priority_id=OP.order_priority_id
                FROM	order_priority OP
                WHERE	OP.usage_flag = 'D'
                IF @@rowcount <> 1
		    BEGIN
		    RaisError 64049 'Unable to determine default order priority'
		    RETURN
		    END
		end
        
               INSERT sched_order(sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,source_flag,action_flag)
               VALUES (@sched_id,@location,@forecast_demand_date,@part_no,@forecast_qty,@forecast_uom,@order_priority_id,'F','?')
               END
	END
ELSE	RaisError 69080 'Illegal category code passed'

RETURN
END


GO
GRANT EXECUTE ON  [dbo].[fs_update_schedule] TO [public]
GO
