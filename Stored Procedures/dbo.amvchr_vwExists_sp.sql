SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amvchr_vwExists_sp]
(
 	@trx_ctrl_num 	smControlNumber,
	@valid							int OUTPUT
)
AS
 
IF EXISTS (SELECT 1 FROM amapnew
			WHERE	trx_ctrl_num				= @trx_ctrl_num
	 	 )
	SELECT @valid = 1
ELSE
	SELECT @valid = 0
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amvchr_vwExists_sp] TO [public]
GO
