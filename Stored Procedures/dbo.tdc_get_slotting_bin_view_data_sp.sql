SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_get_slotting_bin_view_data_sp]
	@template_id	int,
	@userid		varchar(50),
	@err_msg	varchar(255) OUTPUT
AS

DECLARE	
	@location 		varchar(10),
	@current_bin		varchar(12),
	@current_row		int,
	@part_no		varchar(30),
	@check_part		varchar(30),
	@check_qty		decimal(20,8),
	@part_count		decimal(20,8),
	@phy_cyc_count		decimal(20,8),
	@shade_amt		decimal(20,8),
	@shade_color		varchar(20),
	@view_by_style		int,
	@bin_max_defined 	int,  -- 0 for No, 1 for Yes
	@bin_max_value		decimal(20,8),
	@bin_type_color		int,
	@usage_type		varchar(10),
	@empty_bin		int,
	--SLOTTED BINS
	@slotgood_w_max		int,
	@slotgood_wo_max	int,
	@slotbad_w_max		int,
	@slotbad_wo_max		int,
	--INSTOCK BINS
	@instock_w_max		int,
	@instock_wo_max		int,
	@notinstock_w_max	int,
	@notinstock_wo_max	int,
	--BIN TYPE COLORS
	@open_bin_color		int,
	@prodin_bin_color	int,
	@prodout_bin_color	int,
	@quarantine_bin_color	int,
	@receipt_bin_color	int,
	@replenish_bin_color	int,
	@language 		varchar(10)

	SELECT @language = ISNULL(Language, 'us_english') FROM tdc_sec (NOLOCK) WHERE userid = @userid

	SELECT @location = location FROM tdc_graphical_bin_template (NOLOCK) WHERE template_id = @template_id

	SELECT @phy_cyc_count = 0

	SELECT @view_by_style = 4 --Draw like In Stock

	--SET BIN TYPE COLORS
	SELECT 	@open_bin_color = open_color, 
		@prodin_bin_color = prodin_color, 
		@prodout_bin_color = prodout_color, 
		@quarantine_bin_color = quarantine_color, 
		@receipt_bin_color = receipt_color, 
		@replenish_bin_color = replenish_color
	 FROM tdc_graphical_bin_view_bin_type_color_tbl (NOLOCK)
	WHERE template_viewbyid = @view_by_style

	--SET BIN COLORS
	--IN STOCK VIEW
	SELECT @instock_w_max = bin_color 
		FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)
		WHERE template_viewbyid = @view_by_style 
		  AND seq_no = 1
	SELECT @instock_wo_max = bin_color 
		FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)
		WHERE template_viewbyid = @view_by_style 
		  AND seq_no = 2
	SELECT @notinstock_w_max = bin_color 
		FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)
		WHERE template_viewbyid = @view_by_style 
		  AND seq_no = 3
	SELECT @notinstock_wo_max = bin_color 
		FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)
		WHERE template_viewbyid = @view_by_style 
		  AND seq_no = 4
	SELECT @empty_bin = bin_color 
		FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)
		WHERE template_viewbyid = @view_by_style 
		  AND seq_no = 5

	--IN STOCK QUANTITIES VIEW
	INSERT INTO #tdc_graphical_bin_view_display_data (bin_no)
		SELECT bin_no FROM tdc_graphical_bin_store WHERE template_id = @template_id ORDER BY row, col

	DECLARE bin_view_update_cursor CURSOR FOR
		SELECT rowid,  ISNULL(CASE WHEN bin_no LIKE '<%>' THEN '' ELSE bin_no END, '') FROM #tdc_graphical_bin_view_display_data ORDER BY rowid
	OPEN bin_view_update_cursor
	FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT 	@bin_max_value = ISNULL(maximum_level, 0), @usage_type = usage_type_code FROM tdc_bin_master (NOLOCK) WHERE bin_no = @current_bin AND location = @location

		SELECT @bin_type_color = 
				CASE @usage_type
					WHEN 'OPEN' 		THEN @open_bin_color
					WHEN 'PRODIN'		THEN @prodin_bin_color
					WHEN 'PRODOUT'		THEN @prodout_bin_color
					WHEN 'QUARANTINE'	THEN @quarantine_bin_color
					WHEN 'RECEIPT'		THEN @receipt_bin_color
					WHEN 'REPLENISH'	THEN @replenish_bin_color
					ELSE @empty_bin
				END

		IF @bin_max_value = 0
			SELECT @bin_max_defined = 0
		ELSE
			SELECT @bin_max_defined = 1

		--SET THE PART_NO
		IF EXISTS(SELECT TOP 1 * FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location)
		BEGIN

			IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location HAVING Count(DISTINCT part_no) > 1)
				SELECT @part_no = (SELECT TOP 1 part_no FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location)
			ELSE
				SELECT @part_no = 'Mixed'

			--SET THE PART_COUNT
			SELECT @part_count= ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location
			--SET THE SHADE_AMOUNT, SHADE_TYPE AND SHADE_COLOR
			--WE WILL DRAW THE BINS DIFFERENTLY, DEPENDING ON WHETHER OR NOT BIN MAX AMOUNTS HAVE BEEN SET UP
			IF @bin_max_defined = 1
			BEGIN
				SELECT 	@shade_color = @instock_w_max,
					@shade_amt = (@part_count/@bin_max_value)*100
			END
			ELSE
			BEGIN
				SELECT 	@shade_color = @instock_wo_max, 
					@shade_amt = 100
			END
		END
		ELSE
		BEGIN
			SELECT 	@part_count = 0, 
				@shade_amt = 100, 
				@shade_color = @notinstock_w_max

			SELECT 	@part_no = 'No Inv. In Bin'

			IF @bin_max_defined <> 1
				SELECT @shade_color = @notinstock_wo_max
		END
		IF @current_bin = ''
		BEGIN
			SELECT 	@shade_color = @empty_bin,
				@bin_type_color = @empty_bin,
				@part_no = ''
		END

		UPDATE #tdc_graphical_bin_view_display_data 
			SET part_no = @part_no, part_count = @part_count, shade_amt = @shade_amt, shade_color = @shade_color, bin_type_color = @bin_type_color, phy_cyc_count = @phy_cyc_count
			WHERE rowid = @current_row
		FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin
	END
	CLOSE bin_view_update_cursor
	DEALLOCATE bin_view_update_cursor

-- INSERT INTO #tdc_graphical_bin_view_display_data2 
-- 	SELECT * FROM #tdc_graphical_bin_view_display_data

	--SLOTTING VIEW
	SELECT @slotgood_w_max = bin_color 
		FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)
		WHERE template_viewbyid = @view_by_style 
		  AND seq_no = 1
	SELECT @slotgood_wo_max = bin_color 
		FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)
		WHERE template_viewbyid = @view_by_style 
		  AND seq_no = 2
	SELECT @slotbad_w_max = bin_color 
		FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)
		WHERE template_viewbyid = @view_by_style 
		  AND seq_no = 3
	SELECT @slotbad_wo_max = bin_color 
		FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)
		WHERE template_viewbyid = @view_by_style 
		  AND seq_no = 4
	SELECT @empty_bin = bin_color 
		FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)
		WHERE template_viewbyid = @view_by_style 
		  AND seq_no = 5
	--SLOTTING VIEW
	--BUILD SLOTTING VIEW DATA!!!!!!!!!!!!!!!!!!!!!!!!!
	INSERT INTO #tdc_graphical_bin_view_display_data2 (bin_no)
		SELECT bin_no FROM tdc_graphical_bin_store WHERE template_id = @template_id ORDER BY row, col

	DECLARE bin_view_update_cursor CURSOR FOR
		SELECT rowid,  ISNULL(CASE WHEN bin_no LIKE '<%>' THEN '' ELSE bin_no END, '') FROM #tdc_graphical_bin_view_display_data2 ORDER BY rowid
	OPEN bin_view_update_cursor
	FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT 	@bin_max_value = ISNULL(maximum_level, 0), @usage_type = usage_type_code FROM tdc_bin_master (NOLOCK) WHERE bin_no = @current_bin AND location = @location

		SELECT @bin_type_color = 
				CASE @usage_type
					WHEN 'OPEN' 		THEN @open_bin_color
					WHEN 'PRODIN'		THEN @prodin_bin_color
					WHEN 'PRODOUT'		THEN @prodout_bin_color
					WHEN 'QUARANTINE'	THEN @quarantine_bin_color
					WHEN 'RECEIPT'		THEN @receipt_bin_color
					WHEN 'REPLENISH'	THEN @replenish_bin_color
					ELSE @empty_bin
				END

		IF @bin_max_value = 0
			SELECT @bin_max_defined = 0
		ELSE
			SELECT @bin_max_defined = 1

		--SET THE PART_NO
		IF EXISTS(SELECT TOP 1 * FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location) OR (EXISTS(SELECT * FROM #tdc_slot_bin_moves (NOLOCK) WHERE from_bin = @current_bin AND sel_flg <> 0) OR EXISTS(SELECT * FROM #tdc_slot_bin_moves (NOLOCK) WHERE to_bin = @current_bin AND sel_flg <> 0))
		BEGIN
			IF EXISTS(SELECT * FROM #tdc_slot_bin_moves (NOLOCK) WHERE from_bin = @current_bin AND sel_flg <> 0) OR EXISTS(SELECT * FROM #tdc_slot_bin_moves (NOLOCK) WHERE to_bin = @current_bin AND sel_flg <> 0)
			BEGIN
				TRUNCATE TABLE #parts_in_bin
				TRUNCATE TABLE #parts_added_to_bin
				TRUNCATE TABLE #parts_removed_from_bin

				--GET all of the parts currently in this bin
				INSERT INTO #parts_in_bin (part_no, qty, binrowid, bin_no)
					SELECT part_no, SUM(qty), @current_row, @current_bin
					  FROM lot_bin_stock (NOLOCK)
					WHERE bin_no = @current_bin
					  AND location = @location
					GROUP BY part_no

				--GET all of the parts being added to this bin
				INSERT INTO #parts_added_to_bin (part_no, qty, binrowid, bin_no)
					SELECT part_no, SUM(qty), @current_row, @current_bin
					  FROM #tdc_slot_bin_moves (NOLOCK)
					WHERE to_bin = @current_bin
					  AND from_bin IS NOT NULL
					  AND sel_flg <> 0
					GROUP BY part_no

				--GET all of the parts being removed from this bin
				INSERT INTO #parts_removed_from_bin (part_no, qty, binrowid, bin_no)
					SELECT part_no, SUM(qty), @current_row, @current_bin
					  FROM #tdc_slot_bin_moves (NOLOCK)
					WHERE from_bin = @current_bin
					  AND to_bin IS NOT NULL
					  AND sel_flg <> 0
					GROUP BY part_no

				--SEE IF ANY PARTS ARE BEING ADDED TO THIS BIN
				DECLARE parts_added CURSOR FOR
					SELECT part_no, qty 
					  FROM #parts_added_to_bin
				OPEN parts_added
				FETCH NEXT FROM parts_added INTO @check_part, @check_qty
				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF EXISTS(SELECT * FROM #parts_in_bin WHERE part_no = @check_part)
					BEGIN
						UPDATE #parts_in_bin
							SET qty = qty + @check_qty
						WHERE part_no = @check_part
					END
					ELSE
					BEGIN
						INSERT INTO #parts_in_bin (binrowid, bin_no, part_no, qty)
							SELECT @current_row, @current_bin, @check_part, @check_qty
					END

					FETCH NEXT FROM parts_added INTO @check_part, @check_qty
				END
				CLOSE parts_added
				DEALLOCATE parts_added

				--SEE IF ANY PARTS ARE BEING REMOVED FROM THIS BIN
				DECLARE parts_removed CURSOR FOR
					SELECT part_no, qty 
					  FROM #parts_removed_from_bin
				OPEN parts_removed
				FETCH NEXT FROM parts_removed INTO @check_part, @check_qty
				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF EXISTS(SELECT * FROM #parts_in_bin WHERE part_no = @check_part)
					BEGIN
						UPDATE #parts_in_bin
							SET qty = qty - @check_qty
						WHERE part_no = @check_part
					END

					FETCH NEXT FROM parts_removed INTO @check_part, @check_qty
				END
				CLOSE parts_removed
				DEALLOCATE parts_removed

				DELETE FROM #parts_in_bin WHERE qty = 0

				IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM #parts_in_bin (NOLOCK) HAVING Count(DISTINCT part_no) > 1)
					SELECT @part_no = (SELECT TOP 1 part_no FROM #parts_in_bin (NOLOCK))
				ELSE
					SELECT @part_no = 'Mixed'
	
				--SET THE PART_COUNT
				SELECT @part_count= ISNULL(SUM(qty), 0) FROM #parts_in_bin (NOLOCK)
				IF @part_count = 0
				BEGIN
					SELECT 	@part_count = 0, 
						@shade_amt = 100, 
						@shade_color = @notinstock_w_max
		
					SELECT 	@part_no = 'No Inv. In Bin'
		
					IF @bin_max_defined <> 1
						SELECT @shade_color = @notinstock_wo_max
				END
				ELSE
				BEGIN
					--SET THE SHADE_AMOUNT, SHADE_TYPE AND SHADE_COLOR
					--WE WILL DRAW THE BINS DIFFERENTLY, DEPENDING ON WHETHER OR NOT BIN MAX AMOUNTS HAVE BEEN SET UP
					IF @bin_max_defined = 1
					BEGIN
						SELECT 	@shade_color = @instock_w_max,
							@shade_amt = (@part_count/@bin_max_value)*100
					END
					ELSE
					BEGIN
						SELECT 	@shade_color = @instock_wo_max, 
							@shade_amt = 100
					END
				END
			END
			ELSE
			BEGIN
				IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location HAVING Count(DISTINCT part_no) > 1)
					SELECT @part_no = (SELECT TOP 1 part_no FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location)
				ELSE
					SELECT @part_no = 'Mixed'
	
				--SET THE PART_COUNT
				SELECT @part_count= ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location
				--SET THE SHADE_AMOUNT, SHADE_TYPE AND SHADE_COLOR
				--WE WILL DRAW THE BINS DIFFERENTLY, DEPENDING ON WHETHER OR NOT BIN MAX AMOUNTS HAVE BEEN SET UP
				IF @bin_max_defined = 1
				BEGIN
					SELECT 	@shade_color = @instock_w_max,
						@shade_amt = (@part_count/@bin_max_value)*100
				END
				ELSE
				BEGIN
					SELECT 	@shade_color = @instock_wo_max, 
						@shade_amt = 100
				END
			END
		END
		ELSE
		BEGIN
			SELECT 	@part_count = 0, 
				@shade_amt = 100, 
				@shade_color = @notinstock_w_max

			SELECT 	@part_no = 'No Inv. In Bin'

			IF @bin_max_defined <> 1
				SELECT @shade_color = @notinstock_wo_max
		END

		IF @current_bin = ''
		BEGIN
			SELECT 	@shade_color = @empty_bin,
				@bin_type_color = @empty_bin,
				@part_no = ''
		END

		UPDATE #tdc_graphical_bin_view_display_data2 
			SET part_no = @part_no, part_count = @part_count, shade_amt = @shade_amt, shade_color = @shade_color, bin_type_color = @bin_type_color, phy_cyc_count = @phy_cyc_count
			WHERE rowid = @current_row
		FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin
	END
	CLOSE bin_view_update_cursor
	DEALLOCATE bin_view_update_cursor

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_get_slotting_bin_view_data_sp] TO [public]
GO
