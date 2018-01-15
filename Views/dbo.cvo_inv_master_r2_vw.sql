SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- select top 100 * From cvo_inv_master_r2_vw where collection = 'op' and model = '808'
-- select * From cvo_cmi_catalog_view where model = 'simona'
-- select top 1000 * from cvo_inv_master_r2_vw

CREATE VIEW [dbo].[cvo_inv_master_r2_vw] AS 

SELECT DISTINCT i.part_no, 
cia.item_code, 
i.category Collection,
cat.description AS CollectionName,  -- EL added 10/14/2013
ia.field_2 model, 
cia.img_front, 
cia.img_temple,
cia.img_34, -- 052114
cia.img_front_hr,
cia.img_temple_hr,
cia.img_34_hr, -- 040214
cia.IMG_SKU, -- 082415
CIA.IMG_WEB, -- 022516
cia.img_specialtyfit,
cia.future_releasedate,
cia.prim_img,
--'' as brandcasename, '' as tray_num, '' as slot_num,
i.type_code AS RES_type,
LOWER(CASE WHEN ia.category_2 = 'unknown' THEN '' 
 WHEN ia.category_2 = 'Male-Child' AND i.category IN ('izod','izx') THEN 'boys'
 WHEN ia.category_2 = 'Female-Child' AND i.category IN ('jmc') THEN 'girls'
 WHEN ia.category_2 LIKE '%child%' AND i.category IN ('op') THEN 'kids'
 ELSE ISNULL(g.description,'') END) AS PrimaryDemographic,
ISNULL(age.description,'') AS target_age,
ISNULL(x.eye_shape,ISNULL(cia.eye_shape,'')) eye_shape,
ia.category_5 AS ColorGroupCode,      
ISNULL(cc.description,'') ColorGroupName,
ia.field_3 AS ColorName,
ia.field_17 AS eye_size,
ISNULL(x.a_size,ia.field_19) AS a_size, -- get these values from cmi if available - 12/4/2015
ISNULL(x.b_size, ia.field_20) AS b_size,
ISNULL(x.ed_size,ia.field_21) AS ed_size,
ia.field_6 AS dbl_size, -- cia.dbl_size, -- bridge size = dbl_size
ia.field_8 AS temple_size,
-- no longer used - 11/25/2014 ia.field_9 as overall_temple_length,
ISNULL(x.dim_unit,'') AS dim_unit,
ISNULL(ft.description,'') AS frame_type,
ISNULL(fm.description,'') AS front_material,
ISNULL(tm.description,'') AS temple_material,
ISNULL(np.description,'') AS nose_pads,
ISNULL(th.description,'') AS hinge_type,
ISNULL(slc.description,'') AS sun_lens_color,
ISNULL(slm.description,'') AS sun_material,
ISNULL(slt.description,'') AS sun_lens_type,
ISNULL(sf.description,'') AS specialty_fit,
ISNULL(c.description,'') AS Country_of_Origin,
ISNULL(CAST(cp.long_descr AS VARCHAR(60)),'') AS case_part,
ISNULL(rs.description,'') AS rimless_style,
ROUND(pp.front_price,2) front_price,
ROUND(pp.temple_price,2) temple_price,
ROUND(pp.frame_price,2) Wholesale_price,
pp.Last_price_upd_date,
cia.sugg_retail_price,
ia.field_26 AS release_date,
i.upc_code,
i.web_saleable_flag,
ia.field_28 pom_date,
-- add cost fields for CMI - 060614
pp.frame_cost,
pp.temple_cost,
pp.cable_cost,
pp.front_cost
, i.vendor
, ap.nat_cur_code 
, ap.country_code
, gc.description country_name
, ISNULL(ia.field_5,'N') ispolarizedavailable
--, isnull((select top 1 f.feature_desc from cvo_inv_features_vw f where 
--	((f.collection = i.category and f.model = ia.field_2) or (f.part_no = i.part_no))
--	and f.feature_group = 'Progressive Friendly' ),'') as progressive_type
, ISNULL(pf.feature_desc,'') AS progressive_type
-- add case info and frame weight for website
, i.weight_ea frame_weight
, ISNULL(cpi.part_no,'') AS case_part_no
, ISNULL(cpi.weight_ea,0) AS case_weight
, LOWER(CASE WHEN ia.category_2 = 'unknown' THEN '' 
 WHEN ia.category_2 = 'Male-Child' AND i.category IN ('izod','izx','op') THEN 'boys'
 WHEN ia.category_2 = 'Female-Child' AND i.category IN ('jmc','op') THEN 'girls'
 WHEN ia.category_2 LIKE '%child%' THEN 'kids'
 ELSE ISNULL(g.description,'') END) AS PrimaryDemo_Web,
 ISNULL(pa.attribute,'') attributes -- 1/8/2018 - multiple attributes


FROM inv_master i (NOLOCK)
INNER JOIN inv_master_add ia (NOLOCK) ON i.part_no = ia.part_no
LEFT OUTER JOIN cvo_inv_master_add cia (NOLOCK) ON i.part_no = cia.part_no
INNER JOIN category Cat (NOLOCK) ON cat.kys = i.category
-- left outer join dbo.f_get_price_for_styles() pp on pp.part_no = i.part_no 
LEFT OUTER JOIN apmaster ap (NOLOCK) ON ap.vendor_code = i.vendor
LEFT OUTER JOIN gl_country gc (NOLOCK) ON gc.country_code = ap.country_code
LEFT OUTER JOIN cvo_part_price_cost_vw (NOLOCK) pp ON pp.part_no = i.part_no
LEFT OUTER JOIN cvo_age age (NOLOCK) ON age.kys = ia.category_4
LEFT OUTER JOIN cvo_gender g (NOLOCK ) ON g.kys = ia.category_2
LEFT OUTER JOIN cvo_color_code cc (NOLOCK) ON cc.kys = ia.category_5
LEFT OUTER JOIN cvo_frame_type (NOLOCK) ft ON ft.kys = ia.field_11
LEFT OUTER JOIN cvo_frame_matl (NOLOCK) fm ON fm.kys = ia.field_10
LEFT OUTER JOIN cvo_temple_matl (NOLOCK) tm ON tm.kys = ia.field_12
LEFT OUTER JOIN cvo_nose_pad (NOLOCK) np ON np.kys = ia.field_7
LEFT OUTER JOIN cvo_temple_hindge (NOLOCK) th ON th.kys = ia.field_13
LEFT OUTER JOIN cvo_sun_lens_color (NOLOCK) slc ON slc.kys = ia.field_23
LEFT OUTER JOIN cvo_sun_lens_material (NOLOCK) slm ON slm.kys = ia.field_24
LEFT OUTER JOIN cvo_sun_lens_type (NOLOCK) slt ON slt.kys = ia.field_25
LEFT OUTER JOIN cvo_specialty_fit (NOLOCK) sf ON sf.kys = ia.field_32
LEFT OUTER JOIN gl_country (NOLOCK) c ON c.country_code = i.country_code
LEFT OUTER JOIN inv_master_add cp (NOLOCK) ON cp.part_no = ia.field_1
-- add cases for website
LEFT OUTER JOIN inv_master cpi (NOLOCK) ON cpi.part_no = ia.field_1
LEFT OUTER JOIN cvo_frame_type rs (NOLOCK) ON rs.kys = ia.field_11 
LEFT OUTER JOIN cvo_inv_features_vw pf ON 
	((pf.collection = i.category AND pf.model = ia.field_2) OR (pf.part_no = i.part_no))
	AND pf.feature_group = 'Progressive Friendly'
-- 12/4/2015 get a,b,ed from cmi if available
LEFT OUTER JOIN 
(SELECT part_no, a_size, b_size, ed_size, d.dim_unit, m.eye_shape
 FROM dbo.cvo_cmi_sku_xref xref
 JOIN dbo.cvo_cmi_dimensions d ON xref.dim_id = d.id
  JOIN dbo.cvo_cmi_models m ON m.id = d.model_id
) AS x  ON x.part_no = i.part_no
LEFT OUTER JOIN ( SELECT    c.part_no ,
                STUFF(( SELECT  '; ' + attribute
                        FROM    dbo.cvo_part_attributes pa2 (NOLOCK)
                        WHERE   pa2.part_no = c.part_no
                        FOR
                        XML PATH('')
                        ), 1, 1, '') attribute
        FROM      dbo.cvo_part_attributes  c
    ) AS pa ON pa.part_no = i.part_no

   
WHERE i.void='n' AND i.type_code IN ('frame','sun')


-- select * From cvo_part_price_cost_vw where part_no = 'cvellblu5114'









GO

GRANT REFERENCES ON  [dbo].[cvo_inv_master_r2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_inv_master_r2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_inv_master_r2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_inv_master_r2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_inv_master_r2_vw] TO [public]
GO
