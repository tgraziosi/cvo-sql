SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





CREATE PROCEDURE [dbo].[glprd_sp]
 @period_start_date int
AS
BEGIN

	DECLARE @return_code smallint
	
	EXEC	@return_code = apchkprd_sp	@period_start_date
	IF ( @return_code = 1 )
	BEGIN
		SELECT	@return_code
		RETURN	@return_code
	END

	EXEC	@return_code = archkprd_sp	@period_start_date

	SELECT	@return_code
	RETURN	@return_code

END
GO
GRANT EXECUTE ON  [dbo].[glprd_sp] TO [public]
GO
