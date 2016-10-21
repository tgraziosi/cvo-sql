SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 09/10/2012 - Issue #890 - Order Cancel - Packout Message
-- v1.1 CB 29/09/2016 - Remove std code for validating freight_allow_type not = 8

CREATE PROCEDURE [dbo].[tdc_pps_validate_order_sp]	@is_one_order_per_ctn   char(1),  
												@is_packing  char(1),  
												@carton_no  int,  
												@tote_bin  varchar(12),  
												@order_no  int,  
												@order_ext  int,  
												@total_cartons  int OUTPUT,  
												@carton_code  varchar(10) OUTPUT,     
												@pack_type  varchar(10) OUTPUT,    
												@err_msg  varchar(255) OUTPUT  
AS  
BEGIN
  
	DECLARE @new_freight_allow_type varchar(10),  
			@freight_allow_type varchar(10),  
			@new_back_ord_flag char(1),  
			@back_ord_flag  char(1),  
			@new_ship_to  varchar(10),  
			@new_cust_code  varchar(10),  
			@ship_to  varchar(10),  
			@cust_code  varchar(10),  
			@ID_TOTAL_CARTONS  int,  
			@ID_CARTON_CODE  int,  
			@ID_PACK_TYPE  int,  
			@ID_QTX   int,  
			@ID_PART_NO  int,  
			@ID_CARTON_NO  int  
   
	----------------------------------------------------------------------------------------------------------------------------  
	--Set the values of the field indexes  
	----------------------------------------------------------------------------------------------------------------------------  
	SELECT	@ID_CARTON_NO = field_index 
	FROM	tdc_pps_field_index_tbl (NOLOCK)  
	WHERE	order_type = 'S' 
	AND		field_name = 'CARTON_NO'  
  
	SELECT	@ID_TOTAL_CARTONS = field_index 
	FROM	tdc_pps_field_index_tbl (NOLOCK)  
	WHERE	order_type = 'S' 
	AND		field_name = 'TOTAL_CARTONS'  
  
	SELECT	@ID_CARTON_CODE = field_index 
	FROM	tdc_pps_field_index_tbl (NOLOCK)  
	WHERE	order_type = 'S' 
	AND		field_name = 'CARTON_CODE'  
  
	SELECT	@ID_PACK_TYPE = field_index 
	FROM	tdc_pps_field_index_tbl (NOLOCK)  
	WHERE	order_type = 'S' 
	AND		field_name = 'PACK_TYPE'  
  
	SELECT	@ID_QTX = field_index 
	FROM	tdc_pps_field_index_tbl (NOLOCK)  
	WHERE	order_type = 'S' 
	AND		field_name = 'QTX'  
  
	SELECT	@ID_PART_NO = field_index 
	FROM	tdc_pps_field_index_tbl (NOLOCK)  
	WHERE	order_type = 'S' 
	AND		field_name = 'PART_NO'  
    
	--------------------------------------------------------------------------------------------------------------------  
	-- Make sure order-ext is valid  
	--------------------------------------------------------------------------------------------------------------------  
	IF NOT EXISTS(SELECT * FROM orders    a (NOLOCK), tdc_order b (NOLOCK)   
					WHERE a.order_no = @order_no AND a.ext  = @order_ext   
					AND a.order_no = b.order_no AND a.ext  = b.order_ext)          
	BEGIN  
		-- v1.0 Start
		-- Order does not exist so check if its been cancelled, if not return the standard message
		IF EXISTS (SELECT 1 FROM cvo_order_queue_cancellation (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			SELECT @err_msg = 'The order has been cancelled. Please place in putaway station.'  
			RETURN -1   
		END
		-- v1.0 End
		SELECT @err_msg = 'Invalid Order'  
		RETURN -1   
	END   
  
	--------------------------------------------------------------------------------------------------------------------  
	-- Get the total cartons  
	--------------------------------------------------------------------------------------------------------------------  
	SELECT	@total_cartons = ISNULL(total_cartons,0)   
	FROM	tdc_order (NOLOCK)  
	WHERE	order_no  = @order_no  
	AND		order_ext = @order_ext  
  
	--------------------------------------------------------------------------------------------------------------------  
	-- If unpacking to a tote bin, make sure only one order is in the bin.  
	--------------------------------------------------------------------------------------------------------------------  
	IF @is_packing = 'N' AND @tote_bin <> ''  
	BEGIN  
		IF EXISTS(SELECT * FROM tdc_tote_bin_tbl(NOLOCK)  
				WHERE bin_no = @tote_bin  
				AND (order_no != @order_no OR order_ext != @order_ext))  
		BEGIN  
			SELECT @err_msg = 'Only ONE order AND extention is allowed per tote bin'  
			RETURN -2  
		END  
	END  
  
	--------------------------------------------------------------------------------------------------------------------  
	-- Make sure order-ext is not marked for ship verify  
	--------------------------------------------------------------------------------------------------------------------  
	IF EXISTS(SELECT * FROM tdc_config (NOLOCK) WHERE [function] = 'so_picking_sn' AND active = 'Y')  
	BEGIN  
		IF EXISTS(SELECT * FROM tdc_inv_list t (NOLOCK),  ord_list     o (NOLOCK)   
				WHERE t.part_no   = o.part_no   
				AND t.location  = o.location   
				AND t.vendor_sn IN ('I','O')   
				AND o.status IN ('N', 'P', 'Q')   
				AND o.order_no  = @order_no  
				AND o.order_ext = @order_ext  
			OR EXISTS(SELECT * FROM tdc_inv_list t (NOLOCK), ord_list_kit o (NOLOCK)   
				WHERE t.part_no   = o.part_no   
				AND t.location  = o.location   
				AND t.vendor_sn IN ('I','O')   
				AND o.status IN ('N', 'P', 'Q'))  
				AND o.order_no  = @order_no  
				AND o.order_ext = @order_ext)  
		BEGIN  
			SELECT @err_msg = 'Must ship verify this order from the console'  
			RETURN -3  
		END  
	END   
  
	IF @is_one_order_per_ctn = 'Y'  
	BEGIN  
		IF @carton_no > 0  
		BEGIN  
			IF EXISTS(SELECT * FROM tdc_carton_tx(NOLOCK) WHERE carton_no = @carton_no  
					AND (order_no != @order_no OR order_ext != @order_ext))  
			BEGIN  
				SELECT @err_msg = 'Only one order-ext allowed per carton'  
				RETURN -4  
			END  
		END  
  
		RETURN @ID_CARTON_NO  
	END  
	ELSE  
	BEGIN  
		-- v1.1 Start
		/*
		IF EXISTS(SELECT * FROM tdc_carton_tx(NOLOCK) WHERE carton_no = @carton_no AND order_no != @order_no)  
		BEGIN  
			IF EXISTS(SELECT * FROM tdc_config(NOLOCK) WHERE [function] = 'manifest_type' AND active = 'Y')  
			BEGIN  
				IF EXISTS(SELECT * FROM orders(NOLOCK) WHERE order_no = @order_no  
						AND ext = 0 AND ISNULL(freight_allow_type, '') != '8')   
					OR EXISTS(SELECT * FROM tdc_carton_tx a(NOLOCK), orders b(NOLOCK)  
						WHERE a.order_no = b.order_no  
						AND a.order_ext = b.ext  
						AND a.carton_no = @carton_no  
						AND ISNULL(freight_allow_type, '') != '8')   
				BEGIN  
					SELECT @err_msg = 'Freight Type must be 8 (No Charge Freight)'  
					RETURN -5  
				END  
			END  
		END  
		*/
		-- v1.1 End
		--------------------------------------------------------------------------------------------------------------------  
		-- If other order(s) have been packed into the carton, make sure they have the same:  
		--  freight_allow_type of 8 if manifest enabled,   
		--  back_ord_flag must match  
		--------------------------------------------------------------------------------------------------------------------  
		IF EXISTS(SELECT * FROM tdc_carton_tx(NOLOCK)  
			WHERE carton_no = @carton_no  
			AND order_no != @order_no)  
		BEGIN  
			SELECT	TOP 1 @new_freight_allow_type = ISNULL(freight_allow_type, ''),  
					@new_back_ord_flag = back_ord_flag,  
					@new_ship_to = ship_to,  
					@new_cust_code = cust_code  
			FROM	orders(NOLOCK)  
			WHERE	order_no = @order_no  
			AND		ext = 0  
  
			SELECT	TOP 1 @freight_allow_type = ISNULL(a.freight_allow_type, ''),  
					@back_ord_flag = a.back_ord_flag,  
					@cust_code = a.cust_code,  
					@ship_to = ship_to  
			FROM	orders a (NOLOCK),   
					tdc_carton_tx b(NOLOCK)  
			WHERE	b.carton_no = @carton_no  
			AND		a.order_no = b.order_no  
			AND		a.ext = b.order_ext  
   
			IF EXISTS(SELECT * FROM tdc_config(NOLOCK) WHERE [function] = 'manifest_type' AND active = 'Y')  
			BEGIN     
				IF @new_freight_allow_type != @freight_allow_type  
				BEGIN  
					SELECT @err_msg = 'Freight type for this order does not match freight type of other order(s) in the carton'  
					RETURN -6  
				END  
			END  
  
			IF @new_back_ord_flag != @back_ord_flag  
			BEGIN  
				SELECT @err_msg = 'Back Order Flag for this order does not match back order flag of other order(s) in the carton'  
				RETURN -7   
			END   
  
			IF NOT EXISTS(SELECT * FROM tdc_config(NOLOCK) WHERE [function] = 'carton_mixed_shipto' AND active = 'Y')  
			BEGIN  
	  
				IF @new_ship_to != @ship_to  
				BEGIN  
					SELECT @err_msg = 'Ship To for this order does not match ship to of other order(s) in the carton'  
					RETURN -8  
				END  
			END  
  
			IF ISNULL(@new_cust_code, '') != ISNULL(@cust_code, '')  
			BEGIN  
				SELECT @err_msg = 'Customer Code for this order does not match customer code of other order(s) in the carton'  
				RETURN -9  
			END  
		END  
	END  
  
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
	IF EXISTS(SELECT * FROM tdc_config (NOLOCK) WHERE [function] = 'inp_ctn_cd' AND active = 'Y' AND value_str IN ('Both', 'Pack Out Only'))  
	BEGIN  
		SELECT @carton_code = NULL  
		SELECT	@carton_code = carton_type  
		FROM	tdc_carton_tx (NOLOCK)  
		WHERE	carton_no = @carton_no  
  
		IF @carton_code IS NULL AND @is_packing = 'Y'      
		BEGIN  
			RETURN @ID_CARTON_CODE  
		END     
	END  
  
	--------------------------------------------------------------------------------------------------------------------  
	--If the pack type has not been set, set focus to the field to enter pack type  
	--------------------------------------------------------------------------------------------------------------------  
	IF EXISTS(SELECT * FROM tdc_config (NOLOCK) WHERE [function] = 'inp_pck_type' AND active = 'Y' AND value_str IN ('Both', 'Pack Out Only'))  
	BEGIN  
		SELECT @pack_type = NULL  
		SELECT	@pack_type = carton_class  
		FROM	tdc_carton_tx (NOLOCK)  
		WHERE	carton_no = @carton_no  
   
		IF @pack_type IS NULL AND @is_packing = 'Y'      
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
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_order_sp] TO [public]
GO
