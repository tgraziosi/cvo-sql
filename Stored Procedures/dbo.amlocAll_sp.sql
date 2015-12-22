SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amlocAll_sp] 
AS 

SELECT 
	timestamp,
	location_code,
	location_description 
FROM 
	amloc 
ORDER BY 
	location_code 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amlocAll_sp] TO [public]
GO
