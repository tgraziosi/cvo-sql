SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_adh_receipt_validate_sp]
	@part_no	varchar(30),
	@location	varchar(30),
	@lot_ser	varchar(30),
	@bin_no		varchar(30),
	@uom		varchar(2),
	@Rec_ref_no	varchar(30),
	@po_no		int,
	@line_No	int,
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

IF @Rec_ref_no = ''
BEGIN
	SELECT @err_msg = 'Rec reference number is required'
	RETURN -9
END

IF ISNULL(@po_no, 0) != 0
BEGIN
	IF NOT EXISTS(SELECT * FROM purchase(NOLOCK)
		       WHERE po_no = @po_no
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
		       WHERE po_no = @po_no
			 AND line = @line_No
			 AND status = 'O')
	BEGIN
		SELECT @err_msg = 'Invalid Line'
		RETURN -12
	END
	IF NOT EXISTS(SELECT * FROM pur_list (NOLOCK)
		       WHERE po_no = @po_no
			 AND line = @line_No
			 AND part_no = @part_no)
	BEGIN
		SELECT @err_msg = 'Invalid Part for Line'
		RETURN -13
	END

		
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_adh_receipt_validate_sp] TO [public]
GO
