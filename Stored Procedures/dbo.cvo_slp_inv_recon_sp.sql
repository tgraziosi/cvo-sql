SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_slp_inv_recon_sp] @slp VARCHAR(12)
AS
BEGIN

    SET NOCOUNT ON;

    -- exec cvo_slp_inv_recon_sp 'stromst'
    -- exec cvo_slp_inv_recon_sp '20206'

    DECLARE @location VARCHAR(12),
            @today DATETIME;
    SELECT @location = '',
           @today = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0);

    SELECT @location = location
    FROM cvo_sc_addr_vw
    WHERE territory_code = @slp
          OR salesperson_code = @slp
    -- SELECT @location

    ;
    WITH slp -- all inventory in slp location
    AS
    (
    SELECT 'SLPINV' AS INV_TYPE,
           i.part_no,
           i.category BRAND,
           ia.field_2 MODEL
    FROM lot_bin_stock LB
        (NOLOCK)
        JOIN inv_master i
        (NOLOCK)
            ON i.part_no = LB.part_no
        JOIN inv_master_add ia
        (NOLOCK)
            ON ia.part_no = i.part_no
    WHERE i.void = 'n'
          AND i.type_code IN ( 'frame', 'sun' )
          AND location = @location
    ),
         inv -- current inventory items, and any items in slp location regardless of status
    AS
    (
    SELECT CASE WHEN ISNULL(ia.field_28, @today) < @today THEN 'POM' WHEN ia.field_26 < @today THEN 'CURRENT' ELSE
                                                                                                                  'NEW' END AS INV_TYPE,
           i.part_no,
           i.category BRAND,
           ia.field_2 MODEL
    FROM inv_master i
        (NOLOCK)
        JOIN inv_master_add ia
        (NOLOCK)
            ON ia.part_no = i.part_no
    WHERE (
          i.void = 'n'
          AND 'F1' <> RIGHT(i.part_no, 2)
          AND i.type_code IN ( 'frame', 'sun' )
          AND NOT EXISTS
    (
    SELECT 1
    FROM dbo.cvo_part_attributes AS pa
        (NOLOCK)
    WHERE pa.part_no = i.part_no
          AND pa.attribute IN ( 'retail', 'hvc', 'specialord', 'costco' )
    )
          AND ISNULL(field_28, @today) >= @today
          )
          OR EXISTS
    (
    SELECT 1 FROM slp WHERE slp.part_no = i.part_no
    )
    ),
         partslist -- put it all together and tag different things to report (current, new, pom, need, return)
    AS
    (
    SELECT INV.INV_TYPE,
           INV.part_no,
           INV.BRAND,
           INV.MODEL
    FROM inv INV
    WHERE INV_TYPE IN ( 'CURRENT', 'NEW' )
          OR EXISTS
    (
    SELECT 1 FROM slp WHERE slp.part_no = inv.part_no
    )
    UNION ALL
    SELECT SLP.INV_TYPE,
           SLP.part_no,
           SLP.BRAND,
           SLP.MODEL
    FROM slp SLP
    UNION ALL
    SELECT 'NEED' INV_TYPE,
           part_no,
           BRAND,
           inv.MODEL
    FROM inv
    WHERE inv.INV_TYPE <> 'POM'
          AND NOT EXISTS
    (
    SELECT 1 FROM slp WHERE slp.BRAND = inv.BRAND AND slp.MODEL = inv.MODEL
    )
    UNION ALL
    SELECT 'RETURN' INV_TYPE,
           part_no,
           BRAND,
           MODEL
    FROM inv
    WHERE inv.INV_TYPE = 'POM'
          AND EXISTS
    (
    SELECT 1 FROM slp WHERE slp.part_no = inv.part_no
    )
    )
    SELECT DISTINCT -- Final list to output

           @location LOCATION,
           STUFF(
           (
           SELECT DISTINCT
                  ',' + INV_TYPE
           FROM partslist ci
           WHERE ci.part_no = s.part_no
           FOR XML PATH('')
           ),
           1,
           1,
           ''
                ) AS inv_types,
           i.release_date,
           i.pom_date,
           s.part_no,
           cia.qty_avl,
           i.Collection,
           i.CollectionName,
           i.model,
           'http://s3.amazonaws.com/cvo-brand-img/' + i.Collection + '/' + i.IMG_WEB AS IMG_WEB,
           i.prim_img,
           i.RES_type,
           i.PrimaryDemographic,
           i.target_age,
           i.eye_shape,
           i.ColorGroupCode,
           i.ColorGroupName,
           i.ColorName,
           i.eye_size,
           i.a_size,
           i.b_size,
           i.ed_size,
           i.dbl_size,
           i.temple_size,
           i.frame_type,
           i.front_material,
           i.temple_material,
           i.nose_pads,
           i.hinge_type,
           i.sun_lens_color,
           i.sun_material,
           i.sun_lens_type,
           i.specialty_fit,
           i.Country_of_Origin,
           i.case_part,
           i.rimless_style,
           i.front_price,
           i.temple_price,
           i.Wholesale_price,
           i.sugg_retail_price,
           i.upc_code,
           i.web_saleable_flag,
           i.ispolarizedavailable,
           i.progressive_type,
           i.frame_weight,
           i.case_part_no,
           i.case_weight,
           i.PrimaryDemo_Web,
           i.attributes,
           i.special_components,
           i.suns_only,
           i.lens_base
    FROM partslist s
        (NOLOCK)
        JOIN cvo_inv_master_r2_vw i
        (NOLOCK)
            ON i.part_no = s.part_no
        JOIN cvo_item_avail_vw cia
        (NOLOCK)
            ON cia.part_no = s.part_no
               AND cia.location = '001';

END;

GRANT EXECUTE ON dbo.cvo_slp_inv_recon_sp TO PUBLIC;


GO
GRANT EXECUTE ON  [dbo].[cvo_slp_inv_recon_sp] TO [public]
GO
