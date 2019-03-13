SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_INV_AGING_POM_OVERSTOCKS_SP]
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @TODAY DATETIME;

    SELECT @TODAY = GETDATE();



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
        img_web VARCHAR(100),
        LABEL VARCHAR(100) NULL
    );

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
        img_web
    )
    EXEC cvo_inv_aging_pom_sp @TODAY, '001', 'frame,sun';

    UPDATE #REPORTLIST
    SET LABEL = '11'+Brand;

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
        img_web,
        LABEL
    )
    SELECT t.Brand,
           t.ResType,
           t.Style,
           t.Gender,
           t.eos,
           t.part_no,
           t.description,
           t.POM_date,
           t.age,
           t.tot_cost_ea,
           t.tot_ext_cost,
           t.in_stock,
           t.qty_avl,
           t.SOF,
           t.Allocated,
           t.Quarantine,
           t.Non_alloc,
           t.Replen_Qty_Not_SA,
           t.ReplenQty,
           t.material,
           t.color_desc,
           t.img_web,
           '99Kids'
    FROM #REPORTLIST AS t
    WHERE gender IN ('girls','boys','unisex kids','kids');

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
        img_web,
        LABEL
    )
    SELECT t.Brand,
           t.ResType,
           t.Style,
           t.Gender,
           t.eos,
           t.part_no,
           t.description,
           t.POM_date,
           t.age,
           t.tot_cost_ea,
           t.tot_ext_cost,
           t.in_stock,
           t.qty_avl,
           t.SOF,
           t.Allocated,
           t.Quarantine,
           t.Non_alloc,
           t.Replen_Qty_Not_SA,
           t.ReplenQty,
           t.material,
           t.color_desc,
           t.img_web,
           '99Suns'
    FROM #REPORTLIST AS t
    WHERE t.ResType = 'suns'
    

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
        img_web,
        LABEL
    )
    SELECT t.Brand,
           t.ResType,
           t.Style,
           t.Gender,
           t.eos,
           t.part_no,
           t.description,
           t.POM_date,
           t.age,
           t.tot_cost_ea,
           t.tot_ext_cost,
           t.in_stock,
           t.qty_avl,
           t.SOF,
           t.Allocated,
           t.Quarantine,
           t.Non_alloc,
           t.Replen_Qty_Not_SA,
           t.ReplenQty,
           t.material,
           t.color_desc,
           t.img_web,
           '99Suns EOS'
    FROM #REPORTLIST AS t
    WHERE eos = 'eos';

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
        img_web,
        LABEL
    )
    SELECT t.Brand,
           t.ResType,
           t.Style,
           t.Gender,
           t.eos,
           t.part_no,
           t.description,
           t.POM_date,
           t.age,
           t.tot_cost_ea,
           t.tot_ext_cost,
           t.in_stock,
           t.qty_avl,
           t.SOF,
           t.Allocated,
           t.Quarantine,
           t.Non_alloc,
           t.Replen_Qty_Not_SA,
           t.ReplenQty,
           t.material,
           t.color_desc,
           t.img_web,
           '99'+CASE
               WHEN hi.longdesc LIKE '%SPV%' THEN
                   'SV'
               ELSE
                   hi.[category:1]
           END
    FROM #REPORTLIST AS t
        JOIN dbo.cvo_hs_inventory_8 AS hi
            ON hi.sku = t.part_no
    WHERE hi.[category:1] IN ( 'qop', 'eor' )
          OR hi.longdesc LIKE '%SPV%';

    SELECT r.Brand,
           r.ResType,
           r.Style,
           CASE
               WHEN r.Gender = 'UNISEX' THEN
                   CASE
                       WHEN Brand = 'REVO' THEN
                           '1Men'
                       WHEN brand = 'bcbg' THEN
                            '2Women'
                       ELSE
                           '1Men'
                   END
               WHEN r.Gender IN ( 'GIRLS', 'BOYS' )
                    OR Gender LIKE '%KIDS%' THEN
                   '3Kids'
               WHEN r.gender LIKE '%women%' THEN '2Women'
               when r.gender LIKE '%men%' THEN '1Men'
                              ELSE
                   '9'+r.Gender
           END Gender,
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
           CASE
               WHEN r.material LIKE '%METAL%' THEN
                   'METAL'
               ELSE
                   'PLASTIC'
           END material,
           r.color_desc,
           r.img_web,
           r.LABEL VERSION_LABEL
    FROM #REPORTLIST AS r;


END;





GO
GRANT EXECUTE ON  [dbo].[CVO_INV_AGING_POM_OVERSTOCKS_SP] TO [public]
GO
