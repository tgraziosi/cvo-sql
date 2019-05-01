SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_pop_rollfwd_sp]
    @sdate DATETIME = NULL,
    @edate DATETIME = NULL,
    @loc VARCHAR(1024) = null

-- EXEC dbo.cvo_pop_rollfwd_sp @sdate = NULL, @edate = NULL, @loc = '001,002ELM'

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start DATETIME,
            @end DATETIME;
    SELECT @start = @sdate,
           @end = @edate;

    IF @start IS NULL
        SELECT @start = '1/1/2014';
    IF @end IS NULL
        SELECT @end = GETDATE();

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

    WITH pop -- List of POP skus
    AS (SELECT i.part_no,
               i.description,
               ia.field_26 rel_date,
               ia.field_28 pom_date
        FROM inv_master i (NOLOCK)
            JOIN inv_master_add ia (NOLOCK)
                ON ia.part_no = i.part_no
        WHERE i.type_code = 'pop'
              AND i.void = 'n'),
         years -- years to report
    AS (SELECT DATEPART(YEAR, @start) yy
        UNION ALL
        SELECT yy + 1 AS yy
        FROM years
        WHERE yy < DATEPART(YEAR, @end)),
         avgcost -- average cost/price FROM receipt history
    AS (SELECT pl.part_no,
               SUM(pl.quantity) qty_recv,
               SUM(p.unit_cost * pl.quantity) cost_recv,
               CASE
                   WHEN SUM(pl.quantity) = 0 THEN
                       0
                   ELSE
                       SUM(p.unit_cost * pl.quantity) / SUM(pl.quantity)
               END avg_cost,
               DATEPART(YEAR, pl.recv_date) recv_year,
               pl.location
        FROM pop
            CROSS JOIN @loc_tbl AS lt 
            JOIN dbo.receipts_all AS pl (NOLOCK)
                ON pl.part_no = pop.part_no AND pl.location = lt.location
            JOIN pur_list p (NOLOCK) ON p.po_key = pl.po_key AND p.line = pl.po_line
        WHERE pl.part_type = 'p'
              AND pl.recv_date
              BETWEEN @start AND @end
        GROUP BY DATEPART(YEAR, pl.recv_date),
                 pl.part_no,
                 pl.location),
         trans -- inventory transactions (receipts, adjustments, sales)
    AS (SELECT it.part_no,
               it.tran_type,
               DATEPART(YEAR, it.apply_date) tran_year,
               SUM(it.tran_inv_qty) tran_qty,
               it.location
        FROM pop
            CROSS JOIN @loc_tbl AS lt
            JOIN inv_tran it (NOLOCK)
                ON it.part_no = pop.part_no AND it.location = lt.location
        WHERE it.apply_date
              BETWEEN @start AND @end
              AND it.update_typ NOT IN ( 'h', 'c' ) -- update of hold or update of cost
              AND it.tran_type NOT IN ( 'n' ) -- cost changes and receipts
        GROUP BY DATEPART(YEAR, it.apply_date),
                 it.part_no,
                 it.tran_type,
                 it.location),
         inv -- ending (current) inventory info
    AS (SELECT iav.part_no,
               iav.tot_cost_ea,
               SUM(in_stock) in_stock,
               SUM(qty_avl) qty_avl,
               iav.location
        FROM cvo_item_avail_vw iav (NOLOCK)
            JOIN @loc_tbl AS lt ON lt.location = iav.location
            JOIN pop
                ON pop.part_no = iav.part_no
            
        GROUP BY iav.part_no,
                 iav.tot_cost_ea,
                 iav.location)
    SELECT pop.part_no,
           pop.description,
           pop.rel_date,
           pop.pom_date,
           yy,
           tot_cost_ea,
           inv.in_stock,
           inv.qty_avl,
           CASE
               WHEN tran_type = 'r' THEN
                   avgcost.qty_recv
               ELSE
                   0
           END qty_recv,
           CASE
               WHEN tran_type = 'r' THEN
                   avgcost.avg_cost
               ELSE
                   0
           END avg_cost_recv,
           ISNULL(trans.tran_type,'') tran_type,
           CASE
               WHEN tran_type <> 'r' THEN
                   trans.tran_qty
               ELSE
                   0
           END tran_qty,
           inv.location
    FROM pop
        CROSS JOIN years
        JOIN inv
            ON inv.part_no = pop.part_no
        LEFT OUTER JOIN avgcost
            ON avgcost.part_no = pop.part_no
               AND avgcost.recv_year = years.yy
               AND avgcost.location = inv.location
        LEFT OUTER JOIN trans
            ON trans.part_no = pop.part_no
               AND trans.tran_year = years.yy
               AND trans.location = inv.location
    WHERE pop.pom_date IS NULL
          OR
          (
              pom_date IS NOT NULL
              AND (inv.qty_avl + inv.in_stock) <> 0
          );


--SELECT * FROM inv_tran WHERE part_no = 'ddzbook' AND apply_date > '1/1/2018' AND tran_type in ('r','a')

--SELECT * FROM RECEIPTS WHERE part_no = 'ddzbook' AND recv_date > '1/1/2018'
END;

GRANT EXECUTE ON dbo.cvo_pop_rollfwd_sp TO PUBLIC;



GO
GRANT EXECUTE ON  [dbo].[cvo_pop_rollfwd_sp] TO [public]
GO
