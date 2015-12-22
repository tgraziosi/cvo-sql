SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_purge_followups_sp] @purge_date	datetime, @o_user_name	varchar(255)
						

AS

DECLARE 		@user_name	varchar(255),
						@domain			varchar(255)





	SELECT @user_name = LTRIM(RTRIM(loginame)), @domain = LTRIM(RTRIM(nt_domain)) 
	FROM master.dbo.sysprocesses 
	WHERE spid = @@SPID 

	SELECT @user_name = replace(@user_name, @domain, '')
	SELECT @user_name = replace(@user_name, '\', '')

			DELETE 	cc_followups 
			FROM		cc_followups f, cc_comments c
			WHERE 	followup_date < @purge_date
			AND			user_name = @o_user_name
			AND			f.comment_id = c.comment_id
GO
GRANT EXECUTE ON  [dbo].[cc_purge_followups_sp] TO [public]
GO
