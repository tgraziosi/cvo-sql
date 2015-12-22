SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_validate_carton_total_sp]
	@is_packing	char(1),
	@is_3_step	char(1),
	@carton_no	int, 
	@order_no	int,
	@order_ext	int,
	@total_cartons	int OUTPUT,
	@carton_code	varchar(10) OUTPUT,
	@pack_type	varchar(10) OUTPUT,
	@err_msg	varchar(255) OUTPUT

AS

DECLARE	@ID_ORDER	int,
	@ID_TOTE_BIN	int,
	@ID_TOTAL_CARTONS int,
	@ID_CARTON_CODE	int,
	@ID_PACK_TYPE   int,
	@ID_QTX		int,
	@ID_PART_NO	int

--Set the values of the field index
SELECT @ID_ORDER = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'ORDER'

SELECT @ID_TOTE_BIN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'TOTE_BIN'


SELECT @ID_TOTAL_CARTONS = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'TOTAL_CARTONS'

SELECT @ID_CARTON_CODE = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'CARTON_CODE'

SELECT @ID_PACK_TYPE = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'PACK_TYPE'

SELECT @ID_QTX = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'QTX'

SELECT @ID_PART_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'PART_NO'

	IF ISNULL(@total_cartons, 0) <= 0
	BEGIN
		SELECT @err_msg = 'Invalid total cartons'
		RETURN -1
	END
	ELSE
	BEGIN
		UPDATE tdc_order
		   SET total_cartons = @total_cartons
		 WHERE order_no = @order_no
		   AND order_ext = @order_ext
	END



	--------------------------------------------------------------------------------------------------------------------
	--If the carton code has not been set, set focus to the field to enter carton code
	--------------------------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT * FROM tdc_config (NOLOCK) 
		   WHERE [function] = 'inp_ctn_cd'
		     AND active = 'Y'
		     AND value_str IN ('Both', 'Pack Out Only'))
	BEGIN
		SELECT @carton_code = NULL
		SELECT @carton_code = carton_type
		  FROM tdc_carton_tx (NOLOCK)
		 WHERE carton_no = @carton_no
	
		IF @carton_code IS NULL AND @is_packing = 'Y' 	  
		BEGIN
			RETURN @ID_CARTON_CODE
		END
			
	END
	
	--------------------------------------------------------------------------------------------------------------------
	--If the pack type has not been set, set focus to the field to enter pack type
	--------------------------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT * FROM tdc_config (NOLOCK) 
		   WHERE [function] = 'inp_pck_type'
		     AND active = 'Y'
		     AND value_str IN ('Both', 'Pack Out Only'))
	BEGIN
		SELECT @pack_type = NULL
		SELECT @pack_type = carton_class
		  FROM tdc_carton_tx (NOLOCK)
		 WHERE carton_no = @carton_no
		
		IF @pack_type IS NULL AND @is_packing = 'Y' 	  
		BEGIN	
			RETURN @ID_PACK_TYPE
		END
	END

	IF @is_3_step = 'Y'
		RETURN @ID_QTX
	ELSE
		RETURN @ID_PART_NO
	 

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_carton_total_sp] TO [public]
GO
