SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_INV_AGING_POM_df_SP]
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @TODAY DATETIME;

    SELECT @TODAY = GETDATE();

    CREATE TABLE #temptable
    (
        Brand VARCHAR(10),
        ResType VARCHAR(10),
        Style VARCHAR(40),
        Gender VARCHAR(255),
        eos VARCHAR(3),
        part_no VARCHAR(30),
        description VARCHAR(255),
        POM_date DATETIME,
        age VARCHAR(7),
        tot_cost_ea DECIMAL(23, 8),
        tot_ext_cost DECIMAL(38, 6),
        in_stock INT,
        qty_avl DECIMAL(38, 8),
        SOF DECIMAL(38, 8),
        Allocated DECIMAL(38, 8),
        Quarantine DECIMAL(38, 8),
        Non_alloc DECIMAL(38, 8),
        Replen_Qty_Not_SA DECIMAL(38, 8),
        ReplenQty DECIMAL(20, 8),
		material VARCHAR(40),
		color_desc VARCHAR(40)
    );

    CREATE TABLE #REPORTLIST
    (
        Brand VARCHAR(10),
        ResType VARCHAR(10),
        Style VARCHAR(40),
        Gender VARCHAR(255),
        eos VARCHAR(3),
        part_no VARCHAR(30),
        description VARCHAR(255),
        POM_date DATETIME,
        age VARCHAR(7),
        tot_cost_ea DECIMAL(23, 8),
        tot_ext_cost DECIMAL(38, 6),
        in_stock INT,
        qty_avl DECIMAL(38, 8),
        SOF DECIMAL(38, 8),
        Allocated DECIMAL(38, 8),
        Quarantine DECIMAL(38, 8),
        Non_alloc DECIMAL(38, 8),
        Replen_Qty_Not_SA DECIMAL(38, 8),
        ReplenQty DECIMAL(20, 8),
		material VARCHAR(40),
		color_desc VARCHAR(40),
        VERSION_LABEL VARCHAR(100) NULL
    );

    INSERT INTO #temptable
    (
        Brand,
        ResType,
        Style,
        Gender,
        eos,
        part_no,
        description,
        POM_date,
        age,
        tot_cost_ea,
        tot_ext_cost,
        in_stock,
        qty_avl,
        SOF,
        Allocated,
        Quarantine,
        Non_alloc,
        Replen_Qty_Not_SA,
        ReplenQty,
		material,
		color_desc
    )
    EXEC cvo_inv_aging_pom_sp @TODAY, '001', 'frame,sun';

    -- 1) REVO
    INSERT INTO #REPORTLIST
    (
        Brand,
        ResType,
        Style,
        Gender,
        eos,
        part_no,
        description,
        POM_date,
        age,
        tot_cost_ea,
        tot_ext_cost,
        in_stock,
        qty_avl,
        SOF,
        Allocated,
        Quarantine,
        Non_alloc,
        Replen_Qty_Not_SA,
        ReplenQty,
		material,
		color_desc,
        VERSION_LABEL
    )
    SELECT t.*,
           'REVO'
    FROM #temptable AS t
    WHERE Brand = 'REVO';


    -- 2) WOMENS SELL DOWN

    INSERT INTO #REPORTLIST
    (
        Brand,
        ResType,
        Style,
        Gender,
        eos,
        part_no,
        description,
        POM_date,
        age,
        tot_cost_ea,
        tot_ext_cost,
        in_stock,
        qty_avl,
        SOF,
        Allocated,
        Quarantine,
        Non_alloc,
        Replen_Qty_Not_SA,
        ReplenQty,
		material,
		color_desc,
        VERSION_LABEL
    )
    SELECT t.*,
           'Women''s Sell Down'
    FROM #temptable AS t
    WHERE Gender LIKE ('women%');


    -- 3) CVO

    INSERT INTO #REPORTLIST
    (
        Brand,
        ResType,
        Style,
        Gender,
        eos,
        part_no,
        description,
        POM_date,
        age,
        tot_cost_ea,
        tot_ext_cost,
        in_stock,
        qty_avl,
        SOF,
        Allocated,
        Quarantine,
        Non_alloc,
        Replen_Qty_Not_SA,
        ReplenQty,
		material,
		color_desc,
        VERSION_LABEL
    )
    SELECT t.*,
           'CVO'
    FROM #temptable AS t
    WHERE Brand = 'cvo';

    -- 4) Digit and Koodles

    INSERT INTO #REPORTLIST
    (
        Brand,
        ResType,
        Style,
        Gender,
        eos,
        part_no,
        description,
        POM_date,
        age,
        tot_cost_ea,
        tot_ext_cost,
        in_stock,
        qty_avl,
        SOF,
        Allocated,
        Quarantine,
        Non_alloc,
        Replen_Qty_Not_SA,
        ReplenQty,
		material,
		color_desc,
        VERSION_LABEL
    )
    SELECT t.*,
           'Digit and Koodles'
    FROM #temptable AS t
    WHERE Brand IN ( 'di', 'ko' );

    -- 5) Mark Ecko

    INSERT INTO #REPORTLIST
    (
        Brand,
        ResType,
        Style,
        Gender,
        eos,
        part_no,
        description,
        POM_date,
        age,
        tot_cost_ea,
        tot_ext_cost,
        in_stock,
        qty_avl,
        SOF,
        Allocated,
        Quarantine,
        Non_alloc,
        Replen_Qty_Not_SA,
        ReplenQty,
		material,
		color_desc,
        VERSION_LABEL
    )
    SELECT t.*,
           'Mark Ecko'
    FROM #temptable AS t
    WHERE Brand = 'ME';

    -- 6) Cole Haan Suns

    INSERT INTO #REPORTLIST
    (
        Brand,
        ResType,
        Style,
        Gender,
        eos,
        part_no,
        description,
        POM_date,
        age,
        tot_cost_ea,
        tot_ext_cost,
        in_stock,
        qty_avl,
        SOF,
        Allocated,
        Quarantine,
        Non_alloc,
        Replen_Qty_Not_SA,
        ReplenQty,
		material,
		color_desc,
        VERSION_LABEL
    )
    SELECT t.*,
           'Cole Haan Suns'
    FROM #temptable AS t
    WHERE Brand = 'CH'
          AND t.ResType = 'sun';

    -- 5) Mark Ecko

    INSERT INTO #REPORTLIST
    (
        Brand,
        ResType,
        Style,
        Gender,
        eos,
        part_no,
        description,
        POM_date,
        age,
        tot_cost_ea,
        tot_ext_cost,
        in_stock,
        qty_avl,
        SOF,
        Allocated,
        Quarantine,
        Non_alloc,
        Replen_Qty_Not_SA,
        ReplenQty,
		material,
		color_desc,
        VERSION_LABEL
    )
    SELECT t.*,
           'Suns EOS'
    FROM #temptable AS t WHERE eos = 'eos'

    SELECT r.VERSION_LABEL, r.Brand,
                            r.ResType,
                            r.Style,
                            r.Gender,
                            r.eos,
                            r.part_no,
                            r.description,
                            r.POM_date,
                            r.age,
                            r.tot_cost_ea,
                            r.tot_ext_cost,
                            r.in_stock,
                            r.qty_avl,
                            r.SOF,
                            r.Allocated,
                            r.Quarantine,
                            r.Non_alloc,
                            r.Replen_Qty_Not_SA,
                            r.ReplenQty,
							r.material,
							r.color_desc
    FROM #REPORTLIST AS r;

END;
GO
