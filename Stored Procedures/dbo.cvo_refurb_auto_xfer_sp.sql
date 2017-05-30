SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_refurb_auto_xfer_sp] @xfer_no int,
										@user varchar(50)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- WORKING TABLES
	IF (SELECT OBJECT_ID('tempdb..#serial_no')) IS NOT NULL 
	BEGIN   
		DROP TABLE #serial_no  
	END

	CREATE TABLE #serial_no (
		serial_no	varchar(40) not null, 
		serial_raw	varchar(40)	not null) 

	IF (SELECT OBJECT_ID('tempdb..#adm_pick_xfer')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_pick_xfer  
	END

	CREATE TABLE #adm_pick_xfer (
		xfer_no		int not null,
		line_no		int not null,
		from_loc	varchar(10) not null,
		part_no		varchar(30) not null,
		bin_no		varchar(12) null,
		lot_ser		varchar(25) null,
		date_exp	datetime null,
		qty			decimal(20,8) not null,
		who			varchar(50) not null,
		err_msg		varchar(255) null,
		row_id int identity not null)

	IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL 
	BEGIN
		DROP TABLE #temp_who
	END

	CREATE TABLE #temp_who (  
		who			varchar(50),  
		login_id	varchar(50)) 
	
	INSERT	#temp_who
	SELECT	@user, @user

	IF OBJECT_ID('tempdb..#adm_ship_order') IS NOT NULL 
	BEGIN
		DROP TABLE #adm_ship_order
	END

	CREATE TABLE #adm_ship_order (
		order_no		int not null,
		ext				int not null,
		who				varchar(50) not null, 
		err_msg			varchar(255) null,
		row_id			int identity not null)    

	IF OBJECT_ID('tempdb..#cartonsToShip') IS NOT NULL  
	BEGIN
		DROP TABLE #cartonsToShip
	END

	CREATE TABLE #cartonsToShip (
		order_no		int,
		order_ext		int,
		carton_no		int,
		tot_ord_freight decimal(20,8), 
		tot_multi_carton_ord_freight decimal(20,8),  
		master_pack		char(1),
		commit_ok		int,
		first_so_in_carton int) 

	IF OBJECT_ID('tempdb..#xfersToShip') IS NOT NULL  
	BEGIN
		DROP TABLE #xfersToShip
	END

	CREATE TABLE #xfersToShip (
		order_no		int,  
		order_ext		int,
		carton_no		int,  
		commit_ok		int) 

	IF (SELECT OBJECT_ID('tempdb..#xfer_serials')) IS NOT NULL
	BEGIN
		DROP TABLE #xfer_serials
	END
	
	CREATE TABLE #xfer_serials (
		part_no    varchar(30) not null,
		lot_ser    varchar(25) not null,
		serial_no  varchar(40) null,
		serial_raw varchar(40) null)

	IF (SELECT OBJECT_ID('tempdb..#adm_rec_xfer')) IS NOT NULL
	BEGIN
		DROP TABLE #adm_rec_xfer
	END
		            
	CREATE TABLE #adm_rec_xfer (
		xfer_no		Int	not null, 
		part_no		varchar(30)	not null, 
		line_no		int not null, 
		from_bin	varchar(12) null, 
		lot_ser		varchar (25) null, 
		to_bin		varchar (12) null, 
		location	varchar(10) not null, 
		qty			decimal(20,8) not null, 
		who			varchar(50) null, 
		err_msg		varchar(255) null, 
		row_id		int identity not null)

	IF (SELECT OBJECT_ID('tempdb..#cvo_atm_det_cur')) IS NOT NULL
	BEGIN
		DROP TABLE #cvo_atm_det_cur
	END

	CREATE TABLE #cvo_atm_det_cur (
		row_id		int IDENTITY(1,1),
		tran_no		int,
		part_no		varchar(30) NULL,
		line_no		int,
		lot_ser		varchar(25) NULL,
		bin_no		varchar(12) NULL,
		location	varchar(10) NULL,
		qty			decimal(20,8),
		who			varchar(50) NULL)

	IF OBJECT_ID('tempdb..#temp_ship_confirm_display_tbl') IS NOT NULL 
	BEGIN
		DROP TABLE #temp_ship_confirm_display_tbl
	END

	IF OBJECT_ID('tempdb..#tdc_ship_xfer') IS NOT NULL 
	BEGIN
		DROP TABLE #tdc_ship_xfer                
	END

	IF OBJECT_ID('tempdb..#temp_fedex_close_tbl') IS NOT NULL 
	BEGIN
		DROP TABLE #temp_fedex_close_tbl         
	END

	IF OBJECT_ID('tempdb..#temp_ship_confirm_cartons') IS NOT NULL 
	BEGIN
		DROP TABLE #temp_ship_confirm_cartons    
	END

	CREATE TABLE #temp_ship_confirm_cartons (carton_no int not null)                 
 
	CREATE TABLE #temp_fedex_close_tbl (
		sel_flg         int not null default 0,
		location        varchar(10) not null)            

	CREATE TABLE #temp_ship_confirm_display_tbl (
		selected		int default 0,
		stage_no        varchar(50) not null,
		carton_no       int not null,
		master_pack     char(1) not null,
		order_no        int not null, 
		order_ext       int not null,
		tdc_ship_flag   char(1) null,
		adm_ship_flag   char(1) null,
		tdc_ship_date   datetime null,
		adm_ship_date   datetime null,
		carrier_code    varchar(10) null,
		stage_hold      char(1))                    

	CREATE TABLE #tdc_ship_xfer (
		xfer_no			int not null,
		err_msg			varchar(255) null,
		who				varchar(50) not null,    
		row_id			int identity not null)

	-- DECLARTIONS
	DECLARE @tran_id		int,
			@last_tran_id	int,
			@line_no		int,
			@location		varchar(10),
			@part_no		varchar(30),
			@lot			varchar(25),
			@bin_no			varchar(12),
			@expiry_date	datetime,
			@qty			decimal(20,8),
			@carton_no		int,
			@err_msg		varchar(255),
			@ret			int,
			@stage_no		varchar(40),
			@currentstage	varchar(255),    
			@allshipped		int,
			@row_id			int,
			@last_row_id	int

	-- Check if the transfer has been allocated and if so then pick
	IF EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans_source = 'PLW' AND trans = 'XFERPICK' AND trans_type_no = @xfer_no)
	BEGIN

		-- v1.1 Start
		UPDATE	xfers_all
		SET		back_ord_flag = 2
		WHERE	xfer_no = @xfer_no

		UPDATE	xfer_list
		SET		back_ord_flag = 2
		WHERE	xfer_no = @xfer_no
		-- v1.1 End

		SET @last_tran_id = 0

		SELECT	TOP 1 @tran_id = tran_id,
				@line_no = line_no,
				@location = location,
				@part_no = part_no,
				@lot = lot,
				@bin_no = bin_no,
				@qty = qty_to_process
		FROM	tdc_pick_queue (NOLOCK)
		WHERE	trans_source = 'PLW' 
		AND		trans = 'XFERPICK' 
		AND		trans_type_no = @xfer_no
		AND		tran_id > @last_tran_id
		ORDER BY tran_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN				
			TRUNCATE TABLE #serial_no
			TRUNCATE TABLE #adm_pick_xfer

			SELECT	@expiry_date = date_expires
			FROM	lot_bin_stock (NOLOCK)
			WHERE	location = @location
			AND		part_no = @part_no
			AND		bin_no = @bin_no
			AND		lot_ser = @lot

			IF (@@ROWCOUNT = 0)
				RETURN -2
			
			INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, bin_no, lot_ser, date_exp, qty, who) 												 
			VALUES (@xfer_no, @line_no, @location, @part_no, @bin_no, @lot, @expiry_date, @qty, @user)

			EXEC tdc_queue_xfer_ship_pick_sp @tran_id,'','T','0'

			SET @last_tran_id = @tran_id

			SELECT	TOP 1 @tran_id = tran_id,
					@line_no = line_no,
					@location = location,
					@part_no = part_no,
					@lot = lot,
					@bin_no = bin_no,
					@qty = qty_to_process
			FROM	tdc_pick_queue (NOLOCK)
			WHERE	trans_source = 'PLW' 
			AND		trans = 'XFERPICK' 
			AND		trans_type_no = @xfer_no
			AND		tran_id > @last_tran_id
			ORDER BY tran_id ASC
		END

	END
	ELSE
	BEGIN -- Otherwise return fail
		RETURN -1
	END

	-- Close Carton
	SELECT	@carton_no = carton_no
	FROM	tdc_carton_tx (NOLOCK)
	WHERE	order_no = @xfer_no
	AND		order_type = 'T'

	IF (@@ROWCOUNT = 0)
		RETURN -3

	EXEC @ret = dbo.tdc_close_carton_sp @carton_no, '999', @user, 1, @err_msg OUTPUT  

	IF (@ret <> 1)
		RETURN -4

	SELECT @stage_no = 'XFER-' + CAST(@xfer_no as varchar(10))
	EXEC @ret = dbo.tdc_stage_carton_or_mp_sp @carton_no, @stage_no, 1, '999', @user, @err_msg OUTPUT

	IF (@ret <> 0)
		RETURN -5

	EXEC dbo.tdc_ship_confirm_temp_tables 0, @stage_no,'ALL','999'
	EXEC @ret = dbo.tdc_ship_confirm_sp @stage_no, 0, @user, 'Y', @currentstage OUTPUT, @allshipped OUTPUT, @err_msg OUTPUT

	IF (@ret <> 1)
		RETURN -6

	INSERT	#cvo_atm_det_cur (tran_no, part_no, line_no, lot_ser, bin_no, location, qty, who)
	SELECT	tran_no, part_no, line_no, lot_ser, MIN(to_bin), location, SUM(qty), MIN(who) 
	FROM	lot_bin_xfer (NOLOCK) 
	WHERE	tran_no = @xfer_no 
	AND		tran_ext = 0
	GROUP BY tran_no, part_no, line_no, lot_ser,  location

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@part_no = part_no,
			@line_no = line_no,
			@lot = lot_ser,
			@bin_no = bin_no,
			@location = location,
			@qty = qty
	FROM	#cvo_atm_det_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
	
	WHILE @@ROWCOUNT <> 0
	BEGIN
	
		INSERT INTO #adm_rec_xfer (xfer_no, part_no, line_no, from_bin, lot_ser, to_bin, location, qty, who, err_msg) 									
		VALUES (@xfer_no, @part_no, @line_no, @bin_no, @lot, 'RR REFURB', '001', @qty, @user, NULL)
		   
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@part_no = part_no,
				@line_no = line_no,
				@lot = lot_ser,
				@bin_no = bin_no,
				@location = location,
				@qty = qty
		FROM	#cvo_atm_det_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	EXEC @err_msg = dbo.tdc_rec_xfer
			
	IF @err_msg = 0
		RETURN -7

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_refurb_auto_xfer_sp] TO [public]
GO
