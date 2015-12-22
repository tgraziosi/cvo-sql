SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_wo_pick_sp]
	@prod_no int,
	@prod_ext int,
	@loc varchar(10),
	@seq_no	varchar(4),
	@part_no varchar(30),	
	@line_no int ,
	@lot_ser varchar(25) = NULL,
	@bin_no varchar(12) = NULL,
	@dest_bin varchar(12) = NULL,
	@pick_qty decimal(20,8) = 0.0,
	@used_qty decimal(20,8) = 0.0,
	@exp_date datetime = NULL,
	@lb_tracking char(2) = 'N'
AS


IF @lb_tracking = 'N'
BEGIN
	IF EXISTS(SELECT * 
		    FROM tdc_wo_pick (NOLOCK) 
		   WHERE prod_no = @prod_no 
		     AND line_no = @line_no)
	BEGIN
		UPDATE tdc_wo_pick 
		   SET pick_qty = (pick_qty + @pick_qty), used_qty = (used_qty + @used_qty), tran_date = getdate()
		 WHERE prod_no = @prod_no 
		   AND line_no = @line_no
	END
	ELSE
	BEGIN
		INSERT INTO tdc_wo_pick (prod_no, prod_ext, location, seq_no, part_no, line_no, pick_qty, used_qty, tran_date)
		VALUES (@prod_no, @prod_ext, @loc, @seq_no, @part_no, @line_no, @pick_qty, @used_qty, getdate())
 	END
END
ELSE IF @lb_tracking = 'Y'
BEGIN
	IF EXISTS (SELECT 1 FROM inv_master (nolock) WHERE part_no = @part_no AND serial_flag = 1)
	BEGIN
		IF OBJECT_ID('tempdb..#serial_no') IS NOT NULL
		BEGIN
			IF @pick_qty < 0
			BEGIN
				DELETE FROM tdc_wo_pick 
				 WHERE prod_no = @prod_no 
				   AND line_no = @line_no 
				   AND lot_ser IN (SELECT serial FROM #serial_no)
				   AND dest_bin = @bin_no
			END
			ELSE
			BEGIN
				INSERT INTO tdc_wo_pick 
					(prod_no, prod_ext, location, seq_no, part_no, line_no, lot_ser, bin_no, dest_bin, pick_qty, used_qty, tran_date)
				SELECT @prod_no, @prod_ext, @loc, @seq_no, @part_no, @line_no, serial, @bin_no, @dest_bin, 1, 0, getdate()
				  FROM #serial_no
		 	END
			RETURN
		END
	END

	-- unpick
	IF @pick_qty < 0
	BEGIN
		UPDATE tdc_wo_pick 
		   SET pick_qty = (pick_qty + @pick_qty), used_qty = (used_qty + @used_qty), tran_date = getdate()
		 WHERE prod_no = @prod_no 
		   AND line_no = @line_no 
		   AND lot_ser = @lot_ser 
		   AND dest_bin = @bin_no	-- from bin
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT * 
			    FROM tdc_wo_pick (NOLOCK) 
			   WHERE prod_no = @prod_no 
			     AND line_no = @line_no 
			     AND lot_ser = @lot_ser 
			     AND dest_bin = @dest_bin)
		BEGIN
			UPDATE tdc_wo_pick 
			   SET pick_qty = (pick_qty + @pick_qty), used_qty = (used_qty + @used_qty), tran_date = getdate(), bin_no = @bin_no
			 WHERE prod_no = @prod_no 
			   AND line_no = @line_no 
			   AND lot_ser = @lot_ser 
			   AND dest_bin = @dest_bin
		END
		ELSE
		BEGIN
			INSERT INTO tdc_wo_pick 
				(prod_no, prod_ext, location, seq_no, part_no, line_no, lot_ser, bin_no, dest_bin, pick_qty, used_qty, tran_date)
			VALUES (@prod_no, @prod_ext, @loc, @seq_no, @part_no, @line_no, @lot_ser, @bin_no, @dest_bin, @pick_qty, @used_qty, getdate())
	 	END
	END
END
GO
GRANT EXECUTE ON  [dbo].[tdc_wo_pick_sp] TO [public]
GO
