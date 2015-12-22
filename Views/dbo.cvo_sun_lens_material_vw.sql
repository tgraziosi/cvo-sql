SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cvo_sun_lens_material_vw]
as 

-- select * From cvo_sun_lens_material_vw

select cast(kys as varchar(40)) kys, description, kys orig_kys
from cvo_sun_lens_material where void = 'n'
union all
	select kys+cast(feature_id as varchar(4)) as kys, kys + ' '+ feature_desc as description, kys as orig_kys
	From cvo_features f 
	cross join cvo_sun_lens_material sl
	where feature_group = 'sun lens coating'
	and sl.void = 'n' and kys <> 'unknown'

-- order by kys

GO
GRANT REFERENCES ON  [dbo].[cvo_sun_lens_material_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_sun_lens_material_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_sun_lens_material_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_sun_lens_material_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_sun_lens_material_vw] TO [public]
GO
