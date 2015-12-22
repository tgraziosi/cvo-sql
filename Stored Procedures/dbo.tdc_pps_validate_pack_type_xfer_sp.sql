SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_validate_pack_type_xfer_sp]
	@is_packing	char(1),
	@is_3_step	char(1),
	@carton_no	int,
	@pack_type	varchar(11)  OUTPUT, 		
	@err_msg	varchar(255) OUTPUT
AS

DECLARE @Cnt		int,
	@ID_PACK_TYPE 	int,
	@ID_QTX		int,
	@ID_PART_NO	int 
 
--Set the values of the field indexes
SELECT @ID_PACK_TYPE = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'PACK_TYPE'

SELECT @ID_QTX = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'QTX'

SELECT @ID_PART_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'PART_NO'


IF NOT EXISTS(SELECT * FROM tdc_package_usage_type (NOLOCK) WHERE usage_type_code = @pack_type)
BEGIN
	SELECT @err_msg = 'Invalid pack type'
	RETURN -1	
END

--If the carton exists, update the carton record
IF EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK) WHERE carton_no = @carton_no)
BEGIN	
	UPDATE tdc_carton_tx SET carton_class = @pack_type
	 WHERE carton_no = @carton_no
END

IF (@is_packing = 'Y' AND @is_3_step = 'Y') --If pickpack, return qtx field
	RETURN @ID_QTX
ELSE --Else, move focus to Part Number field
BEGIN
	RETURN @ID_PART_NO
END

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_pack_type_xfer_sp] TO [public]
GO
