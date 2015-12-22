SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*                        												*/
/* This SP is used to undo what was done with tdc_item_group_sp. In 	*/
/* other words it will un-stage / un-carton or whatever came directly 	*/
/* after pick in the sequence.											*/
/*																		*/
/* NOTE: This SP is designed to only process a #dist_un_group with		*/
/*       one row of data												*/
/* NOTE: Assumes caller has verified the parent has not moved on to the	*/
/*	 next level															*/
/*																		*/
/* 06/24/1998	Initial		GCJ											*/
/*																		*/
/* 08/12/1998	Revised		CAC											*/
/*		Made changes to handle non-lot/bin tracked items        		*/
/*		correctly.														*/
/*																		*/
/* 08/17/1998	Revised		GCJ											*/
/*		Defined quantity as decimal (20, 8)								*/
/*																		*/

CREATE PROCEDURE [dbo].[tdc_item_pack_ungroup_sp]
AS

DECLARE @recid int, @err int, @available_qty decimal(20,8), @temp_child int, 
@avail_qty_this_row decimal(20,8), @done int, @line_no int
DECLARE @parent int, @method varchar(2), @order int, @order_ext int, @part varchar(30), @lot varchar(25), 
@bin varchar(12), @qty decimal(20,8), @type varchar(3), @func char (1)

DECLARE @language varchar(10), @msg varchar(100)
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

/* Initialize the error code to no errors */
SELECT @err = 0

/* Get the record */
SELECT @recid = 0

SELECT @recid = ISNULL((SELECT MIN(row_id) FROM #dist_un_group WHERE row_id > @recid),-1)

/* Verify there is a row of data in the #dist_un_group table */
IF @recid = -1 
BEGIN
	SELECT @err = -1
	-- 'No data in temp table'
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_item_pack_ungroup_sp' AND err_no = -101 AND language = @language
	UPDATE #dist_un_group SET err_msg = @msg WHERE row_id = @recid
	return @err
END

/* Populate Variables */
SELECT @parent = (SELECT parent_serial_no FROM #dist_un_group where row_id = @recid)
SELECT @type   = (SELECT type FROM #dist_un_group where row_id = @recid)
SELECT @method = (SELECT method FROM #dist_un_group where row_id = @recid)
SELECT @order  = (SELECT order_no FROM #dist_un_group where row_id = @recid)
SELECT @order_ext = (SELECT order_ext FROM #dist_un_group where row_id = @recid)	
SELECT @part   = (SELECT part_no FROM #dist_un_group where row_id = @recid)
SELECT @lot    = (SELECT isNull(lot_ser, '') FROM #dist_un_group where row_id = @recid)
SELECT @bin    = (SELECT isNull(bin_no, '') FROM #dist_un_group where row_id = @recid)
SELECT @qty    = (SELECT quantity FROM #dist_un_group where row_id = @recid)
SELECT @func   = (SELECT [function] FROM #dist_un_group where row_id = @recid)
SELECT @line_no   = (SELECT line_no FROM #dist_un_group where row_id = @recid)

/* Verify there is enough quantity in tdc_dist_item_pick to meet this request before we start */
SELECT @available_qty = 0
SELECT @temp_child=0
SELECT @temp_child = child_serial_no FROM tdc_dist_item_pick
WHERE method = @method 
AND order_no = @order AND order_ext = @order_ext
AND line_no = @line_no AND isnull(status,'') <> 'V' AND [function] = @func

IF (@temp_child <> 0)
BEGIN
	SELECT @available_qty = quantity FROM tdc_dist_group 
	WHERE	 method = @method AND type = @type 
	AND parent_serial_no = @parent AND isnull(status,'') <> 'V' 
	AND child_serial_no = @temp_child  AND [function] = @func
END
IF (@available_qty < @qty)
BEGIN
	SELECT @err = -2
	-- Qty not available
	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_item_pack_ungroup_sp' AND err_no = -102 AND language = @language
	UPDATE #dist_un_group SET err_msg = @msg WHERE row_id = @recid
	return @err
END


	/* Here we will loop through each record in the tdc_dist_group table associated	*/
	/* with this parent and check it's child to determine if it is the correct 		*/
	/* order, part, lot, and bin we are looking for to place qty into. We leave the	*/
	/* status as is.  If we zero out the quantity of the record in tdc_dist_group	*/
	/* we will delete it.															*/

	DECLARE group_cursor CURSOR FOR 
		SELECT	child_serial_no, quantity FROM tdc_dist_group
		WHERE	method = @method AND type = @type AND parent_serial_no = @parent AND status <> 'V'
				AND [function] = @func 
	OPEN group_cursor

	SELECT @done = 0

	FETCH NEXT FROM group_cursor INTO @temp_child, @avail_qty_this_row
	WHILE ((@@FETCH_STATUS <> -1) AND (@done <> 1))
	BEGIN
		IF (@@FETCH_STATUS <> -2)
		BEGIN
			IF EXISTS (SELECT * FROM tdc_dist_item_pick 
				WHERE child_serial_no = @temp_child AND method = @method
				AND order_no = @order AND part_no = @part
				and line_no = @line_no AND isNull(lot_ser, '') = @lot
				AND isNull(bin_no, '') = @bin
				AND [function] = @func)
			BEGIN
				IF (@qty <= @avail_qty_this_row)
				BEGIN
					UPDATE tdc_dist_group 
						SET quantity = quantity - @qty
						WHERE parent_serial_no = @parent AND child_serial_no = @temp_child
						AND [function] = @func AND method = @method

					UPDATE tdc_dist_item_pick
						SET quantity = quantity + @qty
						WHERE child_serial_no = @temp_child
							AND [function] = @func AND method = @method

					DELETE FROM tdc_dist_group
						WHERE parent_serial_no = @parent 
						AND child_serial_no = @temp_child 
						AND quantity = 0 AND method = @method
						AND [function] = @func

					SELECT @done = 1

					SELECT @qty = 0
				END
				ELSE
				BEGIN
					DELETE FROM tdc_dist_group
						WHERE CURRENT OF group_cursor

					UPDATE tdc_dist_item_pick
						SET quantity = quantity + @avail_qty_this_row
						WHERE child_serial_no = @temp_child
						AND [function] = @func AND method = @method

					SELECT @qty = @qty - @avail_qty_this_row
				END
			END
		END

		IF (@done <> 1)
		BEGIN
			FETCH NEXT FROM group_cursor INTO @temp_child, @avail_qty_this_row
		END
	END
	
	IF (@qty > 0)
	BEGIN

		SELECT @err = -3
		-- Qty not available
		SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_item_pack_ungroup_sp' AND err_no = -103 AND language = @language
		UPDATE #dist_un_group SET err_msg = @msg WHERE row_id = @recid

		DEALLOCATE group_cursor

		RETURN @err
	END


	DEALLOCATE group_cursor

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_item_pack_ungroup_sp] TO [public]
GO
