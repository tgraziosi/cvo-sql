SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
																
/****************************************************************/
/* Ship Verify Xfer - This sp will take as input one xfer	*/
/* number in the #dist_ship_verify_x table and will return 	*/
/* zero for success and a negative value for failure.  On	*/
/* failure a negative value is returned and the err_msg field 	*/
/* is updated.							*/
/* if pcs flag is on this sp also verify the xfer # which is	*/
/* picked from either child id or parent id for parent level 	*/
/* pick								*/
/* Send to tdc_adm_ship_xfer stored procedure			*/
/*								*/
/* NOTE: This SP is designed to only process a #dist_group with */
/* one row of data						*/
/*								*/
/****************************************************************/
/* 10/12/1998	Initial turn by HTL				*/
/*		Ship Verify Transfer Pick Transaction		*/
/****************************************************************/

CREATE PROCEDURE [dbo].[tdc_ship_verify_xfer_sp]
AS
				
	CREATE TABLE #adm_ship_xfer (
		xfer_no int not null,
		part_no varchar(30) not null,
		bin_no varchar(12) null,
		lot_ser varchar(25) null,
		date_exp datetime null,
		qty decimal(20,8) not null,
		who varchar(50) null,		
		err_msg varchar(255) null,
		row_id int identity not null
	)

	CREATE TABLE #temp_group(
		parent_serial_no int not null,
		child_serial_no int not null)

	CREATE TABLE #temp_table(
		parent_serial_no int not null,
		child_serial_no int not null)

	DECLARE @err int, @xfer int, @method char(2)
	DECLARE @temp_child int, @temp_line int
	DECLARE @quantity decimal(20, 8), @temp_err varchar(255), @userid varchar(20)
	DECLARE @part_no varchar(30), @lot_ser varchar(30), @bin_no varchar(30)
	DECLARE @date_exp datetime, @status char(2), @language varchar(10)
	DECLARE @lb_track varchar(2), @loc varchar(10), @msg varchar(255)
	DECLARE @x1 decimal(20, 8), @x2 decimal(20, 8)

	/* Initialize the error code to no errors */
	SELECT @err = 0
	SELECT @userid = who FROM #temp_who

	/* Populate Variables */
	SELECT @xfer = xfer_no, @method = method FROM #dist_ship_verify_x

	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @userid), 'us_english')

	/* Verify that nothing on this xfer# has been ship verified */
	DECLARE item_cursor CURSOR FOR 
		SELECT child_serial_no, line_no FROM tdc_dist_item_pick 
						WHERE method = @method AND order_no = @xfer AND [function] = 'T'
	OPEN item_cursor
	FETCH NEXT FROM item_cursor INTO @temp_child, @temp_line

BEGIN TRAN

	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF (@@FETCH_STATUS <> -2)
		BEGIN
			SELECT @lb_track = lb_tracking FROM xfer_list (nolock) WHERE xfer_no = @xfer AND line_no = @temp_line
			SELECT @part_no	 = ( SELECT DISTINCT part_no FROM tdc_dist_item_pick (nolock)
								WHERE order_no = @xfer 
								AND child_serial_no = @temp_child AND line_no = @temp_line 
								AND [function] = 'T' AND method = @method )
			IF @lb_track = 'Y'
			BEGIN
				SELECT @bin_no = bin_no, @lot_ser = lot_ser   
					FROM tdc_dist_item_pick (nolock)
						WHERE order_no = @xfer AND child_serial_no = @temp_child 
						AND line_no = @temp_line AND [function] = 'T' AND method = @method
			END
			/* when pcs flag is no it is OK for pick ship verify method */
			IF NOT EXISTS (SELECT * FROM tdc_dist_group (nolock) WHERE child_serial_no = @temp_child AND [function] = 'T'
														AND method = @method)

			BEGIN	/* when picking from pcs parent level, if the parent id is a child id the status must be 'C' */
				IF EXISTS (SELECT * FROM tdc_dist_item_pick (nolock)
							WHERE child_serial_no = @temp_child AND [function] = 'T'
							AND method = @method AND status = 'V')
				BEGIN
					DEALLOCATE item_cursor
					ROLLBACK TRAN
			
					-- 'This transfer has been verified'
					SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_verify_xfer_sp' AND err_no = -101 AND language = @language						
					RAISERROR (@msg, 16, 1)					
       					RETURN -101
				END	
				IF EXISTS (SELECT * FROM tdc_dist_item_pick (nolock)
							WHERE child_serial_no = @temp_child AND [function] = 'T'
							AND method = @method AND status is NULL AND quantity > 0)
				BEGIN
					DEALLOCATE item_cursor
					ROLLBACK TRAN							
			
					-- 'This transfer must be cartonized before verifing'
					SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_verify_xfer_sp' AND err_no = -102 AND language = @language
					RAISERROR (@msg, 16, 1)					
       					RETURN -102
				END	
				/* get quantity from tdc_dist_item_pick table */
				SELECT @quantity = (SELECT SUM(quantity) FROM tdc_dist_item_pick (nolock)
										WHERE child_serial_no = @temp_child AND status = 'C' AND line_no = @temp_line
										AND [function] = 'T' AND method = @method)
			END
			ELSE	
			BEGIN
				DECLARE check_status CURSOR FOR 
					SELECT g.status FROM tdc_dist_group g, tdc_dist_item_pick i 
							WHERE i.order_no = @xfer AND i.child_serial_no = @temp_child 
							AND i.[function] = 'T' AND g.[function] = 'T' AND i.method = @method 
							AND i.child_serial_no = g.child_serial_no AND g.method = @method
	
				OPEN check_status
				FETCH NEXT FROM check_status INTO @status

				WHILE (@@FETCH_STATUS = 0)
				BEGIN
					IF @status = 'V'
					BEGIN						
						DEALLOCATE check_status
						DEALLOCATE item_cursor

						ROLLBACK TRAN

						--'This Transfer has been verified'
						SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_verify_xfer_sp' AND err_no = -101 AND language = @language
						RAISERROR (@msg, 16, 1)
       						RETURN -101
					END	
				
					IF @status = 'O'
					BEGIN						
						DEALLOCATE check_status
						DEALLOCATE item_cursor

						ROLLBACK TRAN

						-- 'This Transfer is open'
						SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_verify_xfer_sp' AND err_no = -103 AND language = @language
						RAISERROR (@msg, 16, 1)	
       						RETURN -103
					END	
					FETCH NEXT FROM check_status INTO @status
				END

				DEALLOCATE check_status
			
				/* get quantity from tdc_dist_group table */
				SELECT @quantity = (SELECT sum(g.quantity) FROM tdc_dist_group g, tdc_dist_item_pick i 
										WHERE i.order_no = @xfer AND i.child_serial_no = @temp_child 
										AND i.[function] = 'T' AND g.[function] = 'T' AND i.method = @method 
										AND i.child_serial_no = g.child_serial_no AND g.method = @method)
			END
			IF (@lb_track = 'Y')
			BEGIN
				SELECT @loc = (SELECT DISTINCT from_loc FROM xfer_list (nolock) WHERE xfer_no = @xfer)
				SELECT @date_exp = (SELECT DISTINCT date_expires 
							FROM lot_bin_xfer (nolock)
					    			WHERE tran_no = @xfer AND location = @loc 
								AND part_no = @part_no AND lot_ser = @lot_ser 
								AND bin_no = @bin_no AND line_no = @temp_line)

				INSERT INTO #adm_ship_xfer (xfer_no, part_no, bin_no, lot_ser, date_exp, qty, who, err_msg)
						VALUES (@xfer, @part_no, @bin_no, @lot_ser, @date_exp, @quantity, @userid, NULL)
			END
			ELSE
			BEGIN
				INSERT INTO #adm_ship_xfer (xfer_no, part_no, bin_no, lot_ser, date_exp, qty, who, err_msg)
						VALUES (@xfer, @part_no, NULL, NULL, NULL, @quantity, @userid, NULL)
			END
		END

		FETCH NEXT FROM item_cursor INTO @temp_child, @temp_line
	END

	DEALLOCATE item_cursor

	DECLARE part_cursor CURSOR FOR 
		SELECT part_no FROM xfer_list WHERE xfer_no = @xfer 
								
	OPEN part_cursor

	FETCH NEXT FROM part_cursor INTO @part_no
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF NOT EXISTS (SELECT * FROM #adm_ship_xfer WHERE xfer_no = @xfer AND part_no = @part_no)
			SELECT @x1 = 0
		ELSE
			SELECT @x1 = (SELECT SUM(qty) FROM #adm_ship_xfer WHERE xfer_no = @xfer AND part_no = @part_no)

		SELECT @x2 = (SELECT SUM(shipped) FROM xfer_list (nolock) WHERE part_no = @part_no AND xfer_no = @xfer) 
	
		IF (@x1 <> @x2)
		BEGIN
			DEALLOCATE part_cursor
			ROLLBACK TRAN			

			-- 'The verified qty must be equal to the shipped qty'
			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_verify_xfer_sp' AND err_no = -104 AND language = @language
			RAISERROR (@msg, 16, 1)
       			RETURN -104
		END
		FETCH NEXT FROM part_cursor INTO @part_no
	END	

	DEALLOCATE part_cursor

	EXEC @err = tdc_adm_ship_xfer	

	IF (@err < 0)
	BEGIN
	--	SELECT @temp_err = (SELECT min(err_msg) FROM #adm_ship_xfer WHERE xfer_no = @xfer)
		IF (@@TRANCOUNT > 0) ROLLBACK TRAN
	--	SELECT @err = -106
	--	UPDATE #dist_ship_verify_x SET err_msg = @temp_err WHERE xfer_no = @xfer
		RETURN @err
	END
	ELSE
	BEGIN
		/* Update ADM status */
		EXEC tdc_set_xfer_status @xfer, 'R1'

		TRUNCATE TABLE #adm_ship_xfer
	END

	UPDATE tdc_dist_item_pick SET status = 'V' WHERE order_no = @xfer AND [function] = 'T' 

	INSERT INTO #temp_group (parent_serial_no, child_serial_no) 
		SELECT g.parent_serial_no, g.child_serial_no 
			FROM tdc_dist_item_pick i, tdc_dist_group g 
				WHERE i.order_no = @xfer AND i.[function] = 'T' AND g.[function] = 'T'
				AND g.child_serial_no = i.child_serial_no
							
	WHILE EXISTS (SELECT * FROM tdc_dist_group (nolock) WHERE child_serial_no IN (SELECT DISTINCT parent_serial_no FROM #temp_group))
	BEGIN
		INSERT INTO #temp_table (parent_serial_no, child_serial_no)
				SELECT parent_serial_no, child_serial_no 
					FROM tdc_dist_group (nolock)
						WHERE [function] = 'T' AND child_serial_no in 
							(SELECT DISTINCT parent_serial_no FROM #temp_group)

		DELETE FROM #temp_table WHERE parent_serial_no IN (SELECT DISTINCT parent_serial_no FROM #temp_group)
							AND child_serial_no IN (SELECT DISTINCT child_serial_no FROM #temp_group)

		IF EXISTS (SELECT * FROM #temp_table)
			INSERT INTO #temp_group (parent_serial_no, child_serial_no)
						SELECT parent_serial_no, child_serial_no FROM #temp_table
		ELSE
			BREAK
	END

	UPDATE tdc_dist_group 
		SET status = 'V' 
			WHERE [function] = 'T' 
			AND parent_serial_no IN (SELECT DISTINCT parent_serial_no FROM #temp_group)
			AND child_serial_no IN (SELECT DISTINCT child_serial_no FROM #temp_group)

	UPDATE tdc_serial_no_track 
	SET location = transfer_location, last_trans = 'STDXSHVF', Date_time = getdate(), [User_id] = @userid
	WHERE last_tx_control_no = @xfer AND last_trans = 'TPACK'

COMMIT TRAN

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_ship_verify_xfer_sp] TO [public]
GO
