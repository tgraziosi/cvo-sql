SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\SM\VW\smmstprc.VWv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[smmstprc_vw]
AS
SELECT * from master..sysprocesses





/**/                                              
GO
GRANT REFERENCES ON  [dbo].[smmstprc_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smmstprc_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smmstprc_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smmstprc_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smmstprc_vw] TO [public]
GO
