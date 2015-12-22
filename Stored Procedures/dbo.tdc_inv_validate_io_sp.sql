SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_inv_validate_io_sp]
@part_no	VARCHAR(30), 
@location	VARCHAR(13)
AS

IF NOT EXISTS(SELECT *
	FROM inventory (NOLOCK)
	WHERE part_no = @part_no
	AND location = @location
	AND in_stock = 0)
	AND EXISTS(
	SELECT * 
	FROM tdc_serial_no_track (NOLOCK)
	WHERE part_no = @part_no
	AND location = @location
	AND (ISNULL(IO_count,0) % 2) = 0)
BEGIN
	IF EXISTS(SELECT *
	FROM inventory (NOLOCK)
	WHERE part_no = @part_no
	AND location = @location
	AND in_stock = 0)
	AND NOT EXISTS(SELECT *
	FROM tdc_serial_no_track (NOLOCK)
	WHERE part_no = @part_no
	AND location = @location
	)
		RETURN 1
	ELSE
	BEGIN
		IF ((SELECT in_stock
		FROM inventory (NOLOCK)
		WHERE part_no = @part_no
		AND location = @location
		) = (SELECT COUNT(*)
		FROM tdc_serial_no_track (NOLOCK)
		WHERE part_no = @part_no
		AND location = @location
		AND (ISNULL(IO_count,0) % 2) = 1))
			RETURN 1
		ELSE
			RETURN -1
	END
END
ELSE
	RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_inv_validate_io_sp] TO [public]
GO
