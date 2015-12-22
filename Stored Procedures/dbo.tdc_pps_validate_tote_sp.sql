SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_pps_validate_tote_sp] 
	@is_packing		char(1), 
	@is_one_order_per_ctn	char(1),
	@carton_no		int,
	@tote_bin 		varchar(50),
	@order_no 		int          OUTPUT, 
	@order_ext 		int          OUTPUT,
	@err_msg 		varchar(255) OUTPUT 

AS 

--FIELD INDEXES TO BE RETURNED TO VB
DECLARE @ID_ORDER	  int,
	@ID_CARTON_NO	  int,
	@ID_TOTE_BIN	  int,
	@ID_TOTAL_CARTONS int,
	@ID_CARTON_CODE	  int,
	@ID_PACK_TYPE     int,
	@ID_QTX		  int,
	@ID_PART_NO	  int,
	@total_cartons	  int,
	@carton_code	  varchar(10),
	@pack_type	  varchar(10)

--Set the values of the field index
SELECT @ID_CARTON_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'CARTON_NO'

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


--Make sure bin exists
IF NOT EXISTS(SELECT * 
	       FROM tdc_bin_master(NOLOCK) 
	      WHERE bin_no = @tote_bin)
BEGIN
	SELECT @err_msg = 'Invalid Bin'
	RETURN -1
END

--Make bin is type totebin 
IF NOT EXISTS(SELECT * FROM tdc_bin_master (NOLOCK)
	       WHERE bin_no = @tote_bin
	         AND usage_type_code = 'TOTEBIN')
BEGIN
	SELECT @err_msg = 'Bin must be of usage type TOTEBIN'
	RETURN -2
END

--Make sure bin is for correct order type
IF EXISTS(SELECT * FROM tdc_tote_bin_tbl(NOLOCK)
	   WHERE bin_no = @tote_bin
	     AND order_type <> 'S')
BEGIN
	SELECT @err_msg = 'Tote bin contains orders that are not Sales Orders.'
	RETURN -3
END 

SELECT DISTINCT @order_no = order_no, 
		@order_ext = order_ext
  FROM tdc_tote_bin_tbl (NOLOCK) 
 WHERE bin_no = @tote_bin

IF @is_one_order_per_ctn = 'Y'
	RETURN @ID_CARTON_NO
ELSE
BEGIN
	--------------------------------------------------------------------------------------------------------------------
	-- Get the total cartons
	--------------------------------------------------------------------------------------------------------------------
	SELECT @total_cartons = ISNULL(total_cartons,0) 
	  FROM tdc_order (NOLOCK)
	 WHERE order_no  = @order_no
	   AND order_ext = @order_ext
	
	IF @total_cartons = 0
	BEGIN
		IF EXISTS(SELECT * FROM tdc_config (NOLOCK) WHERE [function] = 'carton_total_prompt' and active = 'Y')
		BEGIN
			RETURN @ID_TOTAL_CARTONS
		END
	END
	
	
	--------------------------------------------------------------------------------------------------------------------
	--If the carton code has not been set, set focus to the field to enter carton code
	--------------------------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT * FROM tdc_config (NOLOCK) 
		   WHERE [function] = 'inp_ctn_cd'
		     AND active = 'Y'
		     AND value_str IN ('0', '2'))
	BEGIN
		SELECT @carton_code = NULL
		SELECT @carton_code = carton_type
		  FROM tdc_carton_tx (NOLOCK)
		 WHERE carton_no = @carton_no
	
		IF @carton_code IS NULL	  
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
		     AND value_str IN ('0', '2'))
	BEGIN
		SELECT @pack_type = NULL
		SELECT @pack_type = carton_class
		  FROM tdc_carton_tx (NOLOCK)
		 WHERE carton_no = @carton_no
		
		IF @pack_type IS NULL
		BEGIN	
			RETURN @ID_PACK_TYPE
		END
	END
	
	IF @is_packing = 'Y'
	BEGIN
		IF EXISTS(SELECT * FROM tdc_soft_alloc_tbl(NOLOCK)
			   WHERE order_no = @order_no
			     AND order_ext = @order_ext
			     AND alloc_type = 'PP')
		BEGIN
			RETURN @ID_QTX
		END	
		ELSE
			RETURN @ID_PART_NO
	END
	ELSE
		RETURN @ID_PART_NO
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_tote_sp] TO [public]
GO
