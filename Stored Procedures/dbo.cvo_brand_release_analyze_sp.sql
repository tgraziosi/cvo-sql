SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_brand_release_analyze_sp]
(
    @coll VARCHAR(1024) = NULL,
    @gender VARCHAR(512) = NULL,
    @rel_start DATETIME = NULL,
    @rel_end DATETIME = NULL,
    @wk1 INT = NULL,
    @wk2 INT = NULL
)

AS
BEGIN

    -- exec cvo_brand_release_analyze_sp @coll = 'as', @gender = null, @rel_start = null, @rel_end = null, @wk1 = 4, @wk2 = null

    SET NOCOUNT ON;

    DECLARE @coll_tbl TABLE
    (
        coll VARCHAR(20)
    );

    IF @coll IS NULL
    BEGIN
        INSERT INTO @coll_tbl
        SELECT DISTINCT
               kys
        FROM category
        WHERE void = 'n';
    END;
    ELSE
    BEGIN
        INSERT INTO @coll_tbl
        (
            coll
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@coll);
    END;


    DECLARE @gender_tbl TABLE
    (
        gender VARCHAR(20)
    );

    IF @gender IS NULL
    BEGIN
        INSERT INTO @gender_tbl
        SELECT DISTINCT
               kys
        FROM CVO_Gender
        WHERE void = 'n';
    END;
    ELSE
    BEGIN
        INSERT INTO @gender_tbl
        (
            gender
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@gender);
    END;

    IF @wk1 IS NULL
        SET @wk1 = 4;

    IF @wk2 IS NULL
        SET @wk2 = 6;

    IF @rel_start IS NULL
        SET @rel_start = DATEADD(YEAR, -4, GETDATE());

    IF @rel_end IS NULL
        SET @rel_end = GETDATE()

        ;

    WITH cte
    AS (SELECT i.category brand,
               ia.field_2 MODEL,
               MIN(ia.field_26) rel_date,
               MAX(ISNULL(ia.field_28, '12/31/2999')) pom_date,
               i.type_code,
               MIN(sbm.yyyymmdd) first_brand_sale,
               AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END AS customer,
               CASE WHEN DATEDIFF(WEEK, ia.field_26, sbm.yyyymmdd) <= @wk1 THEN
                        AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END ELSE ''
               END AS customerwk1,
               CASE WHEN DATEDIFF(WEEK, ia.field_26, sbm.yyyymmdd) <= @wk2 THEN
                        AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END ELSE ''
               END AS customerwk2,
               SUM(sbm.qnet) net_qty,
               SUM(CASE WHEN sbm.user_category NOT LIKE 'rx%' THEN sbm.qsales ELSE 0 END) st_qty,
               SUM(CASE WHEN sbm.user_category LIKE 'rx%' THEN sbm.qsales ELSE 0 END) rx_qty,
               SUM(CASE WHEN sbm.return_code <> 'exc' THEN sbm.qreturns ELSE 0 END) return_qty,
               SUM(sbm.qsales) sales_qty,
               SUM(CASE WHEN sbm.promo_id <> '' AND DATEDIFF(MONTH, ia.field_26, sbm.yyyymmdd) <= 3 THEN sbm.qsales ELSE
                                                                                                                        0 END
                  ) qty_on_promo_m1_3

        FROM @coll_tbl c
            JOIN dbo.inv_master i (NOLOCK)
                ON i.category = c.coll AND i.type_code IN ('frame','sun')
            JOIN dbo.inv_master_add ia (NOLOCK)
                ON ia.part_no = i.part_no
            JOIN @gender_tbl g
                ON g.gender = ia.category_2
            JOIN dbo.cvo_sbm_details sbm (NOLOCK)
                ON sbm.part_no = ia.part_no
            JOIN dbo.CVO_armaster_all AS car (NOLOCK)
                ON car.customer_code = sbm.customer
				AND car.ship_to = sbm.ship_to
            JOIN dbo.armaster AR (NOLOCK)
                ON AR.customer_code = car.customer_code
                   AND AR.ship_to_code = car.ship_to
        WHERE ia.field_26
              BETWEEN @rel_start AND @rel_end
              AND sbm.yyyymmdd >= @rel_start
              AND NOT EXISTS (
                             SELECT 1
                             FROM dbo.cvo_part_attributes AS pa (NOLOCK)
                             WHERE pa.part_no = i.part_no
                                   AND attribute IN ( 'hvc', 'retail', 'specialord' )
                             )
        GROUP BY AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END,
                 CASE WHEN DATEDIFF(WEEK, ia.field_26, sbm.yyyymmdd) <= @wk1 THEN
                          AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END ELSE ''
                 END,
                 CASE WHEN DATEDIFF(WEEK, ia.field_26, sbm.yyyymmdd) <= @wk2 THEN
                          AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END ELSE ''
                 END,
                 i.category,
                 ia.field_2,
                 i.type_code),
         rel
    AS (SELECT DISTINCT
               i.category brand,
               ia.field_2 model,
               COUNT(DISTINCT ia.field_26) rel_cnt,
               MAX(ISNULL(ccv.eye_shape, '')) eye_shape,
               MAX(ISNULL(ccv.front_material, ISNULL(ia.field_10, ''))) Material,
               MAX(ISNULL(ccv.PrimaryDemographic, ISNULL(ia.category_2, ''))) PrimaryDemographic,
               MAX(ISNULL(ccv.frame_category, ISNULL(ia.field_11, ''))) Frame_type
        FROM @coll_tbl c
            JOIN dbo.inv_master i (NOLOCK)
                ON i.category = c.coll AND i.type_code IN ('frame','sun')
            JOIN dbo.inv_master_add ia (NOLOCK)
                ON ia.part_no = i.part_no
            JOIN @gender_tbl g
                ON g.gender = ia.category_2
            LEFT OUTER JOIN dbo.cvo_cmi_catalog_view AS ccv (NOLOCK)
                ON ccv.upc_code = i.upc_code
        WHERE ISNULL(i.void, 'N') = 'N'
              AND ia.field_26
              BETWEEN @rel_start AND @rel_end
        GROUP BY
            i.category,
            ia.field_2)

    --SELECT DISTINCT field_26, part_no FROM inv_master_add WHERE field_2 = 'free'

    SELECT CONVERT(DATETIME, MIN(cte.rel_date), 110) rel_date,
           CONVERT(DATETIME, MAX(cte.pom_date), 110) pom_date,
           cte.brand,
           cte.MODEL,
           cte.type_code,
           rel.rel_cnt num_releases,
           COUNT(DISTINCT cte.customer) num_cust,
           COUNT(DISTINCT cte.customerwk1) num_cust_wk1,
           COUNT(DISTINCT cte.customerwk2) num_cust_wk2,
           SUM(cte.net_qty) net_qty,
           SUM(cte.st_qty) st_qty,
           SUM(cte.rx_qty) rx_qty,
           SUM(cte.return_qty) return_qty,
           SUM(cte.sales_qty) sales_qty,
           CASE WHEN SUM(cte.sales_qty) = 0 THEN 0 ELSE SUM(cte.return_qty) / (SUM(cte.sales_qty)) END AS ret_pct,
           CASE WHEN SUM(cte.sales_qty) = 0 THEN 0 ELSE SUM(cte.rx_qty) / (SUM(cte.sales_qty)) END AS rx_pct,
           CASE WHEN SUM(cte.sales_qty) = 0 THEN 0 ELSE SUM(cte.qty_on_promo_m1_3) / SUM(cte.sales_qty) END AS Promo_pct_m1_3,
           rel.eye_shape,
           rel.Material,
           rel.PrimaryDemographic,
           rel.Frame_type,

           GETDATE() ASOFDATE

    FROM cte
        JOIN rel
            ON rel.brand = cte.brand
               AND rel.model = cte.MODEL

    GROUP BY cte.brand,
             cte.MODEL,
             cte.type_code,
             rel.rel_cnt,
             rel.eye_shape,
             rel.Material,
             rel.PrimaryDemographic,
             rel.Frame_type;
END;

GO
