SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\aptrxtyp.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                




CREATE VIEW	[dbo].[aptrxtyp_vw]
	AS SELECT *
	FROM	aptrxtyp
	WHERE	trx_type = 4091
	OR	trx_type = 4092


GO
GRANT REFERENCES ON  [dbo].[aptrxtyp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[aptrxtyp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[aptrxtyp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[aptrxtyp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptrxtyp_vw] TO [public]
GO
