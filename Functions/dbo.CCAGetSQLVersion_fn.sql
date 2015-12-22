SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

CREATE  FUNCTION  [dbo].[CCAGetSQLVersion_fn]( )
RETURNS varchar(5)
AS
BEGIN
  DECLARE  @strver  char(255)
  DECLARE  @pos	    smallint
  DECLARE  @version varchar(5) 
  
  select @strver = @@version
  select @pos = patindex( '%.%', @strver )
  select @strver = substring(@strver, @pos-2, 2 )

  if ( ascii( @strver ) = 47 )
	select @strver = stuff( @strver, 1, 1, ' ' )

  select @version =convert( int, @strver )

	RETURN @version
END

 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[CCAGetSQLVersion_fn] TO [public]
GO
