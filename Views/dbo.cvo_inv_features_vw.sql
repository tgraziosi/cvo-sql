SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[cvo_inv_features_vw] as 

-- 10/7/2014 - add feature_group to outputs

select -- part level features
i.part_no, i.category collection,
ia.field_2 model,
cif.seq_no, cif.feature_id, cf.feature_desc, cf.feature_group
from inv_master i (nolock)
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
inner join cvo_inv_features cif (nolock) on i.part_no = cif.part_no
inner join cvo_features cf (nolock) on cif.feature_id = cf.feature_id
where 1=1
and i.type_code in ('frame','sun')

union all -- collection level features

select distinct 
'' as part_no,
cif.collection collection,
'' as model,
cif.seq_no, cif.feature_id, cf.feature_desc, cf.feature_group
from 
cvo_inv_features cif (nolock) 
inner join cvo_features cf (nolock) on cif.feature_id = cf.feature_id
where 1=1
and cif.part_no is null and cif.style is null

union all

select distinct  -- model level features
'' as part_no,
cif.collection collection,
cif.style as model,
cif.seq_no, cif.feature_id, cf.feature_desc, cf.feature_group
from 
cvo_inv_features cif (nolock) 
inner join cvo_features cf (nolock) on cif.feature_id = cf.feature_id
inner join inv_master_add ia (nolock) on ia.field_2 = cif.style
where 1=1 
and cif.part_no is null 




GO
GRANT REFERENCES ON  [dbo].[cvo_inv_features_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_inv_features_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_inv_features_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_inv_features_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_inv_features_vw] TO [public]
GO
