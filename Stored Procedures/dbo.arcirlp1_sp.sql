SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


 

CREATE PROC [dbo].[arcirlp1_sp]
 	@custcode char(8),
 @relcode char(8),
 @tier int,
 @circular smallint OUTPUT, 
 @too_many_tiers smallint OUTPUT
		 
AS 

DECLARE @custchild char(8), 
 @count int 





INSERT #stack
VALUES ( @tier, @custcode )


SELECT @custchild = ""


WHILE ( ( @circular = 0 ) and ( @too_many_tiers = 0 ) )
BEGIN
 
 SELECT @custchild = MIN(child)
	 FROM	 arnarel
	 WHERE	 parent = @custcode
	 AND	 relation_code = @relcode
	 AND	 child > @custchild
 
 

 If ( ( @@ROWCOUNT = 0 ) OR ( @custchild IS NULL ) ) 
 BREAK

 SELECT @tier = @tier + 1 

 IF ( @tier > 10 ) 
 SELECT @too_many_tiers = 1
 ELSE 
 BEGIN 
 SELECT @count = count(*)
 FROM #stack
 WHERE ( #stack.customer = @custchild )

 IF ( @count > 0 ) 
 SELECT @circular = 1
 ELSE 
 
 exec arcirlp2_sp @custchild, @relcode, @tier, @circular OUTPUT, @too_many_tiers OUTPUT
 
 DELETE #stack
 WHERE #stack.tier = @tier
 END
END 

GO
GRANT EXECUTE ON  [dbo].[arcirlp1_sp] TO [public]
GO
