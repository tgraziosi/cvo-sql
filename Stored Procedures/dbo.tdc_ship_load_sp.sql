SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_ship_load_sp]
	@stage_no varchar(11),
	@load_no int,
	@user_id varchar(50), 
	@alter_by int
AS

DECLARE @order_no int,
	@order_ext int,
	@order_and_ext varchar(100), 
	@err_msg varchar(255), 
	@kit_item varchar(30),
	@line_no int, 
	@part_no varchar(30),
	@picked decimal(20, 8),
	@packed decimal(20, 8),
	@staged decimal(20, 8)

 
	
	DECLARE ord_cur CURSOR FOR 
	SELECT order_no, order_ext 
	  FROM load_list(NOLOCK)
	 WHERE load_no = @load_no
	 ORDER BY order_no, order_ext
	
	OPEN ord_cur
	FETCH NEXT FROM ord_cur INTO @order_no, @order_ext
	WHILE @@FETCH_STATUS = 0  
	BEGIN

		SELECT @order_and_ext = CAST(@order_no AS VARCHAR) + '-' + CAST(@order_ext AS VARCHAR)

		--Make sure no PRE-PACK allocations for order
		IF EXISTS(SELECT * 
			    FROM tdc_soft_alloc_tbl
			   WHERE order_no  = @order_no
			     AND order_ext = @order_ext
			     AND alloc_type = 'PR')
		BEGIN
			IF EXISTS(SELECT * FROM tdc_soft_alloc_tbl (NOLOCK)
				   WHERE order_no   = @order_no
				     AND order_ext  = @order_ext
				     AND order_type = 'S')
			BEGIN
				SELECT @err_msg = 'Order must first be unallocated: ' + @order_and_ext
				UPDATE tdc_stage_carton SET stage_error = @err_msg 
				WHERE stage_no = @stage_no
				  AND carton_no IN
					(SELECT carton_no FROM tdc_carton_tx a(NOLOCK), load_list b(NOLOCK) 
			                 WHERE a.order_no = b.order_no 
					   AND a.order_ext = b.order_ext					  
					   AND a.order_type = 'S'
					   AND b.load_no = @load_no)
				   AND carton_no IN (SELECT carton_no 
						       FROM #temp_ship_confirm_cartons)	
				CLOSE ord_cur
				DEALLOCATE ord_cur
				RETURN -1
			END
		END

		--Make sure pick transactions on queue for order
		IF EXISTS(SELECT *
			    FROM tdc_pick_queue (NOLOCK)
			   WHERE trans_type_no 	 = @order_no
			     AND trans_type_ext  = @order_ext
			     AND trans           = 'STDPICK' )
		BEGIN
			SELECT @err_msg = 'Pick transactions exist on pick queue for order: ' + @order_and_ext
			UPDATE tdc_stage_carton 
			   SET stage_error = @err_msg 
			WHERE stage_no = @stage_no
			  AND carton_no IN
				(SELECT carton_no FROM tdc_carton_tx a(NOLOCK), load_list b(NOLOCK) 
		                 WHERE a.order_no = b.order_no 
				   AND a.order_ext = b.order_ext					  
				   AND a.order_type = 'S'
				   AND b.load_no = @load_no)
			   AND carton_no IN (SELECT carton_no 
					       FROM #temp_ship_confirm_cartons)	
			CLOSE ord_cur
			DEALLOCATE ord_cur
			RETURN -2
		END
	
	
	
	
		--Make sure all subcomponents for custom kits
		--in order have been packed.
		SELECT TOP 1 @kit_item = a.kit_part_no 
		  FROM tdc_ord_list_kit a
		 WHERE a.order_no  = @order_no
		   AND a.order_ext = @order_ext
		   AND a.kit_part_no NOT IN (SELECT b.part_no 
					   FROM tdc_carton_detail_tx b,
						tdc_stage_carton     c
					  WHERE b.order_no 	 = a.order_no
					    AND b.order_ext 	 = a.order_ext
					    AND b.line_no   	 = a.line_no
					    AND c.carton_no 	 = b.carton_no
					    AND c.tdc_ship_flag != 'Y')
		   AND EXISTS(SELECT * 
			        FROM tdc_carton_detail_tx d,
				     tdc_ord_list_kit     e,
				     tdc_stage_carton     f
			       WHERE d.order_no       = @order_no
				 AND d.order_ext      = @order_ext
				 AND d.order_no       = e.order_no
				 AND d.order_ext      = e.order_ext
				 AND d.line_no        = e.line_no
				 AND f.carton_no      = d.carton_no
				 AND f.tdc_ship_flag != 'Y')
		
		IF RTRIM(LTRIM(@kit_item)) <> ''
		BEGIN
			SELECT @err_msg = 'Not all parts in custom kit packed for order: ' + @order_and_ext + '; ' + 'Component: ' + @kit_item
			UPDATE tdc_stage_carton SET stage_error = @err_msg 
			WHERE stage_no = @stage_no
			  AND carton_no IN
				(SELECT carton_no FROM tdc_carton_tx a(NOLOCK), load_list b(NOLOCK) 
		                 WHERE a.order_no = b.order_no 
				   AND a.order_ext = b.order_ext					  
				   AND a.order_type = 'S'
				   AND b.load_no = @load_no)
			   AND carton_no IN (SELECT carton_no 
					       FROM #temp_ship_confirm_cartons)	
			CLOSE ord_cur
			DEALLOCATE ord_cur
			RETURN -3
		END
		 
		--Make sure that all parts picked have been packed
		DECLARE tdc_item_packed_cur INSENSITIVE CURSOR FOR 
		 SELECT ol.line_no, ol.part_no, ol.shipped
		   FROM ord_list ol
		  WHERE ol.order_no = @order_no
		    AND ol.order_ext = @order_ext
	
		
		-- Get picked/shipped quantities from ord_list table.
		OPEN tdc_item_packed_cur
		FETCH NEXT FROM tdc_item_packed_cur INTO @line_no, @part_no, @picked
		
		
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			-- Compare against what has been packed.
			SELECT @packed = ISNULL(SUM(pack_qty), 0)
			  FROM tdc_carton_detail_tx (NOLOCK)
			 WHERE order_no  = @order_no
			   AND order_ext = @order_ext
			   AND line_no   = @line_no
			   AND carton_no IN (SELECT carton_no 
		                               FROM tdc_carton_tx(NOLOCK)
					      WHERE order_no   = @order_no
						AND order_ext  = @order_ext
						AND order_type = 'S')
		
			IF (@packed < @picked)
			BEGIN
				SELECT @err_msg = 'Not all items picked have been packed for order: ' + @order_and_ext
				UPDATE tdc_stage_carton SET stage_error = @err_msg 
				 WHERE stage_no = @stage_no
				  AND carton_no IN
					(SELECT carton_no FROM tdc_carton_tx a(NOLOCK), load_list b(NOLOCK) 
			                 WHERE a.order_no = b.order_no 
					   AND a.order_ext = b.order_ext					  
					   AND a.order_type = 'S'
					   AND b.load_no = @load_no)
				   AND carton_no IN (SELECT carton_no 
						       FROM #temp_ship_confirm_cartons)	
		 
				CLOSE tdc_item_packed_cur
				DEALLOCATE tdc_item_packed_cur
				CLOSE ord_cur
				DEALLOCATE ord_cur
				RETURN -5
			END
			ELSE
			BEGIN
				-- Compare against what has been staged.
				SELECT @staged   = ISNULL(SUM(pack_qty), 0)
				  FROM tdc_carton_detail_tx (NOLOCK)
				 WHERE order_no  = @order_no
				   AND order_ext = @order_ext
				   AND line_no   = @line_no
				   AND carton_no IN (SELECT carton_no 
			                               FROM tdc_carton_tx(NOLOCK)
						      WHERE order_no   = @order_no
							AND order_ext  = @order_ext
							AND order_type = 'S'
							AND status >= 'S')
				   AND status >= 'S'
		
				IF (@staged < @packed)
				BEGIN
					SELECT @err_msg = 'Not all items packed have been staged for order: ' + @order_and_ext
					UPDATE tdc_stage_carton SET stage_error = @err_msg 
					 WHERE stage_no = @stage_no
					  AND carton_no IN
						(SELECT carton_no FROM tdc_carton_tx a(NOLOCK), load_list b(NOLOCK) 
				                 WHERE a.order_no = b.order_no 
						   AND a.order_ext = b.order_ext					  
						   AND a.order_type = 'S'
						   AND b.load_no = @load_no)
					   AND carton_no IN (SELECT carton_no 
							       FROM #temp_ship_confirm_cartons)	
					CLOSE tdc_item_packed_cur
					DEALLOCATE tdc_item_packed_cur
					CLOSE ord_cur
					DEALLOCATE ord_cur
					RETURN -6
				END	
							
				IF 'S' = 'S' AND (SELECT back_ord_flag FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext) = '1'
				BEGIN
					IF (@staged < (SELECT ordered 
							 FROM ord_list (NOLOCK) 		 
							WHERE order_no  = @order_no
							  AND order_ext = @order_ext
							  AND line_no   = @line_no))
					BEGIN
						SELECT @err_msg = 'Not all items ordered have been staged for Ship Complete order: ' + @order_and_ext
						UPDATE tdc_stage_carton SET stage_error = @err_msg 
						 WHERE stage_no = @stage_no
						  AND carton_no IN
							(SELECT carton_no FROM tdc_carton_tx a(NOLOCK), load_list b(NOLOCK) 
					                 WHERE a.order_no = b.order_no 
							   AND a.order_ext = b.order_ext					  
							   AND a.order_type = 'S'
							   AND b.load_no = @load_no)
						   AND carton_no IN (SELECT carton_no 
								       FROM #temp_ship_confirm_cartons)	
						CLOSE tdc_item_packed_cur
						DEALLOCATE tdc_item_packed_cur
						CLOSE ord_cur
						DEALLOCATE ord_cur
						RETURN -7
					END	
				END
			END
		
			FETCH NEXT FROM tdc_item_packed_cur INTO @line_no, @part_no, @picked
		END
		
		CLOSE tdc_item_packed_cur
		DEALLOCATE tdc_item_packed_cur
	
		
		-- If the order is spread accross multiple stages make sure the cartons on
		-- other stages are marked as tdc shipped before marking the order as shipped in ERP
		IF EXISTS (SELECT * 
				 FROM tdc_carton_tx a(NOLOCK),
				      tdc_stage_carton b(NOLOCK)
				WHERE a.carton_no = b.carton_no
				  AND b.stage_no <> @stage_no
				  AND a.order_no = @order_no
				  AND a.order_ext = @order_ext
				  AND a.order_type = 'S'
				  AND tdc_ship_flag <> 'Y'
				  AND a.carton_no IN(SELECT carton_no 
						       FROM tdc_carton_detail_tx
						      WHERE carton_no = a.carton_no))				
		-- Make sure that all cartons created for this sales order have been staged
		OR EXISTS(SELECT *
				 FROM tdc_carton_tx a(NOLOCK)
				WHERE a.order_no = @order_no
				  AND a.order_ext = @order_ext
				  AND a.order_type = 'S'
				  AND a.carton_no NOT IN (SELECT carton_no
							  FROM tdc_stage_carton (NOLOCK)
							 WHERE tdc_ship_flag = 'Y')
				  AND a.carton_no IN(SELECT carton_no 
						       FROM tdc_carton_detail_tx b
						      WHERE b.carton_no = a.carton_no))	 	
		
		BEGIN
		
			SELECT @err_msg = 'Not all cartons have been shipped for order: ' + @order_and_ext
			UPDATE tdc_stage_carton SET stage_error = @err_msg 
			 WHERE stage_no = @stage_no
			  AND carton_no IN
				(SELECT carton_no FROM tdc_carton_tx a(NOLOCK), load_list b(NOLOCK) 
		                 WHERE a.order_no = b.order_no 
				   AND a.order_ext = b.order_ext					  
				   AND a.order_type = 'S'
				   AND b.load_no = @load_no)
			   AND carton_no IN (SELECT carton_no 
					       FROM #temp_ship_confirm_cartons)	
			CLOSE ord_cur
			DEALLOCATE ord_cur
			RETURN -8
		END

		FETCH NEXT FROM ord_cur INTO @order_no, @order_ext
	END
	
	CLOSE ord_cur
	DEALLOCATE ord_cur

	BEGIN TRAN

	UPDATE load_list SET date_shipped = GETDATE()
	WHERE load_no = @load_no

	UPDATE load_master 
	   SET date_shipped = GETDATE(), 
	       status = 'R', 
	       shipped_who_nm = @user_id 
	 WHERE load_no = @load_no


	--Set tdc_stage_carton ADM shipped flag to 'Y' and ADM ship date
	UPDATE tdc_stage_carton  
	   SET adm_ship_flag = 'Y', adm_ship_date = GETDATE() - @alter_by, stage_error = NULL
	 WHERE carton_no IN(SELECT a.carton_no
			      FROM tdc_stage_carton a(NOLOCK),
			           tdc_carton_tx    b(NOLOCK),
				   load_list 	    c(NOLOCK)
			     WHERE a.carton_no = b.carton_no
			       AND c.order_no = b.order_no
			       AND c.order_ext = b.order_ext
			       AND c.load_no = @load_no
			       AND a.tdc_ship_flag = 'Y')

	COMMIT TRAN

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_ship_load_sp] TO [public]
GO
