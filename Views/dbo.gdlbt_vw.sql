SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/





CREATE VIEW [dbo].[gdlbt_vw]
AS
select	l.location,	l.part_no,	l.bin_no,	l.lot_ser,	l.date_tran,
	l.date_expires,	l.qty,		
case m.inv_cost_method
when 'E' then 
isnull((select sum(tot_mtrl_cost + tot_dir_cost + tot_ovhd_cost + tot_util_cost) / sum(balance) from inv_costing c
where c.part_no = l.part_no and c.location = l.location and c.account = 'STOCK' and c.lot_ser = l.lot_ser),0)
when 'S' then 
isnull((select (std_cost + std_direct_dolrs + std_ovhd_dolrs + std_util_dolrs) from inv_list i where i.part_no = l.part_no and i.location = l.location),0)
 else 
isnull((select (avg_cost + avg_direct_dolrs + avg_ovhd_dolrs + avg_util_dolrs) from inv_list i where i.part_no = l.part_no and i.location = l.location),0)
end  cost,	
l.qty_physical
from	lot_bin_stock l
join inv_master m on m.part_no = l.part_no
GO
GRANT SELECT ON  [dbo].[gdlbt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gdlbt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gdlbt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gdlbt_vw] TO [public]
GO
