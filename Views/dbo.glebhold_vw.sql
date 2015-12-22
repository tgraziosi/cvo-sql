SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                















CREATE VIEW [dbo].[glebhold_vw]	
				(
				ebas_key,
				amount,
				din)
				AS
				SELECT	substring(ebas_key,1,3),
					convert(varchar(20),convert(int,round(sum(amount),0,1))),din
				FROM	 glebhold
				GROUP BY ebas_key, din
					
GO
GRANT REFERENCES ON  [dbo].[glebhold_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glebhold_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glebhold_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glebhold_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glebhold_vw] TO [public]
GO
