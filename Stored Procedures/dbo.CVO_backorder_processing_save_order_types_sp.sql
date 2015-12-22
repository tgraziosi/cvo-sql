SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 - CT 04/06/13 - Writes to the BackOrder Processing order types to tables

EXEC dbo.CVO_backorder_processing_save_order_types_sp	'CT02', 'ST,RX'
*/
CREATE PROC [dbo].[CVO_backorder_processing_save_order_types_sp]	@template_code	VARCHAR(30),	
																@order_types	VARCHAR(1000)
AS
BEGIN
	
	-- Delete existing records
	DELETE FROM dbo.CVO_backorder_processing_template_order_types WHERE template_code = @template_code

	-- Insert order types
	INSERT INTO dbo.CVO_backorder_processing_template_order_types(
		template_code,
		order_type)
	SELECT
		UPPER(@template_code), 
		ListItem 
	FROM 
		dbo.f_comma_list_to_table (@order_types)

	IF @@ERROR = 0
	BEGIN
		SELECT 0
	END
	ELSE
	BEGIN
		SELECT -1
	END
END

GO
GRANT EXECUTE ON  [dbo].[CVO_backorder_processing_save_order_types_sp] TO [public]
GO
