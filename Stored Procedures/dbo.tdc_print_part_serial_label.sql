SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_part_serial_label] 
			@user_id 	varchar(50),
			@station_id	varchar(30)
AS

DECLARE @return_value		int,
	@number_of_copies	int,
	@format_id      	varchar (40),   
	@printer_id     	varchar (30),
	@data_field		varchar (40),
	@data_value		varchar (255),
	@part_no		varchar (30),
	@serial 		varchar (40),
	@serial_no 		varchar (40),
	@trans			varchar (40),
	@lot			varchar (25),
	@eBO_serial_flag	int,
	@eWH_serial_flag	int

IF NOT EXISTS(SELECT * FROM #print_part_serial) RETURN 0

DECLARE serial_cursor CURSOR FOR 
	SELECT part_no, serial, serial_no FROM #print_part_serial

OPEN serial_cursor

FETCH NEXT FROM serial_cursor INTO @part_no, @serial, @serial_no
	
WHILE (@@FETCH_STATUS <> -1)
BEGIN
	SET @eBO_serial_flag = 0
	SET @eWH_serial_flag = 0

	SELECT @eBO_serial_flag = serial_flag FROM inv_master   (NOLOCK) WHERE part_no = @part_no
	SELECT @eWH_serial_flag = COUNT(*)    FROM tdc_inv_list (NOLOCK) WHERE part_no = @part_no AND vendor_sn = 'I'

	IF @eBO_serial_flag = 0 AND @eWH_serial_flag = 0 RETURN 0

	IF @eBO_serial_flag <> 0
	BEGIN
		-- Multiple receipt number for qc part
		IF EXISTS (SELECT * FROM lot_bin_recv (NOLOCK) WHERE part_no = @part_no AND lot_ser = @serial)
		BEGIN
			SELECT @trans = tran_no FROM lot_bin_recv (NOLOCK) WHERE part_no = @part_no AND lot_ser = @serial
		END

		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ITEM', 	@part_no)
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOT', 	@serial )
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SERIAL', 	@serial )
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TRANS', 	@trans  )
	END

	IF @eWH_serial_flag <> 0
	BEGIN
		SELECT @lot = lot_ser FROM tdc_serial_no_track WHERE part_no = @part_no AND serial_no = @serial_no

		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ITEM', 	@part_no  )
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOT', 	@lot 	  )
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SERIAL', 	@serial_no)
	END

	EXEC @return_value = tdc_print_label_sp 'LBL', 'SNGEN', 'CO', @station_id

	-- IF label hasn't been set up for the station id, try finding a record for the user id
	IF @return_value != 0
	BEGIN
		EXEC @return_value = tdc_print_label_sp 'LBL', 'SNGEN', 'CO', @user_id
	END
	
	-- IF label hasn't been set up, exit
	IF @return_value != 0
	BEGIN
		TRUNCATE TABLE #PrintData
		CLOSE      serial_cursor
		DEALLOCATE serial_cursor
		RETURN 0
	END

	-- Loop through the format_ids
	DECLARE print_cursor CURSOR FOR 
		SELECT format_id, printer_id, number_of_copies FROM #PrintData_Output
	
	OPEN print_cursor	
	FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
		
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id 
		INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData
	
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
		INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'
	
		FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
	END
	
	CLOSE      print_cursor
	DEALLOCATE print_cursor

	-- Get the table clean and ready for the next part
	TRUNCATE TABLE #PrintData
	TRUNCATE TABLE #PrintData_Output
		
	FETCH NEXT FROM serial_cursor INTO @part_no, @serial, @serial_no
END

CLOSE      serial_cursor
DEALLOCATE serial_cursor

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_print_part_serial_label] TO [public]
GO
