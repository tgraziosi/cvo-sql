SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_pps_pick_part_xfer_sp] 
	@UserID VARCHAR(50),
	@XferNo INT,
	@PartNo VARCHAR(30), 
	@Location VARCHAR(10), 
	@Lot VARCHAR(25), 
	@Bin VARCHAR(12), 
	@LineNo INT, 
	@SerialNo VARCHAR(50),
	@Quantity DECIMAL (20,8), 
	@DSF_Reg INT,
	@UserMethod VARCHAR(5),
	@ErrMsg VARCHAR(255) OUTPUT,
	@ErrNo	INT OUTPUT

AS 

DECLARE @ToLocation   	VARCHAR(15)
DECLARE @Cnt	 	INT
DECLARE @err int
DECLARE @DateExp 	DATETIME
DECLARE @temp 		varchar(200)    
DECLARE @LB_Tracking 	CHAR(1)
DECLARE @ChildSerialNo	INT
DECLARE @language 	varchar(10)

SELECT @err = 0
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

If NOT EXISTS(SELECT * FROM inventory (NOLOCK)
	WHERE part_no = @PartNo 
	AND location = @Location 
	AND in_stock >= @Quantity)
BEGIN
	-- 'Quantity not available to pick'
	SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_pick_part_xfer_sp' AND err_no = -101 AND language = @language 
	RETURN -1
END

SELECT @lb_tracking = lb_tracking 
	FROM inv_master(NOLOCK)
	WHERE part_no = @PartNo 

--IF LB-TRACKED PART
IF @lb_tracking = 'Y'
BEGIN
	IF NOT EXISTS(SELECT * FROM lot_bin_stock (nolock)  	
		WHERE part_no = @PartNo
		AND location = @Location
		AND qty >= @Quantity)
	BEGIN
		-- 'Quantity not available to pick'
		SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_pick_part_xfer_sp' AND err_no = -101 AND language = @language 
		RETURN -1
	END
END

SELECT @ToLocation = from_loc FROM xfers (nolock) WHERE xfer_no = @XferNo

TRUNCATE TABLE #adm_pick_xfer

IF @LB_Tracking = 'Y'
BEGIN
	SELECT @DateExp = CONVERT(varchar(12), date_expires, 106) 
	FROM lot_bin_stock (nolock)  
	WHERE part_no = @PartNo 
	AND lot_ser = @Lot 
	AND bin_no = @Bin 
	AND location = @Location

	INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, bin_no, lot_ser, date_exp, qty, who, err_msg)
	VALUES(@XferNo, @LineNo, @Location, @PartNo, @Bin, @Lot, @DateExp, @Quantity, @UserID, NULL) 

END
ELSE
BEGIN
	INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, bin_no, lot_ser, date_exp, qty, who, err_msg) 
	VALUES(@XferNo, @LineNo, @Location, @PartNo, NULL, NULL, NULL, @Quantity, @UserID, NULL)

END	

--Call stored procedure: tdc_pick_xfer
EXEC @err = tdc_pick_xfer

IF (@err < 0) 
BEGIN
	SELECT @ErrNo = 10
	RETURN -1 
END

EXEC @ChildSerialNo = tdc_get_serialno

IF @ChildSerialNo < 0
BEGIN
	-- 'Error generating child serial number'
	SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_pick_part_xfer_sp' AND err_no = -102 AND language = @language 
	RETURN -1
END

IF @LB_Tracking = 'Y'
BEGIN
	IF NOT EXISTS(SELECT * FROM tdc_dist_item_pick(NOLOCK)
			WHERE method = @UserMethod 
			AND order_no = @XferNo
			AND line_no = @LineNo 
			AND part_no = @PartNo 
			AND lot_ser = @Lot 
			AND bin_no = @Bin 
			AND [function] = 'T')
	BEGIN

		INSERT INTO tdc_dist_item_pick(method, order_no, order_ext, line_no, 
						part_no, lot_ser, bin_no, quantity, child_serial_no, 
						[function], type) 
		VALUES(@UserMethod, @XferNo,0, @LineNo, @PartNo, @Lot, @Bin, @Quantity, @ChildSerialNo, 'T', '01')
	END
	ELSE
	BEGIN
		UPDATE tdc_dist_item_pick SET quantity = quantity + @Quantity 
			WHERE method = @UserMethod 
			AND order_no = @XferNo
			AND line_no = @LineNo 
			AND part_no = @PartNo 
			AND lot_ser = @Lot 
			AND bin_no = @Bin 
			AND [function] = 'T'
	END
END
ELSE
BEGIN
	IF NOT EXISTS(SELECT * FROM tdc_dist_item_pick(NOLOCK)
			WHERE method = @UserMethod 
			AND order_no = @XferNo 
			AND line_no = @LineNo 
			AND part_no = @PartNo
			AND [function] = 'T')
	BEGIN
		INSERT INTO tdc_dist_item_pick(method, order_no, order_ext, line_no, part_no, 
						lot_ser, bin_no, quantity, child_serial_no, [function], type) 
		VALUES(@UserMethod, @XferNo, 0, @LineNo, @PartNo, NULL, NULL, @Quantity, @ChildSerialNo, 'T', '01')

	END
	ELSE
	BEGIN
		UPDATE tdc_dist_item_pick SET quantity = quantity + @Quantity 
		WHERE method = @UserMethod 
		AND order_no = @XferNo 
		AND line_no = @LineNo 
		AND part_no = @PartNo
		AND [function] = 'T'
	END
END

UPDATE tdc_xfers SET tdc_status = 'O1' WHERE xfer_no = @XferNo

RETURN 1 

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_pick_part_xfer_sp] TO [public]
GO
