SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_sim_allocate_by_bin_group_adjust_sp] @alloc_from_ebo	INT = 0
AS
BEGIN
	-- NOTE: Routine based on CVO_allocate_by_bin_group_adjust_sp v1.2 - All changes must be kept in sync

	DECLARE @order_no				INT,
			@order_ext				INT, 
			@location				VARCHAR(30),
			@line_no				INT,
			@part_no				VARCHAR(30),
			@qty_alloc_frame		INT,			
			@qty_alloc_case			INT,						
			@qty_alloc_polarized	INT,
			@frame					VARCHAR(10),
			@case					VARCHAR(10),
			@pattern				VARCHAR(10),			
			@polarized				VARCHAR(10),
			@frame_name				VARCHAR(30),			
			@case_name				VARCHAR(30),						
			@polarized_name			VARCHAR(30),	
			@frame_line_no			INT,
			@case_line_no			INT,
			@polarized_line_no		INT,
			@needed_part_no			VARCHAR(30),	
			@needed_line_no			INT,
			@needed_qty				DECIMAL(20,8),
			@log_info				VARCHAR(100),	
			@polarized_type			varchar(10) 

	DECLARE	@row_id				int,
			@last_row_id		int,
			@line_row_id		int,
			@last_line_row_id	int

	SET @frame		= [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_FRAME')
	SET @case		= [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE')
	SET @pattern	= [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_PATTERN')
	SET @polarized_type = 'PARTS' 

	--HEADER
	--works with a copy of #so_alloc_management
	IF (object_id('tempdb..#so_alloc_management_BAK')IS NOT NULL) 
		DROP TABLE #so_alloc_management_BAK

	--create tabel definition
	CREATE TABLE #so_alloc_management_BAK (
		order_no	INT             NOT NULL,
		order_ext	INT             NOT NULL,
		location	VARCHAR(10)     NOT NULL)

	IF (@alloc_from_ebo = 0)
	BEGIN
		--used when called from VB
		INSERT INTO #so_alloc_management_BAK (order_no, order_ext, location) SELECT order_no, order_ext, location FROM #so_alloc_management WHERE sel_flg <> 0 
	END
	ELSE
		--used when called from eBO
		INSERT INTO #so_alloc_management_BAK (order_no, order_ext, location) SELECT order_no, order_ext, location FROM #so_alloc_management_Header 
						
	--DETAIL
	IF (object_id('tempdb..#so_allocation_detail_view_BAK')IS NOT NULL) 
		DROP TABLE #so_allocation_detail_view_BAK
	
	CREATE TABLE #so_allocation_detail_view_BAK (
		order_no       INT             NOT NULL,    
		order_ext       INT             NOT NULL,         
		location        VARCHAR(10)     NOT NULL,       
		line_no         INT             NOT NULL,       
		part_no         VARCHAR(30)     NOT NULL,       
		part_desc       VARCHAR(278)        NULL,         
		lb_tracking     CHAR(1)         NOT NULL,       
		qty_ordered     DECIMAL(24, 8)  NOT NULL,       
		qty_avail       DECIMAL(24, 8)  NOT NULL,       
		qty_picked      DECIMAL(24, 8)  NOT NULL,         
		qty_alloc       DECIMAL(24, 8)  NOT NULL,       
		avail_pct       DECIMAL(24,8)   NOT NULL,       
		alloc_pct       DECIMAL(24,8)   NOT NULL,       
		qty_to_alloc    INT                 NULL,         
		type_code       VARCHAR(10)         NULL,       
		from_line_no    INT                 NULL,       
		order_by_frame  INT                 NULL) 


	IF (@alloc_from_ebo = 0)
		--used when called from VB
		INSERT INTO #so_allocation_detail_view_BAK SELECT a.* FROM #so_allocation_detail_view a JOIN #so_alloc_management b ON a.order_no = b.order_no
					AND a.order_ext = b.order_ext WHERE b.sel_flg <> 0
	ELSE
	BEGIN
		CREATE TABLE #bga_detail_cursor (
			row_id			int IDENTITY(1,1),
			order_no		int,
			order_ext		int,
			line_no			int,
			location		varchar(10))

		INSERT	#bga_detail_cursor (order_no, order_ext, line_no, location)
		SELECT order_no, order_ext, line_no, location FROM #so_allocation_detail_view_Detail

		CREATE INDEX #bga_detail_cursor_ind0 ON #bga_detail_cursor(row_id)

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@line_no = line_no,
				@location = location
		FROM	#bga_detail_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			UPDATE #so_allocation_detail_view_Detail 	
			SET    qty_alloc = (SELECT	ISNULL(SUM(qty),0)
								FROM	#sim_tdc_soft_alloc_tbl (NOLOCK) 
								WHERE	order_no	= @order_no		AND
										order_ext	= @order_ext	AND
										line_no		= @line_no		AND
										location	= @location)
			WHERE	order_no	= @order_no		AND
					order_ext	= @order_ext	AND
					line_no		= @line_no		AND
					location	= @location							   

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@line_no = line_no,
					@location = location
			FROM	#bga_detail_cursor
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		   
		END

		DROP TABLE #bga_detail_cursor

		--used when called from eBO
		INSERT INTO #so_allocation_detail_view_BAK SELECT * FROM #so_allocation_detail_view_Detail
	END

	CREATE TABLE #bga_selected_orders_cur (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		location		varchar(10))

	CREATE TABLE #bga_alloc_line_cur (
		line_row_id		int IDENTITY(1,1),
		line_no			int,
		part_no			varchar(30))

	INSERT	#bga_selected_orders_cur (order_no, order_ext, location)
	SELECT order_no, order_ext, location FROM #so_alloc_management_BAK
	
	CREATE INDEX #bga_selected_orders_cur_ind0 ON #bga_selected_orders_cur(row_id)
	CREATE INDEX #bga_alloc_line_cur_ind0 ON #bga_alloc_line_cur(line_row_id)

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@location = location
	FROM	#bga_selected_orders_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN		
			
		DELETE	#bga_alloc_line_cur

		INSERT	#bga_alloc_line_cur (line_no, part_no)
		SELECT	line_no, part_no
		FROM	#so_allocation_detail_view_BAK 
		WHERE	from_line_no	= 0		AND 
		order_no   = @order_no	AND  
		order_ext  = @order_ext	AND  
		location   = @location	
		ORDER BY line_no, part_no	

		SET @last_line_row_id = 0

		SELECT	TOP 1 @line_row_id = line_row_id,	
				@line_no = line_no,
				@part_no = part_no
		FROM	#bga_alloc_line_cur
		WHERE	line_row_id > @last_line_row_id
		ORDER BY line_row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			SELECT	@polarized = polarized_part
			FROM	cvo_ord_list_fc (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no

			--if package is not picked
			IF(SELECT SUM(qty_picked) FROM #so_allocation_detail_view_BAK WHERE (line_no = @line_no OR from_line_no	= @line_no) AND order_no = @order_no AND order_ext = @order_ext AND location = @location) = 0
			BEGIN
			
			--if package has been allocated
				IF(SELECT SUM(qty_alloc)
				   FROM   #so_allocation_detail_view_BAK
				   WHERE  (line_no	= @line_no OR from_line_no	= @line_no)	AND
						   order_no		= @order_no							AND 
						   order_ext	= @order_ext						AND 
						   location		= @location) > 0
				BEGIN

					SET @needed_part_no	= ''
					SET @needed_line_no	= 0
					SET @needed_qty     = 0
					SET @log_info       = ''
					
					--Frame + Case
					IF (SELECT	COUNT(*)  
						FROM	#so_allocation_detail_view_BAK 
						WHERE  (line_no = @line_no OR from_line_no = @line_no)	AND
								order_no  = @order_no							AND 
								order_ext = @order_ext							AND 
								location  = @location) = 2 AND
					   (SELECT	COUNT(*)  
						FROM	#so_allocation_detail_view_BAK 
						WHERE  (line_no = @line_no OR (from_line_no = @line_no AND type_code = @case))	AND
								order_no  = @order_no													AND 
								order_ext = @order_ext													AND 
								location  = @location) = 2					

					BEGIN	
						SET @log_info = 'Frame + Case, '
					
						--get frame qty
						SELECT @frame_name		 = part_no,
							   @frame_line_no	 = line_no,
							   @qty_alloc_frame = qty_alloc
						FROM   #so_allocation_detail_view_BAK 
						WHERE  line_no	 = @line_no		AND 
							   order_no	 = @order_no	AND 
							   order_ext = @order_ext	AND 
							   location	 = @location

						--get case qty
						SELECT @case_name		= part_no,
							   @case_line_no	= line_no,
							   @qty_alloc_case	= qty_alloc
						FROM   #so_allocation_detail_view_BAK 
						WHERE  (from_line_no = @line_no AND type_code = @case)	AND	
							   order_no	 = @order_no							AND 
							   order_ext = @order_ext							AND 
							   location	 = @location																				  

						IF (@qty_alloc_case > @qty_alloc_frame)
						--unallocate cases
						BEGIN
							SET @log_info = @log_info + ' unallocate cases'
							SET @needed_part_no = @case_name
							SET @needed_line_no = @case_line_no
							SET @needed_qty		= @qty_alloc_case - @qty_alloc_frame
							EXEC CVO_sim_unallocate_line_no_sp @order_no, @order_ext, @location, @needed_part_no, @needed_line_no, @needed_qty, @log_info, @alloc_from_ebo
						END
					END								
					
					--Frame + Polarized		
					IF (SELECT COUNT(*)
						FROM   #so_allocation_detail_view_BAK 
						WHERE  (line_no = @line_no OR from_line_no = @line_no)	AND
								order_no		= @order_no						AND  
								order_ext		= @order_ext					AND  
								location		= @location) = 2 AND
					   (SELECT COUNT(*)
						FROM   #so_allocation_detail_view_BAK 
						WHERE  (line_no = @line_no OR (from_line_no = @line_no AND type_code = @polarized_type))	AND -- v1.2
								order_no		= @order_no													AND  
								order_ext		= @order_ext												AND  
								location		= @location) = 2 
					   							
					BEGIN										 						
						SET @log_info = 'Frame + Polarized, '
						SELECT   @frame_name	  = part_no,
								 @frame_line_no	  = line_no,					
								 @qty_alloc_frame = qty_alloc
						FROM     #so_allocation_detail_view_BAK
						WHERE	 line_no		= @line_no		AND
								 order_no		= @order_no		AND  
								 order_ext		= @order_ext	AND  
								 location		= @location						  	
								  
						SELECT   @polarized_name		= part_no,
								 @polarized_line_no		= line_no,
								 @qty_alloc_polarized	= qty_alloc
						FROM     #so_allocation_detail_view_BAK
						WHERE	 (from_line_no  = @line_no AND part_no  = @polarized)	AND
								 order_no		= @order_no								AND  
								 order_ext		= @order_ext							AND  
								 location		= @location		
														 
						IF @qty_alloc_frame > @qty_alloc_polarized
						BEGIN
							SET @needed_part_no = @frame_name
							SET @needed_line_no = @frame_line_no					
							SET @needed_qty		= @qty_alloc_frame - @qty_alloc_polarized
							SET @log_info       = @log_info + ' unallocate frames'
						END

						IF @qty_alloc_polarized > @qty_alloc_frame
						BEGIN
							SET @needed_part_no = @polarized_name
							SET @needed_line_no = @polarized_line_no					
							SET @needed_qty		= @qty_alloc_polarized - @qty_alloc_frame	
							SET @log_info       = @log_info + ' unallocate polarized'
						END
						
						IF (@needed_part_no <> '' AND @needed_line_no > 0 AND @needed_qty > 0)
							EXEC CVO_sim_unallocate_line_no_sp @order_no, @order_ext, @location, @needed_part_no, @needed_line_no, @needed_qty, @log_info, @alloc_from_ebo
					END		
					
					--Frame + Case + Polarized										
					IF (SELECT COUNT(*) 
						FROM   #so_allocation_detail_view_BAK 
						WHERE  (from_line_no = @line_no OR line_no = @line_no)	AND 
							   order_no		= @order_no							AND 
							   order_ext	= @order_ext						AND 
							   location		= @location) >= 3
					BEGIN						      					
						SET @log_info       =  'Frame + Case + Polarized, '
						SELECT	@frame_name		 = part_no,
								@frame_line_no	 = line_no,
								@qty_alloc_frame = qty_alloc
						FROM    #so_allocation_detail_view_BAK
						WHERE	line_no		= @line_no		AND
								order_no	= @order_no		AND  
								order_ext	= @order_ext	AND  
								location	= @location								  	

						SELECT  @case_name		 = part_no,
								@case_line_no	 = line_no,
								@qty_alloc_case	 = qty_alloc
						FROM    #so_allocation_detail_view_BAK 
						WHERE   (from_line_no = @line_no AND type_code = @case)	AND	
								order_no  = @order_no							AND 
								order_ext = @order_ext							AND 
								location  = @location	
								  
						SELECT	@polarized_name			= part_no,
								@polarized_line_no		= line_no,
								@qty_alloc_polarized	= qty_alloc
						FROM    #so_allocation_detail_view_BAK
						WHERE	(from_line_no  = @line_no AND part_no  = @polarized)AND
								order_no		= @order_no							AND  
								order_ext		= @order_ext						AND  
								location		= @location			
						
						IF (@qty_alloc_frame > @qty_alloc_polarized) AND (@qty_alloc_polarized > 0)
						BEGIN
							SET @needed_part_no  = @frame_name
							SET @needed_line_no  = @frame_line_no					
							SET @needed_qty		 = @qty_alloc_frame - @qty_alloc_polarized									
							SET @qty_alloc_frame = @qty_alloc_polarized		
							SET @log_info        = @log_info + ' unallocate frame'
							print @needed_qty
							EXEC CVO_sim_unallocate_line_no_sp @order_no, @order_ext, @location, @needed_part_no, @needed_line_no, @needed_qty, @log_info, @alloc_from_ebo
						END					
						
						IF (@qty_alloc_frame < @qty_alloc_polarized)
						BEGIN
							SET @needed_part_no  = @polarized_name
							SET @needed_line_no  = @polarized_line_no					
							SET @needed_qty		 = @qty_alloc_polarized - @qty_alloc_frame
							SET @log_info        = @log_info + ' unallocate polarized'
							print @needed_qty
							EXEC CVO_sim_unallocate_line_no_sp @order_no, @order_ext, @location, @needed_part_no, @needed_line_no, @needed_qty, @log_info, @alloc_from_ebo
						END		
						  
						IF (@qty_alloc_frame < @qty_alloc_case) AND (@qty_alloc_frame > 0)
						BEGIN
							SET @needed_part_no = @case_name
							SET @needed_line_no = @case_line_no					
							SET @needed_qty		= @qty_alloc_case - @qty_alloc_frame									
							SET @qty_alloc_case = @qty_alloc_polarized	
							SET @log_info        = @log_info + ', unalocate case'	
							EXEC CVO_sim_unallocate_line_no_sp @order_no, @order_ext, @location, @needed_part_no, @needed_line_no, @needed_qty, @log_info, @alloc_from_ebo
						END																		
					END																																		  	
				END							
			END 	

			SET @last_line_row_id = @line_row_id

			SELECT	TOP 1 @line_row_id = line_row_id,	
					@line_no = line_no,
					@part_no = part_no
			FROM	#bga_alloc_line_cur
			WHERE	line_row_id > @last_line_row_id
			ORDER BY line_row_id ASC					
		END

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@location = location
		FROM	#bga_selected_orders_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END
	DROP TABLE #bga_selected_orders_cur
	DROP TABLE #bga_alloc_line_cur
END

GO
GRANT EXECUTE ON  [dbo].[CVO_sim_allocate_by_bin_group_adjust_sp] TO [public]
GO
