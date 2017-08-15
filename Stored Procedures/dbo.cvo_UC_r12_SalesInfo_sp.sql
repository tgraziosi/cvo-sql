SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_UC_r12_SalesInfo_sp]
    @startdate DATETIME = NULL, @enddate DATETIME = NULL
AS
BEGIN

-- exec cvo_uc_r12_salesinfo_sp

    SET NOCOUNT ON
    ;
    SET ANSI_WARNINGS OFF
    ;

    DECLARE
        @r12tys DATETIME, @r12tye DATETIME
    ;
    DECLARE
        @r12lys DATETIME, @r12lye DATETIME
    ;

    SELECT
        @r12tys = @startdate, @r12tye = @enddate
    ;

    IF @startdate IS NULL
       OR @enddate IS NULL
    BEGIN
        SELECT
            @r12tys = drv.BeginDate,
            @r12tye = EndDate
        FROM dbo.cvo_date_range_vw AS drv
        WHERE Period = 'rolling 12 ty'
        ;
    END
    ;
    -- SELECT @r12tys = '5/1/2016', @r12tye = '4/30/2017'

    SELECT
        @r12lys = DATEADD(YEAR, -1, @r12tys),
        @r12lye = DATEADD(YEAR, -1, @r12tye)
    ;

	SELECT region, report.Sales_Tier,
	CASE WHEN report.Sales_Tier = 'A' THEN 'Over $20k'
		 WHEN report.Sales_Tier = 'B' THEN '$8500 - $19,999'
		 WHEN report.Sales_Tier = 'C' THEN '$5000 - $8499'
		 WHEN report.Sales_Tier = 'D' THEN '$2500 - $4999'
		 WHEN report.Sales_Tier = 'E' THEN '$1200 - $2499'
		 WHEN report.Sales_Tier = 'F' THEN '$1 - $1199'
		 WHEN report.Sales_Tier = 'G' THEN '$0'
		 WHEN report.Sales_Tier = 'Z' THEN '$Negative'
		 ELSE 'Unknown' END AS SalesTierText,
	report.UC,
	report.UP,
	report.DOWN,
	report.UP_Dolrs,
	report.DOWN_Dolrs

	FROM
    (
    SELECT
        sales_details.region,
        CASE
            WHEN sales_details.netsalesty >= 20000 THEN 'A'
            WHEN sales_details.netsalesty
                 BETWEEN 8500 AND 19999.99 THEN 'B'
            WHEN sales_details.netsalesty
                 BETWEEN 5000 AND 8499.99 THEN 'C'
            WHEN sales_details.netsalesty
                 BETWEEN 2500 AND 4999.99 THEN 'D'
            WHEN sales_details.netsalesty
                 BETWEEN 1200 AND 2499.99 THEN 'E'
            WHEN sales_details.netsalesty
                 BETWEEN 0.01 AND 1199.99 THEN 'F'
            WHEN sales_details.netsalesty = 0.00 THEN  'G'
            WHEN sales_details.netsalesty < 0.00 THEN  'Z'
            ELSE 'zz' END Sales_Tier,
        COUNT(sales_details.UC_code) UC,
        SUM(   CASE WHEN sales_details.netsalesty >= sales_details.netsalesly THEN 1 ELSE 0 END ) UP,
        SUM(   CASE WHEN sales_details.netsalesty < sales_details.netsalesly THEN 1 ELSE 0 END ) DOWN,
        SUM(   CASE
                   WHEN sales_details.netsalesty >= sales_details.netsalesly THEN
                       sales_details.netsalesty - sales_details.netsalesly
                   ELSE
                       0
               END
           ) UP_Dolrs,
        SUM(   CASE
                   WHEN sales_details.netsalesty < sales_details.netsalesly THEN
                       sales_details.netsalesty - sales_details.netsalesly
                   ELSE
                       0
               END
           ) DOWN_Dolrs
    FROM
    (
        SELECT
            terr.region,
            terr.territory_code,
            ar.customer_code UC_code,
            ROUND(SUM(   CASE
                             WHEN yyyymmdd >= @r12tys THEN
                                 anet
                             ELSE
                                 0
                         END
                     ),
                     2
                 ) netsalesty,
            ROUND(SUM(   CASE
                             WHEN yyyymmdd <= @r12lye THEN
                                 anet
                             ELSE
                                 0
                         END
                     ),
                     2
                 ) netsalesly
        FROM
            (
                SELECT DISTINCT
                    territory_code, dbo.calculate_region_fn(territory_code) region
                FROM armaster ar (NOLOCK)
            ) terr
            JOIN armaster ar (NOLOCK)
                ON ar.territory_code = terr.territory_code
            LEFT OUTER JOIN cvo_sbm_details sbm (NOLOCK)
                ON sbm.customer = ar.customer_code
                   AND sbm.ship_to = ar.ship_to_code
        WHERE
            sbm.yyyymmdd
        BETWEEN @r12lys AND @r12tye
		AND terr.region < '800'
        GROUP BY
            terr.region,
            terr.territory_code,
            ar.customer_code
    ) sales_details
    GROUP BY
        sales_details.region,
        CASE
            WHEN sales_details.netsalesty >= 20000 THEN
                'A'
            WHEN sales_details.netsalesty
                 BETWEEN 8500 AND 19999.99 THEN
                'B'
            WHEN sales_details.netsalesty
                 BETWEEN 5000 AND 8499.99 THEN
                'C'
            WHEN sales_details.netsalesty
                 BETWEEN 2500 AND 4999.99 THEN
                'D'
            WHEN sales_details.netsalesty
                 BETWEEN 1200 AND 2499.99 THEN
                'E'
            WHEN sales_details.netsalesty
                 BETWEEN 0.01 AND 1199.99 THEN
                'F'
            WHEN sales_details.netsalesty = 0.00 THEN
                'G'
            WHEN sales_details.netsalesty < 0.00 THEN
                'Z'
            ELSE
                'zz'
        END
    --ORDER BY
    --    region, Sales_Tier

	) report

	ORDER BY REPORT.region, report.Sales_Tier

END
;

GRANT EXECUTE
ON dbo.cvo_UC_r12_SalesInfo_sp
TO  PUBLIC
;


GO
GRANT EXECUTE ON  [dbo].[cvo_UC_r12_SalesInfo_sp] TO [public]
GO
