SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC	[dbo].[cc_mr_check_sp]	@control_db varchar(255),  @company_db varchar(255), @user_id int
AS
	SET NOCOUNT ON



	
	CREATE TABLE #co (company_name varchar(30), [db_name] varchar(128) )
	EXEC(	' INSERT #co(company_name, db_name) 
					SELECT DISTINCT company_name, db_name from ' + @control_db + '..smcomp c, ' + @control_db + '..smperm p
					WHERE c.company_id = p.company_id 
					AND	c.db_name = "' + @company_db + '" ' +
				'	AND	p.user_id = ' + @user_id  )

	EXEC(	'IF ( SELECT COUNT(1) FROM  ' + @company_db + '..sysobjects ' +
						'	WHERE name = "aeg_version_new" AND type = "U" ) > 0
					BEGIN
						IF ( SELECT COUNT(1) FROM #co WHERE db_name = "' + @company_db + '" ) > 0
							BEGIN
								IF ( SELECT COUNT(1) FROM ' + @company_db + '..aeg_version_new WHERE appid = 29000 ) = 0 ' +
						'			DELETE #co ' +
						'	END ' +
				'	END		' )

SELECT COUNT(1) from #co

SET NOCOUNT OFF
GO
GRANT EXECUTE ON  [dbo].[cc_mr_check_sp] TO [public]
GO
