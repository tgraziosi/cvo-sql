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




























CREATE  PROC [dbo].[appvaltrxdup_sp] 	@viewNP varchar(16), 
 				@viewP varchar(16), 
				@tableOPC varchar(16),
				@where1 varchar(255),
				@where2 varchar(255),
				@module smallint = 0
AS

   DECLARE @SQLString NVARCHAR(500),
           @ret SMALLINT

  SELECT @SQLString = 'SELECT SUM(num) FROM (' 
  SELECT @SQLString = @SQLString + 'SELECT 1 num FROM ' + @viewNP + '_all WHERE ' + @where1 + ' AND ' + @where2

  IF (@viewNP <> @viewP)
  	IF (@module = 4000)
  		SELECT @SQLString = @SQLString + ' UNION SELECT 2 FROM ' + @viewP + '_all WHERE ' + @where1
	ELSE
		SELECT @SQLString = @SQLString + ' UNION SELECT 2 FROM ' + @viewP + '_all WHERE ' + @where1 + ' AND ' + @where2


  IF (len(ISNULL(@tableOPC, '')) <> 0 )
  	SELECT @SQLString = @SQLString + ' UNION SELECT 3 FROM ' + @tableOPC + ' WHERE ' + @where1

  SELECT @SQLString = @SQLString + ' ) ret'

  EXEC (@SQLString)

GO
GRANT EXECUTE ON  [dbo].[appvaltrxdup_sp] TO [public]
GO
