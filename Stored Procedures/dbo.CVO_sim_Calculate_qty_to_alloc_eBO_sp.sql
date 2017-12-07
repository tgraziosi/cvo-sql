SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE  [dbo].[CVO_sim_Calculate_qty_to_alloc_eBO_sp]	@order_no	int,
															@order_ext	int 
AS
BEGIN     
    -- NOTE: Based on CVO_Calculate_qty_to_alloc_eBO_sp v10.6 -  - All changes must be kept in sync
    
	DECLARE @location			VARCHAR(30)

	UPDATE	a
	SET		part_no = b.part_no
	FROM	#sim_CVO_qty_to_alloc_tbl a
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.part_no <> b.part_no
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext


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
		auto_po			smallint,
		from_line_no	int) -- v10.1

	CREATE TABLE #part_splits (
		part_no		varchar(30),
		quantity	decimal(20,8),
		diff		decimal(20,8))

	-- Populate working tables
	INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
						pattern_part, polarized_part, quantity, part_type, alloc_qty, auto_po, from_line_no) 
	SELECT	a.order_no,
			a.order_ext,
			a.line_no,
			a.location,
			a.part_no,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN fc.case_part ELSE '' END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN fc.pattern_part ELSE '' END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN fc.polarized_part ELSE '' END, 
			a.ordered, 
			CASE WHEN d.status = 'C' THEN 'KIT' ELSE d.type_code END, 
			0.0,
			ISNULL(a.create_po_flag,0),
			ISNULL(a.cust_po,0) 
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	LEFT JOIN cvo_ord_list_fc fc (NOLOCK) 
	ON		a.order_no = fc.order_no 
	AND		a.order_ext = fc.order_ext 
	AND		a.line_no = fc.line_no 
	JOIN	inv_master d (NOLOCK)
	ON		a.part_no = d.part_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	ORDER BY a.line_no
	
	SELECT	@location = location
	FROM	#so_alloc_management_Header
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	DELETE	#sim_CVO_qty_to_alloc_tbl 
	WHERE	order_no  = @order_no
	AND		order_ext = @order_ext
	AND		location  = @location

	-- Get the allocated quantities
	UPDATE	#splits
	SET		alloc_qty = (CASE WHEN a.auto_po = 1 THEN 0 ELSE b.qty_avail - b.qty_picked END)
	FROM	#splits a
	JOIN	#so_allocation_detail_view_Detail b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		a.part_no = b.part_no

	UPDATE	#splits
	SET		alloc_qty = quantity
	WHERE	part_type = 'KIT'

	-- Get the quantities for cases, patterns and polarized adjusted for non allocated frames
	INSERT	#part_splits (part_no, quantity, diff)
	SELECT	case_part,
			SUM(alloc_qty),
			SUM(quantity - alloc_qty)
	FROM	#splits
	WHERE	case_part <> ''
	GROUP BY case_part

	INSERT	#part_splits (part_no, quantity, diff)
	SELECT	pattern_part,
			SUM(alloc_qty),
			SUM(quantity - alloc_qty)		
	FROM	#splits
	WHERE	pattern_part <> ''
	GROUP BY pattern_part

	INSERT	#part_splits (part_no, quantity, diff)
	SELECT	polarized_part,
			SUM(alloc_qty),
			SUM(quantity - alloc_qty)
	FROM	#splits
	WHERE	polarized_part <> ''
	GROUP BY polarized_part


	-- Adjust the quantities to allocate
	UPDATE	#splits
	SET		alloc_qty = a.alloc_qty - b.diff
	FROM	#splits a 
	JOIN	#part_splits b
	ON		a.part_no = b.part_no
	WHERE	case_part = ''
	AND		pattern_part = ''
	AND		polarized_part = ''
    AND		a.part_no NOT IN (SELECT part_no FROM cvo_polarized_vw)

	UPDATE	a
	SET		alloc_qty = b.alloc_qty
	FROM	#splits a
	JOIN	#splits b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.part_no = b.polarized_part
	AND		a.from_line_no = b.line_no
	WHERE	a.polarized_part = ''
	AND		b.polarized_part <> ''
	AND		b.alloc_qty = 0

	UPDATE	a
	SET		alloc_qty = b.alloc_qty
	FROM	#splits a
	JOIN	#splits b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.polarized_part = b.part_no
	AND		a.line_no = b.from_line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.polarized_part = ''
	AND		a.polarized_part <> ''
	AND		b.alloc_qty < a.alloc_qty
	
	UPDATE	a
	SET		alloc_qty = a.quantity
	FROM	#splits a
	LEFT JOIN	#sim_tdc_soft_alloc_tbl b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.part_type = 'CASE'
	AND		b.order_no IS NULL
	AND		b.order_ext IS NULL
	AND		b.line_no IS NULL

	-- Update back to the processing table
	UPDATE	a
	SET		qty_to_alloc = b.alloc_qty
	FROM	#so_allocation_detail_view_Detail a
	JOIN	#splits b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		a.part_no = b.part_no

	UPDATE	a
	SET		qty_to_alloc = a.qty_avail
	FROM	#so_allocation_detail_view_Detail a
	JOIN	#splits b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		b.part_type = 'KIT'

	-- Populate the CVO_qty_to_alloc_tbl table
	INSERT	#sim_CVO_qty_to_alloc_tbl (order_no, order_ext, location, from_line_no, line_no, part_no, qty_to_alloc )  
	SELECT	order_no, order_ext, location, from_line_no, line_no, part_no, qty_to_alloc  
	FROM	#so_allocation_detail_view_Detail  
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	DROP TABLE #splits
	DROP TABLE #part_splits

END  
GO
GRANT EXECUTE ON  [dbo].[CVO_sim_Calculate_qty_to_alloc_eBO_sp] TO [public]
GO
