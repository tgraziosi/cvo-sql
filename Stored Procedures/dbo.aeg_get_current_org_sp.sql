SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[aeg_get_current_org_sp] @user_name varchar(30), @company_name varchar(30)
AS
	SET NOCOUNT ON

	DECLARE @org_id varchar(30)


	SELECT @user_name = domain_username FROM CVO_Control..smusers WHERE user_name = @user_name

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_name


	SELECT @org_id = dbo.sm_get_current_org_fn ( )

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_logoff_sp' ) EXEC sm_logoff_sp

	SET NOCOUNT ON

	SELECT 		@org_id

GO
GRANT EXECUTE ON  [dbo].[aeg_get_current_org_sp] TO [public]
GO
