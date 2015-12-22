SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_serials_sp] 
	@partno varchar(30)
--WITH ENCRYPTION
AS
	SET NOCOUNT ON
	DECLARE @serial		VARCHAR(50),
		@lot		VARCHAR(25),
		@userid		VARCHAR(50),
		@return_value		INT,
		@number_of_copies	INT,
		@format_id	VARCHAR(40),
		@printer_id	VARCHAR(30)

	IF (object_id('tempdb..#tdc_final_lbl')		IS NULL) RETURN
	IF (object_id('tempdb..#PrintData_Output')	IS NULL) RETURN
	IF (object_id('tempdb..#PrintData')		IS NULL) RETURN
	IF (object_id('tempdb..#Select_Result')		IS NULL) RETURN
	IF (object_id('tempdb..#serial_no')		IS NULL) RETURN

	SELECT @userid = who FROM #temp_who

	DECLARE serial_cursor CURSOR LOCAL FOR SELECT DISTINCT serial_no FROM #serial_no
	DECLARE print_cursor CURSOR LOCAL FOR SELECT format_id, printer_id, number_of_copies FROM #PrintData_Output
	OPEN serial_cursor
	FETCH NEXT FROM serial_cursor INTO @serial
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		TRUNCATE TABLE #PrintData
		TRUNCATE TABLE #PrintData_Output

		SELECT @lot = lot_ser FROM tdc_serial_no_track WHERE part_no = @partno AND serial_no = @serial

		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ITEM', @partno)
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOT', @lot)
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SERIAL', @serial)

		EXEC @return_value = tdc_print_label_sp 'LBL', 'SNGEN', 'CO', @userid
		IF @return_value != 0
		BEGIN
			TRUNCATE TABLE #PrintData
			CLOSE serial_cursor
			DEALLOCATE serial_cursor
			RETURN
		END

		OPEN print_cursor
		FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			-------------- Now let's insert the Header $ Sub Header into the output table -----------------
			INSERT INTO #tdc_final_lbl (print_value) SELECT '*FORMAT,' + @format_id 
			INSERT INTO #tdc_final_lbl (print_value) SELECT data_field + ',' + data_value FROM #PrintData
			INSERT INTO #tdc_final_lbl (print_value) SELECT '*PRINTERNUMBER,' + @printer_id
			INSERT INTO #tdc_final_lbl (print_value) SELECT '*QUANTITY,1'
			INSERT INTO #tdc_final_lbl (print_value) SELECT '*DUPLICATES,' + RTRIM(CAST(@number_of_copies AS char(4)))
			INSERT INTO #tdc_final_lbl (print_value) SELECT '*PRINTLABEL'

			FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
		END
		CLOSE print_cursor
		FETCH NEXT FROM serial_cursor INTO @serial
	END
	CLOSE serial_cursor
	DEALLOCATE print_cursor
	DEALLOCATE serial_cursor
GO
GRANT EXECUTE ON  [dbo].[tdc_print_serials_sp] TO [public]
GO
