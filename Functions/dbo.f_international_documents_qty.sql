SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			f_international_documents_qty
Project ID:		Issue 826
Type:			Function
Description:	Returns qty for international documents
Developer:		Chris Tyler

History
-------
v1.0	03/08/12	CT	Original version
v1.1	08/02/13	CB  Issue #1139 - When printing prior to allocation only include soft allocated items where the inventory is available
v1.2	23/04/13	CB	Issue #1234 - Need to include packed quantites
v1.3	16/07/14	CT	Issue #572 - Logic fix to account for multiple orders in the same carton

*/

CREATE FUNCTION [dbo].[f_international_documents_qty] (	@order_no INT,
													@order_ext INT,
													@line_no INT,
													@part_no VARCHAR(30))
RETURNS DECIMAL(20,8)
AS
BEGIN
	DECLARE @ret_qty		DECIMAL(20,8),
			@soft_alloc_qty	DECIMAL(20,8),
			@hard_alloc_qty	DECIMAL(20,8),
			@packed_qty		DECIMAL(20,8) -- v1.2

	SET @ret_qty = 0
	SET @soft_alloc_qty = 0
	SET @hard_alloc_qty = 0
	SET @packed_qty = 0 -- v1.2

	-- Get qty soft allocated
	SELECT 
		@soft_alloc_qty = SUM(quantity) 
	FROM 
		dbo.cvo_soft_alloc_det (NOLOCK)  
	WHERE 
		order_no = @order_no
		AND order_ext = @order_ext
		AND line_no = @line_no
		AND part_no = @part_no  
		AND [status] NOT IN (-2,-3)
		AND ISNULL(inv_avail,0) = 1 -- v1.1
	
	-- Get hard allocated qty
	SELECT 
		@hard_alloc_qty = SUM(qty) 
	FROM 
		dbo.tdc_soft_alloc_tbl (NOLOCK) 
	WHERE 
		order_no = @order_no
		AND order_ext = @order_ext 
		AND line_no = @line_no 
		AND part_no = @part_no
		AND order_type = 'S'

	-- v1.2 Start
	-- Get the packed qty
	SELECT 
		@packed_qty = SUM(a.pack_qty) 
	FROM 
		dbo.tdc_carton_detail_tx a (NOLOCK)
	JOIN
		dbo.tdc_carton_tx b (NOLOCK)
	ON	a.carton_no = b.carton_no
		-- START v1.3
		AND a.order_no = b.order_no
		AND a.order_ext = b.order_ext 
		-- END v1.3
	WHERE 
		a.order_no = @order_no
		AND a.order_ext = @order_ext 
		AND a.line_no = @line_no 
		AND a.part_no = @part_no
		AND b.order_type = 'S'
	-- v1.2 End

	SET @ret_qty = ISNULL(@soft_alloc_qty,0) + ISNULL(@hard_alloc_qty,0) + ISNULL(@packed_qty,0) -- v1.2
	RETURN @ret_qty
END

GO
GRANT REFERENCES ON  [dbo].[f_international_documents_qty] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_international_documents_qty] TO [public]
GO
