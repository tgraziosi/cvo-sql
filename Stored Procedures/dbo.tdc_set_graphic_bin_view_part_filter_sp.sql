SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_set_graphic_bin_view_part_filter_sp]
	@template_id	int,
	@filter_update	int --valid values are 0 and 1
AS
	IF @filter_update = 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM #selected (NOLOCK))
		BEGIN
			DELETE FROM #tdc_bin_view_part_filter_tbl WHERE template_id = @template_id
			UPDATE #tdc_graphical_bin_template 
				SET part_filter_id = NULL WHERE template_id = @template_id
		END
		ELSE
		BEGIN
			DELETE FROM #tdc_bin_view_part_filter_tbl WHERE template_id = @template_id
			INSERT INTO #tdc_bin_view_part_filter_tbl
				SELECT @template_id, part_no
					FROM #selected
			UPDATE #tdc_graphical_bin_template 
				SET part_filter_id = 1 WHERE template_id = @template_id
		END
	END
	ELSE
	BEGIN
		IF NOT EXISTS(SELECT * FROM #selected (NOLOCK))
		BEGIN
			TRUNCATE TABLE #tdc_bin_view_part_filter_view_only_tbl
		END
		ELSE
		BEGIN
			TRUNCATE TABLE #tdc_bin_view_part_filter_view_only_tbl
			INSERT INTO #tdc_bin_view_part_filter_view_only_tbl
				SELECT @template_id, part_no
					FROM #selected
		END
	END
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_set_graphic_bin_view_part_filter_sp] TO [public]
GO
