SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select * From cvo_inv_master_r2_vw where collection = 'bcbg' and release_date = '05/01/2015'
-- select * From cvo_cmi_catalog_view where model = 'simona'

CREATE view [dbo].[cvo_cart_inv_master_vw] as 

select distinct i.part_no, 
i.category Collection,
cat.description as CollectionName,  -- EL added 10/14/2013
ia.field_2 model, 
cia.img_front, 
cia.img_temple,
cia.img_34, -- 052114
cia.img_front_hr,
cia.img_temple_hr,
cia.img_34_hr, -- 040214
cia.img_specialtyfit,
cia.future_releasedate,
cia.prim_img,
--'' as brandcasename, '' as tray_num, '' as slot_num,
i.type_code as RES_type,
ia.category_5 as ColorGroupCode,      
isnull(cc.description,'') ColorGroupName,
ia.field_3 as ColorName,
ia.field_17 as eye_size,
ia.field_19 as a_size,
ia.field_20 as b_size,
ia.field_21 as ed_size,
ia.field_6 as dbl_size, -- cia.dbl_size, -- bridge size = dbl_size
ia.field_8 as temple_size,
ia.field_26 as release_date,
i.upc_code,
i.web_saleable_flag,
ia.field_28 pom_date,
i.vendor


from inv_master i (nolock)
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
left outer join cvo_inv_master_add cia (nolock) on i.part_no = cia.part_no
inner join category Cat (nolock) on cat.kys = i.category
left outer join cvo_color_code cc (nolock) on cc.kys = ia.category_5
   
where i.void='n' and i.type_code in ('frame','sun')


GO
GRANT REFERENCES ON  [dbo].[cvo_cart_inv_master_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_cart_inv_master_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cart_inv_master_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_cart_inv_master_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cart_inv_master_vw] TO [public]
GO
