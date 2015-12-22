SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\arshipok.VWv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                



CREATE VIEW	[dbo].[arshipok_vw]
AS
SELECT	*
FROM 	armaster
WHERE	address_type = 1		
 AND	status_type != 2		



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arshipok_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arshipok_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arshipok_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arshipok_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arshipok_vw] TO [public]
GO
