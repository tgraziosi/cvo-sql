SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROCEDURE [dbo].[CVO_GetAllocatableStock_sp] @order_no		int,
												@order_ext		int,
												@location		varchar(10),
												@part_no		varchar(30),
												@alloc_qty		decimal(20,8),
												@soft_alloc_no	int = 0 -- pass in when duplicating order
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@ok_to_alloc	decimal(20,8),
			@available		decimal(20,8),
			@soft_alloc		decimal(20,8),
			@max_soft_alloc	int

	DECLARE	@qty_sa_alloc	decimal(20,8) -- v11.0 

	-- Retrieve the available stock
	EXEC dbo.CVO_AvailabilityInStock_sp @part_no, @location, @available OUTPUT

	IF (@soft_alloc_no = 0)
	BEGIN
		-- Get the soft allocation number for this order
		SELECT	@max_soft_alloc = MAX(soft_alloc_no)
		FROM	dbo.cvo_soft_alloc_hdr (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status IN (0,1,-1)
	END
	ELSE
		SET @max_soft_alloc = @soft_alloc_no

	-- Get the soft allocted quantity
/* v1.1 Start
	SELECT	@soft_alloc = ISNULL(SUM(CASE WHEN deleted = 1 THEN quantity * -1 ELSE quantity END),0) 
	FROM	dbo.cvo_soft_alloc_det (NOLOCK) 
	WHERE	location = @location 
	AND		part_no = @part_no
	AND		soft_alloc_no < @max_soft_alloc 
	AND		status IN (0,1)
*/

	SELECT	@soft_alloc = SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN ISNULL((b.qty),0) ELSE 0 END) -- v1.4
	FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
	LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.part_no = b.part_no
	AND		a.line_no = b.line_no
	WHERE	a.status IN (0,1,-1) -- v1.2 NOT IN (-2,-3) 
	AND		a.location = @location
	AND		a.part_no = @part_no
	AND		a.soft_alloc_no < @max_soft_alloc 

-- v1.1 End

	-- v1.3 Start
	SELECT @qty_sa_alloc = ISNULL((SELECT SUM(b.qty)  
					FROM	cvo_soft_alloc_det a (NOLOCK)   
					JOIN	tdc_soft_alloc_tbl b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					AND		a.part_no = b.part_no
					WHERE	a.part_no  = @part_no  
					AND		a.location = @location
					AND		a.soft_alloc_no < @max_soft_alloc
					AND		a.status IN (0,1,-1) -- v11.1  
					GROUP BY a.location) , 0) 


	IF (@soft_alloc IS NULL)
		SET @soft_alloc = 0

	SELECT @soft_alloc = @soft_alloc - ISNULL(@qty_sa_alloc,0)
	-- v1.3 End

	-- Can we still allocate the quantity
	IF (@available - @soft_alloc) >= @alloc_qty
		SELECT @ok_to_alloc = @alloc_qty
	ELSE
		SELECT @ok_to_alloc = (@available - @soft_alloc)

	-- Return value
	RETURN	@ok_to_alloc
END
GO
GRANT EXECUTE ON  [dbo].[CVO_GetAllocatableStock_sp] TO [public]
GO
