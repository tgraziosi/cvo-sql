SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 29/11/2012 - Process a full bin2bin move for the entire contents of a bin

CREATE PROC [dbo].[cvo_full_bin_xfer_sp] 
AS
BEGIN
	DECLARE @location	VARCHAR(10),
			@from_bin	VARCHAR(12),
			@to_bin		VARCHAR(12),
			@part_no	VARCHAR(30),
			@date_expires	VARCHAR(12),
			@lot_ser		VARCHAR(25),
			@qty			DECIMAL(20,8),
			@who_entered	VARCHAR (50),
			@retval			INT,
			@tdc_data		VARCHAR(7500)

	IF (select object_id('tempdb..#temp_who')) IS NULL	
	BEGIN
		CREATE TABLE #temp_who (
			who		VARCHAR(50),
			login_id	VARCHAR(50))
		
		INSERT INTO #temp_who (who, login_id) VALUES ('manager', 'manager')	
	END

	SELECT @who_entered = who  FROM #temp_who

	-- Get values for move
	SELECT
		@location = UPPER(location),
		@from_bin = UPPER(bin_from),
		@to_bin	= UPPER(bin_to)
	FROM
		#cvo_full_bin_xfer

	IF ISNULL(@location,'') = '' OR ISNULL(@from_bin,'') = '' OR ISNULL(@to_bin,'') = ''
	BEGIN
		RETURN -1
	END
	
	-- Create temporary tables
	CREATE TABLE #adm_bin_xfer (
		issue_no	int null,
		location		varchar (10)	not null,
		part_no		varchar (30)	not null,
		lot_ser		varchar (25)	not null,
		bin_from		varchar (12)	not null,
		bin_to		varchar (12)	not null,
		date_expires datetime		not null,
		qty			decimal(20,8)	not null,
		who_entered	varchar (50)	not null,
		reason_code	varchar (10)	null,
		err_msg		varchar (255)	null,
		row_id		int identity	not null)

	-- Loop through parts in from bin
	SET @part_no = ''
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@part_no = part_no,
			@date_expires = CONVERT(varchar(12), date_expires, 109),
			@lot_ser = lot_ser,
			@qty = qty
		FROM
			lot_bin_stock (NOLOCK)
		WHERE
			bin_no = @from_bin
			AND location = @location
			AND part_no > @part_no
		ORDER BY
			part_no


		IF @@ROWCOUNT = 0
			BREAK

		-- Clear temp table
		DELETE FROM #adm_bin_xfer

		-- Load details
		INSERT INTO #adm_bin_xfer (
			issue_no, 
			location, 
			part_no, 
			lot_ser, 
			bin_from, 
			bin_to, 
			date_expires, 
			qty, 
			who_entered, 
			reason_code, 
			err_msg) 													
		SELECT
			NULL,
			@location,
			@part_no,
			@lot_ser,
			@from_bin,
			@to_bin,
			@date_expires,
			@qty,
			@who_entered, 
			NULL, 
			NULL

		-- Execute bin move routine
		EXEC @retval = tdc_bin_xfer 
		IF @retval <= 0
		BEGIN
			RETURN -1
		END

		-- Write logs
		INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, from_bin, userid, direction, quantity) 															  
		SELECT 'ADH',	'BN2BN',  CAST(@retval AS VARCHAR(16)), 0, @location, @part_no, @from_bin, @who_entered,	-1, @qty

		SET @retval = @retval + 1
		INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, to_bin, userid, direction, quantity) 															  
		SELECT 'ADH',	'BN2BN',  CAST(@retval AS VARCHAR(16)), 0, @location, @part_no, @to_bin, @who_entered,	1, @qty
	
		SELECT @tdc_data = dbo.f_create_tdc_log_bin2bin_data_string (@part_no, @qty, @to_bin)

		INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,lot_ser,bin_no,location,quantity,data) 										
		SELECT GETDATE(), @who_entered, 'CO', 'ADH', 'BN2BN', '', '', @part_no, @lot_ser, @from_bin, @location, CAST(@qty AS INT), @tdc_data 


	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_full_bin_xfer_sp] TO [public]
GO
