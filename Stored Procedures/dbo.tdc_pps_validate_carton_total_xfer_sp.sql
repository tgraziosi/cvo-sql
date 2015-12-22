SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_validate_carton_total_xfer_sp]
@order_no	int, 
@order_ext	int,
@carton_total	int, 
@part_no	varchar(30) OUTPUT, 
@err_no		int OUTPUT, 
@err_msg	varchar(255) OUTPUT
AS

DECLARE @Cnt	int,
	@language varchar(10)
DECLARE @ID_PART_NO		int 

--SCR #37905 By Jim On 6/27/07
SELECT @ID_PART_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'PART_NO'


SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')


--Allow entering 0 in case the user does not wish to update the carton total yet
IF (@carton_total <> 0 )
BEGIN
	--Carton total can not be less than one
	IF (@carton_total < 0)
	BEGIN
		-- 'You must enter a valid number of cartons'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_carton_total_xfer_sp' AND err_no = -101 AND language = @language 
		RETURN -1
	END

	--Carton total must be equal or greater then the current number of cartons
	SELECT @Cnt = COUNT (*) 
		FROM tdc_carton_tx a(NOLOCK),
		tdc_carton_tx b(NOLOCK)
		WHERE a.order_no = @order_no
		AND a.order_ext = @order_ext
		AND a.carton_no = b.carton_no
		AND a.order_type = 'T'
	IF (@Cnt > @carton_total)
	BEGIN
		-- 'Carton total cannot be less than the current carton count'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_carton_total_xfer_sp' AND err_no = -102 AND language = @language 
		RETURN -1
	END

	--Update the carton table
	UPDATE tdc_xfers SET total_cartons = @carton_total
		WHERE xfer_no = @order_no

	IF @@ERROR <> 0 
	BEGIN
		-- 'Error updating carton total'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_carton_total_xfer_sp' AND err_no = -103 AND language = @language 
		SELECT @err_no = 10
		RETURN -1
	END
END
ELSE -- Total is = 0
	SELECT @carton_total = NULL


--If only one part number, select it.
SELECT  @Cnt = COUNT(DISTINCT part_no) FROM xfer_list (NOLOCK) 
WHERE xfer_no =  @order_no
				
IF (@CNT = 1)
BEGIN
	SELECT @part_no = part_no FROM xfer_list (NOLOCK)
	WHERE xfer_no = @order_no
END

RETURN @ID_PART_NO

 

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_carton_total_xfer_sp] TO [public]
GO
