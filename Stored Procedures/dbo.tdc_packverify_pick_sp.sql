SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_packverify_pick_sp] 
	@order_no 	int,
	@order_ext 	int,
	@line_no 	int, 
	@part_no 	varchar(30), 
	@lot_ser 	varchar(25), 
	@bin_no 	varchar(12), 
	@location 	varchar(10), 
	@qty 		decimal(24,8), 
	@user_id 	varchar(50),
	@error_msg 	varchar(255) 	OUTPUT
AS 

DECLARE @serial_no	int,
	@err		int,
	@date_expire 	datetime,
	@b2b_qty        decimal(24,8),
	@avail_qty      decimal(24,8),
	@language 	varchar(10)

	SELECT @err = 0

	-- Clear the temp table
	TRUNCATE TABLE #adm_pick_ship

	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (NOLOCK)  WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	-- If it's a first carton for the order, pick all the miscellaneous parts
	IF NOT EXISTS (SELECT * FROM tdc_carton_detail_tx  
	                WHERE order_no  = @order_no
	                  AND order_ext = @order_ext
                          AND pack_qty  > 0)		
	BEGIN
		-- Insert part into temp table for picking
		INSERT INTO #adm_pick_ship (order_no, ext, line_no, part_no, bin_no, lot_ser, location, date_exp,     
					    qty, err_msg, who)  
		SELECT order_no, order_ext, line_no, part_no,  NULL, NULL, location, NULL, ordered, NULL,  @user_id
		  FROM ord_list  (NOLOCK)
                 WHERE order_no  = @order_no
                   AND order_ext = @order_ext
                   AND part_type = 'M'
		
		IF @@ERROR <> 0
		BEGIN
			-- 'Unable to pick the miscellaneous parts: Insert into #adm_pick_ship failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -101 AND language = @language 
			RETURN -100
		END

		--  Call the pick stored procedure
		EXEC @err = tdc_adm_pick_ship
	
		IF (@err < 0) 
		BEGIN
			-- 'Unable to pick the miscellaneous parts: tdc_adm_pick_ship SP failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -102 AND language = @language 
			RETURN -101
		END

	END

	-- Clear the temp table
	TRUNCATE TABLE #adm_pick_ship

	-- Make sure there is no pending B2B transaction for the part on the order
	SELECT @b2b_qty = 0
	SELECT @b2b_qty = (SELECT SUM(qty) FROM tdc_soft_alloc_tbl
                   	    WHERE order_no   = @order_no
                     	      AND order_ext  = @order_ext
	                      AND order_type = 'S'
			      AND line_no    = @line_no
			      AND part_no    = @part_no
			      AND bin_no    != target_bin)

	IF @b2b_qty > 0
	BEGIN
		SELECT @avail_qty = (SELECT SUM(qty) FROM tdc_soft_alloc_tbl
	                   	      WHERE order_no   = @order_no
	                     	        AND order_ext  = @order_ext
		                        AND order_type = 'S'
				        AND line_no    = @line_no
				        AND part_no    = @part_no
				        AND bin_no  IS NOT NULL
				        AND bin_no     = target_bin)

		IF @avail_qty - @b2b_qty < @qty		
		BEGIN
			-- 'Unable to pick: Pending BIN to BIN transaction.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -103 AND language = @language 
			RETURN -1 
		END
	END
	-- If item is LB tracked
	IF (SELECT lb_tracking FROM inv_master   WHERE part_no = @part_no) = 'Y'
	BEGIN
		-- Check if item is TDC Serialized. If it is, we store Lots / Bins in the temp table
		IF NOT EXISTS(SELECT * FROM tdc_inv_list   (NOLOCK)
			       WHERE part_no = @part_no 
				 AND location = @location
				 AND vendor_sn IN ('I', 'O')) 
		BEGIN
			-- 1. Get expiration date  
			SELECT @date_expire = date_expires 
			  FROM lot_bin_stock (NOLOCK)
			 WHERE location = @location
			   AND part_no  = @part_no
			   AND bin_no   = @bin_no
			   AND lot_ser  = @lot_ser

			-- 2. Insert part into temp table for picking
			INSERT INTO #adm_pick_ship (order_no, ext, line_no, part_no,  bin_no,  lot_ser,  location,  
						    date_exp, qty, err_msg, who)  
			VALUES                     (@order_no , @order_ext, @line_no, @part_no, @bin_no, @lot_ser, @location,
						    @date_expire, @qty, NULL, @user_id)
			
			IF @@ERROR <> 0
			BEGIN
				-- 'Unable to pick: Insert into #adm_pick_ship failed.'
				SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -104 AND language = @language 
				RETURN -2
			END

			-- 3. Call the pick stored procedure
			EXEC @err = tdc_adm_pick_ship
		
			IF (@err < 0) 
			BEGIN
				-- 'Unable to pick: tdc_adm_pick_ship SP failed.'
				SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -105 AND language = @language 
				RETURN -3 
			END

			-- 5. Change the allocated qty
			UPDATE tdc_soft_alloc_tbl 
			   SET qty = qty  - @qty
			 WHERE order_no   = @order_no
			   AND order_ext  = @order_ext
			   AND order_type = 'S'
			   AND line_no    = @line_no
			   AND part_no    = @part_no
			   AND lot_ser    = @lot_ser
			   AND bin_no     = @bin_no

			DELETE FROM tdc_soft_alloc_tbl 
			 WHERE order_no   = @order_no
			   AND order_ext  = @order_ext
			   AND order_type = 'S'
			   AND line_no    = @line_no
			   AND part_no    = @part_no
			   AND lot_ser    = @lot_ser
			   AND bin_no     = @bin_no
			   AND qty       <= 0

			DELETE FROM tdc_pick_queue 
			 WHERE trans_type_no   = @order_no 
			   AND trans_type_ext  = @order_ext
			   AND line_no    = @line_no
			   AND part_no    = @part_no
			   AND lot        = @lot_ser
			   AND bin_no     = @bin_no
			   AND qty_to_process <= 0
				
			IF (@@ERROR <> 0) 
			BEGIN
				-- 'Unable to pick: update tdc_soft_alloc_tbl failed.'
				SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -106 AND language = @language 
				RETURN -5 
			END

			-- 7. If the record exists in tdc_dist_item_pick, update the quantity
			--    If not, insert the record into the table
			IF EXISTS(SELECT *
		                    FROM tdc_dist_item_pick
		  	 	   WHERE method = '01'
				     AND order_no   = @order_no
			 	     AND order_ext  = @order_ext
			 	     AND line_no    = @line_no
			 	     AND part_no    = @part_no				     
				     AND lot_ser    = @lot_ser
				     AND bin_no     = @bin_no
				     AND [function] = 'S')
			BEGIN
			    	UPDATE tdc_dist_item_pick  
			           SET quantity   = quantity +  @qty
			         WHERE method = '01'
				   AND order_no   = @order_no
			           AND order_ext  = @order_ext
			           AND line_no    = @line_no
			           AND part_no    = @part_no
				   AND lot_ser    = @lot_ser
				   AND bin_no     = @bin_no
				   AND [function] = 'S'
		
		        	IF (@@ERROR <> 0)
		        	BEGIN
		            		-- 'Unable to pick: update tdc_dist_item_pick failed.'
					SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -108 AND language = @language 
		            		RETURN -7
		        	END 
			END
			ELSE -- Record doesn't exist
			BEGIN
		            -- create new dist_item_pick record
		            EXEC @serial_no = tdc_get_serialno 
		
		            IF (@serial_no < 0)
		            BEGIN
		                -- 'Unable to pick: tdc_get_serialno SP failed.'
				SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -109 AND language = @language 
		                RETURN -8
		            END 
		            
		            INSERT INTO tdc_dist_item_pick (method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, quantity, 
							    child_serial_no, [function], type)  
		            VALUES ('01', @order_no, @order_ext, @line_no, @part_no, @lot_ser, @bin_no, @qty, @serial_no, 'S', '01')
		
		            IF (@@ERROR <> 0)
		            BEGIN
		                -- 'Unable to pick: Insert into tdc_dist_item_pick failed.'
				SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -110 AND language = @language 
		                RETURN -9
		            END 
			END	
		END 		-- Not TDC Serialized
		BEGIN		-- TDC Serialized item
 			-- Get Lots/Bins from the temp table.
			DECLARE lot_bin_cur CURSOR FOR
				SELECT DISTINCT lot_ser, bin_no FROM #scanned_serials

			OPEN lot_bin_cur
			FETCH NEXT FROM lot_bin_cur INTO @lot_ser, @bin_no

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				-- Get qty to pick
				SELECT @qty = COUNT(*) 
                                  FROM #scanned_serials
				 WHERE lot_ser = @lot_ser
                                   AND bin_no  = @bin_no

				-- 1. Get expiration date  
				SELECT @date_expire = date_expires 
				  FROM lot_bin_stock (NOLOCK)
				 WHERE location = @location
				   AND part_no  = @part_no
				   AND bin_no   = @bin_no
				   AND lot_ser  = @lot_ser
	
				-- 2. Insert part into temp table for picking
				INSERT INTO #adm_pick_ship (order_no, ext, line_no, part_no,  bin_no,  lot_ser,  location,  
							    date_exp, qty, err_msg, who)  
				VALUES                     (@order_no , @order_ext, @line_no, @part_no, @bin_no, @lot_ser, @location,
							    @date_expire, @qty, NULL, @user_id)
				
				IF @@ERROR <> 0
				BEGIN
					CLOSE	   lot_bin_cur
					DEALLOCATE lot_bin_cur

					-- 'Unable to pick: Insert into #adm_pick_ship failed.'
					SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -104 AND language = @language 
					RETURN -2
				END

				-- 3. Call the pick stored procedure
				EXEC @err = tdc_adm_pick_ship
			
				IF (@err < 0) 
				BEGIN
					CLOSE	   lot_bin_cur
					DEALLOCATE lot_bin_cur

					-- 'Unable to pick: tdc_adm_pick_ship SP failed.'
					SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -105 AND language = @language
					RETURN -3 
				END

				-- 5. Change the allocated qty
				UPDATE tdc_soft_alloc_tbl 
				   SET qty = qty  - @qty
				 WHERE order_no   = @order_no
				   AND order_ext  = @order_ext
				   AND order_type = 'S'
				   AND line_no    = @line_no
				   AND part_no    = @part_no
				   AND lot_ser    = @lot_ser
				   AND bin_no     = @bin_no

				DELETE FROM tdc_soft_alloc_tbl 
				 WHERE order_no   = @order_no
				   AND order_ext  = @order_ext
				   AND order_type = 'S'
				   AND line_no    = @line_no
				   AND part_no    = @part_no
				   AND lot_ser    = @lot_ser
				   AND bin_no     = @bin_no
				   AND qty       <= 0
	
				DELETE FROM tdc_pick_queue 
				 WHERE trans_type_no   = @order_no 
				   AND trans_type_ext  = @order_ext
				   AND line_no    = @line_no
				   AND part_no    = @part_no
				   AND lot        = @lot_ser
				   AND bin_no     = @bin_no
				   AND qty_to_process <= 0
						
				IF (@@ERROR <> 0) 
				BEGIN
					CLOSE	   lot_bin_cur
					DEALLOCATE lot_bin_cur

					-- 'Unable to pick: update tdc_soft_alloc_tbl failed.'
					SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -106 AND language = @language
					RETURN -5 
				END

				-- 7. If the record exists in tdc_dist_item_pick, update the quantity
				--    If not, insert the record into the table
				IF EXISTS(SELECT *
			                    FROM tdc_dist_item_pick
			  	 	   WHERE method = '01'
					     AND order_no   = @order_no
				 	     AND order_ext  = @order_ext
				 	     AND line_no    = @line_no
				 	     AND part_no    = @part_no
					     AND [function] = 'S'
					     AND lot_ser    = @lot_ser
					     AND bin_no     = @bin_no)
				BEGIN
				    	UPDATE tdc_dist_item_pick 
				           SET quantity   = quantity +  @qty
				         WHERE method = '01'
					   AND order_no   = @order_no
				           AND order_ext  = @order_ext
				           AND line_no    = @line_no
				           AND part_no    = @part_no
					   AND [function] = 'S'
					   AND lot_ser    = @lot_ser
					   AND bin_no     = @bin_no
		
			        	IF (@@ERROR <> 0)
			        	BEGIN
						CLOSE	   lot_bin_cur
						DEALLOCATE lot_bin_cur

			            		-- 'Unable to pick: update tdc_dist_item_pick failed.'
						SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -108 AND language = @language
			            		RETURN -7
			        	END 
				END
				ELSE -- Record doesn't exist
				BEGIN
			            -- create new dist_item_pick record
			            EXEC @serial_no = tdc_get_serialno 
			
			            IF (@serial_no < 0)
			            BEGIN
					CLOSE	   lot_bin_cur
					DEALLOCATE lot_bin_cur

			                -- 'Unable to pick: tdc_get_serialno SP failed.'
					SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -109 AND language = @language
			                RETURN -8
			            END 

			            INSERT INTO tdc_dist_item_pick (method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, quantity, 
								    child_serial_no, [function], type, status)  
			            VALUES ('01', @order_no, @order_ext, @line_no, @part_no, @lot_ser, @bin_no, @qty, @serial_no, 'S', '01', NULL)
			
			            IF (@@ERROR <> 0)
			            BEGIN
					CLOSE	   lot_bin_cur
					DEALLOCATE lot_bin_cur

			                --  'Unable to pick: Insert into tdc_dist_item_pick failed.'
					SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -110 AND language = @language
			                RETURN -9
			            END 
				END	

				FETCH NEXT FROM lot_bin_cur INTO @lot_ser, @bin_no
			END
			CLOSE	   lot_bin_cur
			DEALLOCATE lot_bin_cur

		END -- TDC Serialized item
	END	    -- LB Tracked
	ELSE		-- Non LB Tracked
	BEGIN 
		-- 1. Insert part into temp table for picking
		INSERT INTO #adm_pick_ship (order_no, ext, line_no, part_no, bin_no, lot_ser, location, date_exp,     
					    qty, err_msg, who)  
		VALUES                     (@order_no , @order_ext, @line_no, @part_no,  NULL, NULL, @location, NULL, 
					    @qty, NULL,  @user_id)
		
		IF @@ERROR <> 0
		BEGIN
			-- 'Unable to pick: Insert into #adm_pick_ship failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -104 AND language = @language
			RETURN -10
		END

		-- 2. Call the pick stored procedure
		EXEC @err = tdc_adm_pick_ship
	
		IF (@err < 0) 
		BEGIN
			-- 'Unable to pick: tdc_adm_pick_ship SP failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -105 AND language = @language
			RETURN -11
		END

		-- 4. Change the allocated qty
		UPDATE tdc_soft_alloc_tbl 
		   SET qty = qty  - @qty
		 WHERE order_no   = @order_no
		   AND order_ext  = @order_ext
		   AND order_type = 'S'
		   AND line_no    = @line_no
		   AND part_no    = @part_no
		   AND lot_ser   IS NULL
		   AND bin_no    IS NULL

		DELETE FROM tdc_soft_alloc_tbl 
		 WHERE order_no   = @order_no
		   AND order_ext  = @order_ext
		   AND order_type = 'S'
		   AND line_no    = @line_no
		   AND part_no    = @part_no
		   AND lot_ser    IS NULL
		   AND bin_no     IS NULL
		   AND qty       <= 0

		DELETE FROM tdc_pick_queue 
		 WHERE trans_type_no   = @order_no 
		   AND trans_type_ext  = @order_ext
		   AND line_no    = @line_no
		   AND part_no    = @part_no
		   AND lot        IS NULL
		   AND bin_no     IS NULL
		   AND qty_to_process <= 0
		
		IF (@@ERROR <> 0) 
		BEGIN
			-- 'Unable to pick: update tdc_soft_alloc_tbl failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -106 AND language = @language
			RETURN -13
		END

		-- 6. If the record exists in tdc_dist_item_pick, update the quantity
		--    If not, insert the record into the table
		IF EXISTS(SELECT *
	                    FROM tdc_dist_item_pick
	  	 	   WHERE method = '01'
			     AND order_no   = @order_no
		 	     AND order_ext  = @order_ext
		 	     AND line_no    = @line_no
		 	     AND part_no    = @part_no
			     AND [function] = 'S'
			     AND lot_ser   IS NULL
			     AND bin_no    IS NULL)
		BEGIN
		    	UPDATE tdc_dist_item_pick 
		           SET quantity   = quantity +  @qty
		         WHERE method = '01'
			   AND order_no   = @order_no
		           AND order_ext  = @order_ext
		           AND line_no    = @line_no
		           AND part_no    = @part_no
			   AND [function] = 'S'
			   AND lot_ser   IS NULL
			   AND bin_no    IS NULL

	        	IF (@@ERROR <> 0)
	        	BEGIN
	            		-- 'Unable to pick: update tdc_dist_item_pick failed.'
				SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -108 AND language = @language
	            		RETURN -15
	        	END 
		END
		ELSE -- Record doesn't exist
		BEGIN
	            -- create new dist_item_pick record
	            EXEC @serial_no = tdc_get_serialno 
	
	            IF (@serial_no < 0)
	            BEGIN
	                -- 'Unable to pick: tdc_get_serialno SP failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -109 AND language = @language
	                RETURN -16
	            END 
	            
	            INSERT INTO tdc_dist_item_pick (method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, quantity, 
						    child_serial_no, [function], type)  
	            VALUES ('01', @order_no, @order_ext, @line_no, @part_no, NULL, NULL, @qty, @serial_no, 'S', '01')
	
	            IF (@@ERROR <> 0)
	            BEGIN
	                -- 'Unable to pick: Insert into tdc_dist_item_pick failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -110 AND language = @language
	                RETURN -17
	            END 
		END	
	END -- Non LB Tracked

	--  Update tdc_status in the tdc_order table
	UPDATE tdc_order SET tdc_status = 'O1' WHERE order_no = @order_no AND order_ext = @order_ext

	IF (@@ERROR <> 0) 
	BEGIN
		-- 'Unable to pick: tdc_set_status SP failed.'
		SELECT @error_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_packverify_pick_sp' AND err_no = -111 AND language = @language
		RETURN -18
	END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_packverify_pick_sp] TO [public]
GO
