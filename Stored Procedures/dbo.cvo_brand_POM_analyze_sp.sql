SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_brand_POM_analyze_sp]
(
    @coll VARCHAR(1024) = NULL,
    @gender VARCHAR(512) = NULL,
    @pom_start DATETIME = NULL,
    @pom_end DATETIME = NULL,
    @wk1 INT = NULL,
    @wk2 INT = NULL
)
AS
BEGIN

    -- exec cvo_brand_pom_analyze_sp @coll = 'bcbg', @gender = null, @pom_start = null, @pom_end = null, @wk1 = 13, @wk2 = 26

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

    IF @pom_start IS NULL
        SELECT @pom_start = MIN(ia.field_28)
        FROM inv_master_add ia
		JOIN inv_master i ON i.part_no = ia.part_no
        WHERE i.type_code IN ( 'frame', 'sun' ) AND ia.field_28 IS NOT null;
    IF @pom_end IS NULL
        SET @pom_end = GETDATE();

    WITH cte
    AS
    (
    SELECT i.category brand,
           ia.field_2 MODEL,
           MIN(ia.field_26) rel_date,
           MIN(ISNULL(ia.field_28, '12/31/2999')) pom_date,
           i.type_code,
           MIN(sbm.yyyymmdd) first_brand_return,
           AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END AS customer,
           CASE WHEN DATEDIFF(WEEK, ia.field_28, sbm.yyyymmdd) <= @wk1
                     AND sbm.qreturns <> 0
                     AND sbm.return_code = '' THEN
                    AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END ELSE ''
           END AS customerwk1,
           CASE WHEN DATEDIFF(WEEK, ia.field_28, sbm.yyyymmdd) <= @wk2
                     AND sbm.qreturns <> 0
                     AND sbm.return_code = '' THEN
                    AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END ELSE ''
           END AS customerwk2,
           SUM(CASE WHEN sbm.return_code = '' THEN sbm.qreturns ELSE 0 END) st_returns,
           SUM(CASE WHEN sbm.return_code = 'wty' THEN sbm.qreturns ELSE 0 END) wty_returns,
           SUM(sbm.qsales) sales_qty
    FROM @coll_tbl c
        JOIN dbo.inv_master i
        (NOLOCK)
            ON i.category = c.coll
               AND i.type_code IN ( 'frame', 'sun' )
        JOIN dbo.inv_master_add ia
        (NOLOCK)
            ON ia.part_no = i.part_no
        JOIN @gender_tbl g
            ON g.gender = ia.category_2
        JOIN dbo.cvo_sbm_details sbm
        (NOLOCK)
            ON sbm.part_no = ia.part_no
        JOIN dbo.CVO_armaster_all AS car
        (NOLOCK)
            ON car.customer_code = sbm.customer
               AND car.ship_to = sbm.ship_to
        JOIN dbo.armaster AR
        (NOLOCK)
            ON AR.customer_code = car.customer_code
               AND AR.ship_to_code = car.ship_to
    WHERE ISNULL(ia.field_28, '12/31/2999')
          BETWEEN @pom_start AND @pom_end
          AND sbm.yyyymmdd >= @pom_start
          AND NOT EXISTS
    (
    SELECT 1
    FROM dbo.cvo_part_attributes AS pa
        (NOLOCK)
    WHERE pa.part_no = i.part_no
          AND attribute IN ( 'hvc', 'retail', 'specialord' )
    )
    GROUP BY AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END,
             CASE WHEN DATEDIFF(WEEK, ia.field_28, sbm.yyyymmdd) <= @wk1
                       AND sbm.qreturns <> 0
                       AND sbm.return_code = '' THEN
                      AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END ELSE ''
             END,
             CASE WHEN DATEDIFF(WEEK, ia.field_28, sbm.yyyymmdd) <= @wk2
                       AND sbm.qreturns <> 0
                       AND sbm.return_code = '' THEN
                      AR.customer_code + CASE WHEN car.door = 1 THEN '-' + AR.ship_to_code ELSE '' END ELSE ''
             END,
             i.category,
             ia.field_2,
             i.type_code
    ),
         pom
    AS
    (
    SELECT DISTINCT
           i.category brand,
           ia.field_2 model,
           COUNT(DISTINCT ia.field_28) pom_cnt,
           MAX(ISNULL(ccv.eye_shape, '')) eye_shape,
           MAX(ISNULL(ccv.front_material, ISNULL(ia.field_10, ''))) Material,
           MAX(ISNULL(ccv.PrimaryDemographic, ISNULL(ia.category_2, ''))) PrimaryDemographic,
           MAX(ISNULL(ccv.frame_category, ISNULL(ia.field_11, ''))) Frame_type
    FROM @coll_tbl c
        JOIN dbo.inv_master i
        (NOLOCK)
            ON i.category = c.coll
               AND i.type_code IN ( 'frame', 'sun' )
        JOIN dbo.inv_master_add ia
        (NOLOCK)
            ON ia.part_no = i.part_no
        JOIN @gender_tbl g
            ON g.gender = ia.category_2
        LEFT OUTER JOIN dbo.cvo_cmi_catalog_view AS ccv
        (NOLOCK)
            ON ccv.upc_code = i.upc_code
    WHERE ISNULL(i.void, 'N') = 'N'
          AND ISNULL(ia.field_28, '12/31/2999')
          BETWEEN @pom_start AND @pom_end
    GROUP BY i.category,
             ia.field_2
    )

    --SELECT DISTINCT field_26, part_no FROM inv_master_add WHERE field_2 = 'free'

    SELECT CONVERT(DATETIME, MIN(cte.rel_date), 110) rel_date,
           CONVERT(DATETIME, MIN(cte.pom_date), 110) pom_date,
           cte.brand,
           cte.MODEL,
           cte.type_code,
           pom.pom_cnt num_poms,
           COUNT(DISTINCT cte.customer) num_cust,
           COUNT(DISTINCT cte.customerwk1) num_cust_wk1,
           COUNT(DISTINCT cte.customerwk2) num_cust_wk2,
           SUM(cte.st_returns) st_returns,
           SUM(cte.wty_returns) wty_returns,
           SUM(cte.sales_qty) sales_qty,
           CASE WHEN SUM(cte.sales_qty) = 0 THEN 0 ELSE SUM(cte.st_returns) / (SUM(cte.sales_qty)) END AS st_ret_pct,
           CASE WHEN SUM(cte.sales_qty) = 0 THEN 0 ELSE SUM(cte.wty_returns) / (SUM(cte.sales_qty)) END AS wty_ret_pct,
           pom.eye_shape,
           pom.Material,
           pom.PrimaryDemographic,
           pom.Frame_type,
           GETDATE() ASOFDATE
    FROM cte
        JOIN pom
            ON pom.brand = cte.brand
               AND pom.model = cte.MODEL
    GROUP BY cte.brand,
             cte.MODEL,
             cte.type_code,
             pom.pom_cnt,
             pom.eye_shape,
             pom.Material,
             pom.PrimaryDemographic,
             pom.Frame_type;
END;


GO
GRANT EXECUTE ON  [dbo].[cvo_brand_POM_analyze_sp] TO [public]
GO
