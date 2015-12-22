SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 - CT 04/06/13 - Reads from the BackOrder Processing order types to tables

EXEC dbo.CVO_backorder_processing_load_order_types_sp	'CT02'
*/
CREATE PROC [dbo].[CVO_backorder_processing_load_order_types_sp]	@template_code	VARCHAR(30)
AS
BEGIN
	
	DECLARE @return		VARCHAR(1000),
			@order_type VARCHAR(10)	


	SET @order_type = ''
	SET @return = ''
	
	-- Loop through order types for the template
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@order_type = order_type
		FROM
			dbo.CVO_backorder_processing_template_order_types (NOLOCK)
		WHERE
			template_code = @template_code
			AND order_type > @order_type
		ORDER BY
			order_type

		IF @@ROWCOUNT = 0
			BREAK

		IF @return = ''
		BEGIN
			SET @return = @return + @order_type
		END
		ELSE
		BEGIN
			SET @return = @return + ',' + @order_type
		END
	END
	
	SELECT @return
	
END

GO
GRANT EXECUTE ON  [dbo].[CVO_backorder_processing_load_order_types_sp] TO [public]
GO
