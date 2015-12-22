SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amglchartExists_sp] 
( 
	@account_code varchar(32), 
	@valid int OUTPUT 
) 
AS 


IF EXISTS (SELECT 	account_code 
			FROM 	glchart 
			WHERE 	account_code	= @account_code)
 SELECT @valid = 1 
ELSE 
 SELECT @valid = 0 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amglchartExists_sp] TO [public]
GO
