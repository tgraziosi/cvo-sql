SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_pps_validate_carton_xfer_sp]
	@pcsn_flg		int,
	@xfer_no		int,
	@carton_no		int,	
	@total_cartons 		int 	     OUTPUT,
	@current_carton		int 	     OUTPUT,
	@part_no		varchar(30)  OUTPUT,
	@err_msg		varchar(255) OUTPUT
AS

DECLARE @Cnt		int,
	@P1		int,
	@P2		int,
	@P3		int,

--FIELD INDEXES TO BE RETURNED TO VB
	@ID_TOTAL_CARTONS 	int,
	@ID_PCSN		int,
	@ID_PART_NO		int

--Set the values of the field indexes
SELECT @ID_TOTAL_CARTONS = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'TOTAL_CARTONS'

SELECT @ID_PCSN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'PCSN'

SELECT @ID_PART_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'PART_NO'

-- If the carton_no = -1000, user is generating a new carton
-- Otherwise, validate carton number.
IF @carton_no != -1000 
BEGIN

IF EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK)
	   WHERE carton_no = @carton_no)
	BEGIN	
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK)
				       WHERE carton_no = @carton_no
					 AND order_no = @xfer_no
					 AND order_ext = 0
					 AND order_type = 'T')
			BEGIN
				SELECT @err_msg = 'Invalid Carton'
				RETURN -1
			END
		END
	END
	ELSE IF @carton_no = 0
	BEGIN
		SELECT @err_msg = 'Invalid Carton'
		RETURN -1
	END
	--Get the current carton
	EXEC tdc_get_carton_seq @carton_no, @current_carton OUTPUT,@P1, @P2, @P3
END

SELECT @total_cartons = ISNULL(total_cartons,0) 
  FROM tdc_xfers (NOLOCK)
 WHERE xfer_no = @xfer_no

--If the total number of cartons has not been set, 
--set focus to the field to enter total
IF (@total_cartons < 1)
BEGIN
	IF (SELECT active 
	      FROM tdc_config (NOLOCK)
	     WHERE [function] = 'carton_total_prompt') = 'Y' 
	BEGIN
		SELECT @total_cartons = NULL
		RETURN @ID_TOTAL_CARTONS
	END
END

IF (@pcsn_flg = 1) --If PCSN is on, move focus to PCSN field
	RETURN @ID_PCSN

ELSE --Else, move focus to Part Number field
BEGIN
	--If only one part number, select it.
	SELECT  @Cnt = COUNT(DISTINCT part_no) 
	  FROM xfer_list (NOLOCK) 
	 WHERE xfer_no =  @xfer_no
		
	IF (@CNT = 1)
	BEGIN
		SELECT @part_no = part_no 
		  FROM xfer_list (NOLOCK)
		 WHERE xfer_no = @xfer_no
	END
	RETURN @ID_PART_NO	
END

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_carton_xfer_sp] TO [public]
GO
