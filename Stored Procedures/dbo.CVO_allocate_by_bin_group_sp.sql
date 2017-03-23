SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[CVO_allocate_by_bin_group_sp]    Script Date: 08/09/2010  *****
SED009 -- AutoAllocation    
Object:      Procedure CVO_allocate_by_bin_group_sp  
Source file: CVO_allocate_by_bin_group_sp.sql
Author:		 Jesus Velazquez
Created:	 08/09/2010
Function:    Allocate lines trying with every bin_no in #next_bin_group table, this procedure override any @bin_group used in tdc_plw_so_allocate_line_sp
Modified:    
Calls:    
Called by:   WMS74 -- Allocation Screen
Copyright:   Epicor Software 2010.  All rights reserved.  
v1.1 CB 12/08/2010 - When allocating from a bin group then check the qty availble in that bin group
v1.2 CB 14/04/2011 - Fix - When Allocating, this routine must be run as one to one
v1.3 CB 14/11/2011 - Performance tuning
v1.4 CB 20/12/2012 - Issue #1041 - Commit stock when soft allocated
v1.5 CB 09/05/2013 - Issue #1265 - fix to v1.4
v1.6 CT 14/06/2013 - Issue #695 - allocation for PO ringfenced stock
v1.7 CT 24/07/2013 - Issue #1040 - No stock allocation
v1.8 CT 09/09/2013 - Issue #695 - fix for backorder processing from stock, force qty available to be qty required
v1.9 CB 04/10/2016 - #1606 - Direct Putaway & Fast Track Cart
BEGIN TRAN

EXEC CVO_allocate_by_bin_group_sp  'AUTO_ALLOC', 'AUTO_ALLOC', 1874, 0, 1, 'BC800', 'Y',  
				NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1   	
					

ROLLBACK TRAN
*/

CREATE PROCEDURE [dbo].[CVO_allocate_by_bin_group_sp] 
 @user_id			VARCHAR(50),         
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

-- v1.2
SET @one_for_one_flg = 'Y'

	DECLARE @ret INT, @try_again CHAR(1)
	DECLARE @ALLOC_QTY_FENCE_QTY INT,
			@bulk_bin_group VARCHAR(12), 
			@hight_bays_bin_group VARCHAR(12), 
			@pick_bin_group VARCHAR(12)
	DECLARE @qty_to_alloc decimal(20,8)
	DECLARE @qty_available decimal(20,8), -- v1.1
			@location varchar(10) -- v1.1

	DECLARE @high_bay_qty	decimal(20,8), -- v1.3
			@bulk_qty		decimal(20,8) -- v1.3

	DECLARE	@avail_alloc_qty decimal(20,8) -- v1.4			

	-- START v1.6
	DECLARE @bin_no			VARCHAR(12),
			@qty			DECIMAL(20,8),
			@bop			SMALLINT
	-- END v1.6	
	-- START v1.7
	DECLARE @qty_allocated		DECIMAL(20,8),
			@current_bin_group	VARCHAR(12),
			@current_bin_no		VARCHAR(12)
	-- END v1.7

	-- v1.9 Start
	DECLARE	@ft_qty_fence		decimal(20,8)
	-- v1.9 End

	SELECT @ALLOC_QTY_FENCE_QTY = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'ALLOC_QTY_FENCE'
	SELECT @bulk_bin_group		= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'bulk_bin_group'
	SELECT @hight_bays_bin_group= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'hight_bays_bin_group'
	SELECT @pick_bin_group		= value_str FROM tdc_config (NOLOCK) WHERE [function] = 'pick_bin_group'		--'[ALL]'

	-- START v1.7
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
					@location = location -- v1.1
			FROM	#so_allocation_detail_view_detail
			WHERE	order_no  = @order_no	AND 
					order_ext = @order_ext	AND 
					line_no   = @line_no
		END
		ELSE
		BEGIN


			SELECT	@qty_to_alloc = qty_to_alloc,
					@location = location -- v1.1
			FROM	#so_allocation_detail_view
			WHERE	order_no  = @order_no	AND 
					order_ext = @order_ext	AND 
					line_no   = @line_no
		END
	END
	-- END v1.7

	-- START v1.6
	SET @bop = 0
	IF OBJECT_ID('tempdb..#backorder_processing_po_allocation') IS NOT NULL
	BEGIN
		SET @bin_no = ''
		
		-- Do CROSSDOCK stock first
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@bin_no = bin_no,
				@qty = qty
			FROM
				#backorder_processing_po_allocation (NOLOCK)
			WHERE
				bin_no > @bin_no
				AND bin_no IS NOT NULL
				AND order_no = @order_no
				AND ext = @order_ext
				AND line_no = @line_no
				AND part_no = @part_no
			ORDER BY
				bin_no

			IF @@ROWCOUNT = 0
				BREAK

			BEGIN TRAN
			-- Pass bin_no through in order_by as that's not needed
			EXEC @ret = tdc_plw_so_allocate_line_sp @user_id, @template_code, @order_no,    @order_ext,  @line_no,   @part_no,          
							@one_for_one_flg, 'CROSSDOCK', @search_sort, @alloc_type, @pkg_code,  @replen_group,
							@multiple_parts,  @bin_first, @priority,    @user_hold,  @cdock_flg, @bin_no, 
							@assigned_user,   @lbs_order_by, @qty 						
		                     							
			COMMIT TRAN	
			
		END

		SET @qty = NULL

		-- Do std bin next, get the stock remaining and let the routine run with this
		SELECT
			@qty = SUM(qty)
		FROM
			#backorder_processing_po_allocation (NOLOCK)
		WHERE
			bin_no IS NULL
			AND order_no = @order_no
			AND ext = @order_ext
			AND line_no = @line_no
			AND part_no = @part_no


		IF ISNULL(@qty,0) = 0
		BEGIN
			RETURN
		END

		SET @qty_to_alloc = @qty

		SET @bop = 1
	END
	-- END v1.6		
	-- START v1.8
	IF OBJECT_ID('tempdb..#backorder_processing_allocation') IS NOT NULL
	BEGIN
		SET @qty = NULL

		SELECT
			@qty = SUM(qty)
		FROM
			#backorder_processing_allocation (NOLOCK)
		WHERE
			order_no = @order_no
			AND ext = @order_ext
			AND line_no = @line_no
			AND part_no = @part_no

		IF ISNULL(@qty,0) = 0
		BEGIN
			RETURN
		END

		SET @qty_to_alloc = @qty

		SET @bop = 1
	END
	-- END v1.8

	IF OBJECT_ID('tempdb..#next_bin_group') IS NOT NULL 
		DROP TABLE #next_bin_group 
	
	CREATE TABLE #next_bin_group (id_bin INT, bin_group VARCHAR(12), qty INT, 
										qty_available decimal(20,8)) -- v1.1
	--SELECT * FROM #next_bin_group

	DELETE FROM #next_bin_group
	-- >= @ALLOC_QTY_FENCE_QTY
	-- v1.1 Start

	SET @high_bay_qty = 0 -- v1.3
	exec @high_bay_qty = CVO_CheckAvailabilityInBinGroup_sp @part_no,@location,@hight_bays_bin_group -- v1.3
	-- START v1.7
	IF @current_bin_group  = @hight_bays_bin_group
	BEGIN
		SET @high_bay_qty = @high_bay_qty + @qty_to_alloc
	END
	-- END v1.7
	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (1, @hight_bays_bin_group, @ALLOC_QTY_FENCE_QTY, @high_bay_qty) -- v1.3

	SET @bulk_qty = 0 -- v1.3
	exec @bulk_qty = CVO_CheckAvailabilityInBinGroup_sp @part_no,@location,@bulk_bin_group -- v1.3
	-- START v1.7
	IF @current_bin_group  = @bulk_bin_group
	BEGIN
		SET @bulk_qty = @bulk_qty + @qty_to_alloc
	END
	-- END v1.7
	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (2, @bulk_bin_group      , @ALLOC_QTY_FENCE_QTY, @bulk_qty) -- v1.3

	-- v1.9 Start
	SET @ft_qty_fence = 0
	EXEC @ft_qty_fence = CVO_CheckAvailabilityInBinGroup_sp @part_no, @location, @pick_bin_group, 0, 1 
	IF (@ft_qty_fence >= @qty_to_alloc)
	BEGIN
		INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (3, 'FASTTRACK', @ALLOC_QTY_FENCE_QTY, @ft_qty_fence)
	END
	-- v1.9 End

	SET @qty_available = 0
	exec @qty_available = CVO_CheckAvailabilityInBinGroup_sp @part_no,@location,@pick_bin_group
	-- START v1.7
	IF @current_bin_group  = @pick_bin_group
	BEGIN
		SET @qty_available = @qty_available + @qty_to_alloc
	END
	-- END v1.7
	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (4, @pick_bin_group      , @ALLOC_QTY_FENCE_QTY, @qty_available)

	-- < @ALLOC_QTY_FENCE_QTY
--	SET @qty_available = 0 -- v1.3
--	exec @qty_available = CVO_CheckAvailabilityInBinGroup_sp @part_no,@location,@pick_bin_group -- v1.3
	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (5, @pick_bin_group		 , @ALLOC_QTY_FENCE_QTY - 1, @qty_available)

	-- v1.9 Start
	SET @ft_qty_fence = 0
	EXEC @ft_qty_fence = CVO_CheckAvailabilityInBinGroup_sp @part_no, @location, @pick_bin_group, 0, 1 
	IF (@ft_qty_fence >= @qty_to_alloc)
	BEGIN
		INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (6, 'FASTTRACK', @ALLOC_QTY_FENCE_QTY - 1, @ft_qty_fence)
	END
	-- v1.9 End

	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (7, @hight_bays_bin_group, @ALLOC_QTY_FENCE_QTY - 1, @high_bay_qty)
	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (8, @bulk_bin_group      , @ALLOC_QTY_FENCE_QTY - 1, @bulk_qty)

--	SET @qty_available = 0 -- v1.3
--	exec @qty_available = CVO_CheckAvailabilityInBinGroup_sp @part_no,@location,@hight_bays_bin_group -- v1.3
-- v1.9	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (5, @hight_bays_bin_group, @ALLOC_QTY_FENCE_QTY - 1, @high_bay_qty)

--	SET @qty_available = 0 -- v1.3
--	exec @qty_available = CVO_CheckAvailabilityInBinGroup_sp @part_no,@location,@bulk_bin_group -- v1.3
-- v1.9	INSERT INTO #next_bin_group (id_bin, bin_group, qty, qty_available) VALUES (6, @bulk_bin_group      , @ALLOC_QTY_FENCE_QTY - 1, @bulk_qty)

	-- v1.1 End
/*
--  v1.1
	INSERT INTO #next_bin_group (id_bin, bin_group, qty) VALUES (1, @hight_bays_bin_group, @ALLOC_QTY_FENCE_QTY)
	INSERT INTO #next_bin_group (id_bin, bin_group, qty) VALUES (2, @bulk_bin_group      , @ALLOC_QTY_FENCE_QTY)
	INSERT INTO #next_bin_group (id_bin, bin_group, qty) VALUES (3, @pick_bin_group      , @ALLOC_QTY_FENCE_QTY)

	-- < @ALLOC_QTY_FENCE_QTY
	INSERT INTO #next_bin_group (id_bin, bin_group, qty) VALUES (4, @pick_bin_group		 , @ALLOC_QTY_FENCE_QTY - 1)
	INSERT INTO #next_bin_group (id_bin, bin_group, qty) VALUES (5, @hight_bays_bin_group, @ALLOC_QTY_FENCE_QTY - 1)
	INSERT INTO #next_bin_group (id_bin, bin_group, qty) VALUES (6, @bulk_bin_group      , @ALLOC_QTY_FENCE_QTY - 1)
*/

	SET @try_again = 'Y'
		
	WHILE @try_again = 'Y'
	BEGIN
		SET @try_again = 'N' -- assumes full allocation
		
		SET @bin_group = '--'

		-- v1.1 Start -- Can it be allocated from a single bin group
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

/*	
		IF @qty_to_alloc >= @ALLOC_QTY_FENCE_QTY 
			BEGIN
				SELECT TOP 1 @bin_group = bin_group FROM #next_bin_group WHERE qty >= @ALLOC_QTY_FENCE_QTY ORDER BY id_bin
				SELECT @bin_group
				DELETE FROM #next_bin_group WHERE bin_group = @bin_group AND qty >= @ALLOC_QTY_FENCE_QTY	
			END	
		
		IF @qty_to_alloc <= @ALLOC_QTY_FENCE_QTY - 1
			BEGIN
				SELECT TOP 1 @bin_group = bin_group FROM #next_bin_group WHERE qty <=  @ALLOC_QTY_FENCE_QTY - 1 ORDER BY id_bin
				DELETE FROM #next_bin_group WHERE bin_group = @bin_group AND qty <=  @ALLOC_QTY_FENCE_QTY - 1												
			END
*/
		-- v1.4	Start

		-- START v1.6
		IF @bop = 1
		BEGIN
			-- v1.9 Start
			SET @ft_qty_fence = 0
			EXEC @ft_qty_fence = CVO_CheckAvailabilityInBinGroup_sp @part_no, @location, @pick_bin_group, 0, 1 
			IF (@ft_qty_fence > 0)
				SET @bin_group = 'FASTTRACK'
			-- v1.9 End

			SET @avail_alloc_qty = @qty_to_alloc
		END
		ELSE
		BEGIN
			SET @avail_alloc_qty = 0
			EXEC @avail_alloc_qty = dbo.CVO_GetAllocatableStock_sp @order_no, @order_ext, @location, @part_no, @qty_to_alloc
			-- START v1.7
			IF OBJECT_ID('tempdb..#no_stock_required') IS NOT NULL
			BEGIN
				SET @avail_alloc_qty = @avail_alloc_qty + @qty_to_alloc
			END
			-- END v1.7
		END
		-- END v1.6

-- v1.5		IF (@avail_alloc_qty < @qty_to_alloc)
		IF (@avail_alloc_qty <= @qty_to_alloc) -- v1.5
		BEGIN
			IF (@avail_alloc_qty > 0)
			BEGIN	
				-- START v1.7
				IF OBJECT_ID('tempdb..#no_stock_required') IS NOT NULL
				BEGIN
					BEGIN TRAN
					EXEC cvo_no_stock_get_bins_sp @user_id, @template_code, @order_no,    @order_ext,  @line_no,   @part_no,          
								@one_for_one_flg, @bin_group, @search_sort, @alloc_type, @pkg_code,  @replen_group,
								@multiple_parts,  @bin_first, @priority,    @user_hold,  @cdock_flg, @pass_bin, 
								@assigned_user,   @lbs_order_by, @avail_alloc_qty 

					COMMIT TRAN		
				END
				ELSE
				BEGIN
					BEGIN TRAN
						EXEC @ret = tdc_plw_so_allocate_line_sp @user_id, @template_code, @order_no,    @order_ext,  @line_no,   @part_no,          
										@one_for_one_flg, @bin_group, @search_sort, @alloc_type, @pkg_code,  @replen_group,
										@multiple_parts,  @bin_first, @priority,    @user_hold,  @cdock_flg, @pass_bin, 
										@assigned_user,   @lbs_order_by, @avail_alloc_qty -- v1.4 Pass in the max to alloc							
			                     							
					COMMIT TRAN			
				END
				-- END v1.7		
			END
			ELSE
			BEGIN
				SET @try_again = 'N'
				CONTINUE
			END
		END
		ELSE
		BEGIN
			-- START v1.7
			IF OBJECT_ID('tempdb..#no_stock_required') IS NOT NULL
			BEGIN
				BEGIN TRAN
				EXEC cvo_no_stock_get_bins_sp @user_id, @template_code, @order_no,    @order_ext,  @line_no,   @part_no,          
								@one_for_one_flg, @bin_group, @search_sort, @alloc_type, @pkg_code,  @replen_group,
								@multiple_parts,  @bin_first, @priority,    @user_hold,  @cdock_flg, @pass_bin, 
								@assigned_user,   @lbs_order_by 

				COMMIT TRAN		
			END
			ELSE
			BEGIN
				BEGIN TRAN
				EXEC @ret = tdc_plw_so_allocate_line_sp @user_id, @template_code, @order_no,    @order_ext,  @line_no,   @part_no,          
								@one_for_one_flg, @bin_group, @search_sort, @alloc_type, @pkg_code,  @replen_group,
								@multiple_parts,  @bin_first, @priority,    @user_hold,  @cdock_flg, @pass_bin, 
								@assigned_user,   @lbs_order_by
	                     							
				COMMIT TRAN	
			END
			-- END v1.7
		END
		-- v1.4 End

		-- START v1.7
		-- Get what's been allocated so far
		IF OBJECT_ID('tempdb..#no_stock_required') IS NOT NULL
		BEGIN
			SELECT 
				@qty_allocated = SUM(qty) 
			FROM 
				#no_stock_bins (NOLOCK) 
		END
		ELSE
		BEGIN
			SELECT 
				@qty_allocated = SUM(qty) 
			FROM 
				dbo.tdc_soft_alloc_tbl (NOLOCK) 
			WHERE 
				order_no = @order_no 
				AND order_ext = @order_ext 
				AND line_no = @line_no
		END
		--IF(SELECT SUM(qty) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no ) = @qty_to_alloc
		IF ISNULL(@qty_allocated,0) = @qty_to_alloc
		-- END v1.7
		BEGIN
			--line_no was allocated then go to next line_no	
			SET @try_again = 'N'
		END
		ELSE
		BEGIN -- v1.3 If its allocated then don't loop again
		--select * from tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no 
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
-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_allocate_by_bin_group_sp] TO [public]
GO
