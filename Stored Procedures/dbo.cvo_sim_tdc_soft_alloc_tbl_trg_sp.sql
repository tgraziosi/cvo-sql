SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_sim_tdc_soft_alloc_tbl_trg_sp] @action varchar(6),
												  @upd_target1 varchar(20) = '',
												  @upd_target2 varchar(20) = ''
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @con_no  int,    
			@tran_id  int,     
			@seq_no  int,    
			@trans   varchar(10),     
			@order_no  int,     
			@order_ext  int,     
			@priority int,    
			@order_type  char(1),     
			@location  varchar(10),    
			@part_no  varchar(30),    
			@line_no  int,    
			@qty   decimal(20,8),    
			@lot_ser  varchar(25),     
			@bin_no  varchar(12),     
			@target_bin  varchar(12),     
			@dest_bin  varchar(12),     
			@assigned_user  varchar(50),     
			@assigned_group varchar(50),     
			@alloc_type  varchar(2),    
			@tx_lock char(1),    
			@user_hold char(1),    
			@status  char(1), 
			@bin_to_bin_group varchar(25),
			@row_id   int,  
			@last_row_id int,
			@user_code VARCHAR(8),
			@wo_seq_no  VARCHAR(20),    
			@lot    VARCHAR(25),    
			@pass_bin   VARCHAR(12),     
			@ConNo    INT,     
			@update_q_flg   BIT,     
			@del_target_bin  VARCHAR(12),             
			@del_qty   DECIMAL(24,8),     
			@upd_target_bin  VARCHAR(12),     
			@upd_qty   DECIMAL(24,8),     
			@qty_upd_minus_del  DECIMAL(24,8),     
			@qty_to_process  DECIMAL(24,8),    
			@qty_processed  DECIMAL(24,8)
    
	IF (@action = 'INSERT')
	BEGIN
 
		CREATE TABLE #inserted_cursor (  
			row_id   int IDENTITY(1,1),  
			order_no  int NULL,  
			order_ext  int NULL,  
			location  varchar(10) NULL,  
			part_no   varchar(30) NULL,  
			line_no   int,  
			lot_ser   varchar(25) NULL,  
			bin_no   varchar(12),  
			qty    decimal(20,8) NULL,  
			target_bin  varchar(12) NULL,  
			dest_bin  varchar(12) NULL,  
			alloc_type  char(2) NULL,  
			tx_lock   char(1) NULL,  
			order_type  char(1) NULL,  
			trans   varchar(10) NULL,  
			assigned_user varchar(50) NULL,  
			user_hold  char(1) NULL,  
			q_priority  int NULL)  
  
   
		INSERT #inserted_cursor (order_no, order_ext, location, part_no, line_no, lot_ser, bin_no, qty, target_bin, dest_bin, alloc_type,   
			tx_lock, order_type, trans, assigned_user, user_hold, q_priority)  
		SELECT	order_no, order_ext, location, part_no, line_no, lot_ser, bin_no, qty, target_bin, dest_bin, alloc_type,     
				tx_lock =  CASE  WHEN alloc_type = 'HO' THEN 'H'    
					WHEN alloc_type = 'PT' THEN 'R'    
					WHEN alloc_type = 'PR' then 'P'    
					WHEN alloc_type = 'PP' then '3'    
					WHEN alloc_type = 'PB' then 'G'    
					ELSE 'R' END,    
				order_type,    
				CASE order_type WHEN 'S' THEN 'STDPICK'     
					WHEN 'T' THEN 'XFERPICK'     
					WHEN 'W' THEN 'WOPPICK' END,    
				assigned_user,    
				user_hold,    
				q_priority    
		FROM #inserted    
		WHERE bin_no != 'CDOCK' OR ISNULL(bin_no, '') = ''    
      
		SET @last_row_id = 0  
	  
		SELECT	TOP 1 @row_id = row_id,  
				@order_no = order_no,     
				@order_ext = order_ext,   
				@location = location,     
				@part_no = part_no,   
				@line_no = line_no,      
				@lot_ser = lot_ser,   
				@bin_no = bin_no,          
				@qty = qty,     
				@target_bin = target_bin,   
				@dest_bin = dest_bin,    
				@alloc_type = alloc_type,   
				@tx_lock = tx_lock,   
				@order_type = order_type,   
				@trans = trans,     
				@assigned_user = assigned_user,   
				@user_hold = user_hold,   
				@priority = q_priority  
		FROM	#inserted_cursor  
		WHERE	row_id > @last_row_id  
		ORDER BY row_id ASC  
  
		WHILE (@@ROWCOUNT <> 0)  
		BEGIN    
			IF @order_no = 0    
			BEGIN    
				SET @last_row_id = @row_id  
	  
				SELECT	TOP 1 @row_id = row_id,  
						@order_no = order_no,     
						@order_ext = order_ext,   
						@location = location,     
						@part_no = part_no,   
						@line_no = line_no,      
						@lot_ser = lot_ser,   
						@bin_no = bin_no,          
						@qty = qty,     
						@target_bin = target_bin,   
						@dest_bin = dest_bin,    
						@alloc_type = alloc_type,   
						@tx_lock = tx_lock,   
						@order_type = order_type,   
						@trans = trans,     
						@assigned_user = assigned_user,   
						@user_hold = user_hold,   
						@priority = q_priority  
				FROM	#inserted_cursor  
				WHERE	row_id > @last_row_id  
				ORDER BY row_id ASC  
	  
				CONTINUE    
			END          
			--------------------------------------------------------------    
			-- Change the trans for package builder    
			--------------------------------------------------------------    
			If @alloc_type = 'PB' SET @trans = 'PKGBLD'    
	    
			--------------------------------------------------------------    
			-- If user hold, store the alloc_type, but change the tx_lock    
			--------------------------------------------------------------    
			If @user_hold = 'Y' SET @tx_lock = 'H'      
			--SCR#38203 Modified By Jim On 10/11/07   
	    
			SELECT @status = status FROM orders (nolock) WHERE order_no = @order_no AND ext = @order_ext    
	    
			IF (@status < 'N') SET @tx_lock = 'E'    

			SELECT	@user_code = ISNULL(user_stat_code,'')   
			FROM	so_usrstat (NOLOCK)
			WHERE	default_flag = 1   
			AND		status_code = 'A'  
	  
			IF (@status = 'A') AND EXISTS(SELECT * FROM  orders (NOLOCK) WHERE order_no = @order_no AND   
										ext = @order_ext  AND user_code = @user_code AND   
										hold_reason IN (SELECT hold_code FROM CVO_alloc_hold_values_tbl (NOLOCK)))  
			BEGIN  
				SET @tx_lock = 'R'  
			END  
			----------------------------------------    
			-- Assign a group/user to a transaction    
			----------------------------------------    
			IF @assigned_user = '' OR @assigned_user like '%DEFAULT%' SET @assigned_user = NULL    
			SELECT @assigned_group = group_id FROM tdc_group (NOLOCK) WHERE trans_type = @trans    
	     
			----------------------------------------------------------    
			--   For NON LOT/BIN tracked parts   --    
			----------------------------------------------------------    
			IF (@bin_no IS NULL AND @lot_ser IS NULL)    
			BEGIN    
				-- Generate next seq_no     
				SELECT @seq_no = MAX(seq_no) + 1 FROM #sim_tdc_pick_queue
	    
				IF (@seq_no = 0)     
				BEGIN    
					RETURN    
				END    
	      
				INSERT INTO #sim_tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no, lot, qty_to_process,     
					qty_processed, qty_short, bin_no, date_time, assign_group, assign_user_id,  tx_control, tx_lock, next_op)    
				VALUES ('PLW', @trans, @priority, @seq_no, @location, @order_no, @order_ext, @line_no, @part_no, NULL,    
					@qty, 0, 0, @target_bin, GETDATE(), @assigned_group, @assigned_user, 'M', @tx_lock, @dest_bin)    
	    
				IF @@ERROR <> 0     
				BEGIN    
					RETURN    
				END    
			END -- NON LOT/BIN Tracked items    
			ELSE    
			BEGIN    
				----------------------------------------------------------    
				--   For LOT/BIN tracked parts   --    
				----------------------------------------------------------    
				-- Check if there is a record for this order/location/part/line    
				IF ( @target_bin IS NOT NULL AND @bin_no = @target_bin )    
				BEGIN       
					-- Generate next seq_no     
					SELECT @seq_no = MAX(seq_no) + 1 FROM #sim_tdc_pick_queue
	    
					IF (@seq_no = 0)     
					BEGIN    
						RETURN    
					END         
	    
					INSERT INTO #sim_tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no, lot, qty_to_process,     
						qty_processed, qty_short, bin_no, date_time, assign_group, assign_user_id, tx_control, tx_lock, next_op)    
					VALUES ('PLW', @trans, @priority, @seq_no, @location, @order_no, @order_ext, @line_no, @part_no, @lot_ser,    
						@qty, 0, 0, @target_bin, GETDATE(), @assigned_group, @assigned_user, 'M', @tx_lock, @dest_bin)    
	    
					IF @@ERROR <> 0     
					BEGIN    
						RETURN    
					END    
				END  -- IF ( @target_bin IS NOT NULL AND @bin_no = @target_bin )    
				ELSE IF (@target_bin IS NOT NULL AND @bin_no <> @target_bin )    
				BEGIN    
					--Get the bin to bin groupid    
					SELECT	@bin_to_bin_group = (SELECT group_id     
					FROM	tdc_group (NOLOCK)     
					WHERE	trans_type = 'PLWB2B')     
	    
					SELECT	@con_no   = consolidation_no     
					FROM	#sim_tdc_cons_ords (NOLOCK)    
					WHERE	order_no  = @order_no    
					AND		order_ext = @order_ext     
					AND		location  = @location    
	    
					--Get the next seq no    
					SELECT @seq_no = MAX(seq_no) + 1 FROM #sim_tdc_pick_queue
	    
					IF @seq_no = 0     
					BEGIN    
						RETURN    
					END    
	    
					IF NOT EXISTS(SELECT * FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans_type_no  = @con_no AND trans_type_ext = 0    
						AND trans_source   = 'PLW' AND trans      = 'PLWB2B' AND part_no      = @part_no AND lot      = @lot_ser    
						AND bin_no      = @bin_no AND next_op        = @target_bin)    
					BEGIN     
						--Insert the record    
						INSERT INTO #sim_tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no, lot,qty_to_process,     
							qty_processed, qty_short,next_op, bin_no, date_time, assign_group, assign_user_id, tx_control, tx_lock)    
						VALUES ('PLW', 'PLWB2B', @priority, @seq_no, @location, @con_no, 0, 0,     
							@part_no, @lot_ser, @qty, 0, 0, @target_bin, @bin_no, GETDATE(), @bin_to_bin_group, NULL, 'M', @tx_lock)     
					END    
					ELSE    
					BEGIN    
						UPDATE	#sim_tdc_pick_queue      
						SET		qty_to_process = qty_to_process + @qty    
						WHERE	trans_type_no  = @con_no    
						AND		trans_type_ext = 0    
						AND		trans_source = 'PLW'    
						AND		trans = 'PLWB2B'    
						AND		part_no = @part_no    
						AND		lot = @lot_ser    
						AND		bin_no = @bin_no    
						AND		next_op = @target_bin    
					END    
	    
					IF @@ERROR <> 0     
					BEGIN    
						RETURN    
					END    
				END    
			END     -- NON LOT/BIN Tracked items    
	  
			SET @last_row_id = @row_id  
	  
			SELECT	TOP 1 @row_id = row_id,  
					@order_no = order_no,     
					@order_ext = order_ext,   
					@location = location,     
					@part_no = part_no,   
					@line_no = line_no,      
					@lot_ser = lot_ser,   
					@bin_no = bin_no,          
					@qty = qty,     
					@target_bin = target_bin,   
					@dest_bin = dest_bin,    
					@alloc_type = alloc_type,   
					@tx_lock = tx_lock,   
					@order_type = order_type,   
					@trans = trans,     
					@assigned_user = assigned_user,   
					@user_hold = user_hold,   
					@priority = q_priority  
			FROM	#inserted_cursor  
			WHERE	row_id > @last_row_id  
			ORDER BY row_id ASC       
		END    
        
		RETURN
	END

	IF (@action = 'UPDATE')
	BEGIN
         
		IF (@upd_target1 <> 'target_bin' AND @upd_target2 <> 'qty')    
			RETURN 
              
		SELECT @qty_to_process = 0, @qty_processed = 0    
   
		CREATE TABLE #upd_soft_alloc_cur (  
			row_id   int IDENTITY(1,1),  
			order_no  int,  
			order_ext  int,  
			order_type  char(1) NULL,  
			location  varchar(10) NULL,  
			line_no   int,  
			part_no   varchar(30) NULL,  
			lot_ser   varchar(25) NULL,  
			bin_no   varchar(12) NULL,  
			target_bin  varchar(12) NULL,  
			dest_bin  varchar(12) NULL,  
			qty    decimal(20,8) NULL,  
			trg_off   bit NULL,  
			alloc_type  char(2) NULL,  
			tx_lock   char(1) NULL,  
			trans   varchar(10) NULL,  
			assigned_user varchar(50) NULL,  
			user_hold  char(1) NULL,  
			q_priority  int NULL)  
  
		INSERT #upd_soft_alloc_cur (order_no, order_ext, order_type, location, line_no, part_no, lot_ser, bin_no, target_bin, dest_bin,  
			qty, trg_off, alloc_type, tx_lock, trans, assigned_user, user_hold, q_priority)  
		SELECT	order_no, order_ext, order_type, location,   line_no,     
				part_no,  lot_ser,   bin_no,     target_bin, dest_bin,     
				qty,      trg_off,   alloc_type,    
				TxLock = CASE WHEN alloc_type = 'HO' THEN 'H'     
					WHEN alloc_type = 'PT' THEN 'R'    
					WHEN alloc_type = 'PR' THEN 'P'     
					WHEN alloc_type = 'PP' THEN '3'    
					WHEN alloc_type = 'PB' THEN 'G'    
					ELSE 'R' END,    
				trans = CASE WHEN order_type = 'S'  THEN 'STDPICK'    
					WHEN order_type = 'T'  THEN 'XFERPICK'    
					WHEN order_type = 'W'  THEN 'WOPPICK' END,    
				assigned_user,    
				user_hold,    
				q_priority    
		FROM	#inserted     
		WHERE bin_no != 'CDOCK' OR bin_no IS NULL     
           
		SET @last_row_id = 0  
  
		SELECT	TOP 1 @row_id = row_id,  
				@order_no = order_no,    
				@order_ext = order_ext,   
				@order_type = order_type,     
				@location = location,    
				@line_no = line_no,    
				@part_no = part_no,   
				@lot = lot_ser,             
				@bin_no = bin_no,      
				@upd_target_bin = target_bin,     
				@pass_bin = dest_bin,    
				@upd_qty = qty,     
				@update_q_flg = trg_off,   
				@alloc_type = alloc_type,   
				@tx_lock = tx_lock,    
				@trans = trans,     
				@assigned_user = assigned_user,   
				@user_hold = user_hold,   
				@priority = q_priority  
		FROM	#upd_soft_alloc_cur  
		WHERE	row_id > @last_row_id  
		ORDER BY row_id ASC  
    
		WHILE (@@ROWCOUNT <> 0)  
		BEGIN    
			/*******************************************************************************************************    
			Initialize the variables    
			********************************************************************************************************/    
			SELECT @tran_id = 0    
			SELECT @seq_no = 0    
			--------------------------------------------------------------    
			-- Change the trans for package builder    
			--------------------------------------------------------------    
			If @alloc_type = 'PB' SET @trans = 'PKGBLD'    
    
			--------------------------------------------------------------    
			-- If user hold, store the alloc_type, but change the tx_lock    
			--------------------------------------------------------------    
			If @user_hold = 'Y' SET @tx_lock = 'H'    
    
			----------------------------------------    
			-- Assign a group/user to a transaction    
			----------------------------------------    
			IF @assigned_user = '' OR @assigned_user like '%DEFAULT%' SET @assigned_user = NULL    
			SELECT @assigned_group = group_id FROM tdc_group (NOLOCK) WHERE trans_type = @trans    
     
			--Get the deleted values     
			SELECT	@del_target_bin  = target_bin,      
					@del_qty  = qty        
			FROM	#deleted     
			WHERE	order_no  = @order_no     
			AND		order_ext  = @order_ext     
			AND		order_type = @order_type    
			AND		location  = @location    
			AND		line_no   = @line_no     
			AND		part_no   = @part_no    
			AND		((lot_ser = @lot  AND bin_no = @bin_no)    
			OR		(lot_ser IS NULL AND bin_no IS NULL))    
        
			--Get the consolidation Number we are working with    
			SELECT @ConNo = 0    
			SELECT	@ConNo = consolidation_no     
			FROM	#sim_tdc_cons_ords(NOLOCK)    
			WHERE	order_no   = @order_no     
			AND		order_ext  = @order_ext     
			AND		location   = @location     
			AND		order_type = @order_type    
    
			-------------------------------------------------------------------------------------------------------------------    
			--Lot bin tracked part    
			-------------------------------------------------------------------------------------------------------------------    
			IF (@lot IS NOT NULL AND @bin_no IS NOT NULL)     
			BEGIN     
				/*******************************************************************************************************    
				If updating the queue with stop trigger bit on     
				In this case, update target bin and pass bin and exit.    
				********************************************************************************************************/    
				IF @update_q_flg = 1     
				BEGIN          
					--' We need to update the record on the Queue and set there target bin and PASS bin     
					--'Get the tran Id and Seq_no of the record in the queue     
					UPDATE	#sim_tdc_pick_queue     
					SET		next_op = @upd_target_bin,    
							priority = @priority,    
							assign_user_id = @assigned_user    
					WHERE	trans_type_no = @ConNo    
					AND		trans_type_ext = 0    
					AND		location = @location    
					AND		line_no = @line_no    
					AND		part_no = @part_no    
					AND		lot = @lot    
					AND		bin_no = @bin_no    
					AND		next_op = @del_target_bin           
        
					IF @@ERROR <> 0     
					BEGIN      
						RETURN    
					END    
     
					RETURN    
				END -- update_q_flg = 1     
     
				/*******************************************************************************************************    
				If updating target bin but not quantity and need a bin to bin move    
				********************************************************************************************************/    
				IF (@upd_target1 = 'target_bin' AND @upd_target2 <> 'qty' AND @bin_no <> @upd_target_bin)
				BEGIN
					IF EXISTS(SELECT * FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans = 'PLWB2B' AND trans_type_no  = @ConNo     
						AND trans_type_ext = 0 AND location = @location AND part_no = @part_no AND lot = @lot     
						AND bin_no = @bin_no AND trans_source = 'PLW' AND next_op = @upd_target_bin )           
					BEGIN    
						SELECT	@tran_id = tran_id,    
								@seq_no = seq_no     
						FROM	#sim_tdc_pick_queue (NOLOCK)    
						WHERE	trans = 'PLWB2B'    
						AND		trans_type_no = @ConNo     
						AND		trans_type_ext = 0           
						AND		location = @location     
						AND		part_no = @part_no     
						AND		lot = @lot     
						AND		bin_no = @bin_no     
						AND		trans_source = 'PLW'     
						AND		next_op = @upd_target_bin     

						UPDATE	#sim_tdc_pick_queue     
						SET		next_op = @upd_target_bin,     
								qty_to_process = qty_to_process + @upd_qty,    
								tx_lock = @tx_lock,    
								priority = @priority,    
								assign_user_id = @assigned_user    
						WHERE	tran_id = @tran_id     
       
					    IF @@ERROR <> 0     
						BEGIN    
							RETURN    
						END    
     
						DELETE	#sim_tdc_pick_queue    
						WHERE	tran_id = @tran_id    
						AND		qty_to_process <= 0    
     
						IF @@ERROR <> 0     
						BEGIN    
							RETURN    
						END    
					END --Record exists    
					ELSE    
					BEGIN --Does not exist, insert the record    
      
						--Get the bin to bin groupid    
						SELECT @bin_to_bin_group = (SELECT group_id FROM tdc_group (NOLOCK) WHERE trans_type = 'PLWB2B')     
         
						--Get the next seq no    
						SELECT @seq_no = MAX(seq_no) + 1 FROM #sim_tdc_pick_queue
      
						IF @seq_no = 0     
						BEGIN    
							RETURN    
						END    
     
						--Insert the record    
						INSERT INTO #sim_tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no,     
							lot,qty_to_process, qty_processed, qty_short,next_op, bin_no, date_time, assign_group, tx_control, tx_lock)    
						VALUES ('PLW', 'PLWB2B', @priority, @seq_no, @location, @ConNo, 0, 0,     
							@part_no, @lot, @upd_qty, 0, 0, @upd_target_bin, @bin_no, GETDATE(), @bin_to_bin_group, 'M', @tx_lock)     
     
						IF @@ERROR <> 0     
						BEGIN    
							RETURN    
						END    
					END --Record does not exist          
				END -- (UPDATE(target_bin) AND NOT UPDATE(Qty) AND @bin_no <> @upd_target_bin)    
         
				/*******************************************************************************************************    
				If updating target bin but not quantity and not needing a bin to bin move     
				********************************************************************************************************/    
				IF (@upd_target1 = 'target_bin' AND @upd_target2 <> 'qty' AND @bin_no = @upd_target_bin AND @upd_qty > 0)    
				BEGIN    
     
					--Check to see if the record exists.      
					--If so, get the tran_id and seq_no    
					IF EXISTS(SELECT * FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans   = @trans AND trans_type_no  = @order_no AND trans_type_ext = @order_ext           
						AND location = @location AND part_no  = @part_no AND lot = @lot AND bin_no  = @bin_no AND line_no  = @line_no AND trans_source  = 'PLW')     
					BEGIN         
						SELECT	@tran_id  = tran_id,    
								@seq_no   = seq_no    
						FROM	#sim_tdc_pick_queue (NOLOCK)    
						WHERE	trans   = @trans     
						AND		trans_type_no  = @order_no     
						AND		trans_type_ext  = @order_ext           
						AND		location  = @location     
						AND		part_no   = @part_no     
						AND		lot   = @lot      
						AND		bin_no   = @bin_no      
						AND		line_no   = @line_no   
						AND		trans_source  = 'PLW'     
     
						--'Update the existing transaction just add the qty's     
						UPDATE	#sim_tdc_pick_queue     
						SET		qty_to_process = qty_to_process - @del_qty + @upd_qty,    
								tx_lock       = @tx_lock,    
								priority       = @priority,    
								assign_user_id = @assigned_user    
						WHERE	tran_id        = @tran_id      
       
						IF @@ERROR <> 0     
						BEGIN    
							RETURN     
						END     
      
						DELETE	#sim_tdc_pick_queue    
						WHERE	tran_id = @tran_id    
						AND		qty_to_process <= 0    
      
						IF @@ERROR <> 0     
						BEGIN    
							RETURN    
						END          
					END     
					ELSE    
					BEGIN --Record does not exist       
						--Get the seq no    
						SELECT @seq_no = MAX(seq_no) + 1 FROM #sim_tdc_pick_queue
      
						IF @seq_no = 0     
						BEGIN    
							RETURN    
						END    
       
						INSERT INTO #sim_tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no,     
							part_no,lot, qty_to_process,  qty_processed, qty_short, bin_no, date_time, assign_group, assign_user_id,    
							tx_control, tx_lock, next_op )    
						VALUES ('PLW', @trans, @priority, @seq_no, @location, @order_no, @order_ext, @line_no, @part_no, @lot, @upd_qty,     
							0, 0, @upd_target_bin, GETDATE(), @assigned_group, @assigned_user, 'M', @tx_lock, @pass_bin )    
     
						IF @@ERROR <> 0     
						BEGIN    
							RETURN    
						END        
					END      
				END --(UPDATE(target_bin) AND NOT UPDATE(Qty) AND @bin_no = @upd_target_bin)    
       
				/*******************************************************************************************************    
				If not updating target bin and updating quantity and not needing a bin to bin move     
				********************************************************************************************************/ 
				IF (@upd_target1 <> 'target_bin' AND @upd_target2 = 'qty' AND @bin_no = @upd_target_bin)
				BEGIN    
					--Test to see if the record exists    
					--If so, get the tran_id and seq_no          
     
					IF EXISTS(SELECT * FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans = @trans AND trans_type_no = @order_no AND trans_type_ext = @order_ext AND location = @location     
						AND part_no = @part_no AND lot = @lot AND bin_no = @bin_no AND line_no = @line_no AND trans_source = 'PLW' )              
					BEGIN --Record exists    
						-- If stop update queue flag is ON,     
						IF ((@update_q_flg IS NULL) OR (@update_q_flg != 1)) --SCR 38010 Jim 8/16/07 : disable tdc_upd_softalloc_tg    
						BEGIN    
							SELECT	@tran_id = tran_id,    
									@qty_to_process = qty_to_process,    
									@qty_processed  = qty_processed          
							FROM	#sim_tdc_pick_queue (NOLOCK)    
							WHERE	trans = @trans     
							AND		trans_type_no       = @order_no     
							AND		trans_type_ext      = @order_ext      
							AND		location       = @location     
							AND		part_no        = @part_no     
							AND		lot            = @lot     
							AND		bin_no         = @bin_no     
							AND		line_no        = @line_no    
							AND		trans_source   = 'PLW'     
      
							IF (@qty_to_process > (@qty_to_process + @upd_qty - @del_qty))    
								SELECT @qty_processed = @qty_processed + @del_qty - @upd_qty    
							ELSE   
								SELECT @qty_processed = 0    
      
							UPDATE	#sim_tdc_pick_queue     
							SET		qty_to_process = qty_to_process + ( @upd_qty - @del_qty ),    
									qty_processed  = @qty_processed,    
									tx_lock        = @tx_lock,    
									priority       = @priority,    
									assign_user_id = @assigned_user    
							WHERE	tran_id        = @tran_id     
         
							IF @@ERROR <> 0     
							BEGIN    
								RETURN    
							END    
						END    
     
						DELETE	#sim_tdc_pick_queue    
						WHERE	tran_id = @tran_id    
						AND		qty_to_process <= 0    
     
						IF @@ERROR <> 0     
						BEGIN    
							RETURN    
						END    
					END     
					ELSE    
					BEGIN --Record does not exist    
     
						SELECT @seq_no = MAX(seq_no) + 1 FROM #sim_tdc_pick_queue
      
						IF @seq_no = 0     
						BEGIN    
							RETURN    
						END    
        
						INSERT INTO #sim_tdc_pick_queue (trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no,    
							lot, qty_to_process, qty_processed, qty_short, bin_no, date_time, assign_group, assign_user_id, tx_control, tx_lock, next_op)    
						VALUES ('PLW', @trans, @priority, @seq_no, @location, @order_no, @order_ext, @line_no, @part_no, @lot,     
							( @upd_qty - @del_qty ), 0, 0, @bin_no, GETDATE(), @assigned_group, @assigned_group, 'M', @tx_lock, @pass_bin )    
      
						IF @@ERROR <> 0     
						BEGIN    
							RETURN    
						END        
					END --Record does not exist          
				END     
      
				/*******************************************************************************************************    
				If not updating target bin and updating quantity and needing a bin to bin move for cons no    
				********************************************************************************************************/    
				IF (@upd_target1 <> 'target_bin' AND @upd_target2 = 'qty' AND @bin_no <> @upd_target_bin AND @order_no = 0)    
				BEGIN    
					SELECT @qty_upd_minus_del = @upd_qty - @del_qty    
        
					IF ( @qty_upd_minus_del < 0 )    
					BEGIN     
						RETURN    
					END     
					--Test to see if the record exists    
					--If so, get the tran_id and seq_no    
					SELECT	@tran_id        = tran_id,     
							@qty_to_process = qty_to_process,     
							@qty_processed  = qty_processed    
					FROM	#sim_tdc_pick_queue (NOLOCK)    
					WHERE	trans          = 'MGTB2B'     
					AND		trans_type_no  = @order_no     
					AND		trans_type_ext = @order_ext      
					AND		location       = @location     
					AND		part_no        = @part_no     
					AND		lot            = @lot     
					AND		bin_no         = @bin_no    
					AND		next_op        = @upd_target_bin    
					AND		line_no        = @line_no    
					AND		trans_source   = 'MGT'     
    
					IF @tran_id IS NOT NULL    
					BEGIN    
						IF (@qty_to_process > (@qty_to_process + @upd_qty - @del_qty))    
							SELECT @qty_processed = @qty_processed + @del_qty - @upd_qty    
						ELSE    
							SELECT @qty_processed = 0    
    
						UPDATE	#sim_tdc_pick_queue     
						SET		qty_to_process =  qty_to_process + (@upd_qty - @del_qty),    
								qty_processed  = @qty_processed,    
								tx_lock = @tx_lock,    
								priority       = @priority,    
								assign_user_id = @assigned_user    
						WHERE	tran_id        = @tran_id    
    
						IF @@ERROR <> 0     
						BEGIN    
							RETURN    
						END    
    
						DELETE	#sim_tdc_pick_queue    
						WHERE	tran_id = @tran_id    
						AND		qty_to_process <= 0    
    
						IF @@ERROR <> 0     
						BEGIN    
							RETURN    
						END    
					END     
					ELSE    
					BEGIN    
						RETURN    
					END    
				END --(NOT UPDATE(target_bin) AND UPDATE(Qty) AND @bin_no <> @upd_target_bin AND @order_no = 0)    
			END --LB Tracked    
			ELSE    
			-------------------------------------------------------------------------------------------------------------------    
			--Non lot bin tracked part    
			-------------------------------------------------------------------------------------------------------------------    
			BEGIN    
				-- If stop update queue flag is ON,     
				IF @update_q_flg = 1 RETURN    
    
				--Test to see if the record exists    
				--If so, get the tran_id and seq_no     
				IF EXISTS(SELECT * FROM #sim_tdc_pick_queue (NOLOCK) WHERE trans = @trans AND trans_type_no = @order_no AND trans_type_ext = @order_ext     
					AND location = @location AND part_no = @part_no AND tx_lock != 'H' AND line_no = @line_no AND trans_source   = 'PLW' )             
				BEGIN    
					SELECT	@tran_id = tran_id,   
							@qty_to_process = qty_to_process,   
							@qty_processed = qty_processed    
					FROM	#sim_tdc_pick_queue (NOLOCK)    
					WHERE	trans        = @trans     
					AND		trans_type_no  = @order_no     
					AND		trans_type_ext = @order_ext     
					AND		location       = @location     
					AND		part_no        = @part_no     
					AND		tx_lock       != 'H'     
					AND		line_no        = @line_no     
					AND		trans_source   = 'PLW'       
    
					IF (@qty_to_process > (@qty_to_process + @upd_qty - @del_qty))    
						SELECT @qty_processed = @qty_processed + @del_qty - @upd_qty    
					ELSE    
						SELECT @qty_processed = 0    
    
					UPDATE	#sim_tdc_pick_queue     
					SET		qty_to_process =  qty_to_process + (@upd_qty - @del_qty),    
							qty_processed  = @qty_processed,    
							tx_lock        = @tx_lock,    
							priority       = @priority,    
							assign_user_id = @assigned_user    
					WHERE	tran_id = @tran_id     
    
					IF @@ERROR <> 0     
					BEGIN    
						RETURN    
					END    
    
					DELETE	#sim_tdc_pick_queue    
					WHERE	tran_id = @tran_id    
					AND		qty_to_process <= 0    
    
					IF @@ERROR <> 0     
					BEGIN    
						RETURN    
					END    
				END    
				ELSE --Record does not exist    
				BEGIN    
					-- Generate next seq_no      
					SELECT @seq_no = MAX(seq_no) + 1 FROM #sim_tdc_pick_queue
    
					IF (@seq_no = 0)     
					BEGIN    
						RETURN    
					END    
       
					INSERT INTO #sim_tdc_pick_queue     
						(trans_source, trans, priority, seq_no, location, trans_type_no, trans_type_ext, line_no, part_no, lot,     
						qty_to_process, qty_processed, qty_short, bin_no, date_time, assign_group, tx_control, tx_lock, next_op)    
					VALUES ('PLW', @trans, @priority, @seq_no, @location, @order_no, @order_ext, @line_no, @part_no, NULL,    
						@upd_qty, 0, 0, @upd_target_bin, GETDATE(), @assigned_group, 'M', @tx_lock, @pass_bin )    
    
					IF @@ERROR <> 0     
					BEGIN    
						RETURN    
					END    
				END --record does not exist    
			END --Non lb tracked part    
    
			DELETE	FROM #sim_tdc_soft_alloc_tbl    
			WHERE	order_no = @order_no    
			AND		order_ext = @order_ext    
			AND		order_type = @order_type    
			AND		location = @location    
			AND		line_no = @line_No    
			AND		ISNULL(lot_ser, '') = ISNULL(@lot, '')    
			AND		ISNULL(bin_no, '') = ISNULL(@bin_no, '')    
			AND		part_no = @part_no    
			AND		qty <= 0    
    
			SET @last_row_id = @row_id  
  
			SELECT	TOP 1 @row_id = row_id,  
					@order_no = order_no,    
					@order_ext = order_ext,   
					@order_type = order_type,     
					@location = location,    
					@line_no = line_no,    
					@part_no = part_no,   
					@lot = lot_ser,             
					@bin_no = bin_no,      
					@upd_target_bin = target_bin,     
					@pass_bin = dest_bin,    
					@upd_qty = qty,     
					@update_q_flg = trg_off,   
					@alloc_type = alloc_type,   
					@tx_lock = tx_lock,    
					@trans = trans,     
					@assigned_user = assigned_user,   
					@user_hold = user_hold,   
					@priority = q_priority  
			FROM	#upd_soft_alloc_cur  
			WHERE	row_id > @last_row_id  
			ORDER BY row_id ASC        
		END    
        
		RETURN    
	END  

END
GO
GRANT EXECUTE ON  [dbo].[cvo_sim_tdc_soft_alloc_tbl_trg_sp] TO [public]
GO
