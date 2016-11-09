SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.3 CT 09/05/2013 - Issue #1260 - Reset variables to stop missing queue trans picking up info from previous line
-- v1.4 CB 23/08/2016 - CVO-CF-49 - Dynamic Custom Frames

CREATE PROCEDURE [dbo].[CVO_disassembled_inv_adjust_sp]	@order_no int,
														@order_ext int          
AS
BEGIN	   
	-- DECLARATIONS     
	DECLARE @location		varchar(10),
			@line_no		int,
			@part_no		varchar(30),
			@report_line	int,
			@qty			decimal(20,2),
			@bin_from		varchar(12),
			@bin_to			varchar(12),
			@lbl_pick		varchar(100),
			@lbl_pack		varchar(100),
			@lbl_final		varchar(100),
			@max_lines		int,
			@lp_string		varchar(100),
			@lp_datafield	varchar(100),
			@row_id			int,
			@last_row_id	int,
			@sub_part_no	varchar(30),
			@sub_orig_part	varchar(30),
			@part_type		varchar(10),
			@tran_id		int,
			@data_set		int,
			@queue_tran_id	int,
			@assm_line		int,
			@first			int

	-- INITIALIZE
	SET @lbl_pick = 'Scan frame for pick using printed pick ticket'
	SET @lbl_pack = 'Pack and ship as usual'
	SET @lbl_final = 'After picking completed frames, use the printed putaway ticket to put away the leftover parts'		
	SET @lp_string = ''
	SET @lp_datafield = ''
	SET @bin_to = 'CUSTOM'
	SET @report_line = 8
	SET @max_lines = 7
	SET @data_set = 0
	SET @assm_line = 0
	SET @first = 1


	-- WORKING TABLES
	IF (OBJECT_ID('tempdb..#build_plan')) IS NOT NULL 
		DROP TABLE #build_plan		
		
	CREATE TABLE #build_plan (
		asm_no		varchar(30),
		part_no		varchar(30),
		res_type	varchar(30),
		part_type	varchar(30) NULL)
			
	IF (OBJECT_ID('tempdb..#sub_parts')) IS NOT NULL 
		DROP TABLE #sub_parts	
				
	CREATE TABLE #sub_parts (
		row_id			int IDENTITY(1,1),
		line_no			int,
		part_no			varchar(30),
		res_type		varchar(30),
		part_type		varchar(30) NULL,
		orig_part_no	varchar(30))

	IF (OBJECT_ID('tempdb..#sub_parts_kit')) IS NOT NULL 
		DROP TABLE #sub_parts_kit	
				
	CREATE TABLE #sub_parts_kit (
		row_id			int IDENTITY(1,1),
		line_no			int,
		part_no			varchar(30),
		res_type		varchar(30),
		part_type		varchar(30) NULL,
		orig_part_no	varchar(30),
		from_bin		varchar(12),
		qty_to_process	decimal(20,2),
		tran_id			int)
	
	IF (OBJECT_ID('tempdb..#PrintData_INSTR')) IS NOT NULL 
		DROP TABLE #PrintData_INSTR	
	
	CREATE TABLE #PrintData_INSTR (
		data_field	varchar(300), 
		data_value	varchar(300) NULL)

	-- PROCESSING
	DECLARE values_cur CURSOR FOR  	
	SELECT	ol.order_no, 
			ol.order_ext, 
			location, 
			ol.line_no, 
			ol.part_no,
			ol.part_type
	FROM    CVO_ord_list cvo (NOLOCK), ord_list ol (NOLOCK)
	WHERE   cvo.order_no = ol.order_no	
	AND		cvo.order_ext = ol.order_ext	
	AND		cvo.line_no = ol.line_no	
	AND		cvo.order_no = @order_no
	AND		cvo.order_ext = @order_ext	
	AND		cvo.is_customized = 'S'
	AND		ol.part_type = 'P'
									  									  									  	
	OPEN values_cur

	FETCH NEXT FROM values_cur 
	INTO @order_no, @order_ext, @location, @line_no, @part_no, @part_type

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- v1.2 Start
		IF OBJECT_ID('tempdb..#line_exclusions') IS NOT NULL
		BEGIN
			IF EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no)
			BEGIN

				FETCH NEXT FROM values_cur 
				INTO @order_no, @order_ext, @location, @line_no, @part_no, @part_type

				CONTINUE
			END
		END
		-- v1.2 End

		--Part_no build plan
		DELETE FROM #build_plan
			
		INSERT INTO #build_plan (asm_no, part_no, res_type, part_type) 
		SELECT	wp.asm_no, wp.part_no, imas.type_code, iadd.category_3
		FROM	what_part wp (NOLOCK), inv_master imas (NOLOCK), inv_master_add iadd (NOLOCK)
		WHERE	wp.part_no = imas.part_no 
		AND		wp.part_no = iadd.part_no 
		AND		wp.asm_no  = @part_no				   
				   
		SELECT	@qty = ordered
		FROM	ord_list (NOLOCK)
		WHERE	order_no  = @order_no  
		AND		order_ext = @order_ext 
		AND		line_no   = @line_no

		SELECT	@bin_from = bin_no,
				@queue_tran_id = tran_id
		FROM	tdc_pick_queue (NOLOCK)
		WHERE	trans_type_no = @order_no    
		AND		trans_type_ext = @order_ext 
		AND		location = @location  
		AND		line_no  = @line_no 
		AND		part_no = @part_no 
		AND		trans = 'MGTB2B'			

		IF (@report_line > @max_lines)
		BEGIN

			IF (@first = 0)
			BEGIN
				WHILE (@assm_line <= @max_lines)
				BEGIN

					SET @lp_datafield = 'LP_ASSEMBLY_' + CAST(@assm_line as varchar(10))
					SET @lp_string = ''
					INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

					SET @assm_line = @assm_line + 1

				END			
			END

			SET @report_line = 1
			SET @assm_line = 1
			SET @first = 1
			
			SET @lp_datafield = 'LP_QUEUE_TRAN_' + CAST(@report_line as varchar(10))
			SET @lp_string = CAST(@queue_tran_id as varchar(10))
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_BIN_TO_' + CAST(@report_line as varchar(10))
			SET @lp_string = @bin_to
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_LINE_' + CAST(@report_line as varchar(10))
			SET @lp_string = 'Pull ' + RTRIM(@part_no) + ' from Bin No: ' + RTRIM(@bin_from) + ' and place in Custom Bin: ' + @bin_to
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

--			SET @lp_datafield = 'LP_ASSEMBLY_' + CAST(@report_line as varchar(10))
--			SET @lp_string = ''
--			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @report_line = @report_line + 1

		END
		ELSE
		BEGIN

			SET @lp_datafield = 'LP_QUEUE_TRAN_' + CAST(@report_line as varchar(10))
			SET @lp_string = CAST(@queue_tran_id as varchar(10))
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_BIN_TO_' + CAST(@report_line as varchar(10))
			SET @lp_string = @bin_to
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_LINE_' + CAST(@report_line as varchar(10))
			SET @lp_string = 'Pull ' + RTRIM(@part_no) + ' from Bin No: ' + RTRIM(@bin_from) + ' and place in Custom Bin: ' + @bin_to
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

--			SET @lp_datafield = 'LP_ASSEMBLY_' + CAST(@report_line as varchar(10))
--			SET @lp_string = ''
--			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @report_line = @report_line + 1
			SET @first = 0
		END
		SET @data_set = 1
			       					
		DELETE FROM #sub_parts
			
		INSERT INTO #sub_parts (line_no, part_no, res_type, part_type, orig_part_no)
		SELECT	olk.line_no, olk.part_no, imas.type_code, iadd.category_3, cvo.part_no_original 
		FROM	cvo_ord_list_kit cvo (NOLOCK), ord_list_kit olk (NOLOCK), inv_master imas (NOLOCK), inv_master_add iadd (NOLOCK)
		WHERE	cvo.order_no = olk.order_no	
		AND		cvo.order_ext = olk.order_ext 
		AND		cvo.location = olk.location	
		AND		cvo.line_no = olk.line_no	
		AND		cvo.part_no	= olk.part_no	
		AND		cvo.part_no	= imas.part_no	
		AND		cvo.part_no = iadd.part_no	
		AND		cvo.order_no = @order_no
		AND		cvo.order_ext = @order_ext	
		AND		cvo.location = @location 
		AND		cvo.line_no = @line_no
		AND		cvo.replaced = 'S'  			

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@sub_part_no = part_no,
				@sub_orig_part = orig_part_no
		FROM	#sub_parts
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			SELECT	@bin_from = bin_no,
					@queue_tran_id = tran_id
			FROM	tdc_pick_queue (NOLOCK)
			WHERE	trans_type_no = @order_no    
			AND		trans_type_ext = @order_ext 
			AND		location = @location  
			AND		line_no  = @line_no 
			AND		part_no = @sub_part_no 
			AND		trans = 'MGTB2B'	

			-- Check page throw
			IF (@report_line > @max_lines)
			BEGIN

				IF (@first = 0)
				BEGIN
					WHILE (@assm_line <= @max_lines)
					BEGIN

						SET @lp_datafield = 'LP_ASSEMBLY_' + CAST(@assm_line as varchar(10))
						SET @lp_string = ''
						INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

						SET @assm_line = @assm_line + 1

					END			
				END

				SET @first = 1
				SET @report_line = 1
				SET @assm_line = 1

				SET @lp_datafield = 'LP_QUEUE_TRAN_' + CAST(@report_line as varchar(10))
				SET @lp_string = CAST(@queue_tran_id as varchar(10))
				INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

				SET @lp_datafield = 'LP_BIN_TO_' + CAST(@report_line as varchar(10))
				SET @lp_string = ''
				INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

				SET @lp_datafield = 'LP_LINE_' + CAST(@report_line as varchar(10))
				SET @lp_string = 'Pull ' + RTRIM(@sub_part_no) + ' from Bin No: ' + RTRIM(@bin_from) + ' and place in Custom Bin: ' + @bin_to
				INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

				SET @lp_datafield = 'LP_ASSEMBLY_' + CAST(@assm_line as varchar(10))
				SET @lp_string = 'Replace Part: ' + RTRIM(@sub_orig_part) + ' With Part: ' + RTRIM(@sub_part_no)
				INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

				SET @report_line = @report_line + 1
				SET @assm_line = @assm_line + 1

			END
			ELSE
			BEGIN

				SET @lp_datafield = 'LP_QUEUE_TRAN_' + CAST(@report_line as varchar(10))
				SET @lp_string = CAST(@queue_tran_id as varchar(10))
				INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

				SET @lp_datafield = 'LP_BIN_TO_' + CAST(@report_line as varchar(10))
				SET @lp_string = ''
				INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

				SET @lp_datafield = 'LP_LINE_' + CAST(@report_line as varchar(10))
				SET @lp_string = 'Pull ' + RTRIM(@sub_part_no) + ' from Bin No: ' + RTRIM(@bin_from) + ' and place in Custom Bin: ' + @bin_to
				INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

				SET @lp_datafield = 'LP_ASSEMBLY_' + CAST(@assm_line as varchar(10))
				SET @lp_string = 'Replace Part: ' + RTRIM(@sub_orig_part) + ' With Part: ' + RTRIM(@sub_part_no)
				INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

				SET @report_line = @report_line + 1
				SET @assm_line = @assm_line + 1
				SET @first = 0
			END
			SET @data_set = 1

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@sub_part_no = part_no,
					@sub_orig_part = orig_part_no
			FROM	#sub_parts
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

		END


		FETCH NEXT FROM values_cur 
		INTO @order_no, @order_ext, @location, @line_no, @part_no, @part_type			
	END
	CLOSE values_cur
	DEALLOCATE values_cur	

	IF (@data_set = 1)
	BEGIN
		WHILE (@report_line <= @max_lines)
		BEGIN

			SET @lp_datafield = 'LP_QUEUE_TRAN_' + CAST(@report_line as varchar(10))
			SET @lp_string = ''
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_BIN_TO_' + CAST(@report_line as varchar(10))
			SET @lp_string = ''
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_LINE_' + CAST(@report_line as varchar(10))
			SET @lp_string = ''
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)


			SET @report_line = @report_line + 1

		END	

		WHILE (@assm_line <= @max_lines)
		BEGIN

			SET @lp_datafield = 'LP_ASSEMBLY_' + CAST(@assm_line as varchar(10))
			SET @lp_string = ''
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @assm_line = @assm_line + 1

		END	

	END

	EXEC CVO_disassembled_print_inv_adjust_sp @order_no, @order_ext, 0

	-- INITIALIZE
	SET @lp_string = ''
	SET @lp_datafield = ''
	SET @bin_to = 'CUSTOM'
	SET @report_line = 11
	SET @max_lines = 10
	SET @data_set = 0


	-- PROCESSING
	DECLARE values_cur_kit CURSOR FOR  	
	SELECT	ol.order_no, 
			ol.order_ext, 
			location, 
			ol.line_no, 
			ol.part_no,
			ol.part_type
	FROM    CVO_ord_list cvo (NOLOCK), ord_list ol (NOLOCK)
	WHERE   cvo.order_no = ol.order_no	
	AND		cvo.order_ext = ol.order_ext	
	AND		cvo.line_no = ol.line_no	
	AND		cvo.order_no = @order_no
	AND		cvo.order_ext = @order_ext	
	AND		cvo.is_customized = 'S'
	AND		ol.part_type = 'C'
									  									  									  	
	OPEN values_cur_kit

	FETCH NEXT FROM values_cur_kit 
	INTO @order_no, @order_ext, @location, @line_no, @part_no, @part_type

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- v1.2 Start
		IF OBJECT_ID('tempdb..#line_exclusions') IS NOT NULL
		BEGIN
			IF EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no)
			BEGIN

				FETCH NEXT FROM values_cur_kit 
				INTO @order_no, @order_ext, @location, @line_no, @part_no, @part_type

				CONTINUE
			END
		END
		-- v1.2 End
	       					
		DELETE FROM #sub_parts_kit
			
		INSERT INTO #sub_parts_kit (line_no, part_no, res_type, part_type, orig_part_no, from_bin, qty_to_process, tran_id)
		SELECT	olk.line_no, olk.part_no, imas.type_code, iadd.category_3, cvo.part_no_original, bin_no, qty_to_process, tran_id  
		FROM	cvo_ord_list_kit cvo (NOLOCK), ord_list_kit olk (NOLOCK), inv_master imas (NOLOCK), inv_master_add iadd (NOLOCK), tdc_pick_queue pq (NOLOCK)
		WHERE	cvo.order_no = olk.order_no	
		AND		cvo.order_ext = olk.order_ext 
		AND		cvo.location = olk.location	
		AND		cvo.line_no = olk.line_no	
		AND		cvo.part_no	= olk.part_no	
		AND		cvo.part_no	= imas.part_no	
		AND		cvo.part_no = iadd.part_no	
		AND		olk.order_no = pq.trans_type_no
		AND		olk.order_ext = pq.trans_type_ext
		AND		olk.line_no = pq.line_no
		AND		olk.part_no = pq.part_no
		AND		cvo.order_no = @order_no
		AND		cvo.order_ext = @order_ext	
		AND		cvo.location = @location 
		AND		cvo.line_no = @line_no
		AND		cvo.replaced = 'S' 
		AND		pq.trans = 'STDPICK' 			

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@sub_part_no = part_no,
				@sub_orig_part = orig_part_no,
				@bin_from = from_bin,
				@qty = qty_to_process,
				@tran_id = tran_id
		FROM	#sub_parts_kit
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			-- Check page throw
			IF (@report_line > @max_lines)
			BEGIN
				SET @report_line = 1

				/******************************************************************** HEADER ********************************************************************/				
				SET @lp_datafield = 'LP_TO_BIN'
				SET @lp_string = @bin_to
				INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			END

			SET @data_set = 1

			SET @lp_datafield = 'LP_TRANID_' + CAST(@report_line as varchar(10))
			SET @lp_string = CAST(@tran_id as varchar(13))
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_LINENO_' + CAST(@report_line as varchar(10))
			SET @lp_string = CAST(@line_no as varchar(8))
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_PARTNO_' + CAST(@report_line as varchar(10))
			SET @lp_string = @sub_part_no
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_QTY_' + CAST(@report_line as varchar(10))
			SET @lp_string = CAST(@qty as varchar(20))
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_FROM_BIN_' + CAST(@report_line as varchar(10))
			SET @lp_string = @bin_from
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @report_line = @report_line + 1

			-- Check page throw
			IF (@report_line > @max_lines)
			BEGIN
				SET @report_line = 1

				/******************************************************************** HEADER ********************************************************************/				
				SET @lp_datafield = 'LP_TO_BIN'
				SET @lp_string = @bin_to
				INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)
			END

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@sub_part_no = part_no,
					@sub_orig_part = orig_part_no,
					@bin_from = from_bin,
					@qty = qty_to_process,
					@tran_id = tran_id
			FROM	#sub_parts_kit
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		END

		FETCH NEXT FROM values_cur_kit 
		INTO @order_no, @order_ext, @location, @line_no, @part_no, @part_type			
	END
	CLOSE values_cur_kit
	DEALLOCATE values_cur_kit	

	IF (@data_set = 1)
	BEGIN
		WHILE (@report_line <= @max_lines)
		BEGIN

			SET @lp_datafield = 'LP_TRANID_' + CAST(@report_line as varchar(10))
			SET @lp_string = ''
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_LINENO_' + CAST(@report_line as varchar(10))
			SET @lp_string = ''
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_PARTNO_' + CAST(@report_line as varchar(10))
			SET @lp_string = ''
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_QTY_' + CAST(@report_line as varchar(10))
			SET @lp_string = ''
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @lp_datafield = 'LP_FROM_BIN_' + CAST(@report_line as varchar(10))
			SET @lp_string = ''
			INSERT INTO #PrintData(data_field, data_value) VALUES (@lp_datafield, @lp_string)

			SET @report_line = @report_line + 1

		END	
	END

	EXEC CVO_disassembled_print_inv_adjust_sp @order_no, @order_ext, 1


END
GO
GRANT EXECUTE ON  [dbo].[CVO_disassembled_inv_adjust_sp] TO [public]
GO
