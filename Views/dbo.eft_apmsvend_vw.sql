SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\eft_apmsvend.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                



CREATE VIEW [dbo].[eft_apmsvend_vw] AS
SELECT *
FROM eft_apms
WHERE pay_to_code = ''
GO
GRANT REFERENCES ON  [dbo].[eft_apmsvend_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[eft_apmsvend_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[eft_apmsvend_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[eft_apmsvend_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[eft_apmsvend_vw] TO [public]
GO
