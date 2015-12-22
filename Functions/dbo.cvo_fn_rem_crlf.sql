SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
Author: Tine Graziosi
Date: 2/7/2013
*/

CREATE function [dbo].[cvo_fn_rem_crlf] (@fieldtext as varchar(255))
	returns varchar(255)
as
begin
	set @fieldtext = replace(@fieldtext,char(9),' ') -- tab
	SET @fieldtext = REPLACE(@fieldtext,CHAR(13)+char(10),'.') -- CR/LF
	SET @fieldtext = REPLACE(@fieldtext,'..','.') -- CLEAN IT UP
	SET @fieldtext = REPLACE(@fieldtext,'..','.') -- CLEAN IT UP
	set @fieldtext = ltrim(rtrim(@fieldtext))

return @fieldtext
end
GO
GRANT EXECUTE ON  [dbo].[cvo_fn_rem_crlf] TO [public]
GO
