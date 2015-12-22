SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\appytadj.VWv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                




CREATE VIEW	[dbo].[appytadj_vw]
	AS SELECT *
	FROM	apinppyt
	WHERE	trx_type = 4112


GO
GRANT REFERENCES ON  [dbo].[appytadj_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[appytadj_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[appytadj_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[appytadj_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[appytadj_vw] TO [public]
GO
