SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_pre_pack_mix_parts_sp] 
	@overfill_or_adh_qty decimal(20, 8)
AS

DECLARE @row_id   	int,
	@order_ext	int,
	@order_no	int,
	@pack_qty	decimal(20, 8),
	@qty		decimal(20, 8),
	@move_qty	decimal(20, 8),
	@new_carton_index int
 
TRUNCATE TABLE #new_pre_pack_cartons

INSERT INTO #new_pre_pack_cartons(carton_index, order_no, order_ext, location, con_no, lot_ser, line_no, part_no, pack_qty, qty)
SELECT carton_index, order_no, order_ext, location, con_no, lot_ser, line_no, part_no, pack_qty, qty
  FROM #pre_pack_cartons
 WHERE qty = pack_qty

SELECT @new_carton_index = MAX(carton_index) 
  FROM #pre_pack_cartons

DELETE FROM #pre_pack_cartons
 WHERE qty = pack_qty

DECLARE cartons_cur CURSOR FOR
	SELECT DISTINCT order_no, order_ext 
	  FROM #pre_pack_cartons

ORDER BY order_no, order_ext 

OPEN cartons_cur
FETCH NEXT FROM cartons_cur INTO @order_no, @order_ext 

-----------------------------------------------------------------------------------------------------------
-- Loop through the orders, looking at the pack_qty
-----------------------------------------------------------------------------------------------------------
WHILE @@FETCH_STATUS = 0
BEGIN
	-----------------------------------------------------------------------------------------------------------
	-- Initialize the pack qty and carton index
	-----------------------------------------------------------------------------------------------------------
	SELECT @new_carton_index = ISNULL(@new_carton_index, 0) + 1
	SELECT @pack_qty = @overfill_or_adh_qty

	DECLARE parts_cur CURSOR FOR 
	SELECT row_id, qty
	  FROM #pre_pack_cartons
	 WHERE order_no = @order_no
	   AND order_ext = @order_ext

	OPEN parts_cur
	FETCH NEXT FROM parts_cur INTO @row_id, @qty
	-----------------------------------------------------------------------------------------------------------
	-- Loop through all of the parts for the order-ext
	-----------------------------------------------------------------------------------------------------------
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		-----------------------------------------------------------------------------------------------------------
		-- If the carton will hold ALL of this part/qty, insert the record.
		-----------------------------------------------------------------------------------------------------------
		IF @pack_qty >= @qty
		BEGIN
			INSERT INTO #new_pre_pack_cartons (carton_index, order_no, order_Ext, location, con_no, lot_ser, 
							line_no, part_no, pack_qty, qty)
			SELECT @new_carton_index, order_no, order_Ext, location, con_no, lot_ser, line_no, part_no, pack_qty, @qty
			  FROM #pre_pack_cartons
			 WHERE row_id = @row_id

			SELECT @pack_qty = @pack_qty - @qty

			-----------------------------------------------------------------------------------------------------------
			-- If this fills the carton, get a new carton and reset the pack qty
			-----------------------------------------------------------------------------------------------------------
			IF @pack_qty = 0
			BEGIN
				SELECT @new_carton_index = @new_carton_index + 1
				SELECT @pack_qty = @overfill_or_adh_qty
			END

		END
		ELSE
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			-- If the carton will NOT hold all of this part/qty, split the record
			-----------------------------------------------------------------------------------------------------------
			SELECT @move_qty = @qty - @pack_qty
			
			-----------------------------------------------------------------------------------------------------------
			-- Insert what it takes to fill this carton
			-----------------------------------------------------------------------------------------------------------
			INSERT INTO #new_pre_pack_cartons (carton_index, order_no, order_Ext, location, con_no, lot_ser, 
							line_no, part_no, pack_qty, qty)
			SELECT @new_carton_index, order_no, order_Ext, location, con_no, lot_ser, line_no, part_no, pack_qty, @pack_qty
			  FROM #pre_pack_cartons
			 WHERE row_id = @row_id
	
			-----------------------------------------------------------------------------------------------------------
			-- Increment the carton counter and insert the remainder.
			-----------------------------------------------------------------------------------------------------------
			SELECT @new_carton_index = @new_carton_index + 1

			INSERT INTO #new_pre_pack_cartons (carton_index, order_no, order_Ext, location, con_no, lot_ser, 
							line_no, part_no, pack_qty, qty)
			SELECT @new_carton_index, order_no, order_Ext, location, con_no, lot_ser, line_no, part_no, pack_qty, @move_qty
			  FROM #pre_pack_cartons
			 WHERE row_id = @row_id
 
			-----------------------------------------------------------------------------------------------------------
			-- Reset the pack qty to what it will take to fill this new carton
			-----------------------------------------------------------------------------------------------------------
			SELECT @pack_qty = @overfill_or_adh_qty - @move_qty
 		
		END

		FETCH NEXT FROM parts_cur INTO @row_id, @qty
	END
	CLOSE parts_cur
	DEALLOCATE parts_cur
	

	FETCH NEXT FROM cartons_cur INTO @order_no, @order_ext 
END

CLOSE cartons_cur
DEALLOCATE cartons_cur

-----------------------------------------------------------------------------------------------------------
-- Clear the original temp table and insert the new records.
-----------------------------------------------------------------------------------------------------------
TRUNCATE TABLE #pre_pack_cartons

INSERT INTO #pre_pack_cartons (carton_index, order_no, order_Ext, location, con_no, lot_ser, 
				line_no, part_no, pack_qty, qty)
SELECT carton_index, order_no, order_Ext, location, con_no, lot_ser, line_no, part_no, pack_qty, qty
  FROM #new_pre_pack_cartons
 ORDER BY order_no, order_ext, part_no

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_pre_pack_mix_parts_sp] TO [public]
GO
