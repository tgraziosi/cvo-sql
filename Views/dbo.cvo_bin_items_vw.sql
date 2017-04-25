SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_bin_items_vw]
AS
SELECT
    iv.vendor,
    iv.brand,
    iv.type,
    iv.part_type,
    iv.style,
    iv.part_no,
    iv.description,
    iv.color_code,
    iv.color,
    iv.eye_size,
    iv.bridge_size,
    iv.temple_size,
    iv.weight,
    iv.case_part,
    iv.pattern,
    iv.release_date,
    iv.pom_date,
    iv.base_price,
    iv.cost,
    iv.xfer_cost,
    iv.freight_cost,
    iv.lead_time,
    iv.upc_code,
    iv.void,
    iv.demographic,
    iv.target_age,
    iv.material,
    iv.CntryOfOrgin,
    iv.attribute,
    biv.usage_type_code,
    biv.group_code,
    biv.location,
    biv.bin_no,
    --biv.part_no ,
    --biv.upc_code ,
    --biv.description ,
    --biv.type_code ,
    biv.lot_ser,
    biv.qty,
    biv.date_tran,
    biv.date_expires,
    biv.std_cost,
    biv.std_ovhd_dolrs,
    biv.std_util_dolrs,
    biv.ext_cost,
    biv.Is_Assigned,
    biv.primary_bin,
    biv.maximum_level,
    biv.last_modified_date,
    biv.modified_by
FROM
    dbo.CVO_items_vw AS iv
    LEFT OUTER JOIN dbo.cvo_bin_inquiry_vw AS biv
        ON iv.part_no = biv.part_no
;
GO
GRANT SELECT ON  [dbo].[cvo_bin_items_vw] TO [public]
GO
