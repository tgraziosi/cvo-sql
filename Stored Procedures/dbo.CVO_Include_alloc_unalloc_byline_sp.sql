
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  StoredProcedure [dbo].[CVO_Include_alloc_unalloc_byline_sp]    Script Date: 04/01/2010  *****
SED003 -- Case Part
Object:      Procedure CVO_Include_alloc_unalloc_byline_sp  
Source file: CVO_Include_alloc_unalloc_byline_sp.sql
Author:		 Jesus Velazquez
Created:	 04/05/2010
Function:    When user selects a frame then add the polarized into #so_soft_alloc_byline_tbl_TMP table
Modified:    
Calls:    
Called by:   WMS74 -- Allocation Screen
Copyright:   Epicor Software 2010.  All rights reserved.  
*/

-- v1.0 CB 19/05/2011 - Future Allocations
-- v1.1 CB 04/09/2012 - Issue #839 Alloc / UnAlloc associated cases etc when running by line
-- v1.2 CB 10/10/2012 - When unallocating then use the allocated quantity
-- v1.3 CB 07/06/2013 - Issue #1289 - Frame/case relationship at order entry
-- v1.4 CB 26/01/2016 - #1581 2nd Polarized Option

CREATE PROCEDURE [dbo].[CVO_Include_alloc_unalloc_byline_sp] AS

BEGIN
   
	DECLARE  @order_no				INT
			,@order_ext				INT 
			,@part_no				VARCHAR(40) 
			,@line_no				INT
			,@from_line_no			INT		
		    ,@case				VARCHAR(10)
			,@pattern			VARCHAR(10)
			,@polarized			VARCHAR(10)
			,@type_code			VARCHAR(10),
			@case_part			varchar(30), -- v1.1
			@pattern_part		varchar(30), -- v1.1
			@qty_override		decimal(20,8), -- v1.1
			@qty_alloc			decimal(20,8) -- v1.2


	-- v1.1
	CREATE TABLE #splits (
			order_no		int,
			order_ext		int,
			line_no			int,
			location		varchar(10),
			part_no			varchar(30),
			has_case		int,
			has_pattern		int,
			has_polarized	int,
			case_part		varchar(30),
			pattern_part	varchar(30),
			polarized_part	varchar(30),
			quantity		decimal(20,8),
			material		smallint,
			part_type		varchar(20),
			new_ext			int)

	

	SET @case	   = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE')
	SET @pattern   = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_PATTERN')
-- v1.4	SET @polarized = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_POLARIZED') 

	-- v1.1 #Splits table shows the relationship of cases to frames
	INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
						pattern_part, polarized_part, quantity, material, part_type, new_ext)
	SELECT	a.order_no,
			a.order_ext,
			a.line_no,
			a.location,
			a.part_no,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN 1 ELSE 0 END,
-- v1.3		CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN c.field_1 ELSE '' END,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN fc.case_part ELSE '' END, -- v1.3
-- v1.3		CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN c.field_4 ELSE '' END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN fc.pattern_part ELSE '' END, -- v1.3
-- v1.4		CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN @polarized ELSE '' END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN fc.polarized_part ELSE '' END, -- v1.4
			a.ordered,
			CASE WHEN LEFT(c.field_10,5) = 'metal' THEN 1 ELSE CASE WHEN LEFT(c.field_10,7) = 'plastic' THEN 2 ELSE 0 END END,
			d.type_code,
			0
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	inv_master_add c (NOLOCK)
	ON		a.part_no = c.part_no
	LEFT JOIN cvo_ord_list_fc fc (NOLOCK) -- v1.3
	ON		a.order_no = fc.order_no -- v1.3
	AND		a.order_ext = fc.order_ext -- v1.3
	AND		a.line_no = fc.line_no -- v1.3
	JOIN	inv_master d (NOLOCK)
	ON		a.part_no = d.part_no
	JOIN	#so_alloc_management so (NOLOCK)
	ON		a.order_no = so.order_no
	AND		a.order_ext = so.order_ext
	WHERE	(so.sel_flg2 != 0 OR so.sel_flg != 0)
	ORDER BY a.line_no


	IF OBJECT_ID('tempdb..#so_soft_alloc_byline_tbl_TMP') IS NOT NULL 
		DROP TABLE #so_soft_alloc_byline_tbl_TMP

	--create tmp table
	SELECT DISTINCT * INTO #so_soft_alloc_byline_tbl_TMP FROM #so_soft_alloc_byline_tbl WHERE order_no < 0

	--loop selected items to include the frame or polarized to unallocated
	DECLARE unalloc_cur CURSOR FOR 
							   SELECT  order_no, order_ext,  line_no, part_no, from_line_no, type_code--is_case, is_pattern, is_polarized
							   FROM    #so_soft_alloc_byline_tbl

	OPEN unalloc_cur

		FETCH NEXT FROM unalloc_cur 
		INTO @order_no, @order_ext, @line_no, @part_no, @from_line_no, @type_code--@is_case, @is_pattern, @is_polarized

		WHILE @@FETCH_STATUS = 0
		BEGIN

			IF @from_line_no = 0 -- is frame then include the polarized
				INSERT INTO #so_soft_alloc_byline_tbl_TMP (order_no, order_ext,  line_no, part_no, from_line_no, type_code)--is_case, is_pattern, is_polarized)
				SELECT order_no, order_ext,  line_no, part_no, from_line_no, type_code--is_case, is_pattern, is_polarized
				FROM   #so_allocation_detail_view_Detail
				WHERE  from_line_no = @line_no AND
					   @type_code = @polarized--is_polarized = 1	
			
			IF @type_code = @polarized--IF @is_polarized = 1 -- is polarized then include the frame
				INSERT INTO #so_soft_alloc_byline_tbl_TMP (order_no, order_ext,  line_no, part_no, from_line_no, type_code)--is_case, is_pattern, is_polarized)
				SELECT order_no, order_ext,  line_no, part_no, from_line_no, type_code--is_case, is_pattern, is_polarized
				FROM   #so_allocation_detail_view_Detail
				WHERE  line_no = @from_line_no

			-- v1.1 Start - Add cases and patterns
			SELECT	@case_part = case_part,
					@qty_override = quantity
			FROM	#splits
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		has_case = 1

			IF (ISNULL(@case_part,'') > '') -- Case exists
			BEGIN

				-- v1.2 Start
				SELECT	@from_line_no = line_no
				FROM	#splits
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		part_no = @case_part
				AND		case_part IS NOT NULL

				SELECT	@qty_alloc = SUM(qty)
				FROM	tdc_soft_alloc_tbl (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		line_no = @from_line_no
				AND		order_type = 'S'		

				IF @qty_alloc < @qty_override
					SET @qty_override = @qty_alloc
				-- v1.2 End

				INSERT INTO #so_soft_alloc_byline_tbl_TMP (order_no, order_ext,  line_no, part_no, from_line_no, type_code, qty_override)
				SELECT @order_no, @order_ext, line_no, part_no, @from_line_no, part_type, @qty_override
				FROM	#splits
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		part_no = @case_part
				AND		part_type = @case
			END

			SELECT	@pattern_part = pattern_part,
					@qty_override = quantity
			FROM	#splits
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		has_pattern = 1

			IF (ISNULL(@pattern_part,'') > '') -- Pattern exists
			BEGIN

				-- v1.2 Start
				SELECT	@from_line_no = line_no
				FROM	#splits
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		part_no = @pattern_part
				AND		pattern_part IS NOT NULL

				SELECT	@qty_alloc = SUM(qty)
				FROM	tdc_soft_alloc_tbl (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		line_no = @from_line_no	
				AND		order_type = 'S'	

				IF @qty_alloc < @qty_override
					SET @qty_override = @qty_alloc
				-- v1.2 End
				INSERT INTO #so_soft_alloc_byline_tbl_TMP (order_no, order_ext,  line_no, part_no, from_line_no, type_code, qty_override)
				SELECT @order_no, @order_ext, line_no, part_no, @from_line_no, part_type, @qty_override
				FROM	#splits
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		part_no = @pattern_part
				AND		part_type = @pattern
			END
			-- v1.1 End - Add cases and patterns
		  
			-- v1.4 Start - Polarized
			SELECT	@polarized = polarized_part,
					@qty_override = quantity
			FROM	#splits
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		has_polarized = 1

			IF (ISNULL(@polarized,'') > '') -- Pattern exists
			BEGIN

				-- v1.2 Start
				SELECT	@from_line_no = line_no
				FROM	#splits
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		part_no = @polarized
				AND		@polarized IS NOT NULL

				SELECT	@qty_alloc = SUM(qty)
				FROM	tdc_soft_alloc_tbl (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		line_no = @from_line_no	
				AND		order_type = 'S'	

				IF @qty_alloc < @qty_override
					SET @qty_override = @qty_alloc
				-- v1.2 End
				INSERT INTO #so_soft_alloc_byline_tbl_TMP (order_no, order_ext,  line_no, part_no, from_line_no, type_code, qty_override)
				SELECT @order_no, @order_ext, line_no, part_no, @from_line_no, part_type, @qty_override
				FROM	#splits
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		part_no = @polarized
			END
			-- v1.1 End - Add cases and patterns


		   FETCH NEXT FROM unalloc_cur 
		   INTO @order_no, @order_ext, @line_no, @part_no, @from_line_no, @type_code--@is_case, @is_pattern, @is_polarized
		END

	CLOSE unalloc_cur
	DEALLOCATE unalloc_cur	
		   
	INSERT INTO #so_soft_alloc_byline_tbl
	SELECT * FROM #so_soft_alloc_byline_tbl_TMP
	

--	SELECT * INTO ##algo  FROM #so_soft_alloc_byline_tbl

-- v1.0 Start - Unmark any records where the allocation date is in the future
DELETE	a
FROM	#so_soft_alloc_byline_tbl a
JOIN	dbo.cvo_orders_all b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.order_ext = b.ext
WHERE	ISNULL(b.allocation_date,GETDATE()-1) > GETDATE()
-- v1.0 End

	
END
GO

GRANT EXECUTE ON  [dbo].[CVO_Include_alloc_unalloc_byline_sp] TO [public] WITH GRANT OPTION
GO
