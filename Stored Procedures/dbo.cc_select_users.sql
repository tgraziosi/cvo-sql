SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_select_users]	@status tinyint = 1

AS
	IF @status = 0
		SELECT user_name, user_id FROM CVO_Control..smusers ORDER BY user_name
	ELSE
		SELECT user_name, user_id FROM CVO_Control..smusers WHERE deleted = 0 ORDER BY user_name

GO
GRANT EXECUTE ON  [dbo].[cc_select_users] TO [public]
GO
