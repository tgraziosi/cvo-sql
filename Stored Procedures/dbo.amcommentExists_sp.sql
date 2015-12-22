SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amcommentExists_sp] 
( 
	@company_id		smCompanyID, 
	@key_type		smallint,
	@key_1			varchar(32),
	@sequence_id	int,
	@valid			int 	OUTPUT 		
) 
AS 

IF EXISTS (SELECT 	sequence_id 
			FROM
				comments 	a,
				glusers_vw 	u,
				glco	 	co

			WHERE 	a.company_code 	= co.company_code
			AND		co.company_id	= @company_id
			AND		u.user_id	 	= a.updated_by
			AND		a.key_type		= @key_type
			AND		a.key_1			= @key_1 
			AND 	a.sequence_id 	= @sequence_id 
			 )
 SELECT @valid = 1 
ELSE 
 SELECT @valid = 0

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amcommentExists_sp] TO [public]
GO
