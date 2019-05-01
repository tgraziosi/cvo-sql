SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*  
***** Object:  StoredProcedure [dbo].[CVO_auto_pack_out_sp]    Script Date: 09/01/2010  *****  
SED009 -- Order Pick to Auto Pack Out       
Object:      Procedure CVO_auto_pack_out_sp    
Source file: CVO_auto_pack_out_sp.sql  
Author:   Jesus Velazquez  
Created:  09/01/2010  
Function:      
Modified:      
Calls:      
Called by:   WMS74 -- Console -- Pick  
Copyright:   Epicor Software 2010.  All rights reserved. */    
-- v1.1 Add in processing for all orders not just RX 
-- v1.2 CT 04/04/2014 - Issue #572 - Combine consolidated orders into the same carton 
-- v1.3 CB 23/04/2015 - Performance Changes
-- v1.4 CB 20/04/2016 - #1584 - Add discount amount
-- v1.5 CB 05/12/2018 - #1687 Box Type Update  
-- v1.6 CB 30/01/2018 - Fix for v1.5
-- v1.7 CB 25/02/2019 - Performance
  
CREATE PROCEDURE [dbo].[CVO_auto_pack_out_sp]	@order_no INT,    
												@order_ext INT,   
												@station_id INT      
AS   
BEGIN  
	DECLARE	@carton_no    INT,    
			@scanned_index   INT,    
			@is_one_order_per_ctn CHAR(1),    
			@is_packing    CHAR(1),    
			@is_auto_qty   CHAR(1),    
			@is_cube_active   CHAR(1),    
			@is_using_tote_bins  CHAR(1),    
			@auto_lot    VARCHAR(25),    
			@auto_bin    VARCHAR(12),    
			@user_id    VARCHAR(50),    
			@tote_bin    VARCHAR(12),  
			@carton_code   VARCHAR(10),  
			@pack_type    VARCHAR(10),  
			@total_cartons   INT,  
			@tran_id    INT,  
			@part_no    VARCHAR(30),  
			@kit_item    VARCHAR(30),  
			@line_no    INT,  
			@location    VARCHAR(10),  
			@lot_ser    VARCHAR(25),  
			@bin_no     VARCHAR(12),  
			@serial_no    VARCHAR(40),  
			@version    VARCHAR(40),  
			@qty     numeric(20,8),  
			@uom     VARCHAR(10),  
			@err_msg    VARCHAR(255),  
			@user_category   varchar(10), -- v1.1       
			@consolidation_no INT, -- v1.2
			@pack_row_id	int, -- v1.5
			@box_id			int, -- v1.5
			@last_box_id	int, -- v1.5
			@pre_pack_qty	decimal(20,8), -- v1.5
			@is_kit			char(1), -- v1.5
			@pp_row_id			int -- v1.6

		DECLARE	@row_id			int,
				@last_row_id	int


	-- v1.5 Start
	IF OBJECT_ID('tempdb..#pre_packing') IS NOT NULL
		DROP TABLE #pre_packing

	CREATE TABLE #pre_packing (
		pack_row_id			int IDENTITY(1,1),
		line_no				int,
		part_no				varchar(30),
		ordered				decimal(20,8),
		pack_qty			decimal(20,8),
		box_type			varchar(20),
		box_id				int,
		carton_no			int,
		kit_item			char(1),
		pp_row_id			int) -- v1.6

	SELECT @location = location FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext  
	SET @is_one_order_per_ctn = 'Y'  
  
	IF OBJECT_ID('tempdb..#temp_pps_carton_display') IS NOT NULL   
		DROP TABLE #temp_pps_carton_display  
  
	IF OBJECT_ID('tempdb..#temp_pps_kit_display')  IS NOT NULL   
		DROP TABLE #temp_pps_kit_display  
    
	IF OBJECT_ID('tempdb..#serial_no')     IS NOT NULL  
		DROP TABLE #serial_no  
    
	CREATE TABLE #temp_pps_carton_display (
		order_no INT     NOT NULL,                   
		order_ext   INT     NOT NULL,                   
		line_no     INT     NOT NULL,                   
		part_no     VARCHAR(30)   NOT NULL,  
		[description]   VARCHAR(255)  NULL,  
		ordered     decimal(20, 8)  NOT NULL,  
		picked      decimal(20, 8)  NOT NULL,  
		total_packed    decimal(20, 8) NOT NULL,  
		carton_packed decimal(20, 8) NOT NULL,  
		con_rec      int NULL,                   
		con_ref      int NULL,    
		con_qty      decimal(20,8),  
		con_packed_qty decimal(20,8),  
		con_carton_qty decimal(20,8))     
     
	CREATE TABLE #temp_pps_kit_display (
		order_no  INT    NOT NULL,  
		order_ext       INT    NOT NULL,  
		line_no         INT    NOT NULL,  
		part_no         VARCHAR(30)  NOT NULL,  
		sub_kit_part_no VARCHAR(30)   NULL,  
		[description]   VARCHAR(255)  NULL,  
		qty_per_kit     decimal(20, 8) NOT NULL,  
		ordered         decimal(20, 8) NOT NULL,  
		picked          decimal(20, 8) NOT NULL,  
		total_packed    decimal(20, 8) NOT NULL,  
		carton_packed   decimal(20, 8) NOT NULL)  
  
	SELECT	@user_id = who    
	FROM	#temp_who   
   
	CREATE TABLE #serial_no (
		serial_no VARCHAR(40) NOT NULL,  
		serial_raw VARCHAR(40) NOT NULL)  

	CREATE TABLE #parts_cursor (
		row_id		int IDENTITY(1,1),
		part_no		varchar(30) NULL,
		kit_item	varchar(30) NULL,
		line_no		int NULL,
		qty			decimal(20,8))	
	-- v1.5 End
  
	-- v1.1 Start  
	-- IF EXISTS(SELECT user_category FROM orders WHERE order_no = @order_no AND ext = @order_ext AND user_category <> 'RX')  
	--  RETURN  
	SELECT @user_category = user_category FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
	-- v1.1 End  
   
	-- START v1.2
	/*
	IF EXISTS(SELECT carton_no FROM tdc_carton_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)  
		SELECT @carton_no = carton_no FROM tdc_carton_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext  
	ELSE  
		EXECUTE @carton_no = [dbo].[tdc_get_serialno]   
	*/  

	-- v1.5 Start
	-- Check if record exists in the pre-packing table
	IF EXISTS (SELECT 1 FROM cvo_pre_packaging (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
	BEGIN

		SET @consolidation_no = NULL
		SELECT	@consolidation_no = cons_no
		FROM	cvo_pre_packaging (NOLOCK) 
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext 
		AND		order_type = 'S'

		INSERT	#pre_packing (line_no, part_no, pack_qty, box_type, box_id, carton_no, kit_item, pp_row_id) -- v1.6
		SELECT	line_no, part_no, pack_qty, box_type, box_id, carton_no, kit_item, row_id -- v1.6
		FROM	cvo_pre_packaging (NOLOCK) 
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext 
		AND		order_type = 'S'
		AND		pack_qty > 0 -- v1.6
		ORDER BY box_id, line_no

		CREATE INDEX #pre_packing_ind0 ON #pre_packing(pack_row_id) -- v1.7

		SET @pack_row_id = 0
		SET @last_box_id = 0

		WHILE (1 = 1)
		BEGIN
			SELECT	TOP 1 @pack_row_id = pack_row_id,
					@line_no = line_no,
					@part_no = part_no,
					@carton_code = box_type,
					@box_id = box_id,
					@pre_pack_qty = pack_qty,
					@is_kit = kit_item,
					@pp_row_id = pp_row_id -- v1.6
			FROM	#pre_packing
			WHERE	pack_row_id > @pack_row_id
			ORDER BY pack_row_id ASC

			IF (@@ROWCOUNT = 0)
				BREAK

			SET @carton_no = 0

			IF (@consolidation_no = 0)
			BEGIN
				SELECT	@carton_no = carton_no
				FROM	cvo_pre_packaging (NOLOCK) 
				WHERE	order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		order_type = 'S'
				AND		box_id = @box_id
-- v1.6			AND		line_no = @line_no
				AND		carton_no <> 0
			END
			ELSE
			BEGIN
				SELECT	@carton_no = carton_no
				FROM	cvo_pre_packaging (NOLOCK) 
				WHERE	cons_no = @consolidation_no
				AND		order_type = 'S'
				AND		box_id = @box_id
-- v1.6			AND		line_no = @line_no
				AND		carton_no <> 0
			END

			IF (@box_id <> @last_box_id)
			BEGIN

				IF (ISNULL(@carton_no,0) = 0)
				BEGIN
					EXEC @carton_no = [dbo].[tdc_get_serialno]
				END

				SET @last_box_id = @box_id				
			END 

			-- v1.6 Start
			UPDATE	cvo_pre_packaging WITH (ROWLOCK)
			SET		carton_no = @carton_no
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		box_id = @box_id
			-- v1.6 End

			EXEC tdc_pps_grid_display	@is_one_order_per_ctn,   
										@carton_no,   
										@order_no,   
										@order_ext  


			SET @scanned_index   = 14       
			SET @is_one_order_per_ctn = 'Y'  
			SET @is_packing    = 'Y'  
		    
			SELECT	@is_auto_qty = ISNULL(auto_qty,'N')  
			FROM	tdc_pack_station_tbl(NOLOCK)    
			WHERE	CAST(station_id  AS INT) = @station_id  
		    
			SET @is_cube_active   = 'Y'  
			SET @is_using_tote_bins  = 'N'  
			SET @tote_bin    = ''  
			SET @pack_type    = ''  
			SET @total_cartons   = 0  
			SET @tran_id    = 0  
			SET @kit_item    = ''  
			SET @serial_no    = ''  
			SET @version    = ''  
			SET @err_msg    = NULL   

			SET @qty = 0

			IF (@is_kit = 'N')
			BEGIN
				SELECT	@qty = picked - total_packed   
				FROM	#temp_pps_carton_display   
				WHERE	order_no  = @order_no 
				AND		order_ext  = @order_ext 
				AND		total_packed < ordered  
				AND		picked > total_packed 
				AND		line_no = @line_no 
			END
			ELSE
			BEGIN
				SELECT	@qty = picked - total_packed   
				FROM	#temp_pps_kit_display   
				WHERE	order_no  = @order_no 
				AND		order_ext  = @order_ext 
				AND		total_packed < ordered  
				AND		picked > total_packed 
				AND		line_no = @line_no 
				AND		part_no = @part_no

				SET @kit_item = @part_no
	
				SELECT	@part_no = part_no
				FROM	#temp_pps_carton_display   
				WHERE	order_no  = @order_no 
				AND		order_ext  = @order_ext 
				AND		line_no = @line_no 
			END
		
			IF (@qty <= 0)
				CONTINUE

			IF (@qty > @pre_pack_qty)
				SET @qty = @pre_pack_qty			
   
			SET @auto_lot = ''  
			IF EXISTS(SELECT auto_lot_flag, auto_lot FROM tdc_inv_master (NOLOCK) WHERE auto_lot IS NOT NULL AND part_no = @part_no)  
			BEGIN  
				SELECT	@auto_lot = auto_lot   
				FROM	tdc_inv_master (NOLOCK)   
				WHERE	auto_lot IS NOT NULL 
				AND		part_no = @part_no  
			END  
			ELSE  
			BEGIN  
				IF EXISTS(SELECT active, value_str FROM tdc_config (NOLOCK)  WHERE [function] = 'auto_lot' AND active = 'Y' AND value_str <> '')  
					SELECT	@auto_lot = value_str   
					FROM	tdc_config (NOLOCK)    
					WHERE	[function] = 'auto_lot'
					AND		active  = 'Y'  
					AND		value_str <> ''  
			END  
	  
			--find default bin_no   
			SET @auto_bin = ''   
			IF EXISTS(SELECT active, value_str FROM tdc_config (NOLOCK)  WHERE [function] = 'auto_Bin' AND active = 'Y' AND value_str <> '')  
			BEGIN  
				SELECT	@auto_bin = value_str   
				FROM	tdc_config (NOLOCK)    
				WHERE	[function] = 'auto_Bin'
				AND		active  = 'Y'  
				AND		value_str <> ''  
			END  
	  
			--if exists default lot then assing it to @lot_ser, else go to tdc_dist_item_pick table  
			IF @auto_lot <> ''  
				SET @lot_ser = @auto_lot -- depende de @auto_lot  
			ELSE  
				SELECT	@lot_ser = lot_ser  
				FROM	tdc_dist_item_pick (NOLOCK)   
				WHERE	order_no = @order_no  
				AND		order_ext = @order_ext 
				AND		part_no  = @part_no  
				AND		line_no  = @line_no  
	  
			--if exists default bin_no then assing it to @auto_bin, else go to tdc_dist_item_pick table  
			IF @auto_bin <> ''  
				SET @bin_no =  @auto_bin --depende de @auto_bin  
			ELSE  
				SELECT	@bin_no = bin_no  
				FROM	tdc_dist_item_pick (NOLOCK)   
				WHERE	order_no = @order_no  
				AND		order_ext = @order_ext 
				AND		part_no  = @part_no  
				AND		line_no  = @line_no  
       
			SELECT	@uom = uom  
			FROM	inv_master (NOLOCK)  
			WHERE   part_no  = @part_no    
     
			EXEC tdc_pps_scan_sp @scanned_index       , @is_one_order_per_ctn, @is_packing       , @is_auto_qty     ,  
					@is_cube_active      , @is_using_tote_bins  , @auto_lot              , @auto_bin        ,  
					@user_id          , @station_id   , @carton_no output      , @tote_bin output ,  
					@carton_code output  , @pack_type output    , @order_no output       , @order_ext output,  
					@total_cartons output, @tran_id output      , @part_no output        , @kit_item output ,  
					@line_no output   , @location output     , @lot_ser output        , @bin_no output   ,  
					@serial_no output  , @version output      , @qty output            ,@uom output       , @err_msg output  

			-- v1.6 Start
			UPDATE	cvo_pre_packaging WITH (ROWLOCK)
			SET		pack_qty = pack_qty - @qty
			WHERE	row_id = @pp_row_id
			-- v1.6 End
	          
		END	
	END
	ELSE
	BEGIN 	
		-- Is there a carton for this order
		SET @carton_no = NULL
		IF EXISTS(SELECT carton_no FROM tdc_carton_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
		BEGIN
			SELECT @carton_no = carton_no FROM tdc_carton_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S'
		END
		ELSE
		BEGIN
			-- Is the order consolidated, if so is there a carton for any order in that set
			IF EXISTS (SELECT 1 FROM dbo.cvo_masterpack_consolidation_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
			BEGIN
				SELECT	@consolidation_no = consolidation_no 
				FROM	dbo.cvo_masterpack_consolidation_det (NOLOCK) 
				WHERE	order_no = @order_no 
				AND		order_ext = @order_ext

				SELECT	TOP 1 @carton_no = a.carton_no
				FROM	dbo.tdc_carton_tx a (NOLOCK) 
				INNER JOIN dbo.cvo_masterpack_consolidation_det b (NOLOCK) 
				ON		a.order_no = b.order_no 
				AND		a.order_ext = b.order_ext
				WHERE	a.order_type = 'S'
				AND		b.consolidation_no = @consolidation_no
			END
		END

		-- No carton found, create a new one
		IF @carton_no IS NULL
		BEGIN
			EXECUTE @carton_no = [dbo].[tdc_get_serialno]
		END
		-- END v1.2
     
		EXEC tdc_pps_grid_display	@is_one_order_per_ctn,   
									@carton_no,   
									@order_no,   
									@order_ext  
	  
		SET @scanned_index   = 14       
		SET @is_one_order_per_ctn = 'Y'  
		SET @is_packing    = 'Y'  
	    
		SELECT	@is_auto_qty = ISNULL(auto_qty,'N')  
		FROM	tdc_pack_station_tbl(NOLOCK)    
		WHERE	CAST(station_id  AS INT) = @station_id  
	    
		SET @is_cube_active   = 'Y'  
		SET @is_using_tote_bins  = 'N'  
		SET @tote_bin    = ''  
		SET @carton_code   = 'SMALL_BOX'  
		SET @pack_type    = ''  
		SET @total_cartons   = 0  
		SET @tran_id    = 0  
		SET @kit_item    = ''  
		SET @serial_no    = ''  
		SET @version    = ''  
		SET @err_msg    = NULL   
	  
		-- v1.1 Start  
		IF (@user_category <> 'RX')  
		BEGIN  
			SELECT @carton_code = value_str FROM tdc_config (NOLOCK)  WHERE [function] = 'STOCK_ORDER_PACKAGE_CODE' AND active = 'Y'  
			IF @carton_code IS NULL   
				SET @carton_code = 'QC'  
		END   
		-- v1.1 End  
	    


		INSERT	#parts_cursor (part_no, kit_item, line_no, qty)
		-- v1.3 DECLARE parts_cursor CURSOR FOR   
		SELECT	part_no,          
				'', -- v1.3 AS kit_item,  
				line_no,    
				picked - total_packed   
		FROM	#temp_pps_carton_display   
		WHERE	order_no  = @order_no 
		AND		order_ext  = @order_ext 
		AND		total_packed < ordered  
		AND		picked > total_packed  
		UNION  
		SELECT	c.part_no,   
				k.part_no, -- v1.3 AS kit_item,   
				c.line_no,   
				k.picked - k.total_packed  
		FROM	#temp_pps_carton_display c, #temp_pps_kit_display k  
		WHERE	c.order_no     = k.order_no     
		AND		c.order_ext    = k.order_ext    
		AND     c.line_no      = k.line_no      
		AND		k.order_no    = @order_no     
		AND		k.order_ext    = @order_ext     
		AND		k.total_packed < k.ordered  
		AND		k.picked    > k.total_packed     
	     
		-- v1.3 OPEN parts_cursor  
		-- v1.3 FETCH NEXT FROM parts_cursor   
		-- v1.3 INTO @part_no, @kit_item, @line_no, @qty  

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@part_no = part_no,
				@kit_item = kit_item,
				@line_no = line_no,
				@qty = qty
		FROM	#parts_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)			
		-- v1.3 WHILE @@FETCH_STATUS = 0  
		BEGIN  
			--find default lot  
			SET @auto_lot = ''  
			IF EXISTS(SELECT auto_lot_flag, auto_lot FROM tdc_inv_master (NOLOCK) WHERE auto_lot IS NOT NULL AND part_no = @part_no)  
			BEGIN  
				SELECT	@auto_lot = auto_lot   
				FROM	tdc_inv_master (NOLOCK)   
				WHERE	auto_lot IS NOT NULL 
				AND		part_no = @part_no  
			END  
			ELSE  
			BEGIN  
				IF EXISTS(SELECT active, value_str FROM tdc_config (NOLOCK)  WHERE [function] = 'auto_lot' AND active = 'Y' AND value_str <> '')  
					SELECT	@auto_lot = value_str   
					FROM	tdc_config (NOLOCK)    
					WHERE	[function] = 'auto_lot'
					AND		active  = 'Y'  
					AND		value_str <> ''  
			END  
	  
			--find default bin_no   
			SET @auto_bin = ''   
			IF EXISTS(SELECT active, value_str FROM tdc_config (NOLOCK)  WHERE [function] = 'auto_Bin' AND active = 'Y' AND value_str <> '')  
			BEGIN  
				SELECT	@auto_bin = value_str   
				FROM	tdc_config (NOLOCK)    
				WHERE	[function] = 'auto_Bin'
				AND		active  = 'Y'  
				AND		value_str <> ''  
			END  
	  
			--if exists default lot then assing it to @lot_ser, else go to tdc_dist_item_pick table  
			IF @auto_lot <> ''  
				SET @lot_ser = @auto_lot -- depende de @auto_lot  
			ELSE  
				SELECT	@lot_ser = lot_ser  
				FROM	tdc_dist_item_pick (NOLOCK)   
				WHERE	order_no = @order_no  
				AND		order_ext = @order_ext 
				AND		part_no  = @part_no  
				AND		line_no  = @line_no  
	  
			--if exists default bin_no then assing it to @auto_bin, else go to tdc_dist_item_pick table  
			IF @auto_bin <> ''  
				SET @bin_no =  @auto_bin --depende de @auto_bin  
			ELSE  
				SELECT	@bin_no = bin_no  
				FROM	tdc_dist_item_pick (NOLOCK)   
				WHERE	order_no = @order_no  
				AND		order_ext = @order_ext 
				AND		part_no  = @part_no  
				AND		line_no  = @line_no  
	       
			SELECT	@uom = uom  
			FROM	inv_master (NOLOCK)  
			WHERE   part_no  = @part_no    
	    
	  
			EXEC tdc_pps_scan_sp @scanned_index       , @is_one_order_per_ctn, @is_packing       , @is_auto_qty     ,  
					@is_cube_active      , @is_using_tote_bins  , @auto_lot              , @auto_bin        ,  
					@user_id          , @station_id   , @carton_no output      , @tote_bin output ,  
					@carton_code output  , @pack_type output    , @order_no output       , @order_ext output,  
					@total_cartons output, @tran_id output      , @part_no output        , @kit_item output ,  
					@line_no output   , @location output     , @lot_ser output        , @bin_no output   ,  
					@serial_no output  , @version output      , @qty output            ,@uom output       , @err_msg output  
	          
     		SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@part_no = part_no,
					@kit_item = kit_item,
					@line_no = line_no,
					@qty = qty
			FROM	#parts_cursor
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			-- v1.3 FETCH NEXT FROM parts_cursor   
			-- v1.3 INTO @part_no, @kit_item, @line_no, @qty  
		END  
  
	-- v1.3 CLOSE parts_cursor  
	-- v1.3 DEALLOCATE parts_cursor  
	END -- v1.5 End


	-- v1.4 Start
	UPDATE	ord_list   
	SET		shipped = ordered   
	WHERE	order_no = @order_no  
	AND		order_ext = @order_ext  
	AND		shipped = 0 
	AND		part_no = 'PROMOTION DISCOUNT'
   
	UPDATE	tdc_dist_item_list   
	SET		shipped = quantity   
	WHERE	order_no = @order_no  
	AND		order_ext = @order_ext  
	AND		[function] = 'S'  
	AND		part_no = 'PROMOTION DISCOUNT'
	-- v1.4 End
END  
-- Permissions  

GO
GRANT EXECUTE ON  [dbo].[CVO_auto_pack_out_sp] TO [public]
GO
