SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

Create Procedure [dbo].[EAI_CCAENcode] @acc varchar(255), @pubk varchar(255)  
AS
BEGIN
   exec master.dbo.xp_Encode @pubk ,  @acc OUTPUT
   select  @acc 'CEncode'   
END
GO
GRANT EXECUTE ON  [dbo].[EAI_CCAENcode] TO [public]
GO
