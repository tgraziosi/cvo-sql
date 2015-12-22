SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			f_comma_list_to_table.sql
Type:			Function
Description:	Returns a table populated from the input comma delimited list
Developer:		Chris Tyler
Date:			28th March 2013
Testing Code:	SELECT * FROM dbo.f_comma_list_to_table ('Element1, Element2, Element3')

Revision History

*/

CREATE FUNCTION [dbo].[f_comma_list_to_table] (@inputlist varchar(8000))
RETURNS @ListTable TABLE (ListItem varchar(40))
AS
BEGIN
	DECLARE	@CharPos	int

	--/ Loop through string finding each element and adding quotes
	SET @CharPos = CHARINDEX(',',@inputlist)
	
	WHILE @CharPos <> 0
	BEGIN
		--/ Don't add empty elements
		IF LEN(LTRIM(RTRIM(Substring(@inputlist,1,@Charpos-1)))) > 0 
			INSERT INTO @ListTable VALUES(LTRIM(RTRIM(Substring(@inputlist,1,@Charpos-1))))

		--/ Remove this element from input string
		SET @inputlist = Substring(@inputlist,(@CharPos + 1), (Len(@inputlist) - @Charpos))
		
		SET @CharPos = CHARINDEX(',',@inputlist)
	END


	--/ Get the last element if final character wasn't a comma (if it was remove final character from output (will also be a comma)
	IF LEN (@inputlist) > 0
	BEGIN 
		INSERT INTO @ListTable VALUES(LTRIM(RTRIM(@inputlist)))
	END
	
	RETURN 
END


GO
GRANT REFERENCES ON  [dbo].[f_comma_list_to_table] TO [public]
GO
GRANT SELECT ON  [dbo].[f_comma_list_to_table] TO [public]
GO
