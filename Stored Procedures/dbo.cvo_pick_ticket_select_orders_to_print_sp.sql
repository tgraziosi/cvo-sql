SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_pick_ticket_select_orders_to_print_sp]
AS
BEGIN

	SET NOCOUNT ON
	DECLARE @consolidation_no INT,
			@order_no INT,
			@order_ext INT

	SET @consolidation_no = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@consolidation_no = mp_consolidation_no,
			@order_no = order_no,
			@order_ext = order_ext
		FROM
			#orders_to_print
		WHERE
			ISNULL(mp_consolidation_no,0) > @consolidation_no
		ORDER BY
			mp_consolidation_no,
			lowest_bin_no,
			order_no,
			order_ext

		IF @@ROWCOUNT = 0
			BREAK

		-- Remove other orders for this consolidation set
		DELETE FROM 
			#orders_to_print
		WHERE
			mp_consolidation_no = @consolidation_no
			AND NOT(order_no = @order_no AND order_ext = @order_ext)

	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_pick_ticket_select_orders_to_print_sp] TO [public]
GO
