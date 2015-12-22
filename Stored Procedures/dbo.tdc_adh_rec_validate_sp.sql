SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_adh_rec_validate_sp]
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
	@err_msg	varchar(255) OUTPUT
AS 


IF NOT EXISTS(SELECT * FROM inv_master (NOLOCK) 
	      WHERE part_no = @part_no)
BEGIN
	SELECT @err_msg = 'Part not defined'
	RETURN -1
END
         
    -- Part + Location have to exist in inv_list also
IF NOT EXISTS(SELECT * FROM inv_list (NOLOCK) 
	      WHERE part_no = @part_no
	      AND location = @location)
BEGIN
	SELECT @err_msg = 'Part not valid for location'
	RETURN -2
END

IF (((SELECT lb_tracking FROM inv_master(NOLOCK)
    	WHERE part_no = @part_no) = 'Y') 
	OR
	(SELECT vendor_sn FROM tdc_inv_list (NOLOCK)  
	 	WHERE part_no = @part_no
	      	AND location = @location) = 'I') 	
BEGIN
	IF ISNULL(@lot_ser, '') = '' 
	BEGIN
		SELECT @err_msg = 'Lot is required'
		RETURN -3
	END
	IF ISNULL(@bin_no, '') = '' 
	BEGIN
		SELECT @err_msg = 'Receipt Bin is required'
		RETURN -4
	END
	ELSE
	BEGIN
		IF NOT EXISTS(SELECT * FROM tdc_bin_master (NOLOCK)   
		             	   WHERE bin_no = @bin_no
		             	   AND usage_type_code = 'RECEIPT'                 
		                   AND location = @location)
		BEGIN
			SELECT @err_msg = 'Invalid receiving bin'
			RETURN -5
		END
	END
END
ELSE
BEGIN
	IF ISNULL(@lot_ser, '') != '' 
	BEGIN
		SELECT @err_msg = 'Non LB tracked part cannot be assigned to a lot'
		RETURN -6
	END
	IF ISNULL(@bin_no, '') != '' 
	BEGIN
		SELECT @err_msg = 'Non LB tracked part cannot be assigned to a bin'
		RETURN -7
	END
END

IF @uom = '' 
BEGIN
	SELECT @err_msg = 'Unit Of Measure (UOM) is required'
	RETURN -8
END

IF @rec_ref_no = ''
BEGIN
	SELECT @err_msg = 'Rec reference number is required'
	RETURN -9
END

--------------------------------------------------------------------------------------------------------
-- Purchase Order
--------------------------------------------------------------------------------------------------------
IF @tran_type = 'P' 
BEGIN 
	IF NOT EXISTS(SELECT * FROM purchase(NOLOCK)
		       WHERE po_no = @tran_no
			 AND status = 'O')
	BEGIN
		SELECT @err_msg = 'Invalid PO'
		RETURN -10
	END

	IF ISNULL(@line_no, 0) = 0
	BEGIN
		SELECT @err_msg = 'Line no is requried'
		RETURN -11
	END

	IF NOT EXISTS(SELECT * FROM pur_list (NOLOCK)
		       WHERE po_no = @tran_no
			 AND line = @line_no
			 AND status = 'O')
	BEGIN
		SELECT @err_msg = 'Invalid Line'
		RETURN -12
	END

	IF NOT EXISTS(SELECT * FROM pur_list (NOLOCK)
		       WHERE po_no = @tran_no
			 AND line = @line_no
			 AND location = @location)
	BEGIN
		SELECT @err_msg = 'Invalid location for line'
		RETURN -13
	END

	IF NOT EXISTS(SELECT * FROM pur_list (NOLOCK)
		       WHERE po_no = @tran_no
			 AND line = @line_no
			 AND part_no = @part_no)
	BEGIN
		SELECT @err_msg = 'Invalid Part for line'
		RETURN -14
	END
END
--------------------------------------------------------------------------------------------------------
-- Credit Return
--------------------------------------------------------------------------------------------------------
ELSE IF @tran_type = 'C' 
BEGIN
	IF NOT EXISTS(SELECT * FROM orders(NOLOCK)
		       WHERE order_no = CAST(@tran_no AS INT)
		         AND ext = CAST(@tran_ext AS INT)
			 AND status = 'N')
	BEGIN
		SELECT @err_msg = 'Invalid Credit Return'
		RETURN -15
	END

	IF ISNULL(@line_no, 0) = 0
	BEGIN
		SELECT @err_msg = 'Line no is requried'
		RETURN -16
	END

	IF NOT EXISTS(SELECT * FROM ord_list (NOLOCK)
		       WHERE order_no = CAST(@tran_no AS INT)
		         AND order_ext = CAST(@tran_ext AS INT)
			 AND line_no = @line_no)
	BEGIN
		SELECT @err_msg = 'Invalid Line'
		RETURN -17
	END

	IF NOT EXISTS(SELECT * FROM ord_list (NOLOCK)
		       WHERE order_no = CAST(@tran_no AS INT)
		         AND order_ext = CAST(@tran_ext AS INT)
			 AND line_no = @line_no
			 AND location = @location)
	BEGIN
		SELECT @err_msg = 'Invalid Location for line'
		RETURN -18
	END

	IF NOT EXISTS(SELECT * FROM ord_list (NOLOCK)
		       WHERE order_no = CAST(@tran_no AS INT)
		         AND order_ext = CAST(@tran_ext AS INT)
			 AND line_no = @line_no
			 AND part_no = @part_no)
	BEGIN
		SELECT @err_msg = 'Invalid Part for line'
		RETURN -19
	END
END
--------------------------------------------------------------------------------------------------------
-- Transfer Order
--------------------------------------------------------------------------------------------------------
IF @tran_type = 'T' 
BEGIN
	IF NOT EXISTS(SELECT * FROM xfers(NOLOCK)
		       WHERE xfer_no = CAST(@tran_no AS INT)
			 AND status = 'R')
	BEGIN
		IF EXISTS(SELECT * FROM xfers(NOLOCK)
		           WHERE xfer_no = CAST(@tran_no AS INT))
		BEGIN
			SELECT @err_msg = 'Transfer has not yet been shipped.'
		END
		ELSE
			SELECT @err_msg = 'Invalid Transfer'

		RETURN -20
	END

	IF ISNULL(@line_no, 0) = 0
	BEGIN
		SELECT @err_msg = 'Line no is requried'
		RETURN -21
	END

	IF NOT EXISTS(SELECT * FROM xfer_list (NOLOCK)
		       WHERE xfer_no = CAST(@tran_no AS INT)
			 AND line_no = @line_no)
	BEGIN
		SELECT @err_msg = 'Invalid Line'
		RETURN -22
	END

	IF NOT EXISTS(SELECT * FROM xfer_list (NOLOCK)
		       WHERE xfer_no = CAST(@tran_no AS INT)
			 AND line_no = @line_no
			 AND to_loc = @location)
	BEGIN
		SELECT @err_msg = 'Invalid location for line'
		RETURN -23
	END

	IF NOT EXISTS(SELECT * FROM xfer_list (NOLOCK)
		       WHERE xfer_no = CAST(@tran_no AS INT)
			 AND line_no = @line_no
			 AND part_no = @part_no)
	BEGIN
		SELECT @err_msg = 'Invalid Part for line'
		RETURN -24
	END
END


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_adh_rec_validate_sp] TO [public]
GO
