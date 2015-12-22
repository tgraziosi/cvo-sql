SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_Cost_Differences_vw] as
select inv1.part_no, 
i.description, 
i.type_code, 
inv1.std_cost as std_cost_001, 
inv1.std_ovhd_dolrs as std_ovhd_dolrs_001,
inv1.std_util_dolrs as std_util_dolrs_001,
inv2.location, 
inv2.std_cost, 
inv2.std_ovhd_dolrs, 
inv2.std_util_dolrs, 
inv1.entered_who, 
inv1.entered_date
from inv_list inv1 (nolock)
inner join inv_master i (nolock) on inv1.part_no = i.part_no
left outer join inv_list inv2 (nolock) on inv1.part_no = inv2.part_no
where (inv1.location = '001') and (inv2.location != '001')
and ((inv1.std_cost <> inv2.std_cost or inv1.std_cost is null or inv2.std_cost is null) or
	(inv1.std_ovhd_dolrs <> inv2.std_ovhd_dolrs or inv1.std_ovhd_dolrs is null or 
     inv2.std_ovhd_dolrs is null) or 
	(inv1.std_util_dolrs <> inv2.std_util_dolrs or inv2.std_util_dolrs is null or 
     inv2.std_util_dolrs is null))
GO
