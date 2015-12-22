SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\VW\glchart.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW 	[dbo].[glchart_vw]
	AS 	SELECT * 
	FROM	glchart
	WHERE	inactive_flag = 0
	AND account_code IN (SELECT  account_code FROM sm_accounts_access_vw)



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[glchart_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glchart_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glchart_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glchart_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glchart_vw] TO [public]
GO
