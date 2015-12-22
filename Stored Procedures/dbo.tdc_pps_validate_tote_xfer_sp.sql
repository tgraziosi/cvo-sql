SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_pps_validate_tote_xfer_sp] 
	@packing_flg	int, 
	@tote_bin 	varchar(50),
	@xfer_no 	int          OUTPUT, 
	@err_msg 	varchar(255) OUTPUT 

AS 
--FIELD INDEXES TO BE RETURNED TO VB
DECLARE
	@ID_ORDER	   	int,
	@ID_CARTON_NO	   	int, 
	@language 		varchar(10)

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

--Set the values of the field indexes
SELECT @ID_ORDER = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'ORDER'

SELECT @ID_CARTON_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'CARTON_NO'


--Make sure bin exists
IF NOT EXISTS(SELECT * 
	       FROM tdc_bin_master(NOLOCK) 
	      WHERE bin_no = @tote_bin)
BEGIN
	-- @err_msg = 'Invalid Bin'
	SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_tote_xfer_sp' AND err_no = -101 AND language = @language 
	RETURN -1
END

--Make bin is type totebin 
IF NOT EXISTS(SELECT * FROM tdc_bin_master (NOLOCK)
	       WHERE bin_no = @tote_bin
	         AND usage_type_code = 'TOTEBIN')
BEGIN
	-- @err_msg = 'Bin must be of usage type TOTEBIN'
	SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_tote_xfer_sp' AND err_no = -102 AND language = @language 
	RETURN -1
END

--Make sure bin is for correct order type
IF EXISTS(SELECT * FROM tdc_tote_bin_tbl(NOLOCK)
	   WHERE bin_no = @tote_bin
	     AND order_type <> 'T')
BEGIN
	-- @err_msg = 'Tote bin contains orders that are not Transfer Orders.'
	SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_tote_xfer_sp' AND err_no = -103 AND language = @language 
	RETURN -1
END

        
IF EXISTS(SELECT DISTINCT bin_no FROM tdc_tote_bin_tbl a, #tdc_exclude_order b 
		WHERE a.order_type = 'T' AND a.order_no = b.xfer_no AND a.bin_no = @tote_bin)
BEGIN
	-- @err_msg = 'Must ship verify this transfer from the console.'
	SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_tote_xfer_sp' AND err_no = -104 AND language = @language 
	RETURN -1
END
   


SELECT DISTINCT @xfer_no = order_no 
  FROM tdc_tote_bin_tbl (NOLOCK) 
 WHERE bin_no = @tote_bin

IF (@packing_flg = 1)
	RETURN @ID_CARTON_NO
ELSE
	IF EXISTS(SELECT * FROM tdc_tote_bin_tbl (NOLOCK) WHERE bin_no = @tote_bin)
		RETURN @ID_CARTON_NO
	ELSE
		RETURN @ID_ORDER

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_tote_xfer_sp] TO [public]
GO
