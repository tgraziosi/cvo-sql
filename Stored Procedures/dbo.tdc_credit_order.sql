SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CB 15/08/2014 - Performance

CREATE PROC [dbo].[tdc_credit_order]  
AS  
   
	SET NOCOUNT ON  
  
	/* This procedure credits orders    */  
	DECLARE	@order_no int,   
			@ext int,  
			@part_no varchar(30),  
			@line_no int,  
			@ordered decimal(20, 8),  
			@bin_no varchar(12),  
			@lot_ser varchar(25),  
			@date_expires datetime,   
			@location varchar(10),  
			@lb_tracking char(1),  
			@cost decimal(20, 8),  
			@uom char(2),  
			@conv_factor decimal(20, 8),  
			@tax_perc decimal(20, 8),  
			@who_entered varchar(50),  
			@part_type char(1),  
			@qc char(1),  
			@qc_flag char(1),   
			@rec_id int,  
			@status char(1),  
			@language varchar(10),  
			@err_msg varchar(255),  
			@process_ctrl_num varchar(32),  
			@err int    
  
	IF OBJECT_ID('tempdb..#adm_taxinfo') IS NOT NULL  
		TRUNCATE TABLE #adm_taxinfo  
  
	IF OBJECT_ID('tempdb..#adm_taxtype') IS NOT NULL  
		TRUNCATE TABLE #adm_taxtype  
  
	IF OBJECT_ID('tempdb..#adm_taxtyperec') IS NOT NULL  
		TRUNCATE TABLE #adm_taxtyperec  
  
	IF OBJECT_ID('tempdb..#adm_taxcode') IS NOT NULL  
		TRUNCATE TABLE #adm_taxcode  
  
	IF OBJECT_ID('tempdb..#cents') IS NOT NULL  
		TRUNCATE TABLE #cents  
  
   /* Find the first record */  
	SELECT @rec_id = 0   
	
	SELECT @order_no = min(order_no), @ext = min(ext), @who_entered = min(who_entered)  
	FROM #adm_credit_order  
  
	SELECT @language = Language FROM tdc_sec (nolock) WHERE userid = @who_entered  
	SELECT @language = ISNULL(@language, 'us_english')  
  
	SELECT @who_entered = login_id FROM #temp_who  
  
    /* Make sure order number exists */  
    IF NOT EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @order_no AND ext = @ext)  
    BEGIN              
		SELECT @err_msg = err_msg   
		FROM tdc_lookup_error (nolock)  
		WHERE module = 'SPR' AND trans = 'tdc_credit_order' AND err_no = -101 AND language = @language  
  
		-- 'Order number is not valid.'  
		UPDATE #adm_credit_order SET err_msg = @err_msg WHERE row_id = 1  
		RETURN -101  
	END           
   
    /* Make sure the type is 'C' = Credit */  
	IF NOT EXISTS(SELECT * FROM orders (nolock) WHERE order_no = @order_no AND ext = @ext AND type = 'C')  
	BEGIN     
		SELECT @err_msg = err_msg   
		FROM tdc_lookup_error (nolock)  
		WHERE module = 'SPR' AND trans = 'tdc_credit_order' AND err_no = -102 AND language = @language  
  
		-- 'Order type must be credit.'  
		UPDATE #adm_credit_order SET err_msg = @err_msg WHERE row_id = 1  
		RETURN -102  
    END  
  
	/* Make sure the status is 'N' (Open)  */  
	IF NOT EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @order_no AND ext = @ext AND status IN ('N', 'Q', 'R'))  
	BEGIN     
		SELECT @err_msg = err_msg   
		FROM tdc_lookup_error (nolock)  
		WHERE module = 'SPR' AND trans = 'tdc_credit_order' AND err_no = -103 AND language = @language  
  
		-- 'Order status must be Open'  
		UPDATE #adm_credit_order SET err_msg = @err_msg WHERE row_id = 1  
		RETURN -103  
	END  
  
	/* Look at each record... */  
	WHILE (@rec_id >= 0)  
	BEGIN  
		/* Get record from #adm_credit_order */  
        SELECT @rec_id = ISNULL((SELECT min(row_id) FROM #adm_credit_order WHERE row_id > @rec_id AND ordered <> 0), -1)  
        IF @rec_id = -1 BREAK  
  
        /* Get order_no */  
        SELECT  @part_no  = part_no,  
				@line_no  = line_no,  
				@ordered  = ordered,  
				@lot_ser  = lot_ser,  
				@bin_no   = bin_no  
        FROM #adm_credit_order   
		WHERE row_id = @rec_id  
  
		/* Make sure the part_no is valid */  
		IF NOT EXISTS(SELECT * FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND part_no = @part_no AND line_no = @line_no)  
		BEGIN  
			SELECT @err_msg = err_msg   
			FROM tdc_lookup_error (nolock)  
			WHERE module = 'SPR' AND trans = 'tdc_credit_order' AND err_no = -104 AND language = @language  
  
			-- 'Order must have a valid part / line number.'  
			UPDATE #adm_credit_order SET err_msg = @err_msg WHERE row_id = @rec_id  
			RETURN -104  
		END  
  
		/* Make sure the quantity ordered is valid */  
		IF NOT EXISTS(SELECT * FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND (cr_shipped * conv_factor + @ordered) >= 0)  
		BEGIN  
			SELECT @err_msg = err_msg   
			FROM tdc_lookup_error (nolock)  
			WHERE module = 'SPR' AND trans = 'tdc_credit_order' AND err_no = -105 AND language = @language  
     
			-- 'Order must have a valid quantity.'  
			UPDATE #adm_credit_order SET err_msg = @err_msg WHERE row_id = @rec_id  
			RETURN -105  
		END  
  
		SELECT @lb_tracking = lb_tracking FROM inv_master (nolock) WHERE part_no = @part_no  
		SELECT @date_expires = CONVERT(varchar(12), dateadd(mm, 12, getdate()), 106)  
  
		-- check qc flag.  for qc order we update order status to 'Q'  
		IF EXISTS (SELECT * FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND qc_flag = 'Y')  
		BEGIN  
			IF EXISTS (SELECT * FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND qc_flag = 'Y') AND (@ordered < 0)  
			BEGIN     
				UPDATE #adm_credit_order SET err_msg = 'Can not change an item that is on QC hold!' WHERE row_id = @rec_id  
				RETURN -106  
			END  
  
			SELECT @qc = 'Y', @status = 'Q'  
		END  
		ELSE  
		BEGIN  
			SELECT @qc = 'N', @status = 'R'  
		END  
  
		/* Check for Lot Bin Tracking */  
		SELECT  @part_type = part_type,  
				@location = location,  
				@uom = uom,  
				@cost = cost,  
				@conv_factor = conv_factor,  
				@qc_flag = qc_flag   
		FROM ord_list (nolock)   
		WHERE order_no = @order_no   
		AND order_ext = @ext   
		AND line_no = @line_no  
  
		IF (@ordered < 0) AND (@lb_tracking = 'Y') AND (@part_type = 'P')  
		BEGIN  
			IF NOT EXISTS (SELECT * FROM lot_bin_ship (nolock)   
							WHERE tran_no = @order_no   
							AND tran_ext = @ext  
							AND line_no = @line_no   
							AND part_no = @part_no   
							AND lot_ser = @lot_ser   
							AND bin_no = @bin_no   
							AND (qty + @ordered) >= 0)  
			BEGIN  
				SELECT @err_msg = err_msg   
				FROM tdc_lookup_error (nolock)  
				WHERE module = 'SPR' AND trans = 'tdc_credit_order' AND err_no = -105 AND language = @language  
  
				-- 'Order must have a valid quantity.'  
				UPDATE #adm_credit_order SET err_msg = @err_msg WHERE row_id = @rec_id  
				RETURN -107  
			END  
		END  
  
		SELECT @process_ctrl_num = ISNULL(process_ctrl_num, ''), @tax_perc = tax_perc  
		FROM orders (nolock)   
		WHERE order_no = @order_no   
		AND ext = @ext  
  
		-- Only update it if status is 'N'  
		UPDATE orders_all WITH (ROWLOCK) -- v1.0
		SET status = @status, printed = @status, date_shipped = GETDATE(), who_picked = @who_entered, tax_perc = @tax_perc  
		WHERE order_no = @order_no   
		AND ext = @ext   
		AND status IN ('N', 'Q', 'R')  
  
		/* Update credit shipped values to reflect the returned stock */  
		UPDATE ord_list WITH (ROWLOCK) -- v1.0
		SET status = @status, cr_shipped = cr_shipped + @ordered/@conv_factor, who_entered = @who_entered  
		WHERE order_no = @order_no   
		AND order_ext = @ext   
		AND line_no = @line_no  
  
		IF (@lb_tracking = 'Y' AND @part_type = 'P')  
		BEGIN  
			IF NOT EXISTS ( SELECT * FROM lot_bin_ship (nolock)  
							WHERE tran_no = @order_no   
							AND tran_ext = @ext   
							AND line_no = @line_no   
							AND bin_no = @bin_no   
							AND lot_ser = @lot_ser )  
			BEGIN  
				INSERT lot_bin_ship WITH (ROWLOCK) (location, part_no, bin_no, lot_ser, tran_code,   -- v1.0
				tran_no, tran_ext, date_tran, date_expires, qty,   
				direction, cost, uom, uom_qty, conv_factor, line_no, who, qc_flag, kit_flag)  
                VALUES( @location, @part_no, @bin_no, @lot_ser, @status,   
				@order_no, @ext, GETDATE(), @date_expires, @ordered,   
				1, @cost, @uom, @ordered/@conv_factor, @conv_factor, @line_no, @who_entered, @qc_flag, 'N')  
			END  
			ELSE   
			BEGIN  
				UPDATE lot_bin_ship WITH (ROWLOCK) -- v1.0  
				SET qty = qty + @ordered, date_tran = GETDATE(), uom_qty = uom_qty + @ordered/@conv_factor, who = @who_entered  
				WHERE tran_no  = @order_no   
				AND tran_ext = @ext   
                AND line_no  = @line_no    
                AND bin_no   = @bin_no     
				AND lot_ser  = @lot_ser  
  
				DELETE FROM dbo.lot_bin_ship   
				WHERE tran_no  = @order_no   
				AND tran_ext = @ext   
                AND line_no  = @line_no    
                AND bin_no   = @bin_no     
				AND lot_ser  = @lot_ser  
				AND qty <= 0  
			END  
		END  
	END  
  
	IF NOT EXISTS (SELECT * FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = 0 AND cr_shipped > 0)  
	BEGIN  
		SELECT @status = 'N'  
  
		UPDATE orders_all WITH (ROWLOCK) -- v1.0  
		SET status = 'N', printed = 'N'  
		WHERE order_no = @order_no  
		AND ext = 0  
    
		UPDATE ord_list WITH (ROWLOCK) -- v1.0
		SET status = 'N', who_entered = @who_entered  
		WHERE order_no = @order_no  
		AND order_ext = 0   
  
		UPDATE ord_list_kit WITH (ROWLOCK) -- v1.0
		SET status = 'N'  
		WHERE order_no = @order_no  
		AND order_ext = 0  
  
		UPDATE tdc_order WITH (ROWLOCK) -- v1.0
		SET tdc_status = 'Q1'   
		WHERE order_no = @order_no  
		AND order_ext = 0  
	END  
  
	EXEC dbo.fs_calculate_oetax @order_no, 0, @err OUTPUT  
   
	EXEC dbo.fs_updordtots @order_no, 0   
  
	IF NOT EXISTS ( SELECT * FROM config (nolock) WHERE flag = 'SHP_AUTO_POST' AND flag_class = 'shp' AND value_str = 'YES' )  
		EXEC dbo.fs_close_batch @process_ctrl_num  
  
RETURN 0  

GO
GRANT EXECUTE ON  [dbo].[tdc_credit_order] TO [public]
GO
