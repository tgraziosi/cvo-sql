SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_next_pallet_tran_sp](
	@user_id varchar (50),
	@prev_tran int,
	@last_bin varchar (12)
)
AS

DECLARE @err int,
	@tran_id int,
	@pkg_tran_id int,
	@sort  varchar (2),
	@ord_lock varchar (2),
	@order_no int,
	@order_ext int,
	@def_loc_flag varchar (2),
	@def_loc varchar(10),
	@trans_type varchar(10),
	@current_pallet_id int,
	@current_load_no int,
	@allow_null_load varchar (2)

BEGIN

	SELECT @tran_id  = 0
	SELECT @err      = 0

--	IF NOT EXISTS (SELECT * FROM tdc_user_pallet_build_tbl (nolock) WHERE userid = @user_id)
--		RETURN -1

	IF ((SELECT count(*) FROM tdc_pick_queue WHERE trans = 'PKGBLD' AND (assign_user_id IS NULL OR assign_user_id = @user_id)) = 1)
	BEGIN
		DELETE FROM #prev_tran
		  FROM #prev_tran t, tdc_pick_queue q (nolock)
		 WHERE t.tran_id = q.tran_id
		   AND q.trans = 'PKGBLD' 
		   AND (q.assign_user_id IS NULL OR q.assign_user_id = @user_id)
	END

	-- 'high' priority txs locked by the same user (for exmple, when application was terminated)
	-- check for any transactions locked by the current user on the pick queue
	SELECT @tran_id = tran_id 
	  FROM tdc_pick_queue (nolock) 
	 WHERE [user_id] = @user_id 
	   AND tx_lock = 'C' 
	   AND trans = 'PKGBLD' 
	   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran)
	ORDER BY priority DESC, seq_no DESC

	IF (@tran_id > 0)
	BEGIN
		-- update just date_time
		UPDATE tdc_pick_queue SET date_time = getdate() WHERE tran_id = @tran_id
		RETURN (@tran_id)
	END	

	SELECT @current_pallet_id = ISNULL((SELECT current_pallet_id 
					      FROM tdc_user_pallet_build_tbl (nolock)
					     WHERE userid = @user_id), 0)

	-- if carton has been packed by current user we should look at all orders which tied to this carton
	IF EXISTS (SELECT * FROM tdc_carton_detail_tx (nolock) WHERE carton_no = @current_pallet_id)
	BEGIN
		SELECT top 1 @order_no = l.order_no, @order_ext = l.order_ext
		  FROM load_list l (nolock), tdc_user_pallet_build_tbl p (nolock), tdc_pick_queue q (nolock)
		 WHERE p.userid = @user_id
		   AND p.current_pallet_id = @current_pallet_id
		   AND l.load_no = p.current_load_no
		   AND l.order_no = q.trans_type_no
		   AND l.order_ext = q.trans_type_ext
		   AND q.trans = 'PKGBLD'
		   AND q.tx_lock = 'G'
		   AND q.tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran)
		ORDER BY l.seq_no

		IF @order_no IS NOT NULL AND @order_ext IS NOT NULL
		BEGIN
			SELECT @tran_id = min(tran_id)
			  FROM tdc_pick_queue (nolock)
			 WHERE trans = 'PKGBLD' 
			   AND tx_lock = 'G' 
			   AND trans_type_no = @order_no
			   AND trans_type_ext = @order_ext
			   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran)
		END
		ELSE
		BEGIN
			SELECT @tran_id = min(q.tran_id)
			  FROM tdc_pick_queue q (nolock), tdc_carton_detail_tx c (nolock)
			 WHERE q.trans = 'PKGBLD' 
			   AND q.tx_lock = 'G' 
			   AND q.trans_type_no = c.order_no
			   AND q.trans_type_ext = c.order_ext 
			   AND q.tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran)
		END

		IF (@tran_id > 0)
		BEGIN
			-- update just date_time
			UPDATE tdc_pick_queue SET date_time = getdate() WHERE tran_id = @tran_id
			RETURN (@tran_id)
		END		
	END

	INSERT #prev_tran_with_load SELECT tran_id FROM #prev_tran

	-- do not include orders that is not belong to current user
	INSERT #prev_tran_with_load (tran_id)
		SELECT tran_id 
		  FROM tdc_pick_queue (nolock), load_list (nolock)
		 WHERE trans_type_no = order_no
		   AND trans_type_ext = order_ext
		   AND load_no IN (SELECT current_load_no 
				     FROM tdc_user_pallet_build_tbl (nolock) 
				    WHERE userid != @user_id AND current_load_no != 0)

	INSERT #prev_tran_with_load (tran_id)
		SELECT tran_id 
		  FROM tdc_pick_queue (nolock), tdc_carton_tx (nolock)
		 WHERE trans_type_no = order_no
		   AND trans_type_ext = order_ext
		   AND carton_no IN (SELECT current_pallet_id 
				       FROM tdc_user_pallet_build_tbl (nolock) 
				      WHERE userid != @user_id AND current_load_no = 0)
	
	SELECT @allow_null_load = ISNULL(active, 'N')
	  FROM tdc_config (nolock) 
	 WHERE [function] = 'pallet_loadseq_nullable'

	SELECT @ord_lock = ISNULL(active, 'N') 
	  FROM tdc_config (nolock) 
	 WHERE [function] = 'lock_orders_on_pick'

	SELECT @sort = ISNULL(active, 'N') 
	  FROM tdc_config (nolock) 
	 WHERE [function] = 'sort_queue_by_bin'

	SELECT @def_loc_flag = ISNULL(active, 'N') 
	  FROM tdc_config (nolock) 
	 WHERE [function] = 'q_use_def_loc'

	SELECT @pkg_tran_id = pick.tran_id
	  FROM tdc_user_config_tran_types type (nolock), tdc_user_config_assign_users users (nolock), tdc_pick_queue pick (nolock)
	WHERE type.type = pick.assign_group
	  AND users.group_id = type.group_id
	  AND users.userid = @user_id
	  AND pick.trans = 'PKGBLD'
	  AND pick.tran_id NOT IN (SELECT tran_id FROM #prev_tran_with_load)
	ORDER BY pick.priority desc, pick.seq_no desc

	IF @pkg_tran_id IS NULL
	BEGIN
		SELECT @pkg_tran_id = -1
	END

--- Not using Epicor tables, so just get the next tran according to config flags
	IF (@allow_null_load = 'Y') 
	BEGIN
		IF (@def_loc_flag = 'N')	-- Sort by Location
		BEGIN
			IF (@ord_lock = 'N')	-- Sort by Order Number
			BEGIN
				IF (@sort = 'N')     --Sort by Priority, Bin_no, Seq_no
				BEGIN
					-- check for any transactions assigned to the current user on the pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, seq_no desc

					IF (@tran_id != 0)
						RETURN (@tran_id)
					
					--SELECT transaction with highest priority that is not assigned to anyone from pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, seq_no desc
					
					IF (@tran_id != 0)
						RETURN @tran_id
				END
				ELSE  --SORT BY PRIORITY, BIN_NO, SEQ_NO
				BEGIN
					SELECT @last_bin = isnull(@last_bin, '')
		
					-- check for any transactions assigned to the current user on the pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, bin_no desc, seq_no desc
					
					IF (@tran_id != 0)
						RETURN @tran_id
						
					--SELECT transaction with highest priority that is not assigned to anyone from pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, bin_no desc, seq_no desc

					IF (@tran_id != 0)
						RETURN @tran_id
				END
			END	
			ELSE 
			BEGIN
				IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
				BEGIN
					-- check for any transactions already order locked by the user
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O'
					ORDER BY priority desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans 
						  FROM tdc_pick_queue (nolock) 
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue 
						   SET [user_id] = @user_id, tx_lock = 'O' 
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END
	
					-- check for any transactions assigned to the current user on the pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans 
						  FROM tdc_pick_queue (nolock) 
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue 
						   SET [user_id] = @user_id, tx_lock = 'O' 
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END		
					
					--SELECT transaction with highest priority that is not assigned to anyone from pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans 
						  FROM tdc_pick_queue (nolock) 
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue 
						   SET [user_id] = @user_id, tx_lock = 'O' 
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END			
				END	
				ELSE  --SORT BY PRIORITY, BIN_NO, SEQ_NO
				BEGIN
					SELECT @last_bin = isnull(@last_bin, '')
	
					-- check for any transactions already order locked by the user
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O'
					ORDER BY priority desc, bin_no desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans 
						  FROM tdc_pick_queue (nolock) 
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue 
						   SET [user_id] = @user_id, tx_lock = 'O' 
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END
		
					-- check for any transactions assigned to the current user on the pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, bin_no desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans 
						  FROM tdc_pick_queue (nolock) 
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue 
						   SET [user_id] = @user_id, tx_lock = 'O' 
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END	
					
					--SELECT transaction with highest priority that is not assigned to anyone from pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 	
					 WHERE assign_user_id IS NULL   AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, bin_no desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans 
						  FROM tdc_pick_queue (nolock) 
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue 
						   SET [user_id] = @user_id, tx_lock = 'O' 
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END
				END
			END
		END
	
	-- ONLY look for transactions where location = user's default location
	
		ELSE
		BEGIN
			SELECT @def_loc = location FROM tdc_sec (nolock) WHERE UserID = @user_id
	
			IF (@ord_lock = 'N')
			BEGIN
				IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
				BEGIN
					-- check for any transactions assigned to the current user on the pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						RETURN (@tran_id)
					END
							
					--SELECT transaction with highest priority that is not assigned to anyone from pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' AND location = @def_loc AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						RETURN @tran_id
					END
				END	
				ELSE --SORT BY PRIORITY, BIN_NO, SEQ_NO
				BEGIN
					SELECT @last_bin = isnull(@last_bin, '')
		
					-- check for any transactions assigned to the current user on the pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND location = @def_loc AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, bin_no desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						RETURN (@tran_id)
					END
	
					--SELECT transaction with highest priority that is not assigned to anyone from pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' AND location = @def_loc AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, bin_no desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						RETURN @tran_id
					END
				END
			END		
			ELSE
			BEGIN
				IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
				BEGIN
					-- check for any transactions already order locked by the user
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O'
					ORDER BY priority desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans 
						  FROM tdc_pick_queue (nolock) 
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue 
						   SET [user_id] = @user_id, tx_lock = 'O' 
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END
	
					-- check for any transactions assigned to the current user on the pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans 
						  FROM tdc_pick_queue (nolock) 
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue 
						   SET [user_id] = @user_id, tx_lock = 'O' 
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END
							
					--SELECT transaction with highest priority that is not assigned to anyone from pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock) 
					 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' AND location = @def_loc AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans 
						  FROM tdc_pick_queue (nolock)
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue
						   SET [user_id] = @user_id, tx_lock = 'O'
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END				
				END	
				ELSE  --SORT BY PRIORITY, BIN_NO, SEQ_NO
				BEGIN
					SELECT @last_bin = isnull(@last_bin, '')
	
					-- check for any transactions already order locked by the user
					SELECT @tran_id = tran_id
					  FROM tdc_pick_queue (nolock) 
					 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O' 
					ORDER BY priority desc, bin_no desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans 
						  FROM tdc_pick_queue (nolock)
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue 
						   SET [user_id] = @user_id, tx_lock = 'O'
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END
		
					-- check for any transactions assigned to the current user on the pick queue
					SELECT @tran_id = tran_id 
					  FROM tdc_pick_queue (nolock)
					 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, bin_no desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans
						  FROM tdc_pick_queue (nolock)
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue
						   SET [user_id] = @user_id, tx_lock = 'O'
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END	
					
					--SELECT transaction with highest priority that is not assigned to anyone from pick queue
					SELECT @tran_id = tran_id
					  FROM tdc_pick_queue (nolock)
					 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' AND location = @def_loc AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
					ORDER BY priority desc, bin_no desc, seq_no desc

					IF (@tran_id != 0)
					BEGIN
						SELECT @order_no = trans_type_no, @trans_type = trans
						  FROM tdc_pick_queue (nolock)
						 WHERE tran_id = @tran_id

						UPDATE tdc_pick_queue
						   SET [user_id] = @user_id, tx_lock = 'O'
						 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

						RETURN (@tran_id)
					END
				END
			END
		END
	END		
	ELSE -- Use Epicor group orders table (load list) to determine which tran to get next
	BEGIN
		INSERT INTO #temp_queue_load 
			SELECT  a.trans, a.tran_id, a.priority, a.seq_no, a.location, a.trans_type_no, a.trans_type_ext, a.line_no, a.part_no, a.lot, a.bin_no, a.qty_to_process, a.next_op, 
				a.assign_group, a.assign_user_id, a.[user_id], a.tx_lock, b.load_no, b.seq_no 
			  FROM tdc_pick_queue a (nolock), load_list b (nolock)
			 WHERE a.trans = 'PKGBLD'
			   AND a.tx_lock = 'G'
			   AND a.trans_type_no = b.order_no 
			   AND a.trans_type_ext = b.order_ext
			ORDER BY b.load_no, b.seq_no

		IF (@current_pallet_id = 0)   -- start a new load and look for transactions that are tied to a load that no other users are working on
		BEGIN
			IF (@def_loc_flag = 'N')	-- Sort by Location
			BEGIN
				IF (@ord_lock = 'N')	-- Sort by Order Number
				BEGIN
					IF (@sort = 'N')     --Sort by Priority, Bin_no, Seq_no
					BEGIN
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id 
						   AND trans = 'PKGBLD' 
						   AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran_with_load) 
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN (@tran_id)
						END			
						
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL 
						   AND trans = 'PKGBLD' 
						   AND tx_lock = 'G'
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load)
--						   AND load_no NOT IN (SELECT isnull(current_load_no, 0) FROM tdc_user_pallet_build_tbl WHERE userid != @user_id) 
						ORDER BY load_no, load_seq, priority desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN @tran_id
						END
					END
					ELSE  --SORT BY PRIORITY, BIN_NO, SEQ_NO
					BEGIN
						SELECT @last_bin = isnull(@last_bin, '')
			
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN (@tran_id)
						END		
						
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL 
						   AND trans = 'PKGBLD' 
						   AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load)
--						   AND load_no NOT IN (SELECT isnull(current_load_no, 0) FROM tdc_user_pallet_build_tbl (nolock) WHERE userid != @user_id) 
						ORDER BY load_no, load_seq, priority desc, bin_no desc, q_seq_no desc 

						IF (@tran_id != 0)
						BEGIN
							RETURN @tran_id
						END
					END
				END
				ELSE				
				BEGIN
					IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
					BEGIN
						-- check for any transactions already order locked by the user
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O'
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
		
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load)
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END			
						
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) from #prev_tran_with_load)
--						   AND load_no NOT IN (SELECT isnull(current_load_no, 0) FROM tdc_user_pallet_build_tbl (nolock) WHERE userid != @user_id) 
						ORDER BY load_no, load_seq, priority desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
					END
					ELSE  --SORT BY PRIORITY, BIN_NO, SEQ_NO
					BEGIN
						SELECT @last_bin = isnull(@last_bin, '')
		
						-- check for any transactions already order locked by the user
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O' 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
			
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END		
						
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G'
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load)
--						   AND load_no NOT IN (SELECT isnull(current_load_no, 0) FROM tdc_user_pallet_build_tbl (nolock) WHERE userid != @user_id) 
						ORDER BY load_no, load_seq, priority desc, bin_no desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
					END
				END
			END
		
		-- ONLY look for transactions where location = user's default location
		
			ELSE
			BEGIN
				SELECT @def_loc = location FROM tdc_sec (nolock) WHERE UserID = @user_id
		
				IF (@ord_lock = 'N')
				BEGIN
					IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
					BEGIN
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN						
							RETURN (@tran_id)
						END			
						
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id 
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G'
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
--						   AND load_no not in (select isnull(current_load_no, 0) from tdc_user_pallet_build_tbl) 
						ORDER BY load_no, load_seq, priority desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN @tran_id
						END
					END		
					ELSE  --SORT BY PRIORITY, BIN_NO, SEQ_NO
					BEGIN
						SELECT @last_bin = isnull(@last_bin, '')
			
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND location = @def_loc AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN (@tran_id)
						END
		
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load)
--						   AND load_no not in (select isnull(current_load_no, 0) from tdc_user_pallet_build_tbl) 
						ORDER BY load_no, load_seq, priority desc, bin_no desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN @tran_id
						END
					END
				END
				ELSE				
				BEGIN
					IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
					BEGIN
						-- check for any transactions already order locked by the user
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock) 
						 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O' 
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
		
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue 
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
			
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id 
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load)
--						   AND load_no not in (select isnull(current_load_no, 0) from tdc_user_pallet_build_tbl) 
						ORDER BY load_no, load_seq, priority desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans 
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END					
					END		
					ELSE --SORT BY PRIORITY, BIN_NO, SEQ_NO
					BEGIN
						SELECT @last_bin = isnull(@last_bin, '')
		
						-- check for any transactions already order locked by the user
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (nolock)
						 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O'
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
			
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
								
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G'
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load)
--						   AND load_no not in (select isnull(current_load_no, 0) from tdc_user_pallet_build_tbl) 
						ORDER BY load_no, load_seq, priority desc, bin_no desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
					END
				END
			END				
		END
/****************************************************/
		ELSE   -- find the next transaction for the load that you are currently working on order by seq_no
		BEGIN
--			*** repeat above code but use the @current_pallet_id   ****
			IF (@def_loc_flag = 'N')	-- Sort by Location
			BEGIN
				IF (@ord_lock = 'N')	-- Sort by Order Number
				BEGIN
					IF (@sort = 'N')     --Sort by Priority, Bin_no, Seq_no
					BEGIN
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN (@tran_id)
						END
			
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id 
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL 
						   AND trans = 'PKGBLD' 
						   AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
--						   AND load_no IN (SELECT current_load_no FROM tdc_user_pallet_build_tbl WHERE userid = @user_id) 
						ORDER BY load_no, load_seq, priority desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN @tran_id
						END					
					END		
					ELSE --SORT BY PRIORITY, BIN_NO, SEQ_NO
					BEGIN
						SELECT @last_bin = isnull(@last_bin, '')
			
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN (@tran_id)
						END
								
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id 
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran_with_load) 
--						   AND load_no in (select current_load_no from tdc_user_pallet_build_tbl where UserID = @user_id) 
						ORDER BY load_no, load_seq, priority desc, bin_no desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN @tran_id
						END
					END
				END
				ELSE
				BEGIN
					IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
					BEGIN
						-- check for any transactions already order locked by the user
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O' 
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
		
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
									
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
--						   AND load_no in (select current_load_no from tdc_user_pallet_build_tbl where UserID = @user_id) 
						ORDER BY load_no, load_seq, priority desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END	
					END		
					ELSE --SORT BY PRIORITY, BIN_NO, SEQ_NO
					BEGIN
						SELECT @last_bin = isnull(@last_bin, '')
		
						-- check for any transactions already order locked by the user
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O' 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
			
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
								
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id 
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
--						   AND load_no in (select current_load_no from tdc_user_pallet_build_tbl where UserID = @user_id) 
						ORDER BY load_no, load_seq, priority desc, bin_no desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
					END
				END
			END
		
		-- ONLY look for transactions where location = user's default location
		
			ELSE
			BEGIN
				SELECT @def_loc = location FROM tdc_sec (nolock) WHERE UserID = @user_id
		
				IF (@ord_lock = 'N')
				BEGIN
					IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
					BEGIN
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN (@tran_id)
						END			
						
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id 
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
--						   AND load_no in (select current_load_no from tdc_user_pallet_build_tbl where UserID = @user_id) 
						ORDER BY load_no, load_seq, priority desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN @tran_id
						END
					END		
					ELSE --SORT BY PRIORITY, BIN_NO, SEQ_NO
					BEGIN
						SELECT @last_bin = isnull(@last_bin, '')
			
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND location = @def_loc AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN (@tran_id)
						END
		
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id
						  FROM #temp_queue_load (nolock) 
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
--						   AND load_no in (select current_load_no from tdc_user_pallet_build_tbl where UserID = @user_id) 
						ORDER BY load_no, load_seq, priority desc,bin_no desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							RETURN @tran_id
						END					
					END
				END				
				ELSE
				BEGIN
					IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
					BEGIN
						-- check for any transactions already order locked by the user
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (nolock) 
						 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O'
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans 
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
		
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END			
						
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id 
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
--						   AND load_no in (select current_load_no from tdc_user_pallet_build_tbl where UserID = @user_id) 
						ORDER BY load_no, load_seq, priority desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END								
					END		
					ELSE --SORT BY PRIORITY, BIN_NO, SEQ_NO
					BEGIN
						SELECT @last_bin = isnull(@last_bin, '')
		
						-- check for any transactions already order locked by the user
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (nolock)
						 WHERE [user_id] = @user_id AND trans = 'PKGBLD' AND tx_lock = 'O' 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
			
						-- check for any transactions assigned to the current user on the pick queue
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (nolock)
						 WHERE assign_user_id = @user_id AND trans = 'PKGBLD' AND tx_lock = 'G' AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
						ORDER BY priority desc, bin_no desc, seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans 
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END		
						
						--SELECT transaction with highest priority that is not assigned to anyone from pick queue
						SELECT @tran_id = tran_id 
						  FROM #temp_queue_load (nolock)
						 WHERE assign_user_id IS NULL AND trans = 'PKGBLD' AND tx_lock = 'G' 
						   AND tran_id NOT IN (SELECT ISNULL(tran_id, 0) FROM #prev_tran_with_load) 
--						   AND load_no in (select current_load_no from tdc_user_pallet_build_tbl where UserID = @user_id) 
						ORDER BY load_no, load_seq, priority desc, bin_no desc, q_seq_no desc

						IF (@tran_id != 0)
						BEGIN
							SELECT @order_no = trans_type_no, @trans_type = trans
							  FROM tdc_pick_queue (nolock)
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue
							   SET [user_id] = @user_id, tx_lock = 'O'
							 WHERE trans_type_no = @order_no and trans = @trans_type AND tx_lock = 'G'

							RETURN (@tran_id)
						END
					END
				END
			END				
		END
	END

	IF (@pkg_tran_id > 0)
		RETURN @pkg_tran_id

	RETURN -1
END
GO
GRANT EXECUTE ON  [dbo].[tdc_next_pallet_tran_sp] TO [public]
GO
