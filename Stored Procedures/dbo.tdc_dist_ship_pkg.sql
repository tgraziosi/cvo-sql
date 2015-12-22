SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*                        					*/
/* tdc_dist_ship_pkg - Given a parent this sp will scan through	*/
/* the tree and mark all children as verified. (status = V) If 	*/
/* any of the children are still open it will stop and return 	*/
/* an error.  As it marks the children as verified it will	*/
/* store unique order/ext's associated with the given parent.	*/
/* After marking all children verified we check the table of 	*/
/* unique order/ext's associated with this parent to see if we	*/
/* are finished with any of them.  If we are then we call 	*/
/* tdc_adm_ship_order to relinquish control of the order/ext back	*/
/* to ADM.							*/
/*								*/
/* NOTE: This SP is designed to only process a #ship_pkg with	*/
/*       one row of data					*/
/* NOTE: Caller must verify this parent is ready to be ship	*/
/*       verified.						*/
/*								*/
/*								*/
/* 06/17/1998	Initial				REA		*/
/* 07/06/1998	Rewriting			GCJ		*/
/* 02/03/1999   Updating			SHD		*/
/* 		ship_flag = 0 allows backorders			*/
/*		ship_flag = 1 ship complete			*/
/*		ship_flag = 2 ship partial - no backorder	*/
/*		RETURN @err = -150 warning the user backorder	*/
/*		is not created if they want to ship partial	*/

CREATE PROCEDURE [dbo].[tdc_dist_ship_pkg]
AS
	SET NOCOUNT ON

	DECLARE @err int, @parent int, @temporary_parent int, @temporary_order int, @temporary_ext int, @line_no int
	DECLARE @temp_qty int, @return_code int, @temp_err varchar(255), @temp_row int, @ship_flag char(1)
	DECLARE	@qty decimal(20,8), @qty_fill decimal(20,8), @order int, @ext int, @qty_order decimal(20,8)
	DECLARE @temporary_child int, @tempQty decimal(20,8), @qty_verify decimal(20,8), @dsf char(2)
	DECLARE @language varchar(10), @msg varchar(255)

CREATE TABLE #temp_tb1
(
	parent_no INT NOT NULL, 
	child_no INT NOT NULL
)

CREATE TABLE #temp_tb2
(
	parent_no INT NOT NULL, 
	child_no INT NOT NULL
)

	TRUNCATE TABLE #temp_parent
	TRUNCATE TABLE #temp_child
	TRUNCATE TABLE #root_children
	TRUNCATE TABLE #order_ext

	SELECT @err = 0
	
	SELECT 	@parent = (SELECT parent_serial_no FROM #ship_pkg) 
	SELECT 	@dsf = (SELECT dsf FROM #ship_pkg) 
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')	

BEGIN TRAN

	TRUNCATE TABLE #adm_ship_order
	TRUNCATE TABLE #temp_child

	/* Get the parent to be ship verified */
	INSERT INTO #temp_parent(temp_parent) VALUES(@parent)

	WHILE EXISTS (SELECT * FROM #temp_parent)
	BEGIN	
		DECLARE parent_cursor CURSOR FOR SELECT temp_parent FROM #temp_parent
		OPEN parent_cursor
		FETCH NEXT FROM parent_cursor INTO @temporary_parent

		WHILE (@@FETCH_STATUS = 0 )
		BEGIN
			-- ship verify order that was picked at P level.  
			-- During the picking process, since the user filled the order with independent child_serial_no in tdc_pcs_item, 
			-- record would not be inserted into tdc_dist_group.  The status = 'C' would be inserted into tdc_dist_item_pick instead.
			IF EXISTS ( SELECT * FROM tdc_dist_item_pick WHERE child_serial_no =  @temporary_parent AND status = 'C' AND [function] = 'S')
			BEGIN
				UPDATE tdc_dist_item_pick SET status = 'V' WHERE child_serial_no = @temporary_parent
				INSERT INTO #root_children(child_serial_no) VALUES(@temporary_parent)
			END

			ELSE
			BEGIN
				IF EXISTS (SELECT * FROM tdc_dist_group WHERE parent_serial_no = @temporary_parent AND status = 'O'
								AND [function] = 'S')
				BEGIN
					DEALLOCATE parent_cursor					
					ROLLBACK TRAN
					
				--	UPDATE #ship_pkg SET err_msg = CONVERT(varchar(10),@temporary_parent) + ' is OPEN' WHERE parent_serial_no = @parent
					SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_dist_ship_pkg_sp' AND err_no = -101 AND language = @language
					RAISERROR (@msg, 16, 1, @temporary_parent)
					RETURN -1
				END

				IF EXISTS (SELECT * FROM tdc_dist_item_pick WHERE child_serial_no = @temporary_parent AND [function] = 'S')
				BEGIN
					INSERT INTO #root_children(child_serial_no) VALUES(@temporary_parent)
				END

				UPDATE tdc_dist_group 	SET status = 'V' 
							WHERE parent_serial_no = @temporary_parent
							AND [function] = 'S'

				INSERT INTO #temp_child (temp_child) SELECT child_serial_no 
							FROM tdc_dist_group 
							WHERE parent_serial_no = @temporary_parent
							AND [function] = 'S'

				DELETE FROM #temp_parent WHERE CURRENT OF parent_cursor			
			END
			FETCH NEXT FROM parent_cursor INTO @temporary_parent
		END
		DEALLOCATE parent_cursor
		TRUNCATE TABLE #temp_parent
		INSERT INTO #temp_parent(temp_parent)  SELECT temp_child FROM #temp_child
		TRUNCATE TABLE #temp_child
	END

	INSERT INTO #order_ext (order_no,order_ext)  	SELECT DISTINCT order_no, order_ext 
				FROM tdc_dist_item_pick
				WHERE child_serial_no IN (SELECT DISTINCT child_serial_no FROM #root_children)
				AND [function] = 'S'
--------------------------
--SELECT * FROM #ORDER_EXT
--------------------------
	/* Delete rows from #order_ext that have not moved past the pick process */
	DECLARE order_cursor CURSOR FOR SELECT order_no, order_ext FROM #order_ext

	OPEN order_cursor

	FETCH NEXT FROM order_cursor INTO @temporary_order, @temporary_ext

	WHILE (@@FETCH_STATUS = 0 )
	BEGIN
-------------
--SELECT @temporary_order, @temporary_ext
-----------------
		SELECT @temp_qty = (SELECT SUM(quantity) FROM tdc_dist_item_pick 
					WHERE order_no = @temporary_order AND order_ext = @temporary_ext
					AND [function] = 'S')
		IF (@temp_qty > 0)
		BEGIN
			IF EXISTS( SELECT * FROM tdc_dist_item_pick WHERE child_serial_no = @parent AND status = 'V')
			BEGIN
				-- find quantity that has been picked but not ship verified
				SELECT @tempQty = ( SELECT sum(quantity) FROM tdc_dist_item_pick 
									WHERE order_no = @temporary_order
									AND order_ext = @temporary_ext
									AND status = 'C' AND [function] = 'S')
				IF( @tempQty > 0 )
				BEGIN
					DELETE FROM #order_ext WHERE CURRENT OF order_cursor
				END
				ELSE
				BEGIN
					-- check to see which flag is set for customer
					SELECT @ship_flag = back_ord_flag FROM orders (nolock) WHERE order_no = @temporary_order AND ext = @temporary_ext

 					-- ship complete or ship partial
					IF( @ship_flag = '1' or @ship_flag = '2')
					BEGIN
						-- check if the whole order has been picked,and/or cartonized
						DECLARE fill_cursor CURSOR FOR SELECT line_no, ordered FROM ord_list
										WHERE order_no = @temporary_order
										AND order_ext = @temporary_ext
						OPEN fill_cursor
						FETCH NEXT FROM fill_cursor INTO @line_no, @qty

						WHILE (@@FETCH_STATUS = 0)
						BEGIN
							SELECT @qty_fill = ( SELECT sum(quantity) FROM tdc_dist_item_pick 
					    							WHERE order_no = @temporary_order
					    							AND order_ext = @temporary_ext
					    							AND line_no = @line_no
												AND [function] = 'S' )
							IF( @qty_fill <  @qty )
							BEGIN
								-- ship complete : only allow to ship verify if all items of the orders
								-- has been picked, cartonized. 
								IF( @ship_flag = '1' )
								BEGIN
									DEALLOCATE fill_cursor
									DEALLOCATE order_cursor
									ROLLBACK TRAN

								--	UPDATE #ship_pkg SET err_msg = 'This order must be ship completed'
									SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_dist_ship_pkg_sp' AND err_no = -102 AND language = @language
									RAISERROR (@msg, 16, 1)
									RETURN -110
								END
								-- ship partial - no backorder
								ELSE
								BEGIN
									IF( @ship_flag <> (SELECT ship_flag FROM #ship_pkg) )
									BEGIN
										DEALLOCATE fill_cursor
										DEALLOCATE order_cursor
										ROLLBACK TRAN										
										RETURN -150
									END
								END	
							END
							FETCH NEXT FROM fill_cursor INTO @line_no, @qty
						END
						DEALLOCATE fill_cursor
					END
					INSERT INTO #adm_ship_order (order_no,ext,err_msg)
	 					VALUES(@temporary_order, @temporary_ext, NULL)		
				END
			END

			ELSE
			BEGIN
				DELETE FROM #order_ext WHERE CURRENT OF order_cursor
			END
		END
		ELSE
		BEGIN
			/* See if all children associated with this order / ext have	*/
			/* been ship verified.						*/
			IF EXISTS (SELECT * FROM tdc_dist_group WHERE status <> 'V' AND child_serial_no IN 
							(SELECT child_serial_no FROM tdc_dist_item_pick 
							WHERE order_no = @temporary_order AND order_ext = @temporary_ext
							AND [function] = 'S') AND [function] = 'S')
			BEGIN
				DELETE FROM #order_ext WHERE CURRENT OF order_cursor
			END
			ELSE
			BEGIN
				-- check to see which flag is set for customer
				SELECT @ship_flag = back_ord_flag FROM orders (nolock) WHERE order_no = @temporary_order AND ext = @temporary_ext

--select @ship_flag
 				-- ship complete or ship partial
				IF( @ship_flag = '1' or @ship_flag = '2')
				BEGIN
					-- check if the whole order has been picked,and/or cartonized
					DECLARE fill_cursor CURSOR FOR SELECT line_no, ordered FROM ord_list
										WHERE order_no = @temporary_order
										AND order_ext = @temporary_ext
					OPEN fill_cursor
					FETCH NEXT FROM fill_cursor INTO @line_no, @qty

					WHILE (@@FETCH_STATUS = 0)
					BEGIN
--						SELECT @qty_fill = (SELECT sum(quantity) FROM tdc_dist_group
--										WHERE child_serial_no in (SELECT child_serial_no 
--					    									FROM tdc_dist_item_pick
--					    									WHERE order_no = @temporary_order
--					    									AND order_ext = @temporary_ext
--					    									AND line_no = @line_no))
--select @qty, @qty_fill

--						IF( @qty_fill <  @qty )
						IF EXISTS( SELECT * FROM ord_list WHERE order_no = @temporary_order 
											AND order_ext = @temporary_ext
											AND line_no = @line_no
											AND ordered > shipped) 
						BEGIN
							-- ship complete : only allow to ship verify if all items of the orders
							-- has been picked, cartonized. 
							IF( @ship_flag = '1' )
							BEGIN
								DEALLOCATE fill_cursor
								DEALLOCATE order_cursor
								ROLLBACK TRAN
							--	UPDATE #ship_pkg SET err_msg = 'This order must be ship completed'
								SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_dist_ship_pkg_sp' AND err_no = -102 AND language = @language
								RAISERROR (@msg, 16, 1)
								RETURN -110
							END
							-- ship partial - no backorder
							ELSE
							BEGIN
								IF( @ship_flag <> (SELECT ship_flag FROM #ship_pkg) )
								BEGIN
									DEALLOCATE fill_cursor
									DEALLOCATE order_cursor
									ROLLBACK TRAN										
									RETURN -150
								END
							END
						END
						FETCH NEXT FROM fill_cursor INTO @line_no, @qty
					END
					DEALLOCATE fill_cursor
				END					
				INSERT INTO #adm_ship_order(order_no,ext,err_msg) VALUES(@temporary_order, @temporary_ext, NULL)
			END
		END
		FETCH NEXT FROM order_cursor INTO @temporary_order, @temporary_ext
	END

	DEALLOCATE order_cursor

	IF NOT EXISTS (SELECT * FROM #adm_ship_order)
	BEGIN
		/* No order extensions need to be turned over to ADM */
		GOTO Calculation
	END

EXEC @return_code = tdc_adm_ship_order 

IF (@return_code < 0)
BEGIN
	ROLLBACK TRAN
	SELECT @temp_row = (SELECT MIN(row_id) FROM #adm_ship_order WHERE err_msg <> NULL)
	SELECT @temp_err = (SELECT err_msg FROM #adm_ship_order WHERE row_id = @temp_row)
	UPDATE #ship_pkg SET err_msg = @temp_err WHERE parent_serial_no = @parent
	RETURN @return_code
END

EXEC tdc_set_status @temporary_order, @temporary_ext, 'R1'

GOTO Calculation

/**************************************** Calculation  ******************************************/
/* Calculation quantity ordered vs. quantity ship verified					*/
/************************************************************************************************/
Calculation:
	-- initialize @qty_verify = 0
	SELECT 	@qty_verify = 0,
		@tempQty = 0

	IF EXISTS( SELECT * FROM tdc_dist_item_pick WHERE child_serial_no = @parent AND status = 'V' AND [function] = 'S')
	BEGIN
		SELECT @order = (SELECT DISTINCT order_no FROM tdc_dist_item_pick WHERE child_serial_no = @parent)
		-- find ext of blanket order
		IF( (SELECT status FROM orders WHERE order_no = @order AND ext = 0 ) = 'M')
		BEGIN
			SELECT @ext = ( SELECT DISTINCT order_ext FROM tdc_dist_item_pick 
					WHERE child_serial_no = @parent)
		END
		-- find ext of non-blanket order
		ELSE
		BEGIN
			SELECT @ext = ( SELECT DISTINCT max(order_ext) FROM tdc_dist_item_pick 
					WHERE child_serial_no = @parent)
		END

		SELECT @qty_order  = (SELECT sum(ordered) FROM ord_list WHERE order_no = @order AND order_ext = @ext)
		SELECT @qty_verify = (SELECT sum(quantity) FROM tdc_dist_item_pick 
								WHERE order_no = @order
								AND order_ext = @ext
								AND status = 'V'
								AND [function] = 'S') 
	END
	ELSE
	BEGIN
		TRUNCATE TABLE #temp_parent
		TRUNCATE TABLE #temp_child
		TRUNCATE TABLE #root_children

		INSERT INTO #temp_parent (temp_parent) 	SELECT child_serial_no 
							FROM tdc_dist_group 
							WHERE parent_serial_no = @parent
		WHILE EXISTS( SELECT * FROM #temp_parent)
		BEGIN
			DECLARE serial_cursor CURSOR FOR SELECT temp_parent FROM #temp_parent
			OPEN serial_cursor
			FETCH NEXT FROM serial_cursor INTO @temporary_parent

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				IF EXISTS (SELECT child_serial_no FROM tdc_dist_group WHERE parent_serial_no = @temporary_parent AND status = 'V')
				BEGIN
					IF NOT EXISTS(SELECT * 	FROM #temp_child WHERE temp_child in (SELECT child_serial_no FROM tdc_dist_group WHERE parent_serial_no = @temporary_parent AND status = 'V')  )
					BEGIN
						INSERT INTO #temp_child (temp_child) SELECT child_serial_no FROM tdc_dist_group WHERE parent_serial_no = @temporary_parent AND status = 'V'
					END								
				END

				ELSE
				BEGIN
					IF NOT EXISTS (SELECT * FROM #root_children WHERE child_serial_no = @temporary_parent)
					BEGIN
						INSERT INTO #root_children (child_serial_no) VALUES(@temporary_parent)
					END
				END
				FETCH NEXT FROM serial_cursor INTO @temporary_parent
			END
			DEALLOCATE serial_cursor

			TRUNCATE TABLE #temp_parent
			INSERT INTO #temp_parent (temp_parent) SELECT temp_child FROM #temp_child
			TRUNCATE TABLE #temp_child
		END

		IF ((SELECT COUNT(DISTINCT order_no) 
			FROM tdc_dist_item_pick 
			WHERE child_serial_no IN (SELECT * FROM #root_children)) = 1)
		BEGIN
			SELECT @order = (SELECT DISTINCT order_no FROM tdc_dist_item_pick 
						  	WHERE child_serial_no in ( SELECT * FROM #root_children) )
	
			-- find ext of blanket order 
			IF( (SELECT status FROM orders WHERE order_no = @order AND ext = 0 ) = 'M')
			BEGIN
				SELECT @ext   = (SELECT DISTINCT order_ext FROM tdc_dist_item_pick 
						           	WHERE child_serial_no in (SELECT * FROM #root_children) )
			END
			-- not a blanket order - ext = max(ext)
			ELSE
			BEGIN
				SELECT @ext   = (SELECT DISTINCT max(order_ext) FROM tdc_dist_item_pick 
						        WHERE child_serial_no in (SELECT * FROM #root_children) )
			END

			SELECT @qty_order  = (SELECT sum(ordered) FROM ord_list WHERE order_no = @order AND order_ext = @ext) 
--			SELECT @qty_verify = (SELECT sum(quantity) FROM tdc_dist_group WHERE child_serial_no in( SELECT * FROM #root_children) )

			TRUNCATE TABLE #temp_child
			INSERT INTO #temp_child (temp_child) SELECT DISTINCT child_serial_no 
									FROM  tdc_dist_item_pick
									WHERE order_no  = @order AND order_ext = @ext AND [function] = 'S'	
		
			DECLARE child_cursor CURSOR FOR SELECT temp_child FROM #temp_child
			OPEN child_cursor
			FETCH NEXT FROM child_cursor INTO @temporary_child

			WHILE (@@FETCH_STATUS = 0)
			BEGIN	
				IF EXISTS (SELECT DISTINCT * FROM tdc_dist_group WHERE child_serial_no = @temporary_child AND status = 'V')
				BEGIN
					SELECT @tempQty    = (SELECT sum(quantity) FROM tdc_dist_group WHERE child_serial_no = @temporary_child AND status = 'V')
					SELECT @qty_verify = @qty_verify + @tempQty
				END
				FETCH NEXT FROM child_cursor INTO @temporary_child
			END
			DEALLOCATE child_cursor
		END
		ELSE
		BEGIN
			SELECT @order = 0	-- if multiple orders  we don't count percentage
		END
	END
	UPDATE #ship_pkg SET 	qty_order  = @qty_order, 
				qty_verify = @qty_verify,
				order_no   = @order,
				order_ext  = @ext
			 WHERE parent_serial_no = @parent

/**************************************** End Calculation *************************************/

/***************************************	back up		*****************************************/

IF EXISTS (SELECT * FROM #adm_ship_order)
BEGIN
	DECLARE get_order_no CURSOR FOR SELECT DISTINCT order_no, ext FROM #adm_ship_order
	OPEN get_order_no
	FETCH NEXT FROM get_order_no INTO @order, @ext

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		TRUNCATE TABLE #temp_tb1
		TRUNCATE TABLE #temp_tb2

		INSERT INTO #temp_tb1 (parent_no, child_no) 
			SELECT DISTINCT g.parent_serial_no, g.child_serial_no 
								FROM tdc_dist_group g, tdc_dist_item_pick i
								WHERE g.child_serial_no = i.child_serial_no
								AND g.[function] = 'S' AND i.[function] = 'S'
								AND i.order_no = @order AND i.order_ext = @ext
							
		WHILE EXISTS (SELECT parent_serial_no 	FROM tdc_dist_group
												WHERE child_serial_no IN (SELECT DISTINCT parent_no FROM #temp_tb1) 
												AND [function] = 'S')
		BEGIN
			INSERT INTO #temp_tb2 (parent_no, child_no) SELECT DISTINCT parent_serial_no, child_serial_no
							FROM tdc_dist_group 	
							WHERE child_serial_no IN (SELECT DISTINCT parent_no FROM #temp_tb1)
							AND [function] = 'S'

			DELETE FROM #temp_tb2 WHERE parent_no IN (SELECT DISTINCT parent_no FROM #temp_tb1)
									AND child_no IN (SELECT DISTINCT child_no FROM #temp_tb1)
							
			IF EXISTS (SELECT * FROM #temp_tb2)
				INSERT INTO #temp_tb1 (parent_no, child_no) SELECT parent_no, child_no FROM #temp_tb2
			ELSE 
				BREAK
		END
	
		IF EXISTS (SELECT * FROM orders WHERE order_no = @order AND ext = @ext AND status = 'R')
		BEGIN
			IF @dsf = 'Y'
			BEGIN
				DELETE FROM tdc_soft_alloc_tbl WHERE order_no = @order AND order_ext = @ext
			END		

			INSERT INTO tdc_bkp_dist_item_pick (method,order_no,order_ext,line_no,part_no,lot_ser,bin_no,
												quantity,child_serial_no,[function],type,status,bkp_status,bkp_date )
				 	SELECT method,order_no,order_ext,line_no,part_no,lot_ser,bin_no,quantity,
					       child_serial_no,[function],type,status, 'C', GETDATE() 
												FROM tdc_dist_item_pick 
												WHERE order_no = @order AND order_ext = @ext 
												AND [function] = 'S'
			DELETE FROM tdc_dist_item_pick 	WHERE order_no = @order 
											AND order_ext = @ext AND [function] = 'S'
			INSERT INTO tdc_bkp_dist_group (method,type,parent_serial_no,child_serial_no,quantity,status,[function],bkp_status,bkp_date)
			 	SELECT 	method,type,parent_serial_no,child_serial_no,quantity,status,[function], 'C', GETDATE() 
											FROM tdc_dist_group 
											WHERE parent_serial_no IN (SELECT DISTINCT parent_no FROM #temp_tb1) 
											AND child_serial_no IN (SELECT DISTINCT child_no FROM #temp_tb1)
											AND [function] = 'S'
			DELETE FROM tdc_dist_group 	WHERE parent_serial_no IN (SELECT DISTINCT parent_no FROM #temp_tb1) 
										AND child_serial_no IN (SELECT DISTINCT child_no FROM #temp_tb1)
										AND [function] = 'S'
			INSERT INTO tdc_bkp_dist_item_list 	(order_no,order_ext,line_no,part_no,quantity,
												 shipped,[function],bkp_status,bkp_date)
						SELECT order_no,order_ext,line_no,part_no,quantity,shipped,[function], 'C', GETDATE() 
												FROM tdc_dist_item_list 
												WHERE order_no = @order AND order_ext = @ext AND [function] = 'S'
			DELETE FROM tdc_dist_item_list WHERE order_no = @order AND order_ext = @ext AND [function] = 'S'

		END
		FETCH NEXT FROM get_order_no INTO @order, @ext
	END
	DEALLOCATE get_order_no
END

COMMIT TRANSACTION
RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_dist_ship_pkg] TO [public]
GO
