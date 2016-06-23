SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[cvo_masterpack_pick_consolidated_transaction_sp] (	@tran_id INT,
																	@qty DECIMAL(20,8),
																	@station_id int,  
																	@user_id varchar(50))
AS
BEGIN
	DECLARE @row_id			INT,
			@child_tran_id	INT,
			@qty_to_process	DECIMAL(20,8),
			@qty_to_pick	DECIMAL(20,8),
			@part_no		varchar(30),   
			@bin_no			varchar(20),   
			@lot_ser		varchar(20),   
			@location		varchar(10),   
			@date_exp		datetime,
			@order_no		int,   
			@ext			int,   
			@line_no		int,
			@orig_qty		DECIMAL(20,8),
			@data			varchar(7500),
			@cons_no		int, -- v1.1 
			@consolidation_no int -- v1.2
			
	-- v1.2 Start
	SELECT	@consolidation_no = consolidation_no
	FROM	dbo.cvo_masterpack_consolidation_picks (NOLOCK)
	WHERE	parent_tran_id = @tran_id
	-- v1.2 End

	SET @orig_qty = @qty

	-- Loop through child records and consume stock
	SET @row_id = 0
	WHILE 1=1
	BEGIN
		IF @qty <= 0
			BREAK

		SELECT TOP 1
			@row_id = row_id,
			@child_tran_id = child_tran_id,
			@cons_no = consolidation_no -- v1.1
		FROM
			dbo.cvo_masterpack_consolidation_picks (NOLOCK)
		WHERE
			parent_tran_id = @tran_id
			AND row_id > @row_id
		ORDER BY
			row_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Get the qty_to_process on this record
		SET @qty_to_process = 0
		SELECT
			@qty_to_process = qty_to_process,
			@part_no = part_no,  
			@bin_no = bin_no,  
			@lot_ser = lot,  
			@location = location,
			@order_no = trans_type_no,  
			@ext = trans_type_ext,  
			@line_no = line_no
		FROM
			dbo.tdc_pick_queue (NOLOCK)
		WHERE
			tran_id = @child_tran_id
			AND  ISNULL(assign_user_id,'') = 'HIDDEN'  

		IF ISNULL(@qty_to_process,0) > 0 
		BEGIN
			SET @qty_to_pick = 0

			-- Calculate what to pick for this transaction
			IF @qty_to_process >= @qty
			BEGIN
				SET @qty_to_pick = @qty
				SET @qty = 0
			END
			ELSE
			BEGIN
				SET @qty_to_pick = @qty_to_process
				SET @qty = @qty - @qty_to_pick
			END

			SELECT 
				@date_exp = date_expires  
			FROM 
				dbo.lot_bin_stock (NOLOCK)  
			WHERE 
				part_no = @part_no  
				AND  lot_ser = @lot_ser  
				AND  bin_no = @bin_no  
				AND  location = @location  
  
			-- Working tables  
			IF (SELECT OBJECT_ID('tempdb..#serial_no')) IS NOT NULL   
			BEGIN     
				DROP TABLE #serial_no    
			END  

			CREATE TABLE #serial_no (  
				serial_no varchar(40) not null,   
				serial_raw varchar(40) not null)   

			IF (SELECT OBJECT_ID('tempdb..#adm_pick_ship')) IS NOT NULL   
			BEGIN     
				DROP TABLE #adm_pick_ship    
			END  

			CREATE TABLE #adm_pick_ship (  
				order_no int not null,   
				ext   int not null,   
				line_no  int not null,   
				part_no  varchar(30) not null,   
				tracking_no varchar(30) null,   
				bin_no  varchar(12) null,   
				lot_ser  varchar(25) null,   
				location varchar(10) null,   
				date_exp datetime null,   
				qty   decimal(20,8) not null,   
				err_msg  varchar(255) null,   
				row_id  int identity not null)  

			IF (SELECT OBJECT_ID('tempdb..#pick_custom_kit_order')) IS NOT NULL   
			BEGIN     
				DROP TABLE #pick_custom_kit_order    
			END  

			CREATE TABLE #pick_custom_kit_order(  
				method  varchar(2) not null,  
				order_no int not null,  
				order_ext int not null,  
				line_no  int not null,  
				location varchar(10) not null,  
				item  varchar(30) null,  
				part_no  varchar(30) not null,  
				sub_part_no varchar(30) null,  
				lot_ser  varchar(25) null,  
				bin_no  varchar(12) null,  
				quantity decimal(20,8) not null,  
				who   varchar(50) not null,  
				row_id  int identity not null)  

			-- Populate table with record to process  
			INSERT INTO #adm_pick_ship (order_no, ext, line_no, part_no, bin_no, lot_ser, location, date_exp,   
					qty, err_msg)                 
			VALUES(@order_no, @ext, @line_no, @part_no, @bin_no, @lot_ser, @location, @date_exp,  
					 @qty_to_pick, NULL)  
  
			-- Call Standard routine to pick the queue record  
			EXEC dbo.tdc_queue_xfer_ship_pick_sp @child_tran_id,'','S',@station_id  

			-- Record the action in the transaction log 
			SET @data = 'Consolidated pick for line: ' + CAST(@line_no AS varchar(10))
 
			INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)  
			VALUES (getdate(),@user_id,'CO','QTX','STDPICK',CAST(@order_no AS varchar(16)), CAST(@ext AS varchar(5)), @part_no, @lot_ser, @bin_no, @location, CAST(@qty_to_pick AS varchar(20)), @data)  

			-- If we have picked everything on that line then remove it from the consolidation table
			IF @qty_to_pick = @qty_to_process
			BEGIN
				DELETE FROM dbo.cvo_masterpack_consolidation_picks WHERE row_id = @row_id
			END

			-- v1.2 Start
			IF OBJECT_ID('tempdb..#tmp_autopickcase') IS NOT NULL   
			BEGIN     
				DROP TABLE #tmp_autopickcase    
			END  

			CREATE TABLE #tmp_autopickcase (temp int)
			-- v1.2 End

			-- Process case records
			EXEC cvo_autopick_cases_sp @order_no, @ext, @line_no, @qty_to_pick, @station_id, @user_id 

			-- v1.2 Start
			IF OBJECT_ID('tempdb..#tmp_autopickcase') IS NOT NULL   
			BEGIN     
				DROP TABLE #tmp_autopickcase    
			END  
			-- v1.2 End

			
			-- Rehide the transaction
			UPDATE
				tdc_pick_queue
			SET
				assign_user_id = 'HIDDEN'  
			WHERE
				tran_id = @child_tran_id			

		END
		ELSE
		BEGIN
			-- Pick record is missing or has nothing to process, so remove consolidation record
			DELETE FROM dbo.cvo_masterpack_consolidation_picks WHERE row_id = @row_id
		END

		-- v1.1 Start
		UPDATE	cvo_masterpack_consolidation_hdr
		SET		closed = 1
		WHERE	consolidation_no = @cons_no
		AND		closed = 0
		-- v1.1 End
	END

	SET @orig_qty = @orig_qty - @qty

	-- Update parent pick queue record
	UPDATE 
		dbo.tdc_pick_queue 
	SET 
		qty_to_process = qty_to_process - @orig_qty,
		qty_processed  = ISNULL(qty_processed,0) + @orig_qty,
		tx_lock        = 'R'
	WHERE 
		tran_id = @tran_id 

	-- Delete it if there's nothing left to process
	DELETE FROM dbo.tdc_pick_queue WHERE tran_id = @tran_id  AND qty_to_process <= 0

	-- v1.2 Start
	UPDATE	a
	SET		assign_user_id = 'HIDDEN'
	FROM	tdc_pick_queue a
	JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
	ON		a.trans_type_no = b.order_no
	AND		a.trans_type_ext = b.order_ext
	WHERE	b.consolidation_no = @consolidation_no
	AND		a.trans = 'STDPICK'

	DELETE	a
	FROM	cvo_masterpack_consolidation_picks a
	LEFT JOIN tdc_pick_queue b (NOLOCK)
	ON		a.child_tran_id = b.tran_id
	WHERE	a.consolidation_no = @consolidation_no
	AND		b.tran_id IS NULL

	DELETE	a
	FROM	cvo_masterpack_consolidation_picks a
	LEFT JOIN tdc_pick_queue b (NOLOCK)
	ON		a.parent_tran_id = b.tran_id
	WHERE	a.consolidation_no = @consolidation_no
	AND		b.tran_id IS NULL
	-- v1.2 End
	
END
GO
GRANT EXECUTE ON  [dbo].[cvo_masterpack_pick_consolidated_transaction_sp] TO [public]
GO
