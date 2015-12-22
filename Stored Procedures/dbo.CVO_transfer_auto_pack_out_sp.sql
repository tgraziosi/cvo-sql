SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CT 08/11/12 - created
-- v1.1 CB 06/06/2013 - Issue #1187 - Auto pack out for standard transfers


CREATE PROCEDURE [dbo].[CVO_transfer_auto_pack_out_sp]   
        @xfer_no	INT,  
	    @station_id	INT    
AS 
BEGIN
	DECLARE
			@carton_no				INT,  
			@scanned_index			INT,  
			@is_one_order_per_ctn	CHAR(1),  
			@is_packing				INT,  
			@is_auto_qty			INT,  
			@is_cube_active			INT,  
			@is_using_tote_bins		CHAR(1),  
			@auto_lot				VARCHAR(25),  
			@auto_bin				VARCHAR(12),  
			@user_id				VARCHAR(50),  
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
			@err_msg				VARCHAR(255),
			@xfer_ext				INT,
			@current_carton			INT,
			@PCSN					INT,
			@Reserved5				VARCHAR(30),
			@serial_lot				VARCHAR(25),
			@Reserved7				INT,  
			@Reserved8				INT,
			@line_cnt				INT,
			@carton_status			VARCHAR(25),
			@err_no					INT,
			@reserved9				INT,
			@current_stage			VARCHAR(11),
			@carton_weight			DECIMAL(20,8),
			@retval					INT		

	SET @xfer_ext = 0

	-- Check if transfer is set to autopack or autoship
-- v1.1 Start
--	IF NOT EXISTS (SELECT 1 FROM dbo.xfers WHERE xfer_no = @xfer_no AND (autopack = 1 OR autoship = 1))
--	BEGIN
--		RETURN
--	END
-- v1.1 End
	
	-- Check if carton already exists 
	IF EXISTS(SELECT carton_no FROM tdc_carton_tx (NOLOCK) WHERE order_no = @xfer_no AND order_ext = @xfer_ext AND order_type = 'T')
		SELECT @carton_no = carton_no FROM tdc_carton_tx (NOLOCK) WHERE order_no = @xfer_no AND order_ext = @xfer_ext AND order_type = 'T'
	ELSE
		EXECUTE @carton_no = [dbo].[tdc_get_serialno] 
		
	SELECT @location		    = from_loc FROM xfers (NOLOCK) WHERE xfer_no = @xfer_no 
	SET @is_one_order_per_ctn	= 'Y'

	IF OBJECT_ID('tempdb..#tdc_pack_out_item_xfer')	IS NOT NULL 
		DROP TABLE #tdc_pack_out_item_xfer

	CREATE TABLE #tdc_pack_out_item_xfer (
		line_no     int,                 
		display_line int,                 
		part_no     varchar(30),          
		description varchar(255) NULL,    
		ordered     decimal(20, 8),       
		picked      decimal(20, 8),       
		cum_packed  decimal(20, 8),       
		carton      decimal(20, 8),       
		cur_packed  decimal(20, 8),       
		status      varchar(10) NULL)    

	SELECT	@user_id = who 	
	FROM	#temp_who 

	EXEC tdc_get_pack_out_item_list_sp '01', @xfer_no, 0,	@carton_no, 'T'

	SET @scanned_index			= 10 
	SET @is_one_order_per_ctn	= 'Y'
	SET @is_packing				= 1
		
	SELECT @is_auto_qty = CASE ISNULL(auto_qty,'N') WHEN 'N' THEN 0 ELSE 1 END
	FROM   tdc_pack_station_tbl(NOLOCK)  
	WHERE  CAST(station_id  AS INT) = @station_id
		
	SET @is_cube_active			= 1
	SET @is_using_tote_bins		= 'N'
	SET @tote_bin				= ''
	SET @pack_type				= ''
	SET @total_cartons			= 0
	SET @tran_id				= 0
	SET @kit_item				= ''
	SET @serial_no				= ''
	SET @version				= ''
	SET @err_msg				= NULL	
	SET @current_carton			= 0
	SET @PCSN					= 0
	SET @Reserved5				= ''
	SET @serial_lot				= '0'
	SET @Reserved7				= 0
	SET @Reserved8				= 0
	SET @current_stage			= ''
	SET @carton_weight			= 0.00000000

	SELECT @carton_code = value_str FROM tdc_config (NOLOCK)  WHERE [function] = 'TRANSFER_ORDER_PACKAGE_CODE' AND active = 'Y'
	IF @carton_code IS NULL 
	BEGIN
		SET @carton_code = 'QC'
	END
	
	SET @line_no = 0

	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@part_no = part_no,        
	        @line_no = line_no,  
	        @qty = picked - cum_packed 
		FROM  
			#tdc_pack_out_item_xfer	
		WHERE  
			cum_packed < ordered		 
			AND picked > cum_packed	
			AND line_no > @line_no
		ORDER BY
			line_no

		IF @@ROWCOUNT = 0
			BREAK
			

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

		--if exists default lot then assign it to @lot_ser, else go to tdc_dist_item_pick table
		IF @auto_lot <> ''
			SET @lot_ser = @auto_lot -- depende de @auto_lot
		ELSE
			SELECT	@lot_ser    = lot_ser
			FROM	tdc_dist_item_pick (NOLOCK) 
			WHERE	order_no	= @xfer_no		AND
					order_ext	= @xfer_ext		AND
					part_no		= @part_no		AND
					line_no		= @line_no

		--if exists default bin_no then assing it to @auto_bin, else go to tdc_dist_item_pick table
		IF @auto_bin <> ''
			SET @bin_no =  @auto_bin --depende de @auto_bin
		ELSE
			SELECT	@bin_no     = bin_no
			FROM	tdc_dist_item_pick (NOLOCK) 
			WHERE	order_no	= @xfer_no		AND
					order_ext	= @xfer_ext		AND
					part_no		= @part_no		AND
					line_no		= @line_no
					
		SELECT	@uom = uom
		FROM	inv_master (NOLOCK)
		WHERE   part_no		= @part_no		
		


		EXEC @retval = tdc_pps_validate_and_redirect_xfer_sp	@is_packing, @scanned_index, 0, '01', 1,
																0,@auto_lot, @auto_bin, 0, @user_id,
																@station_id, @is_auto_qty, 0, 0, @is_cube_active,
																@line_no OUTPUT, @tote_bin OUTPUT, @xfer_no OUTPUT, @carton_no OUTPUT, @total_cartons OUTPUT,
																@current_carton OUTPUT, @PCSN OUTPUT, @part_no OUTPUT, @Reserved5 OUTPUT, @location OUTPUT,
																@uom OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @serial_no OUTPUT, @version OUTPUT,
																@qty OUTPUT, @serial_lot OUTPUT, @Reserved7 OUTPUT, @Reserved8 OUTPUT, @line_cnt OUTPUT,
																@carton_status OUTPUT, @err_msg OUTPUT, @err_no OUTPUT, @reserved9 OUTPUT, @current_stage OUTPUT, @carton_weight OUTPUT
		
	END

	-- Update carton type
	UPDATE 
		tdc_carton_tx 
	SET 
		carton_type = @carton_code 
	WHERE 
		carton_no = @carton_no

END
-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_transfer_auto_pack_out_sp] TO [public]
GO
