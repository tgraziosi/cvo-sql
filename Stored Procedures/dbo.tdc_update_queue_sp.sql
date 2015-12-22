SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 -- Custom Frame Processing -- Take STDPICK record off of hold when processing the MGTB2B
-- v1.1 CB 25/03/2011 - 13.Ship Complete - Reset the mfg_lot field - Used for SC holds
-- v1.2 CB 14/06/2011 - Release additional hold items for substituted frames
-- v1.3 CT 26/07/2012 - Call routine to update autpack carton info
-- v1.4 CB 17/10/2012 - Issue #949 - Only release the custom frame pick once all bin to bin moves have been done
-- v1.5 CB 12/06/2013 - Issue #965 - Tax Calculation
-- v1.6 CB 12/09/2013 - Move tax calculation to a queued job
/************************************************************************/
/* Name:	tdc_update_queue_sp		      	      		*/
/*									*/
/* Module:	WMS							*/
/*						      			*/
/* Input:						      		*/
/*	tran_id   - 	USER ID	Transaction ID		      		*/
/*	act_qty   - 	Quantity actually picked/ available    		*/
/* Output:        					     	 	*/
/*	errmsg	-	Null IF no errors		     	 	*/
/*									*/
/* Description:								*/
/*	This SP updates the the queue and the tdc_soft_alloc_tbl	*/
/*	after a bINTobin  or picking transcation has been completed  	*/
/*	from the queue.							*/
/* Revision History:							*/
/* 	Date		Who	Description				*/
/*	----		---	-----------				*/
/* 	12/03/1999	KMH	Initial					*/
/*	05/03/2000	KMH	bug fix - IF 2  pick transactions 	*/
/*				exsisted for the same part for the same */
/*				order but 2 different bins, we were 	*/
/*				gettting a negative qty, beacause the 	*/
/*				where clause for our updates weren't 	*/
/*				inclusive enough.			*/
/*	05/08/2000	KMH	moved some variable definitions outside */
/*				of a loop to fix errors  		*/
/*	07/11/2000	IA	changed error return. 	 		*/
/*				Deleted COMMIT/ROLLBACK TRAN, because 	*/
/*				there wasn't BEGIN TRAN		 	*/
/*	08/23/2000	IA	Pass line_no as parameter		*/
/*				to fis tdc_soft_alloc tbl update 	*/
/*				[STDPICK] Tx			 	*/
/*	08/25/2000	IA	[STDPICK] Tx: update queue 		*/
/*				qty_to_process only on  delete from 	*/
/*                              tdc_soft_alloc_tbl, because of on update*/
/*				tdc_soft_alloc_tbl trigger updates 	*/
/*				qty_to_process in the queue		*/
/*	01/24/2001	DM	[PLWB2B] Tx: ran INTo problem with Lason*/
/*				where records in soft_alloc with same   */
/*				location, part, lot, bin; so need to 	*/
/*				loop thru line by line.			*/
/************************************************************************/


CREATE PROCEDURE [dbo].[tdc_update_queue_sp](
  @tran_id 	INT,
  @act_qty 	decimal(20,8),
  @line_no	INT
)
AS

DECLARE @trans VARCHAR (10),
	@order_no INT,
	@order_ext INT,
	@seq_no INT,
	@cons INT,
	@location VARCHAR (10),
	@part_no VARCHAR (30),
	@temp_part VARCHAR (30),
	@from_bin VARCHAR (12),
	@target_bin VARCHAR (30),
	@dest_bin VARCHAR (30),
	@lot_ser VARCHAR (25),	
	@total_qty DECIMAL(20,8),
	@order_qty DECIMAL(20,8),
	@record INT,
	@temp_qty DECIMAL(20,8),
	@AllocType VARCHAR(2),
	@order_type CHAR(1),
	@tx_lock CHAR(1),
	@q_priority int,
	@err_ret int -- v1.5

BEGIN 
	SELECT @q_priority = 5
	SELECT @q_priority = CAST(value_str AS INT) FROM tdc_config(NOLOCK) where [function] = 'Pick_Q_Priority'
	IF @q_priority IN ('', 0)
		SELECT @q_priority = 5

	SELECT 	@trans = trans, @order_no = trans_type_no, @cons = trans_type_no, @order_ext = trans_type_ext, 
		@total_qty = qty_to_process, @part_no = part_no, 
		@from_bin = bin_no, @lot_ser = lot, @target_bin = next_op, @location = location  
	  FROM tdc_pick_queue (nolock)
	 WHERE tran_id = @tran_id

	SELECT @tx_lock = 'R'
	IF EXISTS(SELECT * 
		    FROM tdc_pick_queue pq (nolock), tdc_cons_ords co (nolock)
		   WHERE pq.trans_type_no = co.order_no
		     AND pq.trans_type_ext = co.order_ext
		     AND co.alloc_type = 'PP'
	             AND tran_id = @tran_id)
		SELECT @tx_lock = '3'

	IF(@trans = 'WOPPICK')
	BEGIN
		IF NOT EXISTS (SELECT * FROM tdc_config (nolock) WHERE [function] = 'AllowQWOOverPick' AND active = 'Y')
		BEGIN
			IF (@act_qty > @total_qty) --qty too large			
				RETURN -1
		END

		IF (@lot_ser IS NULL)
			UPDATE tdc_soft_alloc_tbl 
			   SET qty = (qty - @act_qty) 
			 WHERE order_no = @cons 
			   AND order_ext = @order_ext 
			   AND part_no = @part_no 				
			   AND line_no = @line_no 				
        		   AND dest_bin = @target_bin
			   AND order_type = 'W'
		ELSE
			UPDATE tdc_soft_alloc_tbl 
			   SET qty = (qty - @act_qty) 
			 WHERE order_no = @cons 
			   AND order_ext = @order_ext 
			   AND part_no = @part_no 
			   AND lot_ser = @lot_ser 
			   AND line_no = @line_no 
			   AND bin_no = @from_bin
 			   AND dest_bin = @target_bin
			   AND order_type = 'W'

		DELETE FROM tdc_pick_queue 
                 WHERE tran_id = @tran_id 
		   AND qty_to_process <= 0

		DELETE FROM tdc_soft_alloc_tbl 
		 WHERE order_no  = @order_no 
		   AND order_ext = @order_ext 
		   AND line_no   = @line_no
		   AND qty <= 0

		RETURN 100
	END

	IF (@trans = 'MGTB2B')
	BEGIN
		IF (@act_qty > @total_qty) --qty too large
		BEGIN
			RETURN -1
		END

		IF (@act_qty = @total_qty)
		BEGIN
			-- v1.0
			DECLARE	@tran_id_link int
			SELECT	@tran_id_link = ISNULL(tran_id_link,0)
			FROM	tdc_pick_queue
			WHERE	tran_id = @tran_id

			-- v1.1 Reset mfg_lot field
			-- v1.2
			IF @tran_id_link > 0
			BEGIN
				-- v1.4 Start
				IF NOT EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE tran_id_link = @tran_id_link and tran_id <> @tran_id)
				BEGIN
					UPDATE	tdc_pick_queue SET tx_lock = 'R', mfg_lot = NULL WHERE tran_id = @tran_id_link
					UPDATE	tdc_pick_queue SET tx_lock = 'R', mfg_lot = NULL, tran_id_link = NULL 
					WHERE	tran_id_link = @tran_id_link
				END
				-- v1.4 End
			END

			DELETE FROM tdc_pick_queue WHERE tran_id = @tran_id
		END
		ELSE
		BEGIN
			UPDATE tdc_pick_queue 
			   SET qty_to_process = (qty_to_process - @act_qty), 
			       qty_processed = (qty_processed + @act_qty) 
			 WHERE tran_id = @tran_id
		END

		UPDATE tdc_soft_alloc_tbl 
		   SET qty = (qty - @act_qty) 
		 WHERE order_no = 0 AND order_ext = 0 
	 	   AND part_no = @part_no 
		   AND lot_ser = @lot_ser 
		   AND line_no = 0 
		   AND bin_no = @from_bin
		   AND target_bin = @target_bin

		DELETE FROM tdc_soft_alloc_tbl
		 WHERE order_no = 0 
		   AND order_ext = 0
	  	   AND part_no = @part_no 
		   AND lot_ser = @lot_ser 
		   AND line_no = 0 
		--   AND bin_no = @from_bin
		--   AND target_bin = @target_bin
		   AND qty <= 0

		UPDATE tdc_pick_queue 
		   SET tx_lock = @tx_lock 
		 WHERE tran_id = @tran_id

		RETURN 100
	END
		
	IF (@trans = 'PLWB2B')
	BEGIN
		--Ensure not attempting to pick too much
		IF (@act_qty > @total_qty) --qty too large
		BEGIN
			RETURN -1
		END
		
		DECLARE line_info CURSOR FOR
			SELECT tsa.order_no, tsa.order_ext, tsa.line_no, tsa.qty, tsa.order_type, tsa.alloc_type
			FROM tdc_cons_ords tco
			INNER JOIN tdc_soft_alloc_tbl tsa
				ON tsa.order_no = tco.order_no 
				AND tsa.order_ext = tco.order_ext 
				AND tsa.location = tco.location
				AND tsa.order_type = tco.order_type
			WHERE tco.consolidation_no = @cons
			AND tco.location = @location 
			AND tsa.lot_ser = @lot_ser 
			AND tsa.part_no = @part_no 
			AND tsa.bin_no = @from_bin
			AND tsa.target_bin = @target_bin
		
		OPEN line_info
		FETCH NEXT FROM line_info INTO @order_no , @order_ext, @line_no, @order_qty, @order_type, @AllocType
		WHILE(@@FETCH_STATUS = 0 AND @act_qty > 0)
		BEGIN				
			SELECT @dest_bin = dest_bin FROM tdc_soft_alloc_tbl 
			WHERE 	order_no = @order_no 
				AND order_ext = @order_ext 
				AND part_no = @part_no 
				AND lot_ser = @lot_ser 
				AND line_no = @line_no 
				AND bin_no = @from_bin
				AND order_type = @order_type

			IF(@act_qty <= @order_qty)
			BEGIN
				UPDATE 	tdc_soft_alloc_tbl 
				SET 	qty = qty - @act_qty
				WHERE 	order_no = @order_no 
					AND order_ext = @order_ext 
					AND part_no = @part_no 
					AND lot_ser = @lot_ser 
					AND line_no = @line_no 
					AND bin_no = @from_bin
					AND target_bin = @target_bin
					AND order_type = @order_type

				UPDATE 	tdc_pick_queue 
				SET 	qty_to_process = qty_to_process - @act_qty, 
				    	qty_processed = qty_processed + @act_qty 
				WHERE 	tran_id = @tran_id

				IF (@@ERROR <> 0)
				BEGIN
					CLOSE line_info
					DEALLOCATE line_info				
					RETURN -2
				END

				IF EXISTS(SELECT * FROM tdc_soft_alloc_tbl 
					  WHERE order_no = @order_no 
						AND order_ext = @order_ext 
						AND part_no = @part_no 
						AND lot_ser = @lot_ser 
						AND line_no = @line_no 
						AND bin_no = @target_bin
						AND order_type = @order_type)
				BEGIN
					UPDATE 	tdc_soft_alloc_tbl 
					SET 	qty = qty + @act_qty
					WHERE 	order_no = @order_no 
						AND order_ext = @order_ext 
						AND part_no = @part_no 
						AND lot_ser = @lot_ser 
						AND line_no = @line_no 
						AND bin_no = @target_bin
						AND order_type = @order_type
					
					IF (@@ERROR <> 0)
					BEGIN
						CLOSE line_info
						DEALLOCATE line_info			
						RETURN -3
					END			
				END
				ELSE --not exist in tdc_soft_alloc_tbl
				BEGIN	
					INSERT INTO tdc_soft_alloc_tbl (order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin, trg_off, order_type, alloc_type, q_priority)
					VALUES (@order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @target_bin, @act_qty, @target_bin, @dest_bin, NULL, @order_type, @AllocType, @q_priority)

					IF (@@ERROR <> 0)
					BEGIN
						CLOSE line_info
						DEALLOCATE line_info			
						RETURN -5
					END
				END

				BREAK
			END	
			ELSE 	-- @act_qty > @order_qty
			BEGIN
				UPDATE 	tdc_soft_alloc_tbl 
				SET 	qty = qty - @order_qty
				WHERE 	order_no = @order_no 
					AND order_ext = @order_ext 
					AND part_no = @part_no 
					AND lot_ser = @lot_ser 
					AND line_no = @line_no 
					AND bin_no = @from_bin
					AND target_bin = @target_bin
					AND order_type = @order_type

				IF EXISTS(SELECT * FROM tdc_soft_alloc_tbl (NOLOCK) 
					  WHERE order_no = @order_no 
						AND order_ext = @order_ext 
						AND part_no = @part_no 
						AND lot_ser = @lot_ser 
						AND line_no = @line_no 
						AND bin_no  = @target_bin
						AND order_type = @order_type)
				BEGIN
					UPDATE 	tdc_soft_alloc_tbl 
					SET 	qty = qty + @order_qty
					WHERE 	order_no = @order_no 
						AND order_ext = @order_ext 
						AND part_no = @part_no 
						AND lot_ser = @lot_ser 
						AND line_no = @line_no 
						AND bin_no = @target_bin
						AND order_type = @order_type
				END
				ELSE --Not exist in the tdc_soft_alloc_tbl
				BEGIN
					INSERT INTO tdc_soft_alloc_tbl  (order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin, trg_off, order_type, alloc_type, q_priority) 
						VALUES (@order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @target_bin, @order_qty, @target_bin, @dest_bin, NULL, @order_type, @AllocType, @q_priority)

					IF (@@ERROR <> 0)
					BEGIN
						CLOSE line_info
						DEALLOCATE line_info

						RETURN -13
					END			
				END

				UPDATE 	tdc_pick_queue 
				SET 	qty_to_process = qty_to_process - @order_qty, 
					qty_processed = qty_processed + @order_qty
				WHERE 	tran_id = @tran_id

				IF (@@ERROR <> 0)
				BEGIN
					CLOSE line_info
					DEALLOCATE line_info

					RETURN -14
				END						
			END	
			
			SELECT @act_qty = @act_qty - @order_qty  --decrese the actual qty
 
			DELETE FROM tdc_soft_alloc_tbl 
				 WHERE order_no  = @order_no
				   AND order_ext = @order_ext
				   AND location  = @location
				   AND line_no   = @line_no
				   AND qty <= 0 

			FETCH NEXT FROM line_info INTO @order_no , @order_ext, @line_no, @order_qty, @order_type, @AllocType
		END

		CLOSE line_info
		DEALLOCATE line_info

		UPDATE tdc_pick_queue SET tx_lock = @tx_lock WHERE tran_id = @tran_id
		DELETE FROM tdc_pick_queue WHERE qty_to_process <= 0 AND tran_id = @tran_id

		DELETE FROM tdc_soft_alloc_tbl 
			 WHERE order_no  = @order_no
			   AND order_ext = @order_ext
			   AND location  = @location
			   AND qty <= 0 


		RETURN 100
	END

	IF (@trans = 'STDPICK') OR (@trans = 'XFERPICK') OR (@trans = 'PKGBLD') 
	BEGIN 
		IF (@trans = 'STDPICK') OR (@trans = 'PKGBLD')
			SELECT @order_type = 'S'
		
		IF (@trans = 'XFERPICK')
			SELECT @order_type = 'T'

		IF (@lot_ser is NULL)
		BEGIN 
			UPDATE tdc_soft_alloc_tbl 
			SET qty = qty - @act_qty
			WHERE order_no = @order_no 
			  AND order_ext = @order_ext 
			  AND line_no = @line_no
			  AND part_no = @part_no 
			  AND order_type = @order_type
		END 
		ELSE
		BEGIN 
			UPDATE tdc_soft_alloc_tbl 
			SET qty = qty - @act_qty
			WHERE order_no  = @order_no 
			  AND order_ext = @order_ext 
			  AND line_no   = @line_no
			  AND location  = @location 
			  AND lot_ser   = @lot_ser 
			  AND part_no   = @part_no
			  AND bin_no    = @from_bin
			  AND target_bin = @from_bin 
			  AND order_type = @order_type
		END

		DELETE FROM tdc_soft_alloc_tbl 
		 WHERE order_no  = @order_no
		   AND order_ext = @order_ext
		   AND location  = @location
		   AND line_no   = @line_no
		   AND qty <= 0 
			
		IF (@@ERROR <> 0) RETURN -17
		
		-- v1.3
		IF @trans = 'STDPICK'
		BEGIN
			EXEC CVO_autopack_carton_pick_sp @order_no = @order_no, @order_ext = @order_ext, @line_no = @line_no, @part_no =@part_no, @qty = @act_qty

			-- v1.5 Start
			IF NOT EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext AND trans = 'STDPICK')
			BEGIN
				-- v1.6 Start
				INSERT	dbo.cvo_calc_tax (order_no, order_ext, date_entered)
				VALUES	(@order_no, @order_ext, GETDATE())

--				EXEC dbo.fs_calculate_oetax @order_no, @order_ext, @err_ret OUT  
--				EXEC dbo.fs_updordtots @order_no, @order_ext     
				-- v1.6 End
			END
			-- v1.5 End  

		END

		RETURN 100
	END	 

	SELECT @total_qty = qty_to_process  FROM tdc_put_queue WHERE tran_id = @tran_id

	IF (@act_qty <= @total_qty)
	BEGIN
		UPDATE tdc_put_queue SET qty_to_process = (qty_to_process - @act_qty), qty_processed = (qty_processed + @act_qty), tx_lock = 'R' WHERE tran_id = @tran_id
		IF (@@ERROR <> 0)
		BEGIN
			RETURN -20
		END			
	END

	DELETE FROM tdc_put_queue WHERE tran_id = @tran_id AND qty_to_process <= 0
	IF (@@ERROR <> 0)
	BEGIN
		RETURN -21
	END	

RETURN 100

END
GO
GRANT EXECUTE ON  [dbo].[tdc_update_queue_sp] TO [public]
GO
