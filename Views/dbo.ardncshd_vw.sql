SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                


















CREATE VIEW	[dbo].[ardncshd_vw]
AS

	SELECT	*, (amt_due-amt_paid) as total_due
	FROM 	ardncshd		

	
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[ardncshd_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ardncshd_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ardncshd_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ardncshd_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ardncshd_vw] TO [public]
GO
