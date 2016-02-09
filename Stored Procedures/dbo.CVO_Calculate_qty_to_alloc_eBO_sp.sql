
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[ CVO_Calculate_qty_to_alloc_eBO_sp]    Script Date: 06/04/2010  *****
SED003 -- Case Part
Object:      Procedure  CVO_Calculate_qty_to_alloc_eBO_sp  
Source file:  CVO_Calculate_qty_to_alloc_eBO_sp.sql
Author:		 Jesus Velazquez
Created:	 04/05/2010
Function:    Calculates qty_to_alloc everytime sales order is saved
Modified:    
Calls:    
Called by:   CVO_tdc_plw_so_alloc_management_sp
Copyright:   Epicor Software 2010.  All rights reserved.  
v1.1 CB 12/13/2010 - If items on a backorder relate to a line on the original order then they do 
					not allocate when they should
v1.2 CB 12/13/2010 - Cases get allocated with the same qty as a frame, fix this for patterns
v1.3 CB 08/04/2011 - Fix for partially allocated items 
v1.4 CB 26/04/2011 - Change logic - Only checked frame qty when case existed
v1.5 CB 02/09/2011 - Add logic for auto POs
v1.6 CB 22/09/2011 - Performance
v1.9 CB 28/06/2012 - Cases not allocating due to the part has been changed on the backorder
v10.0 CB 23/05/2012 - Soft Allocation 
v10.1 CB 05/06/2013 - Issue #1297 - Deal with polarized items
v10.2 CB 07/06/2013 - Issue #1289 - Frame/case relationship at order entry
v10.3 CB 05/06/2014 - Fix issue when case has been fully unallocated due to change but does not fully allocate qty
v10.4 CB 26/01/2016 - #1581 2nd Polarized Option
*/
CREATE PROCEDURE  [dbo].[CVO_Calculate_qty_to_alloc_eBO_sp]	@order_no	int,
													@order_ext	int 
AS
BEGIN     
        
	DECLARE @location			VARCHAR(30)--,
			-- v10.4 @polarized			VARCHAR(10)

-- v10.4 SET @polarized	= [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_POLARIZED')   

	-- v1.9
	UPDATE	a
	SET		part_no = b.part_no
	FROM	CVO_qty_to_alloc_tbl a
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.part_no <> b.part_no
	AND		a.order_no = @order_no
	AND		a.order_ext = @order_ext


	-- v10.0
	-- Create working tables
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
						pattern_part, polarized_part, quantity, part_type, alloc_qty, auto_po, from_line_no) -- v10.1
	SELECT	a.order_no,
			a.order_ext,
			a.line_no,
			a.location,
			a.part_no,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN 1 ELSE 0 END,
-- v10.2	CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN c.field_1 ELSE '' END,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN fc.case_part ELSE '' END,
-- v10.2	CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN c.field_4 ELSE '' END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN fc.pattern_part ELSE '' END,
-- v10.4	CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN @polarized ELSE '' END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN fc.polarized_part ELSE '' END, -- v10.4
			a.ordered, 
			d.type_code, 0.0,
			ISNULL(a.create_po_flag,0),
			ISNULL(a.cust_po,0) -- v10.1
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
-- v10.2	JOIN	inv_master_add c (NOLOCK)
-- v10.2	ON		a.part_no = c.part_no
	LEFT JOIN cvo_ord_list_fc fc (NOLOCK) -- v10.2
	ON		a.order_no = fc.order_no -- v10.2
	AND		a.order_ext = fc.order_ext -- v10.2
	AND		a.line_no = fc.line_no -- v10.2
	JOIN	inv_master d (NOLOCK)
	ON		a.part_no = d.part_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	ORDER BY a.line_no
	
	SELECT	@location = location
	FROM	#so_alloc_management_Header
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	DELETE	CVO_qty_to_alloc_tbl 
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
-- v10.4 AND	a.part_no <> @polarized -- v10.1
    AND		a.part_no NOT IN (SELECT part_no FROM cvo_polarized_vw) -- v10.4

	-- v10.1 Start
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
	-- v10.1 End
	
	-- v10.3 Start
	UPDATE	a
	SET		alloc_qty = a.quantity
	FROM	#splits a
	LEFT JOIN	tdc_soft_alloc_tbl b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.part_type = 'CASE'
	AND		b.order_no IS NULL
	AND		b.order_ext IS NULL
	AND		b.line_no IS NULL
	-- v10.3 End

	-- Update back to the processing table
	UPDATE	a
	SET		qty_to_alloc = b.alloc_qty
	FROM	#so_allocation_detail_view_Detail a
	JOIN	#splits b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		a.part_no = b.part_no


	-- Populate the CVO_qty_to_alloc_tbl table
	INSERT	CVO_qty_to_alloc_tbl (order_no, order_ext, location, from_line_no, line_no, part_no, qty_to_alloc )  
	SELECT	order_no, order_ext, location, from_line_no, line_no, part_no, qty_to_alloc  
	FROM	#so_allocation_detail_view_Detail  
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	DROP TABLE #splits
	DROP TABLE #part_splits

END  
GO

GRANT EXECUTE ON  [dbo].[CVO_Calculate_qty_to_alloc_eBO_sp] TO [public]
GO
