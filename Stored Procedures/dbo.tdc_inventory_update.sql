SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.tdc_inventory_update    Script Date: 3/29/99 10:27:59 AM ******/
CREATE PROCEDURE [dbo].[tdc_inventory_update] (

	@location	varchar (10),
	@part_no	varchar (30),
	@lot_ser	varchar (25),
	@bin_no         varchar (12),
	@qty_from_lbs   decimal (20,8),
	@delta_qty      decimal (20,8),
	@direction      smallint,
	@tran_no        int
) 
AS


/* Declare local variables */
DECLARE @qty_left_after_move	decimal (20,8)	
DECLARE @qty_reserved           decimal (20,8)
DECLARE @lbt_check              int
DECLARE @cnt                    int 
DECLARE @BYPASS                 int
DECLARE @active			char (1)
DECLARE @replen_min		int

DECLARE	@q_tran_id1 int,
	@q_tran_id2 int,
	@q_qty decimal(20, 8)
/*
 * This procedure uses parameters from a trigger on Platinums side off the lot_bin_tran
 * table.  This stored Procedure will check our tdc_bin_inventory_res table to make sure
 * for the part, lot, bin, location that if the user is trying to remove or transfer a 
 * quantity that the amount they are removing will not affect the amount eWarehouse has reserved
 * already. If it does we will send back the  negative  amount raising an error with the 
 * calling trigger on Platinum's side.  
 */


/* Initialize Vars */
SELECT @qty_left_after_move = 0 
SELECT @qty_reserved = 0 
SELECT @BYPASS = 6969

/*
if @tran_no = 1386417
begin
Return
End
*/

IF EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @tran_no AND ext = 0 AND type = 'C' AND status > 'R')
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_bin_master (nolock) WHERE location = @location AND bin_no = @bin_no AND status = 'A')
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		RAISERROR 84902 'Invalid Inventory Update.  Inventory controlled by Supply Chain Execution.'	
		RETURN 0
	END

	UPDATE tdc_serial_no_track
	   SET last_control_type = '0', date_time = getdate()
	 WHERE last_trans = 'CRRETN' 
	   AND last_tx_control_no = @tran_no 
	   AND last_control_type = 'H'

	--This handles merging records if the COMBINE_CRPTWY flag is set
	-- AND auto-posting is turned off.  If auto-posting is on,
	-- this is handled in tdc_queue_cred_ret_sp.
	
	--This checks for the tdc_config flag
	IF EXISTS (SELECT * FROM tdc_config WHERE [function] = 'COMBINE_CRPTWY' AND active='Y')
	BEGIN
		DECLARE queue_cursor CURSOR FOR
			SELECT tran_id
			  FROM tdc_put_queue
			 WHERE trans_source = 'CO' 
			   AND trans = 'CRPTWY' 
			   AND trans_type_no = cast(@tran_no as varchar(16)) 
			   AND tx_lock = 'Q'
		
		OPEN queue_cursor
		FETCH NEXT FROM queue_cursor INTO @q_tran_id1

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SELECT @q_tran_id2 = ISNULL((SELECT MAX(b.tran_id )
						       FROM tdc_put_queue a, tdc_put_queue b
						      WHERE a.location = b.location
							AND a.part_no = b.part_no
							AND a.lot = b.lot
							AND a.bin_no = b.bin_no
							AND a.tran_id = @q_tran_id1
							AND b.tran_id <> @q_tran_id1
							AND b.trans_source = 'CO'
							AND b.trans = 'CRPTWY'
							AND b.tx_lock = 'R'), -1)  --SCR 2873 CNASH 06/04/04
									
			IF (@q_tran_id2 <> -1)
			BEGIN	--found a matching queue record.  Perform merge
			--	UPDATE tdc_put_queue
			--		SET tdc_put_queue.qty_to_process = tdc_put_queue.qty_to_process + a.qty_to_process
			--		FROM tdc_put_queue a, tdc_put_queue
			--		WHERE a.tran_id = @q_tran_id1
			--		AND tdc_put_queue.tran_id = @q_tran_id2
			
				SELECT @q_qty = qty_to_process FROM tdc_put_queue where tran_id = @q_tran_id1
				
				UPDATE tdc_put_queue 
				   SET qty_to_process = qty_to_process + @q_qty  
				 WHERE tran_id = @q_tran_id2
					
				DELETE FROM tdc_put_queue WHERE tran_id = @q_tran_id1
			END
			ELSE	--no matching queue record found.  just unlock this one.
				UPDATE tdc_put_queue SET tx_lock = 'R' WHERE tran_id = @q_tran_id1
				
			FETCH NEXT FROM queue_cursor INTO @q_tran_id1
		END

		CLOSE queue_cursor
		DEALLOCATE queue_cursor
	END 
	ELSE --Merge flag is not set, so just unlock all the queue records. for this credit return
	BEGIN
		UPDATE tdc_put_queue 
		   SET tx_lock = 'R', date_time = getdate()
		 WHERE trans_source = 'CO' 
		   AND trans = 'CRPTWY' 
		   AND trans_type_no = cast(@tran_no as varchar(16)) 
		   AND tx_lock = 'Q'
	END

	RETURN 0
END
--BEGIN SED005 -- Custom Frames
--JVM 06/14/2010
--IF (SYSTEM_USER <> 'tdcsql')
-- Temporary change to allow use of backoffice UI for receiving transfers that were not auto- received when shipped - DMOON

IF (SYSTEM_USER <> 'tdcsql') AND (NOT EXISTS(SELECT * FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv')) AND
(NOT EXISTS(SELECT * FROM dbo.lot_bin_tran WHERE tran_no = @tran_no and tran_code = 'T')) -- DMOON 2/24/2011
--END   SED005
BEGIN
	IF @@TRANCOUNT > 0 ROLLBACK TRAN

	RAISERROR 84902 'Invalid Inventory Update.  Inventory controlled by Supply Chain Execution.'	
	RETURN 0
END


/*Logic that follows is for auto bin replenish */


	IF EXISTS (SELECT * 
			 FROM tdc_config (NOLOCK) 
			WHERE [function] IN ('alloc_bin_sort_so', 'alloc_bin_sort_wo', 'alloc_bin_sort_xfer') 
			  AND active = 'Y' 
			  AND value_str = 'REPLENISH') 
	BEGIN
		 IF EXISTS (SELECT * 
				  FROM tdc_bin_replenishment (NOLOCK) 
				 WHERE location = @location 
				   AND bin_no = @bin_no 
				   AND part_no = @part_no 
						   AND auto_replen = 1  
				   AND replenish_min_lvl IS NOT NULL 
				   AND replenish_max_lvl IS NOT NULL
				   AND replenish_qty IS NOT NULL 
				   AND replenish_min_lvl >= @qty_from_lbs)
		BEGIN
			EXEC tdc_automatic_bin_replenish @location, @part_no, @bin_no, @delta_qty, @qty_from_lbs
		END /* End if this bin is setup for auto replenish */
	END   /* end if direction = -1 and auto replenish is turned on */


RETURN @qty_left_after_move



GO
GRANT EXECUTE ON  [dbo].[tdc_inventory_update] TO [public]
GO
