SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[tdc_security_module_get_sp]
		@strUserID VARCHAR (50) ,
		@strModule VARCHAR (50) , 
		@strSource  VARCHAR (10)
AS

--First create a temp table to store the functions and access user has to those functions
--We are doing this because we only want to return records if 2 conditions are met:
-- 1.) User has access to that Module
-- 2.) User has access to at least 1 Function in that Module

CREATE TABLE #tdc_function_access (
	[Function] varchar(50) , 
	Access	 integer          )

DECLARE @intCounter INTEGER


--If no records are returned then user does not have access to that particular module
-- Because user should have access to at least  one function for that module 

INSERT INTO #tdc_function_access ([Function], Access)
SELECT tdc_security_function.[Function], 
    	tdc_security_function.Access
	FROM tdc_security_module (NOLOCK) INNER JOIN
   	              tdc_security_function (NOLOCK) ON 
   	              tdc_security_module.UserID = tdc_security_function.UserID 
	AND    tdc_security_module.Module = tdc_security_function.Module 
	AND    tdc_security_module.Source = tdc_security_function.Source
	WHERE tdc_security_module.Access = 1
	 AND       tdc_security_module.UserID = @strUserID
	AND        tdc_security_module.Module = @strModule
	AND        tdc_security_module.Source = @strSource


SELECT @intCounter = COUNT(*) FROM #tdc_function_access 
	WHERE Access > 0

IF @intCounter > 0
	BEGIN
		SELECT * FROM #tdc_function_access
	END

ELSE
	BEGIN
		SELECT * FROM #tdc_function_access WHERE Access > 0
	END


DROP TABLE #tdc_function_access

RETURN

GO
GRANT EXECUTE ON  [dbo].[tdc_security_module_get_sp] TO [public]
GO
