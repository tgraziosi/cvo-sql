SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\SM\VW\sminstap.VWv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW	[dbo].[sminstap_vw]
AS
SELECT	b.app_id,
	b.company_id,
	a.app_code,
	a.app_title
FROM	CVO_Control..smapp a, CVO_Control..sminst b
WHERE	b.app_id = a.app_id
AND	b.installed = 1




/**/                                              
GO
GRANT REFERENCES ON  [dbo].[sminstap_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[sminstap_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[sminstap_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[sminstap_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[sminstap_vw] TO [public]
GO
