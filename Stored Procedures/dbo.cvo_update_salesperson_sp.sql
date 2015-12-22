SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_update_salesperson_sp]	@from_code	varchar(10),
											@to_code	varchar(10)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @territory_code	varchar(10)

	-- Check if the to_code needs to be activated
	IF EXISTS (SELECT 1 FROM arsalesp (NOLOCK) WHERE salesperson_code = @to_code AND status_type = 2)
	BEGIN
		UPDATE	arsalesp
		SET		status_type = 1
		WHERE	salesperson_code = @to_code
	END

	-- Deactivate the from_code
	UPDATE	arsalesp
	SET		status_type = 2
	WHERE	salesperson_code = @from_code

	-- Get the territory of the new salesperson
	SELECT	@territory_code = territory_code
	FROM	arsalesp (NOLOCK)
	WHERE	salesperson_code = @to_code	

	-- Update customer and ship to record to the new salesperson code
	UPDATE	armaster_all
	SET		salesperson_code = @to_code,
			territory_code = @territory_code
	WHERE	salesperson_code = @from_code		


END
GO
GRANT EXECUTE ON  [dbo].[cvo_update_salesperson_sp] TO [public]
GO
