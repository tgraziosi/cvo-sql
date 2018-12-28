SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_autopick_transfer_line_sp] (@tran_id INT,  @user_id varchar(50))
AS
BEGIN

	SET NOCOUNT ON -- v1.1

	DECLARE @location		VARCHAR(10),
			@part_no		VARCHAR(30),
			@qty_to_process DECIMAL(20,8),
			@bin_no			VARCHAR(12),
			@lot			VARCHAR(25),
			@trans_type_no	INT,
			@line_no		INT,
			@in_stock		DECIMAL(20,8),
			@in_bin			DECIMAL(20,8),
			@allocated		DECIMAL(20,8),
			@uom			CHAR(2),
			@group_code		VARCHAR(10),
			@data			VARCHAR(7500),
			@date_expires	DATETIME,
			@retval			INT

	-- Lock pick record
	UPDATE 
		dbo.tdc_pick_queue 
	SET 
		date_time = getdate(), 
		[user_id] = @user_id, 
		tx_lock = 'C' 
	WHERE 
		tran_id = @tran_id

	-- Get info from pick record
	SELECT
		@part_no = part_no,
		@location = location,
		@qty_to_process = qty_to_process,
		@bin_no = bin_no,
		@lot = lot,
		@trans_type_no = trans_type_no,
		@line_no = line_no
	FROM
		dbo.tdc_pick_queue (NOLOCK)
	WHERE
		tran_id = @tran_id

	-- Get qty in stock
	SELECT 
		@in_stock = in_stock 
	FROM 
		dbo.inventory (NOLOCK) 						
	WHERE 
		location = @location 
		AND part_no = @part_no

	IF @qty_to_process > ISNULL(@in_stock,0)
	BEGIN
		Goto ReleaseRecord
	END

	-- Get qty in bin
	SELECT 
		@in_bin = qty,
		@date_expires = CONVERT(varchar(12), date_expires, 109) 
	FROM 
		dbo.lot_bin_stock (NOLOCK) 							
	WHERE 
		location = @location 
		AND part_no = @part_no 
		AND bin_no = @bin_no 
		AND lot_ser = @lot

	IF @qty_to_process > ISNULL(@in_bin,0)
	BEGIN
		Goto ReleaseRecord
	END

	-- Get qty allocated
	SELECT 
		@allocated = qty 
	FROM 
		tdc_soft_alloc_tbl (NOLOCK) 							
	WHERE 
		order_no = @trans_type_no 
		AND order_ext = 0 
		AND part_no = @part_no 							
		AND line_no = @line_no 
		AND lot_ser = @lot 
		AND bin_no = @bin_no 
		AND order_type = 'T'

	IF @qty_to_process > ISNULL(@allocated,0)
	BEGIN
		Goto ReleaseRecord
	END

	-- Create temporary tables
	CREATE TABLE #serial_no (
		serial_no	varchar(40)		not null, 
		serial_raw	varchar(40)		not null) 

	CREATE TABLE #adm_pick_xfer(
		xfer_no int not null,
		line_no int not null,
		from_loc varchar(10) not null,
		part_no varchar(30) not null,
		bin_no varchar(12) null,
		lot_ser varchar(25) null,
		date_exp datetime null,
		qty decimal(20,8) not null,
		who varchar(50) not null,
		err_msg varchar(255) null,
		row_id int identity not null)

	-- Create temp_who table if it doesn't exist
	IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NULL 
	BEGIN   
		CREATE TABLE #temp_who (
			who		VARCHAR(50),
			login_id	VARCHAR(50))
		
		INSERT INTO #temp_who (who, login_id) VALUES (@user_id, @user_id)
	END

	-- Get additional info for logs
	SELECT 
		@uom = uom 
	FROM 
		dbo.inv_master (NOLOCK) 
	WHERE 
		part_no = @part_no

	SELECT 
		@group_code = group_code 
	FROM 
		dbo.tdc_bin_master (NOLOCK) 
	WHERE 
		location = @location 
		AND bin_no = @bin_no

	-- Write logs
	INSERT INTO dbo.tdc_ei_performance_log ( 										
		start_tran, 
		userid, 
		tran_type, 
		trans, 
		tran_no, 
		tran_ext, 
		location, 
		part_no, 
		quantity) 								
	SELECT
		GETDATE(),
		@user_id, 
		'XFPICKER', 
		'XFERPICK',		
		@trans_type_no,			
		0,		
		@location,	
		@part_no,	          
		@qty_to_process

	INSERT INTO dbo.tdc_ei_bin_log (
		module, 
		trans, 
		tran_no, 
		tran_ext,	
		location, 
		part_no, 
		from_bin, 
		begin_tran,	
		userid, 
		direction, 
		quantity) 														
	SELECT
		'QTX',	  
		'XFERPICK', 
		@trans_type_no,		
		0,			
		@location,
		@part_no,	
		@bin_no,	  
		GETDATE(),			
		@user_id,    
		-1,                  
		@qty_to_process

	INSERT INTO dbo.tdc_3pl_pick_log (
		trans,		
		tran_no, 
		tran_ext, 
		location, 
		line_no, 
		part_no, 
		bin_no, 
		bin_group, 
		uom, 
		qty, 
		userid, 
		expert) 																
	SELECT 
		'QXFERPICK', 
		@trans_type_no,		
		0,		
		@location,	  
		@line_no, 	
		@part_no,	
		@bin_no,	
		@group_code,	
		@uom,
		@qty_to_process,  
		@user_id, 
		'N'


	-- Load temporary table
	INSERT INTO #adm_pick_xfer (
		xfer_no, 
		line_no, 
		from_loc, 
		part_no, 
		bin_no, 
		lot_ser, 
		date_exp, 
		qty, 
		who) 												 
	SELECT
		@trans_type_no, 
		@line_no, 
		@location, 
		@part_no,
		@bin_no, 
		@lot, 
		@date_expires,           
		@qty_to_process,
		@user_id

	-- Execute transfer pick
	EXEC @retval = tdc_queue_xfer_ship_pick_sp @tran_id,'','T','0'
	
	IF @retval <> 0
	BEGIN
		Goto ReleaseRecord
	END

	-- More logs
	INSERT INTO dbo.tdc_ei_transaction_log ( 
		begin_tran, 
		module, 
		trans, 
		location, 
		userid, 
		num_of_trans) 							
	SELECT
		GETDATE(), 
		'QTX', 
		'XFERPICK', 
		@location, 
		@user_id, 
		1

	SELECT @data = dbo.f_create_tdc_log_transfer_data_string (@trans_type_no,@line_no)

	INSERT INTO tdc_log (
		tran_date,
		UserID,
		trans_source,
		module,
		trans,
		tran_no,
		tran_ext,
		part_no,
		lot_ser,
		bin_no,
		location,
		quantity,
		data) 										
	SELECT 
		GETDATE(), 
		@user_id, 
		'CO', 
		'QTX', 
		'XFERPICK', 
		CAST(@trans_type_no AS VARCHAR(16)), 
		'', 
		@part_no, 
		@lot, 
		@bin_no, 
		@location, 
		CAST(CAST(@qty_to_process AS INT) AS VARCHAR(20)), 
		@data

	ReleaseRecord:
	UPDATE 
		dbo.tdc_pick_queue 
	SET 
		tx_lock = 'R', 
		user_id = NULL 
	WHERE 
		tran_id = @tran_id
	
	RETURN
END
GO
GRANT EXECUTE ON  [dbo].[cvo_autopick_transfer_line_sp] TO [public]
GO
