SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[mc_getcmnandmember_sp]( @homecurr varchar( 8 ),  @opercurr varchar( 8 ), 
 @CmnAndMem int OUTPUT) AS BEGIN  SELECT @CmnAndMem = 0  IF EXISTS(  SELECT CVO_Control..mc_currency_group.currency_code 
 FROM CVO_Control..mc_currency_group, CVO_Control..mc_currency_group_member  WHERE ((CVO_Control..mc_currency_group.currency_code = @homecurr and 
 CVO_Control..mc_currency_group_member.currency_code = @opercurr)  OR  (CVO_Control..mc_currency_group.currency_code = @opercurr and 
 CVO_Control..mc_currency_group_member.currency_code = @homecurr))  AND  CVO_Control..mc_currency_group.currency_group_code = CVO_Control..mc_currency_group_member.currency_group_code) 
 BEGIN  SELECT @CmnAndMem = 1  END END 
GO
GRANT EXECUTE ON  [dbo].[mc_getcmnandmember_sp] TO [public]
GO
