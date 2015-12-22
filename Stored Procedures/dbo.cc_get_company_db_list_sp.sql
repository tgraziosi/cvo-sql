SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC	[dbo].[cc_get_company_db_list_sp]	@control_db varchar(255), @user_id int
AS
	SET NOCOUNT ON


	
	CREATE TABLE #co (company_name varchar(30), [db_name] varchar(128) )
	EXEC(	' INSERT #co(company_name, db_name) 
					SELECT DISTINCT company_name, db_name from ' + @control_db + '..smcomp c, ' + @control_db + '..smperm p
					WHERE c.company_id = p.company_id 
					AND c.company_id = p.company_id
					AND	p.user_id = ' + @user_id  )

	DECLARE @last_db varchar(30)
	SELECT @last_db = MIN([db_name]) FROM #co
	WHILE ( @last_db IS NOT NULL )
		BEGIN 

			EXEC(	'IF ( SELECT COUNT(*) FROM ' + @last_db + '..sysobjects WHERE name = "aeg_version_new" AND type = "U" ) = 1
							BEGIN
								IF ( SELECT COUNT(*) FROM ' + @last_db + '..aeg_version_new WHERE appid = 25000 ) = 0 ' +
								'	DELETE #co WHERE db_name = "' + @last_db + '" ' +
						'	END		' +
					'	ELSE
							DELETE #co WHERE db_name = "' +  @last_db + '" ' )
	
			SELECT @last_db = MIN([db_name]) FROM #co WHERE [db_name] > @last_db
		END

	SELECT company_name, [db_name] from #co ORDER BY company_name

SET NOCOUNT OFF
GO
GRANT EXECUTE ON  [dbo].[cc_get_company_db_list_sp] TO [public]
GO
