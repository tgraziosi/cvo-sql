SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_FramePurchase_sp]
    @asofdate     DATETIME = NULL,
    @MthsToReport INT      = NULL,
    @Cust         VARCHAR(8000),
    @OrderType      VARCHAR(50) = NULL
    
AS

    -- exec cvo_FramePurchase_sp '7/31/2018',18,'014888'

    BEGIN
        SET NOCOUNT ON;

        -- debugging ...
        --DECLARE @asofdate DATETIME ,
        --        @MthsToReport INT ,
        --        @cust VARCHAR(20);
        --SELECT @asofdate = '10/17/2017' ,
        --       @MthsToReport = 12 ,
        --       @Cust = '045183';


        DECLARE
            @asofyear  INT,
            @asofmonth INT;


        IF @asofdate IS NULL
            SELECT
                @asofdate = DATEADD(DAY, 0, DATEDIFF(DAY, 0, GETDATE()));
        IF @MthsToReport IS NULL
            SELECT
                @MthsToReport = 12;

        SELECT
            @asofyear  = YEAR(@asofdate),
            @asofmonth = MONTH(@asofdate);

        -- SELECT @asofyear


        IF (OBJECT_ID('tempdb.dbo.#Cust') IS NOT NULL)
            DROP TABLE #Cust;
        CREATE TABLE #cust
            (
                customer_code  VARCHAR(10),
                territory_code VARCHAR(10)
            );

        INSERT INTO #cust
            (
                customer_code,
                territory_code
            )
                    SELECT  DISTINCT
                            ListItem,
                            ar.territory_code
                    FROM
                            dbo.f_comma_list_to_table(@Cust)
                        JOIN
                            arcust ar
                                ON ar.customer_code = ListItem
                    ORDER BY
                            ListItem;


        IF (OBJECT_ID('tempdb.dbo.#ordtype') IS NOT NULL)
            DROP TABLE #ordtype;
        CREATE TABLE #ordtype
            (
                ordtype  VARCHAR(10)
            );

        INSERT INTO #ordtype
            (
                ordtype
            )
                    SELECT  DISTINCT
                            ListItem    FROM   dbo.f_comma_list_to_table(ISNULL(@ordertype,'RX,ST'))
                       
                    ORDER BY
                            ListItem;

        ;WITH sda
        AS (   SELECT
                       ar.territory_code,
                       ar.customer_code,
                       CASE WHEN co.door = 1 THEN ar.ship_to_code ELSE '' END ship_to_code,
                       LTRIM(RTRIM(ISNULL(designations.desig, '<None>'))) desig,
                       i.category,
                       ia.field_2                                         style,
                       i.part_no,
                       sbm.c_year,
                       sbm.c_month,
                       CASE
                           WHEN LEFT(sbm.user_category, 2) = 'RX'
                               THEN
                               'RX'
                           ELSE
                               'ST'
                       END                                                order_type,
                       SUM(ISNULL(sbm.qnet, 0))                           net_qty,
                       -- 07/23/2018
                       SUM(ISNULL(sbm.anet, 0))                           net_amt,
                       i.description,
                       co.door,
                       fs.FirstSale
               FROM
                       (
                           SELECT DISTINCT
                                  customer_code
                           FROM
                                  #cust
                       )                    cust
                   JOIN
                       armaster             ar (NOLOCK)
                           ON ar.customer_code = cust.customer_code
                   JOIN
                       dbo.CVO_armaster_all co (NOLOCK)
                           ON co.customer_code = ar.customer_code
                              AND co.ship_to = ar.ship_to_code
                   LEFT OUTER JOIN
                       cvo_sbm_details      sbm (NOLOCK)
                           ON sbm.customer = ar.customer_code
                              AND sbm.ship_to = ar.ship_to_code
                   JOIN
                       inv_master           i
                           ON i.part_no = sbm.part_no
                   JOIN
                       inv_master_add       ia
                           ON ia.part_no = sbm.part_no
                   LEFT OUTER JOIN
                       (
                           SELECT DISTINCT
                                  c.customer_code,
                                  STUFF(
                                      (
                                          SELECT
                                              '; ' + code
                                          FROM
                                              cvo_cust_designation_codes (NOLOCK)
                                          WHERE
                                              customer_code = c.customer_code
                                              AND ISNULL(start_date, @asofdate) <= @asofdate
                                              AND ISNULL(end_date, @asofdate) >= @asofdate
                                              AND code LIKE 'M-%'
                                          FOR XML PATH('')
                                      ), 1, 1, ''
                                       ) desig
                           FROM
                                  dbo.cvo_cust_designation_codes (NOLOCK) c
                       )                    AS designations
                           ON designations.customer_code = ar.customer_code
                   LEFT OUTER JOIN
                       (
                           SELECT
                                   customer,
                                   CASE
                                       WHEN co.door = 1
                                           THEN
                                           co.ship_to
                                       ELSE
                                           ''
                                   END           ship_to,
                                   part_no,
                                   MIN(yyyymmdd) FirstSale
                           FROM
                                   cvo_sbm_details (NOLOCK)
                               JOIN
                                   CVO_armaster_all co
                                       ON co.ship_to = cvo_sbm_details.ship_to
                                          AND co.customer_code = dbo.cvo_sbm_details.customer
                           WHERE
                                   user_category LIKE 'st%'
                           GROUP BY
                                   customer,
                                   CASE
                                       WHEN co.door = 1
                                           THEN
                                           co.ship_to
                                       ELSE
                                           ''
                                   END,
                                   part_no
                       )                    fs
                           ON fs.customer = co.customer_code
                              AND fs.ship_to = CASE
                                                   WHEN co.door = 1
                                                       THEN
                                                       co.ship_to
                                                   ELSE
                                                       ''
                                               END
                              AND fs.part_no = i.part_no
               WHERE
                       sbm.yyyymmdd >= DATEADD(MONTH, -@MthsToReport, @asofdate)
                       AND i.type_code IN (
                                              'frame', 'sun'
                                          )
               GROUP BY
                       LTRIM(RTRIM(ISNULL(designations.desig, '<None>'))),
                       CASE
                           WHEN LEFT(sbm.user_category, 2) = 'RX'
                               THEN
                               'RX'
                           ELSE
                               'ST'
                       END,
                       ar.territory_code,
                       ar.customer_code,
                       CASE WHEN co.door = 1 THEN ar.ship_to_code ELSE '' END,
                       i.category,
                       ia.field_2,
                       i.part_no,
                       sbm.c_year,
                       sbm.c_month,
                       i.description,
                       co.door,
                       fs.FirstSale)
        SELECT
                sda.territory_code,
                sda.customer_code,
                sda.ship_to_code,
                ar.address_name,
                sda.desig,
                sda.category,
                sda.style,
                sda.part_no,
                sda.c_year,
                sda.c_month,
                sda.order_type,
                sda.net_qty,
                sda.net_amt,
                sda.description,
                sda.door,
                sda.FirstSale,
                ISNULL(s.sku_rank,99999) sku_rank
        FROM
            sda
            JOIN armaster ar ON ar.customer_code = sda.customer_code AND ar.ship_to_code = sda.ship_to_code
            LEFT OUTER JOIN
                (
                    SELECT
                        sda.territory_code,
                        sda.customer_code,
                        sda.ship_to_code,
                        sda.part_no,
                        @asofyear    c_year,
                        RANK() OVER (PARTITION BY customer_code, ship_to_code ORDER BY SUM(net_Qty) DESC ) sku_rank
                    FROM
                        sda 
                        INNER JOIN #ordtype AS o ON o.ordtype = sda.order_type
                    WHERE
                        c_year = @asofyear
             
                    GROUP BY
                        sda.territory_code,
                        sda.customer_code,
                        sda.ship_to_code,
                        sda.part_no
                )         s
                    ON s.customer_code = sda.customer_code
                       AND s.ship_to_code = sda.ship_to_code
                       AND s.territory_code = sda.territory_code
                       AND s.part_no = sda.part_no;

    END;

GO
GRANT EXECUTE ON  [dbo].[cvo_FramePurchase_sp] TO [public]
GO
