SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                

CREATE VIEW [dbo].[ccalog_vw]
AS
SELECT  entry_user, 
	(datediff( day, '01/01/1900', entry_date) + 693596) entry_date_jul,
	entry_date	entry_date_greg,
	message_text
 FROM CVO_Control..ccalog
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[ccalog_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ccalog_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ccalog_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ccalog_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ccalog_vw] TO [public]
GO
