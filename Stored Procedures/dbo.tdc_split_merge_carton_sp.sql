SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_split_merge_carton_sp]
	@order_no           int,
	@order_ext          int,
	@carton_no          int,
	@merge_split_flag   char(1),
	@station_id         varchar(25),
	@user_id            varchar(50)
AS

DECLARE @line_no  	    int,
	@pre_pack_qty  	    decimal(24,8),
	@split_qty   	    decimal(24,8),
	@merge_qty          decimal(24,8),
	@carton_no_to_merge int,
	@NewCarton_no	    int,
	@part_no  	    varchar(30),
	@lot_ser            varchar(25),
	@qty_to_pack        decimal(24,8),
	@insert_qty         decimal(24,8),
	@orgin_pre_pack_qty decimal(24,8),
	@orgin_packed_qty   decimal(24,8),
	@moved_qty          decimal(24,8)

BEGIN TRAN
	IF @merge_split_flag = 'S'
	BEGIN
		-- Generate a new carton no
		EXEC @NewCarton_no = tdc_get_serialno
		
		IF @NewCarton_no <= 0
		BEGIN
			ROLLBACK TRAN
			raiserror('Generating new Carton Number failed.', 16, 1)
			RETURN
		END

		INSERT INTO tdc_carton_tx (order_no, order_ext, carton_no, carton_type, carton_class, cust_code, carrier_code, ship_to_no,
					   [name], address1, address2, address3, city, zip, country, attention, weight,
					   weight_uom, operator, consolidated_pick_no, void, status, station_id, bill_to_key, last_modified_date,
					   modified_by, order_type, stl_status, changed)
		SELECT       @order_no, @order_ext, @NewCarton_no, NULL, NULL, cust_code, carrier_code, ship_to_no,
			     [name], address1, address2, address3,city, zip, country, attention, weight, 
			     weight_uom, operator, consolidated_pick_no, void, status, @station_id, bill_to_key, getdate(), 
			     modified_by, order_type, stl_status, changed
		  FROM tdc_carton_tx 
	         WHERE carton_no = @carton_no

		IF (@@ERROR <> 0)
		BEGIN
			

			ROLLBACK TRAN
			RAISERROR('Unable to split: Insert into tdc_carton_detail_tx failed.', 16, 1)
			RETURN
		END
	
		DECLARE line_cursor CURSOR FOR 
			SELECT part_no, line_no, qty 
		          FROM #split_merge
		         WHERE qty > 0
		
		OPEN line_cursor
		FETCH NEXT FROM line_cursor INTO @part_no, @line_no, @split_qty
		

		WHILE (@@FETCH_STATUS = 0)
		BEGIN		
			SELECT @moved_qty = @split_qty

			DECLARE lot_cursor CURSOR FOR 
				SELECT lot_ser, qty_to_pack
			          FROM tdc_carton_detail_tx
			         WHERE carton_no = @carton_no
				   AND line_no   = @line_no
				  ORDER BY qty_to_pack, lot_ser

			OPEN lot_cursor
			FETCH NEXT FROM lot_cursor INTO @lot_ser, @qty_to_pack
			
			WHILE (@@FETCH_STATUS = 0) OR (@split_qty > 0) 
			BEGIN
				-- Change the packed qty.	
				UPDATE tdc_carton_detail_tx 
				   SET qty_to_pack = CASE WHEN @qty_to_pack > @split_qty
							  THEN @qty_to_pack - @split_qty
							  ELSE 0
						     END
				 WHERE carton_no               = @carton_no
				   AND line_no                 = @line_no
				   AND ISNULL(lot_ser, '')     = ISNULL(@lot_ser, '')
	
				IF (@@ERROR <> 0)
				BEGIN
					CLOSE      lot_cursor
					DEALLOCATE lot_cursor
					CLOSE      line_cursor
					DEALLOCATE line_cursor

					ROLLBACK TRAN
					RAISERROR('Unable to split: Update tdc_carton_detail_tx failed.', 16, 1)
					RETURN
				END			

				----------------------------------------------------------------------------------------------------------------------------------------------------

				SELECT @insert_qty = CASE WHEN @qty_to_pack < @split_qty
							  THEN @qty_to_pack 
							  ELSE @split_qty
						     END

				INSERT INTO tdc_carton_detail_tx (order_no, order_ext, carton_no, tx_date, line_no, 
								  part_no, price, lot_ser, rec_date, pack_qty, status, 
								  warranty_track, qty_to_pack, pack_tx)
				SELECT @order_no, @order_ext, @NewCarton_no, GETDATE(), @line_no, @part_no,
				       b.price, @lot_ser, GETDATE(), 0, b.status, b.warranty_track, @insert_qty, 'Split'
				  FROM tdc_carton_detail_tx b(NOLOCK)
				 WHERE carton_no = @carton_no
				   AND line_no   = @line_no
                                   AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')

				IF (@@ERROR <> 0)
				BEGIN
					CLOSE      lot_cursor
					DEALLOCATE lot_cursor
					CLOSE      line_cursor
					DEALLOCATE line_cursor

					ROLLBACK TRAN
					RAISERROR('Unable to split: Insert into tdc_carton_detail_tx failed.', 16, 1)
					RETURN
				END

				SELECT @split_qty = @split_qty - @insert_qty
	
				SELECT @orgin_pre_pack_qty = qty_to_pack + @moved_qty, 
				       @orgin_packed_qty   = pack_qty
				 FROM tdc_carton_detail_tx(NOLOCK)
				WHERE carton_no = @carton_no
				  AND line_no   = @line_no
				  AND status IN ('O', 'P', 'Q')
	
				--------Inserts into tdc_split_merge_history-----------------------------------
				INSERT INTO tdc_split_merge_history(from_carton, to_carton, part_no, line_no,
							            lot_ser, serial_no, tx_date, type,
							            orgin_pre_pack_qty, orgin_packed_qty, moved_qty,
							            from_carton_printed, to_carton_printed)
				VALUES(@carton_no, @NewCarton_no, @part_no, @line_no, @lot_ser, 0, GETDATE(), 'S',
				       @orgin_pre_pack_qty, ISNULL(@orgin_packed_qty,''), @moved_qty, 'N', 'N')
	
				IF (@@ERROR <> 0)
				BEGIN
					CLOSE      lot_cursor
					DEALLOCATE lot_cursor
					CLOSE      line_cursor
					DEALLOCATE line_cursor
	
					RAISERROR('Insert into tdc_split_merge_history failed.', 16, 1)
					RETURN
				END
				---------------------------------------------------------------------------

				FETCH NEXT FROM lot_cursor INTO @lot_ser, @qty_to_pack
			END

			CLOSE      lot_cursor
			DEALLOCATE lot_cursor

			FETCH NEXT FROM line_cursor INTO @part_no, @line_no, @split_qty
		END	
	END
	ELSE -- Merge
	BEGIN
		DECLARE line_cursor CURSOR FOR 
			SELECT part_no, line_no, qty, NewCarton
			  FROM #split_merge 
			 WHERE qty > 0
		
		OPEN line_cursor
		FETCH NEXT FROM line_cursor INTO @part_no, @line_no, @merge_qty, @carton_no_to_merge
		
		WHILE (@@FETCH_STATUS <> -1)
		BEGIN	
			SELECT @moved_qty = @merge_qty
			
			DECLARE lot_cursor CURSOR FOR 
				SELECT lot_ser, qty_to_pack
			          FROM tdc_carton_detail_tx
			         WHERE carton_no = @carton_no
				   AND line_no   = @line_no
				 ORDER BY qty_to_pack, lot_ser

			OPEN lot_cursor
			FETCH NEXT FROM lot_cursor INTO @lot_ser, @qty_to_pack
			
			WHILE (@@FETCH_STATUS = 0) OR (@merge_qty > 0) 
			BEGIN
				-- Change the qty to pack.	
				UPDATE tdc_carton_detail_tx 
				   SET qty_to_pack = CASE WHEN @qty_to_pack > @merge_qty
							  THEN @qty_to_pack - @merge_qty
							  ELSE 0
						     END
				 WHERE carton_no               = @carton_no
				   AND line_no                 = @line_no
				   AND ISNULL(lot_ser, '')     = ISNULL(@lot_ser, '')
	
				IF (@@ERROR <> 0)
				BEGIN
					CLOSE      lot_cursor
					DEALLOCATE lot_cursor
					CLOSE      line_cursor
					DEALLOCATE line_cursor

					ROLLBACK TRAN
					RAISERROR('Unable to merge: Update tdc_carton_detail_tx failed.', 16, 1)
					RETURN
				END

				SELECT @insert_qty = CASE WHEN @qty_to_pack < @merge_qty
							  THEN @qty_to_pack 
							  ELSE @merge_qty
						     END

				IF EXISTS(SELECT * FROM tdc_carton_detail_tx (NOLOCK)
					   WHERE carton_no           = @carton_no_to_merge
					     AND line_no             = @line_no
					     AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
					  ) 
				BEGIN
					UPDATE tdc_carton_detail_tx 
					   SET qty_to_pack         = qty_to_pack + @insert_qty 
				         WHERE carton_no           = @carton_no_to_merge
					   AND line_no             = @line_no
					   AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '') 

					IF (@@ERROR <> 0)
					BEGIN
						CLOSE      lot_cursor
						DEALLOCATE lot_cursor
						CLOSE      line_cursor
						DEALLOCATE line_cursor
	
						ROLLBACK TRAN
						RAISERROR('Unable to merge: Update tdc_carton_detail_tx failed.', 16, 1)
						RETURN
					END
				END
				ELSE  -- Record doesn't exist
				BEGIN		
					INSERT INTO tdc_carton_detail_tx(order_no, order_ext, carton_no, tx_date, line_no, part_no,
									 price, lot_ser, rec_date, pack_qty, status, warranty_track, qty_to_pack, pack_tx)
					SELECT @order_no, @order_ext, @carton_no_to_merge, GETDATE(), @line_no, @part_no, b.price, @lot_ser,
					       GETDATE(), 0, b.status, b.warranty_track, @insert_qty, 'Merge'
					  FROM tdc_carton_detail_tx b(NOLOCK)
				         WHERE carton_no = @carton_no 
					   AND line_no   = @line_no
				
					IF (@@ROWCOUNT < 1)
					BEGIN
						CLOSE      line_cursor
						DEALLOCATE line_cursor
						CLOSE      lot_cursor
						DEALLOCATE lot_cursor
	
						ROLLBACK TRAN
						RAISERROR('Unable to merge: Insert into tdc_carton_detail_tx failed.', 16, 1)
						RETURN
					END
				END	-- Record doesn't exist
				
				SELECT @merge_qty = @merge_qty - @insert_qty


				SELECT @orgin_pre_pack_qty = qty_to_pack + @moved_qty, 
	                               @orgin_packed_qty   = pack_qty
				  FROM tdc_carton_detail_tx(NOLOCK)
				 WHERE carton_no = @carton_no
				   AND line_no   = @line_no
				   AND status IN ('O', 'P', 'Q')

				------------Inserts into tdc_split_merge_history table-------------------------
				INSERT INTO tdc_split_merge_history(from_carton, to_carton, part_no, line_no,
							            lot_ser, serial_no, tx_date, type,
							            orgin_pre_pack_qty, orgin_packed_qty, moved_qty)
				VALUES(@carton_no, @carton_no_to_merge, @part_no, @line_no, @lot_ser, 0, GETDATE(), 'M',
				       @orgin_pre_pack_qty, ISNULL(@orgin_packed_qty,''), @moved_qty) 
	
				IF (@@ERROR <> 0)
				BEGIN
					CLOSE      lot_cursor
					DEALLOCATE lot_cursor
					CLOSE      line_cursor
					DEALLOCATE line_cursor
	
					--ROLLBACK TRAN
					RAISERROR('Insert into tdc_split_merge_history failed.', 16, 1)
					RETURN
				END
				---------------------------------------------------------------------------

				FETCH NEXT FROM lot_cursor INTO @lot_ser, @qty_to_pack
			END

			CLOSE      lot_cursor
			DEALLOCATE lot_cursor				
							
			FETCH NEXT FROM line_cursor INTO @part_no, @line_no, @merge_qty, @carton_no_to_merge
		END
	
		
	END-- Merge

	CLOSE	   line_cursor
	DEALLOCATE line_cursor

	-- Get rid of the cartons that have qty_to_pack = 0
	DELETE FROM tdc_carton_detail_tx
	 WHERE order_no    = @order_no
           AND order_ext   = @order_ext
           AND qty_to_pack = 0

	DELETE FROM tdc_carton_tx        
	 WHERE order_no    = @order_no
           AND order_ext   = @order_ext
	   AND carton_no   NOT IN (SELECT carton_no 
				     FROM tdc_carton_detail_tx
				    WHERE order_no  = @order_no
			              AND order_ext = @order_ext)

COMMIT TRAN	

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_split_merge_carton_sp] TO [public]
GO
