SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arcirc.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[arcirc_sp]	@relcode char(8)
AS 
DECLARE @custcode char(8), 
 @tier int,
 @circular smallint,
 @too_many_tiers smallint





CREATE TABLE #stack
(
	tier		int not null,
	customer	char(8) not null
)
CREATE UNIQUE INDEX #stack_ind_0 ON #stack ( tier )
CREATE INDEX #stack_ind_1 ON #stack ( customer )




SELECT @circular = 0 
SELECT @too_many_tiers = 0 
SELECT @tier = 0 
SELECT @custcode = ""


WHILE ( ( @circular = 0 ) and ( @too_many_tiers = 0 ) )
BEGIN
  
 
 SELECT @custcode = MIN(parent)
 FROM	 arnarel
 WHERE	 arnarel.relation_code = @relcode
 AND	 parent > @custcode
 
 

 IF ( ( @@ROWCOUNT = 0 ) OR ( @custcode IS NULL ) ) 
 BREAK

 SELECT @tier = 1 

 
 exec arcirlp1_sp @custcode, @relcode, @tier, @circular OUTPUT, @too_many_tiers OUTPUT

 
 DELETE #stack
 WHERE #stack.tier = @tier
END


SELECT @circular, @too_many_tiers

DROP TABLE #stack


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcirc_sp] TO [public]
GO
