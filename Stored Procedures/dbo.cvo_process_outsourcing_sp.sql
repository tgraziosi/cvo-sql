SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_process_outsourcing_sp]	@process		varchar(5),
											@rqty			decimal(20,8),
											@part_no		varchar(30),
											@tran_no		int,
											@proc_date		datetime,
											@who			varchar(50),
											@location		varchar(10)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @retval			int,
			@xfer_no		int,
			@line_no		int,
			@temp_part_no	varchar(30),
			@fg_part_no		varchar(30),
			@serial_no		int,
			@bin_no			varchar(20),
			@seq_no			int

	-- WORKING TABLES
	IF (SELECT OBJECT_ID('tempdb..#adm_pick_xfer')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_pick_xfer  
	END

	CREATE TABLE #adm_pick_xfer (
		xfer_no			int not null,
		line_no			int not null,
		from_loc		varchar(10) not null,
		part_no			varchar(30) not null,
		bin_no			varchar(12) null,
		lot_ser			varchar(25) null,
		date_exp		datetime null,
		qty				decimal(20,8) not null,
		who				varchar(50) not null,
		err_msg			varchar(255) null,
		row_id			int identity not null)
	
	IF (SELECT OBJECT_ID('tempdb..#tdc_ship_xfer')) IS NOT NULL 
	BEGIN   
		DROP TABLE #tdc_ship_xfer  
	END

	CREATE TABLE #tdc_ship_xfer (
		xfer_no		int not null,
		err_msg		varchar(255) null,
		row_id		int identity not null)

	IF (SELECT OBJECT_ID('tempdb..#adm_rec_xfer')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_rec_xfer  
	END

	CREATE TABLE #adm_rec_xfer (
		xfer_no		int not null,
		part_no		varchar (30) not null,
		line_no		int not null,
		from_bin	varchar (12) null,
		lot_ser		varchar (25) null,
		to_bin		varchar (12) null,
		location	varchar(10) not null, 
		qty			decimal(20,8) not null, 
		who			varchar(50) null,
		err_msg		varchar(255) null, 
		row_id		int identity not null)

	IF (SELECT OBJECT_ID('tempdb..#xfer_serials')) IS NOT NULL 
	BEGIN   
		DROP TABLE #xfer_serials  
	END

	CREATE TABLE #xfer_serials (
		part_no		varchar (30) not null,
		lot_ser		varchar (25) not null,
		serial_no	varchar (40) null,
		serial_raw	varchar (40) null)
	
	IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_inv_adj  
	END

	CREATE TABLE #adm_inv_adj (
		adj_no		int null,
		loc			varchar(10)	not null,
		part_no		varchar(30) not null,
		bin_no		varchar(12) null,
		lot_ser		varchar(25) null,
		date_exp	datetime null,
		qty			decimal(20,8) not null,
		direction	int not null,
		who_entered	varchar(50) not null,
		reason_code	varchar(10) null,
		code		varchar(8) not null,
		cost_flag	char(1) null,
		avg_cost	decimal(20,8) null,
		direct_dolrs decimal(20,8) null,
		ovhd_dolrs	decimal(20,8) null,
		util_dolrs	decimal(20,8) null,
		err_msg		varchar(255) null,
		row_id		int identity not null)

	-- PROCESSING
	IF (@process = 'RAW')
	BEGIN

		SET @temp_part_no = LEFT(@part_no,CHARINDEX('-',@part_no)-1) + '-MAKE'
		IF EXISTS ( SELECT 1 FROM agents (NOLOCK) WHERE part_no = @temp_part_no and agent_type = 'B' )  
		BEGIN  

			SELECT	@location = vendor
			FROM	inv_master (NOLOCK)
			WHERE	part_no = @temp_part_no

			SET @temp_part_no = LEFT(@part_no,CHARINDEX('-',@part_no)-1) + '-RAW'

			IF NOT EXISTS (SELECT 1 FROM lot_bin_stock (NOLOCK) WHERE location = '001' AND part_no = @temp_part_no AND bin_no = 'FRAMEWIP' AND qty >= @rqty)
			BEGIN
				EXEC adm_raiserror 81234 ,'Not enough RAW material to process transfer!'  
				RETURN  
			END

			EXEC @retval = fs_agent @temp_part_no, 'B', @tran_no, @proc_date, @who, @rqty  
			
			IF (@retval = -3)   
			BEGIN  
				EXEC adm_raiserror 81234 ,'Agent Error... Outsource item not found on this Prod No!'  
				RETURN  
			END  
			IF (@retval <= 0)   
			BEGIN  
				EXEC adm_raiserror 81235 ,'Agent Error... Try Re-Saving!'  
				RETURN  
			END
	
			-- Process transfer
			-- Picking
			SET @temp_part_no = LEFT(@part_no,CHARINDEX('-',@part_no)-1) + '-RAW'

			SELECT	TOP 1 @xfer_no = xfer_no,
					@line_no = line_no
			FROM	xfer_list (NOLOCK)
			WHERE	from_loc = '001'
			AND		to_loc = @location
			AND		status = 'N'
			AND		part_no = @temp_part_no
			ORDER BY xfer_no DESC

			SET @proc_date = @proc_date + 365

			INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, bin_no, lot_ser, date_exp, qty, who, err_msg) 							
			VALUES(@xfer_no, @line_no, '001', @temp_part_no, 'FRAMEWIP', '1', @proc_date, @rqty, @who, NULL)

			EXEC tdc_pick_xfer 

			IF (@@ERROR <> 0)
			BEGIN
				EXEC adm_raiserror 81235 ,'Error picking transfer for RAW part(1)!'  
				RETURN
			END

			IF NOT EXISTS(SELECT 1 FROM tdc_dist_item_pick (NOLOCK) WHERE method = '01' AND order_no = @xfer_no AND line_no = @line_no AND part_no = @temp_part_no 
							AND lot_ser = '1' AND bin_no = 'FRAMEWIP' AND [function] = 'T') 
			BEGIN
				EXEC @serial_no = tdc_get_serialno 

				INSERT INTO tdc_dist_item_pick(method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, quantity, child_serial_no, [function], type)
				VALUES('01', @xfer_no, 0, @line_no, @temp_part_no, '1', 'FRAMEWIP', @rqty, @serial_no, 'T', 'O1')

				UPDATE tdc_xfers SET tdc_status = 'O1' WHERE xfer_no = @xfer_no 
			END

			IF (@@ERROR <> 0)
			BEGIN
				EXEC adm_raiserror 81235 ,'Error picking transfer for RAW part(2)!'  
				RETURN
			END

			INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			VALUES (GETDATE(), @who, 'CO', 'ADH', 'OUTSOURCE', @xfer_no, '', @temp_part_no, '1', 'FRAMEWIP', '001', CAST(@rqty as varchar(20)), 'Pick transfer for RAW part')

			-- Shipping
			INSERT INTO #tdc_ship_xfer (xfer_no, err_msg) 
			VALUES(@xfer_no, NULL)

			EXEC tdc_ship_xfer_sp 

 			IF (@@ERROR <> 0)
			BEGIN
				EXEC adm_raiserror 81235 ,'Error shipping transfer for RAW part!'  
				RETURN
			END

			INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			VALUES (GETDATE(), @who, 'CO', 'ADH', 'OUTSOURCE', @xfer_no, '', @temp_part_no, '1', 'FRAMEWIP', '001', CAST(@rqty as varchar(20)), 'Ship transfer for RAW part')
		
			-- Receiving
			INSERT INTO #adm_rec_xfer (xfer_no, part_no, line_no, from_bin, lot_ser, to_bin, location, qty, who, err_msg) 									
			VALUES (@xfer_no, @temp_part_no, @line_no, '', '1', 'OUTBIN', @location, @rqty, @who, NULL)

			EXEC tdc_rec_xfer 

			IF (@@ERROR <> 0)
			BEGIN
				EXEC adm_raiserror 81235 ,'Error receiving transfer for RAW part!'  
				RETURN
			END

			INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			VALUES (GETDATE(), @who, 'CO', 'ADH', 'OUTSOURCE', @xfer_no, '', @temp_part_no, '1', 'OUTBIN', @location, CAST(@rqty as varchar(20)), 'Receive transfer for RAW part')
		END 
	END

	IF (@process = 'MAKE')
	BEGIN
		IF EXISTS ( SELECT 1 FROM agents (NOLOCK) WHERE part_no = @part_no and agent_type = 'R' )  
		BEGIN  
			EXEC @retval = fs_agent @part_no, 'R', @tran_no, @proc_date, @who, @rqty
  
			IF (@retval = -3)  
			BEGIN  
				EXEC adm_raiserror 81324 ,'Agent Error... Outsource item not found on this Prod No!'  
				RETURN  
			END  
  
			IF (@retval <= 0)
			BEGIN  
				EXEC adm_raiserror 81325, 'Agent Error... Try Re-Saving!'  
				RETURN  
			END  

			-- Process Transfer
			-- Picking
			SET @temp_part_no = LEFT(@part_no,CHARINDEX('-',@part_no)-1) + '-FG'

			SELECT	TOP 1 @xfer_no = xfer_no,
					@line_no = line_no
			FROM	xfer_list (NOLOCK)
			WHERE	from_loc = @location
			AND		to_loc = '001'
			AND		status = 'N'
			AND		part_no = @temp_part_no
			ORDER BY xfer_no DESC

			SET @proc_date = @proc_date + 365

			INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, bin_no, lot_ser, date_exp, qty, who, err_msg) 							
			VALUES(@xfer_no, @line_no, @location, @temp_part_no, 'OUTBIN', '1', @proc_date, @rqty, @who, NULL)

			EXEC tdc_pick_xfer 

			IF (@@ERROR <> 0)
			BEGIN
				EXEC adm_raiserror 81235 ,'Error picking transfer for finished part(1)!'  
				RETURN
			END

			IF NOT EXISTS(SELECT 1 FROM tdc_dist_item_pick (NOLOCK) WHERE method = '01' AND order_no = @xfer_no AND line_no = @line_no AND part_no = @temp_part_no 
						AND lot_ser = '1' AND bin_no = 'OUTBIN' AND [function] = 'T')
			BEGIN
				EXEC @serial_no = tdc_get_serialno 

				INSERT INTO tdc_dist_item_pick(method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, quantity, child_serial_no, [function], type) 								
				VALUES('01', @xfer_no, 0, @line_no, @temp_part_no, '1', 'OUTBIN', @rqty, @serial_no, 'T', 'O1')

				UPDATE tdc_xfers SET tdc_status = 'O1' WHERE xfer_no = @xfer_no 
			END

			IF (@@ERROR <> 0)
				BEGIN
				EXEC adm_raiserror 81235 ,'Error picking transfer for finished part(2)!'  
				RETURN
			END

			INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			VALUES (GETDATE(), @who, 'CO', 'ADH', 'OUTSOURCE', @xfer_no, '', @temp_part_no, '1', 'OUTBIN', @location, CAST(@rqty as varchar(20)), 'Pick transfer for FG part')

			-- Shipping
			INSERT INTO #tdc_ship_xfer (xfer_no, err_msg) 
			VALUES(@xfer_no, NULL)

			EXEC tdc_ship_xfer_sp 

			IF (@@ERROR <> 0)
				BEGIN
				EXEC adm_raiserror 81235 ,'Error shipping transfer for finished part!'  
				RETURN
			END

			INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			VALUES (GETDATE(), @who, 'CO', 'ADH', 'OUTSOURCE', @xfer_no, '', @temp_part_no, '1', 'OUTBIN', @location, CAST(@rqty as varchar(20)), 'Ship transfer for FG part')

			-- Receiving
			INSERT INTO #adm_rec_xfer (xfer_no, part_no, line_no, from_bin, lot_ser, to_bin, location, qty, who, err_msg) 									
			VALUES (@xfer_no, @temp_part_no, @line_no, '', '1', 'FRAMEWIP', '001', @rqty, @who, NULL)

			EXEC tdc_rec_xfer 

			IF (@@ERROR <> 0)
				BEGIN
				EXEC adm_raiserror 81235 ,'Error receiving transfer for finished part!'  
				RETURN
			END

			INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			VALUES (GETDATE(), @who, 'CO', 'ADH', 'OUTSOURCE', @xfer_no, '', @temp_part_no, '1', 'FRAMEWIP', '001', CAST(@rqty as varchar(20)), 'Receive transfer for FG part')

			-- Reclass
			SELECT	@bin_no = bin_no
			FROM	tdc_bin_part_qty (NOLOCK)
			WHERE	location = '001'
			AND		part_no = @temp_part_no
			AND		[primary] = 'Y'

			SET @fg_part_no = LEFT(@part_no,CHARINDEX('-',@part_no)-1) + '-FG'
			SET @temp_part_no = LEFT(@part_no,CHARINDEX('-',@part_no)-1)

			INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, reason_code, code) 									
			VALUES('001', @temp_part_no, 'RDOCK', '1', @proc_date, @rqty, 1, @who, 'RECLASS', 'XFR')

			EXEC tdc_adm_inv_adj 

			IF (@@ERROR <> 0)
				BEGIN
				EXEC adm_raiserror 81235 ,'Error moving stock to!'  
				RETURN
			END

			TRUNCATE TABLE #adm_inv_adj

			INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, reason_code, code) 							
			VALUES('001', @fg_part_no, 'FRAMEWIP', '1', @proc_date, @rqty, -1, @who, 'RECLASS', 'XFR')

			EXEC tdc_adm_inv_adj 

			IF (@@ERROR <> 0)
				BEGIN
				EXEC adm_raiserror 81235 ,'Error moving stock from FG part!'  
				RETURN
			END

			INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			VALUES (GETDATE(), @who, 'CO', 'ADH', 'OUTSOURCE', '', '', @fg_part_no, '1', 'FRAMEWIP', '001', CAST(@rqty as varchar(20)), 'Move FG Stock to completed frame')

			INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			VALUES (GETDATE(), @who, 'CO', 'ADH', 'OUTSOURCE', '', '', @temp_part_no, '1', @bin_no, '001', CAST(@rqty as varchar(20)), 'Receive completed frame from FG Stock')

			SET @bin_no = ISNULL(@bin_no,'')
	
			EXEC dbo.tdc_queue_xfer_putaway  @xfer_no, '001', @temp_part_no, '1', 'RDOCK', @rqty

			IF (@@ERROR <> 0)
				BEGIN
				EXEC adm_raiserror 81235 ,'Error creating putaway transaction for FG part!'  
				RETURN
			END

 
		END 
	END

	-- Clean Up
	IF (SELECT OBJECT_ID('tempdb..#adm_pick_xfer')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_pick_xfer  
	END

	IF (SELECT OBJECT_ID('tempdb..#tdc_ship_xfer')) IS NOT NULL 
	BEGIN   
		DROP TABLE #tdc_ship_xfer  
	END

	IF (SELECT OBJECT_ID('tempdb..#adm_rec_xfer')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_rec_xfer  
	END

	IF (SELECT OBJECT_ID('tempdb..#xfer_serials')) IS NOT NULL 
	BEGIN   
		DROP TABLE #xfer_serials  
	END

	IF (SELECT OBJECT_ID('tempdb..#adm_inv_adj')) IS NOT NULL 
	BEGIN   
		DROP TABLE #adm_inv_adj  
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_process_outsourcing_sp] TO [public]
GO
