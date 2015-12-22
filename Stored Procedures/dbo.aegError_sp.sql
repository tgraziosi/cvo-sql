SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

       
CREATE PROCEDURE [dbo].[aegError_sp] @appid int, @ErrorCode int, @ErrorMsg varchar(255) OUT
AS
	DECLARE @active		smallint
	DECLARE @text		varchar(255)
	DECLARE @elevel		int
	DECLARE @rowcount	int

	SET NOCOUNT ON

	SELECT 	@active = active,
		@elevel = elevel,
		@text = text
	  FROM 	aeg_error
	 WHERE	appid = @appid
	   AND	error_code = @ErrorCode

	SELECT @rowcount = @@rowcount

	IF @rowcount = 0
	BEGIN
		SELECT @ErrorMsg = CONVERT(CHAR, @ErrorCode)
		RETURN @ErrorCode
	END

	IF @active = 0
	BEGIN
		SELECT @ErrorMsg = ""
		RETURN 0
	END

	SELECT @ErrorMsg = @text
	RETURN @ErrorCode
GO
GRANT EXECUTE ON  [dbo].[aegError_sp] TO [public]
GO
