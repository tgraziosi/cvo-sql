
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[CVO_allocate_by_bin_group_adjust_sp]    Script Date: 08/18/2010  *****
SED009 -- AutoAllocation   
Object:      Procedure  CVO_allocate_by_bin_group_adjust_sp  
Source file: CVO_allocate_by_bin_group_adjust_sp.sql
Author:		 Jesus Velazquez
Created:	 08/18/2010
Function:    
Modified:    
Calls:    
Called by:   
Copyright:   Epicor Software 2010.  All rights reserved.  
 v1.0 CB 01/05/2012 - Stop the routine being called for orders that are not selected in PWB
 v1.1 CB 01/05/2013 - Replace cursors
 v1.2 CB 26/01/2016 - #1581 2nd Polarized Option
*/
CREATE PROCEDURE [dbo].[CVO_allocate_by_bin_group_adjust_sp]
	@alloc_from_ebo	INT = 0
AS

BEGIN
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
		@polarized_type			varchar(10) -- v1.2

-- v1.1 Start
DECLARE	@row_id				int,
		@last_row_id		int,
		@line_row_id		int,
		@last_line_row_id	int
-- v1.1 End

	SET @frame		= [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_FRAME')
	SET @case		= [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE')
	SET @pattern	= [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_PATTERN')
	SET @polarized_type = 'PARTS' -- v1.2
-- v1.2	SET @polarized	= [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_POLARIZED') 

	--HEADER
	--works with a copy of #so_alloc_management
	IF (object_id('tempdb..#so_alloc_management_BAK')IS NOT NULL) 
		DROP TABLE #so_alloc_management_BAK

	--create tabel definition
	CREATE TABLE #so_alloc_management_BAK 
	(order_no	INT             NOT NULL,
	order_ext	INT             NOT NULL,
	location	VARCHAR(10)     NOT NULL)


	IF (@alloc_from_ebo = 0)
	BEGIN
		--used when called from VB
		INSERT INTO #so_alloc_management_BAK (order_no, order_ext, location) SELECT order_no, order_ext, location FROM #so_alloc_management WHERE sel_flg <> 0 -- v1.0
	END
	ELSE
		--used when called from eBO
		INSERT INTO #so_alloc_management_BAK (order_no, order_ext, location) SELECT order_no, order_ext, location FROM #so_alloc_management_Header --348, 0 , 'Dallas'
						
	--DETAIL
	IF (object_id('tempdb..#so_allocation_detail_view_BAK')IS NOT NULL) 
		DROP TABLE #so_allocation_detail_view_BAK
	
	CREATE TABLE #so_allocation_detail_view_BAK         
	(order_no       INT             NOT NULL,    
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
					AND a.order_ext = b.order_ext WHERE b.sel_flg <> 0 -- v1.0
	ELSE
	BEGIN
		-- v1.1 Start
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
			
--		DECLARE detail_cursor CURSOR FOR 
--		SELECT order_no, order_ext, line_no, location FROM #so_allocation_detail_view_Detail
--
--		OPEN detail_cursor
--
--		FETCH NEXT FROM detail_cursor 
--		INTO @order_no, @order_ext, @line_no, @location
--
--		WHILE @@FETCH_STATUS = 0
--		BEGIN
		-- v1.1 End

			UPDATE #so_allocation_detail_view_Detail 	
			SET    qty_alloc = (SELECT	ISNULL(SUM(qty),0)
								FROM	tdc_soft_alloc_tbl (NOLOCK) 
								WHERE	order_no	= @order_no		AND
										order_ext	= @order_ext	AND
										line_no		= @line_no		AND
										location	= @location)
			WHERE	order_no	= @order_no		AND
					order_ext	= @order_ext	AND
					line_no		= @line_no		AND
					location	= @location							   

			-- v1.1 Start
			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@line_no = line_no,
					@location = location
			FROM	#bga_detail_cursor
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		   
--		   FETCH NEXT FROM detail_cursor 
--		   INTO @order_no, @order_ext, @line_no, @location
		END

--		CLOSE detail_cursor
--		DEALLOCATE detail_cursor

		DROP TABLE #bga_detail_cursor
		-- v1.1 End
		--used when called from eBO
		INSERT INTO #so_allocation_detail_view_BAK SELECT * FROM #so_allocation_detail_view_Detail
	END

--IF (object_id('tmp_#so_allocation_detail_view_Detail')IS NOT NULL) 
--		DROP TABLE tmp_#so_allocation_detail_view_Detail
--
--select * into tmp_#so_allocation_detail_view_Detail from #so_allocation_detail_view_Detail

	/*IF (object_id('tempdb..##algo')IS NOT NULL) 
		DROP TABLE ##algo
	
	select * into ##algo from #so_allocation_detail_view_BAK
	
	select * from ##algo*/
	
	-- v1.1 Start
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
	
--	DECLARE selected_orders_cur CURSOR FOR
--			  					SELECT order_no, order_ext, location FROM #so_alloc_management_BAK
--	
--	OPEN selected_orders_cur
--
--	FETCH NEXT FROM selected_orders_cur INTO @order_no, @order_ext, @location
--	WHILE @@FETCH_STATUS = 0
--	BEGIN
		
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

--		DECLARE alloc_line_cur CURSOR FOR -- all packages for this sales orders
--								SELECT	line_no, part_no
--								FROM	#so_allocation_detail_view_BAK 
--								WHERE	from_line_no	= 0		AND 
--										order_no   = @order_no	AND  
--										order_ext  = @order_ext	AND  
--										location   = @location	
--								ORDER BY line_no, part_no
--
--		OPEN alloc_line_cur		
--		
--
--		FETCH NEXT FROM alloc_line_cur INTO @line_no, @part_no		
--		WHILE @@FETCH_STATUS = 0
--		BEGIN					
	-- v1.1 End

		-- v1.2 Start
		SELECT	@polarized = polarized_part
		FROM	cvo_ord_list_fc (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no = @line_no
		-- v1.2 End

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

					  /*--case 1					--(100=100)			
						--case 2					--(100=100)AND(85<100)*/							
						--case 3					--(85<100)AND(100=100)
						IF (@qty_alloc_case > @qty_alloc_frame)
						--unallocate cases
						BEGIN
							SET @log_info = @log_info + ' unallocate cases'
							SET @needed_part_no = @case_name
							SET @needed_line_no = @case_line_no
							SET @needed_qty		= @qty_alloc_case - @qty_alloc_frame
							EXEC CVO_unallocate_line_no_sp @order_no, @order_ext, @location, @needed_part_no, @needed_line_no, @needed_qty, @log_info, @alloc_from_ebo
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
							EXEC CVO_unallocate_line_no_sp @order_no, @order_ext, @location, @needed_part_no, @needed_line_no, @needed_qty, @log_info, @alloc_from_ebo
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
							EXEC CVO_unallocate_line_no_sp @order_no, @order_ext, @location, @needed_part_no, @needed_line_no, @needed_qty, @log_info, @alloc_from_ebo
						END					
						
						IF (@qty_alloc_frame < @qty_alloc_polarized)
						BEGIN
							SET @needed_part_no  = @polarized_name
							SET @needed_line_no  = @polarized_line_no					
							SET @needed_qty		 = @qty_alloc_polarized - @qty_alloc_frame
							SET @log_info        = @log_info + ' unallocate polarized'
							print @needed_qty
							EXEC CVO_unallocate_line_no_sp @order_no, @order_ext, @location, @needed_part_no, @needed_line_no, @needed_qty, @log_info, @alloc_from_ebo
						END		
						  
						IF (@qty_alloc_frame < @qty_alloc_case) AND (@qty_alloc_frame > 0)
						BEGIN
							SET @needed_part_no = @case_name
							SET @needed_line_no = @case_line_no					
							SET @needed_qty		= @qty_alloc_case - @qty_alloc_frame									
							SET @qty_alloc_case = @qty_alloc_polarized	
							SET @log_info        = @log_info + ', unalocate case'	
							EXEC CVO_unallocate_line_no_sp @order_no, @order_ext, @location, @needed_part_no, @needed_line_no, @needed_qty, @log_info, @alloc_from_ebo
						END																		
					END																																		  	
				END							
			-- END SUM(qty_picked)=0										
			END 	
		-- v1.1 Start

			SET @last_line_row_id = @line_row_id

			SELECT	TOP 1 @line_row_id = line_row_id,	
					@line_no = line_no,
					@part_no = part_no
			FROM	#bga_alloc_line_cur
			WHERE	line_row_id > @last_line_row_id
			ORDER BY line_row_id ASC					
--			FETCH NEXT FROM alloc_line_cur  INTO @line_no, @part_no
		END
--		CLOSE      alloc_line_cur	
--		DEALLOCATE alloc_line_cur

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@location = location
		FROM	#bga_selected_orders_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

--		FETCH NEXT FROM selected_orders_cur INTO @order_no, @order_ext, @location
	END
--	CLOSE      selected_orders_cur	
--	DEALLOCATE selected_orders_cur
	DROP TABLE #bga_selected_orders_cur
	DROP TABLE #bga_alloc_line_cur
	-- v1.1 End
	--return data to #so_alloc_management
	--DELETE FROM #so_alloc_management	
	--INSERT INTO #so_alloc_management SELECT * FROM #so_alloc_management_BAK
END
-- Permissions
GO

GRANT EXECUTE ON  [dbo].[CVO_allocate_by_bin_group_adjust_sp] TO [public]
GO
