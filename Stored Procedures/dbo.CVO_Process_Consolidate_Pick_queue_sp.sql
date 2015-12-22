SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_Process_Consolidate_Pick_queue_sp] @tran_id int
AS
BEGIN
	-- Declarations
	DECLARE	@id			int,
			@last_id	int,
			@order_no	int, 
			@ext		int, 
			@line_no	int, 
			@part_no	varchar(30), 
			@bin_no		varchar(20), 
			@lot_ser	varchar(20), 
			@location	varchar(10), 
			@date_exp	datetime, 
			@qty		decimal(20,8)

	SET @last_id = 0

	SELECT	TOP 1 @id = tran_id,
			@order_no = trans_type_no,
			@ext = trans_type_ext,
			@line_no = line_no,
			@part_no = part_no,
			@bin_no = bin_no,
			@lot_ser = lot,
			@location = location,
			@qty = qty_to_process
	FROM	dbo.tdc_pick_queue (NOLOCK)
	WHERE	tran_id_link = @tran_id
	AND		ISNULL(assign_user_id,'') = 'HIDDEN'
	AND		tran_id > @last_id
	ORDER BY tran_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Working tables
		IF (SELECT OBJECT_ID('tempdb..#serial_no')) IS NOT NULL 
		BEGIN   
			DROP TABLE #serial_no  
		END

		CREATE TABLE	#serial_no (
			serial_no	varchar(40) not null, 
			serial_raw	varchar(40) not null) 

		IF (SELECT OBJECT_ID('tempdb..#adm_pick_ship')) IS NOT NULL 
		BEGIN   
			DROP TABLE #adm_pick_ship  
		END

		CREATE TABLE #adm_pick_ship (
			order_no	int	not null, 
			ext			int	not null, 
			line_no		int	not null, 
			part_no		varchar(30) not null, 
			tracking_no	varchar(30) null, 
			bin_no		varchar(12) null, 
			lot_ser		varchar(25) null, 
			location	varchar(10) null, 
			date_exp	datetime null, 
			qty			decimal(20,8) not null, 
			err_msg		varchar(255) null, 
			row_id		int identity not null)

		IF (SELECT OBJECT_ID('tempdb..#pick_custom_kit_order')) IS NOT NULL 
		BEGIN   
			DROP TABLE #pick_custom_kit_order  
		END

		CREATE TABLE #pick_custom_kit_order(
			method		varchar(2) not null,
			order_no	int not null,
			order_ext	int not null,
			line_no		int not null,
			location	varchar(10) not null,
			item		varchar(30) null,
			part_no		varchar(30) not null,
			sub_part_no varchar(30) null,
			lot_ser		varchar(25) null,
			bin_no		varchar(12) null,
			quantity	decimal(20,8) not null,
			who			varchar(50) not null,
			row_id		int identity not null)

	-- Process each queue tran which is releated to the consolidated pick

		SELECT	@date_exp = date_expires
		FROM	dbo.lot_bin_stock (NOLOCK)
		WHERE	part_no = @part_no
		AND		lot_ser = @lot_ser
		AND		bin_no = @bin_no
		AND		location = @location

		-- Populate table with record to process
		INSERT INTO #adm_pick_ship (order_no, ext, line_no, part_no, bin_no, lot_ser, location, date_exp, 
									qty, err_msg) 													 
		VALUES(@order_no, @ext, @line_no, @part_no, @bin_no, @lot_ser, @location, @date_exp,
						           @qty, NULL)

		-- Call Standard routine to pick the queue record
-- v1.1		EXEC dbo.tdc_queue_xfer_ship_pick_sp @id,'','S',0
		EXEC dbo.tdc_queue_xfer_ship_pick_sp @id,'','S',-1 -- v1.1 Send through -1 to stop consolidated pack out



		SET @last_id = @id

		SELECT	TOP 1 @id = tran_id,
				@order_no = trans_type_no,
				@ext = trans_type_ext,
				@line_no = line_no,
				@part_no = part_no,
				@bin_no = bin_no,
				@lot_ser = lot,
				@location = location,
				@qty = qty_to_process
		FROM	dbo.tdc_pick_queue (NOLOCK)
		WHERE	tran_id_link = @tran_id
		AND		ISNULL(assign_user_id,'') = 'HIDDEN'
		AND		tran_id > @last_id
		ORDER BY tran_id ASC

	END

	-- Clean Up
	-- v1.2
--	DROP TABLE #serial_no
--	DROP TABLE #adm_pick_ship
--	DROP TABLE #pick_custom_kit_order
END
GO
GRANT EXECUTE ON  [dbo].[CVO_Process_Consolidate_Pick_queue_sp] TO [public]
GO
