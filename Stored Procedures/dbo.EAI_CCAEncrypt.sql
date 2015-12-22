SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

Create Procedure [dbo].[EAI_CCAEncrypt] @acc varchar(255), @pubk varchar(255)  
AS
BEGIN

   exec master.dbo.xp_EncryptAcct @pubk ,  @acc OUTPUT
   SELECT  @acc 'EncryptValue' 
END
GO
GRANT EXECUTE ON  [dbo].[EAI_CCAEncrypt] TO [public]
GO
