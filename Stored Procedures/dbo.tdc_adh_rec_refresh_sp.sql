SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_adh_rec_refresh_sp]
	@rec_type varchar(3),
	@adhoc_rec_no int
AS

DECLARE @row_id		int,
	@tran_type	char(1),
	@tran_no	varchar(20),
	@tran_ext	varchar(15),
	@line_no	varchar(10),
	@part_no	varchar(30),
	@location	varchar(30),
	@lot_ser	varchar(30),
	@bin_no		varchar(30),
	@uom		varchar(2),
	@rec_ref_no	varchar(30),
	@err_msg	varchar(255),
	@ret		int

DECLARE adh_rec_cur CURSOR FOR 
SELECT row_id, tran_type, tran_no, tran_ext, line_no, part_no, location, lot_ser, bin_no, uom, rec_ref_no 
FROM tdc_adhoc_receipts (NOLOCK)
WHERE (@rec_type = 'ALL' OR rec_type = @rec_type)
AND (@adhoc_rec_no = -1 OR adhoc_rec_no = @adhoc_rec_no)

OPEN adh_rec_cur
FETCH NEXT FROM adh_rec_cur INTO @row_id, @tran_type, @tran_no, @tran_ext, @line_no, @part_no, @location, @lot_ser, @bin_no, @uom, @rec_ref_no
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @err_msg = NULL

	EXEC @ret = tdc_adh_rec_validate_sp @tran_type, @tran_no, @tran_ext, @line_no, @part_no, @location, @lot_ser, @bin_no, @uom, @rec_ref_no, @err_msg OUTPUT

	IF @ret = 0
	BEGIN
		UPDATE tdc_adhoc_receipts SET error_code = NULL 
		WHERE row_id = @row_id
	END
	ELSE
	BEGIN
		UPDATE tdc_adhoc_receipts SET error_code = @err_msg 
		WHERE row_id = @row_id
	END
	FETCH NEXT FROM adh_rec_cur INTO @row_id, @tran_type, @tran_no, @tran_ext, @line_no, @part_no, @location, @lot_ser, @bin_no, @uom, @rec_ref_no
END
CLOSE adh_rec_cur
DEALLOCATE adh_rec_cur

GO
GRANT EXECUTE ON  [dbo].[tdc_adh_rec_refresh_sp] TO [public]
GO
