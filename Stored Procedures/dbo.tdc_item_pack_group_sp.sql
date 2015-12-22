SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*                        					*/
/* This SP is used to when moving inventory from the		*/
/* tdc_dist_item_pick table to the tdc_dist_group table		*/
/*								*/
/* NOTE: This SP is designed to only process a #dist_group with */
/*       one row of data					*/
/* NOTE: This SP leaves it up the the caller to validate the	*/
/*       parent is valid.					*/
/*								*/
/*								*/
/* 06/19/1998	Initial		GCJ				*/
/*								*/
/* 08/12/1998	Revision	CAC				*/
/*		Made modifications to handle non-LB tracked     */
/*		items correctly.  Also made modification to     */
/*		check if record exists in tdc_dist_group table  */
/*		and if so then use update, rather than insert.  */
/*								*/
/* 08/17/1998	Revision	GCJ				*/
/*		Defined Quantity as decimal (20, 8)		*/
/*								*/
/* 01/31/1999	Revision 	SHD				*/
/*		Need to pass order_ext to handle blanket order	*/

CREATE PROCEDURE [dbo].[tdc_item_pack_group_sp]
AS

DECLARE
	@recid 			int, 
	@err   			int,
	@available_qty		decimal(20,8),
	@temp_child 		int,
	@avail_qty_this_line	decimal(20,8),
	@done 			int, 
	@order_ext 		int,
	@line_no		int

DECLARE	@parent 	int,
	@method 	varchar(2),
	@order	 	int,
	@part 		varchar(30), 
	@lot 		varchar(25),
	@bin 		varchar(12),
	@qty		decimal(20,8),
	@type 		varchar(3),
	@new_type 	varchar(3),
	@reccnt 	int,
	@func		char(1),
	@Custom_kit 	int

DECLARE @language varchar(10), @msg varchar(100)
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

/* Initialize the error code to no errors */
SELECT @err = 0

/* Get the record */
SELECT @recid = 0

SELECT @recid = ISNULL((SELECT MIN(row_id) FROM #dist_group WHERE row_id > @recid),-1)

/* Verify there is a row of data in the #dist_group table */
IF @recid = -1 
BEGIN
	SELECT @err = -1
	-- 'No data in temp table'
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_item_pack_group_sp' AND err_no = -1 AND language = @language
	UPDATE #dist_group SET err_msg = @msg WHERE row_id = @recid
	return @err
END

/* Populate Variables */
SELECT @parent = (SELECT parent_serial_no FROM #dist_group where row_id = @recid)
SELECT @type   = (SELECT type FROM #dist_group where row_id = @recid)
SELECT @new_type   = (SELECT new_type FROM #dist_group where row_id = @recid)
SELECT @method = (SELECT method FROM #dist_group where row_id = @recid)
SELECT @order  = (SELECT order_no FROM #dist_group where row_id = @recid)
SELECT @order_ext = (SELECT order_ext FROM #dist_group where row_id = @recid)	
SELECT @part   = (SELECT part_no FROM #dist_group where row_id = @recid)
SELECT @lot    = (SELECT isNull(lot_ser, '') FROM #dist_group where row_id = @recid)
SELECT @bin    = (SELECT isNull(bin_no, '') FROM #dist_group where row_id = @recid)
SELECT @qty    = (SELECT quantity FROM #dist_group where row_id = @recid)
SELECT @func   = (SELECT [function] FROM #dist_group where row_id = @recid)
SELECT @line_no   = (SELECT line_no FROM #dist_group where row_id = @recid)

/* Verify there is enough quantity in tdc_dist_item_pick to meet this request before we start */
SELECT @available_qty =(SELECT SUM(quantity) FROM tdc_dist_item_pick 
WHERE method = @method 
AND order_no = @order 
AND order_ext = @order_ext
AND part_no = @part 
AND line_no = @line_no
AND isNull(lot_ser, '') = @lot 
AND isNull(bin_no, '') = @bin 
AND [function] = @func )

IF (@available_qty < @qty)
BEGIN
	SELECT @err = -2
	-- 'Qty has not been picked'
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_item_pack_group_sp' AND err_no = -2 AND language = @language
	UPDATE #dist_group SET err_msg = @msg WHERE row_id = @recid
	return @err
END

	/* We need to find the row in the tdc_dist_item_pick table that matches all	*/
	/* variables and has the greatest extension and lowest line number.  We pull	*/
	/* quantity from this child first.  If there there was not enough in this child	*/
	/* we decrement it to zero and get the next row.  We keep looping through until	*/
	/* we have allocated sufficent inventory. For each row in tdc_dist_item_pick we	*/
	/* decrement quantity we must create the new entry in tdc_dist_group.		*/

	/* NOTE: We may need to add a check here to only pull from MAX(order_ext)	*/

	DECLARE group_cursor CURSOR FOR 
		SELECT	child_serial_no, quantity FROM tdc_dist_item_pick 
		WHERE	method = @method 
			AND order_no = @order 
			AND order_ext = @order_ext
			AND line_no = @line_no
			AND isNull(lot_ser, '') = @lot 
			AND isNull(bin_no, '') = @bin 
			AND quantity > 0 
			AND [function] = @func
		ORDER BY line_no

	OPEN group_cursor

	SELECT @done = 0

	FETCH NEXT FROM group_cursor INTO @temp_child, @avail_qty_this_line
	WHILE ((@@FETCH_STATUS <> -1) AND (@done <> 1))
	BEGIN
		IF (@@FETCH_STATUS <> -2) /* Row changed */
		BEGIN
			IF (@qty <= @avail_qty_this_line)
			BEGIN
				IF EXISTS( SELECT * FROM inv_master WHERE part_no = @part AND lb_tracking = 'Y')
					UPDATE tdc_dist_item_pick SET quantity = quantity - @qty 
								WHERE child_serial_no = @temp_child
								AND [function] = @func
								AND line_no = @line_no
								AND lot_ser = @lot
								AND bin_no = @bin
				ELSE
					UPDATE tdc_dist_item_pick SET quantity = quantity - @qty 
								WHERE child_serial_no = @temp_child
								AND [function] = @func
								AND line_no = @line_no

				SELECT @reccnt =
				   	(SELECT count(*) 
				     FROM tdc_dist_group
				     WHERE method = @method
				       	AND type = @new_type
				      	AND parent_serial_no = @parent
				       	AND child_serial_no = @temp_child
				       	AND status = 'O'
					AND [function] = @func)
				
				if (@reccnt > 0)
				BEGIN
					UPDATE tdc_dist_group
					SET quantity = quantity + @qty
					WHERE method = @method
					AND type = @new_type
				       	AND parent_serial_no = @parent
				       	AND child_serial_no = @temp_child
				       	AND status = 'O'
					AND [function] = @func
				END
				ELSE
				BEGIN
					INSERT tdc_dist_group (method, type, parent_serial_no, child_serial_no, quantity, status, [function])
					VALUES (@method, @new_type, @parent, @temp_child, @qty, 'O', @func)
				END
	
				IF @func = 'S'
					UPDATE tdc_order SET tdc_status = @new_type WHERE order_no = @order AND order_ext = @order_ext
				ELSE
					UPDATE tdc_xfers SET tdc_status = @new_type WHERE xfer_no = @order
	
				SELECT @qty = 0
	
				SELECT @done = 1
			END
			ELSE
			BEGIN
				IF (@qty > @avail_qty_this_line)
				BEGIN
					UPDATE tdc_dist_item_pick 
						SET quantity = 0
						WHERE child_serial_no = @temp_child
							AND [function] = @func
							AND line_no = @line_no
	
					SELECT @reccnt =
				   		(SELECT count(*) 
				      		   	FROM tdc_dist_group
				     		  	WHERE method = @method
				       		    	AND type = @new_type
				        	    	AND parent_serial_no = @parent
				       		    	AND child_serial_no = @temp_child
				       		    	AND status = 'O'
							AND [function] = @func)
				
					if (@reccnt > 0)
					BEGIN
						UPDATE tdc_dist_group
					   	   	SET quantity = quantity + @avail_qty_this_line
					 	 	WHERE method = @method
					   	   	AND type = @new_type
				           	   	AND parent_serial_no = @parent
				           	   	AND child_serial_no = @temp_child
				           	  	AND status = 'O'
							AND [function] = @func
					END
					ELSE
					BEGIN
						INSERT tdc_dist_group (method, type, parent_serial_no, child_serial_no, quantity, status, [function])
						VALUES (@method, @new_type, @parent, @temp_child, @avail_qty_this_line, 'O', @func)
					END
		
					SELECT @qty = @qty - @avail_qty_this_line

					IF @func = 'S'
						UPDATE tdc_order SET tdc_status = @new_type WHERE order_no = @order AND order_ext = @order_ext
					ELSE
						UPDATE tdc_xfers SET tdc_status = @new_type WHERE xfer_no = @order

				END
			END
		END

		IF (@done <> 1)
		BEGIN
			FETCH NEXT FROM group_cursor INTO @temp_child, @avail_qty_this_line
		END
	END
	
	IF (@qty > 0)
	BEGIN

		SELECT @err = -3
		-- 'Qty not available'
		SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_item_pack_group_sp' AND err_no = -3 AND language = @language
		UPDATE #dist_group SET err_msg = @msg WHERE row_id = @recid

		DEALLOCATE group_cursor

		return @err
	END


	DEALLOCATE group_cursor

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_item_pack_group_sp] TO [public]
GO
