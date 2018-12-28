SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_terr_list_for_username_sp]
AS
BEGIN
    
    -- Used for Power BI RLS security to filter valid territories for a user

    SET NOCOUNT ON;
    WITH XREF
    AS (SELECT CAST(dbo.calculate_region_fn(territory_code) AS CHAR(3)) REGION,
               territory_code,
               Salesperson_code,
               User_name username,
               REPLACE(User_name,'cvoptical\','')+'@cvoptical.local' email_address,
               user_type
        FROM dbo.CVO_TerritoryXref
        WHERE Status = 1),
         RSM
    AS (SELECT REGION,
               territory_code,
               Salesperson_code,
               username,
               x.email_address,
               user_type
        FROM XREF x
        WHERE user_type = 'RSM'),
         SLP
    AS (SELECT REGION,
               territory_code,
               Salesperson_code,
               username,
               x.email_address,
               user_type
        FROM XREF x
        WHERE user_type = 'SLP'),
         SS
    AS (SELECT REGION,
               territory_code,
               Salesperson_code,
               username,
               x.email_address,
               user_type
        FROM XREF x
        WHERE x.Salesperson_code = 'SS'),
         ALLTERR
    AS (SELECT REGION,
               territory_code,
               Salesperson_code,
               username,
               XREF.email_address,
               user_type
        FROM XREF
        WHERE Salesperson_code IN ( 'iNTERNAL', 'CS', 'KA', 'IS' ))
    SELECT DISTINCT
           a.territory_code,
           ALLTERR.username,
           ALLTERR.email_address
    FROM ALLTERR
        CROSS JOIN dbo.arterr AS a (NOLOCK)
    WHERE a.territory_code <> 'ter00001'
          AND EXISTS
    (
        SELECT 1 FROM armaster ar WHERE ar.territory_code = a.territory_code
    )
    UNION ALL
    SELECT DISTINCT
           SLP.territory_code,
           RSM.username,
           RSM.email_address
    FROM RSM
        LEFT OUTER JOIN SLP
            ON SLP.REGION = RSM.REGION
    UNION ALL
    SELECT DISTINCT
           SLP.territory_code,
           SLP.username,
           SLP.email_address
    FROM SLP
    UNION ALL
    SELECT DISTINCT
           a.territory_code,
           SS.username,
           SS.email_address
    FROM SS
        CROSS JOIN dbo.arterr AS a (NOLOCK)
    WHERE a.territory_code
          BETWEEN '20000' AND '79999'
          AND EXISTS
    (
        SELECT 1
        FROM armaster ar (NOLOCK)
        WHERE ar.territory_code = a.territory_code
    );

END;

GRANT EXECUTE ON dbo.cvo_terr_list_for_username_sp TO PUBLIC;
GO
GRANT EXECUTE ON  [dbo].[cvo_terr_list_for_username_sp] TO [public]
GO
