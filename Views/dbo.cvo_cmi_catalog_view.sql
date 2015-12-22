SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- select img_34, img_front, img_temple, * from cvo_cmi_catalog_view where model = 'cupcake'


CREATE VIEW [dbo].[cvo_cmi_catalog_view] AS 
	SELECT 
	ISNULL(x.dim_id, d.id) AS part_no, 
	bm.id AS cmi_model_id,
	bm.brand AS Collection,
	bm.brand AS CollectionName,
	bm.model_name AS model, 
	bm.short_model, -- 070914- tag
	-- v.temple_img as img_temple, 
	-- v.front_img as img_front, 
	bm.demographic AS PrimaryDemographic, 
	bm.target_age, 
	bm.eye_shape, 
	bm.RES_type, 
	bm.case_part,
	bm.frame_category,
	bm.front_material,
	bm.temple_material,
	bm.nose_pads,
	bm.hinge_type,
	bm.release_date,
	'1' AS prim_img,
	v.color_family AS ColorGroupCode, 
	v.color AS ColorName,
	d.fit AS specialty_fit,
	'Y' AS web_saleable_flag,
	d.eye_size,
	CAST(d.a_size AS DECIMAL(18,1)) AS a_size, 
	CAST(d.b_size AS DECIMAL(18,1)) AS b_size, 
	CAST(d.ed_size AS DECIMAL(18,1)) AS ed_size, 
	d.bridge_size AS dbl_size,
	CAST(d.temple_size AS DECIMAL(18,1)) AS temple_size, 			
	d.dim_unit,
	-- d.overall_temple_length,
	-- tag - more fields for line sheets and Epicor in general
	bm.temple_tip_material,
	bm.suns_only,
	bm.lens_base,
	bm.front_price,
	bm.temple_price,
	bm.wholesale_price,
	bm.retail_price,
	bm.progressive_type,
	bm.component_1,
	bm.component_2,
	bm.component_3,
	bm.spare_temple_length,
	v.asterisk_1,
	v.asterisk_2,
	v.asterisk_3,
	-- v.highres_34_img img_34,
	v.varImported,
	v.varImportDate,
	ISNULL(	CASE WHEN v.variant_release_date='1/1/1900' THEN NULL ELSE v.variant_release_date END, bm.release_date) variant_release_date
	, bm.id model_id
	, v.id  variant_id
	, d.id dim_id
	, w.id wsht_id
	-- added 101314 for sku generate
	, BM.clips_available
	, v.ispolarizedavailable
	, bm.supplier
	, bm.country_origin
	, d.frame_cost
	, d.front_cost
	, d.temple_cost
	, bm.cost_currency
	, bm.single_cable_cost
	, d.ws_ship1_qty
	, d.ws_ship2_qty
	, d.ws_ship3_qty
	, i.img_34 img_34
	, i.img_temple AS img_temple
	, i.img_front AS img_front
	, i.img_sku
	, bm.print_flag
	-- 08/25/2015 - add for sku gen project
	-- , x.part_no
	, x.upc_code
	, x.date_added
	, ISNULL(	CASE WHEN d.dim_release_date='1/1/1900' THEN NULL ELSE d.dim_release_date END, bm.release_date) dim_release_date
	, bm.model_lead_time
	, v.lens_color

	FROM 
	
	cvo_cmi_models bm 
	LEFT JOIN	cvo_cmi_variants v ON (v.model_id = bm.id) 
	LEFT JOIN 	cvo_cmi_dimensions d ON (v.id = d.variant_id) 
	LEFT JOIN 	cvo_cmi_worksheet w ON (v.id = w.variant_id)
	LEFT JOIN   dbo.cvo_cmi_sku_xref x ON (x.dim_id = d.id)
	LEFT JOIN   cvo_inv_master_r2_vw i 
		ON i.collection = bm.brand AND i.model= bm.model_name
		AND d.eye_size =  i.eye_size AND v.color = i.colorname
	
	WHERE v.isActive = 1









GO
