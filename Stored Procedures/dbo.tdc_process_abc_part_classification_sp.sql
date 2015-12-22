SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_process_abc_part_classification_sp]
	@location	varchar(10)
AS

DECLARE	
	@part_no	varchar(30),
	@new_rank	char(1)

	DECLARE part_cursor CURSOR FOR
		SELECT part_no, new_rank
		  FROM #inv_class_temp_parts
		WHERE sel_flg <> 0
		  AND old_rank <> new_rank
		ORDER BY rowid
	OPEN part_cursor
	FETCH NEXT FROM part_cursor INTO @part_no, @new_rank
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE inv_list
			SET rank_class = @new_rank
		WHERE part_no = @part_no
		  AND location = @location

		FETCH NEXT FROM part_cursor INTO @part_no, @new_rank
	END
	CLOSE part_cursor
	DEALLOCATE part_cursor

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_process_abc_part_classification_sp] TO [public]
GO
