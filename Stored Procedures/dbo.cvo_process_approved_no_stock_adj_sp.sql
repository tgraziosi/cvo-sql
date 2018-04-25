SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_process_approved_no_stock_adj_sp]
AS

BEGIN

	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@id				int,
			@last_id		int,
			@bin_no			varchar(20),
			@lot_ser		varchar(25),
			@part_no		varchar(30),
			@location		varchar(10),
			@qty			decimal(20,8),
			@direction		int,
			@reason_code	varchar(10),
			@created_by		varchar(50),
			@bin_qty		decimal(20,8),
			@issue_no		int,
			@uom			varchar(2),
			@group_code		varchar(10),
			@description	varchar(255),
			@sku_code		varchar(30), 
			@height			decimal(20,8), 
			@width			decimal(20,8), 
			@length			decimal(20,8), 
			@cmdty_code		varchar(8),
			@weight_ea		decimal(20,8), 
			@so_qty_increment decimal(20,8),
			@cubic_feet		decimal(20,8),
			@category_1		varchar(15),
			@category_2		varchar(15),
			@category_3		varchar(15),
			@category_4		varchar(15),
			@category_5		varchar(15),
			@UPC			varchar(12),
			@GTIN			varchar(14),
			@EAN_8			varchar(8),
			@EAN_13			varchar(13),
			@EAN_14			varchar(14),
			@data			varchar(7500),
			@iret			int -- v1.1			


	-- Create working table
	IF (SELECT OBJECT_ID('tempdb..#approved_adj')) IS NOT NULL 
	BEGIN   
		DROP TABLE #approved_adj  
	END

	CREATE TABLE #approved_adj (
		id			int,
		bin_no		varchar(20),
		lot_ser		varchar(25),
		part_no		varchar(30),
		location	varchar(10),
		qty			decimal(20,8),
		direction	int,
		reason_code	varchar(10),
		created_by	varchar(50))

	IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_inv_adj  
	END

	CREATE TABLE #adm_inv_adj (
		adj_no			int	null,
		loc				varchar(10) not null,
		part_no			varchar(30)	not null,
		bin_no			varchar(12) null,
		lot_ser			varchar(25) null,
		date_exp		datetime null,
		qty				decimal(20,8) not null,
		direction		int	not null,
		who_entered		varchar(50)	not null,
		reason_code		varchar(10) null,
		code			varchar(8) not null,
		cost_flag		char(1)	null,
		avg_cost		decimal(20,8) null,
		direct_dolrs	decimal(20,8) null,
		ovhd_dolrs		decimal(20,8) null,
		util_dolrs		decimal(20,8) null,
		err_msg			varchar(255) null,
		row_id			int identity not null)

	-- Mark the records to process
	UPDATE	dbo.CVO_no_stock_approval
	SET		approve = -5
	WHERE	approve = -1
	AND		direction <> -2

	INSERT	#approved_adj (id, bin_no, lot_ser, part_no, location, qty, direction, reason_code, created_by)
	SELECT	id, bin_no, lot_ser, part_no, location, qty, direction, adj_code, created_by
	FROM	dbo.CVO_no_stock_approval (NOLOCK)
	WHERE	approve = -5
	ORDER BY id ASC	

	SET @last_id = 0

	SELECT	TOP 1 @id = id,
			@bin_no = bin_no, 
			@lot_ser = lot_ser, 
			@part_no = part_no, 
			@location = location, 
			@qty = qty,
			@direction = direction,
			@reason_code = reason_code,
			@created_by = created_by
	FROM	#approved_adj
	WHERE	id > @last_id
	ORDER BY id ASC
	
	WHILE @@ROWCOUNT <> 0
	BEGIN

		IF (@direction = -1) -- OUT
		BEGIN

			SET @bin_qty = NULL

			SELECT	@bin_qty = qty
			FROM	lot_bin_stock (NOLOCK)
			WHERE	location = @location
			AND		part_no = @part_no
			AND		lot_ser = @lot_ser
			AND		bin_no = @bin_no

			IF (@bin_qty IS NULL OR @bin_qty < @qty)
			BEGIN

				UPDATE	dbo.CVO_no_stock_approval
				SET		approve = 0,
						direction = -2
				WHERE	approve = -5
				AND		id = @id
		
				SET @last_id = @id

				SELECT	TOP 1 @id = id,
						@bin_no = bin_no, 
						@lot_ser = lot_ser, 
						@part_no = part_no, 
						@location = location, 
						@qty = qty,
						@direction = direction,
						@reason_code = reason_code,
						@created_by = created_by		
				FROM	#approved_adj
				WHERE	id > @last_id
				ORDER BY id ASC
				
				CONTINUE
			END
		END

		TRUNCATE TABLE #adm_inv_adj

		INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, 
									reason_code, code) 							
		SELECT	location, part_no, bin_no, lot_ser, date_expires, qty, direction, created_by, reason_code, adj_code
		FROM	dbo.CVO_no_stock_approval (NOLOCK)
		WHERE	id = @id

		EXEC @iret = dbo.tdc_adm_inv_adj 

		-- v1.1 Start
		IF (@@ERROR <> 0) OR (@iret < 0)
		BEGIN
			UPDATE	dbo.CVO_no_stock_approval
			SET		approve = 0,
					direction = -2
			WHERE	approve = -5
			AND		id = @id
	
			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@bin_no = bin_no, 
					@lot_ser = lot_ser, 
					@part_no = part_no, 
					@location = location, 
					@qty = qty,
					@direction = direction,
					@reason_code = reason_code,
					@created_by = created_by		
			FROM	#approved_adj
			WHERE	id > @last_id
			ORDER BY id ASC
			
			CONTINUE

		END

		SET @issue_no = @iret

		UPDATE	dbo.CVO_no_stock_approval
		SET		approve = -7
		WHERE	approve = -5
		AND		id = @id

		INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, from_bin, 
					userid, direction, quantity) 														  
		VALUES( 'ADH', 'ADHOC', @issue_no, 0, @location, @part_no, @bin_no, @created_by, @direction, @qty)

		SELECT	@uom = uom, @description = description FROM inventory (nolock) WHERE part_no = @part_no AND location = @location 
		SELECT	@group_code = group_code FROM tdc_bin_master (nolock) WHERE location = @location AND bin_no = @bin_no
		SELECT	@sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, 
				@cmdty_code = isnull(cmdty_code, ''), @weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), 
				@cubic_feet = cubic_feet 
		FROM	inv_master (nolock) WHERE part_no = @part_no
		SELECT	@category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), 
				@category_3 = isnull(category_3, ''), @category_4 = isnull(category_4, ''), 
				@category_5 = isnull(category_5, '') 
		FROM	inv_master_add (nolock) WHERE part_no = @part_no
		SELECT	@UPC = ISNULL(UPC, ''), @GTIN = ISNULL(GTIN, ''), @EAN_8 = ISNULL(EAN_8, ''), 
				@EAN_13 = ISNULL(EAN_13, ''), @EAN_14 = ISNULL(EAN_14, '')						
		FROM	uom_id_code (nolock) WHERE part_no = @part_no 
		AND		UOM = @uom

		INSERT INTO dbo.tdc_3pl_issues_log (trans, issue_no, location, part_no, bin_no, bin_group, uom, 
								qty, userid, expert) 																
		VALUES ('ADHOC', @issue_no,	 @location, @part_no, @bin_no, @group_code, @uom, (@qty * @direction),  
					@created_by, 'N')
		
		SELECT @data = 'LP_ITEM_EAN14: ; LP_ITEM_EAN13: ; LP_ITEM_EAN8: ; LP_ITEM_GTIN: ; LP_ITEM_UPC: ' 
		SELECT @data = @data + LTRIM(RTRIM(@UPC)) + '; LP_CATEGORY_5: '+ LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_4: ' 
		SELECT @data = @data + LTRIM(RTRIM(@category_4)) + '; LP_CATEGORY_3: ' + LTRIM(RTRIM(@category_3)) + '; LP_CATEGORY_2: '
		SELECT @data = @data + LTRIM(RTRIM(@category_2)) + '; LP_CATEGORY_1: ; LP_CUBIC_FEET: ' + STR(@cubic_feet) + '; LP_SO_QTY_INCR: '
		SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
		SELECT @data = @data + STR(@so_qty_increment) + '; LP_WEIGHT: ' + STR(@weight_ea) + '; LP_CMDTY_CODE: '
		SELECT @data = @data + LTRIM(RTRIM(@cmdty_code)) + '; LP_LENGTH: ' + STR(@length)+ '; LP_WIDTH: ' + STR(@width) + '; LP_HEIGHT: ' 
		SELECT @data = @data + STR(@height) + '; LP_SKU: ; LP_ADJ_DIR: ' + CASE WHEN @direction = 1 THEN 'IN' ELSE 'OUT' END + '; LP_ADJ_CODE: ' + LTRIM(RTRIM(@reason_code)) + '; ' -- v1.1
		SELECT @data = @data + 'LP_REASON_CODE: ; LP_BASE_UOM: ' + LTRIM(RTRIM(@uom)) + '; LP_ITEM_UOM: ' + LTRIM(RTRIM(@uom))
		SELECT @data = @data + '; LP_BASE_QTY: ' + STR((@qty * @direction)) + '; LP_LB_TRACKING: Y; LP_ITEM_DESC: '
		SELECT @data = @data + LTRIM(RTRIM(@description)) + '; '

		INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,
									lot_ser,bin_no,location,quantity,data) 										
		VALUES (getdate(), @created_by, 'CO', 'ADH', 'ADHOC', CAST(@issue_no AS varchar(10)), '', @part_no, @lot_ser, @bin_no, 
					@location, CAST((@qty * @direction) as varchar(30)), @data) 

		SET @last_id = @id

		SELECT	TOP 1 @id = id,
				@bin_no = bin_no, 
				@lot_ser = lot_ser, 
				@part_no = part_no, 
				@location = location, 
				@qty = qty,
				@direction = direction,
				@reason_code = reason_code,
				@created_by = created_by
		FROM	#approved_adj
		WHERE	id > @last_id
		ORDER BY id ASC
	END

	-- Clean up
	DROP TABLE #approved_adj

	-- Remove processed records
	DELETE	dbo.CVO_no_stock_approval 
	WHERE	approve = -7


END
GO
GRANT EXECUTE ON  [dbo].[cvo_process_approved_no_stock_adj_sp] TO [public]
GO
