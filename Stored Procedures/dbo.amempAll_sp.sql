SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amempAll_sp] 
AS 

SELECT 
	timestamp,
	employee_code,
	employee_name,
	job_title 
FROM 
	amemp 
ORDER BY 
	employee_code 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amempAll_sp] TO [public]
GO
