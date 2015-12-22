SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_graphical_bin_view_remove_rows_cols_sp]
	@template_id	int,
	@userid		varchar(50),
	@remove_type	char(1),
	@row_or_col	int,
	@err_msg	varchar(255) OUTPUT

AS
DECLARE	@row_count	int,
	@col_count	int,
	@language 	varchar(10)

SELECT @language = ISNULL(Language, 'us_english') FROM tdc_sec (nolock) WHERE userid = @userid
IF NOT EXISTS(SELECT * FROM #tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id)
BEGIN
	--'Template ID does not exist.'
	SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 9 AND language = @language
	RETURN -1
END

IF @remove_type NOT IN ('C', 'R') 
BEGIN
	--'Invalid remove type specified.'
	SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 10 AND language = @language
	RETURN -2
END

IF @remove_type = 'C' --REMOVING A COLUMN
BEGIN
	IF NOT EXISTS(SELECT * FROM #tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id AND col = @row_or_col)
	BEGIN
		--'Column cannot be removed, because it does not exist.'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 11 AND language = @language
		RETURN -3
	END

	SELECT @col_count = MAX(col) FROM #tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id
	IF @row_or_col = @col_count --WE ARE DELETING THE LAST COLUMN IN THE TABLE
	BEGIN
		DELETE FROM #tdc_graphical_bin_store WHERE template_id = @template_id AND col = @row_or_col
	END
	ELSE
	BEGIN
		IF @row_or_col < @col_count
		BEGIN
			DELETE FROM #tdc_graphical_bin_store WHERE template_id = @template_id AND col = @row_or_col
			UPDATE #tdc_graphical_bin_store SET col = col -1 WHERE template_id = @template_id AND col > @row_or_col
	
		END
	END
END
ELSE --REMOVING A ROW
BEGIN
	IF NOT EXISTS(SELECT * FROM #tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id AND row = @row_or_col)
	BEGIN
		--'Row cannot be removed, because it does not exist.'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 12 AND language = @language
		RETURN -4
	END	
	SELECT @row_count = MAX(row) FROM #tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id
	IF @row_or_col = @row_count --WE ARE DELETING THE LAST COLUMN IN THE TABLE
	BEGIN
		DELETE FROM #tdc_graphical_bin_store WHERE template_id = @template_id AND row = @row_or_col
	END
	ELSE
	BEGIN
		IF @row_or_col < @row_count
		BEGIN
			DELETE FROM #tdc_graphical_bin_store WHERE template_id = @template_id AND row = @row_or_col
			UPDATE #tdc_graphical_bin_store SET row = row -1 WHERE template_id = @template_id AND row > @row_or_col
	
		END
	END
END
RETURN 0 --SUCCESS
GO
GRANT EXECUTE ON  [dbo].[tdc_graphical_bin_view_remove_rows_cols_sp] TO [public]
GO
