SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_FramePurchase_sp]
    @asofdate DATETIME = NULL, @MthsToReport INT = NULL, @Cust VARCHAR(8000) 
AS

    -- exec cvo_FramePurchase_sp
begin
SET NOCOUNT ON;



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
            JOIN armaster ar
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
        SUM(qnet) net_qty,
		CASE WHEN LEFT(sbm.user_category,2) = 'RX' THEN 'RX' ELSE 'ST' END order_type
    FROM
        #cust AS c
        JOIN armaster ar
            ON ar.customer_code = c.customer_code
        LEFT OUTER JOIN cvo_sbm_details sbm
            ON ar.customer_code = sbm.customer
               AND ar.ship_to_code = sbm.ship_to
        JOIN inv_master i
            ON i.part_no = sbm.part_no
        JOIN inv_master_add ia
            ON ia.part_no = i.part_no
        LEFT OUTER JOIN
        (
            SELECT
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
    GROUP BY
        ar.territory_code,
        ar.customer_code,
        ar.ship_to_code,
        ar.address_name,
        designations.desig,
        i.category,
        ia.field_2,
        i.part_no,
        sbm.c_year,
        sbm.c_month,
		CASE WHEN LEFT(sbm.user_category,2) = 'RX' THEN 'RX' ELSE 'ST' END 
    ;

END;

GO
GRANT EXECUTE ON  [dbo].[cvo_FramePurchase_sp] TO [public]
GO
