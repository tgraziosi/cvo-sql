SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\VW\arinvadj.VWv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                





CREATE VIEW	[dbo].[arinvadj_vw]
AS
SELECT	*
FROM 	artrx
WHERE	trx_type = 2031		
AND apply_to_num NOT IN ( SELECT apply_to_num FROM arinpchg
 WHERE trx_type = 2051 )


/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arinvadj_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arinvadj_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arinvadj_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arinvadj_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinvadj_vw] TO [public]
GO
