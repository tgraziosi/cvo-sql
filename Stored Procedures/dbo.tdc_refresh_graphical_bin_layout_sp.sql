SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_refresh_graphical_bin_layout_sp]
	@template_id	int
AS

DECLARE @rows 		int,
	@cols		int,
	@rowstart 	int,
	@colstart	int,
	@bin_no		varchar(12),
	@exec_statement	varchar(300),
	@row_cast	varchar(20),
	@col_cast	varchar(20),
	@template_cast	varchar(40)

SELECT @rowstart = 1
SELECT @template_cast = CAST(@template_id as varchar)
TRUNCATE TABLE #tdc_graphical_bin_layout_tbl
SELECT @rows = ISNULL(MAX(row), -1), @cols = ISNULL(MAX(col), -1) FROM #tdc_graphical_bin_store WHERE template_id = @template_id

IF @rows <> -1
BEGIN
	WHILE @rowstart <= @rows
	BEGIN
		SELECT @row_cast = CAST(@rowstart as varchar)
		INSERT INTO #tdc_graphical_bin_layout_tbl (row) VALUES(@rowstart)

		SELECT @colstart = 1
		WHILE @colstart <= @cols
		BEGIN
			SELECT @col_cast = CAST(@colstart as varchar)
			SELECT @bin_no = ISNULL(bin_no, '') FROM #tdc_graphical_bin_store WHERE template_id = @template_id AND row = @rowstart AND col = @colstart
			SELECT @exec_statement = 'UPDATE #tdc_graphical_bin_layout_tbl SET [' + @col_cast + '] = ''' + @bin_no + ''' WHERE row = ' + @row_cast
			EXEC(@exec_statement)
			SELECT @colstart = @colstart + 1
		END
		SELECT @rowstart = @rowstart + 1
	END
END
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_refresh_graphical_bin_layout_sp] TO [public]
GO
