SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			f_return_autopack_carton_free_space
Project ID:		Issue 690
Type:			Function
Description:	Returns free space in an autopack carton
Developer:		Chris Tyler

History
-------
v1.0	24/07/12	CT	Original version
v1.1	30/07/12	CT	Include cases which are linked to a frame, but where the frame hasn't been assigned to the carton yet

-- SELECT dbo.f_return_autopack_carton_free_space (2) 

*/

CREATE FUNCTION [dbo].[f_return_autopack_carton_free_space] (@carton_id INT)
RETURNS DECIMAL (20,8)
AS
BEGIN
	DECLARE @max_qty	DECIMAL(20,8),
			@carton_qty DECIMAL(20,8)

	-- Get max qty from config
	SELECT @max_qty = CAST(value_str AS DECIMAL(20,8)) FROM dbo.tdc_config (NOLOCK) WHERE mod_owner = 'GEN' AND [function] = 'STOCK_ORDER_CARTON_QTY'
	
	-- Get qty on carton
	SELECT 
		@carton_qty = SUM(qty)
	FROM
		dbo.CVO_autopack_carton (NOLOCK)
	WHERE
		-- START v1.1
		--part_type <> 'CASE'
		((part_type <> 'CASE') OR (part_type = 'CASE' AND frame_link IS NULL))
		-- END v1.1
		AND carton_id = @carton_id

	RETURN (@max_qty - ISNULL(@carton_qty,0))
		

END

GO
GRANT REFERENCES ON  [dbo].[f_return_autopack_carton_free_space] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_return_autopack_carton_free_space] TO [public]
GO
