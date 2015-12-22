SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************************************************************/
/* This sp only receive one xfer number and verify all picked items  		*/
/* from any pick method, as long as the item does not pass to next sequence	*/	
/* (pick and ship verify, if pcs flag is on only verify unit level pick )	*/
/********************************************************************************/

CREATE PROCEDURE [dbo].[tdc_ship_xfer_sp] 
AS

SET NOCOUNT ON

CREATE TABLE #adm_ship_xfer (
	xfer_no int not null,
	part_no varchar(30) not null,
	bin_no varchar(12) null,
	lot_ser varchar(25) null,
	date_exp datetime null,
	qty decimal(20,8) not null,
	who varchar(50) null,		
	err_msg varchar(255) null,
	row_id int identity not null
)

DECLARE @xfer_no int, @part_no varchar(30), @bin_no varchar(12), @language varchar(10), @who varchar(50)
DECLARE @lot_ser varchar(25), @date_exp datetime, @qty decimal(20, 8)
DECLARE @msg varchar(255), @child_no int, @line_no int, @err int 

TRUNCATE TABLE #adm_ship_xfer

SELECT @err = 0
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @who), 'us_english') 

-- Verify there is a row of data in the #tdc_ship_xfer
IF NOT EXISTS (SELECT * FROM #tdc_ship_xfer)
BEGIN
	-- 'No data in temp table' 
	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_xfer_sp' AND err_no = -101 AND language = @language
	RAISERROR (@msg, 16, 1)
	RETURN -101
END

SELECT @xfer_no = (SELECT xfer_no FROM #tdc_ship_xfer)

BEGIN TRAN

DECLARE get_xfer_items CURSOR FOR
	SELECT	child_serial_no, part_no, line_no, bin_no, lot_ser, quantity
	FROM	tdc_dist_item_pick
	WHERE	order_no = @xfer_no AND [function] = 'T'

OPEN get_xfer_items

FETCH NEXT FROM get_xfer_items INTO @child_no, @part_no, @line_no, @bin_no, @lot_ser, @qty

WHILE (@@FETCH_STATUS = 0) 
BEGIN
	IF EXISTS (SELECT * FROM tdc_dist_group (nolock) WHERE [function] = 'T' and child_serial_no = @child_no)
	BEGIN
		DEALLOCATE get_xfer_items
		ROLLBACK TRAN

		-- 'Order has been passed to next sequence' 
		SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_xfer_sp' AND err_no = -102 AND language = @language
		RAISERROR (@msg, 16, 1)
		RETURN -102
	END
	
	IF EXISTS (SELECT * FROM inv_master (nolock) WHERE part_no = @part_no AND lb_tracking = 'Y')
	BEGIN
		IF EXISTS (SELECT * FROM #adm_ship_xfer WHERE xfer_no = @xfer_no AND part_no = @part_no
							AND bin_no = @bin_no AND lot_ser = @lot_ser)						
		BEGIN
			UPDATE #adm_ship_xfer 
				SET qty = qty + @qty 
					WHERE xfer_no = @xfer_no AND part_no = @part_no
					AND bin_no = @bin_no AND lot_ser = @lot_ser
		END
		ELSE
		BEGIN
			SELECT @date_exp = (SELECT date_expires FROM lot_bin_xfer (nolock)
									WHERE tran_no = @xfer_no AND lot_ser = @lot_ser
									AND part_no = @part_no AND bin_no = @bin_no
									AND line_no = @line_no)

			INSERT INTO #adm_ship_xfer VALUES(@xfer_no, @part_no, @bin_no, @lot_ser, @date_exp, @qty, @who, NULL)
		END
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT * FROM #adm_ship_xfer WHERE xfer_no = @xfer_no AND part_no = @part_no)
			UPDATE #adm_ship_xfer SET qty = qty + @qty WHERE xfer_no = @xfer_no AND part_no = @part_no
		ELSE
			INSERT INTO #adm_ship_xfer VALUES(@xfer_no, @part_no, NULL, NULL, NULL, @qty, @who, NULL)
	END

	FETCH NEXT FROM get_xfer_items INTO @child_no, @part_no, @line_no, @bin_no, @lot_ser, @qty
END

DEALLOCATE get_xfer_items

UPDATE tdc_xfers SET tdc_status = 'R1' WHERE xfer_no = @xfer_no

EXEC @err = tdc_adm_ship_xfer	

IF (@err < 0)
BEGIN
--	SELECT @err = -102
--	SELECT @err_msg = (SELECT min(err_msg) FROM #adm_ship_xfer WHERE xfer_no = @xfer_no)
	IF (@@TRANCOUNT > 0) ROLLBACK TRAN
--	UPDATE #tdc_ship_xfer SET err_msg = @err_msg WHERE xfer_no = @xfer_no
	RETURN @err
END

UPDATE tdc_dist_item_pick SET status = 'V' WHERE order_no = @xfer_no AND [function] = 'T'
--INSERT INTO tdc_bkp_dist_item_pick 	SELECT *, 'C', GETDATE() 
--	FROM tdc_dist_item_pick WHERE order_no = @xfer_no AND [function] = 'T'
--DELETE FROM tdc_dist_item_pick WHERE order_no = @xfer_no AND [function] = 'T'

TRUNCATE TABLE #adm_ship_xfer

SELECT @err = 0
EXEC @err = tdc_xfer_un_allocate_sp @xfer_no

IF (@err < 0)
BEGIN
	IF (@@TRANCOUNT > 0) ROLLBACK TRAN
	RETURN @err
END

COMMIT TRAN

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_ship_xfer_sp] TO [public]
GO
