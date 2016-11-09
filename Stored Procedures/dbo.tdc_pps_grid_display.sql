SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Epicor Software UK Ltd
-- v1.0 CB 11/05/2011 - Case Part Consolidation
-- v10.0 CB 12/06/2012 - Soft Allocation - Remove case consolidation
-- v10.1 CB 23/04/2015 - Performance Changes
-- v10.2 CB 24/08/2016 - CVO-CF-49 - Dynamic Custom Frames

CREATE PROC [dbo].[tdc_pps_grid_display]
	@is_one_order_per_ctn	char(1),
	@carton_no		int,
	@order_no		int,
	@order_ext		int

AS
BEGIN
	DECLARE	@line_no 	 int,
			@part_no 	 varchar(30),
			@sub_kit_part_no varchar(30),
			@total_packed 	 decimal(20, 8),
			@carton_packed 	 decimal(20, 8)

	-----------------------------------------------------------------------------------------------------------------
	-- Carton packed items display for non-kit items
	-----------------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE #temp_pps_carton_display

	-----------------------------------------------------------------------------------------------------------------
	-- Insert the records that are packed for this carton.
	-----------------------------------------------------------------------------------------------------------------
 	INSERT INTO #temp_pps_carton_display(order_no, order_ext, line_no, part_no, [description], ordered, picked, total_packed, carton_packed)
	SELECT	DISTINCT b.order_no, b.order_ext, b.line_no, b.part_no, c.[description], b.ordered * b.conv_factor, b.shipped * b.conv_factor, 0, 0
	FROM	tdc_carton_detail_tx a(NOLOCK),
			ord_list b(NOLOCK),
			inv_master c(NOLOCK)
	WHERE	carton_no = @carton_no
	AND		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		b.part_no = c.part_no
	AND		a.part_no <> 'C'
	UNION
	SELECT	DISTINCT b.order_no, b.order_ext, b.line_no, b.part_no, c.[description], b.ordered * b.conv_factor, FLOOR(b.shipped) * b.conv_factor, 0, 0
	FROM	tdc_carton_detail_tx a(NOLOCK),
			ord_list b(NOLOCK),
			inv_master c(NOLOCK)
	WHERE	carton_no = @carton_no
	AND		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		b.part_no = c.part_no
	AND		a.part_no = 'C'
	 
	-----------------------------------------------------------------------------------------------------------------
	-- If the order number is passed in, insert all the records for this order.
	-----------------------------------------------------------------------------------------------------------------
	IF @order_no > 0
	BEGIN
		-- SCR 34709

	 	INSERT INTO #temp_pps_carton_display(order_no, order_ext, line_no, part_no, [description], ordered, picked, total_packed, carton_packed)	
		SELECT	order_no, order_ext, line_no, a.part_no, b.[description], a.ordered * a.conv_factor, case when a.part_type = 'C' then FLOOR(a.shipped) * a.conv_factor else a.shipped * a.conv_factor end as shipped, 0, 0
		FROM	ord_list a (NOLOCK),
				inv_master b(NOLOCK)
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext 
	    AND		a.part_no = b.part_no
		AND NOT EXISTS(SELECT * FROM #temp_pps_carton_display
						WHERE order_no = a.order_no
						AND order_ext = a.order_ext
						AND line_no = a.line_no)
	END

	-- v10.1 Start
	DECLARE @row_id			int,
			@last_row_id	int

	CREATE TABLE #upd_cur (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		line_no			int,
		part_no			varchar(30) NULL)

	-- v10.1 DECLARE upd_cur CURSOR FOR 
	INSERT	#upd_cur (order_no, order_ext, line_no, part_no)
	SELECT	order_no, order_ext, line_no, part_no
	FROM	#temp_pps_carton_display

	-- v10.1 OPEN upd_cur
	-- v10.1 FETCH NEXT FROM upd_cur INTO @order_no, @order_ext, @line_no, @part_no
	-- v10.1 WHILE @@FETCH_STATUS = 0
	SET @last_row_id = 0
	
	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@line_no = line_no,
			@part_no = part_no
	FROM	#upd_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		SELECT @total_packed = 0
		SELECT @carton_packed = 0

		IF EXISTS(SELECT * FROM inv_master (NOLOCK) WHERE part_no = @part_no AND status = 'C')
		BEGIN

			EXEC @total_packed = dbo.tdc_cust_kit_units_packed_sp @order_no, @order_ext, 0, @line_no
			
			IF @carton_no != 0 
				EXEC @carton_packed = dbo.tdc_cust_kit_units_packed_sp @order_no, @order_ext, @carton_no, @line_no
		END
		ELSE
		BEGIN
			SELECT	@total_packed = SUM(pack_qty) 
			FROM	tdc_carton_detail_tx (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no  = @line_no
			GROUP BY order_no, order_ext, line_no

			SELECT	@carton_packed = SUM(pack_qty)
			FROM	tdc_carton_detail_tx (NOLOCK)
			WHERE	carton_no = @carton_no
			AND		order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no  = @line_no
			GROUP BY carton_no, line_no

		END

		UPDATE	#temp_pps_carton_display 
		SET		total_packed = @total_packed,
				carton_packed = @carton_packed
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no = @line_no

		-- v10.2 Start
		IF EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans_source = 'PLW' AND trans = 'STDPICK' AND trans_type_no = @order_no
						AND trans_type_ext = @order_ext AND line_no = @line_no AND ISNULL(company_no,'') = 'CF')
		BEGIN
			UPDATE	#temp_pps_carton_display 
			SET		total_packed = 0,
					carton_packed = 0,
					picked = 0
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
		END
		-- v10.2 End
		
		SET @last_row_id = @row_id
	
		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@line_no = line_no,
				@part_no = part_no
		FROM	#upd_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		-- v10.1 FETCH NEXT FROM upd_cur INTO @order_no, @order_ext, @line_no, @part_no
	END
	
	-- v10.1 CLOSE upd_cur
	-- v10.1 DEALLOCATE upd_cur
 
	-----------------------------------------------------------------------------------------------------------------
	-- Carton packed items display for kit items
	-----------------------------------------------------------------------------------------------------------------

	TRUNCATE TABLE #temp_pps_kit_display

	-----------------------------------------------------------------------------------------------------------------
	-- Insert the records that are packed for this carton.
	-----------------------------------------------------------------------------------------------------------------
 	INSERT INTO #temp_pps_kit_display(order_no, order_ext, line_no, part_no, [description], qty_per_kit, ordered, picked, total_packed, carton_packed, sub_kit_part_no)
	SELECT	DISTINCT b.order_no, b.order_ext, b.line_no, b.kit_part_no, c.[description], b.qty_per_kit, b.ordered * b.qty_per_kit, b.kit_picked, 0, 0,
			sub_kit_part_no = NULL
	FROM	tdc_carton_detail_tx a(NOLOCK),
			tdc_ord_list_kit b(NOLOCK),
			inv_master c(NOLOCK)
	WHERE	carton_no = @carton_no
	AND		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		b.kit_part_no = c.part_no
	AND		b.sub_kit_part_no IS NULL
	UNION
	SELECT	DISTINCT b.order_no, b.order_ext, b.line_no, b.kit_part_no, c.[description], b.kit_picked, kit_picked, b.kit_picked, 0, 0,
			sub_kit_part_no 
	FROM	tdc_carton_detail_tx a(NOLOCK),
			tdc_ord_list_kit b(NOLOCK),
			inv_master c(NOLOCK)
	WHERE	carton_no = @carton_no
	AND		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		b.kit_part_no = c.part_no
	AND		b.sub_kit_part_no IS NOT NULL
 
	-----------------------------------------------------------------------------------------------------------------
	-- If the order number is passed in, insert all the records for this order.
	-----------------------------------------------------------------------------------------------------------------
	IF @order_no > 0
	BEGIN
	 	INSERT INTO #temp_pps_kit_display(order_no, order_ext, line_no, part_no, [description], qty_per_kit, ordered, picked, total_packed, carton_packed, sub_kit_part_no)
		SELECT order_no, order_ext, line_no, a.kit_part_no, b.[description], a.qty_per_kit, ordered = a.ordered * a.qty_per_kit, 
		       kit_picked = (SELECT SUM(kit_picked)
				       FROM tdc_ord_list_kit c(NOLOCK)
						WHERE order_no = @order_no 
				        AND order_ext = @order_ext
						AND line_no = a.line_No
						AND kit_part_no = a.kit_part_no),
				0, 0, sub_kit_part_no = NULL
		FROM	tdc_ord_list_kit a(NOLOCK),
				inv_master b(NOLOCK)
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext 
	    AND		a.kit_part_no = b.part_no
		AND		sub_kit_part_no IS NULL
		AND NOT EXISTS(SELECT * FROM #temp_pps_kit_display
					WHERE order_no = a.order_no
				    AND order_ext = a.order_ext
				    AND line_no = a.line_no
				    AND part_no = a.kit_part_no)
		  
		UNION
	 	SELECT order_no, order_ext, line_no, a.kit_part_no, b.[description], a.kit_picked, a.kit_picked, 
		       kit_picked = (SELECT SUM(kit_picked)
						FROM tdc_ord_list_kit c(NOLOCK)
						WHERE order_no = @order_no 
				        AND order_ext = @order_ext
						AND line_no = a.line_No
						AND kit_part_no = a.kit_part_no
						AND sub_kit_part_no = a.sub_kit_part_no),
		       0, 0, sub_kit_part_no 
		FROM	tdc_ord_list_kit a(NOLOCK),
				inv_master b(NOLOCK)
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext 
	    AND		a.kit_part_no = b.part_no
		AND		sub_kit_part_no IS NOT NULL
		AND NOT EXISTS(SELECT * FROM #temp_pps_kit_display
					WHERE order_no = a.order_no
				    AND order_ext = a.order_ext
				    AND line_no = a.line_no
				    AND part_no = a.kit_part_no)
	END

	CREATE TABLE #kit_upd_cur (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		line_no			int,
		part_no			varchar(30) NULL,
		sub_kit_part_no	varchar(30) NULL)

	INSERT	#kit_upd_cur (order_no, order_ext, line_no, part_no, sub_kit_part_no)
	-- v10.1 DECLARE upd_cur CURSOR FOR 
	SELECT	order_no, order_ext, line_no, part_no, sub_kit_part_no
	FROM	#temp_pps_kit_display
	
	-- v10.1 OPEN upd_cur
	-- v10.1 FETCH NEXT FROM upd_cur INTO @order_no, @order_ext, @line_no, @part_no, @sub_kit_part_no

	-- v10.1 WHILE @@FETCH_STATUS = 0

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@line_no = line_no,
			@part_no = part_no,
			@sub_kit_part_no = sub_kit_part_no
	FROM	#kit_upd_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN
		SELECT @total_packed = 0
		SELECT @carton_packed = 0

		SELECT	@total_packed = SUM(pack_qty)
		FROM	tdc_carton_detail_tx (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no  = @line_no
		AND		((part_no = @part_no AND @sub_kit_part_no IS NULL) OR (part_no = @sub_kit_part_no AND @sub_kit_part_no IS NOT NULL))
		GROUP BY order_no, order_ext, line_no

		SELECT	@carton_packed = SUM(pack_qty)
		FROM	tdc_carton_detail_tx (NOLOCK)
		WHERE	carton_no = @carton_no
		AND		order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no  = @line_no
		AND		((part_no = @part_no AND @sub_kit_part_no IS NULL) OR (part_no = @sub_kit_part_no AND @sub_kit_part_no IS NOT NULL))
		GROUP BY carton_no, line_no
 
		UPDATE	#temp_pps_kit_display 
		SET		total_packed = @total_packed,
				carton_packed = @carton_packed
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no = @line_no
		AND		part_no = @part_no 
		AND		ISNULL(sub_kit_part_no, '') = ISNULL(@sub_kit_part_no, '')
 
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@line_no = line_no,
				@part_no = part_no,
				@sub_kit_part_no = sub_kit_part_no
		FROM	#kit_upd_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
		
		-- v10.1 FETCH NEXT FROM upd_cur INTO @order_no, @order_ext, @line_no, @part_no, @sub_kit_part_no
	END
	
	-- v10.1CLOSE upd_cur
	-- v10.1 DEALLOCATE upd_cur
END
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_grid_display] TO [public]
GO
