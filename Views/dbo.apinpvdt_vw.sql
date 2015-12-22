SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                











                                                

create view [dbo].[apinpvdt_vw] as
select trx_ctrl_num, trx_type, 
case 					
when item_code = '' then ' ' 
when  item_code = CHAR(0)  then ' '
when  item_code is null  then ' '
else 
item_code
end as item_code,
qty_received, unit_price, amt_extended from apinpcdt 
union
select trx_ctrl_num, trx_type, apply_to_num, 0,0, amt_applied  from apinppdt 
union
select pl.po_no, 1, pl.part_no, pl.qty_ordered, pl.unit_cost, pl.qty_received * pl.unit_cost
from pur_list pl (NOLOCK) inner join purchase p (NOLOCK) on pl.po_no = p.po_no where p.approval_flag = 1
GO
GRANT SELECT ON  [dbo].[apinpvdt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apinpvdt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apinpvdt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinpvdt_vw] TO [public]
GO
