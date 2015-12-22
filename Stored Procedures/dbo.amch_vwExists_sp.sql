SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amch_vwExists_sp]
(
	@company_id			smCompanyID,
	@trx_ctrl_num		smControlNumber,
	@sequence_id 		smCounter,
	@line_id			smCounter,
	@valid 				int 	OUTPUT
) 
AS

IF @line_id = 1
	SELECT @valid = 1
ELSE
BEGIN
	IF EXISTS (SELECT	line_id 
				FROM 	amapdet 
				WHERE	company_id		=	@company_id 
				AND		trx_ctrl_num	=	@trx_ctrl_num 
				AND		sequence_id		=	@sequence_id 
				AND		line_id			=	@line_id)
	 SELECT @valid = 1
	ELSE
	 SELECT @valid = 0
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amch_vwExists_sp] TO [public]
GO
