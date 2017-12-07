SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_sim_allocate_by_bin_group_sp]	@user_id			VARCHAR(50),         
													@template_code		VARCHAR(20),        
													@order_no			INT,         
													@order_ext			INT,         
													@line_no			INT,         
													@part_no			VARCHAR(30),        
													@one_for_one_flg	CHAR(1),        
													@bin_group			VARCHAR(30),         
													@search_sort		VARCHAR(30),         
													@alloc_type		VARCHAR(30),         
													@pkg_code			VARCHAR(10),        
													@replen_group		VARCHAR(12),        
													@multiple_parts	CHAR(1),        
													@bin_first			VARCHAR(10),         
													@priority			INT,        
													@user_hold			CHAR(1),         
													@cdock_flg			CHAR(1),           
													@pass_bin			VARCHAR(12),          
													@assigned_user		VARCHAR(25),            
													@lbs_order_by		VARCHAR(5000),
													@alloc_from_ebo	INT = 0

AS
BEGIN
	-- NOTE: Routine based on CVO_allocate_by_bin_group_sp v1.9 - All changes must be kept in sync

	SET @one_for_one_flg = 'Y'

	DECLARE @ret INT, @try_again CHAR(1)
	DECLARE @ALLOC_QTY_FENCE_QTY INT,
			@bulk_bin_group VARCHAR(12), 
			@hight_bays_bin_group VARCHAR(12), 
			@pick_bin_group VARCHAR(12)
	DECLARE @qty_to_alloc decimal(20,8)
	DECLARE @qty_available decimal(20,8),
			@location varchar(10)

	DECLARE @high_bay_qty	decimal(20,8), 
			@bulk_qty		decimal(20,8) 

	DECLARE	@avail_alloc_qty decimal(20,8)	

	DECLARE @bin_no			VARCHAR(12),
			@qty			DECIMAL(20,8),
			@bop			SMALLINT
	DECLARE @qty_allocated		DECIMAL(20,8),
			@current_bin_group	VARCHAR(12),
			@current_bin_no		VARCHAR(12)
	DECLARE	@ft_qty_fence		decimal(20,8)

	SELECT @ALLOC_QTY_FENCE_QTY = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'ALLOC_QTY_FENCE'
	SELECT @bulk_bin_group		= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'bulk_bin_group'
	SELECT @hight_bays_bin_group= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'hight_bays_bin_group'
	SELECT @pick_bin_group		= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'pick_bin_group'		--'[ALL]'

	SET @current_bin_group = ''
	IF OBJECT_ID('tempdb..#no_stock_required') IS NOT NULL
	BEGIN
		SELECT	@qty_to_alloc = qty,
				@location = location,
				@current_bin_no = bin_no
		FROM	#no_stock_required

		SELECT 
			@current_bin_group = group_code 
		FROM 
			dbo.tdc_bin_master (NOLOCK) 
		WHERE 
			location = @location 
			AND bin_no = @current_bin_no
	END
	ELSE
	BEGIN

		IF @alloc_from_ebo = 1
		BEGIN

			SELECT	@qty_to_alloc = qty_to_alloc,
					@location = location
			FROM	#so_allocation_detail_view_detail
			WHERE	order_no  = @order_no	AND 
					order_ext = @order_ext	AND 
					line_no   = @line_no
		END
		ELSE
		BEGIN


			SELECT	@qty_to_alloc = qty_to_alloc,
					@location = location
			FROM	#so_allocation_detail_view
			WHERE	order_no  = @order_no	AND 
					order_ext = @order_ext	AND 
					line_no   = @line_no
		END
	END

	-- v1.1 Start
	IF (@order_ext > 0)
		SET @bop = 1 
	-- v1.1 End

	IF OBJECT_ID('tempdb..#next_bin_group') IS NOT NULL 
		DROP TABLE #next_bin_group 
	
	CREATE TABLE #next_bin_group (id_bin INT, bin_group VARCHAR(12), qty INT, 
										qty_available decimal(20,8))

	DELETE FROM #next_bin_group

	SET @high_bay_qty = 0 
	exec @high_bay_qty = CVO_CheckAvailabilityInBinGroup_sp @part_no,@location,@hight_bays_bin_group 
	IF @current_bin_group  = @hight_bays_bin_group
	BEGIN
		SET @high_bay_qty = @high_bay_qty + @qty_to_alloc
	END
	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (1, @hight_bays_bin_group, @ALLOC_QTY_FENCE_QTY, @high_bay_qty) 

	SET @bulk_qty = 0 
	exec @bulk_qty = CVO_CheckAvailabilityInBinGroup_sp @part_no,@location,@bulk_bin_group 
	IF @current_bin_group  = @bulk_bin_group
	BEGIN
		SET @bulk_qty = @bulk_qty + @qty_to_alloc
	END
	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (2, @bulk_bin_group      , @ALLOC_QTY_FENCE_QTY, @bulk_qty) 

	SET @ft_qty_fence = 0
	EXEC @ft_qty_fence = CVO_CheckAvailabilityInBinGroup_sp @part_no, @location, @pick_bin_group, 0, 1 
	IF (@ft_qty_fence >= @qty_to_alloc)
	BEGIN
		INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (3, 'FASTTRACK', @ALLOC_QTY_FENCE_QTY, @ft_qty_fence)
	END

	SET @qty_available = 0
	exec @qty_available = CVO_CheckAvailabilityInBinGroup_sp @part_no,@location,@pick_bin_group
	IF @current_bin_group  = @pick_bin_group
	BEGIN
		SET @qty_available = @qty_available + @qty_to_alloc
	END
	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (4, @pick_bin_group      , @ALLOC_QTY_FENCE_QTY, @qty_available)

	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (5, @pick_bin_group		 , @ALLOC_QTY_FENCE_QTY - 1, @qty_available)

	SET @ft_qty_fence = 0
	EXEC @ft_qty_fence = CVO_CheckAvailabilityInBinGroup_sp @part_no, @location, @pick_bin_group, 0, 1 
	IF (@ft_qty_fence >= @qty_to_alloc)
	BEGIN
		INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (6, 'FASTTRACK', @ALLOC_QTY_FENCE_QTY - 1, @ft_qty_fence)
	END

	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (7, @hight_bays_bin_group, @ALLOC_QTY_FENCE_QTY - 1, @high_bay_qty)
	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (8, @bulk_bin_group      , @ALLOC_QTY_FENCE_QTY - 1, @bulk_qty)

	SET @try_again = 'Y'
		
	WHILE @try_again = 'Y'
	BEGIN
		SET @try_again = 'N' -- assumes full allocation
		
		SET @bin_group = '--'

		IF @qty_to_alloc >= @ALLOC_QTY_FENCE_QTY
			BEGIN
				SELECT TOP 1 @bin_group = bin_group FROM #next_bin_group 
						WHERE qty >= @ALLOC_QTY_FENCE_QTY AND qty_available >= @qty_to_alloc ORDER BY id_bin
				IF @bin_group = '--' OR @bin_group IS NULL
				BEGIN
					SELECT TOP 1 @bin_group = bin_group FROM #next_bin_group 
							WHERE qty >= @ALLOC_QTY_FENCE_QTY ORDER BY id_bin
				END
				DELETE FROM #next_bin_group WHERE bin_group = @bin_group 
						AND qty >= @ALLOC_QTY_FENCE_QTY 
			END	

		IF @qty_to_alloc <= @ALLOC_QTY_FENCE_QTY - 1
			BEGIN
				SELECT TOP 1 @bin_group = bin_group FROM #next_bin_group WHERE qty <=  @ALLOC_QTY_FENCE_QTY - 1 AND qty_available >= @qty_to_alloc ORDER BY id_bin
				IF @bin_group = '--' OR @bin_group IS NULL
				BEGIN
					SELECT TOP 1 @bin_group = bin_group FROM #next_bin_group WHERE qty <=  @ALLOC_QTY_FENCE_QTY - 1 ORDER BY id_bin
				END
				DELETE FROM #next_bin_group WHERE bin_group = @bin_group AND qty <=  @ALLOC_QTY_FENCE_QTY - 1												
			END


		SET @avail_alloc_qty = 0
		EXEC @avail_alloc_qty = dbo.CVO_GetAllocatableStock_sp @order_no, @order_ext, @location, @part_no, @qty_to_alloc

		IF (@avail_alloc_qty <= @qty_to_alloc) 
		BEGIN
			IF (@avail_alloc_qty > 0)
			BEGIN	
				EXEC @ret = sim_tdc_plw_so_allocate_line_sp @user_id, @template_code, @order_no,    @order_ext,  @line_no,   @part_no,          
										@one_for_one_flg, @bin_group, @search_sort, @alloc_type, @pkg_code,  @replen_group,
										@multiple_parts,  @bin_first, @priority,    @user_hold,  @cdock_flg, @pass_bin, 
										@assigned_user,   @lbs_order_by, @avail_alloc_qty -- v1.4 Pass in the max to alloc							
			                     							
			END
			ELSE
			BEGIN
				SET @try_again = 'N'
				CONTINUE
			END
		END
		ELSE
		BEGIN
			EXEC @ret = sim_tdc_plw_so_allocate_line_sp @user_id, @template_code, @order_no,    @order_ext,  @line_no,   @part_no,          
								@one_for_one_flg, @bin_group, @search_sort, @alloc_type, @pkg_code,  @replen_group,
								@multiple_parts,  @bin_first, @priority,    @user_hold,  @cdock_flg, @pass_bin, 
								@assigned_user,   @lbs_order_by
	                     							
		END

		SELECT	@qty_allocated = SUM(qty) 
		FROM	#sim_tdc_soft_alloc_tbl (NOLOCK) 
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext 
		AND		line_no = @line_no

		IF ISNULL(@qty_allocated,0) = @qty_to_alloc
		BEGIN
			--line_no was allocated then go to next line_no	
			SET @try_again = 'N'
		END
		ELSE
		BEGIN
			IF @qty_to_alloc >= @ALLOC_QTY_FENCE_QTY 
			BEGIN
				IF EXISTS (SELECT * FROM #next_bin_group WHERE qty >= @ALLOC_QTY_FENCE_QTY)
					SET @try_again = 'Y'
			END										

			IF @qty_to_alloc <= @ALLOC_QTY_FENCE_QTY - 1
			BEGIN
				IF EXISTS (SELECT * FROM #next_bin_group WHERE qty <=  @ALLOC_QTY_FENCE_QTY - 1)
					SET @try_again = 'Y'
			END
		END
	END
END

GO
GRANT EXECUTE ON  [dbo].[CVO_sim_allocate_by_bin_group_sp] TO [public]
GO
