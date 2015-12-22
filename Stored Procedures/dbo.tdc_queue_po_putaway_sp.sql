SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************************************************************/
/* Name:	tdc_queue_putaway_sp		      	      			*/
/*										*/
/* Module:	WMS								*/
/*						      				*/
/* Input:						      			*/
/*	PO_no   - 	PO Number			      			*/
/*	part_no - 	Part Number			    			*/
/*	mod	-	Module that stored procedure is called from		*/
/*	qty	- 	qty to be putaway					*/
/*	bin_no	-	receipt bin where inventory is waiting			*/
/* Output:        					     	 		*/
/*	tran_id	-	Neg. # if errors occured	     	 		*/
/*										*/
/* Description:									*/
/*	This SP places a bin to bin transaction on the put_queue after		*/
/*	a PO, Xfer, Credit Return or a manufacturing transaction   		*/
/*	has been completed. The bin_no is set equal to the receipt bin.		*/
/*										*/
/* Revision History:								*/
/* 	Date		Who	Description					*/
/*	----		---	-----------					*/
/* 	12/14/1999	KMH	Initial						*/
/* 	3/28/2000	KMH	added a check for QC parts - insert		*/
/*				tx_lock = 'Q'					*/
/*	5/16/2000	KMH	changed the return value to equal 		*/
/*				tran_id						*/
/*	5/23/2000	KMH	added check for QC parts on PO Receipt		*/
/*				at the line level				*/
/*	5/31/2000	KMH	added a check for qty in Xfer putaways  	*/
/*										*/
/*	6/14/2000	IA	Deleted putaway for 'WOPTWY'. Replaced  	*/
/*				into separate SP tdc_queue_wo_putaway_sp	*/
/*	8/14/2000	IA	Deleted putaway for 'XPTWY'. Replaced   	*/
/*				into separate SP tdc_queue_xfer_putaway 	*/
/*	8/14/2000	IA	Renamed into tdc_queue_po_putaway 		*/
/*				because of one transaction left in this SP	*/
/*										*/
/********************************************************************************/

-- v1.1 CT 13/06/2013 - Issue #695 - Logic for receiving against a PO line which is ringfenced for Backorder processing

CREATE PROCEDURE [dbo].[tdc_queue_po_putaway_sp] 
	@receipt_no 	int,
	@part_no 	varchar (30),
	@bin_no 	varchar (12),
	@qty 		decimal(20, 8),
	@lot 		varchar (25)
AS


DECLARE @location varchar (10),
	@assign_group char (30),
	@po_no varchar (16),
	@priority int,
	@seq_no int,
	@tran_id int,
	@tx_lock varchar(2),
	@order_type char(1),
	@cd_qty decimal(20, 8),
	@po_qty decimal(20, 8),
	@order_no int,
	@order_ext int, 
	@count int, 
	@line_no int,
	@target_bin varchar(12), 
	@dest_bin varchar(12), 
	@trg_off bit,
	@filled_ind char(1),
	@who varchar(50),
	@tran_type varchar(10),
	@bintype int

-- START v1.1
	DECLARE @releases_row_id	INT,
			@qty_to_allocate	DECIMAL(20,8),
			@qty_os				DECIMAL(20,8),
			@qty_applied		DECIMAL(20,8),
			@qty_received		DECIMAL(20,8),
			@qty_crossdock		DECIMAL(20,8),
			@rec_id				INT,
			@template_code		VARCHAR(30),
			@min_crossdock		DECIMAL(20,8),
			@r_bin_no			VARCHAR(12),
			@r_tran_id			INT,
			@rdate				DATETIME,
			@po_line			INT,
			@xd_tran_id			INT,
			@non_xd_tran_id		INT
	-- END v1.1

	SELECT @priority = ISNULL((SELECT value_str FROM tdc_config (nolock) WHERE [function] = 'Put_Q_Priority'), '5')
	IF @priority = '0' SELECT @priority = '5'

	SELECT @assign_group = 'PUTAWAY'
	SELECT @tx_lock = 'R'
	SELECT @filled_ind = 'N'

	SELECT @who = who FROM #temp_who

	IF (SELECT qc_flag FROM receipts (NOLOCK) WHERE receipt_no = @receipt_no AND part_no = @part_no) = 'Y'
		SELECT @tx_lock = 'Q'

	SELECT @location = location, @po_no = po_no,
			@rdate = release_date, @po_line = po_line -- v1.1
	  FROM receipts (nolock) 
 	 WHERE receipt_no = @receipt_no AND part_no = @part_no

-------------------------------------------

	IF EXISTS (SELECT * 
		     FROM tdc_cdock_mgt (nolock)
		    WHERE from_tran_type = 'P'
		      AND from_tran_no   = @po_no
		      AND (from_tran_ext IS NULL OR from_tran_ext = 0)
		      AND location = @location
		      AND part_no  = @part_no)
	BEGIN
		EXEC @tran_id = tdc_cross_dock_management @location, @part_no, @lot, @bin_no, @qty, 'P', @po_no, 0, @qty OUTPUT
	END

	IF @qty <= 0 RETURN @tran_id

--------------------------------------------

	SELECT @bintype = (SELECT count(*) FROM tdc_bin_master (nolock) WHERE location = @location AND bin_no = @bin_no AND usage_type_code = 'RECEIPT' AND status = 'A')

	IF(@bintype > 0)
		EXEC @seq_no = tdc_queue_get_next_seq_num  'tdc_put_queue', @priority

	SELECT @count = count(*) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE location = @location AND part_no = @part_no AND lot_ser = 'CDOCK' AND bin_no = 'CDOCK'
	
	-- Cross dock commitments found for inbound inventory
	IF (@count <> 0 AND @tx_lock != 'Q')
	BEGIN
		DECLARE next_cd CURSOR FOR
			SELECT trans_type_no, trans_type_ext, qty_to_process, line_no, trans, tran_id
			  FROM tdc_pick_queue (NOLOCK)
			 WHERE location = @location
			   AND part_no = @part_no
			   AND lot = 'CDOCK'
			   AND bin_no = 'CDOCK'
			   AND NOT EXISTS (SELECT * 
					     FROM tdc_cdock_mgt (nolock)
					    WHERE tran_type = trans
					      AND trans_type_no  = tran_no
					      AND ISNULL(trans_type_ext, 0) = ISNULL(tran_ext, 0)
					      AND location = @location 
					      AND part_no  = @part_no)
			ORDER BY priority, date_time

		OPEN next_cd
		FETCH NEXT FROM next_cd into @order_no, @order_ext, @cd_qty, @line_no, @tran_type, @tran_id

		WHILE (@@FETCH_STATUS = 0 AND @filled_ind = 'N')
		BEGIN
			SELECT @target_bin = target_bin, @dest_bin = dest_bin, @trg_off =  trg_off, @order_type = order_type 
			  FROM tdc_soft_alloc_tbl (NOLOCK)
			 WHERE order_no = @order_no
			   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
			   AND location = @location
			   AND part_no = @part_no
			   AND lot_ser = 'CDOCK'
			   AND bin_no = 'CDOCK'

			IF (@cd_qty >= @qty) --all inbound inventory will be used for sales order pick... no putaway inserted
			BEGIN
				UPDATE tdc_soft_alloc_tbl 
				   SET qty = (qty - @qty) 
				 WHERE order_no = @order_no
				   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
				   AND line_no = @line_no
				   AND lot_ser = 'CDOCK'
				   AND bin_no = 'CDOCK'
			 	   AND part_no = @part_no
				   AND order_type = @order_type

				IF (@cd_qty = @qty)
				BEGIN
					DELETE FROM tdc_pick_queue 
					 WHERE trans_type_no = @order_no
					   AND ISNULL(trans_type_ext, 0) = ISNULL(@order_ext, 0)
					   AND line_no = @line_no
					   AND lot = 'CDOCK'
					   AND bin_no = 'CDOCK'
					   AND part_no = @part_no
					   AND trans = @tran_type
					   AND tran_id = @tran_id
				END
				ELSE
				BEGIN
					UPDATE tdc_pick_queue 
					   SET qty_to_process = (qty_to_process - @qty) 
					 WHERE trans_type_no = @order_no
					   AND ISNULL(trans_type_ext, 0) = ISNULL(@order_ext, 0)
					   AND line_no = @line_no
					   AND lot = 'CDOCK'
					   AND bin_no = 'CDOCK'
					   AND part_no = @part_no
					   AND trans = @tran_type
					   AND tran_id = @tran_id
				END

				IF EXISTS (SELECT * 
					     FROM tdc_soft_alloc_tbl
					    WHERE order_no = @order_no
					      AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
					      AND location = @location
					      AND part_no = @part_no
					      AND line_no = @line_no
					      AND lot_ser = @lot
					      AND bin_no = @bin_no)
				BEGIN
					UPDATE tdc_soft_alloc_tbl
					   SET qty = qty + @qty
					 WHERE order_no = @order_no
					   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
					   AND location = @location
					   AND part_no = @part_no
					   AND line_no = @line_no
					   AND lot_ser = @lot
					   AND bin_no = @bin_no
				END
				ELSE
				BEGIN
					INSERT INTO tdc_soft_alloc_tbl (order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin, trg_off, order_type, q_priority) 
								VALUES(@order_no, @order_ext, @location, @line_no, @part_no, @lot, @bin_no, @qty, @bin_no, @dest_bin, @trg_off, @order_type, @priority)
				END

				SELECT @filled_ind = 'Y'
			END
			ELSE --putaway inserted for left over qty
			BEGIN
				DELETE FROM tdc_soft_alloc_tbl 
				 WHERE order_no = @order_no
				   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
				   AND line_no = @line_no
				   AND lot_ser = 'CDOCK'
				   AND bin_no = 'CDOCK'
				   AND part_no = @part_no

				DELETE FROM tdc_pick_queue
				 WHERE trans_type_no = @order_no
				   AND ISNULL(trans_type_ext, 0) = ISNULL(@order_ext, 0)
				   AND line_no = @line_no
				   AND part_no = @part_no
				   AND lot = 'CDOCK'
				   AND bin_no = 'CDOCK'
				   AND tran_id = @tran_id

				IF EXISTS (SELECT * 
					     FROM tdc_soft_alloc_tbl
					    WHERE order_no = @order_no
					      AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
					      AND location = @location
					      AND part_no = @part_no
					      AND line_no = @line_no
					      AND lot_ser = @lot
					      AND bin_no = @bin_no)
				BEGIN
					UPDATE tdc_soft_alloc_tbl
					   SET qty = qty + @cd_qty
					 WHERE order_no = @order_no
					   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
					   AND location = @location
					   AND part_no = @part_no
					   AND line_no = @line_no
					   AND lot_ser = @lot
				 	   AND bin_no = @bin_no
				END
				ELSE
				BEGIN
					INSERT INTO tdc_soft_alloc_tbl (order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin, trg_off, order_type, q_priority) 
								VALUES(@order_no, @order_ext, @location, @line_no, @part_no, @lot, @bin_no, @cd_qty, @bin_no, @dest_bin, @trg_off, @order_type, @priority)
				END

				SELECT @qty = (@qty - @cd_qty)				
			END

			FETCH NEXT FROM next_cd into @order_no, @order_ext, @cd_qty, @line_no, @tran_type, @tran_id			
		END

		DEALLOCATE next_cd
		
		IF (@filled_ind = 'N') AND (@bintype > 0)
		BEGIN						
			INSERT INTO tdc_put_queue (trans_source, trans, priority, seq_no, company_no, location, warehouse_no, 
				trans_type_no, trans_type_ext, tran_receipt_no, line_no, pcsn, part_no, eco_no,
				lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process, qty_processed, qty_short, next_op,
				tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock) 
			VALUES('CO', 'POPTWY', @priority, @seq_no, NULL, @location, NULL, @po_no, NULL, 
				@receipt_no, NULL, NULL, @part_no, NULL, @lot, NULL, NULL, NULL, @bin_no, @qty, 0, 0, NULL,
				NULL, GETDATE(), @assign_group, NULL, @who, NULL, NULL, 'M', @tx_lock)

			SELECT @tran_id = MAX(tran_id) FROM tdc_put_queue
		END
	END
	-- No cross dock commitments found for inbound inventory, so total qty should be inserted in queue for putaway.
	ELSE IF(@bintype > 0)
	BEGIN
		INSERT INTO tdc_put_queue (trans_source, trans, priority, seq_no, company_no, location, warehouse_no, 
			trans_type_no, trans_type_ext, tran_receipt_no, line_no, pcsn, part_no, eco_no,
			lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process, qty_processed, qty_short, next_op,
			tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock)
		VALUES('CO', 'POPTWY', @priority, @seq_no, NULL, @location, NULL, @po_no, NULL, 
			@receipt_no, NULL, NULL, @part_no, NULL, @lot, NULL, NULL, NULL, @bin_no, @qty, 0, 0, NULL, 
			NULL, GETDATE(), @assign_group, NULL, @who, NULL, NULL, 'M', @tx_lock)

		SELECT @tran_id = MAX(tran_id) FROM tdc_put_queue
	END

	-- START v1.1
/*
	-- Get release row id
	SELECT @releases_row_id = MIN(row_id) -- v1.1
	  FROM releases (nolock) 
	 WHERE po_no   = @po_no 
	   AND part_no = @part_no 
	   AND [status]  = 'O'
	   AND po_line = @po_line
	   AND release_date = @rdate

	-- Check if this is ringfenced PO stock
	SET @qty_to_allocate = @qty
	SET @rec_id = 0

	-- Create temp table of backorders
	CREATE TABLE #po_backorders (
		rec_id		INT,
		qty			DECIMAL(20,8),
		bin_no		VARCHAR(10),
		location	VARCHAR(10),
		crossdock	SMALLINT)

	-- Loop through ringfenced table and assign stock if required
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@template_code = template_code,
			@qty_os = qty_ringfenced - qty_received,
			@r_bin_no = bin_no
		FROM 
			dbo.CVO_backorder_processing_orders_po_xref (NOLOCK)
		WHERE
			[status] <= 0
			AND qty_ringfenced > qty_received
			AND rec_id > @rec_id
			AND releases_row_id = @releases_row_id
		ORDER BY
			rec_id


		IF @@ROWCOUNT = 0
			BREAK

		-- Get template details
		SELECT
			@min_crossdock = min_crossdock
		FROM
			dbo.CVO_backorder_processing_templates (NOLOCK)
		WHERE
			template_code = @template_code

		-- Apply stock
		IF @qty_to_allocate > @qty_os 
		BEGIN
			SET @qty_applied = @qty_os
			SET @qty_to_allocate = @qty_to_allocate - @qty_applied
		END
		ELSE
		BEGIN
			SET @qty_applied = @qty_to_allocate
			SET @qty_to_allocate = 0
		END


		-- Write record
		INSERT INTO #po_backorders(
			rec_id,
			qty,
			bin_no,
			location,
			crossdock)
		SELECT
			@rec_id,
			@qty_applied,
			@r_bin_no,
			@location,
			CASE WHEN @qty_os >= ISNULL(@min_crossdock,0) THEN 1 ELSE 0 END
		
		IF @qty_to_allocate <= 0
			BREAK

	END

	IF NOT EXISTS (SELECT 1 FROM #po_backorders) 
	BEGIN
		DROP TABLE #po_backorders
	END
	ELSE
	BEGIN
		-- If there are any POs which need to go to a crossdock bin then get the bin
		IF EXISTS (SELECT 1 FROM #po_backorders WHERE crossdock = 1) 
		BEGIN
			-- Is there already a crossdock bin for this part
			SELECT TOP 1
				@r_bin_no = a.bin_no
			FROM
				dbo.lot_bin_stock a (NOLOCK)
			INNER JOIN
				dbo.tdc_bin_master b (NOLOCK)
			ON
				a.bin_no = b.bin_no
				AND a.location = b.location
			WHERE
				a.location = @location
				AND a.part_no = @part_no
				AND b.group_code = 'CROSSDOCK'
				AND b.status = 'A'

			-- If no bin then get the crossdock bin with the least stock in it
			IF @r_bin_no IS NULL
			BEGIN
				SELECT TOP 1
					@r_bin_no = a.bin_no
				FROM
					dbo.tdc_bin_master a (NOLOCK)
				LEFT JOIN
					(SELECT location, bin_no, SUM(qty) qty FROM dbo.lot_bin_stock (NOLOCK) GROUP BY location, bin_no) b
				ON
					a.bin_no = b.bin_no
					AND a.location = b.location
				WHERE
					a.location = @location
					AND a.group_code = 'CROSSDOCK'
					AND a.status = 'A'
				ORDER BY 
					ISNULL(b.qty,0) 
			END
				
			IF @r_bin_no IS NOT NULL
			BEGIN
				UPDATE
					#po_backorders
				SET
					bin_no = ISNULL(bin_no,@r_bin_no)
				WHERE
					crossdock = 1
			END	
		END
	END
*/
	IF OBJECT_ID('tempdb..#po_backorders') IS NOT NULL
	BEGIN
		
		-- Get qty to crossdock
		SELECT
			@qty_crossdock = SUM(qty),
			@r_bin_no = MIN(bin_no)
		FROM
			#po_backorders
		WHERE
			crossdock = 1

		IF ISNULL(@qty_crossdock,0) > 0
		BEGIN

			-- Get put queue record
			SELECT 
				@r_tran_id = tran_id,
				@qty_received = qty_to_process
			FROM
				dbo.tdc_put_queue (NOLOCK) 
			WHERE 
				part_no = @part_no 
				AND tran_receipt_no = @receipt_no 
				AND trans = 'POPTWY'		

			-- If no put queue record then this must have gone to a non-receipt bin
			IF @r_tran_id IS NULL
			BEGIN
				SET @qty_received = @qty
			END
			
			-- If the full amount is being moved to crossdock then update the put queue record
			IF @qty_crossdock = @qty_received
			BEGIN
				IF @r_tran_id IS NOT NULL
				BEGIN
					UPDATE tdc_put_queue SET next_op = @r_bin_no WHERE tran_id = @r_tran_id
					SET @xd_tran_id = @r_tran_id
				END
				ELSE
				BEGIN
					-- Create a new put queue record
					EXEC dbo.cvo_create_poptwy_transaction_sp @location, @po_no, @receipt_no, @part_no, '1', @bin_no, @r_bin_no, @qty_crossdock, @who, @xd_tran_id OUTPUT
				END

			END
			ELSE
			BEGIN
				-- Split the ringfence qty from the rest
				-- 1. Update existing transaction
				IF @r_tran_id IS NOT NULL
				BEGIN
					UPDATE tdc_put_queue SET qty_to_process = qty_to_process - @qty_crossdock WHERE tran_id = @r_tran_id
				END
				SET @non_xd_tran_id = ISNULL(@r_tran_id,-1)

				-- Create a new put queue record
				EXEC dbo.cvo_create_poptwy_transaction_sp @location, @po_no, @receipt_no, @part_no, '1', @bin_no, @r_bin_no, @qty_crossdock, @who, @xd_tran_id OUTPUT
				
			END			
		END
		ELSE
		BEGIN
			-- Get put queue record
			SELECT 
				@non_xd_tran_id = tran_id
			FROM
				dbo.tdc_put_queue (NOLOCK) 
			WHERE 
				part_no = @part_no 
				AND tran_receipt_no = @receipt_no 
				AND trans = 'POPTWY'
		END

		-- Update cross reference table
		UPDATE
			a
		SET
			qty_ready_to_process = a.qty_ready_to_process + b.qty,
			bin_no = CASE b.crossdock WHEN 1 THEN b.bin_no ELSE NULL END
		FROM
			dbo.CVO_backorder_processing_orders_po_xref a
		INNER JOIN
			#po_backorders b
		ON
			a.rec_id = b.rec_id

		-- Write to tran table
		INSERT INTO dbo.CVO_backorder_processing_orders_po_xref_trans (
			parent_rec_id,
			qty,
			tran_id,
			location,
			orig_bin_no,
			processed)
		SELECT
			rec_id,
			qty,
			CASE crossdock WHEN 1 THEN @xd_tran_id ELSE @non_xd_tran_id END, 
			location,
			CASE ISNULL(@xd_tran_id,@non_xd_tran_id) WHEN -1 THEN @bin_no ELSE NULL END,
			0
		FROM
			#po_backorders
	END

	-- END v1.1

RETURN @tran_id
GO
GRANT EXECUTE ON  [dbo].[tdc_queue_po_putaway_sp] TO [public]
GO
