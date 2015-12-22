SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_fill_qty_available_bins_sp]
	@mode		smallint,
	@part_no	varchar(30),
	@location	varchar(10),
	@bin_no		varchar(12),
	@bin_group	varchar(10)

AS

DECLARE	@bin_cur	varchar(12),
	@bin_size_group_cur	varchar(10),
	@upd_qty	decimal(20,8),
	@part_group	varchar(10),
	@part_group_defined bit,
	@part_defined	bit

	SELECT @part_group_defined = 0, @part_defined = 0

TRUNCATE TABLE #available_bins

--INSERT MODE
IF @mode = 1
BEGIN
	IF @bin_group = '[ALL]'
	BEGIN
		INSERT INTO #available_bins (bin_no, qty, seq_no) 
			SELECT bin_no, 0, 0 
			  FROM tdc_bin_master a (NOLOCK)
			WHERE a.location = @location
			  AND a.usage_type_code IN ('OPEN', 'REPLENISH')
			  AND a.bin_no <> @bin_no
			  AND a.bin_no NOT IN (SELECT bin_no FROM #selected_bins)
			ORDER BY a.bin_no
	END
	ELSE
	BEGIN
		INSERT INTO #available_bins (bin_no, qty, seq_no) 
			SELECT a.bin_no, 0, 0 
			  FROM 	tdc_bin_master a (NOLOCK),
				tdc_bin_group  b (NOLOCK)
			WHERE a.location = @location
			  AND a.usage_type_code IN ('OPEN', 'REPLENISH')
			  AND a.group_code = b.group_code
			  AND a.group_code = @bin_group
			  AND a.bin_no <> @bin_no
			  AND a.bin_no NOT IN (SELECT bin_no FROM #selected_bins)
			ORDER BY a.bin_no
	END
END
--EDIT MODE
IF @mode = 2
BEGIN
	IF @bin_group = '[ALL]'
	BEGIN
		INSERT INTO #available_bins (bin_no, qty, seq_no) 
			SELECT bin_no, 0, 0 
			  FROM tdc_bin_master a (NOLOCK)
			WHERE a.location = @location
			  AND a.usage_type_code IN ('OPEN', 'REPLENISH')
			  AND a.bin_no <> @bin_no
			  AND a.bin_no NOT IN (SELECT bin_no FROM #selected_bins)
			ORDER BY a.bin_no
	END
	ELSE
	BEGIN
		INSERT INTO #available_bins (bin_no, qty, seq_no) 
			SELECT a.bin_no, 0, 0 
			  FROM 	tdc_bin_master a (NOLOCK),
				tdc_bin_group  b (NOLOCK)
			WHERE a.location = @location
			  AND a.usage_type_code IN ('OPEN', 'REPLENISH')
			  AND a.group_code = b.group_code
			  AND a.group_code = @bin_group
			  AND a.bin_no <> @bin_no
			  AND a.bin_no NOT IN (SELECT bin_no FROM #selected_bins)
			ORDER BY a.bin_no
	END
END
--GET part group
SELECT @part_group = category 
  FROM inv_master (NOLOCK) WHERE part_no = @part_no

--SEE IF PART IS DEFINED IN THE BIN SIZE GROUP PART TABLE
IF EXISTS(SELECT * FROM tdc_bin_size_group_part_values (NOLOCK) WHERE part_no =  @part_no)
BEGIN
	SELECT @part_defined = 1
END

--SEE IF PART GROUP IS DEFINED IN BIN SIZE GROUP PART GROUP TABLE
IF EXISTS(SELECT * FROM tdc_bin_size_group_part_group_values (NOLOCK) WHERE part_group =  @part_group)
BEGIN
	SELECT @part_group_defined = 1
END

--UPDATE QTY APPROPRIATELY
DECLARE update_cursor CURSOR FOR
	SELECT bin_no 
	  FROM #available_bins
	ORDER BY bin_no
OPEN update_cursor
FETCH NEXT FROM update_cursor INTO @bin_cur
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @bin_size_group_cur = size_group_code 
	  FROM tdc_bin_master (NOLOCK) 
	WHERE location = @location AND bin_no = @bin_cur

	IF @part_defined = 1
	BEGIN
		SELECT @upd_qty = ISNULL(max_qty, 0)
                   FROM	tdc_bin_size_group_part_values (NOLOCK)  
                 WHERE part_no = @part_no
		   AND bin_size_group = @bin_size_group_cur

		UPDATE #available_bins
		  SET qty = @upd_qty
		WHERE bin_no = @bin_cur
	END
	ELSE
	BEGIN
		IF @part_group_defined = 1
		BEGIN
			 SELECT @upd_qty = ISNULL(a.max_qty, 0)
	                   FROM  tdc_bin_size_group_part_group_values a (NOLOCK)  
	                 WHERE a.bin_size_group = @bin_size_group_cur
	                   AND a.part_group =  @part_group 

			UPDATE #available_bins
			  SET qty = @upd_qty
			WHERE bin_no = @bin_cur
		END
	END

	FETCH NEXT FROM update_cursor INTO @bin_cur
END
CLOSE update_cursor
DEALLOCATE update_cursor

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_get_fill_qty_available_bins_sp] TO [public]
GO
