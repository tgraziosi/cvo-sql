SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM dbo.cvo_cart_inv_master_vw AS cimv WHERE model = 'camilla'
-- select * From cvo_inv_master_r2_vw where collection = 'bcbg' and release_date = '05/01/2015'
-- select * From cvo_cmi_catalog_view where model = 'simona'

CREATE VIEW [dbo].[cvo_cart_inv_master_vw] AS 

SELECT DISTINCT i.part_no, 
i.category Collection,
cat.description AS CollectionName,  -- EL added 10/14/2013
ia.field_2 model, 
-- cia.img_front, 
-- cia.img_temple,
-- cia.img_34, -- 052114
---cia.img_front_hr,
---cia.img_temple_hr,
---cia.img_34_hr, -- 040214
cia.img_specialtyfit,
cia.future_releasedate,
cia.prim_img,
--'' as brandcasename, '' as tray_num, '' as slot_num,
i.type_code AS RES_type,
ia.category_5 AS ColorGroupCode,      
ISNULL(cc.description,'') ColorGroupName,
ia.field_3 AS ColorName,
ia.field_17 AS eye_size,
ia.field_19 AS a_size,
ia.field_20 AS b_size,
ia.field_21 AS ed_size,
ia.field_6 AS dbl_size, -- cia.dbl_size, -- bridge size = dbl_size
ia.field_8 AS temple_size,
ia.field_26 AS release_date,
i.upc_code,
i.web_saleable_flag,
ia.field_28 pom_date,
i.vendor


FROM inv_master i (NOLOCK)
INNER JOIN inv_master_add ia (NOLOCK) ON i.part_no = ia.part_no
LEFT OUTER JOIN cvo_inv_master_add cia (NOLOCK) ON i.part_no = cia.part_no
INNER JOIN category Cat (NOLOCK) ON cat.kys = i.category
LEFT OUTER JOIN cvo_color_code cc (NOLOCK) ON cc.kys = ia.category_5
   
WHERE i.void='n' AND i.type_code IN ('frame','sun')



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
