
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_create_fc_relationship_sp]	@order_no	int,
												@order_ext	int
AS
BEGIN

	SET NOCOUNT ON

	-- Declarations
-- v1.2	DECLARE	@polarized		varchar(10)

	-- Init
-- v1.2	SET @polarized = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_POLARIZED') 

	-- Working tables
	IF (OBJECT_ID('tempdb..#splits') IS NOT NULL) 
		DROP TABLE #splits


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
		part_type		varchar(20),
		alloc_qty		decimal(20,8),
		auto_po			smallint)


	-- Populate the working table
	INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
						pattern_part, polarized_part, quantity, part_type, alloc_qty, auto_po)
	SELECT	a.order_no,
			a.order_ext,
			a.line_no,
			a.location,
			a.part_no,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN 1 ELSE 0 END,
-- v1.1		CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN c.field_1 ELSE '' END,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN fc.case_part ELSE '' END, -- v1.1
-- v1.1		CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN c.field_4 ELSE '' END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN fc.pattern_part ELSE '' END, -- v1.1
-- v1.2		CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN @polarized ELSE '' END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN fc.polarized_part ELSE '' END, -- v1.2
			a.ordered, 
			d.type_code, 0.0,
			ISNULL(a.create_po_flag,0)
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
-- v1.1		JOIN	inv_master_add c (NOLOCK)
-- v1.1		ON		a.part_no = c.part_no
	LEFT JOIN cvo_ord_list_fc fc (NOLOCK) -- v1.1
	ON		a.order_no = fc.order_no -- v1.1
	AND		a.order_ext = fc.order_ext -- v1.1
	AND		a.line_no = fc.line_no -- v1.1
	JOIN	inv_master d (NOLOCK)
	ON		a.part_no = d.part_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	ORDER BY a.line_no

	-- if the data is an order since soft allocation was added then the #splits table is correct
	-- if the data is from a prior order then we need to update te splits table to mimic the new data
	IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND ISNULL(from_line_no,0) <> 0)
	BEGIN
		UPDATE	a
		SET		case_part = c.part_no,
				has_case = 1
		FROM	#splits a	
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.from_line_no
		JOIN	ord_list c (NOLOCK)
		ON		b.order_no = c.order_no
		AND		b.order_ext = c.order_ext
		AND		b.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		b.is_case = 1

		UPDATE	a
		SET		pattern_part = c.part_no,
				has_pattern = 1
		FROM	#splits a	
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.from_line_no
		JOIN	ord_list c (NOLOCK)
		ON		b.order_no = c.order_no
		AND		b.order_ext = c.order_ext
		AND		b.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		b.is_pattern = 1

		UPDATE	a
		SET		polarized_part = c.part_no,
				has_polarized = 1
		FROM	#splits a	
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.from_line_no
		JOIN	ord_list c (NOLOCK)
		ON		b.order_no = c.order_no
		AND		b.order_ext = c.order_ext
		AND		b.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		b.is_polarized = 1
	END

	-- If this is an old order then the cvo_ord_list will contain the relationship
	IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext  AND from_line_no <> 0 AND is_polarized = 0)
	BEGIN
		INSERT	#cvo_ord_list(order_no, order_ext, line_no, add_case, add_pattern, from_line_no, is_case, is_pattern, add_polarized, is_polarized, is_pop_gif)		
		SELECT	order_no, order_ext, line_no, add_case, add_pattern, from_line_no, is_case, is_pattern, add_polarized, is_polarized, is_pop_gif
		FROM	cvo_ord_list (NOLOCK) 
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext
	END
	ELSE
	BEGIN
		-- Build the #cvo_ord_list table to mimic the frame/case/pattern relationship
		-- Insert the non case/pattern lines that are not related
		INSERT	#cvo_ord_list(order_no, order_ext, line_no, add_case, add_pattern, from_line_no, is_case, is_pattern, add_polarized, is_polarized, is_pop_gif)
		SELECT	order_no, order_ext, line_no, CASE WHEN case_part IS NULL THEN 'Y' ELSE 'N' END, 'N', 0, 0, 0, 'N', 0, 0
		FROM	#splits
		WHERE	(part_type IN ('FRAME','SUN')
		OR		(case_part IS NULL)
		OR		(pattern_part IS NULL)
		OR		(polarized_part IS NULL))
				
		-- Insert lines that are cases and are related
		INSERT	#cvo_ord_list(order_no, order_ext, line_no, add_case, add_pattern, from_line_no, is_case, is_pattern, add_polarized, is_polarized, is_pop_gif)
		SELECT	a.order_no, a.order_ext, a.line_no, 'N', 'N', 
				b.line_no, CASE WHEN a.part_type = 'CASE' THEN 1 ELSE 0 END, 0, 'N', 0, 0
		FROM	#splits a
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.part_no = b.case_part
		WHERE	a.has_case = 0
		AND		a.part_type NOT IN ('FRAME','SUN')

		-- Insert lines that are patterns and are related
		INSERT	#cvo_ord_list(order_no, order_ext, line_no, add_case, add_pattern, from_line_no, is_case, is_pattern, add_polarized, is_polarized, is_pop_gif)
		SELECT	a.order_no, a.order_ext, a.line_no, 'N', 'N', 
				b.line_no, 0, CASE WHEN a.part_type = 'PATTERN' THEN 1 ELSE 0 END, 'N', 0, 0
		FROM	#splits a
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.part_no = b.pattern_part
		WHERE	a.has_pattern = 0
		AND		a.part_type NOT IN ('FRAME','SUN')

		-- Insert lines that are polarized and are related
		INSERT	#cvo_ord_list(order_no, order_ext, line_no, add_case, add_pattern, from_line_no, is_case, is_pattern, add_polarized, is_polarized, is_pop_gif)
		SELECT	a.order_no, a.order_ext, a.line_no, 'N', 'N', 
-- v1.2			b.line_no, 0, 0, 'N', CASE WHEN (a.part_type = 'PARTS' AND a.part_no = @polarized) THEN 1 ELSE 0 END, 0
				b.line_no, 0, 0, 'N', CASE WHEN (a.part_type = 'PARTS' AND a.part_no IN (SELECT part_no FROM cvo_polarized_vw)) THEN 1 ELSE 0 END, 0 -- v1.2
		FROM	#splits a
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.part_no = b.polarized_part
		WHERE	a.has_polarized = 0
		AND		a.part_type NOT IN ('FRAME','SUN')
	END

END
GO

GRANT EXECUTE ON  [dbo].[CVO_create_fc_relationship_sp] TO [public]
GO
