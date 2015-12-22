SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*

Object:      CVO_pack_autopack_carton_sp  
Author:		 Chris Tyler
Created:	 26/07/2012
Copyright:   Epicor Software 2012.  All rights reserved. */  


CREATE PROCEDURE [dbo].[CVO_pack_autopack_carton_sp]  (@autopack_id	INT,
													   @carton_no INT OUTPUT)
	   
AS 
BEGIN
	DECLARE  
			@order_no				INT,  
			@order_ext			INT,
			@scanned_index			INT,  
			@is_one_order_per_ctn	CHAR(1),  
			@is_packing				CHAR(1),  
			@is_auto_qty			CHAR(1),  
			@is_cube_active			CHAR(1),  
			@is_using_tote_bins		CHAR(1),  
			@auto_lot				VARCHAR(25),  
			@auto_bin				VARCHAR(12),  
			@user_id				VARCHAR(50),  
			@station_id			VARCHAR(3),
			@tote_bin				VARCHAR(12),
			@carton_code			VARCHAR(10),
			@pack_type				VARCHAR(10),
			@total_cartons			INT,
			@tran_id				INT,
			@part_no				VARCHAR(30),
			@kit_item				VARCHAR(30),
			@line_no				INT,
			@location				VARCHAR(10),
			@lot_ser				VARCHAR(25),
			@bin_no					VARCHAR(12),
			@serial_no				VARCHAR(40),
			@version				VARCHAR(40),
			@qty					numeric(20,8),
			@uom					VARCHAR(10),
			@err_msg				VARCHAR(255)					

	SET @station_id		= '999'

	-- Get order details
	SELECT
		@order_no = order_no,
		@order_ext = order_ext,
		@carton_no = carton_no,
		@line_no = line_no,
		@part_no = part_no,
		@qty = picked
	FROM
		dbo.CVO_autopack_carton (NOLOCK)
	WHERE
		autopack_id = @autopack_id

		
	-- If carton_no is null get a new one
	IF ISNULL(@carton_no,0) = 0
	EXECUTE @carton_no = [dbo].[tdc_get_serialno] 
		
	SELECT @location		    = location FROM orders(NOLOCK) WHERE order_no = @order_no AND ext = @order_ext
	SET @is_one_order_per_ctn	= 'Y'

	IF OBJECT_ID('tempdb..#temp_pps_carton_display')	IS NOT NULL 
		DROP TABLE #temp_pps_carton_display

	IF OBJECT_ID('tempdb..#temp_pps_kit_display')		IS NOT NULL 
		DROP TABLE #temp_pps_kit_display

	IF OBJECT_ID('tempdb..#serial_no')					IS NOT NULL
		DROP TABLE #serial_no


	CREATE TABLE #temp_pps_carton_display
	(order_no	INT					NOT NULL,                 
	order_ext   INT					NOT NULL,                 
	line_no     INT					NOT NULL,                 
	part_no     VARCHAR(30)			NOT NULL,
	[description]   VARCHAR(255)		NULL,
	ordered     decimal(20, 8)		NOT NULL,
	picked      decimal(20, 8)		NOT NULL,
	total_packed    decimal(20, 8)	NOT NULL,
	carton_packed decimal(20, 8)	NOT NULL,
	con_rec      int NULL,                 
    con_ref      int NULL,  
    con_qty      decimal(20,8),
    con_packed_qty decimal(20,8),
    con_carton_qty decimal(20,8))   
	  
	CREATE TABLE #temp_pps_kit_display	
	(order_no		INT				NOT NULL,
	order_ext       INT				NOT NULL,
	line_no         INT				NOT NULL,
	part_no         VARCHAR(30)		NOT NULL,
	sub_kit_part_no VARCHAR(30)			NULL,
	[description]   VARCHAR(255)		NULL,
	qty_per_kit     decimal(20, 8)	NOT NULL,
	ordered         decimal(20, 8)	NOT NULL,
	picked          decimal(20, 8)	NOT NULL,
	total_packed    decimal(20, 8)	NOT NULL,
	carton_packed   decimal(20, 8)	NOT NULL)

	SELECT	@user_id = who 	
	FROM	#temp_who 

	CREATE TABLE #serial_no
	(serial_no VARCHAR(40)	NOT NULL,
	 serial_raw VARCHAR(40)	NOT NULL)
	

	EXEC tdc_pps_grid_display	@is_one_order_per_ctn, 
								@carton_no, 
								@order_no, 
								@order_ext

	SET @scanned_index			= 14	    
	SET @is_one_order_per_ctn	= 'Y'
	SET @is_packing				= 'Y'
		
	SELECT @is_auto_qty = ISNULL(auto_qty,'N')
	FROM   tdc_pack_station_tbl(NOLOCK)  
	WHERE  CAST(station_id  AS INT) = @station_id
		
	SET @is_cube_active			= 'Y'
	SET @is_using_tote_bins		= 'N'
	SET @tote_bin				= ''
	SELECT @carton_code	= value_str FROM dbo.tdc_config (NOLOCK) WHERE mod_owner = 'GEN' AND [function] = 'STOCK_ORDER_PACKAGE_CODE'
	SET @pack_type				= ''
	SET @total_cartons			= 0
	SET @tran_id				= 0
	SET @kit_item				= ''
	SET @serial_no				= ''
	SET @version				= ''
	SET @err_msg				= NULL					
	SET @kit_item				= ''		
	
	
	--find default lot
	SET @auto_lot = ''
	IF EXISTS(SELECT auto_lot_flag, auto_lot FROM tdc_inv_master (NOLOCK) WHERE auto_lot IS NOT NULL AND part_no = @part_no)
		BEGIN
			SELECT	@auto_lot = auto_lot 
			FROM	tdc_inv_master (NOLOCK) 
			WHERE	auto_lot IS NOT NULL AND 
					part_no = @part_no
		END
	ELSE
		BEGIN
			IF EXISTS(SELECT active, value_str FROM tdc_config (NOLOCK)  WHERE [function] = 'auto_lot' AND active = 'Y' AND value_str <> '')
				SELECT	@auto_lot = value_str 
				FROM	tdc_config (NOLOCK)  
				WHERE	[function]	= 'auto_lot'AND 
						active		= 'Y'		AND 
						value_str	<> ''
		END


	--find default bin_no	
	SET @auto_bin = ''	
	IF EXISTS(SELECT active, value_str FROM tdc_config (NOLOCK)  WHERE [function] = 'auto_Bin' AND active = 'Y' AND value_str <> '')
	BEGIN
		SELECT	@auto_bin = value_str 
		FROM	tdc_config (NOLOCK)  
		WHERE	[function]	= 'auto_Bin'AND 
				active		= 'Y'		AND 
				value_str	<> ''
	END

	--if exists default lot then assing it to @lot_ser, else go to tdc_dist_item_pick table
	IF @auto_lot <> ''
		SET @lot_ser = @auto_lot -- depende de @auto_lot
	ELSE
		SELECT	@lot_ser    = lot_ser
		FROM	tdc_dist_item_pick (NOLOCK) 
		WHERE	order_no	= @order_no		AND
				order_ext	= @order_ext	AND
				part_no		= @part_no		AND
				line_no		= @line_no

	--if exists default bin_no then assing it to @auto_bin, else go to tdc_dist_item_pick table
	IF @auto_bin <> ''
		SET @bin_no =  @auto_bin --depende de @auto_bin
	ELSE
		SELECT	@bin_no     = bin_no
		FROM	tdc_dist_item_pick (NOLOCK) 
		WHERE	order_no	= @order_no		AND
				order_ext	= @order_ext	AND
				part_no		= @part_no		AND
				line_no		= @line_no
				
	SELECT	@uom = uom
	FROM	inv_master (NOLOCK)
	WHERE   part_no		= @part_no		
	

	EXEC tdc_pps_scan_sp	@scanned_index       , @is_one_order_per_ctn, @is_packing		     , @is_auto_qty	    ,
							@is_cube_active      , @is_using_tote_bins  , @auto_lot              , @auto_bin        ,
							@user_id	         , @station_id			, @carton_no output      , @tote_bin output ,
							@carton_code output  , @pack_type output    , @order_no output       , @order_ext output,
							@total_cartons output, @tran_id output      , @part_no output        , @kit_item output ,
							@line_no output		 , @location output     , @lot_ser output        , @bin_no output   ,
							@serial_no output	 , @version output      , @qty output            ,@uom output       , @err_msg output
							
	

END
-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_pack_autopack_carton_sp] TO [public]
GO
