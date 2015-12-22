SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_RFID_receipt_label] 
			@user_id 	varchar(50),
			@station_id	varchar(30)
AS

DECLARE @return_value		int,
	@number_of_copies	int,
	@format_id      	varchar (40),   
	@printer_id     	varchar (30),
	@data_field		varchar (40),
	@data_value		varchar (255)

IF NOT EXISTS(SELECT * FROM #print_header) RETURN 0

DECLARE data_cursor CURSOR FOR 
	SELECT field, value FROM #print_header

OPEN data_cursor

FETCH NEXT FROM data_cursor INTO @data_field, @data_value
	
WHILE (@@FETCH_STATUS <> -1)
BEGIN
	IF @data_field <> 'END_OF_FILE'
	BEGIN
		------------------------------------------------------------
		-- Populate the table with the header data
		------------------------------------------------------------
		INSERT INTO #PrintData (data_field, data_value) VALUES(@data_field, @data_value)
	END
	ELSE
	BEGIN
		------------------------------------------------------------
		-- Get format_id and populate the final print table
		------------------------------------------------------------
		EXEC @return_value = tdc_print_label_sp 'RFD', 'RCVRFID', 'VB', @station_id
		
		-- IF label hasn't been set up for the station id, try finding a record for the user id
		IF @return_value != 0
		BEGIN
			EXEC @return_value = tdc_print_label_sp 'RFD', 'RCVRFID', 'VB', @user_id
		END
		
		-- IF label hasn't been set up, exit
		IF @return_value != 0
		BEGIN
			CLOSE      data_cursor
			DEALLOCATE data_cursor
			TRUNCATE TABLE #PrintData
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

		-- Get the table clean and ready for the next RFID line
		TRUNCATE TABLE #PrintData
		TRUNCATE TABLE #PrintData_Output
	END
	
	FETCH NEXT FROM data_cursor INTO @data_field, @data_value
END

CLOSE      data_cursor
DEALLOCATE data_cursor

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_print_RFID_receipt_label] TO [public]
GO
