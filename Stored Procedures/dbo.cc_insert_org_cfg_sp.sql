SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_insert_org_cfg_sp] @all_org_flag	smallint = 0,
																			@from_org varchar(30) = '',
																			@to_org		varchar(30) = '',
																			@user_id	int = 0	 		
			
AS

			DELETE ccorgcfg 
			WHERE user_id = @user_id

			INSERT ccorgcfg ( all_org_flag, from_org, to_org, user_id )
			VALUES ( @all_org_flag, @from_org, @to_org, @user_id )

GO
GRANT EXECUTE ON  [dbo].[cc_insert_org_cfg_sp] TO [public]
GO
