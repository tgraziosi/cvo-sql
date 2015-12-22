SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amglrefExists_sp]
(
	@reference_code 	varchar(32),
	@valid int output
) 
AS

IF EXISTS (SELECT 	reference_code 
			FROM 	glref 
			WHERE	reference_code 	= @reference_code
			AND		status_flag		= 0)
 SELECT @valid = 1
ELSE
 SELECT @valid = 0

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amglrefExists_sp] TO [public]
GO
