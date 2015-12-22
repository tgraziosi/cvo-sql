SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_graphical_bin_view_check_max_values_sp]
	@location		varchar(10),
	@from_bin		varchar(12),
	@to_bin			varchar(12),
	@current_to_bin_qty	decimal(20,8) OUTPUT,
	@qty_over_max		decimal(20,8) OUTPUT

AS
DECLARE
	@from_bin_qty		decimal(20,8),
	@alloc_parts		decimal(20,8),
	@total_parts_to_move	decimal(20,8),
	@to_bin_qty		decimal(20,8),
	@to_bin_max		decimal(20,8),
	@to_bin_queue_qty	decimal(20,8)
	
	IF EXISTS(SELECT * FROM tdc_bin_master (NOLOCK) WHERE location = @location AND bin_no = @to_bin AND maximum_level = 0)
	BEGIN
		SELECT @qty_over_max = 0, @current_to_bin_qty = 0
		RETURN 0
	END
--SUM THE TOTAL NUMBER OF AVAILABLE PARTS FROM THE: FROM BIN
	SELECT @from_bin_qty = ISNULL(SUM(qty), 0) 
		FROM lot_bin_stock (NOLOCK) WHERE location = @location AND bin_no = @from_bin

--SUBTRACT ALLOCATED QUANTITIES FROM THE: FROM BIN
	SELECT @alloc_parts = ISNULL(SUM(qty), 0) 
		FROM tdc_soft_alloc_tbl (NOLOCK) WHERE location = @location and bin_no = @from_bin

--TOTAL NUMBER OF PARTS AVAILABLE TO MOVE
	SELECT @total_parts_to_move = @from_bin_qty - @alloc_parts

--GET THE MAXIMUM LEVEL FOR THE: TO BIN
	SELECT @to_bin_max = ISNULL(maximum_level, 0)
		FROM tdc_bin_master (NOLOCK) WHERE location = @location AND bin_no = @to_bin

--SUM THE TOTAL NUMBER OF PARTS CURRENTLY IN THE:   TO BIN
	SELECT @to_bin_qty = ISNULL(SUM(qty), 0)
		FROM lot_bin_stock (NOLOCK) WHERE location = @location AND bin_no = @to_bin
--SUM THE TOTAL NUMBER OF PARTS ON QUEUE TO THE:    TO BIN
	SELECT @to_bin_queue_qty = ISNULL((SUM(qty_to_process)-SUM(qty_processed)), 0) FROM tdc_pick_queue (NOLOCK) WHERE next_op = @to_bin

	IF @to_bin_qty + @to_bin_queue_qty + @total_parts_to_move > @to_bin_max
	BEGIN
		SELECT 	@qty_over_max = (@to_bin_qty + @to_bin_queue_qty + @total_parts_to_move - @to_bin_max), 
			@current_to_bin_qty = @to_bin_qty
		RETURN -1
	END
SELECT @qty_over_max = 0, @current_to_bin_qty = @to_bin_qty
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_graphical_bin_view_check_max_values_sp] TO [public]
GO
