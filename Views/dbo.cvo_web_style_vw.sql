SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/*
 select collection, model, img_34, img_34_hr, prim_img From cvo_inv_master_r2_vw where collection = 'cvo' and model = 'clint'
 select  collection, model, skus, image, images_all, * from cvo_web_style_vw where collection = 'cvo' and model = 'clint'
*/

-- 1/22/15 - tag - remove some fields as per AK request
-- 1/23/15 - tag - only show front and temple images when 34 image does not exist
-- 6/16/15 - tag - only look at the img_34 fields for image files
-- 10/13/15 - tag - show sku list as only the web sellable ones
-- 10/28/15 - tag - use img_sku instead of img_34
-- 2/25/16 - TAG - ADD WEB IMAGE

CREATE VIEW [dbo].[cvo_web_style_vw] AS
	SELECT collection+'-'+model AS mastersku
	  , collection  
	  , collectionname
	  , model
	  ,	STUFF (( SELECT ';' + part_no
			 FROM cvo_inv_master_r2_vw ci
			 WHERE ci.collection = c.collection AND ci.model = c.model AND ISNULL(ci.web_saleable_flag,'') = 'Y'
			 FOR XML PATH('') ),1,1, '' ) AS skus
		, image = ISNULL((SELECT TOP 1 ISNULL(IMG_WEB,ISNULL(img_sku,CASE WHEN CHARINDEX('.jpg',img_34_hr)>0 THEN img_34_hr ELSE '' END) )
						  FROM cvo_inv_master_r2_vw cc 
						  WHERE cc.collection = c.collection AND cc.model = c.model
						  AND ISNULL(cc.web_saleable_flag,'') = 'Y'
						  AND ISNULL(cc.prim_img,0) = 1 ),'')
		, images_all = 
			STUFF ((
			SELECT DISTINCT ';' + '/'+collection+'/'+images 
			FROM 
			(
			-- 2/25/16
			SELECT DISTINCT Collection, model, ISNULL(IMG_WEB,'') IMAGES FROM dbo.cvo_inv_master_r2_vw AS cimrv
			UNION ALL
			SELECT DISTINCT collection, model, ISNULL(img_sku,'') images FROM cvo_inv_master_r2_vw
			UNION ALL
			SELECT DISTINCT collection, model, ISNULL(CASE WHEN CHARINDEX('.jpg',img_34_hr) > 0 THEN img_34_hr ELSE '' END,'') images 
			FROM cvo_inv_master_r2_vw
						--SELECT  DISTINCT collection, model, ISNULL(img_front,'') images FROM cvo_inv_master_r2_vw
			--	WHERE img_front IS NOT NULL AND img_34 IS NULL
			--UNION ALL
			--SELECT  DISTINCT collection, model, ISNULL(img_temple,'') images FROM cvo_inv_master_r2_vw
			--	WHERE img_temple IS NOT NULL AND img_34 IS NULL

			) AS T
			WHERE t.images IS NOT NULL AND t.images <> 'null' AND t.images <> ''
			AND t.collection = c.collection AND t.model = c.model
			FOR XML PATH('') ),1,1, '' )
		, res_type
		, primarydemographic
		, target_age
		--, eye_shape
		--, frame_type
		, front_material
		--, temple_material
		--, nose_pads
		--, hinge_type
		--, sun_lens_color
		--, max(sun_material) sun_material
		--, sun_lens_type
		--, specialty_Fit 
		--, case_part
		, MAX(ISNULL(wholesale_price,0)) price
		-- , sugg_retail_price msrp
		, MAX(release_date) release_date 
		, web_saleable_flag
		FROM cvo_inv_master_r2_vw c
		WHERE web_saleable_flag = 'y' AND c.part_no NOT LIKE '%F1'
		GROUP BY 
		collection
	  , collectionname
	  , model
	  	, res_type
		, primarydemographic
		, target_age
		--, eye_shape
		--, frame_type
		, front_material
		--, temple_material
		--, nose_pads
		--, hinge_type
		-- , sun_lens_color
		-- , sun_material
		-- , sun_lens_type
		-- , specialty_Fit 
		--, case_part
		--, wholesale_price
		-- , sugg_retail_price msrp
		, web_saleable_flag
		--, img_34_hr
		--, img_34
		--, img_front_hr
		--, img_front
	







GO

GRANT REFERENCES ON  [dbo].[cvo_web_style_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_web_style_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_web_style_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_web_style_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_web_style_vw] TO [public]
GO
