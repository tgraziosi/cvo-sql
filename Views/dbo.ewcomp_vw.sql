SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



/*             
ewcomp.VWv - e7.3.3 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 2004 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 2004 Epicor Software Corporation, 2004  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[ewcomp_vw]
AS SELECT * from CVO_Control..ewcomp

/**/                                              

GO
GRANT REFERENCES ON  [dbo].[ewcomp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ewcomp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ewcomp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ewcomp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ewcomp_vw] TO [public]
GO
