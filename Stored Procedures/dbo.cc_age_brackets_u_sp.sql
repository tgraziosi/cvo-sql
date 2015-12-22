SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_age_brackets_u_sp]	@age_bracket1	smallint,
																			@age_bracket2	smallint,
																			@age_bracket3	smallint,
																			@age_bracket4	smallint,
																			@age_bracket5	smallint,
																			@age_bracket6	smallint,
																			@age_bracket7	smallint,
																			@age_bracket8	smallint,
																			@age_bracket9	smallint,
																			@user_id			int
	
AS

DELETE ccagebrk	WHERE [user_id] = @user_id

INSERT	ccagebrk(	age_bracket1,
			age_bracket2,
			age_bracket3,
			age_bracket4,
			age_bracket5,
			age_bracket6,
			age_bracket7,
			age_bracket8,
			age_bracket9,
			[user_id]
		)
VALUES		(	@age_bracket1,
			@age_bracket2,
			@age_bracket3,
			@age_bracket4,
			@age_bracket5,
			@age_bracket6,
			@age_bracket7,
			@age_bracket8,
			@age_bracket9,
			@user_id
		)


GO
GRANT EXECUTE ON  [dbo].[cc_age_brackets_u_sp] TO [public]
GO
