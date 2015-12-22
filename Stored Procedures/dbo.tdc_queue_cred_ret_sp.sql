SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/************************************************************************/  
/* Name: tdc_queue_cred_ret_sp                 */  
/*         */  
/* Module: WMS       */  
/*               */  
/* Input:              */  
/*            */  
/* Output:                     */  
/* errmsg - Null if no errors          */  
/*         */  
/* Description:        */  
/* This SP updates the the queue to add all of the Items (entered */  
/* in a credit return) onto the queue to be putaway.    */  
/*         */  
/* Revision History:       */  
/*  Date  Who Description    */  
/* ----  --- -----------    */  
/*  1/07/2000 KMH Initial     */  
/* 6/01/2000 KMH added code to set tx_lock = 'Q' if part */  
/*    is a qc part    */  
/* 6/05/2000 IA fixed code to set tx_lock = 'Q' not only*/  
/*    for qc requared parts   */  
/*         */  
/************************************************************************/  
-- v1.1 CB 15/08/2014 - Performance  

CREATE PROCEDURE [dbo].[tdc_queue_cred_ret_sp] AS  
  
DECLARE	@credit_no int,  
		@part_no varchar (30),  
		@mod varchar (10),  
		@bin_no varchar (12),  
		@qty decimal(20, 8),  
		@lot varchar (25),   
		@location varchar (10),  
		@assign_group char (30),  
		@seq_no int,  
		@tx_lock varchar(1),  
		@line_no int,  
		@who varchar(50),  
		@return_code varchar(10),  
		@tran_id int,  
		@conv_factor decimal(20,8)  
		--@is_kit bit  
  
SELECT @mod = 'CRPTWY'  
SELECT @assign_group = 'PUTAWAY'  
SELECT @tx_lock = 'Q'  
  
SELECT @credit_no = min(order_no), @who = min(who_entered)  
FROM #adm_credit_order   
  
IF EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @credit_no AND status = 'T' AND type = 'C')  
	SELECT @tx_lock = 'R' --This order was auto-posted    
  
DECLARE credit_info CURSOR FOR  
SELECT location, part_no, line_no, lot_ser, bin_no, ordered --, 0  
FROM #adm_credit_order  
WHERE lot_ser IS NOT NULL AND bin_no IS NOT NULL  
UNION  
SELECT location, part_no, line_no, lot_ser, bin_no, qty --, 1  
FROM #temp_tbl_for_kit  
WHERE lot_ser IS NOT NULL AND bin_no IS NOT NULL  
    
OPEN credit_info  
FETCH NEXT FROM credit_info INTO @location, @part_no, @line_no, @lot, @bin_no, @qty --, @is_kit  
  
WHILE(@@FETCH_STATUS = 0)  
BEGIN  
	IF EXISTS (SELECT * FROM tdc_bin_master (nolock)   
				WHERE usage_type_code = 'RECEIPT'   
				AND location = @location   
				AND bin_no = @bin_no   
				AND status = 'A')  
	BEGIN  
	-- IF (@is_kit = 0)  
	--  SELECT @conv_factor = conv_factor FROM ord_list WHERE order_no = @credit_no and line_no = @line_no  
	-- ELSE  
	--  SELECT @conv_factor = 1  
      
		IF EXISTS (SELECT * FROM tdc_put_queue (nolock) WHERE trans = 'CRPTWY' AND trans_type_no = @credit_no AND location = @location AND line_no = @line_no AND part_no = @part_no AND lot = @lot AND @bin_no = @bin_no)  
		BEGIN  
			UPDATE tdc_put_queue  WITH (ROWLOCK) -- v1.0
			SET qty_to_process = qty_to_process + @qty  
			WHERE trans = 'CRPTWY'   
			AND trans_type_no = @credit_no   
			AND location = @location   
			AND line_no = @line_no   
			AND part_no = @part_no   
			AND lot = @lot  
			AND @bin_no = @bin_no  
		END  
		ELSE  
		BEGIN  
			EXEC @seq_no = tdc_queue_get_next_seq_num 'tdc_put_queue', 5  
      
			INSERT INTO tdc_put_queue WITH (ROWLOCK) (trans_source, trans, priority, seq_no, company_no,  -- v1.0
			location, warehouse_no, trans_type_no, trans_type_ext, tran_receipt_no, line_no,   
			pcsn, part_no, eco_no, lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process,  
			qty_processed, qty_short, next_op, tran_id_link, date_time, assign_group,   
			assign_user_id, [user_id], status, tx_status, tx_control, tx_lock )  
			VALUES('CO', @mod, 5, @seq_no, NULL,   
			@location, NULL, @credit_no, 0, NULL, @line_no,  
			NULL, @part_no, NULL, @lot, NULL, NULL, NULL, @bin_no, @qty,   
			0, 0, NULL, NULL, GETDATE(), @assign_group,   
			NULL, @who, NULL, NULL, 'M', @tx_lock)  
		END  
	END  
  
	FETCH NEXT FROM credit_info INTO @location, @part_no, @line_no, @lot, @bin_no, @qty --, @is_kit  
END  
  
DEALLOCATE credit_info  

DECLARE credit_info CURSOR FOR  
SELECT location, part_no, line_no, lot_ser, bin_no, qty  
FROM lot_bin_ship (nolock)   
WHERE tran_no = @credit_no  
FOR READ ONLY  
    
OPEN credit_info  
FETCH NEXT FROM credit_info INTO @location, @part_no, @line_no, @lot, @bin_no, @qty  
  
WHILE(@@FETCH_STATUS = 0)  
BEGIN  
	IF EXISTS (SELECT * FROM tdc_bin_master (nolock)   
				WHERE usage_type_code = 'RECEIPT'   
				AND location = @location   
				AND bin_no = @bin_no   
				AND status = 'A')  
	BEGIN  
		--This handles merging records if the COMBINE_CRPTWY flag is set  
		-- AND auto-posting is turned on.  If auto-posting is not on,  
		-- this is handled in tdc_inventory_update.  
     
		--This checks for auto-posting  
		IF @tx_lock = 'R'  
		--This checks for the tdc_config flag  
		AND EXISTS (SELECT * FROM tdc_config (NOLOCK) -- v1.0  
					WHERE [function] = 'COMBINE_CRPTWY'   
					AND active='Y')  
		--This checks for a pre-existing queue record.  
		AND EXISTS (SELECT * FROM tdc_put_queue (NOLOCK) -- v1.0  
					WHERE trans = @mod --trans  
					AND location = @location --location  
					AND part_no = @part_no --part  
					AND lot = @lot   --lot  
					AND bin_no = @bin_no --bin  
					AND tx_lock = 'R') --tx_lock  
		BEGIN  
			--Get the tran_id that we want to merge with  
			SELECT @tran_id = MAX(tran_id)  
			FROM tdc_put_queue (NOLOCK) -- v1.0  
			WHERE trans = @mod --trans  
			AND location = @location --location  
			AND part_no = @part_no --part  
			AND lot = @lot   --lot  
			AND bin_no = @bin_no --bin  
			AND tx_lock = 'R'  
  
			--merge it  
			UPDATE tdc_put_queue WITH (ROWLOCK) -- v1.0 
			SET trans_type_no = 'UNKNOWN',  
			line_no = 0,  
			qty_to_process = qty_to_process + @qty  
			WHERE tran_id = @tran_id      
		END  
	END  
  
	FETCH NEXT FROM credit_info INTO @location, @part_no, @line_no, @lot, @bin_no, @qty  
END  
  
DEALLOCATE credit_info  

GO
GRANT EXECUTE ON  [dbo].[tdc_queue_cred_ret_sp] TO [public]
GO
