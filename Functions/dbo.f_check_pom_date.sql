SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Epicor Software (UK) Ltd (c)2013
-- For ClearVision Optical - 68668
-- Returns 0 = Invalid 1 = valid
-- v1.0 CT 12/06/2013	Checks whether a part is valid for adding to an order based on POM date
-- v1.1 CT 25/06/2013	Issue #1324 - Fix permissions
-- v1.2	CT 03/02/2014	Don't include orders with status of R or beyond when calculating what is outstanding for the part

-- SELECT dbo.f_check_pom_date ('CH215BRO5418', '001',1, 1419636, 0)

CREATE FUNCTION [dbo].[f_check_pom_date]	(@part_no	VARCHAR(30), 
										 @location	VARCHAR(10),
										 @qty		DECIMAL(20,8),
										 @order_no	INT,
										 @order_ext	INT) 
RETURNS SMALLINT
AS
BEGIN
	DECLARE @po_due			DECIMAL(20,8),
			@qty_required	DECIMAL(20,8)

	-- Is part a FRAME/SUN?
	IF NOT EXISTS(SELECT 1 FROM dbo.inv_master (NOLOCK) WHERE part_no = @part_no AND type_code IN ('FRAME','SUN'))
	BEGIN
		RETURN 1 -- valid
	END
	
	-- Does it have a POM date?
	IF EXISTS(SELECT 1 FROM dbo.inv_master_add (NOLOCK) WHERE part_no = @part_no AND field_28 IS NULL)
	BEGIN
		RETURN 1 -- valid
	END

	-- Does it have a POM date in the past?
	IF NOT EXISTS(SELECT 1 FROM dbo.inv_master_add (NOLOCK) WHERE part_no = @part_no AND field_28 < DATEADD(dd, 1, DATEDIFF(dd, 0, GETDATE())))
	BEGIN
		RETURN 1 -- valid
	END

	-- Get the stock due in on POs for the part
	SELECT 
		@po_due = SUM(quantity - received)
	FROM
		dbo.releases
	WHERE
		[status] = 'O'
		AND quantity > received
		AND part_no = @part_no
		AND location = @location
	
	IF ISNULL(@po_due,0) = 0
	BEGIN
		RETURN 0 -- invalid
	END

	-- Get the qty on outstanding orders for the part
 	SELECT
		@qty_required = SUM(a.ordered - (a.shipped + ISNULL(c.qty,0)))
	FROM
		dbo.ord_list a (NOLOCK)
	INNER JOIN
		dbo.orders b (NOLOCK)
	ON 
		a.order_no = b.order_no
		AND a.order_ext = b.ext
	LEFT JOIN
		dbo.cvo_hard_allocated_vw c (NOLOCK)
	ON
		a.order_no = c.order_no
		AND a.order_ext = c.order_ext
		AND a.line_no = c.line_no
		AND c.order_type = 'S'
	WHERE
		b.[type] = 'I'
		AND b.void = 'N'
		-- START v1.2
		AND b.[status] < 'R'
		-- END v1.2
		AND a.part_no = @part_no
		AND a.location = @location
		AND NOT (a.order_no = @order_no AND a.order_ext = @order_ext)
		AND a.part_type = 'P'
		AND a.ordered <> a.shipped
		
	SET @qty_required = ISNULL(@qty_required,0) + @qty
	
	IF @po_due < @qty_required
	BEGIN
		RETURN 0 -- invalid
	END

	RETURN 1 -- valid

END
GO
GRANT REFERENCES ON  [dbo].[f_check_pom_date] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_check_pom_date] TO [public]
GO
