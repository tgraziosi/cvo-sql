SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_adh_rec_update]
	@user_id varchar(50), 
	@err_msg varchar(255) OUTPUT
AS


DECLARE	@adjcode 	varchar(255),
	@reason_code 	varchar(255),
	@ret		int,
	@rec_no		int,
	@serial_flg	char(1),
	@location	varchar(10), 
	@part_no	varchar(30), 
	@lot_ser	varchar(25), 
	@bin_no		varchar(12),
	@language	varchar(10),
	@qc_flag	char(1),
	@tran_no	varchar(20),
	@tran_ext	varchar(15),
	@mask_code	varchar(15),
	@serial_no	varchar(40),
	@qty		decimal(20, 8)

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @user_id), 'us_english')
SELECT @serial_flg = 'N'

--SCR#38215 Jim On 10/29/2007
DELETE FROM #temp_adhoc_receipts
WHERE row_id NOT IN (SELECT row_id FROM tdc_adhoc_receipts) 

------------------------------------------------------------------------------------------------------
-- Make sure checked records exist
------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM #temp_adhoc_receipts WHERE upd_flg != 0)  
BEGIN
    	-- 'Nothing is selected'
	SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock)
	 WHERE module = 'ADH' AND trans = 'tdc_adh_rec_update' AND err_no = -101 AND language = @language

    	RETURN -1
END

------------------------------------------------------------------------------------------------------
-- Make sure not updating record with error status
------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM #temp_adhoc_receipts WHERE upd_flg != 0 AND error_code IS NOT NULL)  
BEGIN
    	-- 'Cannot update records with error status ''Y'''
	SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock)
	 WHERE module = 'ADH' AND trans = 'tdc_adh_rec_update' AND err_no = -102 AND language = @language

    	RETURN -2
END

------------------------------------------------------------------------------------------------------
-- Cannot do adhoc adjust if the Adjustment Code is not configured
------------------------------------------------------------------------------------------------------
SELECT @adjcode = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'Adhoc_Recv_Adj'), '')     

IF @adjcode = '' 
BEGIN
    	-- 'Need to set up Adjustment Code in System Configuration'
	SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock)
	 WHERE module = 'ADH' AND trans = 'tdc_adh_rec_update' AND err_no = -103 AND language = @language

    	RETURN -3
END
 
------------------------------------------------------------------------------------------------------
-- Reason Code can be blank
------------------------------------------------------------------------------------------------------
SELECT @reason_code = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'Adhoc_Recv_Rsn'), '')    


TRUNCATE TABLE #adh_rec_serial_err

 INSERT INTO #adh_rec_serial_err(adhoc_rec_no, tran_type, tran_no, tran_ext, line_no, location, part_no, lot_ser, serial_no, bin_no)
 SELECT a.adhoc_rec_no, a.tran_type, a.tran_no, a.tran_ext, a.line_no, a.location, a.part_no, a.lot_ser, a.serial_no, a.bin_no
   FROM tdc_adhoc_rec_serial_tbl a(NOLOCK),
	tdc_serial_no_track b(NOLOCK),
	#temp_adhoc_receipts c(NOLOCK)
  WHERE a.part_no = b.part_no
    AND a.lot_ser = b.lot_ser
    AND a.serial_no = b.serial_no
    AND b.io_count %2 != 0
    AND c.upd_flg != 0
    AND c.error_code IS NULL      
    AND a.adhoc_rec_no = c.adhoc_rec_no
    AND a.part_no = c.part_no
    AND a.lot_ser = c.lot_ser
    AND a.tran_type = c.tran_type
    AND ISNULL(a.tran_no, '') = ISNULL(c.tran_no, '')
    AND ISNULL(a.tran_ext, '') = ISNULL(c.tran_ext, '')
    AND ISNULL(a.line_no, -1) = ISNULL(c.line_no, -1)
    AND ISNULL(a.bin_no, '') = ISNULL(c.bin_no, '')

IF @@ROWCOUNT > 0 
BEGIN
	SELECT @err_msg = 'Updating these record(s) will result in duplicate serial numbers in inventory.'
	RETURN -4	
END

 



------------------------------------------------------------------------------------------------------
-- Update PO records
------------------------------------------------------------------------------------------------------
DECLARE po_cur
CURSOR FOR
	SELECT DISTINCT tran_no
	  FROM #temp_adhoc_receipts a
	 WHERE error_code IS NULL
	   AND upd_flg != 0    
	   AND tran_type = 'P'
OPEN po_cur
FETCH NEXT FROM po_cur INTO @tran_no

WHILE @@FETCH_STATUS = 0
BEGIN                     	
	TRUNCATE TABLE #receipts
	     
	INSERT INTO #receipts(po_no, part_no, line_No, location, recv_date, quantity, who_entered, lot_ser, bin_no, date_expires, qc_flag)
 
	SELECT a.tran_no, a.part_no, a.line_No, a.location, a.rec_date, a.qty, @user_id, a.lot_ser, a.bin_no, dateadd(year, 1, getdate()), b.qc_flag
	  FROM #temp_adhoc_receipts a,
	       inv_master b(NOLOCK)
	 WHERE a.tran_no = @tran_no
	   AND a.error_code IS NULL
	   AND a.upd_flg != 0    
	   AND a.tran_type = 'P'
	   AND a.part_no = b.part_no	  
                    
	IF @@ROWCOUNT > 0 
	BEGIN         
	 
		EXEC @ret = tdc_ins_receipt @err_msg output
				         
		IF @@error <> 0
		BEGIN
			RAISERROR('tdc_ins_receipt failed.', 16, 1)
			RETURN -5
		END

		IF @ret < 0
		BEGIN
			RETURN -4	
		END

		DECLARE po_q_cur CURSOR FOR 
			SELECT a.part_no, a.bin_no, SUM(a.qty), a.lot_ser
			  FROM #temp_adhoc_receipts a,
			       inv_master b(NOLOCK)
			 WHERE a.tran_no = @tran_no
			   AND a.error_code IS NULL
			   AND a.upd_flg != 0    
			   AND a.tran_type = 'P'
			   AND a.part_no = b.part_no
			GROUP BY a.part_no, a.bin_no, a.lot_ser	

		OPEN po_q_cur
		FETCH NEXT FROM po_q_cur INTO @part_no, @bin_no, @qty, @lot_ser

		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC tdc_queue_po_putaway_sp @ret, @part_no, @bin_no, @qty, @lot_ser			

			If @ret < 0 
			BEGIN
				SELECT @err_msg = MAX(err_msg) FROM #adm_inv_adj WHERE err_msg IS NOT NULL
				CLOSE po_cur
				DEALLOCATE po_cur
				CLOSE po_q_cur
				DEALLOCATE po_q_cur
				RETURN -6
			END
			FETCH NEXT FROM po_q_cur INTO @part_no, @bin_no, @qty, @lot_ser
		END
		CLOSE po_q_cur
		DEALLOCATE po_q_cur 		
	END

	FETCH NEXT FROM po_cur INTO @tran_no
END

CLOSE po_cur
DEALLOCATE po_cur


------------------------------------------------------------------------------------------------------
-- Update Credit Order records
------------------------------------------------------------------------------------------------------
DECLARE credit_cur
CURSOR FOR
	SELECT DISTINCT tran_no, tran_ext
	  FROM #temp_adhoc_receipts a
	 WHERE error_code IS NULL
	   AND upd_flg != 0    
	   AND tran_type = 'C'
OPEN credit_cur
FETCH NEXT FROM credit_cur INTO @tran_no, @tran_ext

WHILE @@FETCH_STATUS = 0
BEGIN    
	TRUNCATE TABLE #adm_credit_order
	
	INSERT INTO #adm_credit_order (order_no, ext, serial_no, part_no, line_no, location, ordered, bin_no, lot_ser, date_expires, who_entered)
	SELECT CAST(tran_no AS INT), CAST(tran_ext AS INT), NULL, part_no, line_No, location, qty, bin_no, lot_ser, rec_date, @user_id
	  FROM #temp_adhoc_receipts 
	 WHERE tran_no = @tran_no
	   AND tran_ext = @tran_ext
	   AND error_code IS NULL
	   AND upd_flg != 0    
	   AND tran_type = 'C'
	 
	IF @@ROWCOUNT > 0 
	BEGIN         
	 
		EXEC @ret = tdc_credit_order 
		IF @@error <> 0
		BEGIN
			RAISERROR('tdc_credit_order failed.', 16, 1)
			RETURN -5
		END
		
		If @ret < 0 
		BEGIN
			SELECT @err_msg = MAX(err_msg) FROM #adm_credit_order WHERE err_msg IS NOT NULL
			CLOSE credit_cur
			DEALLOCATE credit_cur
			RETURN -6
		END

		EXEC @ret = tdc_queue_cred_ret_sp
		If @ret < 0 
		BEGIN
			SELECT @err_msg = MAX(err_msg) FROM #adm_credit_order WHERE err_msg IS NOT NULL
			CLOSE credit_cur
			DEALLOCATE credit_cur
			RETURN -7
		END
	END

	FETCH NEXT FROM credit_cur INTO @tran_no, @tran_ext
END

CLOSE credit_cur
DEALLOCATE credit_cur


------------------------------------------------------------------------------------------------------
-- Update xfer records
------------------------------------------------------------------------------------------------------
DECLARE xfer_cur
CURSOR FOR
	SELECT DISTINCT tran_no
	  FROM #temp_adhoc_receipts a
	 WHERE error_code IS NULL
	   AND upd_flg != 0    
	   AND tran_type = 'T'
OPEN xfer_cur
FETCH NEXT FROM xfer_cur INTO @tran_no

WHILE @@FETCH_STATUS = 0
BEGIN                     	 
	TRUNCATE TABLE #adm_rec_xfer
	    
	INSERT INTO #adm_rec_xfer (xfer_no, part_no, line_no, lot_ser, to_bin, location, qty, who)
	SELECT CAST(tran_no AS INT),  part_no, line_No, lot_ser, bin_no, location, qty, @user_id
	  FROM #temp_adhoc_receipts 
	 WHERE tran_no = @tran_no
	   AND error_code IS NULL
	   AND upd_flg != 0    
	   AND tran_type = 'T'
	IF @@ROWCOUNT > 0 
	BEGIN         
	 
		EXEC @ret = tdc_rec_xfer 
		         
		IF @@error <> 0
		BEGIN
			RAISERROR('tdc_rec_xfer failed.', 16, 1)
			RETURN -5
		END

		DECLARE xfer_q_cur CURSOR FOR 
			SELECT a.location, a.part_no, a.lot_ser, a.bin_no, SUM(a.qty)
			  FROM #temp_adhoc_receipts a,
			       inv_master b(NOLOCK)
			 WHERE a.tran_no = @tran_no
			   AND a.error_code IS NULL
			   AND a.upd_flg != 0    
			   AND a.tran_type = 'T'
			   AND a.part_no = b.part_no
			GROUP BY a.location, a.part_no, a.bin_no, a.lot_ser	

		OPEN xfer_q_cur
		FETCH NEXT FROM xfer_q_cur INTO @location, @part_no, @lot_ser, @bin_no, @qty 	

		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC @ret = tdc_queue_xfer_putaway @tran_no, @location, @part_no, @lot_ser, @bin_no, @qty 		
			If @ret < 0 
			BEGIN
				SELECT @err_msg = MAX(err_msg) FROM #adm_inv_adj WHERE err_msg IS NOT NULL
				CLOSE xfer_cur
				DEALLOCATE xfer_cur
				CLOSE xfer_q_cur
				DEALLOCATE xfer_q_cur
				RETURN -6
			END
			FETCH NEXT FROM xfer_q_cur INTO @location, @part_no, @lot_ser, @bin_no, @qty 	
		END
		CLOSE xfer_q_cur
		DEALLOCATE xfer_q_cur 	
	END

	FETCH NEXT FROM xfer_cur INTO @tran_no
END

CLOSE xfer_cur
DEALLOCATE xfer_cur

 
------------------------------------------------------------------------------------------------------
-- Update Adhoc records
------------------------------------------------------------------------------------------------------
TRUNCATE TABLE #adm_inv_adj
 
INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, reason_code, code) 
SELECT location, part_no, bin_no, lot_ser, rec_date, qty, 1, @user_id, @reason_code, @adjcode
FROM #temp_adhoc_receipts 
 WHERE error_code IS NULL
   AND upd_flg != 0    
   AND tran_type = 'A'


IF @@ROWCOUNT > 0 
BEGIN
	EXEC @ret = tdc_adhocreceiptputaway
	
	IF @@error <> 0
	BEGIN
		RAISERROR('tdc_adhocreceiptputaway failed.', 16, 1)
		RETURN -7
	END
END
        
------------------------------------------------------------------------------------------------------
-- Move to archive
------------------------------------------------------------------------------------------------------
INSERT INTO tdc_adhoc_rec_archive (adhoc_rec_no, rec_type, rec_ref_no, rec_date, tran_type, tran_no, tran_ext,
			 line_no, location, part_no, uom, lot_ser, bin_no, qty, status, error_code, userid, modified_date)
SELECT adhoc_rec_no, rec_type, rec_ref_no, rec_date, tran_type, tran_no, tran_ext, line_no, location, part_no, uom, 
		lot_ser, bin_no, qty, status, error_code, userid, modified_date
  FROM #temp_adhoc_receipts 
 WHERE upd_flg != 0 
   AND error_code IS NULL                      

DELETE FROM tdc_adhoc_receipts                   
WHERE row_id IN (SELECT row_id 
		   FROM #temp_adhoc_receipts
                  WHERE  error_code IS NULL       
                    AND upd_flg != 0) 
 

------------------------------------------------------------------------------------------------------        
-- Insert INTO TDC Log
------------------------------------------------------------------------------------------------------    
INSERT INTO tdc_log(tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no,location, quantity) 
SELECT GETDATE(), @user_id, 'VB', 'ADH', 'ADHOCRECV', adhoc_rec_no, '',  part_no, lot_ser, bin_no, location, qty
  FROM #temp_adhoc_receipts 
 WHERE upd_flg != 0  

------------------------------------------------------------------------------------------------------   
--Update the control type on the serial table
------------------------------------------------------------------------------------------------------   
 
DECLARE adh_rec_update_cur
CURSOR FOR
	SELECT DISTINCT tmp.adhoc_rec_no, tmp.location, tmp.part_no, tmp.lot_ser, tmp.bin_no, adh.serial_no
	  FROM #temp_adhoc_receipts tmp, tdc_adhoc_rec_serial_tbl adh (nolock)
	 WHERE upd_flg != 0
	   AND error_code IS NULL      
	   AND adh.adhoc_rec_no = tmp.adhoc_rec_no
	   AND adh.part_no = tmp.part_no
	   AND adh.lot_ser = tmp.lot_ser
	   AND adh.tran_type = tmp.tran_type
	   AND ISNULL(adh.tran_no, '') = ISNULL(adh.tran_no, '')
	   AND ISNULL(adh.tran_ext, '') = ISNULL(adh.tran_ext, '')
	   AND ISNULL(adh.line_no, -1) = ISNULL(adh.line_no, -1)
	   AND ISNULL(adh.bin_no, '') = ISNULL(adh.bin_no, '')

OPEN adh_rec_update_cur
FETCH NEXT FROM adh_rec_update_cur INTO @rec_no, @location, @part_no, @lot_ser, @bin_no, @serial_no

WHILE @@FETCH_STATUS = 0
BEGIN

	IF EXISTS (SELECT * 
		     FROM tdc_serial_no_track (nolock)
		    WHERE part_no = @part_no
		      AND lot_ser = @lot_ser
		      AND serial_no = @serial_no
		      AND IO_count % 2 <> 0 )
	BEGIN
		-- Some serial numbers already exists in inventory
		SELECT @err_msg = err_msg 
		  FROM tdc_lookup_error (nolock)
		 WHERE module = 'ADH' AND trans = 'tdc_adh_rec_update' AND err_no = -104 AND language = @language
	
		CLOSE adh_rec_update_cur
		DEALLOCATE adh_rec_update_cur

	    	RETURN -4
	END

	SELECT @mask_code = mask_code FROM tdc_inv_master (nolock) WHERE part_no = @part_no

	IF NOT EXISTS (SELECT * 
			 FROM tdc_serial_no_track (nolock)
	    		WHERE part_no = @part_no
		      	  AND lot_ser = @lot_ser
		      	  AND serial_no = @serial_no )
	BEGIN
		INSERT INTO tdc_serial_no_track(location, transfer_location, part_no, 
						lot_ser, mask_code, serial_no, serial_no_raw, IO_count, init_control_type, 
						init_trans, init_tx_control_no, last_control_type, last_trans, last_tx_control_no, 
						date_time, [user_id], arbc_no) 
		SELECT 	@location, @location, @part_no, 
			@lot_ser, @mask_code, @serial_no, @serial_no, 1, '0', 
			'ADHOCRECV', @rec_no, '0', 'ADHOCRECV', @rec_no, -- SCR #35384  9/2/05
			GETDATE(), @user_id, @bin_no
	END
	ELSE
	BEGIN		
		UPDATE tdc_serial_no_track
		   SET location = @location, transfer_location = @location, IO_count = IO_count + 1, 
		       last_control_type = '0', last_trans = 'ADHOCRECV', last_tx_control_no = @rec_no,	-- SCR #35384  9/2/05
		       date_time = GETDATE(), [user_id] = @user_id, arbc_no = @bin_no 
		 WHERE part_no = @part_no 
		   AND lot_ser = @lot_ser
		   AND serial_no = @serial_no
		   AND IO_count % 2 = 0
	END

	SELECT @serial_flg = 'Y'
	FETCH NEXT FROM adh_rec_update_cur INTO @rec_no, @location, @part_no, @lot_ser, @bin_no, @serial_no
END

CLOSE adh_rec_update_cur
DEALLOCATE adh_rec_update_cur

IF @serial_flg = 'Y'
BEGIN
	INSERT INTO tdc_adhoc_rec_serial_archive (adhoc_rec_no, tran_type, tran_no, tran_ext, line_no, location, part_no, lot_ser, bin_no, serial_no, serial_no_raw)
	SELECT adhoc_rec_no, tran_type, tran_no, tran_ext, line_no, location, part_no, lot_ser, bin_no, serial_no, serial_no_raw
	  FROM tdc_adhoc_rec_serial_tbl (NOLOCK) 
	 WHERE adhoc_rec_no = @rec_no
	
	DELETE FROM tdc_adhoc_rec_serial_tbl WHERE adhoc_rec_no = @rec_no
END 

RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_adh_rec_update] TO [public]
GO
