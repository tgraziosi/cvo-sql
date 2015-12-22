SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

Create Procedure [dbo].[EAI_CCADecode] @acc varchar(255)  
AS
BEGIN
   declare @ret int   
   DECLARE @conrtoldb varchar(50)
   DECLARE @version varchar(5) 
   DECLARE  @srv_inst_ctrl  varchar(500)
   
   SELECT @conrtoldb = control_db FROM CVO.dbo.control_db_vw
    
   select @version =convert( int, (select CVO.dbo.CCAGetSQLVersion_fn()) )
   
      IF (CHARINDEX('\',@@SERVERNAME)>0) 
   	BEGIN
   
   		SELECT @srv_inst_ctrl= SUBSTRING(@@SERVERNAME ,1,  CHARINDEX('\',@@SERVERNAME)-1) + '\\'+
   				SUBSTRING(@@SERVERNAME , CHARINDEX('\',@@SERVERNAME)+1, LEN(@@SERVERNAME)) + '\\' +@conrtoldb
   	END
      ELSE
   	BEGIN
   			
   		SELECT @srv_inst_ctrl= @conrtoldb
	END 
     
   exec master.dbo.xp_Decode @srv_inst_ctrl, @version, @acc OUTPUT , @ret OUTPUT
  
  select  @ret 'Error' , @acc 'CValue'   
END
GO
GRANT EXECUTE ON  [dbo].[EAI_CCADecode] TO [public]
GO
