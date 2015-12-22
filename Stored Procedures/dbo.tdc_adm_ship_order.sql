SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************************************************* */  
/* This procedure ships picked orders              */  
/* Revised by CAC.  Changed status updates to 'R' rather than 'S'           */  
/*                  We want the user to be able to print an invoice.                           */  
/*                  CAC.  July 31, 1998 for Lunt.                                              */  
/********************************************************************************************* */  
-- v1.0 CB 23/04/2015 - Performance Changes
CREATE PROC [dbo].[tdc_adm_ship_order] ( @Shift_Day_by int )    
AS  
BEGIN
  
	DECLARE @order_no int,   
			@ext int,    
			@recid int,  
			@loc varchar(10),  
			@item varchar(30),   
			@lot varchar(25),  
			@bin varchar(12),  
			@qty decimal(20,8),  
			@line_no int,  
			@err int,  
			@ret int,  
			@who varchar(50),  
			@err_msg varchar(255),  
			@language varchar(10)  

	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int
	-- v1.0 End
  
	SELECT @order_no = MIN(order_no), @ext = MIN(ext) FROM #adm_ship_order  
	SELECT @who = who FROM #temp_who   
  
	SELECT @language = Language FROM tdc_sec (nolock) WHERE userid = @who  
	SELECT @language = ISNULL(@language, 'us_english')  
	SELECT @who = login_id FROM #temp_who   
  
    /* Make sure order number exists */  
    IF NOT EXISTS (SELECT * FROM orders_all (nolock) WHERE order_no = @order_no)  
    BEGIN  
		SELECT	@err_msg = err_msg   
		FROM	tdc_lookup_error (nolock)  
		WHERE	module = 'SPR' 
		AND		trans = 'tdc_adm_ship_order' 
		AND		err_no = -101 
		AND		language = @language  
             
		-- 'Order number is not valid.'  
        UPDATE #adm_ship_order SET err_msg = @err_msg  
        RETURN -101  
	END  
  
    IF NOT EXISTS (SELECT * FROM orders_all (NOLOCK) WHERE order_no = @order_no and ext = @ext)  
    BEGIN  
		SELECT	@err_msg = err_msg   
		FROM	tdc_lookup_error (nolock)  
		WHERE	module = 'SPR' 
		AND		trans = 'tdc_adm_ship_order' 
		AND		err_no = -102 
		AND		language = @language  
             
		-- 'Order extension is not valid.'  
        UPDATE #adm_ship_order SET err_msg = @err_msg                                         
        RETURN -102  
	END  
  
    /* Make sure the status is picked/printed */  
    IF NOT EXISTS (SELECT * FROM orders_all (nolock) WHERE order_no = @order_no AND ext = @ext AND (status = 'P' or status = 'Q'))  
    BEGIN  
		SELECT	@err_msg = err_msg   
		FROM	tdc_lookup_error (nolock)  
		WHERE	module = 'SPR' 
		AND		trans = 'tdc_adm_ship_order' 
		AND		err_no = -103 
		AND		language = @language  
             
		-- 'Order must be picked.'  
        UPDATE #adm_ship_order SET err_msg = @err_msg                               
        RETURN -103  
	END  
  
	IF EXISTS (SELECT * FROM tdc_config (NOLOCK) WHERE [function] = 'N_QTY_AUTO_PICK' AND active = 'Y')  
	BEGIN  
		UPDATE	ord_list   
		SET		shipped = ordered   
		WHERE	order_no = @order_no  
		AND		order_ext = @ext  
		AND		shipped = 0 -- SCR 35965 Jim 9/22/06  
		AND		(SELECT status  
				FROM	inv_master (NOLOCK) 
				WHERE inv_master.part_no = ord_list.part_no) = 'V' --non-quantity bearing parts  
   
		UPDATE	tdc_dist_item_list   
		SET		shipped = quantity   
		WHERE	order_no = @order_no  
		AND		order_ext = @ext  
		AND		[function] = 'S'  
		AND		part_no in (SELECT part_no  
							FROM ord_list (nolock)  
							WHERE order_no = @order_no  
							AND order_ext = @ext  
							AND part_type = 'V') --non-quantity bearing parts  
	END  
   
	--        BEGIN TRAN  
  
	--SCR 36708 which is releated to 35783 MK  we decided that we need to call this  
	-- just to be safe. You could add another if to take into consideration the Non Qty bearing parts flag...but we decided to call it all the time  
	--Greg and I.   
	--IF EXISTS (SELECT 1 FROM tdc_config WHERE [function] = 'delay_so_update' AND active = 'Y')  
	--BEGIN  
	--EXEC dbo.fs_calculate_oetax_wrap @order_no, @ext  
	EXEC dbo.fs_calculate_oetax @order_no, @ext, @err OUT  
	IF @err <> 1   
	BEGIN  
		RAISERROR ('SP fs_calculate_oetax failed', 16, 1)  
		RETURN -111  
	END  
          
	EXEC dbo.fs_updordtots @order_no, @ext     
	IF @@ERROR <> 0   
	BEGIN  
	    RAISERROR ('SP fs_updordtots failed', 16, 1)  
		RETURN -112  
	END  
	--END  
    
	/* Update the order status to shipped */  
    UPDATE	orders_all 
	SET		date_shipped = getdate() - @Shift_Day_by, 
			status = 'R', 
			printed = 'R', 
			process_ctrl_num = ' ' 
	WHERE	order_no = @order_no 
	AND		ext = @ext  
  
	IF @@ERROR != 0  
	BEGIN  
		RAISERROR('Update orders failed', 16, 1)  
		RETURN -9999  
	END  
  
	UPDATE	tdc_order 
	SET		tdc_status = 'R1' 
	WHERE	order_no = @order_no 
	AND		order_ext = @ext  
  
	IF @@ERROR != 0  
	BEGIN  
		RAISERROR('Update tdc_order failed', 16, 1)  
		RETURN -9998  
	END  
  
	-- v1.0 Start
	CREATE TABLE #tdc_ship_line_cursor (
		row_id		int IDENTITY(1,1),
		bin_no		varchar(12) NULL,
		lot_ser		varchar(25) NULL,
		line_no		int,
		qty			decimal(20,8))

	INSERT	#tdc_ship_line_cursor (bin_no, lot_ser, line_no, qty)
	-- v1.0 DECLARE line_cursor CURSOR FOR 
	SELECT	bin_no, lot_ser, line_no, qty 
	FROM	lot_bin_ship (nolock) 
	WHERE	tran_no = @order_no 
	AND		tran_ext = @ext  

	-- v1.0 OPEN line_cursor  
	-- v1.0 FETCH NEXT FROM line_cursor INTO @bin, @lot, @line_no, @qty  
	-- v1.0 WHILE (@@FETCH_STATUS = 0)  
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@bin = bin_no,
			@lot = lot_ser,
			@line_no = line_no,
			@qty = qty
	FROM	#tdc_ship_line_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
	
	WHILE @@ROWCOUNT <> 0
	BEGIN  
		UPDATE	lot_bin_ship   
		SET		tran_code = 'R', 
				date_tran = GETDATE(), 
				who = @who    
		WHERE	tran_no = @order_no   
		AND		tran_ext = @ext   
		AND		bin_no = @bin  
		AND		lot_ser = @lot  
		AND		line_no = @line_no   
		AND		qty = @qty  
  
		IF @@ERROR != 0  
		BEGIN  
			-- v1.0 CLOSE line_cursor  
			-- v1.0 DEALLOCATE line_cursor  
			RAISERROR('Update tdc_order lot_bin_ship', 16, 1)  
			RETURN -9997  
		END  
  
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@bin = bin_no,
				@lot = lot_ser,
				@line_no = line_no,
				@qty = qty
		FROM	#tdc_ship_line_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
  
		-- v1.0 FETCH NEXT FROM line_cursor INTO @bin, @lot, @line_no, @qty  
	END  
  
	-- v1.0 CLOSE line_cursor  
	-- v1.0 DEALLOCATE line_cursor  
  
	IF EXISTS (SELECT * FROM config (NOLOCK) WHERE flag = 'SHP_AUTO_POST' AND value_str = 'YES')  
	BEGIN  
		EXEC @ret = tdc_auto_post_ship @order_no, @ext, NULL, 'Y', 'Y', @who, @err OUTPUT  
    
		IF @@ERROR != 0  
		BEGIN  
			RAISERROR('EXEC tdc_auto_post_ship failed', 16, 1)  
			RETURN -9996  
		END  
		IF (@ret < 0)  
        BEGIN  
			--    IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
            RETURN @ret  
        END  
	END  
  
	-- COMMIT TRAN  
  
	RETURN 0  
END
GO
GRANT EXECUTE ON  [dbo].[tdc_adm_ship_order] TO [public]
GO
