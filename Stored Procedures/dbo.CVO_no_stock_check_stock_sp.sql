SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 24/07/2013 - Issue #1040 - No stock process 2013
-- v1.1 CB 07/11/2017 - Add process info for tdc_log
-- v1.2 CB 07/03/2018 - Issue #1660 - No Stock Hold
/*
Returns:
0	= 1 bin found - transaction updated
1	= mutliple bins found
-1	= not enough stock found
*/

CREATE PROC [dbo].[CVO_no_stock_check_stock_sp]	@order_no INT, @ext INT, @line_no INT, @tran_id INT
AS 
BEGIN
	SET NOCOUNT ON

	DECLARE	@qty_required		DECIMAL(20,8),
			@location			VARCHAR(10),
			@part_no			VARCHAR(30),
			@qty_allocated		DECIMAL(20,8),
			@bin_no				VARCHAR(12),
			@lot_ser			VARCHAR(25),
			@qty				DECIMAL(20,8),
			@current_bin_no		VARCHAR(12),
			@current_lot_ser	VARCHAR(25),
			@rec_id				INT,
			@new_tran_id		INT

	-- Get line details
	SELECT
		@location = location,
		@part_no = part_no,
		--@qty_required = qty_to_process - qty_processed,
		@qty_required = qty_to_process,
		@current_bin_no = bin_no,
		@current_lot_ser = lot
	FROM
		dbo.tdc_pick_queue (NOLOCK)
	WHERE
		tran_id = @tran_id

	-- Create temporary tables
	IF OBJECT_ID('tempdb..#no_stock_required')   IS NOT NULL DROP TABLE #no_stock_required     
	CREATE TABLE #no_stock_required (
		qty			DECIMAL(20,8),
		location	VARCHAR(10),
		bin_no		VARCHAR(12))

	IF OBJECT_ID('tempdb..#no_stock_bins')   IS NOT NULL DROP TABLE #no_stock_bins
	CREATE TABLE #no_stock_bins (
		rec_id	INT IDENTITY (1,1),
		bin_no	VARCHAR(12),
		lot_ser VARCHAR(25),
		qty		DECIMAL(20,8))

	-- Load details into temp table
	INSERT INTO #no_stock_required VALUES(@qty_required,@location,@current_bin_no)

	EXEC dbo.cvo_auto_alloc_process_sp 1, 'CVO_no_stock_check_stock_sp' -- v1.1

	-- Call routine to search for stock
	EXEC CVO_allocate_by_bin_group_sp  'AUTO_ALLOC', 'AUTO_ALLOC', @order_no, @ext, @line_no, @part_no, 'Y',  
					NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1   	

	EXEC dbo.cvo_auto_alloc_process_sp 0 -- v1.1

	-- Check if there is enough stock			
	SELECT @qty_allocated = SUM(qty) FROM #no_stock_bins 
	WHERE bin_no <> @current_bin_no -- v1.2

	IF ISNULL(@qty_allocated,0) < @qty_required
	BEGIN
		-- No stock available
		RETURN -1
	END
	ELSE
	BEGIN

		-- Is there only one bin needed to fulfil the required qty
		IF (SELECT COUNT(1) FROM #no_stock_bins) = 1
		BEGIN
			SELECT 
				@bin_no = bin_no,
				@lot_ser = lot_ser
			FROM
				#no_stock_bins

			-- Update existing records
			UPDATE
				tdc_soft_alloc_tbl               
			SET            
				bin_no = @bin_no,              
				target_bin = @bin_no,
				lot_ser = @lot_ser,
				trg_off = 1			
			WHERE 
				order_no = @order_no               
				AND order_ext = @ext              
				AND order_type = 'S'              
				AND location = @location               
				AND line_no = @line_no              
				AND part_no = @part_no               
				AND lot_ser = @current_lot_ser               
				AND bin_no = @current_bin_no                
		
			UPDATE
				tdc_pick_queue
			SET
				bin_no = @bin_no,
				lot = @lot_ser
			WHERE
				tran_id = @tran_id

			UPDATE
				tdc_soft_alloc_tbl               
			SET            
				trg_off = 0		
			WHERE 
				order_no = @order_no               
				AND order_ext = @ext              
				AND order_type = 'S'              
				AND location = @location               
				AND line_no = @line_no              
				AND part_no = @part_no               
				AND lot_ser = @lot_ser               
				AND bin_no = @bin_no 

			-- Hold tran_id on table related to the current tran_id
			INSERT INTO CVO_no_stock_linked_pick_trans(
				parent_tran_id,
				tran_id,
				create_date,
				create_user)
			SELECT
				@tran_id,
				@tran_id,
				GETDATE(),
				SUSER_SNAME()

			-- Pick record updated
			RETURN 0
		END
		ELSE
		BEGIN
			-- loop through bin records and allocate them
			SET @rec_id = 0
		
			WHILE 1=1
			BEGIN
				SELECT TOP 1
					@rec_id = rec_id,
					@bin_no = bin_no,
					@lot_ser = lot_ser,
					@qty = qty
				FROM
					#no_stock_bins
				WHERE
					rec_id > @rec_id
				ORDER BY 
					rec_id

				IF @@ROWCOUNT = 0
					BREAK

				-- Allocate
				INSERT INTO tdc_soft_alloc_tbl              
					(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty, order_type,               
					target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold, pkg_code)              
				SELECT  order_no, order_ext, location, line_no, part_no, @lot_ser, @bin_no, @qty, 'S', 
					@bin_no, dest_bin, alloc_type, q_priority, assigned_user, user_hold, pkg_code
				FROM
					tdc_soft_alloc_tbl (NOLOCK)
				WHERE
					order_no      = @order_no               
					AND order_ext     = @ext              
					AND order_type    = 'S'              
					AND location      = @location               
					AND line_no       = @line_no              
					AND part_no       = @part_no               
					AND lot_ser       = @current_lot_ser               
					AND bin_no        = @current_bin_no

				SELECT @new_tran_id = @@IDENTITY

				-- Hide the pick queue record
				UPDATE tdc_pick_queue SET assign_user_id = 'HIDDEN' WHERE tran_id = @new_tran_id
				
				-- Hold tran_id on table related to the current tran_id
				INSERT INTO CVO_no_stock_linked_pick_trans(
					parent_tran_id,
					tran_id,
					create_date,
					create_user)
				SELECT
					@tran_id,
					@new_tran_id,
					GETDATE(),
					SUSER_SNAME()
			END

			-- Mutliple picks created
			RETURN 1
		END
	END
END
GO
GRANT EXECUTE ON  [dbo].[CVO_no_stock_check_stock_sp] TO [public]
GO
