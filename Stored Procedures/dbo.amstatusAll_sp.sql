SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amstatusAll_sp] 
AS 

SELECT 
	timestamp,
 status_code,
	status_description,
	activity_state 
FROM 
	amstatus 
ORDER BY 
	status_code 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amstatusAll_sp] TO [public]
GO
