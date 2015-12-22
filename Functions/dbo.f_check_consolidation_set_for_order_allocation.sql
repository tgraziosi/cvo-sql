SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Epicor Software (UK) Ltd (c)2014
-- For ClearVision Optical - 68668
-- Returns 0 = Order can be allocated 1 = Order cannot be allocated
-- v1.0 CT 03/04/2013	Checks whether an order is already part of a non shipped consolidation set and is printed, if so it can't be allocated again

-- SELECT dbo.f_check_consolidation_set_for_order_allocation (1419636, 0)

CREATE FUNCTION [dbo].[f_check_consolidation_set_for_order_allocation] (@order_no	INT,
																	@order_ext	INT) 
RETURNS SMALLINT
AS
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.cvo_masterpack_consolidation_det a (NOLOCK) INNER JOIN dbo.cvo_masterpack_consolidation_hdr b (NOLOCK)
				ON a.consolidation_no = b.consolidation_no WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND b.shipped = 0)
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND [status] > 'N')
		BEGIN
			RETURN 1
		END
	END

	RETURN 0
END
GO
GRANT REFERENCES ON  [dbo].[f_check_consolidation_set_for_order_allocation] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_check_consolidation_set_for_order_allocation] TO [public]
GO
