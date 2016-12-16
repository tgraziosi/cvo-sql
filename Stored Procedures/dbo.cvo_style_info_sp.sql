SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_style_info_sp] AS

BEGIN

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

IF ( OBJECT_ID('tempdb.dbo.#s') IS NOT NULL )
    DROP TABLE dbo.#s;

SELECT  s.collection ,
        s.style ,
        s.part_no ,
        s.frame_price ,
        s.temple_price ,
        s.front_price ,
        s.frame_cost ,
        s.temple_cost ,
        s.cable_cost ,
        s.front_cost,
		ia.field_3 ColorName
INTO    #s
FROM    dbo.f_get_price_for_styles() s
JOIN inv_master_add ia ON ia.part_no = s.part_no;

CREATE INDEX idx_s_part ON #s (part_no ASC, colorname ASC, collection ASC, style ASC, frame_cost asc);

SELECT  DISTINCT 
		ccv.Collection ,
        ccv.RES_type ,
        ccv.model ,
        ccv.PrimaryDemographic ,
		CASE WHEN ccv.specialty_fit = 'Regular Fit' THEN '' ELSE ccv.specialty_fit END AS specialty_fit,
		ccv.special_program,
		ccv.supplier ,
        ccv.country_origin ,
        ccv.frame_category ,
        ccv.front_material ,
        ccv.temple_material ,
        CASE WHEN ccv.hinge_type <> 'spring hinges' THEN 'N'
             ELSE 'Y'
        END Spring_hinge ,
        ISNULL(ccv.print_flag, '') print_flag ,
        cmi.release_date ,
        cmi.pom_date ,
        s.front_price ,
        s.temple_price ,
        s.frame_price wholesale_price ,
        s.frame_cost ,
		CASE WHEN ISNULL(s.frame_cost,0) = 0 THEN 0 ELSE ISNULL(s.frame_price,0)/ISNULL(s.frame_cost,0) END AS Margin,
		STUFF(( SELECT DISTINCT ', ' + ss.colorname
                                FROM    #s ss (NOLOCK)
                                WHERE   ss.collection = ccv.Collection AND ss.style = ccv.model AND ss.frame_cost = s.frame_cost
	                            FOR
                                XML PATH('')
                                ), 1, 1, '') Colors
        --ISNULL(ccv.lens_color, '') lens_color ,
        --ccv.sku
FROM    dbo.cvo_cmi_catalog_view AS ccv
        JOIN #s s ON s.part_no = ccv.sku
        JOIN ( SELECT   Collection ,
                        model ,
                        MIN(release_date) release_date ,
                        MAX(ISNULL(pom_date, '12/31/2999')) pom_date
               FROM     dbo.cvo_cmi_catalog_view
               GROUP BY Collection ,
                        model
             ) cmi ON cmi.Collection = ccv.Collection
                      AND cmi.model = ccv.model
ORDER BY ccv.Collection ,
        ccv.RES_type ,
        ccv.model 
		;

end
GO
GRANT EXECUTE ON  [dbo].[cvo_style_info_sp] TO [public]
GO
