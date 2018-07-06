SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cvo_whse_planning_qtys_sp]
(
    @Location VARCHAR(1024) = NULL,
    @Brand VARCHAR(1024) = NULL,
    @Model VARCHAR(5000) = NULL,
    @TypeCode VARCHAR(1024) = NULL
)
AS
BEGIN

    SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

    /*
EXEC dbo.cvo_whse_planning_qtys_sp @Location = '001', -- varchar(1024)
                                   @Brand = 'SM',    -- varchar(1024)
                                   @Model = null,    -- varchar(5000)
                                   @TypeCode = 'FRAME'  -- varchar(1024)
*/

    DECLARE @loc VARCHAR(1024),
            @br VARCHAR(1024),
            @m VARCHAR(5000),
            @tc VARCHAR(1024);

    SELECT @loc = @Location,
           @br = @Brand,
           @m  = @Model,
           @tc = @TypeCode;

    --SELECT @loc = '001',
    --       @br = 'bcbg',
    --       @m  = null,
    --       @tc = 'frame';


    DECLARE @coll_tbl TABLE
    (
        coll VARCHAR(20) NOT NULL
    );

    IF @br IS NULL
       OR @br LIKE '%*ALL*%'
    BEGIN
        INSERT INTO @coll_tbl
        SELECT DISTINCT
               kys
        FROM dbo.category
        WHERE void = 'n';
    END;
    ELSE
    BEGIN
        INSERT INTO @coll_tbl
        (
            coll
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@br);
    END;

    DECLARE @style_list_tbl TABLE
    (
        style VARCHAR(40) NULL
    );

    IF @m IS NULL
       OR @m LIKE '%*ALL*%'
    BEGIN
        INSERT INTO @style_list_tbl
        SELECT DISTINCT
               ia.field_2
        FROM @coll_tbl c
            INNER JOIN dbo.inv_master i
            (NOLOCK)
                ON i.category = c.coll
            JOIN dbo.inv_master_add ia
            (NOLOCK)
                ON i.part_no = ia.part_no
        WHERE i.void = 'n';
    END;
    ELSE
    BEGIN
        INSERT INTO @style_list_tbl
        (
            style
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@m);
    END;

    DECLARE @loc_tbl TABLE
    (
        location VARCHAR(10) NOT NULL
    );

    IF @loc IS NULL
       OR @loc LIKE '%*ALL*%'
    BEGIN
        INSERT INTO @loc_tbl
        (
            location
        )
        VALUES
        ('' );

        INSERT INTO @loc_tbl
        (
            location
        )
        SELECT DISTINCT
               la.location
        FROM dbo.locations_all AS la
        WHERE la.void = 'n';
    END;
    ELSE
    BEGIN
        INSERT INTO @loc_tbl
        (
            location
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@loc);
    END;

    DECLARE @tc_tbl TABLE
    (
        tc VARCHAR(10) NOT NULL
    );

    IF @tc IS NULL
       OR @tc LIKE '%*ALL*%'
    BEGIN

        INSERT INTO @tc_tbl
        (
            tc
        )
        SELECT DISTINCT
               la.type_code
        FROM dbo.inv_master AS la;
    END;
    ELSE
    BEGIN
        INSERT INTO @tc_tbl
        (
            tc
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@tc);
    END;


    ;WITH inv
    AS
    (
    SELECT i.part_no
    FROM inv_master i
        JOIN inv_master_add ia
            ON i.part_no = ia.part_no
        JOIN @coll_tbl AS ct
            ON ct.coll = i.category
        JOIN @style_list_tbl AS slt
            ON slt.style = ia.field_2
        JOIN @tc_tbl AS tt
            ON tt.tc = i.type_code
    WHERE i.void = 'N'
    ),
          w
    AS
    (
    SELECT w.part_no,
           w.bin_no,
           w.Brand,
           w.model,
           w.description,
           w.type_code,
           w.qty,
           w.Is_Assigned,
           w.primary_bin,
           w.status,
           w.max_lvl,
           w.repl_min,
           w.repl_max,
           w.repl_qty,
           w.rel_date,
           w.pom_date,
           w.POM_age,
           w.usage_type_code,
           w.group_code,
           w.location,
           w.inv_void
    FROM cvo_whse_planning_vw w
    WHERE w.part_no IN
          (
          SELECT part_no FROM inv
          )
          AND w.location IN
              (
              SELECT location FROM @loc_tbl
              )
		  AND (W.group_code <> 'BULK' OR (w.group_code='BULK' AND w.bin_no LIKE 'W%'))
		  AND w.slot LIKE '[0-9]%'

		)
    ,
          iav
    AS
    (
    SELECT i.location,
           i.part_no,
           Brand,
           i.Style,
           ResType,
           qty_avl,
           backorder,
           po_on_order,
           NextPOOnOrder,
           NextPODueDate
    FROM cvo_item_avail_vw i
        (NOLOCK)
    WHERE i.location IN
          (
          SELECT location FROM @loc_tbl
          )
          AND i.part_no IN
              (
              SELECT part_no FROM inv
              )
    )
    SELECT w.part_no,
           w.bin_no,
           w.Brand,
           w.model,
           w.description,
           w.type_code,
           w.qty,
           w.Is_Assigned,
           w.primary_bin,
           w.status,
           w.max_lvl,
           w.repl_min,
           w.repl_max,
           w.repl_qty,
           w.rel_date,
           w.pom_date,
           w.POM_age,
           w.usage_type_code,
           w.group_code,
           w.location,
           w.inv_void,
           iav.qty_avl,
           iav.backorder,
           iav.po_on_order,
           iav.NextPOOnOrder,
           iav.NextPODueDate
    FROM w
        JOIN iav
            ON iav.location = w.location
               AND iav.part_no = w.part_no;

END;



GO
