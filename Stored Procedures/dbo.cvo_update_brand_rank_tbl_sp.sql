SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_update_brand_rank_tbl_sp]
AS

BEGIN
    SET NOCOUNT ON;

    -- Get brand analysis for each collection being reported - takes 2 minutes/brand
	-- exec cvo_update_brand_rank_tbl_SP

	-- drop table dbo.cvo_brand_rank_tbl

    IF (OBJECT_ID('dbo.cvo_brand_rank_tbl') IS NULL)
    BEGIN
        CREATE TABLE cvo_brand_rank_tbl
        (
            rel_date DATETIME,
            pom_date DATETIME NULL,
            brand VARCHAR(10),
            MODEL VARCHAR(40),
            type_code VARCHAR(10),
            num_releases INT,
            num_cust INT,
            num_cust_wk4 INT,
            num_cust_wk6 INT,
            net_qty FLOAT(8),
            st_qty FLOAT(8),
            rx_qty FLOAT(8),
            return_qty FLOAT(8),
            sales_qty FLOAT(8),
            ret_pct FLOAT(8),
            rx_pct FLOAT(8),
            Promo_pct_m1_3 FLOAT(8),
            eye_shape VARCHAR(40),
            Material VARCHAR(255),
            PrimaryDemographic VARCHAR(40),
            Frame_type VARCHAR(255),
            ASOFDATE DATETIME,
			quartile INT,
            id BIGINT IDENTITY(1, 1)
        );

        CREATE CLUSTERED INDEX idx_brand_rank_id
        ON dbo.cvo_brand_rank_tbl (id ASC);

        CREATE INDEX idx_brand_rank_model
        ON dbo.cvo_brand_rank_tbl
        (
        brand,
        MODEL
        )
        INCLUDE
        (
        quartile,
        ASOFDATE
        );
    END;

    IF (OBJECT_ID('tempdb.dbo.#brandrank') IS NOT NULL)
        DROP TABLE #brandrank;

    CREATE TABLE #brandrank
    (
        rel_date DATETIME,
        pom_date DATETIME,
        brand VARCHAR(10),
        MODEL VARCHAR(40),
        type_code VARCHAR(10),
        num_releases INT,
        num_cust INT,
        num_cust_wk1 INT,
        num_cust_wk2 INT,
        net_qty FLOAT(8),
        st_qty FLOAT(8),
        rx_qty FLOAT(8),
        return_qty FLOAT(8),
        sales_qty FLOAT(8),
        ret_pct FLOAT(8),
        rx_pct FLOAT(8),
        Promo_pct_m1_3 FLOAT(8),
        eye_shape VARCHAR(40),
        Material VARCHAR(255),
        PrimaryDemographic VARCHAR(40),
        Frame_type VARCHAR(255),
        quartile INT,
        ASOFDATE DATETIME
    );

    INSERT #brandrank
    (
        rel_date,
        pom_date,
        brand,
        MODEL,
        type_code,
        num_releases,
        num_cust,
        num_cust_wk1,
        num_cust_wk2,
        net_qty,
        st_qty,
        rx_qty,
        return_qty,
        sales_qty,
        ret_pct,
        rx_pct,
        Promo_pct_m1_3,
        eye_shape,
        Material,
        PrimaryDemographic,
        Frame_type,
        ASOFDATE
    )
    EXEC cvo_brand_release_analyze_sp @coll = NULL,      -- all
                                      @gender = NULL,    -- all
                                      @rel_start = NULL, -- four years ago
                                      @rel_end = NULL,   -- now
                                      @wk1 = 4,
                                      @wk2 = 6;

    INSERT INTO dbo.cvo_brand_rank_tbl
    (
        rel_date,
        pom_date,
        brand,
        MODEL,
        type_code,
        num_releases,
        num_cust,
        num_cust_wk4,
        num_cust_wk6,
        net_qty,
        st_qty,
        rx_qty,
        return_qty,
        sales_qty,
        ret_pct,
        rx_pct,
        Promo_pct_m1_3,
        eye_shape,
        Material,
        PrimaryDemographic,
        Frame_type,
        quartile,
        ASOFDATE
    )
    SELECT b.rel_date,
           CASE WHEN b.pom_date = '2999-12-31' THEN NULL ELSE b.pom_date END pom_date,
           b.brand,
           b.MODEL,
           b.type_code,
           b.num_releases,
           b.num_cust,
           b.num_cust_wk1,
           b.num_cust_wk2,
           b.net_qty,
           b.st_qty,
           b.rx_qty,
           b.return_qty,
           b.sales_qty,
           b.ret_pct,
           b.rx_pct,
           b.Promo_pct_m1_3,
           b.eye_shape,
           b.Material,
           b.PrimaryDemographic,
           b.Frame_type,
           CAST(NTILE(4) OVER (PARTITION BY b.brand ORDER BY b.num_cust_wk1 DESC) AS CHAR(1)) quartile,
           b.ASOFDATE

    FROM #brandrank AS b;

END;

GO
GRANT EXECUTE ON  [dbo].[cvo_update_brand_rank_tbl_sp] TO [public]
GO
