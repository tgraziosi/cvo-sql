SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************/
/* Name:	tdc_queue_qcrelease_sp		      	      		*/
/*									*/
/* Module:	WMS							*/
/*						      			*/
/* Input:						      		*/
/*	Location  -	Location					*/
/*	tran_no   - 	transaction Number			      	*/
/*	part_no   - 	Part Number			    		*/
/*	Lot	  -	Lot						*/
/*	bin_no	  -	bin number					*/
/*	qty	  - 	qty to be released				*/
/*	tran_code -	transaction type				*/
/*	tran_ext  -	transaction extention				*/
/*									*/
/* Output:        					     	 	*/
/*	errmsg	-	Null if no errors		     	 	*/
/*									*/
/* Description:								*/
/*	This SP is called once a QC hold is released. If the inventory	*/
/*	that was being held has a cooresponding queue transaction, the 	*/
/*	queue transaction will be released and the qty will be updated.	*/
/*									*/
/* Revision History:							*/
/* 	Date		Who	Description				*/
/*	----		---	-----------				*/
/* 	3/23/2000	MK	Initial					*/
/*	6/01/2000	KMH	added code to change qty in queue if 	*/
/*				credit return is released		*/
/*	6/05/2000	IA	fixed code for CRPTWY on queue for QC  	*/
/*				Release   (line sensetive)		*/
/*	6/08/2000	IA	fixed code for POPTWY on queue for QC 	*/
/*				Release	sensetive on rejected type (S/R)*/
/*	6/14/2000	IA	fixed code for WOPTWY on queue for QC 	*/
/*				(line sensetive)			*/
/*	6/21/2000	IA	fixed code for POPTWY on queue for QC 	*/
/*				Release not sensetive on rejected type  */
/************************************************************************/

CREATE PROCEDURE [dbo].[tdc_queue_qcrelease_sp](
	@tran_no        int,	
	@tran_ext	int,
	@tran_code	varchar (1),
	@amt_to_release decimal (20,8),
	@orig_bin       varchar (12),
	@bin_no         varchar (12),
	@orig_lot	varchar (25),
	@lot_ser	varchar (25),
	@part_no	varchar (30),
	@location	varchar (10),
	@line_no	int,
	@rej_type	char(1),
	@qc_no		int
)
AS


DECLARE @q_tran_type varchar (10)
DECLARE @language varchar(10), @msg varchar(255)
DECLARE @csorder_no int,
	@csorder_ext int, 
	@cscount int, 
	@csline_no int,
	@csdest_bin varchar(12), 
	@cstrg_off bit,
	@csorder_type varchar(1),
	@cscd_qty decimal(20, 8),
	@userid	varchar(50),
	@q_priority int

DECLARE @po_no varchar(16)
DECLARE @tran_id int
DECLARE @tran_type varchar(10), @order_type char(1)
DECLARE @po_qty decimal(20,8)

	SELECT @q_priority = CAST(ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'Pick_Q_Priority'), 5) AS INT)
	IF @q_priority = 0 SET @q_priority = 5

BEGIN

	SELECT @userid = ISNULL(who, 'sa') FROM #temp_who
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @userid), 'us_english')
	SELECT @msg = ISNULL(err_msg, 'Error Updating TDC_Put_Queue on QC Release.') 
	  FROM tdc_lookup_error (nolock)
	 WHERE module = 'SPR' AND trans = 'tdc_queue_qcrelease_sp' AND err_no = -1 AND language = @language

	SELECT @q_tran_type = CASE WHEN @tran_code = 'R' THEN 'POPTWY'
			   	   WHEN @tran_code = 'P' THEN 'WOPTWY'
			   	   WHEN @tran_code = 'C' THEN 'CRPTWY'
			   	   ELSE 'ERROR'
		      END

	IF EXISTS (SELECT * 
		     FROM tdc_soft_alloc_tbl (NOLOCK) 
		    WHERE location = @location AND part_no = @part_no AND lot_ser = 'CDOCK' AND bin_no = 'CDOCK')
	BEGIN

-------------------------------------------
		IF (@tran_code IN ('P', 'R'))
		BEGIN
			IF (@tran_code = 'R') 
			BEGIN
				SET @order_type = 'P'
				SELECT @po_no = po_no FROM receipts (nolock) WHERE receipt_no = @tran_no
			END
			ELSE
			BEGIN
				SET @order_type = 'W'
				SELECT @po_no = CAST(@tran_no AS VARCHAR(16))
			END

			IF EXISTS (SELECT * 
				     FROM tdc_cdock_mgt (nolock)
				    WHERE from_tran_type = @order_type
				      AND from_tran_no   = @po_no
				      AND ISNULL(from_tran_ext, 0) = 0
				      AND location = @location
				      AND part_no  = @part_no)
			BEGIN
				EXEC @tran_id = tdc_cross_dock_management @location, @part_no, @lot_ser, @bin_no, @amt_to_release, @order_type, @po_no, 0, @amt_to_release OUTPUT
			END
		
			IF @amt_to_release <= 0 RETURN @tran_id
		END
--------------------------------------------

		DECLARE next_cd CURSOR FOR
		SELECT order_no, order_ext, qty, line_no, dest_bin, trg_off, order_type 
		  FROM tdc_soft_alloc_tbl 
		 WHERE location = @location AND part_no = @part_no AND lot_ser = 'CDOCK' AND bin_no = 'CDOCK' AND @amt_to_release > 0

		OPEN next_cd
		FETCH NEXT FROM next_cd INTO @csorder_no, @csorder_ext, @cscd_qty, @csline_no, @csdest_bin, @cstrg_off, @csorder_type
		WHILE (@@FETCH_STATUS = 0)
		BEGIN

			IF (@cscd_qty >= @amt_to_release) --all inbound inventory will be used for sales order pick... no putaway inserted
			BEGIN
				UPDATE tdc_soft_alloc_tbl 
				   SET qty = (qty - @amt_to_release)
				 WHERE CURRENT OF next_cd

				UPDATE tdc_pick_queue
				   SET qty_to_process = qty_to_process - @amt_to_release
				 WHERE trans_type_no = @csorder_no 
				   AND trans_type_ext = @csorder_ext 
				   AND line_no = @csline_no
				   AND part_no = @part_no 
				   AND lot = 'CDOCK' 
				   AND bin_no = 'CDOCK'

				IF EXISTS (SELECT * 
					     FROM tdc_soft_alloc_tbl 
					    WHERE order_no = @csorder_no 
					      AND order_ext = @csorder_ext 
					      AND location = @location
					      AND part_no = @part_no 
					      AND line_no = @csline_no 
					      AND lot_ser = @orig_lot 
					      AND bin_no = @orig_bin
					      AND order_type = @csorder_type)
				BEGIN
					UPDATE tdc_soft_alloc_tbl
					   SET qty = qty + @amt_to_release
					 WHERE order_no = @csorder_no 
					   AND order_ext = @csorder_ext 
					   AND location = @location 
					   AND part_no = @part_no 
					   AND line_no = @csline_no 
					   AND lot_ser = @orig_lot 
					   AND bin_no = @orig_bin
					   AND order_type = @csorder_type
				END
				ELSE
				BEGIN
					INSERT INTO tdc_soft_alloc_tbl 
						(order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin, trg_off, order_type, q_priority) 
					  VALUES(@csorder_no, @csorder_ext, @location, @csline_no, @part_no, @orig_lot, @orig_bin, @amt_to_release,
							 @bin_no, @csdest_bin, @cstrg_off, @csorder_type, @q_priority)
				END

				SELECT @amt_to_release = 0
				BREAK
			END
			ELSE --IF (@cscd_qty < @amt_to_release) --putaway inserted for left over qty
			BEGIN
				DELETE FROM tdc_soft_alloc_tbl 
				WHERE CURRENT OF next_cd

				DELETE FROM tdc_pick_queue 
				WHERE trans_type_no = @csorder_no 
				  AND trans_type_ext = @csorder_ext 
				  AND line_no = @csline_no  
				  AND part_no = @part_no 
				  AND lot = 'CDOCK' 
				  AND bin_no = 'CDOCK' 

				IF EXISTS (SELECT * 
					     FROM tdc_soft_alloc_tbl
					    WHERE order_no = @csorder_no 
					      AND order_ext = @csorder_ext 
					      AND location = @location
					      AND part_no = @part_no  
					      AND line_no = @csline_no 
					      AND lot_ser = @orig_lot 
					      AND bin_no = @orig_bin)
				BEGIN
					UPDATE tdc_soft_alloc_tbl
					   SET qty = qty + @cscd_qty
					 WHERE order_no = @csorder_no 
					   AND order_ext = @csorder_ext 
					   AND location = @location
					   AND part_no = @part_no  
					   AND line_no = @csline_no
					   AND lot_ser = @orig_lot 
					   AND bin_no = @orig_bin
				END
				ELSE
				BEGIN
					INSERT INTO tdc_soft_alloc_tbl 
						(order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin, trg_off, order_type, q_priority) 
					  VALUES(@csorder_no, @csorder_ext, @location, @csline_no, @part_no, @orig_lot, @orig_bin, @cscd_qty,
							 @bin_no, @csdest_bin, @cstrg_off, @csorder_type, @q_priority)
				END

				SELECT @amt_to_release = @amt_to_release - @cscd_qty

				IF(@amt_to_release <= 0) BREAK
			END

			FETCH NEXT FROM next_cd INTO @csorder_no, @csorder_ext, @cscd_qty, @csline_no, @csdest_bin, @cstrg_off, @csorder_type			
		END

		CLOSE next_cd
		DEALLOCATE next_cd
	END

	IF (@amt_to_release <= 0)
	BEGIN
		--transaction is a PO
		IF (@tran_code = 'R')
		BEGIN
			DELETE FROM tdc_put_queue
			WHERE trans 	= @q_tran_type 
			  AND tran_receipt_no = @tran_no 
			  AND location 	= @location 
		       	  AND part_no 	= @part_no 
			  AND lot 	= @orig_lot 
			  AND bin_no 	= @orig_bin 
		       	  AND tx_lock 	= 'Q'
		END		
		--transaction is a Work Order Prod. Output
		ELSE IF (@tran_code = 'P')
		BEGIN
			DELETE FROM tdc_put_queue
			 WHERE tran_id_link = @qc_no
			-- WHERE trans 	= @q_tran_type 
			--   AND trans_type_no  = @tran_no 
		        --   AND trans_type_ext = @tran_ext 
		        --   AND location 	= @location 
		        --   AND part_no 	= @part_no
			--   AND lot 		= @orig_lot 
		        --   AND bin_no 	= @orig_bin 
		        --   AND line_no 	= @line_no 		/* added line sencetive */
		        --   AND tx_lock 	= 'Q'
		END		
		--transaction is a Credit Return
		ELSE IF (@tran_code = 'C')
		BEGIN
			DELETE FROM tdc_put_queue
			 WHERE trans 	= @q_tran_type 
			   AND trans_type_no = @tran_no 
			   AND location = @location 
			   AND part_no 	= @part_no
			   AND lot 	= @orig_lot 
			   AND bin_no 	= @orig_bin
			   AND line_no 	= @line_no		/* added line sencetive */
			   AND tx_lock 	= 'Q'
		END
	END
	ELSE
	BEGIN
		--transaction is a PO
		IF (@tran_code = 'R')
		BEGIN
			UPDATE tdc_put_queue 
			   SET tx_lock = 'R', qty_to_process = @amt_to_release, [user_id] = @userid, lot = @lot_ser, bin_no = @bin_no
			 WHERE trans = @q_tran_type 
			   AND tran_receipt_no = @tran_no 
			   AND location = @location 
		           AND part_no = @part_no 
		           AND lot = @orig_lot
			   AND bin_no = @orig_bin
		           AND tx_lock = 'Q'
		END
		--transaction is a Work Order Prod. Output
		ELSE IF (@tran_code = 'P')
		BEGIN
			UPDATE tdc_put_queue 
			   SET tx_lock = 'R', qty_to_process = @amt_to_release, [user_id] = @userid, lot = @lot_ser, bin_no = @bin_no
			 WHERE tran_id_link = @qc_no
		--	 WHERE trans = @q_tran_type 
		--	   AND trans_type_no = @tran_no 
		--         AND trans_type_ext = @tran_ext 
		--         AND location = @location 
		--         AND part_no = @part_no
		--         AND lot = @orig_lot
		--	   AND bin_no = @orig_bin
		--	   AND line_no = @line_no 	/* added line sencetive */
		--         AND tx_lock = 'Q'
		END
		--transaction is a Credit Return
		ELSE IF (@tran_code = 'C')
		BEGIN
			UPDATE tdc_put_queue 
			   SET tx_lock = 'R', qty_to_process = @amt_to_release, [user_id] = @userid, lot = @lot_ser, bin_no = @bin_no 
			 WHERE trans = @q_tran_type 
			   AND trans_type_no = @tran_no 
		           AND location = @location 
		           AND part_no = @part_no
		           AND lot = @orig_lot
			   AND bin_no = @orig_bin
			   AND line_no = @line_no	/* added line sencetive */
		           AND tx_lock = 'Q'
		END
	END

RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[tdc_queue_qcrelease_sp] TO [public]
GO
