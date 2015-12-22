SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- select * From cvo_line_sheets_vw

CREATE view [dbo].[cvo_Line_sheets_vw] as 

select 
isnull(ia.field_26,'') as release_date,
i.upc_code,
i.web_saleable_flag,
isnull(ia.field_28,'') pom_date,
i.part_no, 
isnull(cia.item_code,'') item_code, 
i.category Collection,
c.description as CollectionName,  -- EL added 10/14/2013
ia.field_2 model, 
isnull(cia.img_front_hr,'') img_front, 
isnull(cia.img_temple_hr,'') img_temple,
isnull(cia.img_specialtyFit,'') img_specialtyfit,
isnull(cia.future_releasedate,'') future_releasedate,
cia.prim_img,
--'' as brandcasename, '' as tray_num, '' as slot_num,
i.type_code as RES_type,
isnull(ia.category_2,'') as PrimaryDemographic,
isnull(ia.category_4,'') as target_age,
isnull(cia.eye_shape,'') eye_shape,
ia.category_5 as ColorGroupCode,      -- EL added 10/14/2013
isnull((SELECT top 1 description from cvo_color_code where kys = ia.category_5),'OTHER') ColorGroupName,/*case WHEN ia.category_5 = 'BLA' THEN 'BLACK'
	WHEN ia.category_5 = 'BLU' THEN 'BLUE'
	WHEN ia.category_5 = 'BRN' THEN 'BROWN'
	WHEN ia.category_5 = 'GLD' THEN 'GOLD'
	WHEN ia.category_5 = 'GRN' THEN 'GREEN'
	WHEN ia.category_5 = 'GRY' THEN 'GREY'
	WHEN ia.category_5 = 'GUN' THEN 'GUNMETAL'
	WHEN ia.category_5 = 'MUL' THEN 'MULTI'
	WHEN ia.category_5 = 'ORA' THEN 'ORANGE'
	WHEN ia.category_5 = 'PNK' THEN 'PINK'
	WHEN ia.category_5 = 'PUR' THEN 'PURPLE'
	WHEN ia.category_5 = 'RED' THEN 'RED'
	WHEN ia.category_5 = 'SIL' THEN 'SILVER'
	WHEN ia.category_5 = 'TOR' THEN 'TORTOISE'
	WHEN ia.category_5 = 'WHI' THEN 'WHITE'
	ELSE 'OTHER' END AS ColorGroupName,     -- EL added 10/14/2013
*/
ia.field_3 as ColorName,
ia.field_17 as eye_size,
ia.field_19 as a_size,
ia.field_20 as b_size,
ia.field_21 as ed_size,
cia.dbl_size,
ia.field_8 as temple_size,
-- ia.field_9 as overall_temple_length,
ia.field_11 as frame_category,
ia.field_10 as front_material,
ia.field_12 as temple_material,
ia.field_7 as nose_pads,
ia.field_13 as hinge_type,
ia.field_24 as suns_only,
isnull(ia.field_32,'') as specialty_fit,
i.country_code as Country_of_Origin,
isnull((select top 1 description from inv_master where part_no = ia.field_1),'') as case_part,
ia.field_11 as rimless_style,
round(pp.price_a*.5,2) Price_b_front,
round(pp.price_a*.5+.75,2) Price_d_temple,
pp.price_a as Wholesale_price,
isnull(cia.sugg_retail_price,0) sugg_retail_price


from inv_master i (nolock)
inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
left outer join cvo_inv_master_add cia (nolock) on i.part_no = cia.part_no
left outer join cvo_inv_features cif (nolock) on i.part_no = cif.part_no
left outer join cvo_features cf (nolock) on cif.feature_id = cf.feature_id
inner join part_price pp (nolock) on i.part_no = pp.part_no
join category C (nolock) on i.category=c.kys              -- EL added 10/14/2013
where i.void='n' and i.type_code in ('frame','sun')











GO
GRANT REFERENCES ON  [dbo].[cvo_Line_sheets_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_Line_sheets_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_Line_sheets_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_Line_sheets_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_Line_sheets_vw] TO [public]
GO
