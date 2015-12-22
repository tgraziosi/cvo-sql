SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\apremit.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                




CREATE VIEW [dbo].[apremit_vw] 
AS
SELECT
 	appayto.vendor_code,
	appayto.pay_to_code,
 appayto.pay_to_name,
 apvend.vendor_name
	
FROM apvend, appayto
WHERE apvend.vendor_code = appayto.vendor_code

GO
GRANT REFERENCES ON  [dbo].[apremit_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apremit_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apremit_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apremit_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apremit_vw] TO [public]
GO
