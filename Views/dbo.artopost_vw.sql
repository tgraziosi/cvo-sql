SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\artopost.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                





CREATE VIEW	[dbo].[artopost_vw]
AS
SELECT	*
FROM 	arinpchg
WHERE	trx_type = 2031		
AND	printed_flag = 1
AND	hold_flag = 0



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[artopost_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[artopost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[artopost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[artopost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[artopost_vw] TO [public]
GO
