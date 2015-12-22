SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE FUNCTION [dbo].[ep_replace_characters](@fieldtext AS VARCHAR(255))
	RETURNS VARCHAR(255)
AS
BEGIN
	SET @fieldtext = REPLACE(@fieldtext,CHAR(38),'&amp;')
	SET @fieldtext = REPLACE(@fieldtext, '''''', '''')
	SET @fieldtext = REPLACE(@fieldtext,CHAR(34),'&quot;')
	SET @fieldtext = REPLACE(@fieldtext,CHAR(60),'&lt;')
	SET @fieldtext = REPLACE(@fieldtext,CHAR(62),'&gt;')


	RETURN @fieldtext
END

GO
GRANT EXECUTE ON  [dbo].[ep_replace_characters] TO [public]
GO
