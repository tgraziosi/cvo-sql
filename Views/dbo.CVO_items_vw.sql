SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO

CREATE VIEW [dbo].[CVO_items_vw]
AS
-- SELECT attribute,* FROM cvo_items_vw WHERE part_no LIKE 'cv3024%'
SELECT ISNULL(i.vendor, '') vendor,
       ISNULL(i.category, '') AS brand,
       ISNULL(i.type_code, '') AS type,
       ISNULL(ia.category_3, '') AS part_type,
       ISNULL(ia.field_2, '') AS style,
       ISNULL(i.part_no, '') part_no,
       SUBSTRING(ISNULL(i.description, ''), 1, 60) description,
       ISNULL(ia.category_5, '') AS color_code,
       ISNULL(ia.field_3, '') AS color,
       CONVERT(INT, ISNULL(ia.field_17, 0)) AS eye_size,
       ISNULL(ia.field_6, '') AS bridge_size,
       ISNULL(ia.field_8, '') AS temple_size,
       ISNULL(i.weight_ea, 0.0) AS weight,         -- 11/10 - TAG - add. fields for TB
       ISNULL(ia.field_1, '') AS case_part,
       ISNULL(ia.field_4, '') AS pattern,          -- 11/10 - TAG - add. fields for TB
       ISNULL(ia.field_26, '') AS release_date,    -- 11/10 - TAG - add. fields for TB
       ia.field_28 AS pom_date,                    -- 4/1 - EL - add. fields 
       ISNULL(p.price_a, 0) AS base_price,
                                                   --IsNull(v.last_price,0) as cost,
       ISNULL(l.std_cost, 0) AS cost,              -- tag - 12/9/2013
       ISNULL(l.std_ovhd_dolrs, 0) AS xfer_cost,
       ISNULL(l.std_util_dolrs, 0) AS freight_cost,
       ISNULL(l.lead_time, 0) AS lead_time,        -- 11/10 - TAG - add. fields for TB
       ISNULL(u.UPC, '') AS upc_code,
       void = CASE i.void
                  WHEN 'N' THEN
                      'No'
                  WHEN 'V' THEN
                      'Yes' -- 11/15 - tag - added for TB
                  ELSE
                      'N'
              END,
       ISNULL(ia.category_2, '') AS demographic,
       ISNULL(ia.category_4, '') AS target_age,    -- 032714
       ISNULL(i.cmdty_code, '') AS material,
       ISNULL(CN.description, '') AS CntryOfOrgin, -- 041514 EL	
                                                   -- ISNULL(ia.field_32,'') attribute -- 9/21/15 per TB request
       CAST(LTRIM(RTRIM(ISNULL(pa.attribute, ''))) AS VARCHAR(256)) attribute,         -- 1/5/18 - multiple attributes
       x.a_size,
       x.b_size,
       x.ed_size,
       x.hinge_type,
       x.frame_category

FROM inv_master i
    LEFT OUTER JOIN inv_master_add ia
        ON i.part_no = ia.part_no
    LEFT OUTER JOIN uom_id_code u
        ON i.part_no = u.part_no
    LEFT OUTER JOIN part_price p
        ON i.part_no = p.part_no
           AND p.curr_key = 'USD'
    LEFT OUTER JOIN vendor_sku v
        ON i.part_no = v.sku_no
           AND i.vendor = v.vendor_no
           AND v.curr_key = 'USD'
           AND v.last_recv_date > GETDATE()
    LEFT OUTER JOIN inv_list l
        ON i.part_no = l.part_no
           AND l.location = '001'
    LEFT OUTER JOIN gl_country CN (NOLOCK)
        ON i.country_code = CN.country_code
    -- 12/4/2015 get a,b,ed from cmi if available
    LEFT OUTER JOIN
    (
        SELECT part_no,
               a_size,
               b_size,
               ed_size,
               d.dim_unit,
               m.eye_shape,
               m.hinge_type,
               m.frame_category
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
                   FROM dbo.cvo_part_attributes pa2 (NOLOCK)
                   WHERE pa2.part_no = c.part_no
                   FOR XML PATH('')
               ),
               1,
               1,
               ''
                    ) attribute
        FROM dbo.cvo_part_attributes c
    ) AS pa
        ON pa.part_no = i.part_no;

--WHERE ia.field_2 = 't 5607'
GO
GRANT REFERENCES ON  [dbo].[CVO_items_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_items_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_items_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_items_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_items_vw] TO [public]
GO
