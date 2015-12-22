SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_set_graphical_bin_values_sp]
	@template_id	int,
	@row_or_col	int,
	@update_type	char(1),
	@userid		varchar(50),
	@err_msg	varchar(255) OUTPUT
AS
	DECLARE
	@language 	varchar(10)
	
	SELECT @language = ISNULL(Language, 'us_english') FROM tdc_sec (nolock) WHERE userid = @userid

	IF OBJECT_ID('tempdb..#internal_selected_bins') IS NOT NULL
		DROP TABLE #internal_selected_bins

	CREATE TABLE #internal_selected_bins
	(
		bin_no		varchar(12) NULL,
		usage_type_code	varchar(10) NULL,
		seq		int	NOT NULL,
		rowid		int identity
	)
	INSERT INTO #internal_selected_bins (bin_no, usage_type_code, seq)
		SELECT bin_no, usage_type_code, seq FROM #selected_bins ORDER BY rowid

	DECLARE	@current_col	int,
		@current_row	int,
		@new_bin	varchar(12)

	IF NOT EXISTS(SELECT * FROM #internal_selected_bins(NOLOCK))
	BEGIN
		--'No data exists for updating.'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 13 AND language = @language
		RETURN -1
	END

	IF NOT EXISTS(SELECT TOP 1 * FROM #tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id)
	BEGIN
		--'Template ID does not exist.'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 9 AND language = @language
		RETURN -2
	END

	IF @update_type NOT IN ('C', 'R')
	BEGIN
		--'Invalid update type specified.'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 14 AND language = @language
		RETURN -3
	END

	IF @update_type = 'C' --COLUMN UPDATE
	BEGIN--WE RETRIEVE ALL OF THE ROWS THAT NEED TO BE UPDATED FOR THIS COLUMN
		IF NOT EXISTS(SELECT * FROM #tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id AND col = @row_or_col)
		BEGIN
			--'Column cannot be updated, because it does not exist.'
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 15 AND language = @language
			RETURN -4	
		END
	
		DECLARE row_col_cursor CURSOR FOR
		SELECT rowid, ISNULL(bin_no, '')
		  FROM #internal_selected_bins
		ORDER BY rowid
		OPEN row_col_cursor
		FETCH NEXT FROM row_col_cursor INTO @current_row, @new_bin
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @new_bin <> ''
			BEGIN
				IF @new_bin LIKE '<BLANK%'
				BEGIN
					UPDATE #tdc_graphical_bin_store 
						SET bin_no = NULL 
					WHERE template_id = @template_id AND row = @current_row AND col = @row_or_col				
				END
				ELSE
				BEGIN
					UPDATE #tdc_graphical_bin_store 
						SET bin_no = @new_bin 
					WHERE template_id = @template_id AND row = @current_row AND col = @row_or_col
				END
			END
			FETCH NEXT FROM row_col_cursor INTO @current_row, @new_bin
		END
		CLOSE row_col_cursor
		DEALLOCATE row_col_cursor	
	END
	ELSE --ROW UPDATE
	BEGIN--WE RETRIEVE ALL OF THE COLUMNS THAT NEED TO BE UPDATED FOR THIS ROW
		IF NOT EXISTS(SELECT * FROM #tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id AND row = @row_or_col)
		BEGIN
			--'Row cannot be updated, because it does not exist.'
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 16 AND language = @language
			RETURN -5	
		END
	
		DECLARE row_col_cursor CURSOR FOR
		SELECT rowid, ISNULL(bin_no, '')
		  FROM #internal_selected_bins
		ORDER BY rowid
		OPEN row_col_cursor
		FETCH NEXT FROM row_col_cursor INTO @current_col, @new_bin
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @new_bin <> ''
			BEGIN
				IF @new_bin LIKE '<BLANK%'
				BEGIN
					UPDATE #tdc_graphical_bin_store 
						SET bin_no = NULL 
					WHERE template_id = @template_id AND row = @row_or_col AND col = @current_col			
				END
				ELSE
				BEGIN
					UPDATE #tdc_graphical_bin_store 
						SET bin_no = @new_bin 
					WHERE template_id = @template_id AND row = @row_or_col AND col = @current_col
				END
			END
			FETCH NEXT FROM row_col_cursor INTO @current_col, @new_bin
		END
		CLOSE row_col_cursor
		DEALLOCATE row_col_cursor
	END
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_set_graphical_bin_values_sp] TO [public]
GO
