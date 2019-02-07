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
FROM    inv_master i (NOLOCK)
JOIN dbo.f_get_price_for_styles() s ON s.part_no = i.part_no
JOIN inv_master_add ia ON ia.part_no = s.part_no
WHERE i.void = 'n';

CREATE INDEX idx_s_part ON #s (part_no ASC, colorname ASC, collection ASC, style ASC, frame_cost asc);

INSERT INTO #s 
SELECT i.category, ia.field_2, pp.part_no, pp.price_a,
  0.0 , -- temple_price - float
         0.0 , -- front_price - float
         il.std_cost , -- frame_cost - float
         0.0 , -- temple_cost - float 
         0.0 , -- cable_cost - float
         0.0 , -- front_cost - float
         ia.field_3    -- ColorName - varchar(40)
FROM inv_master i 
JOIN dbo.part_price AS pp ON pp.part_no = i.part_no
JOIN inv_master_add ia ON ia.part_no = i.part_no
JOIN inv_list il ON il.part_no = pp.part_no AND il.location = '001'
LEFT OUTER JOIN #s ON #s.part_no = pp.part_no
WHERE #s.part_no IS NULL AND i.type_code IN ('frame','sun')
AND i.void = 'n';

SELECT  DISTINCT 
		ccv.Collection ,
        ccv.RES_type ,
        ccv.model ,
        ccv.PrimaryDemographic ,
		-- CASE WHEN ccv.specialty_fit = 'Regular Fit' THEN '' ELSE ccv.specialty_fit END AS specialty_fit,
        cmi.specialty_fit,
		ISNULL(ccv.special_program,'') special_program,
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
        CASE WHEN cmi.pom_date IN ('1/1/1900','12/31/2999') THEN NULL ELSE cmi.pom_date END pom_date ,
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
                        MAX(ISNULL(pom_date, '12/31/2999')) pom_date,
                        MAX(imrv.specialty_fit) specialty_fit
               FROM     dbo.cvo_inv_master_r2_vw AS imrv
               GROUP BY Collection , model
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
