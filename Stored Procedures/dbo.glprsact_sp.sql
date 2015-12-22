SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glprsact.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[glprsact_sp]
	@acct_code	varchar(32), 
	@acct_mask	varchar(35),
	@seg1_code	varchar(32) OUTPUT, 
	@seg2_code	varchar(32) OUTPUT, 
	@seg3_code	varchar(32) OUTPUT,
	@seg4_code	varchar(32) OUTPUT

AS
DECLARE @len smallint, @pos smallint, @str varchar(35), @pre_pos smallint,
	@index smallint


SELECT 	@pos = 0,	@pre_pos = 0,	@index = 1,	@seg1_code = '', 
	@seg2_code = '',@seg3_code = '',@seg4_code = ''


SELECT	@str = @acct_mask
SELECT 	@len = datalength( @str )


SELECT 	@pos = charindex( "-", @str )


WHILE	@pos != 0
BEGIN	
	
	IF	@index = 1
	BEGIN
		SELECT	@seg1_code = SUBSTRING( @acct_mask, 1, ( @pos-1 ) )
		SELECT 	@seg1_code = SUBSTRING( @acct_code, 1, 
					datalength( @seg1_code ) )
	END
	ELSE IF @index = 2
	BEGIN
		SELECT	@seg2_code = SUBSTRING( @acct_mask, @pre_pos+1,
					( @pos - 1 ) )
		SELECT 	@seg2_code = SUBSTRING( @acct_code, 
			datalength( @seg1_code ) + 1,
			datalength( @seg2_code ) )
	END
	ELSE IF @index = 3
	BEGIN
		SELECT	@seg3_code = SUBSTRING( @acct_mask, @pre_pos+1,
					( @pos - 1 ) )
		SELECT 	@seg3_code = SUBSTRING( @acct_code, 
			datalength( @seg1_code ) + datalength( @seg2_code ) +1,
			datalength( @seg3_code ) )
	END
	ELSE IF @index = 4
	BEGIN
		SELECT	@seg4_code = SUBSTRING( @acct_mask, @pre_pos+1,
					( @pos - 1 ) )
		SELECT 	@seg4_code = SUBSTRING( @acct_code, 
			datalength( @seg1_code ) + datalength( @seg2_code ) +
			datalength( @seg3_code ) + 1,
			datalength( @seg4_code ) )
	END

	
	SELECT	@len = @len - @pos
	SELECT 	@str = substring( @str, @pos+1, @len )

	
	SELECT @index = @index + 1
	SELECT	@pre_pos = @pos + @pre_pos

	SELECT 	@pos = charindex( "-", @str )
END


SELECT 	@pos = 1

IF 	@index = 1
BEGIN
	SELECT 	@seg1_code = SUBSTRING( @acct_code, @pos, datalength( @str ) )
	SELECT 	@seg2_code = '', @seg3_code = '', @seg4_code = ''
END
ELSE IF @index = 2
BEGIN
	SELECT 	@pos = @pos + datalength( @seg1_code )
	SELECT 	@seg2_code = SUBSTRING( @acct_code, @pos, datalength( @str ) )
	SELECT 	@seg3_code = '', @seg4_code = ''
END
ELSE IF @index = 3
BEGIN
	SELECT @pos = @pos + datalength( @seg1_code ) + 
		 datalength( @seg2_code )
	SELECT 	@seg3_code = SUBSTRING( @acct_code, @pos, datalength( @str ) )
	SELECT 	@seg4_code = ''
END
ELSE IF @index = 4
BEGIN
	SELECT @pos = @pos + datalength( @seg1_code ) + 
		datalength( @seg2_code ) + datalength( @seg3_code )
	SELECT 	@seg4_code = SUBSTRING( @acct_code, @pos, datalength( @str ) )
END

RETURN 0


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glprsact_sp] TO [public]
GO
