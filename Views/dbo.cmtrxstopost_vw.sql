SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              

              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[cmtrxstopost_vw] AS
select org_id = b.org_id, organizationname = b.organization_name, 
	trx_type = a.trx_type, hold_flag= a.hold_flag
from cmmanhdr a, iborganization_zoom_vw b 
where a.org_id = b.org_id and  hold_flag <> 1

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[cmtrxstopost_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cmtrxstopost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cmtrxstopost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cmtrxstopost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmtrxstopost_vw] TO [public]
GO
