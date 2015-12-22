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

CREATE VIEW [dbo].[smacctgrphdr_vw]
AS
	
	SELECT
		group_name,
		group_desc,
		global_flag=CASE global_flag WHEN 0 THEN 'NO' ELSE 'YES' END
	FROM smaccountgrphdr
GO
GRANT REFERENCES ON  [dbo].[smacctgrphdr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smacctgrphdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smacctgrphdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smacctgrphdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smacctgrphdr_vw] TO [public]
GO
