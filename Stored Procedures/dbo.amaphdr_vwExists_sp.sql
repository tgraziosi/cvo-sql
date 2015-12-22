SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amaphdr_vwExists_sp]
(
	@company_id		smCompanyID,
	@trx_ctrl_num	smControlNumber,
	@valid			int OUTPUT
) 
AS

IF EXISTS (SELECT 1 
			FROM 	amaphdr_vw 
			WHERE	company_id 		=	@company_id 
			AND		trx_ctrl_num	=	@trx_ctrl_num)
 SELECT @valid = 1
ELSE
 SELECT @valid = 0

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amaphdr_vwExists_sp] TO [public]
GO
