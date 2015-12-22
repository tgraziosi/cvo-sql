SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amcommentAll_sp] 
( 
	@company_id		smCompanyID, 
	@key_type		smallint,
	@key_1			varchar(32)
) 
AS 

SELECT
	timestamp=a.timestamp, company_id=co.company_id, key_type, key_1, sequence_id, date_updated=CONVERT(char(8), DATEADD(dd, a.date_updated-722815, "1/1/1980"), 112), updated_by, user_name=u.user_name, link_path, note
FROM
	comments 	a,
	glusers_vw 	u,
	glco	 	co

WHERE 	a.company_code 	= co.company_code
AND		co.company_id	= @company_id
AND		u.user_id	 	= a.updated_by
AND		a.key_type		= @key_type
AND		a.key_1			= @key_1 
 
ORDER BY 
	a.date_updated DESC, 
	a.sequence_id DESC

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amcommentAll_sp] TO [public]
GO
