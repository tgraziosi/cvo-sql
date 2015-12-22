SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO











                                                

















CREATE  FUNCTION  [dbo].[CCADecode_fn]
    ( @IAS_Account varchar(300))
RETURNS varchar(20)
AS
BEGIN
  DECLARE @ret integer 
  DECLARE  @conrtoldb varchar(50)
  DECLARE  @version varchar(5) 
  DECLARE  @srv_inst_ctrl  varchar(500)

  SELECT @conrtoldb = control_db FROM control_db_vw
  select @version =convert( int, (select  dbo.CCAGetSQLVersion_fn()) )

 
   IF (CHARINDEX('\',@@SERVERNAME)>0) 
		BEGIN

			SELECT @srv_inst_ctrl= SUBSTRING(@@SERVERNAME ,1,  CHARINDEX('\',@@SERVERNAME)-1) + '\\'+
				SUBSTRING(@@SERVERNAME , CHARINDEX('\',@@SERVERNAME)+1, LEN(@@SERVERNAME)) + '\\' +@conrtoldb
		END
	ELSE
		BEGIN
			
			SELECT @srv_inst_ctrl= @conrtoldb
		END 
 
  
	exec master..xp_Decode  @srv_inst_ctrl, @version,  @IAS_Account OUTPUT, @ret OUTPUT
	RETURN @IAS_Account
END

 
                                              
GO
GRANT EXECUTE ON  [dbo].[CCADecode_fn] TO [public]
GO
