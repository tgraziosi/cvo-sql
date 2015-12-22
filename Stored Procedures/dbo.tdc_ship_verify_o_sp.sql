SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*                        						*/
/* Ship Verify Order - This sp will take as input one order		*/
/* number in the #dist_ship_verify_order table and will return 		*/
/* zero for success and a negative value for failure.  On		*/
/* failure a negative value is returned and the err_msg field 		*/
/* is updated.								*/
/* 									*/
/* Verify this order extension exists in tdc_dist_item_list.		*/
/*									*/
/* Verify that nothing on this order extension has moved past		*/
/* the pick process.							*/
/*									*/
/* Send to tdc_adm_ship_order stored procedure				*/
/*									*/
/* NOTE: This SP is designed to only process a #dist_group with 	*/
/* one row of data							*/
/* NOTE: The order with the highest extension in the			*/
/* tdc_dist_item_pick will be used. The assumption is that		*/
/* there should only be one extension per order in this table		*/
/* at any time.								*/
/*									*/

/*									*/
/* 06/30/1998	Initial		GCJ					*/
/*									*/
/* 07/07/1998	Revision	GCJ					*/
/*		No longer verifies entire order has been picked		*/
/*		instead it will return error code -100 and the		*/
/*		percent picked eWarehouse will then manually call 	*/
/*		tdc_adm_ship_order if user wants to go ahead and 	*/
/*		create backorder.					*/
/*									*/
/* 08/17/1998	Revision	GCJ					*/
/*		Modified quantity to decimal (20, 8)			*/
/*									*/

CREATE PROCEDURE [dbo].[tdc_ship_verify_o_sp]
AS

SET NOCOUNT ON

	DECLARE @err int, @order int, @order_ext int, @temp_err varchar(255) 
	DECLARE @ordered decimal(20,8)
	DECLARE @ordered_tot decimal(20, 8), @shipped_tot decimal(20, 8)
	DECLARE	@ship_flag char(1), @shipped decimal(20,8), @language varchar(10), @msg varchar(255)

	/* Initialize the error code to no errors */
	SELECT @err = 0

	/* Populate Variables */
	SELECT @order = order_no, @order_ext = order_ext FROM #dist_ship_verify_o
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	/* Verify this order extension exists in tdc_dist_item_list */
	IF NOT EXISTS (SELECT * FROM tdc_dist_item_list WHERE order_no = @order AND order_ext = @order_ext AND [function] = 'S')
	BEGIN
		RAISERROR ('Order: %d-%d NOT found in Supply Chain Execution system.', 16, 1, @order, @order_ext)
		RETURN -101
	END

	/* Verify that nothing on this order extension has moved past	*/
	/* the pick process						*/

	IF EXISTS (SELECT * 
		     FROM tdc_dist_group g (nolock), tdc_dist_item_pick p (nolock) 
		    WHERE p.order_no = @order 
		      AND p.order_ext = @order_ext 
		      AND p.[function] = 'S' 
		      AND g.child_serial_no = p.child_serial_no 
		      AND g.[function] = 'S' 
		      AND p.method = g.method)
	BEGIN
		--Order %d-%d has moved past picking process
		SELECT @msg = err_msg 
		  FROM tdc_lookup_error (nolock) 
		 WHERE module = 'SPR' AND trans = 'tdc_ship_verify_order_sp' AND err_no = -102 AND language = @language

		RAISERROR (@msg, 16, 1, @order, @order_ext)
		DEALLOCATE item_cursor
		RETURN -102
	END

	IF ((SELECT sum(shipped * conv_factor) FROM ord_list WHERE order_no = @order AND order_ext = @order_ext) <> 
		(SELECT sum(quantity) FROM tdc_dist_item_pick WHERE order_no = @order AND order_ext = @order_ext AND [function] = 'S'))
	BEGIN
		-- Shipped qty is different from picked qty 
		SELECT @msg = err_msg
		  FROM tdc_lookup_error (nolock)
		 WHERE module = 'SPR' AND trans = 'tdc_ship_verify_order_sp' AND err_no = -103 AND language = @language

		RAISERROR (@msg, 16, 1)
		RETURN -103
	END

	TRUNCATE TABLE #adm_ship_order
	/* Check to see how much of the order has been picked. If the	*/
	/* entire order has been picked then go ahead and call		*/
	/* tdc_adm_ship_order else return the total qty and qty picked so	*/
	/* they can be displayed to the user so that the user can	*/
	/* decide wether or not they want to go ahead and verify the	*/
	/* order.							*/

	-- check to see which flag is set for customer
	SELECT @ship_flag = back_ord_flag FROM orders (nolock) WHERE order_no = @order AND ext = @order_ext

	SELECT @ordered_tot = 0.0
	SELECT @shipped_tot = 0.0

	-- check if the whole order has been picked
	IF (@ship_flag = '1')
	BEGIN
		SELECT @ordered_tot = SUM(ordered * conv_factor), @shipped_tot = SUM(
			CASE 
				WHEN shipped > ordered THEN ordered * conv_factor
				ELSE shipped * conv_factor
			END )
		  FROM ord_list (nolock) 
		 WHERE order_no = @order 
		   AND order_ext = @order_ext 
		   --AND shipped > 0 SCR 36428 04-16-06 ToddR
	END
	ELSE
	BEGIN
		SELECT @ordered_tot = SUM(ordered * conv_factor), @shipped_tot = SUM(
			CASE 
				WHEN shipped > ordered THEN ordered * conv_factor
				ELSE shipped * conv_factor
			END )
		  FROM ord_list (nolock) 
		 WHERE order_no = @order 
		   AND order_ext = @order_ext
	END
		
	--SCR 33035 - CNASH - 06/18/04
	IF EXISTS (SELECT 1 FROM tdc_config WHERE [function] = 'N_QTY_AUTO_PICK' AND active = 'Y')
	BEGIN
		SELECT @shipped_tot = @shipped_tot + ISNULL(SUM(ordered * conv_factor) , 0)
			FROM ord_list 
			WHERE order_no = @order 
			AND order_ext = @order_ext
			AND (SELECT status
				FROM inv_master
				WHERE inv_master.part_no = ord_list.part_no) = 'V' --non-quantity bearing parts
		
		IF @shipped_tot > @ordered_tot
			SELECT @shipped_tot = @ordered_tot
	END

	-- ship complete : only allow to ship verify if all items of the orders
	-- has been picked
	IF ((@ship_flag = '1') AND (@ordered_tot > @shipped_tot))
	BEGIN
		-- Order %d-%d must be ship completed'
		SELECT @msg = err_msg 
		  FROM tdc_lookup_error (nolock)
		 WHERE module = 'SPR' AND trans = 'tdc_ship_verify_order_sp' AND err_no = -110 AND language = @language

		RAISERROR (@msg, 16, 1, @order, @order_ext)
		RETURN -110
	END

	-- ship partial - no allow backorder	
	IF ((@ship_flag = '2') AND (@ordered_tot > @shipped_tot))
	BEGIN
		UPDATE #dist_ship_verify_o 	
		   SET err_msg = CONVERT(char(255), ROUND((@shipped_tot/@ordered_tot)*100, 0))
		 WHERE order_no = @order
									
		RETURN -150
	END

	IF (@ship_flag = '0') AND (@shipped_tot < @ordered_tot)
	BEGIN
		/* Entire order has not been picked. Send warning back to user of percent picked	*/
		/* If user says to go ahead eWarehouse will manually call tdc_adm_ship_order.		*/
		UPDATE #dist_ship_verify_o 
		   SET err_msg = CONVERT(char(255), ROUND((@shipped_tot/@ordered_tot)*100, 0))
		 WHERE order_no = @order
		
		UPDATE #dist_ship_verify_o
		   SET order_ext = @order_ext
		 WHERE order_no = @order

		SELECT @err = -100
	END
	ELSE
	BEGIN
		INSERT INTO #adm_ship_order (order_no, ext, err_msg)
			VALUES(@order, @order_ext, NULL)
	
		BEGIN TRAN

		EXEC @err = tdc_adm_ship_order 0

		IF (@err < 0)
		BEGIN
			IF (@@TRANCOUNT > 0) ROLLBACK TRAN
			RETURN @err
		END
		
		INSERT INTO tdc_bkp_dist_item_pick(method,order_no,order_ext,line_no,part_no,lot_ser,bin_no,quantity,
						   child_serial_no,[function],type,status,bkp_status,bkp_date) 	
				SELECT method, order_no, order_ext, line_no, part_no, lot_ser, bin_no,
					quantity, child_serial_no, [function], type, status, 'C', GETDATE()
				  FROM tdc_dist_item_pick (nolock)
				 WHERE order_no = @order 
				   AND order_ext = @order_ext 
				   AND [function] = 'S'

		DELETE FROM tdc_dist_item_pick WHERE order_no = @order AND order_ext = @order_ext AND [function] = 'S'

		INSERT INTO tdc_bkp_ord_list_kit (order_no,order_ext,part_no,line_no,ordered,picked,location,
						  kit_part_no,sub_kit_part_no,qty_per_kit,kit_picked,bkp_status,bkp_date)	
			SELECT order_no, order_ext, part_no, line_no, ordered, picked, location,
				kit_part_no, sub_kit_part_no, qty_per_kit, kit_picked, 'C', GETDATE()
			  FROM tdc_ord_list_kit (nolock)
			 WHERE order_no = @order 
			   AND order_ext = @order_ext

		DELETE FROM tdc_ord_list_kit WHERE order_no = @order AND order_ext = @order_ext

		INSERT INTO tdc_bkp_dist_item_list(order_no,order_ext,line_no,part_no,quantity,shipped,
						   [function],bkp_status,bkp_date)  	
			SELECT order_no, order_ext, line_no, part_no, quantity, shipped, [function], 'C', GETDATE()	
			  FROM tdc_dist_item_list (nolock)
			 WHERE order_no = @order 
			   AND order_ext = @order_ext 
			   AND [function] = 'S'

		DELETE FROM tdc_dist_item_list WHERE order_no = @order AND order_ext = @order_ext AND [function] = 'S'

		EXEC tdc_set_status @order, @order_ext, 'R1'

		COMMIT TRAN

		DROP TABLE #adm_ship_order
	END

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_ship_verify_o_sp] TO [public]
GO
