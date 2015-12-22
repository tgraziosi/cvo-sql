SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[mc_getcurrencies_sp]( @homecurr varchar( 8 ) OUTPUT,  @opercurr varchar( 8 ) OUTPUT) 
AS BEGIN  SELECT @homecurr = home_currency, @opercurr = oper_currency  FROM glco 
END 
GO
GRANT EXECUTE ON  [dbo].[mc_getcurrencies_sp] TO [public]
GO
