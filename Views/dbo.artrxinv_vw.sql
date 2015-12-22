SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\artrxinv.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                





CREATE VIEW	[dbo].[artrxinv_vw]
AS
SELECT	*
FROM 	artrx
WHERE	trx_type = 2031		



/**/                                              
GO
GRANT REFERENCES ON  [dbo].[artrxinv_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxinv_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxinv_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxinv_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxinv_vw] TO [public]
GO
