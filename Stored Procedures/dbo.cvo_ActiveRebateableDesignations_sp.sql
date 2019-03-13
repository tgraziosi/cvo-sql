SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_ActiveRebateableDesignations_sp]  @single_email INT = 0
AS

BEGIN

SET NOCOUNT ON

DECLARE @lastcust VARCHAR(5),                 
        @emails VARCHAR(1024) ;

--select * FRom cvo_activerebateabledesignations_vw
IF (OBJECT_ID('tempdb.dbo.#email') IS NOT NULL)
    DROP TABLE #email;
CREATE TABLE #email
( mergecust VARCHAR(10),
  contact_email VARCHAR(255),
  email_id INT
  )
IF (OBJECT_ID('tempdb.dbo.#single_email') IS NOT NULL)
    DROP TABLE #single_email;
CREATE TABLE #single_email
( mergecust VARCHAR(10),
  contact_email VARCHAR(255),
  email_id INT
  )

INSERT #email
(
    mergecust,
    contact_email,
    email_id
)
SELECT DISTINCT email.mergecust,
       CAST(email.contact_email AS VARCHAR(255)) contact_email,
       0 email_id
FROM
(
    SELECT DISTINCT
           RIGHT(customer_code, 5) mergecust,
           contact_email
    FROM armaster
    WHERE CHARINDEX('@', contact_email) > 0
    UNION
    SELECT DISTINCT
           RIGHT(customer_code, 5) mergecust,
           contact_email
    FROM adm_arcontacts
    WHERE CHARINDEX('@', contact_email) > 0
          AND contact_code = 'Dr.'
) email;

-- do some clean up

UPDATE #email SET contact_email = REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(contact_email)),' ',','),';',','),',,',',')

-- parse out multiple emails
INSERT #single_email
(
    mergecust,
    contact_email,
    email_id
)
SELECT DISTINCT
       mergecust,
       contact_email,
       0 AS email_id
FROM #email
WHERE CHARINDEX(',', contact_email, 1) > 0;

DELETE FROM #email
WHERE CHARINDEX(',', contact_email, 1) > 0;


-- SELECT * FROM #single_email AS se

-- SELECT contact_email, * FROM armaster WHERE customer_code = '016776'


--DECLARE @lastcust VARCHAR(5),                 
--        @emails VARCHAR(1024) ;
--        SET XACT_ABORT ON 

        SELECT @lastcust = MIN(mergecust)
        FROM   #single_email AS se;

        WHILE @lastcust IS NOT NULL
            BEGIN

                -- SELECT @lastcust

                SELECT @emails = se.contact_email
                FROM   #single_email AS se
                WHERE  se.mergecust = @lastcust;

                INSERT #email ( mergecust ,
                                contact_email ,
                                email_id )
                       SELECT @lastcust ,
                              LTRIM(RTRIM(ListItem)) ,
                              0
                       FROM   dbo.f_comma_list_to_table(@emails)
                       WHERE CHARINDEX('@',ListItem,1) > 0;

                       --SELECT * FROM #single_email AS se WHERE se.mergecust = '16776'
                       --SELECT * FROM dbo.f_comma_list_to_table((SELECT TOP (1) contact_email FROM #single_email WHERE mergecust = '16776'))

                SELECT @lastcust = MIN(mergecust)
                FROM   #single_email AS se
                WHERE  mergecust > @lastcust;

            END;


UPDATE ee
SET ee.email_id = e_id.email_id
FROM #email ee
    JOIN
    (
        SELECT e.mergecust,
               e.contact_email,
               -- DENSE_RANK() OVER ( PARTITION BY e.contact_email
               ROW_NUMBER() OVER (PARTITION BY e.contact_email ORDER BY contact_email ASC) email_id
        FROM #email AS e
    ) e_id
        ON e_id.contact_email = ee.contact_email
           AND e_id.mergecust = ee.mergecust;

;WITH report
AS (SELECT DISTINCT
           ar.territory_code,
           ar.customer_code,
           ar.address_name,
           ar.addr2,
           CASE
               WHEN ar.addr3 LIKE '%, __ %' THEN
                   ''
               ELSE
                   ar.addr3
           END AS addr3,
           city,
           state,
           postal_code AS Zip,
           country_code AS CC,
           ar.contact_email,
           ar.price_code price_class, -- 042015 - LF request
           ISNULL(Pri_desig.desig, '') Primary_Designation,
           ISNULL(REPLACE(STUFF(
                          (
                              SELECT '; ' + dc.description
                              FROM cvo_cust_designation_codes (NOLOCK) cd
                                  JOIN dbo.cvo_designation_codes dc
                                      ON dc.rebate = 'Y'
                                         AND dc.code = cd.code
                              WHERE cd.customer_code = ar.customer_code
                                    AND ISNULL(cd.start_date, GETDATE()) <= GETDATE()
                                    AND ISNULL(cd.end_date, GETDATE()) >= GETDATE()
                                    AND cd.primary_flag <> 1
                                    AND dc.rebate = 'Y'
                              FOR XML PATH('')
                          ),
                          1,
                          1,
                          ''
                               ),
                          '&amp;',
                          '&'
                         ),
                  ''
                 ) Active_Rebateable_Designations,
           GETDATE() asofdate
    FROM dbo.armaster AS ar
        LEFT OUTER JOIN
        (
            SELECT DISTINCT
                   RIGHT(cd.customer_code, 5) MergeCust,
                   dc2.description desig
            FROM cvo_cust_designation_codes (NOLOCK) cd
                JOIN dbo.cvo_designation_codes AS dc2
                    ON dc2.code = cd.code
            WHERE cd.primary_flag = 1
                  AND ISNULL(cd.start_date, GETDATE()) <= GETDATE()
                  AND ISNULL(cd.end_date, GETDATE()) >= GETDATE()
        ) AS Pri_desig
            ON Pri_desig.MergeCust = RIGHT(ar.customer_code, 5)
    WHERE (ar.address_type = 0)
-- ORDER BY ar.customer_code
),
      emails
AS (SELECT DISTINCT
           e.mergecust,
           STUFF(
           (
               SELECT DISTINCT
                      ';' + ee.contact_email
               FROM #email AS ee
               WHERE ee.mergecust = e.mergecust
               FOR XML PATH('')
           ),
           1,
           1,
           ''
                ) contact_emails,
           email_each = CASE
                            WHEN @single_email = 1 THEN
                                e.contact_email
                            ELSE
                                ''
                        END,
           email_id = CASE
                          WHEN @single_email = 1 THEN
                              e.email_id
                          ELSE
                              0
                      END
    FROM #email e)

SELECT report.territory_code,
       report.customer_code,
       report.address_name,
       report.addr2,
       report.addr3,
       report.city,
       report.state,
       report.Zip,
       report.CC,
       report.price_class,
       report.Primary_Designation,
       report.Active_Rebateable_Designations,
       report.asofdate,
       ISNULL(emails.contact_emails,'') contact_emails,
       ISNULL(emails.email_each,'') email_each,
       ISNULL(emails.email_id,'') email_id
FROM report
    LEFT OUTER JOIN emails
        ON emails.mergecust = RIGHT(report.customer_code, 5)
        where (report.Primary_Designation <> '' OR report.Active_Rebateable_Designations <> '');


END



GO
GRANT EXECUTE ON  [dbo].[cvo_ActiveRebateableDesignations_sp] TO [public]
GO
