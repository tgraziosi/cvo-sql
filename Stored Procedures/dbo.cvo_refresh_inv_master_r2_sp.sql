SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- create table to replace cvo_inv_master_r2_vw used for apps and website

-- SELECT * FROM dbo.cvo_inv_master_r2_tbl AS imrt


CREATE PROCEDURE [dbo].[cvo_refresh_inv_master_r2_sp]
AS
BEGIN

    SET ANSI_WARNINGS OFF;
    SET NOCOUNT ON;

    IF (OBJECT_ID('tempdb.dbo.#r2') IS NOT NULL)
        DROP TABLE #r2;


    SELECT DISTINCT i.part_no,
           cia.item_code,
           i.category Collection,
           Cat.description AS CollectionName,       -- EL added 10/14/2013
           ia.field_2 model,
            --cia.img_front, 
            --cia.img_temple,
            --cia.img_34, -- 052114
            --cia.img_front_hr,
            --cia.img_temple_hr,
            --cia.img_34_hr, -- 040214
           cia.IMG_SKU,                             -- 082415
           cia.IMG_WEB,                             -- 022516
           cia.img_SpecialtyFit,
           cia.Future_ReleaseDate,
           cia.prim_img,
                                                    --'' as brandcasename, '' as tray_num, '' as slot_num,
           i.type_code AS RES_type,
           LOWER(   CASE WHEN ia.category_2 = 'unknown' THEN ''
                    WHEN ia.category_2 = 'Male-Child'
                         AND i.category IN ( 'izod', 'izx' ) THEN 'boys'
                    WHEN ia.category_2 = 'Female-Child'
                         AND i.category IN ( 'jmc' ) THEN 'girls'
                    WHEN ia.category_2 LIKE '%child%'
                         AND i.category IN ( 'op' ) THEN 'kids' ELSE ISNULL(g.description, '')
                    END
                ) AS PrimaryDemographic,
           ISNULL(age.description, '') AS target_age,
           ISNULL(x.eye_shape, ISNULL(cia.eye_shape, '')) eye_shape,
           ia.category_5 AS ColorGroupCode,
           ISNULL(cc.description, '') ColorGroupName,
           ia.field_3 AS ColorName,
           ia.field_17 AS eye_size,
           ISNULL(x.a_size, ia.field_19) AS a_size, -- get these values from cmi if available - 12/4/2015
           ISNULL(x.b_size, ia.field_20) AS b_size,
           ISNULL(x.ed_size, ia.field_21) AS ed_size,
           ia.field_6 AS dbl_size,                  -- cia.dbl_size, -- bridge size = dbl_size
           ia.field_8 AS temple_size,
                                                    -- no longer used - 11/25/2014 ia.field_9 as overall_temple_length,
           ISNULL(x.dim_unit, '') AS dim_unit,
           ISNULL(ft.description, '') AS frame_type,
           ISNULL(fm.description, '') AS front_material,
           ISNULL(tm.description, '') AS temple_material,
           ISNULL(np.description, '') AS nose_pads,
           ISNULL(th.description, '') AS hinge_type,
           ISNULL(slc.description, '') AS sun_lens_color,
           ISNULL(slm.description, '') AS sun_material,
           ISNULL(slt.description, '') AS sun_lens_type,
           ISNULL(sf.description, '') AS specialty_fit,
           ISNULL(c.description, '') AS Country_of_Origin,
           ISNULL(CAST(cp.long_descr AS VARCHAR(60)), '') AS case_part,
           ISNULL(rs.description, '') AS rimless_style,
           ROUND(pp.front_price, 2) front_price,
           ROUND(pp.temple_price, 2) temple_price,
           ROUND(pp.frame_price, 2) Wholesale_price,
           pp.last_price_upd_date,
           cia.Sugg_Retail_Price,
           ia.field_26 AS release_date,
           i.upc_code,
           i.web_saleable_flag,
           ia.field_28 pom_date,
                                                    -- add cost fields for CMI - 060614
           pp.frame_cost,
           pp.temple_cost,
           pp.cable_cost,
           pp.front_cost,
           i.vendor,
           ap.nat_cur_code,
           ap.country_code,
           gc.description country_name,
           ISNULL(ia.field_5, 'N') ispolarizedavailable,
                                                    --, isnull((select top 1 f.feature_desc from cvo_inv_features_vw f where 
                                                    --	((f.collection = i.category and f.model = ia.field_2) or (f.part_no = i.part_no))
                                                    --	and f.feature_group = 'Progressive Friendly' ),'') as progressive_type
           ISNULL(pf.feature_desc, '') AS progressive_type,
                                                    -- add case info and frame weight for website
           ISNULL(i.weight_ea, 0) frame_weight,
           ISNULL(cpi.part_no, '') AS case_part_no,
           ISNULL(cpi.weight_ea, 0) AS case_weight,
           LOWER(   CASE WHEN ia.category_2 = 'unknown' THEN ''
                    WHEN ia.category_2 = 'Male-Child'
                         AND i.category IN ( 'izod', 'izx', 'op' ) THEN 'boys'
                    WHEN ia.category_2 = 'Female-Child'
                         AND i.category IN ( 'jmc', 'op' ) THEN 'girls'
                    WHEN ia.category_2 LIKE '%child%' THEN 'kids' ELSE ISNULL(g.description, '')
                    END
                ) AS PrimaryDemo_Web,
           ISNULL(pa.attribute, '') attributes,     -- 1/8/2018 - multiple attributes
           ISNULL(x.special_components, '') AS special_components,
           ISNULL(x.suns_only, '') suns_only,
           ISNULL(x.lens_base, '') lens_base
    INTO #r2
    FROM inv_master i
        (NOLOCK)
        INNER JOIN inv_master_add ia
        (NOLOCK)
            ON i.part_no = ia.part_no
        LEFT OUTER JOIN cvo_inv_master_add cia
        (NOLOCK)
            ON i.part_no = cia.part_no
        INNER JOIN category Cat
        (NOLOCK)
            ON Cat.kys = i.category
        -- left outer join dbo.f_get_price_for_styles() pp on pp.part_no = i.part_no 
        LEFT OUTER JOIN apmaster ap
        (NOLOCK)
            ON ap.vendor_code = i.vendor
        LEFT OUTER JOIN gl_country gc
        (NOLOCK)
            ON gc.country_code = ap.country_code
        LEFT OUTER JOIN cvo_part_price_cost_vw
        (NOLOCK) pp
            ON pp.part_no = i.part_no
        LEFT OUTER JOIN CVO_age age
        (NOLOCK)
            ON age.kys = ia.category_4
        LEFT OUTER JOIN CVO_Gender g
        (NOLOCK)
            ON g.kys = ia.category_2
        LEFT OUTER JOIN CVO_Color_Code cc
        (NOLOCK)
            ON cc.kys = ia.category_5
        LEFT OUTER JOIN CVO_frame_type
        (NOLOCK) ft
            ON ft.kys = ia.field_11
        LEFT OUTER JOIN CVO_frame_matl
        (NOLOCK) fm
            ON fm.kys = ia.field_10
        LEFT OUTER JOIN CVO_temple_matl
        (NOLOCK) tm
            ON tm.kys = ia.field_12
        LEFT OUTER JOIN CVO_nose_pad
        (NOLOCK) np
            ON np.kys = ia.field_7
        LEFT OUTER JOIN CVO_temple_hindge
        (NOLOCK) th
            ON th.kys = ia.field_13
        LEFT OUTER JOIN cvo_sun_lens_color
        (NOLOCK) slc
            ON slc.kys = ia.field_23
        LEFT OUTER JOIN CVO_sun_lens_material
        (NOLOCK) slm
            ON slm.kys = ia.field_24
        LEFT OUTER JOIN CVO_sun_lens_type
        (NOLOCK) slt
            ON slt.kys = ia.field_25
        LEFT OUTER JOIN cvo_specialty_fit
        (NOLOCK) sf
            ON sf.kys = -- 5/30/18 - per AK request for website
            ISNULL(
            (
            SELECT TOP 1
                   attribute
            FROM cvo_part_attributes xx
            WHERE xx.part_no = ia.part_no
                  AND xx.attribute IN ( 'Global Fit', 'Petite', 'Style N', 'XL', 'Pediatric' )
            ORDER BY xx.attribute
            ),
            ''
                  ) -- ia.field_32
        LEFT OUTER JOIN gl_country
        (NOLOCK) c
            ON c.country_code = i.country_code
        LEFT OUTER JOIN inv_master_add cp
        (NOLOCK)
            ON cp.part_no = ia.field_1
        -- add cases for website
        LEFT OUTER JOIN inv_master cpi
        (NOLOCK)
            ON cpi.part_no = ia.field_1
        LEFT OUTER JOIN CVO_frame_type rs
        (NOLOCK)
            ON rs.kys = ia.field_11
        LEFT OUTER JOIN cvo_inv_features_vw pf
            ON (
               (
               pf.collection = i.category
               AND pf.model = ia.field_2
               )
               OR (pf.part_no = i.part_no)
               )
               AND pf.feature_group = 'Progressive Friendly'
        -- 12/4/2015 get a,b,ed from cmi if available
        LEFT OUTER JOIN
        (
        SELECT part_no,
               a_size,
               b_size,
               ed_size,
               d.dim_unit,
               m.eye_shape,
               m.suns_only,
               m.lens_base,
               -- 3/8/2018 - for AK
               ISNULL(m.component_1, '')
               + CASE WHEN ISNULL(m.component_2, '') = '' THEN '' ELSE '|' + m.component_2 END
               + CASE WHEN ISNULL(m.component_3, '') = '' THEN '' ELSE '|' + m.component_3 END
               + CASE WHEN ISNULL(m.component_4, '') = '' THEN '' ELSE '|' + m.component_4 END
               + CASE WHEN ISNULL(m.component_5, '') = '' THEN '' ELSE '|' + m.component_5 END
               + CASE WHEN ISNULL(m.component_6, '') = '' THEN '' ELSE '|' + m.component_6 END AS special_components
        FROM dbo.cvo_cmi_sku_xref xref
            JOIN dbo.cvo_cmi_dimensions d
                ON xref.dim_id = d.id
            JOIN dbo.cvo_cmi_models m
                ON m.id = d.model_id
        ) AS x
            ON x.part_no = i.part_no
        LEFT OUTER JOIN
        (
        SELECT c.part_no,
               STUFF(
               (
               SELECT '; ' + attribute
               FROM dbo.cvo_part_attributes pa2
                   (NOLOCK)
               WHERE pa2.part_no = c.part_no
               FOR XML PATH('')
               ),
               1,
               1,
               ''
                    ) attribute
        FROM dbo.cvo_part_attributes c
        ) AS pa
            ON pa.part_no = i.part_no
    WHERE i.void = 'n'
          AND i.type_code IN ( 'frame', 'sun' );


    INSERT INTO dbo.cvo_inv_master_r2_tbl
    SELECT DISTINCT r2.part_no,
           r2.item_code,
           r2.Collection,
           r2.CollectionName,
           r2.model,
           r2.IMG_SKU,
           r2.IMG_WEB,
           r2.img_SpecialtyFit,
           r2.Future_ReleaseDate,
           r2.prim_img,
           r2.RES_type,
           r2.PrimaryDemographic,
           r2.target_age,
           r2.eye_shape,
           r2.ColorGroupCode,
           r2.ColorGroupName,
           r2.ColorName,
           r2.eye_size,
           r2.a_size,
           r2.b_size,
           r2.ed_size,
           r2.dbl_size,
           r2.temple_size,
           r2.dim_unit,
           r2.frame_type,
           r2.front_material,
           r2.temple_material,
           r2.nose_pads,
           r2.hinge_type,
           r2.sun_lens_color,
           r2.sun_material,
           r2.sun_lens_type,
           r2.specialty_fit,
           r2.Country_of_Origin,
           r2.case_part,
           r2.rimless_style,
           r2.front_price,
           r2.temple_price,
           r2.Wholesale_price,
           r2.last_price_upd_date,
           r2.Sugg_Retail_Price,
           r2.release_date,
           r2.upc_code,
           r2.web_saleable_flag,
           r2.pom_date,
           r2.frame_cost,
           r2.temple_cost,
           r2.cable_cost,
           r2.front_cost,
           r2.vendor,
           r2.nat_cur_code,
           r2.country_code,
           r2.country_name,
           r2.ispolarizedavailable,
           r2.progressive_type,
           r2.frame_weight,
           r2.case_part_no,
           r2.case_weight,
           r2.PrimaryDemo_Web,
           r2.attributes,
           r2.special_components,
           r2.suns_only,
           r2.lens_base
    FROM #r2 r2
    WHERE NOT EXISTS
    (
    SELECT 1 FROM DBO.cvo_inv_master_r2_tbl t WHERE t.part_no = r2.part_no
    );


    UPDATE dst
    SET dst.item_code = src.item_code,
        dst.Collection = src.Collection,
        dst.CollectionName = src.CollectionName,
        dst.model = src.model,
        dst.IMG_SKU = src.IMG_SKU,
        dst.IMG_WEB = src.IMG_WEB,
        dst.img_SpecialtyFit = src.img_SpecialtyFit,
        dst.Future_ReleaseDate = src.Future_ReleaseDate,
        dst.prim_img = src.prim_img,
        dst.RES_type = src.RES_type,
        dst.PrimaryDemographic = src.PrimaryDemographic,
        dst.target_age = src.target_age,
		dst.eye_shape = src.eye_shape,
		dst.ColorGroupCode = src.ColorGroupCode,
		dst.ColorGroupName = src.ColorGroupName,
		dst.colorname = src.colorname,
		dst.eye_size = src.eye_size,
		dst.a_size = src.a_size,
		dst.b_size = src.b_size,
		dst.ed_size = src.ed_size,
		dst.dbl_size = src.dbl_size,
		dst.temple_size = src.temple_size,
		dst.dim_unit = src.dim_unit,
		dst.frame_type = src.frame_type,
		dst.front_material = src.front_material,
		dst.temple_material = src.temple_material,
		   dst.nose_pads = src.nose_pads,
           dst.hinge_type = src.hinge_type,
           dst.sun_lens_color = src.sun_lens_color,
           dst.sun_material = src.sun_material,
           dst.sun_lens_type = src.sun_lens_type,
           dst.specialty_fit = src.specialty_fit,
           dst.Country_of_Origin = src.Country_of_Origin,
           dst.case_part = src.case_part,
           dst.rimless_style = src.rimless_style,
           dst.front_price = src.front_price,
           dst.temple_price = src.temple_price,
           dst.Wholesale_price = src.Wholesale_price,
           dst.last_price_upd_date = src.last_price_upd_date,
           dst.Sugg_Retail_Price = src.Sugg_Retail_Price,
           dst.release_date = src.release_date,
           dst.upc_code = src.upc_code,
           dst.web_saleable_flag = src.web_saleable_flag,
           dst.pom_date = src.pom_date,
           dst.frame_cost = src.frame_cost,
           dst.temple_cost = src.temple_cost,
           dst.cable_cost = src.cable_cost,
           dst.front_cost = src.front_cost,
           dst.vendor = src.vendor,
           dst.nat_cur_code = src.nat_cur_code,
           dst.country_code = src.country_code,
           dst.country_name = src.country_name,
           dst.ispolarizedavailable = src.ispolarizedavailable,
           dst.progressive_type = src.progressive_type,
           dst.frame_weight = src.frame_weight,
           dst.case_part_no = src.case_part_no,
           dst.case_weight = src.case_weight,
           dst.PrimaryDemo_Web = src.PrimaryDemo_Web,
           dst.attributes = src.attributes,
           dst.special_components = src.special_components,
           dst.suns_only = src.suns_only,
           dst.lens_base = src.lens_base

    FROM dbo.cvo_inv_master_r2_tbl AS dst
        JOIN #r2 src
            ON src.part_no = dst.part_no
	WHERE
	    dst.item_code <> src.item_code OR 
        dst.Collection <> src.Collection OR 
        dst.CollectionName <> src.CollectionName OR 
        dst.model <> src.model OR 
        dst.IMG_SKU <> src.IMG_SKU OR 
        dst.IMG_WEB <> src.IMG_WEB OR 
        dst.img_SpecialtyFit <> src.img_SpecialtyFit OR 
        dst.Future_ReleaseDate <> src.Future_ReleaseDate OR 
        dst.prim_img <> src.prim_img OR 
        dst.RES_type <> src.RES_type OR 
        dst.PrimaryDemographic <> src.PrimaryDemographic OR 
        dst.target_age <> src.target_age OR 
		dst.eye_shape <> src.eye_shape OR 
		dst.ColorGroupCode <> src.ColorGroupCode OR 
		dst.ColorGroupName <> src.ColorGroupName OR 
		dst.colorname <> src.colorname OR 
		dst.eye_size <> src.eye_size OR 
		dst.a_size <> src.a_size OR 
		dst.b_size <> src.b_size OR 
		dst.ed_size <> src.ed_size OR 
		dst.dbl_size <> src.dbl_size OR 
		dst.temple_size <> src.temple_size OR 
		dst.dim_unit <> src.dim_unit OR 
		dst.frame_type <> src.frame_type OR 
		dst.front_material <> src.front_material OR 
		dst.temple_material <> src.temple_material OR 
		   dst.nose_pads <> src.nose_pads OR 
           dst.hinge_type <> src.hinge_type OR 
           dst.sun_lens_color <> src.sun_lens_color OR 
           dst.sun_material <> src.sun_material OR 
           dst.sun_lens_type <> src.sun_lens_type OR 
           dst.specialty_fit <> src.specialty_fit OR 
           dst.Country_of_Origin <> src.Country_of_Origin OR 
           dst.case_part <> src.case_part OR 
           dst.rimless_style <> src.rimless_style OR 
           dst.front_price <> src.front_price OR 
           dst.temple_price <> src.temple_price OR 
           dst.Wholesale_price <> src.Wholesale_price OR 
           dst.last_price_upd_date <> src.last_price_upd_date OR 
           dst.Sugg_Retail_Price <> src.Sugg_Retail_Price OR 
           dst.release_date <> src.release_date OR 
           dst.upc_code <> src.upc_code OR 
           dst.web_saleable_flag <> src.web_saleable_flag OR 
           dst.pom_date <> src.pom_date OR 
           dst.frame_cost <> src.frame_cost OR 
           dst.temple_cost <> src.temple_cost OR 
           dst.cable_cost <> src.cable_cost OR 
           dst.front_cost <> src.front_cost OR 
           dst.vendor <> src.vendor OR 
           dst.nat_cur_code <> src.nat_cur_code OR 
           dst.country_code <> src.country_code OR 
           dst.country_name <> src.country_name OR 
           dst.ispolarizedavailable <> src.ispolarizedavailable OR 
           dst.progressive_type <> src.progressive_type OR 
           dst.frame_weight <> src.frame_weight OR 
           dst.case_part_no <> src.case_part_no OR 
           dst.case_weight <> src.case_weight OR 
           dst.PrimaryDemo_Web <> src.PrimaryDemo_Web OR 
           dst.attributes <> src.attributes OR 
           dst.special_components <> src.special_components OR 
           dst.suns_only <> src.suns_only OR 
           dst.lens_base <> src.lens_base
	;

END;

GRANT EXECUTE ON cvo_refresh_inv_master_r2_sp TO PUBLIC

GO
GRANT EXECUTE ON  [dbo].[cvo_refresh_inv_master_r2_sp] TO [public]
GO
