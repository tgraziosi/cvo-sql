SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
-- Bin range
DECLARE @retval INT
EXEC @retval = cvo_barcode_label_print_sp @location = 'LIBERTY', @bin_group = 'BULK',	@bin_from = 'F01A-01-01', @bin_to = 'F01A-01-10', @part_no = 'BCZBAG2', @part_type = '', @label = 'Bin_Label1.lwl', 
@station_id = '999', @user_id = 'manager', @bin_range = 1
SELECT CASE @retval
		WHEN 0 THEN 'Successfully printed'
		WHEN -1 THEN 'Error getting label details'
		WHEN -2 THEN 'No bins meet criteria'
		WHEN -3 THEN 'Error printing labels'
		ELSE '?'
	END

-- Bin list
DECLARE @retval INT
EXEC @retval = cvo_barcode_label_print_sp @location = 'LIBERTY', @bin_group = 'BULK',	@bin_from = '', @bin_to = '', @part_no = 'BCZBAG2', @part_type = '', @label = 'Bin_Label1.lwl', 
@station_id = '999', @user_id = 'manager', @bin_range = 0, @bin_1 = 'F01A-01-01', @bin_2 = 'F01A-01-02', @bin_3 = 'F01A-01-03', @bin_4 = 'F01A-01-04', @bin_5 = 'F01A-01-05',
@bin_6 = 'F01A-01-06', @bin_7 = 'F01A-01-07', @bin_8 = 'F01A-01-08', @bin_9 = 'F01A-01-09', @bin_10 = 'F01A-01-10'
SELECT CASE @retval
		WHEN 0 THEN 'Successfully printed'
		WHEN -1 THEN 'Error getting label details'
		WHEN -2 THEN 'No bins meet criteria'
		WHEN -3 THEN 'Error printing labels'
		ELSE '?'
	END
*/
 
-- v1.1 CT 22/04/2013 - Get which parts are in a bin from tdc_bin_replenishment, not lot_bin_stock
-- v1.2	CT 22/04/2013 - Instead of bin range, user can pass in up to 10 specific bins
-- v1.3 CT 05/06/2013 - Ensure records are inserted into cvo_barcode_label in correct order
 
CREATE PROCEDURE [dbo].[cvo_barcode_label_print_sp]    (@location   VARCHAR(10),
														@bin_group	VARCHAR(10),
														-- START v1.2
														@bin_from	VARCHAR(12) = NULL,
														@bin_to		VARCHAR(12) = NULL,
														--@bin_from	VARCHAR(12),
														--@bin_to	VARCHAR(12),
														-- END v1.2
														@part_no	VARCHAR(30),
														@part_type	VARCHAR(10),
														@label		VARCHAR(40),
														@station_id	VARCHAR(20),
														@user_id    VARCHAR(50),
														-- START v1.2
														@bin_range	SMALLINT = 1, 
														@bin_1		VARCHAR(12) = NULL,
														@bin_2		VARCHAR(12) = NULL,
														@bin_3		VARCHAR(12) = NULL,
														@bin_4		VARCHAR(12) = NULL,
														@bin_5		VARCHAR(12) = NULL,
														@bin_6		VARCHAR(12) = NULL,
														@bin_7		VARCHAR(12) = NULL,
														@bin_8		VARCHAR(12) = NULL,
														@bin_9		VARCHAR(12) = NULL,
														@bin_10		VARCHAR(12) = NULL)
														-- END v1.2
AS    
   
BEGIN

DECLARE @SQL					VARCHAR(1000),
		@rec_key				INT,
		@s_bin_no				VARCHAR(12),
		@s_part_no				VARCHAR(30),
		@s_part_desc			VARCHAR(255),
		@return_value			INT,
		@max_details_on_page	INT,
		@item_count				INT,
		@printer_id				VARCHAR(30),
		@number_of_copies		INT,
		@lwlPath				VARCHAR(100),
		@xp_cmdshell			VARCHAR(1000),
		@bin_list				VARCHAR(200) -- v1.1

	-- Create temp table to hold results
	CREATE TABLE #selected(
		rec_key INT IDENTITY (1,1),
		bin_no	VARCHAR(12),
		part_no VARCHAR(30),
		part_desc VARCHAR(255) NULL)

	-- Clear out temp tables sent in from PC Client
	DELETE FROM #cvo_barcode_label
	DELETE FROM #PrintData_Output


	-- Get lable details
	EXEC @return_value = cvo_print_label_sp 'ADH', 'BINLBL', 'VB', @station_id, @label    
    
	-- IF label hasn't been set up for the station id, try finding a record for the user id    
	IF @return_value != 0    
	BEGIN    
	 EXEC @return_value = cvo_print_label_sp 'ADH', 'BINLBL', 'VB', @user_id, @label    
	END    
	    
	-- IF label hasn't been set up for the user id, exit    
	IF @return_value <> 0    
	BEGIN 
		SELECT -1
		RETURN -1  
	END

	SELECT TOP 1
		@number_of_copies = number_of_copies,
		@printer_id = printer_id
	FROM
		#PrintData_Output

	-- Get maximum number of pages
	SELECT 
		@max_details_on_page = detail_lines
	FROM 
		dbo.tdc_tx_print_detail_config (NOLOCK)    
	WHERE 
		module			 = 'ADH'     
		AND trans        = 'BINLBL'  
		AND trans_source = 'VB'  
		AND format_id    = @label  

	-- If not defined, get default from config
	IF ISNULL(@max_details_on_page, 0) = 0  
	BEGIN  
		SELECT @max_details_on_page = CAST(value_str AS INT) FROM tdc_config WHERE [function] = 'BARCODELBL_Detl_Cnt'
	END 
    
	-- Build SQL to get bin data
	SET @SQL = 'INSERT #selected (bin_no, part_no, part_desc)'
	-- START v1.1
	SET @SQL = @SQL + ' SELECT a.bin_no, a.part_no,	b.[description]	FROM dbo.tdc_bin_replenishment a (NOLOCK)' 
	--SET @SQL = @SQL + ' SELECT a.bin_no, a.part_no,	b.[description]	FROM dbo.lot_bin_stock a (NOLOCK)' 
	-- END v1.1
	SET @SQL = @SQL + ' INNER JOIN dbo.inv_master b (NOLOCK) ON a.part_no = b.part_no '
	SET @SQL = @SQL + ' INNER JOIN dbo.tdc_bin_master c (NOLOCK) ON a.location = c.location AND a.bin_no = c.bin_no '
	SET @SQL = @SQL + ' WHERE 1=1'
	
	IF ISNULL(@location, '') <> ''
	BEGIN
		SET @SQL = @SQL + ' AND a.location = ' + '''' + @location + ''''
	END

	IF ISNULL(@bin_group, '') <> ''
	BEGIN
		SET @SQL = @SQL + ' AND c.group_code = ' + '''' + @bin_group + ''''
	END

	-- START v1.2 - get bin data by using range or specific bins passed in
	IF ISNULL(@bin_range,1) = 1
	BEGIN
		IF ISNULL(@bin_from, '') <> ''
		BEGIN
			SET @SQL = @SQL + ' AND a.bin_no >= ' + '''' + @bin_from + ''''
		END

		IF ISNULL(@bin_to, '') <> ''
		BEGIN
			SET @SQL = @SQL + ' AND a.bin_no <= ' + '''' + @bin_to + ''''
		END
	END
	ELSE
	BEGIN
		SET @bin_list = ''
		IF ISNULL(@bin_1, '') <> ''
		BEGIN
			SET @bin_list = @bin_list + '''' + @bin_1 + '''' + ','
		END

		IF ISNULL(@bin_2, '') <> ''
		BEGIN
			SET @bin_list = @bin_list + '''' + @bin_2 + '''' + ','
		END

		IF ISNULL(@bin_3, '') <> ''
		BEGIN
			SET @bin_list = @bin_list + '''' + @bin_3 + '''' + ','
		END

		IF ISNULL(@bin_4, '') <> ''
		BEGIN
			SET @bin_list = @bin_list + '''' + @bin_4 + '''' + ','
		END

		IF ISNULL(@bin_5, '') <> ''
		BEGIN
			SET @bin_list = @bin_list + '''' + @bin_5 + '''' + ','
		END

		IF ISNULL(@bin_6, '') <> ''
		BEGIN
			SET @bin_list = @bin_list + '''' + @bin_6 + '''' + ','
		END

		IF ISNULL(@bin_7, '') <> ''
		BEGIN
			SET @bin_list = @bin_list + '''' + @bin_7 + '''' + ','
		END

		IF ISNULL(@bin_8, '') <> ''
		BEGIN
			SET @bin_list = @bin_list + '''' + @bin_8 + '''' + ','
		END

		IF ISNULL(@bin_9, '') <> ''
		BEGIN
			SET @bin_list = @bin_list + '''' + @bin_9 + '''' + ','
		END

		IF ISNULL(@bin_10, '') <> ''
		BEGIN
			SET @bin_list = @bin_list + '''' + @bin_10 + '''' + ','
		END

		-- Remove last comma
		SET @bin_list = LEFT(@bin_list, LEN(@bin_list) - 1)

		-- Build IN syntax
		SET @SQL = @SQL + ' AND a.bin_no IN (' + @bin_list + ')'

	END
	-- END v1.2
	IF ISNULL(@part_no, '') <> ''
	BEGIN
		SET @SQL = @SQL + ' AND a.part_no = ' + '''' + @part_no + ''''
	END

	IF ISNULL(@part_type, '') <> ''
	BEGIN
		SET @SQL = @SQL + ' AND b.type_code = ' + '''' + @part_type + ''''
	END

	SET @SQL = @SQL + ' ORDER BY a.bin_no, a.part_no'
	
	EXEC (@SQL)

	IF (SELECT COUNT(1) FROM #selected) = 0
	BEGIN
		SELECT -2
		RETURN -2
	END

	-- Insert header
	INSERT INTO #cvo_barcode_label (print_value) SELECT '*FORMAT,' + @label  
	
	-- Loop through returned data
	SET @rec_key = 0
	SEt @item_count = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_key = rec_key,
			@s_bin_no	= bin_no,
			@s_part_no = part_no,
			@s_part_desc = ISNULL(part_desc,'')
		FROM
			#selected
		WHERE
			rec_key > @rec_key
		ORDER BY
			rec_key

		IF @@ROWCOUNT = 0
			BREAK

		SET @item_count = @item_count + 1
	
		-- Add bin details
		INSERT INTO #cvo_barcode_label (print_value) SELECT 'LP_BIN_NO_' + RTRIM(CAST(@item_count AS char(4))) + ',' + @s_bin_no
		INSERT INTO #cvo_barcode_label (print_value) SELECT 'LP_PART_NO_' + RTRIM(CAST(@item_count AS char(4))) + ',' + @s_part_no
		INSERT INTO #cvo_barcode_label (print_value) SELECT 'LP_PART_DESC_' + RTRIM(CAST(@item_count AS char(4))) + ',' + @s_part_desc

		IF @item_count = @max_details_on_page 
		BEGIN
			-- Print footer
			INSERT INTO #cvo_barcode_label (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
			INSERT INTO #cvo_barcode_label (print_value) SELECT '*QUANTITY,1'  
			INSERT INTO #cvo_barcode_label (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))  
			INSERT INTO #cvo_barcode_label (print_value) SELECT '*PRINTLABEL'  
			
			-- New page
			INSERT INTO #cvo_barcode_label (print_value) SELECT '*FORMAT,' + @label  
			SET @item_count = 0
		END
	
	END	

	-- Add final footer
	IF @item_count > 0
	BEGIN
		-- Print footer
		INSERT INTO #cvo_barcode_label (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
		INSERT INTO #cvo_barcode_label (print_value) SELECT '*QUANTITY,1'  
		INSERT INTO #cvo_barcode_label (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))  
		INSERT INTO #cvo_barcode_label (print_value) SELECT '*PRINTLABEL'  
	END

	-- Drop temp table
	DROP TABLE #selected

	-- Load into static table
	DELETE FROM cvo_barcode_label WHERE [user_id] = @user_ID
	-- v1.3 - add order by
	INSERT INTO cvo_barcode_label SELECT print_value, @user_id FROM #cvo_barcode_label order by row_id

	--Create the file
	SELECT @lwlPath = ISNULL(value_str,'C:\') FROM dbo.tdc_config WHERE [function] = 'WDDrop_Directory'
	SET @xp_cmdshell = 'SQLCMD -S ' + @@servername + ' -E -Q "SET NOCOUNT ON SELECT print_value FROM ' + db_name() 
	SET @xp_cmdshell = @xp_cmdshell + '.dbo.cvo_barcode_label (NOLOCK) WHERE [user_id] = ' + '''' + @user_id + '''' + ' order by row_id" -s"," -h -1 -W -b -o  "' 
	SET @xp_cmdshell = @xp_cmdshell + @lwlPath  + '\BLP-' + CAST(newid()AS VARCHAR(60)) + '.pas"'   
		
	EXEC master..xp_cmdshell  @xp_cmdshell, no_output
	IF @@ERROR <> 0
	BEGIN
		SELECT -3
		RETURN -3
	END
	ELSE
	BEGIN
		SELECT 0
		RETURN 0
	END
END   
  
  
  
GO
