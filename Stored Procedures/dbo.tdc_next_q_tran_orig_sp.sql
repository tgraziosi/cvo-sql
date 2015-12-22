SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SCR #34537 4/19/05 By Jim : added assign_user_id = @user_id in where clause for trans is picker. if tran_id not found then check assign_user_id is null
-- SCR #34537 4/21/05 By Jim : assign_user_id can be either @user_id or @user_config_group

/************************************************************************/
/* Name:	tdc_next_q_tran_orig_sp	        	      		*/
/*									*/
/* Module:	WMS							*/
/*						      			*/
/* Input:						      		*/
/*	user_id   - 	USER ID				      		*/
/*	prev_tran -	Previous Transaction		      		*/
/*							      		*/
/*							      		*/
/* Output:        					     	 	*/
/*	tran_id - 	Transaction ID					*/
/*									*/
/* Description:								*/
/*	This SP will be called to get the next transaction off 		*/
/*	the queue to be complete. The sp will check to see IF 		*/
/*	the user has any open trans, first, then the workers		*/
/*	assignment list, then the user	group will be checked		*/
/*	for assignments. IF none of these have a tran waiting		*/
/*	to be completed then the next tran assigned to the 		*/
/*	everyone with the highest priority will be chosen.		*/
/*									*/
/************************************************************************/

CREATE PROCEDURE [dbo].[tdc_next_q_tran_orig_sp](
  @user_id varchar (50),
  @prev_tran int,
  @last_bin varchar (12)
)
AS

DECLARE @group_id varchar (20),
	@config_group varchar (20),
	@err int,
	@tran_id int,
	@sort  varchar (2),
	@ord_lock varchar (2),
	@order_no int,
	@def_loc_flag varchar (2),
	@def_loc varchar(10),
	@trans_type varchar(10)

BEGIN
	SELECT @tran_id  = 0
	SELECT @group_id = NULL
	SELECT @err      = 0
	SELECT @config_group = ISNULL((SELECT group_id FROM tdc_user_config_assign_users (NOLOCK) WHERE userid = @user_id), '')

	-- 'high' priority txs locked by the same user (for exmple, when application was terminated)
	-- check for any transactions locked by the current user on the pick queue
	SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) 
		WHERE [user_id] = @user_id AND tx_lock = 'C' AND tran_id NOT IN (SELECT tran_id from #prev_tran)
		ORDER BY priority desc, seq_no desc

	IF (@tran_id != 0)
	BEGIN
		-- update just date_time
		UPDATE tdc_pick_queue SET date_time = GETDATE() WHERE tran_id = @tran_id
		RETURN @tran_id
	END
	
	-- check for any transactions locked by the current user on the put queue
	SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) 
		WHERE [user_id] = @user_id AND tx_lock = 'C' AND tran_id NOT IN (SELECT tran_id from #prev_tran)
		ORDER BY priority desc, seq_no desc
	IF (@tran_id != 0)
	BEGIN
		-- update just date_time
		UPDATE tdc_pick_queue SET date_time = GETDATE() WHERE tran_id = @tran_id
		RETURN @tran_id
	END

	SELECT @ord_lock = active FROM tdc_config (NOLOCK) WHERE [function] = 'lock_orders_on_pick'
	SELECT @sort     = active FROM tdc_config (NOLOCK) WHERE [function] = 'sort_queue_by_bin'
	SELECT @def_loc_flag = active FROM tdc_config (NOLOCK) WHERE [function] = 'q_use_def_loc'

	IF (@def_loc_flag = 'N')	-- Sort by Location
	BEGIN
		IF (@ord_lock = 'N')	-- Sort by Order Number
		BEGIN
			IF (@sort = 'N')     --Sort by Priority, Bin_no, Seq_no
			BEGIN
				-- check for any transactions assigned to the current user on the pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END
	
				-- check for any transactions assigned to the current user on the put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END 

				DECLARE trans_type_assign CURSOR FOR
					SELECT type FROM tdc_user_config_tran_types (NOLOCK) WHERE group_id = @config_group ORDER BY priority

				OPEN trans_type_assign
				FETCH NEXT FROM trans_type_assign INTO @group_id
				WHILE(@@FETCH_STATUS = 0)
				BEGIN
					SELECT @tran_id = 0

					IF @group_id = 'PLWB2B' OR @group_id = 'MGTB2B'	 
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
	 					END
					END
					ELSE IF (@group_id = 'PUTAWAY')  -- check put queue  
					BEGIN
						SELECT @tran_id = 0
						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
						END
					END
					ELSE
					BEGIN
						SELECT @tran_id = 0
						SELECT @tran_id = tran_id
						  FROM tdc_pick_queue (NOLOCK) 
						 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
						   AND assign_group = @group_id
						   AND assign_user_id = @user_id
						   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
						ORDER BY priority DESC, seq_no DESC

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id = @config_group
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							ORDER BY priority DESC, seq_no DESC
						END

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id IS NULL
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							ORDER BY priority DESC, seq_no DESC
						END

						IF (@tran_id != 0)
						BEGIN
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue 
							   SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' 
							 WHERE tran_id = @tran_id
							RETURN @tran_id
	 					END
					END

					FETCH NEXT FROM trans_type_assign INTO @group_id
				END

				CLOSE      trans_type_assign
				DEALLOCATE trans_type_assign

				--SELECT transaction with highest priority that is not assigned to anyone from pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				--SELECT transaction with highest priority that is not assigned to anyone from put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

			END

			ELSE IF (@sort = 'Y') --SORT BY PRIORITY, BIN_NO, SEQ_NO
			BEGIN
				SELECT @last_bin = ISNULL(@last_bin, '')
	
				-- check for any transactions assigned to the current user on the pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				-- check for any transactions assigned to the current user on the put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				DECLARE trans_type_assign CURSOR FOR
				SELECT type FROM tdc_user_config_tran_types (NOLOCK) WHERE group_id = @config_group ORDER BY priority
	
				OPEN trans_type_assign
				FETCH NEXT FROM trans_type_assign INTO @group_id
				WHILE(@@FETCH_STATUS = 0)
				BEGIN
					SELECT @tran_id = 0

					IF @group_id = 'PLWB2B' OR @group_id = 'MGTB2B'
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no >= @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
		 				END

						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id from #prev_tran)  ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
	 					END
					END
					ELSE IF (@group_id = 'PUTAWAY') 	-- check put queue  
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no >= @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
 						END
						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no < @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
						END
					END
					ELSE
					BEGIN
						SELECT @tran_id = 0
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (NOLOCK) 
						 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
						   AND assign_group = @group_id
						   AND assign_user_id = @user_id
						   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
						ORDER BY priority DESC, bin_no DESC, seq_no DESC

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id = @config_group
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							ORDER BY priority DESC, bin_no DESC, seq_no DESC
						END

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id IS NULL
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							ORDER BY priority DESC, bin_no DESC, seq_no DESC
						END

						IF (@tran_id != 0)
						BEGIN
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue 
							   SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' 
							 WHERE tran_id = @tran_id
							RETURN @tran_id
	 					END
					END

					FETCH NEXT FROM trans_type_assign INTO @group_id
				END

				CLOSE      trans_type_assign
				DEALLOCATE trans_type_assign

				--SELECT transaction with highest priority that is not assigned to anyone from pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				--SELECT transaction with highest priority that is not assigned to anyone from put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END
			END
		END

		IF (@ord_lock = 'Y')
		BEGIN
			IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
			BEGIN
				-- check for any transactions already order locked by the user
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) where [user_id] = @user_id AND tx_lock = 'O' 
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END

				-- check for any transactions assigned to the current user on the pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END
	
				-- check for any transactions assigned to the current user on the put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				DECLARE trans_type_assign CURSOR FOR
					SELECT type FROM tdc_user_config_tran_types (NOLOCK) WHERE group_id = @config_group ORDER BY priority

				OPEN trans_type_assign
				FETCH NEXT FROM trans_type_assign INTO @group_id
				WHILE(@@FETCH_STATUS = 0)
				BEGIN
					SELECT @tran_id = 0

					IF @group_id = 'PLWB2B' OR @group_id = 'MGTB2B'
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
		 				END
					END
					ELSE IF (@group_id = 'PUTAWAY') 	-- check put queue  
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
						END
					END		
					ELSE
					BEGIN
						SELECT @tran_id = 0
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (NOLOCK) 
						 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
						   AND assign_group = @group_id
						   AND assign_user_id = @user_id
						   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
						ORDER BY priority DESC, seq_no DESC

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id = @config_group
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							ORDER BY priority DESC, seq_no DESC
						END

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id IS NULL
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							ORDER BY priority DESC, seq_no DESC
						END

						IF (@tran_id != 0)
						BEGIN
							DEALLOCATE trans_type_assign

							UPDATE tdc_pick_queue 
							   SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' 
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue 
							   SET [user_id] = @user_id, tx_lock = 'O' 
							 WHERE trans_type_no = @order_no 
							   AND trans = @trans_type 
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')

							RETURN @tran_id
	 					END
					END

					FETCH NEXT FROM trans_type_assign INTO @group_id
				END

				CLOSE      trans_type_assign
				DEALLOCATE trans_type_assign

				--SELECT transaction with highest priority that is not assigned to anyone from pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END

				--SELECT transaction with highest priority that is not assigned to anyone from put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END
			END

			ELSE IF (@sort = 'Y') --SORT BY PRIORITY, BIN_NO, SEQ_NO
			BEGIN
				SELECT @last_bin = ISNULL(@last_bin, '')

				-- check for any transactions already order locked by the user
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) where [user_id] = @user_id AND tx_lock = 'O' 
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END
	
				-- check for any transactions assigned to the current user on the pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END

				-- check for any transactions assigned to the current user on the put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				DECLARE trans_type_assign CURSOR FOR
				SELECT type FROM tdc_user_config_tran_types (NOLOCK) WHERE group_id = @config_group ORDER BY priority
	
				OPEN trans_type_assign
				FETCH NEXT FROM trans_type_assign INTO @group_id
				WHILE(@@FETCH_STATUS = 0)
				BEGIN
					SELECT @tran_id = 0

					IF @group_id = 'PLWB2B' OR @group_id = 'MGTB2B'
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no >= @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
		 				END

						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id from #prev_tran)  ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
 						END				
					END
					ELSE IF (@group_id = 'PUTAWAY') 	-- check put queue  
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no >= @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
						END

						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no  < @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
						END
					END
					ELSE
					BEGIN
						SELECT @tran_id = 0
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (NOLOCK) 
						 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
						   AND assign_group = @group_id
						   AND assign_user_id = @user_id
						   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
						ORDER BY priority DESC, bin_no DESC, seq_no DESC

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id = @config_group
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							ORDER BY priority DESC, bin_no DESC, seq_no DESC
						END

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id IS NULL
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							ORDER BY priority DESC, bin_no DESC, seq_no DESC
						END

						IF (@tran_id != 0)
						BEGIN
							DEALLOCATE trans_type_assign

							UPDATE tdc_pick_queue 
							   SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' 
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue 
							   SET [user_id] = @user_id, tx_lock = 'O' 
							 WHERE trans_type_no = @order_no 
							   AND trans = @trans_type 
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')

							RETURN @tran_id
	 					END
					END

					FETCH NEXT FROM trans_type_assign INTO @group_id
				END

				CLOSE      trans_type_assign
				DEALLOCATE trans_type_assign

				--SELECT transaction with highest priority that is not assigned to anyone from pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END

				--SELECT transaction with highest priority that is not assigned to anyone from put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END
			END
		END
	END

-- ONLY look for transactions where location = user's default location

	IF (@def_loc_flag = 'Y')
	BEGIN
		SELECT @def_loc = location FROM tdc_sec (NOLOCK) WHERE UserID = @user_id

		IF (@ord_lock = 'N')
		BEGIN
			IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
			BEGIN
				-- check for any transactions assigned to the current user on the pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END
	
				-- check for any transactions assigned to the current user on the put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				DECLARE trans_type_assign CURSOR FOR
					SELECT type FROM tdc_user_config_tran_types (NOLOCK) WHERE group_id = @config_group ORDER BY priority

				OPEN trans_type_assign
				FETCH NEXT FROM trans_type_assign INTO @group_id
				WHILE(@@FETCH_STATUS = 0)
				BEGIN
					SELECT @tran_id = 0

					IF @group_id = 'PLWB2B' OR @group_id = 'MGTB2B'
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
	 					END
					END
					ELSE IF (@group_id = 'PUTAWAY') 	-- check put queue  
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
						END
					END
					ELSE
					BEGIN
						SELECT @tran_id = 0
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (NOLOCK) 
						 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
						   AND assign_group = @group_id
						   AND assign_user_id = @user_id
						   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
						   AND location = @def_loc
						ORDER BY priority DESC, seq_no DESC

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id = @config_group
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							   AND location = @def_loc
							ORDER BY priority DESC, seq_no DESC
						END

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id IS NULL
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							   AND location = @def_loc
							ORDER BY priority DESC, seq_no DESC
						END

						IF (@tran_id != 0)
						BEGIN
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue 
							   SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' 
							 WHERE tran_id = @tran_id
							RETURN @tran_id
	 					END
					END

					FETCH NEXT FROM trans_type_assign INTO @group_id
				END

				CLOSE      trans_type_assign
				DEALLOCATE trans_type_assign

				--SELECT transaction with highest priority that is not assigned to anyone from pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				--SELECT transaction with highest priority that is not assigned to anyone from put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END
			END

			ELSE IF (@sort = 'Y') --SORT BY PRIORITY, BIN_NO, SEQ_NO
			BEGIN
				SELECT @last_bin = ISNULL(@last_bin, '')
	
				-- check for any transactions assigned to the current user on the pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				-- check for any transactions assigned to the current user on the put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				DECLARE trans_type_assign CURSOR FOR
				SELECT type FROM tdc_user_config_tran_types (NOLOCK) WHERE group_id = @config_group ORDER BY priority
	
				OPEN trans_type_assign
				FETCH NEXT FROM trans_type_assign INTO @group_id
				WHILE(@@FETCH_STATUS = 0)
				BEGIN
					SELECT @tran_id = 0

					IF @group_id = 'PLWB2B' OR @group_id = 'MGTB2B'
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no >= @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
		 				END

						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran)  ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
	 					END
					END
					ELSE IF (@group_id = 'PUTAWAY') 	-- check put queue  
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no >= @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
 						END

						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no < @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
						END
					END
					ELSE
					BEGIN
						-- check each group starting with highest priority for a transaction
						SELECT @tran_id = 0
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (NOLOCK) 
						 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
						   AND assign_group = @group_id
						   AND assign_user_id = @user_id
						   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
						   AND location = @def_loc
						ORDER BY priority DESC, bin_no DESC, seq_no DESC

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id = @config_group
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							   AND location = @def_loc
							ORDER BY priority DESC, bin_no DESC, seq_no DESC
						END

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id IS NULL
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							   AND location = @def_loc
							ORDER BY priority DESC, bin_no DESC, seq_no DESC
						END

						IF (@tran_id != 0)
						BEGIN
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue 
							   SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' 
							 WHERE tran_id = @tran_id
							RETURN @tran_id
	 					END
					END

					FETCH NEXT FROM trans_type_assign INTO @group_id
				END

				CLOSE      trans_type_assign
				DEALLOCATE trans_type_assign

				--SELECT transaction with highest priority that is not assigned to anyone from pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				--SELECT transaction with highest priority that is not assigned to anyone from put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END
			END
		END

		IF (@ord_lock = 'Y')
		BEGIN
			IF (@sort = 'N')     --SORT BY PRIORITY, SEQ_NO
			BEGIN
				-- check for any transactions already order locked by the user
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) where [user_id] = @user_id AND tx_lock = 'O' 
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END

				-- check for any transactions assigned to the current user on the pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END
	
				-- check for any transactions assigned to the current user on the put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				DECLARE trans_type_assign CURSOR FOR
					SELECT type FROM tdc_user_config_tran_types (NOLOCK) WHERE group_id = @config_group ORDER BY priority

				OPEN trans_type_assign
				FETCH NEXT FROM trans_type_assign INTO @group_id
				WHILE(@@FETCH_STATUS = 0)
				BEGIN
					SELECT @tran_id = 0

					IF @group_id = 'PLWB2B' OR @group_id = 'MGTB2B'
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
		 				END
					END
					ELSE IF (@group_id = 'PUTAWAY') 	-- check put queue  
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
						END
					END
					ELSE
					BEGIN
						-- check each group starting with highest priority for a transaction
						SELECT @tran_id = 0
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (NOLOCK) 
						 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
						   AND assign_group = @group_id
						   AND assign_user_id = @user_id
						   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
						   AND location = @def_loc
						ORDER BY priority DESC, seq_no DESC

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id = @config_group
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							   AND location = @def_loc
							ORDER BY priority DESC, seq_no DESC
						END

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id IS NULL
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							   AND location = @def_loc
							ORDER BY priority DESC, seq_no DESC
						END

						IF (@tran_id != 0)
						BEGIN
							DEALLOCATE trans_type_assign

							UPDATE tdc_pick_queue 
							   SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' 
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue 
							   SET [user_id] = @user_id, tx_lock = 'O' 
							 WHERE trans_type_no = @order_no 
							   AND trans = @trans_type 
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')

							RETURN @tran_id
	 					END
					END

					FETCH NEXT FROM trans_type_assign INTO @group_id
				END

				CLOSE      trans_type_assign
				DEALLOCATE trans_type_assign

				--SELECT transaction with highest priority that is not assigned to anyone from pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END

				--SELECT transaction with highest priority that is not assigned to anyone from put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

			END

			ELSE IF (@sort = 'Y') --SORT BY PRIORITY, BIN_NO, SEQ_NO
			BEGIN
				SELECT @last_bin = ISNULL(@last_bin, '')

				-- check for any transactions already order locked by the user
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) where [user_id] = @user_id AND tx_lock = 'O' 
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END
	
				-- check for any transactions assigned to the current user on the pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END

				-- check for any transactions assigned to the current user on the put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id = @user_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END

				DECLARE trans_type_assign CURSOR FOR
				SELECT type FROM tdc_user_config_tran_types (NOLOCK) WHERE group_id = @config_group ORDER BY priority
	
				OPEN trans_type_assign
				FETCH NEXT FROM trans_type_assign INTO @group_id
				WHILE(@@FETCH_STATUS = 0)
				BEGIN
					SELECT @tran_id = 0

					IF @group_id = 'PLWB2B' OR @group_id = 'MGTB2B'
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no >= @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
		 				END

						SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_group = @group_id AND trans = @group_id AND tx_lock = 'R' AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran)  ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
 						END
					END
					ELSE IF (@group_id = 'PUTAWAY') 	-- check put queue  
					BEGIN
						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no >= @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
						END

						SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_group = @group_id AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) and bin_no < @last_bin ORDER BY priority desc, bin_no desc, seq_no desc
						IF (@tran_id != 0)
						BEGIN
							CLOSE      trans_type_assign
							DEALLOCATE trans_type_assign
							UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
							RETURN @tran_id
						END
					END
					ELSE
					BEGIN
						SELECT @tran_id = 0
						SELECT @tran_id = tran_id 
						  FROM tdc_pick_queue (NOLOCK) 
						 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
						   AND assign_group = @group_id
						   AND assign_user_id = @user_id
						   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
						   AND location = @def_loc
						ORDER BY priority DESC, bin_no DESC, seq_no DESC


						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id = @config_group
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							   AND location = @def_loc
							ORDER BY priority DESC, bin_no DESC, seq_no DESC
						END

						IF (@tran_id = 0)
						BEGIN
							SELECT @tran_id = tran_id 
							  FROM tdc_pick_queue (NOLOCK) 
							 WHERE tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
							   AND assign_group = @group_id
							   AND assign_user_id IS NULL
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') 
							   AND location = @def_loc
							ORDER BY priority DESC, bin_no DESC, seq_no DESC
						END

						IF (@tran_id != 0)
						BEGIN
							DEALLOCATE trans_type_assign

							UPDATE tdc_pick_queue 
							   SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' 
							 WHERE tran_id = @tran_id

							UPDATE tdc_pick_queue 
							   SET [user_id] = @user_id, tx_lock = 'O' 
							 WHERE trans_type_no = @order_no 
							   AND trans = @trans_type 
							   AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')

							RETURN @tran_id
	 					END
					END

					FETCH NEXT FROM trans_type_assign INTO @group_id
				END

				CLOSE      trans_type_assign
				DEALLOCATE trans_type_assign

				--SELECT transaction with highest priority that is not assigned to anyone from pick queue
				SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					SELECT @order_no = trans_type_no, @trans_type = trans FROM tdc_pick_queue (NOLOCK) WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					UPDATE tdc_pick_queue SET [user_id] = @user_id, tx_lock = 'O' WHERE trans_type_no = @order_no and trans = @trans_type AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R')
					RETURN @tran_id
				END

				--SELECT transaction with highest priority that is not assigned to anyone from put queue
				SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK) WHERE assign_user_id IS NULL AND assign_group IS NULL AND ((tx_lock = 'P' AND trans != 'STDPICK') OR tx_lock = 'R') AND location = @def_loc AND tran_id NOT IN (SELECT tran_id from #prev_tran) ORDER BY priority desc, bin_no desc, seq_no desc
				IF (@tran_id != 0)
				BEGIN
					UPDATE tdc_put_queue SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
					RETURN @tran_id
				END
			END
		END
	END

	SELECT @tran_id = -1
	RETURN @tran_id
END
GO
GRANT EXECUTE ON  [dbo].[tdc_next_q_tran_orig_sp] TO [public]
GO
