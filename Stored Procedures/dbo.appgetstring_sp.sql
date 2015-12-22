SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[appgetstring_sp] @stringcode VARCHAR(40), @text	VARCHAR(255) OUT
AS

SET NOCOUNT ON

SELECT	@text = str.stringtext 
FROM	CVO_Control..appstrings str
WHERE	str.stringcode = @stringcode
AND	str.languageid = (SELECT lan.languageid FROM CVO_Control..languages lan WHERE lan.active = 1)



IF @text IS NULL
SELECT @text = @stringcode + ' not found'

GO
GRANT EXECUTE ON  [dbo].[appgetstring_sp] TO [public]
GO
