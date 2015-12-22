SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_update_user_defaults]
@user VARCHAR(50)
WITH ENCRYPTION AS

BEGIN TRAN

INSERT INTO tdc_security_module             
(userid, module, source, access)            
SELECT @user userid, module, source, 0 access            
FROM tdc_security_module a(NOLOCK)          
WHERE userid = 'manager'                    
AND module NOT IN(SELECT module             
          FROM tdc_security_module b(NOLOCK)
          WHERE b.userid = @user
          AND a.source = b.source)                    

IF @@ERROR <> 0 ROLLBACK TRAN

INSERT INTO tdc_security_function
(userid, module, source, [function], access)
SELECT @user userid, module, source, [function],0 access
FROM tdc_security_function a(NOLOCK)
WHERE userid = 'manager'
AND [function] NOT IN(SELECT [function]
		  FROM tdc_security_function b(NOLOCK)
		  WHERE b.userid = @user
		  AND a.source = b.source
		  AND a.module = b.module)
IF @@ERROR <> 0 ROLLBACK TRAN

COMMIT TRAN
RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_update_user_defaults] TO [public]
GO
