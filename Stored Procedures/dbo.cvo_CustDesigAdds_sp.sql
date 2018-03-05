SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_CustDesigAdds_sp]
    @start DATETIME,
    @end DATETIME

AS

-- exec cvo_custdesigadds_sp '8/6/2016', '8/16/2016'

BEGIN

    SET NOCOUNT ON;

    SET ANSI_WARNINGS OFF;

    IF (OBJECT_ID('tempdb.dbo.#tbl1') IS NOT NULL)
        DROP TABLE dbo.#tbl1;

    SELECT t2.territory_code AS Terr,
           t2.customer_code,
           t2.contact_name,
           t2.address_name,
           t2.addr2,
           CASE WHEN t2.addr3 LIKE '%, __ %' THEN '' ELSE t2.addr3 END AS addr3,
           t2.city,
           t2.state,
           t2.postal_code AS zip,
           CASE WHEN t2.contact_email NOT LIKE '%@%.%' THEN '' ELSE LOWER(t2.contact_email) END AS Email,
           t1.code,
           t1.description,
           t1.start_date,
           t1.end_date,
           STUFF((
                 SELECT '; ' + c.code
                 FROM dbo.cvo_cust_designation_codes (NOLOCK) c
                 WHERE c.customer_code = t2.customer_code
                       AND (
                           c.start_date IS NULL
                           OR c.start_date <= GETDATE()
                           )
                       AND (
                           c.end_date IS NULL
                           OR c.end_date >= GETDATE()
                           )
                 FOR XML PATH('')
                 ),
                 1,
                 1,
                 ''
                ) AS ActiveDesig,
           pri_desig.code CurrPri,
           pri_desig.description CurrPriDescription
    INTO #tbl1
    FROM dbo.cvo_cust_designation_codes t1 (NOLOCK)
        JOIN dbo.armaster t2 (NOLOCK)
            ON t2.customer_code = t1.customer_code
        LEFT OUTER JOIN
        (
        SELECT DISTINCT
               cdc.customer_code,
               code,
               description
        FROM dbo.cvo_cust_designation_codes AS cdc
        WHERE cdc.primary_flag = 1
              -- AND ISNULL(end_date, GETDATE()) >= GETDATE()
              AND ISNULL(end_date, @end) >= @end
        ) pri_desig
            ON pri_desig.customer_code = t1.customer_code
    WHERE
        --( t1.start_date > DATEADD(d, -7, GETDATE())
        --        OR t1.end_date BETWEEN DATEADD(d, -7, GETDATE()) AND GETDATE()
        --      )
        (
        t1.start_date >= @start
        OR t1.end_date
        BETWEEN @start AND @end
        )
        AND t2.address_type = 0
        AND (
            t1.code IN ( 'Opt-1', 'IDOC', 'VT', 'FEC', 'TSO', 'IVA', 'RXE', 'RX3', 'RX5' )
            OR t1.code LIKE 'BB%'
            OR t1.code LIKE 'I-%'
            );


    SELECT DISTINCT
           t1.Terr,
           t1.customer_code,
           t1.contact_name,
           t1.address_name,
           t1.addr2,
           t1.addr3,
           t1.city,
           t1.state,
           t1.zip,
           t1.Email,
           t1.code,
           t1.description,
           t1.start_date,
           t1.end_date,
           t1.ActiveDesig,
           t1.CurrPri,
           t1.CurrPriDescription,
           (
           SELECT TOP (1)
                  Item
           FROM dbo.cvo_cust_designation_codes_audit t3
           WHERE t1.customer_code = t3.customer_code
                 AND t1.code = t3.code
           ORDER BY Audit_Date DESC
           ) Movement,
           (
           SELECT TOP (1)
                  Audit_Date
           FROM DBO.cvo_cust_designation_codes_audit t3
           WHERE t1.customer_code = t3.customer_code
                 AND t1.code = t3.code
           ORDER BY Audit_Date DESC
           ) DesigAuditDate,
           CASE WHEN (
                     SELECT TOP 1
                            User_ID
                     FROM DBO.cvo_cust_designation_codes_audit t3
                     WHERE t1.customer_code = t3.customer_code
                           AND t1.code = t3.code
                     ORDER BY Audit_Date DESC
                     ) = 'SA' THEN 'SYSTEM ADMIN'
               WHEN (
                    SELECT TOP (1)
                           User_ID
                    FROM DBO.cvo_cust_designation_codes_audit t3
                    WHERE t1.customer_code = t3.customer_code
                          AND t1.code = t3.code
                    ORDER BY Audit_Date DESC
                    ) = 'NT AUTHORITY\SYSTEM' THEN 'SYSTEM ADMIN' ELSE (
                                                                       SELECT TOP (1)
                                                                              User_ID
                                                                       FROM DBO.cvo_cust_designation_codes_audit t3
                                                                       WHERE t1.customer_code = t3.customer_code
                                                                             AND t1.code = t3.code
                                                                       ORDER BY Audit_Date DESC
                                                                       )
           END AS DesigUserMod
    FROM #tbl1 t1
    ORDER BY t1.code,
             t1.customer_code;

END;
GO
GRANT EXECUTE ON  [dbo].[cvo_CustDesigAdds_sp] TO [public]
GO
