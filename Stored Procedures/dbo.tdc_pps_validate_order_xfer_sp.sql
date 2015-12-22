SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_validate_order_xfer_sp]
	@packing_flg	int, 
	@tote_bin	varchar(12),
	@xfer_no	int,
	@total_cartons	int OUTPUT,
	@err_msg 	varchar (255) OUTPUT
 
AS


DECLARE @Order		int,
	@tote_order	int,
	@ID_CARTON_NO	int,
	@language 	varchar(10)

	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	SELECT @ID_CARTON_NO = field_index 
	  FROM tdc_pps_field_index_tbl (NOLOCK)
	 WHERE order_type = 'T' 
	   AND field_name = 'CARTON_NO'

	IF (@packing_flg = 0 AND @tote_bin <> '')
	BEGIN
		IF EXISTS(SELECT * FROM tdc_tote_bin_tbl(NOLOCK)
			  WHERE bin_no = @tote_bin)
		BEGIN
			SELECT DISTINCT @tote_order = order_no
			  FROM tdc_tote_bin_tbl(NOLOCK)
			 WHERE bin_no     = @tote_bin
			   AND order_type = 'T'

			IF (@tote_order <> @xfer_no)
			BEGIN
				-- @err_msg = 'Only ONE transfer is allowed per tote bin'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_order_xfer_sp' AND err_no = -101 AND language = @language 
				RETURN -1
			END
		END
	END

        
	IF EXISTS(SELECT *FROM #tdc_exclude_order WHERE xfer_no = @xfer_no)
	BEGIN
		-- @err_msg = 'Must ship verify this transfer from the console.'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_order_xfer_sp' AND err_no = -102 AND language = @language 
		RETURN -1
	END
   
	--Set the total carton variable
	SELECT @total_cartons = ISNULL(total_cartons,0) 
	  FROM tdc_xfers (NOLOCK)
	 WHERE xfer_no = @xfer_no

	IF EXISTS(SELECT * 
		    FROM xfers     x (NOLOCK), 
			 tdc_xfers t (NOLOCK) 
       		   WHERE x.xfer_no = @xfer_no
       		     AND x.xfer_no = t.xfer_no )         
	-- If the order and ext are valid, return index of carton
		RETURN @ID_CARTON_NO   
	ELSE
	BEGIN
		-- @err_msg = 'Invalid transfer number'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_order_xfer_sp' AND err_no = -103 AND language = @language 
		RETURN -1 
	END

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_order_xfer_sp] TO [public]
GO
