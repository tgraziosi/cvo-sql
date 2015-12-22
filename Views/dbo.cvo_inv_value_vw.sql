SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
select y.account, x.* from cvo_inv_value_vw x, inv_master y where x.part_no = y.part_no
and x.std_cost = 0 and inv_acct_code like '140%'
order by y.account, x.type_code, x.part_no

select * into cvo_inv_val_201207 from cvo_inv_value_vw
grant select on cvo_inv_val_201207 to public

*/

CREATE view [dbo].[cvo_inv_value_vw] 
as
-- v1.1 - tag - 071912 - add account numbers for the posting code
-- v1.2 - tag - 080612 - picked orders and transfers not yet shipped
-- v1.3 - tag - 091712 - added columns for inventory w/o any exclusions (cvo_in_stock)
-- v1.4 - tag - 10/24/2012 - add qc holds to support 1405 account
-- v1.5 - tag - 110612 - add transit qty and value to track transfers shipped not rec'd

select i.location, inv.category, inv.type_code, i.part_no, inv.description, i.in_stock,
isnull((select sum(lbs.qty) from lot_bin_stock lbs (nolock) 
	where lbs.location=i.location and i.part_no = lbs.part_no), 0) LBS_qty,
-- tag 091712
i.cvo_in_stock,
i.in_stock * (i.std_cost + i.std_ovhd_dolrs + i.std_util_dolrs) ext_value,
isnull((select sum(lbs.qty) from lot_bin_stock lbs (nolock) 
	where lbs.location=i.location and i.part_no = lbs.part_no), 0) 
	* (i.std_cost + i.std_ovhd_dolrs + i.std_util_dolrs) LBS_ext_value,
-- 091712
i.cvo_in_stock * (i.std_cost + i.std_ovhd_dolrs + i.std_util_dolrs) cvo_ext_value,
i.std_cost, i.std_ovhd_dolrs, i.std_util_dolrs, 
-- added 080612 - tag - picked orders and transfers not yet shipped
(i.hold_ord + i.hold_xfr) as PNS_qty,
(i.hold_ord + i.hold_xfr) * (i.std_cost + i.std_ovhd_dolrs + i.std_util_dolrs) PNS_value,
i.hold_rcv as QC_qty,
i.hold_rcv * (i.std_cost + i.std_ovhd_dolrs + i.std_util_dolrs) QC_Value,
-- 110612 - v1.5
i.transit as INT_qty,
i.transit * (i.std_cost + i.std_ovhd_dolrs + i.std_util_dolrs) INT_Value,
case when inv.obsolete = 1 then 'yes' else 'no' end as obs,
ia.field_28 as pom_date,
ia.datetime_2 as bkordr_date,
inv_acct_code, inv_ovhd_acct_code, inv_util_acct_code, getdate() as AsOfDate
-- tag - 12/08/2014 - add valuation groupings - acctg request
, Valuation_group = case when i.type_code in ('frame','sun') then 'Frame/Sun'
					when i.type_code in ('Case') then 'Cases'
					else 'Parts' end
from inventory i (nolock) 
inner join inv_master inv (nolock) on inv.part_no = i.part_no
inner join inv_master_add ia (nolock) on inv.part_no = ia.part_no
inner join in_account acct (nolock) on inv.account=acct.acct_code
where (i.cvo_in_stock <> 0 or i.hold_ord <> 0 or i.hold_xfr <> 0 or i.hold_rcv<>0)

GO
GRANT REFERENCES ON  [dbo].[cvo_inv_value_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_inv_value_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_inv_value_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_inv_value_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_inv_value_vw] TO [public]
GO
