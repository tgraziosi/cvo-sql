SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2005 Epicor Software Corporation, 2005    
                  All Rights Reserved                    
*/                                                



CREATE FUNCTION [dbo].[ib_strlevel_fn] ( @string1  nvarchar(255), @charindex varchar(1) )
RETURNS int
AS
BEGIN
   DECLARE @dots  integer, 
        @countciclo  integer, 
        @string2  nvarchar(255),
        @levelreturn integer
    IF (LEN(RTRIM(@charindex)) = 0 )
       SET @charindex = '.' 

    SELECT @string2 = RTRIM(@string1)
    SELECT @countciclo = LEN(RTRIM(@string1)) 
    SELECT @dots = 1 

   IF( @string2 = '0' ) 
   BEGIN 
    SELECT @dots = 0
    SELECT @levelreturn = @dots
    RETURN ( @levelreturn )
   END

   WHILE ( @countciclo ) > 0
   BEGIN
           IF ( charindex(@charindex , @string2)  > 0 )
           BEGIN 
             SELECT  @string2 = SUBSTRING( @string2, CASE WHEN charindex(@charindex , @string2) = 0 THEN 1                                                       
                           ELSE ( charindex(@charindex , @string2) + 1 ) END, 
                           LEN(@string2) - ( CASE WHEN charindex(@charindex , @string2 ) = 0 THEN 1
                           ELSE ( charindex(@charindex , @string2)  ) END )  )  
             SELECT  @dots = @dots + 1 
           END
           
           SELECT @countciclo = @countciclo - 1
           IF ( @countciclo  = 0 )   BREAK
           CONTINUE
   END 
   SELECT @levelreturn = @dots
   RETURN ( @levelreturn )
END
GO
GRANT REFERENCES ON  [dbo].[ib_strlevel_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[ib_strlevel_fn] TO [public]
GO
