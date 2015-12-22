SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_age_brackets_s_sp] @user_id int = 0
	
AS

IF ( SELECT COUNT(*) FROM ccagebrk WHERE [user_id] = @user_id ) > 0
	SELECT 	age_bracket1,
		age_bracket2,
		age_bracket3,
		age_bracket4,
		age_bracket5,
		age_bracket6,
		age_bracket7,
		age_bracket8,
		age_bracket9
	FROM	ccagebrk
	WHERE [user_id] = @user_id
ELSE
	SELECT 	age_bracket1,
		age_bracket2,
		age_bracket3,
		age_bracket4,
		age_bracket5,
		age_bracket6,
		age_bracket7,
		age_bracket8,
		age_bracket9
	FROM	ccagebrk
	WHERE [user_id] = 0


GO
GRANT EXECUTE ON  [dbo].[cc_age_brackets_s_sp] TO [public]
GO
