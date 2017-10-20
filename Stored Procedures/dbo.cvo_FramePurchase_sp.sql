SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_FramePurchase_sp]
    @asofdate DATETIME = NULL, @MthsToReport INT = NULL, @Cust VARCHAR(8000) 
AS

    -- exec cvo_FramePurchase_sp '10/31/2017',1,'045183'
	
begin
SET NOCOUNT ON;

-- debugging ...
--DECLARE @asofdate DATETIME ,
--        @MthsToReport INT ,
--        @cust VARCHAR(20);
--SELECT @asofdate = '10/17/2017' ,
--       @MthsToReport = 12 ,
--       @Cust = '045183';



    IF @asofdate IS NULL SELECT @asofdate = DATEADD(DAY, 0, DATEDIFF(DAY, 0, GETDATE()))
        ;
    IF @MthsToReport IS NULL SELECT @MthsToReport = 12
        ;

    -- SELECT @asofyear


    IF (OBJECT_ID('tempdb.dbo.#Cust') IS NOT NULL) DROP TABLE #Cust
        ;
    CREATE TABLE #cust
    (
        customer_code VARCHAR(10),
        territory_code VARCHAR(10)
    )
    ;

        INSERT INTO #cust
        (
            customer_code, territory_code
        )
        SELECT DISTINCT
            ListItem, ar.territory_code
        FROM
            dbo.f_comma_list_to_table(@Cust)
            JOIN arcust ar
                ON ar.customer_code = ListItem
        ORDER BY ListItem
        ;


    SELECT
        ar.territory_code,
        ar.customer_code,
        ar.ship_to_code,
        ar.address_name,
        LTRIM(RTRIM(ISNULL(designations.desig, '<None>'))) desig,
        i.category,
        ia.field_2 style,
        i.part_no,
        sbm.c_year,
        sbm.c_month,
		CASE WHEN LEFT(sbm.user_category,2) = 'RX' THEN 'RX' ELSE 'ST' END order_type,
        SUM(qnet) net_qty

    FROM
		armaster ar (nolock)
		LEFT OUTER join
		 cvo_sbm_details sbm (NOLOCK)
		 ON sbm.customer = ar.customer_code AND sbm.ship_to = ar.ship_to_code
		 
        JOIN inv_master i
            ON i.part_no = sbm.part_no
        JOIN inv_master_add ia
            ON ia.part_no = sbm.part_no
        LEFT OUTER JOIN
        (
            SELECT distinct
                c.customer_code,
                STUFF(
                (
                    SELECT '; ' + code
                    FROM cvo_cust_designation_codes (NOLOCK)
                    WHERE
                        customer_code = c.customer_code
                        AND ISNULL(start_date, @asofdate) <= @asofdate
                        AND ISNULL(end_date, @asofdate) >= @asofdate
                        AND code LIKE 'M-%'
                    FOR XML PATH('')
                ),
                         1,
                         1,
                         ''
                     ) desig
            FROM dbo.cvo_cust_designation_codes (NOLOCK) c
        ) AS designations
            ON designations.customer_code = ar.customer_code
    WHERE
        sbm.yyyymmdd >= DATEADD(MONTH, -@MthsToReport, @asofdate)
        AND i.type_code IN ( 'frame', 'sun' )
		AND ar.customer_code IN (SELECT DISTINCT customer_code FROM #cust)
    GROUP BY LTRIM(RTRIM(ISNULL(designations.desig, '<None>'))) ,
             CASE WHEN LEFT(sbm.user_category, 2) = 'RX' THEN 'RX'
             ELSE 'ST'
             END ,
             ar.territory_code ,
             ar.customer_code ,
             ar.ship_to_code ,
             ar.address_name ,
             i.category ,
             ia.field_2 ,
             i.part_no ,
             sbm.c_year ,
             sbm.c_month
    ;

END;


GO
GRANT EXECUTE ON  [dbo].[cvo_FramePurchase_sp] TO [public]
GO
