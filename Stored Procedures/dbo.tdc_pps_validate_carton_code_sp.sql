SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_pps_validate_carton_code_sp]
	@is_packing	char(1),
	@is_3_step	char(1),
	@carton_no	int,
	@carton_code	varchar(11)  OUTPUT, 		
	@err_msg	varchar(255) OUTPUT
AS

DECLARE @Cnt		int,
	@P1		int,
	@P2		int,
	@P3		int
--FIELD INDEXES TO BE RETURNED TO VB
DECLARE @ID_PACK_TYPE 		int,
	@ID_QTX			int,
	@ID_PART_NO		int 
 
--Set the values of the field indexes
SELECT @ID_PACK_TYPE = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'PACK_TYPE'

SELECT @ID_QTX = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'QTX'

SELECT @ID_PART_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'PART_NO'


IF NOT EXISTS(SELECT * FROM tdc_pkg_master (NOLOCK) WHERE pkg_code = @carton_code)
BEGIN
	SELECT @err_msg = 'Invalid carton code'
	RETURN -1	
END

--If the pack type has not been set, 
--set focus to the field to enter pack type
IF EXISTS(SELECT * FROM tdc_config (NOLOCK)
	   WHERE [function] = 'inp_pck_type'
	     AND active = 'Y'
	     AND value_str IN ('Both', 'Pack Out Only'))
AND NOT EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK)
		WHERE carton_no = @carton_no
		  AND carton_class != NULL)
BEGIN	
	RETURN @ID_PACK_TYPE
END

--If the carton exists, update the carton record
IF EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK) WHERE carton_no = @carton_no)
BEGIN	
	UPDATE tdc_carton_tx SET carton_type = @carton_code
	 WHERE carton_no = @carton_no	
END

IF (@is_packing = 'Y' AND @is_3_step = 'Y') --If pickpack, return qtx field
	RETURN @ID_QTX
ELSE --Else, move focus to Part Number field
BEGIN
	RETURN @ID_PART_NO
END

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_carton_code_sp] TO [public]
GO
