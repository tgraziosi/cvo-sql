SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_tsr_pbirs_sp]
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @compyear INT, @asofdate datetime;
    SELECT @compyear = DATEPART(YEAR, GETDATE()) , @asofdate = GETDATE();


    IF (OBJECT_ID('dbo.cvo_tsr_pbirs_tbl') IS NULL)
    BEGIN

        CREATE TABLE dbo.cvo_tsr_pbirs_tbl
        (
            region VARCHAR(3),
            territory_code VARCHAR(8),
            salesperson_code VARCHAR(40),
            Sales_type VARCHAR(11),
            month VARCHAR(15),
            x_month INT,
            ty_monthsales FLOAT(8),
            ly_monthsales FLOAT(8),
            ly_month_tot_sales FLOAT(8),
			ly_monthsales_ytd FLOAT(8),
            asofdate DATETIME,
            id BIGINT IDENTITY(1, 1)
        );
        CREATE NONCLUSTERED INDEX idx_tsr_date
        ON dbo.cvo_tsr_pbirs_tbl (asofdate DESC);
		

    END;



    IF (OBJECT_ID('tempdb.dbo.#tsr') IS NOT NULL) DROP TABLE #tsr;

    CREATE TABLE #tsr
    (
        territory_code VARCHAR(8),
        salesperson_code VARCHAR(40),
        x_month INT,
        Year INT,
        month VARCHAR(15),
        anet FLOAT(8),
        qnet FLOAT(8),
        currentmonthsales FLOAT(8),
        Sales_type VARCHAR(11),
        region VARCHAR(3),
        Q INT,
        r_id INT,
        t_id INT,
        col VARCHAR(1),
        ly_ytd FLOAT(8)
    );
    INSERT INTO #tsr
    EXEC dbo.cvo_territory_sales_r2016_sp @CompareYear = @compyear;

	INSERT INTO dbo.cvo_tsr_pbirs_tbl
	(
	    region,
	    territory_code,
	    salesperson_code,
	    Sales_type,
	    month,
	    x_month,
	    ty_monthsales,
	    ly_monthsales,
	    ly_month_tot_sales,
		ly_monthsales_ytd,
	    asofdate
	)
    SELECT region,
           territory_code,
           salesperson_code,
           Sales_type,
           month,
           x_month,
           SUM(CASE WHEN Year = @compyear THEN anet ELSE 0 END) AS ty_monthsales,
           SUM(CASE WHEN Year <> @compyear THEN anet ELSE 0 END) AS ly_monthsales,
           SUM(CASE WHEN Year <> @compyear THEN currentmonthsales ELSE 0 END) AS ly_month_tot_sales,
		   SUM(tsr.ly_ytd) ly_monthsales_ytd,
		   @asofdate
    FROM #tsr tsr
    GROUP BY tsr.region,
             tsr.territory_code,
             tsr.salesperson_code,
             tsr.Sales_type,
             tsr.x_month,
             tsr.month;

END;

GO
GRANT EXECUTE ON  [dbo].[cvo_tsr_pbirs_sp] TO [public]
GO
