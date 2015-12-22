SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                

CREATE VIEW [dbo].[arinpchg_cus_vw]
as
select a.customer_code, b.customer_name, a.trx_type, a.printed_flag, a.hold_flag, a.org_id, c.organizationname
from arinpchg a, arcust b, iborganization_zoom_vw c
where a.customer_code = b.customer_code and a.org_id = c.org_id

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arinpchg_cus_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arinpchg_cus_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arinpchg_cus_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arinpchg_cus_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinpchg_cus_vw] TO [public]
GO
