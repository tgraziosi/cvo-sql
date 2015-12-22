SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                

CREATE VIEW [dbo].[dispute_trx_vw]
AS 
SELECT 	
	a.dispute_flag,
	a.dispute_code,
	b.trx_ctrl_num ,
	b.controlling_org_id,
	b.detail_org_id,
	c.trx_ctrl_num as journal_ctrl_num,
	b.trx_type,
	b.date_applied,
	a.account_code,
	convert(float,a.amount)  amount,
        a.last_change_username
from ibdet a
inner join ibhdr b
on a.id = b.id
inner join iblink c
on a.id = c.id
where reconciled_flag = 0
and a.sequence_id = 1
and c.sequence_id = 2
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[dispute_trx_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[dispute_trx_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[dispute_trx_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[dispute_trx_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[dispute_trx_vw] TO [public]
GO
