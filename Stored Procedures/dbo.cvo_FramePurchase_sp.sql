SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_FramePurchase_sp]
    @asofdate DATETIME = NULL, @MthsToReport INT = NULL, @Cust VARCHAR(8000) 
AS

    -- exec cvo_FramePurchase_sp '7/31/2018',18,'014888'
	
begin
SET NOCOUNT ON;

-- debugging ...
--DECLARE @asofdate DATETIME ,
--        @MthsToReport INT ,
--        @cust VARCHAR(20);
--SELECT @asofdate = '10/17/2017' ,
--       @MthsToReport = 12 ,
--       @Cust = '045183';


    DECLARE @asofyear INT, @asofmonth int;


    IF @asofdate IS NULL SELECT @asofdate = DATEADD(DAY, 0, DATEDIFF(DAY, 0, GETDATE()))
        ;
    IF @MthsToReport IS NULL SELECT @MthsToReport = 12
        ;

    SELECT @asofyear = YEAR(@asofdate), @asofmonth = MONTH(@asofdate)

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

    ;WITH salesdata AS 
    (
    SELECT
        ar.territory_code,
        ar.customer_code,
        ar.ship_to_code ,
        ar.address_name,
        LTRIM(RTRIM(ISNULL(designations.desig, '<None>'))) desig,
        i.category,
        ia.field_2 style,
        i.part_no,
        sbm.c_year,
        sbm.c_month,
		CASE WHEN LEFT(sbm.user_category,2) = 'RX' THEN 'RX' ELSE 'ST' END order_type,
        SUM(ISNULL(sbm.qnet,0)) net_qty,
-- 07/23/2018
		SUM(ISNULL(sbm.anet,0)) net_amt,
		i.description,
		co.door,
		fs.FirstSale

    FROM
		(SELECT DISTINCT customer_code FROM #cust) cust
		join
		armaster ar (nolock) ON ar.customer_code = cust.customer_code
		JOIN 
		dbo.cvo_armaster_all co (nolock) ON co.customer_code = ar.customer_code AND co.ship_to = ar.ship_to_code
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
			LEFT OUTER join
		( SELECT customer, CASE WHEN co.door = 1 THEN co.ship_to ELSE '' END ship_to, part_no, MIN(yyyymmdd) FirstSale
			FROM cvo_sbm_details (NOLOCK)
            JOIN cvo_armaster_all co ON co.ship_to = cvo_sbm_details.ship_to AND co.customer_code = dbo.cvo_sbm_details.customer
            where user_category LIKE 'st%' 
			GROUP BY customer,
                     CASE WHEN co.door = 1 THEN co.ship_to ELSE '' END,
                     part_no
		) fs ON fs.customer = co.customer_code AND fs.ship_to = CASE WHEN co.door = 1 THEN co.ship_to ELSE '' END AND fs.part_no = i.part_no
 
    WHERE
        sbm.yyyymmdd >= DATEADD(MONTH, -@MthsToReport, @asofdate)
        AND i.type_code IN ( 'frame', 'sun' )
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
             sbm.c_month,
			 i.description,
			 co.door,
			 fs.FirstSale
    )

    SELECT sd.territory_code,
           sd.customer_code,
           sd.ship_to_code ,
           sd.address_name,
           sd.desig,
           sd.category,
           sd.style,
           sd.part_no,
           sd.c_year,
           sd.c_month,
           sd.order_type,
           sd.net_qty,
           sd.net_amt,
           sd.description,
           sd.door,
           sd.FirstSale,
           ISNULL(CASE WHEN sd.c_month = s.c_month THEN s.net_qty_st_ty ELSE 0 END,0) net_qty_st_ty,
           ISNULL(CASE WHEN sd.c_month = s.c_month THEN s.net_qty_rx_ty ELSE 0 END,0) net_qty_rx_ty
           fROM salesdata sd
           LEFT OUTER JOIN 
           ( SELECT salesdata.territory_code,
                    salesdata.customer_code,
                    salesdata.ship_to_code ,
                    salesdata.part_no,
                    MAX(c_month) c_month,
                    SUM(CASE WHEN salesdata.order_type = 'st' THEN salesdata.net_qty ELSE 0 end) net_qty_st_ty,
                    SUM(CASE WHEN salesdata.order_type = 'rx' THEN salesdata.net_qty ELSE 0 end) net_qty_rx_ty
                    FROM 
           salesdata WHERE c_year = @asofyear
           GROUP BY salesdata.territory_code,
                    salesdata.customer_code,
                    salesdata.ship_to_code ,
                    salesdata.part_no
           ) s ON s.customer_code = sd.customer_code AND s.ship_to_code = sd.ship_to_code AND s.territory_code = sd.territory_code AND s.part_no = sd.part_no

END;







GO
GRANT EXECUTE ON  [dbo].[cvo_FramePurchase_sp] TO [public]
GO
