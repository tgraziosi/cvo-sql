SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amglrefAll_sp]
(
	
	@account_code 	varchar(32)
)
AS


SELECT 		
		a.reference_code,
		a.description,
		a.reference_type
FROM 	glref a,
		glratyp b
WHERE 	a.reference_type = b.reference_type
AND 	@account_code like b.account_mask
ORDER BY a.reference_code


RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amglrefAll_sp] TO [public]
GO
