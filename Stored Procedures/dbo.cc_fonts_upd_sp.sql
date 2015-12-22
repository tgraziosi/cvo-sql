SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_fonts_upd_sp]	@font_name 		varchar(255),
																	@font_size 		varchar(255),
																	@font_bold 		varchar(255),
																	@font_italics	varchar(255),
																	@user_id			int
	
AS

DELETE ccfonts	WHERE [user_id] = @user_id

INSERT	ccfonts(	[font_name],
									[font_size],
									[font_bold],
									[font_italics],
									[user_id]	)
VALUES		(	@font_name,
						@font_size,
						@font_bold,
						@font_italics,
						@user_id	)


GO
GRANT EXECUTE ON  [dbo].[cc_fonts_upd_sp] TO [public]
GO
