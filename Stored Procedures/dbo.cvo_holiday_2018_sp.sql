SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_holiday_2018_sp] @Terr VARCHAR(1000) = NULL
AS
BEGIN

-- exec cvo_holiday_2018_sp

    DECLARE @territory VARCHAR(1000);
    SET @territory = @Terr;

    CREATE TABLE #territory
    (
        territory VARCHAR(10),
        region VARCHAR(3)
    );
    IF @territory IS NULL
    BEGIN
        INSERT INTO #territory
        (
            territory,
            region
        )
        SELECT DISTINCT
               territory_code,
               dbo.calculate_region_fn(territory_code) region
        FROM armaster (NOLOCK)
        WHERE status_type = 1; -- active accounts only
    END;
    ELSE
    BEGIN
        INSERT INTO #territory
        (
            territory,
            region
        )
        SELECT ListItem,
               dbo.calculate_region_fn(ListItem) region
        FROM dbo.f_comma_list_to_table(@territory);
    END;

    SELECT t.region,
           t.territory,
           ar.customer_code,
           ar.ship_to_code,
           ar.address_name,
           ar.contact_name, ar.contact_phone, ar.contact_email,
           MAX(sd.yyyymmdd) ship_date,
           SUM(ISNULL(sd.qnet,0)) qty_shipped
    FROM #territory AS t
        JOIN armaster ar (NOLOCK)
            ON ar.territory_code = t.territory
        JOIN cvo_sbm_details sd (NOLOCK)
            ON ar.customer_code = sd.customer
               AND ar.ship_to_code = sd.ship_to
        JOIN inv_master i (NOLOCK)
            ON sd.part_no = i.part_no
    WHERE i.part_no = 'CVZHOLN2018'
    GROUP BY t.region,
             t.territory,
             ar.customer_code,
             ar.ship_to_code,
             ar.address_name,
             ar.contact_name, ar.contact_phone, ar.contact_email;

END;

GO
GRANT EXECUTE ON  [dbo].[cvo_holiday_2018_sp] TO [public]
GO
