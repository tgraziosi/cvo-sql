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


















CREATE  FUNCTION  [dbo].[CCAGenerateKeys_fn]( )
RETURNS varchar(255)
AS
BEGIN
  DECLARE @pub_key varchar(255)
  DECLARE  @conrtoldb varchar(50)
  DECLARE  @version varchar(5) 
  DECLARE  @srv_inst_ctrl  varchar(500)
 
  SELECT @conrtoldb = control_db FROM control_db_vw
  
  SELECT @version =convert( int, (select  dbo.CCAGetSQLVersion_fn()) )

 
   IF (CHARINDEX('\',@@SERVERNAME)>0) 
		BEGIN

			SELECT @srv_inst_ctrl= SUBSTRING(@@SERVERNAME ,1,  CHARINDEX('\',@@SERVERNAME)-1) + '\\'+
				SUBSTRING(@@SERVERNAME , CHARINDEX('\',@@SERVERNAME)+1, LEN(@@SERVERNAME)) + '\\' +@conrtoldb
		END
	ELSE
		BEGIN
			
			SELECT @srv_inst_ctrl= @conrtoldb
		END 
 
  
  EXEC master..xp_GenerateKeys @srv_inst_ctrl, @version ,@pub_key OUTPUT
  RETURN @pub_key
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[CCAGenerateKeys_fn] TO [public]
GO
