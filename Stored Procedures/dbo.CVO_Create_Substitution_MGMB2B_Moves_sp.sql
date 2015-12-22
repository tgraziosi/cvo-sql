SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].CVO_Create_Substitution_MGMB2B_Moves    Script Date: 12/01/2010  *****
SED009 -- AutoAllocation   
Object:      Procedure  CVO_Create_Substitution_MGMB2B_Moves  
Source file: CVO_Create_Substitution_MGMB2B_Moves.sql
Author:		 Craig Boston
Created:	 12/01/2010
Function:    
Modified:    
Calls:    
Called by:   
Copyright:   Epicor Software 2010.  All rights reserved.  
BEGIN TRAN
EXEC CVO_Create_Substitution_MGMB2B_Moves_sp 1283,0,1,'001','BCALBBROLS130',4
SELECT * FROM tdc_soft_alloc_tbl WHERE part_no = 'BCALBBROLS130'
SELECT * FROM tdc_pick_queue WHERE part_no = 'BCALBBROLS130'
ROLLBACK TRAN
COMMIT TRAN

v1.1 CB 17/10/2012 - Issue #949 - Mark all lines with the tran_id_link of the STDPICK
v1.2 CT 02/05/2013 - Write a tdc_log record to show pick queue transaction has been created
v1.3 CT 04/04/2014 - Issue #1470 - Do select stock from bins marked as "Exclude From Allocation"
*/
CREATE PROCEDURE [dbo].[CVO_Create_Substitution_MGMB2B_Moves_sp]	@order_no int,
																	@order_ext int,
																	@line_no int,
																	@location varchar(10),
																	@part_no varchar(30),
																	@original_part varchar(30),
																	@part_no_original varchar(30),
																	@qty decimal(20,8)
AS

BEGIN
-- Declarations
DECLARE @bin_no			varchar(20),
		@dest_bin_no	varchar(20),
		@tran_id		int,
		@Priority		int,
		@SeqNo			int,
		@Bin2BinGroupId	varchar(25),
		@lot			varchar(25),
		@pick_fence_qty int,
		@qty_remaining	decimal(20,8),
		@last_bin_no	varchar(20),
		@bin_qty		decimal(20,8),
		@tran_id_link	int,
		@B2B_tran_id	int, -- v1.2	
		@UserID			varchar(50), -- v1.2
		@frame_part_no	VARCHAR(30)	-- v1.2


	-- START v1.2
	-- Get user who allocated frame
	SELECT @frame_part_no = part_no FROM dbo.ord_list WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no

	IF ISNULL(@frame_part_no,'') <> ''
	BEGIN
		SELECT TOP 1 
			@UserID = UserId 
		FROM 
			dbo.tdc_log (NOLOCK) 
		WHERE 
			tran_no = CAST(@order_no AS VARCHAR(16)) 
			AND tran_ext = CAST(@order_ext AS VARCHAR(5)) 
			AND part_no = @frame_part_no 
			AND trans_source = 'VB' 
			AND module = 'PLW' 
			AND trans = 'ALLOCATION' 
		ORDER BY 
			tran_date DESC
	END

	IF ISNULL(@UserID,'') = ''
	BEGIN
		SET @userID = SUSER_SNAME()
	END
	-- END v1.2
	

	-- If the frame did not allocate then do not create the frame break records
	IF NOT EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no 
				AND trans_type_ext = @order_ext AND line_no = @line_no AND trans <> 'MGTB2B')
		RETURN


	-- Check for existing MGTB2B queue transaction and remove
	IF EXISTS (SELECT 1 FROM dbo.tdc_pick_queue (NOLOCK) WHERE trans = 'MGTB2B' AND trans_type_no = @order_no 
				AND trans_type_ext = @order_ext AND line_no = @line_no AND part_no = @original_part)
	BEGIN

		-- Get the tran id of the existing MGTB2B queue transaction
		SELECT	@tran_id = tran_id
		FROM	dbo.tdc_pick_queue (NOLOCK)
		WHERE	trans = 'MGTB2B' 
		AND 	trans_type_no = @order_no 
		AND		trans_type_ext = @order_ext
		AND 	line_no = @line_no
		AND 	part_no = @original_part
		
		-- Check if an existing tdc_soft_alloc_tbl record exists and the qty is greater then the qty passed in
		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl a JOIN tdc_pick_queue b ON a.part_no = b.part_no AND a.lot_ser = b.lot        
						AND a.bin_no = b.bin_no AND a.target_bin = b.next_op WHERE a.order_no = 0 AND a.order_ext  = 0            
						AND a.order_type = 'S' AND a.line_no = 0 AND b.tran_id = @tran_id AND a.qty > @qty)
		BEGIN
			-- Reduce the qty on the allocation record
			UPDATE	tdc_soft_alloc_tbl
			SET		qty = qty - @qty
			FROM 	tdc_soft_alloc_tbl a
			JOIN    tdc_pick_queue b          
			ON		a.part_no = b.part_no    
			AND		a.lot_ser = b.lot        
			AND		a.bin_no = b.bin_no     
			AND		a.target_bin = b.next_op 
			WHERE	a.order_no  = 0            
			AND		a.order_ext  = 0            
			AND		a.order_type = 'S'          
			AND		a.line_no    = 0   
			AND		b.tran_id = @tran_id
		
		END
		ELSE
		BEGIN
			-- Delete the allocation record
			DELETE	tdc_soft_alloc_tbl    
			FROM 	tdc_soft_alloc_tbl a
			JOIN    tdc_pick_queue b          
			ON		a.part_no = b.part_no    
			AND		a.lot_ser = b.lot        
			AND		a.bin_no = b.bin_no     
			AND		a.target_bin = b.next_op 
			WHERE	a.order_no  = 0            
			AND		a.order_ext  = 0            
			AND		a.order_type = 'S'          
			AND		a.line_no    = 0   
			AND		b.tran_id = @tran_id  
		END

		-- Delete the MGTB2B queue transaction
		DELETE	tdc_pick_queue
		WHERE	tran_id = @tran_id

	END

-- Add new MGTB2B queue transaction

	-- If the substituted part is the same as the original then do not create the moves
	IF @part_no = @part_no_original
		RETURN

	-- Get the queue priority
	SELECT @priority = ISNULL((SELECT value_str FROM tdc_config (nolock)  
				    WHERE [function] = 'MGT_Pick_Q_Priority' AND active = 'Y'), 0)

	-- if not queue prority then default to 5
	IF @priority = 0
		SET @priority = 5

	-- Get the trans
	SELECT @Bin2BinGroupId = (SELECT group_id FROM tdc_group (NOLOCK) WHERE trans_type = 'MGTB2B')	

	-- Where are we getting the stock from
	SELECT	@pick_fence_qty = ISNULL((SELECT value_str FROM tdc_config (nolock)  
				    WHERE [function] = 'ALLOC_QTY_FENCE' AND active = 'Y'), 0)

	-- Create working table
	IF OBJECT_ID('tempdb..#temp_stock') IS NOT NULL 
		DROP TABLE #temp_stock  

	CREATE TABLE #temp_stock (
		location	varchar(10),
		part_no		varchar(30),
		lot_ser		varchar(25),
		bin_no		varchar(12),
		qty			decimal(20,8))

	IF OBJECT_ID('tempdb..#alloc_stock') IS NOT NULL 
		DROP TABLE #alloc_stock  

	CREATE TABLE #alloc_stock (
		location	varchar(10),
		part_no		varchar(30),
		lot_ser		varchar(25),
		bin_no		varchar(12),
		qty			decimal(20,8))

	-- Get a list of where the stock is available in order of FP, HB, WH
	INSERT	#temp_stock (location, part_no , lot_ser, bin_no, qty)
	SELECT	a.location, 
			a.part_no, 
			a.lot_ser, 
			a.bin_no, 
			a.qty
	FROM	lot_bin_stock a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	WHERE	b.usage_type_code NOT IN ('RECEIPT', 'QUARANTINE', 'PRODIN', 'PRODOUT')
	AND		b.bin_no NOT IN ('CUSTOM')
	-- START v1.3
	AND		ISNULL(b.bm_udef_e,'') <> '1'
	-- END v1.3
	AND		a.location = @location
	AND		a.part_no = @part_no	
	ORDER BY b.group_code DESC

	-- Update the quantities to reduce them by what is already allocated
	INSERT	#alloc_stock (location, part_no , lot_ser, bin_no, qty)
	SELECT	location, 
			part_no, 
			lot_ser, 
			bin_no, 
			SUM(qty)
	FROM	tdc_soft_alloc_tbl (nolock)
	WHERE	location = @location
	AND		part_no = @part_no	
	GROUP BY location, 
			part_no, 
			lot_ser, 
			bin_no

	UPDATE	#temp_stock
	SET		qty = a.qty - b.qty
	FROM	#temp_stock a
	JOIN	#alloc_stock b
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	AND		a.bin_no = b.bin_no
	AND		a.lot_ser = b.lot_ser
	
	-- Remove any records where qty is now zero 
	DELETE	#temp_stock
	WHERE	qty <= 0

	-- If the qty is above the qty fence and stock exists in other bins then remove the pick area bins
	IF @qty > @pick_fence_qty AND EXISTS (SELECT 1 FROM #temp_stock a JOIN tdc_bin_master b (NOLOCK) ON
											a.location = b.location and a.bin_no = b.bin_no 
											WHERE @qty <= ISNULL((SELECT sum(qty) FROM  #temp_stock a
																	JOIN tdc_bin_master b (NOLOCK) ON
																	a.location = b.location 
																	AND a.bin_no = b.bin_no
																	WHERE a.location = @location
																	AND a.part_no = @part_no
																	AND b.group_code NOT IN ('PICKAREA')),0)
											AND	b.group_code NOT IN ('PICKAREA'))
	BEGIN
		DELETE	#temp_stock
		FROM	#temp_stock a
		JOIN	tdc_bin_master b (NOLOCK) 
		ON		a.location = b.location 
		AND		a.bin_no = b.bin_no
		WHERE	a.location = @location
		AND		a.part_no = @part_no
		AND		b.group_code IN ('PICKAREA')	
	END

	-- Get the first bin that can fulfil this requirement in full
	SET	@bin_no = NULL

	SELECT	TOP 1 @bin_no = bin_no, @lot = lot_ser
	FROM	#temp_stock
	WHERE	qty >= @qty

	-- Get the custom bin from the config
	SELECT	@dest_bin_no = ISNULL((SELECT value_str FROM tdc_config (nolock)  
				    WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'UNKNOWN')

	-- If one bin can not satisfy the requirement then loop through the bins other use the first bin
	IF @bin_no IS NOT NULL
	BEGIN
		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl WHERE order_no = 0 AND order_ext = 0 AND order_type = 'S' 
					AND location = @location AND line_no = 0 AND part_no = @part_no 
					AND lot_ser = @lot AND bin_no = @bin_no AND dest_bin = @dest_bin_no )
		BEGIN
			UPDATE tdc_soft_alloc_tbl
			   SET qty = qty + @qty
			 WHERE order_no = 0
			   AND order_ext = 0
			   AND order_type = 'S'
			   AND location = @location
			   AND line_no = 0
			   AND part_no = @part_no
			   AND lot_ser = @lot
			   AND bin_no = @bin_no
			   AND dest_bin = @dest_bin_no
		END
		ELSE
		BEGIN
			INSERT INTO tdc_soft_alloc_tbl
				(order_type, order_no, order_ext, location, line_no, part_no,
				 lot_ser, bin_no, qty, target_bin, dest_bin, q_priority)
			VALUES ('S', 0, 0, @location, 0, @part_no, 
				@lot, @bin_no, @qty, @dest_bin_no, @dest_bin_no, @priority)
		END

		EXEC @SeqNo = tdc_queue_get_next_seq_num 'tdc_pick_queue', @Priority 	
	
		-- v1.1 Start
		SELECT	@tran_id_link = tran_id_link
		FROM	tdc_pick_queue (NOLOCK)
		WHERE	trans_type_no = @order_no
		AND		trans_type_ext = @order_ext
		AND		line_no = @line_no
		AND		tran_id_link IS NOT NULL

		INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,
				location, trans_type_no, trans_type_ext, line_no, part_no, lot,qty_to_process, 
				qty_processed, qty_short,next_op, bin_no, date_time,assign_group, tx_control, tx_lock, tran_id_link)
		VALUES ('MGT', 'MGTB2B', @Priority, @SeqNo, @location,  @order_no,  @order_ext, @line_no, 
			@part_no, @lot, @qty, 0, 0, @dest_bin_no, @bin_no, GETDATE(), @Bin2BinGroupId, 'M', 'R', @tran_id_link) 
		-- v1.1 End

		-- START v1.2
		SET @B2B_tran_id = @@IDENTITY

		-- Create tdc_log record
		INSERT INTO tdc_log(
			tran_date,
			UserID,
			trans_source,
			module,
			trans,
			tran_no,
			tran_ext,
			part_no,
			lot_ser,
			bin_no,
			location,
			quantity,
			data)
		SELECT
			GETDATE(),
			@UserID,
			'VB',
			'PLW',
			'CF MGTB2B CREATED',
			CAST(@order_no AS VARCHAR(16)),
			CAST(@order_ext AS VARCHAR(5)),
			@part_no,
			@lot,
			@bin_no,
			@location,
			@qty,
			'Custom Frame MGTB2B created for line ' + CAST(@line_no AS VARCHAR(5)) + '. Tran_ID = ' + CAST(@B2B_tran_id AS VARCHAR(16))
		-- END v1.2

	END
	ELSE
	BEGIN
		-- We need to consume the qty required from multiple bins
		SET @last_bin_no = ''
		SET @qty_remaining = @qty

		SELECT	TOP 1 @bin_no = bin_no, @bin_qty = qty
		FROM	#temp_stock
		WHERE	bin_no > @last_bin_no
		ORDER BY bin_no

		WHILE @@ROWCOUNT <> 0
		BEGIN

			IF @qty_remaining = 0
				BREAK

			IF @bin_qty > @qty_remaining
				SET @bin_qty = @qty_remaining

			IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl WHERE order_no = 0 AND order_ext = 0 AND order_type = 'S' 
						AND location = @location AND line_no = 0 AND part_no = @part_no 
						AND lot_ser = @lot AND bin_no = @bin_no AND dest_bin = @dest_bin_no )
			BEGIN
				UPDATE tdc_soft_alloc_tbl
				   SET qty = qty + @bin_qty
				 WHERE order_no = 0
				   AND order_ext = 0
				   AND order_type = 'S'
				   AND location = @location
				   AND line_no = 0
				   AND part_no = @part_no
				   AND lot_ser = @lot
				   AND bin_no = @bin_no
				   AND dest_bin = @dest_bin_no
			END
			ELSE
			BEGIN
				INSERT INTO tdc_soft_alloc_tbl
					(order_type, order_no, order_ext, location, line_no, part_no,
					 lot_ser, bin_no, qty, target_bin, dest_bin, q_priority)
				VALUES ('S', 0, 0, @location, 0, @part_no, 
					@lot, @bin_no, @bin_qty, @dest_bin_no, @dest_bin_no, @priority)
			END

			EXEC @SeqNo = tdc_queue_get_next_seq_num 'tdc_pick_queue', @Priority 	
		
			-- v1.1 Start
			SELECT	@tran_id_link = tran_id_link
			FROM	tdc_pick_queue (NOLOCK)
			WHERE	trans_type_no = @order_no
			AND		trans_type_ext = @order_ext
			AND		line_no = @line_no
			AND		tran_id_link IS NOT NULL

			INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,
					location, trans_type_no, trans_type_ext, line_no, part_no, lot,qty_to_process, 
					qty_processed, qty_short,next_op, bin_no, date_time,assign_group, tx_control, tx_lock, tran_id_link)
			VALUES ('MGT', 'MGTB2B', @Priority, @SeqNo, @location,  @order_no,  @order_ext, @line_no, 
				@part_no, @lot, @bin_qty, 0, 0, @dest_bin_no, @bin_no, GETDATE(), @Bin2BinGroupId, 'M', 'R', @tran_id_link) 
		
			-- START v1.2
			SET @B2B_tran_id = @@IDENTITY

			-- Create tdc_log record
			INSERT INTO tdc_log(
				tran_date,
				UserID,
				trans_source,
				module,
				trans,
				tran_no,
				tran_ext,
				part_no,
				lot_ser,
				bin_no,
				location,
				quantity,
				data)
			SELECT
				GETDATE(),
				@UserID,
				'VB',
				'PLW',
				'CF MGTB2B CREATED',
				CAST(@order_no AS VARCHAR(16)),
				CAST(@order_ext AS VARCHAR(5)),
				@part_no,
				@lot,
				@bin_no,
				@location,
				@bin_qty,
				'Custom Frame MGTB2B created for line ' + CAST(@line_no AS VARCHAR(5)) + '. Tran_ID = ' + CAST(@B2B_tran_id AS VARCHAR(16))
			-- END v1.2

			SET @qty_remaining = @bin_qty
			SET @last_bin_no = @bin_no

			SELECT	TOP 1 @bin_no = bin_no,  @bin_qty = qty
			FROM	#temp_stock
			WHERE	bin_no > @last_bin_no
			ORDER BY bin_no
		END

	END
		
END
-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_Create_Substitution_MGMB2B_Moves_sp] TO [public]
GO
