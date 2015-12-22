SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_get_org_cfg_sp] 	@user_id	int = 0,
																		@org_id varchar(30) = ''

AS

	DECLARE @from_org varchar(30),
					@to_org		varchar(30),
					@all_org_flag	smallint,
					@min_org varchar(30),
					@max_org		varchar(30)
					
	SELECT @min_org = MIN(organization_id) FROM Organization
	SELECT @max_org = MAX(organization_id) FROM Organization

	IF ( SELECT COUNT(*) FROM ccorgcfg WHERE user_id = @user_id ) > 0
			SELECT 	@all_org_flag = all_org_flag,
							@from_org = from_org,
							@to_org = to_org
			FROM ccorgcfg 
			WHERE user_id = @user_id
	ELSE
		BEGIN
			IF ( SELECT COUNT(*) FROM ccorgcfg WHERE user_id = 0 ) = 0
				SELECT	@all_org_flag = 0,
								@from_org = @org_id,
								@to_org = @org_id
			ELSE
				SELECT 	@all_org_flag = all_org_flag,
								@from_org = from_org,
								@to_org = to_org
				FROM ccorgcfg 
				WHERE user_id = 0
		END

	SELECT	@all_org_flag,
					@from_org,
					@to_org,
					@min_org,
					@max_org

GO
GRANT EXECUTE ON  [dbo].[cc_get_org_cfg_sp] TO [public]
GO
