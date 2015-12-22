SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_fonts_sel_sp] @user_id int = 0
	
AS


IF ( SELECT COUNT(*) FROM ccfonts WHERE [user_id] = @user_id ) > 0
	SELECT 	[font_name],
					[font_size],
					[font_bold],
					[font_italics]
	FROM	ccfonts
	WHERE [user_id] = @user_id
ELSE
	SELECT 	[font_name],
					[font_size],
					[font_bold],
					[font_italics]
	FROM	ccfonts
	WHERE [user_id] = 0


GO
GRANT EXECUTE ON  [dbo].[cc_fonts_sel_sp] TO [public]
GO
