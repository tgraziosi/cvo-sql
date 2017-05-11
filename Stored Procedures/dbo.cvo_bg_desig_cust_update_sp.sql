SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_bg_desig_cust_update_sp]
AS
    SET NOCOUNT ON
    ;

    IF (OBJECT_ID('tempdb.dbo.#DS') IS NOT NULL)
        DROP TABLE #DS
        ;
    SELECT
        customer_code AS DesCust,
        code,
        description,
        start_date,
        end_date,
        CASE
            WHEN code = 'bbg' THEN
                502
            WHEN code LIKE 'fec-%' THEN
                550
            WHEN code = 'VWEST' THEN
                563
            WHEN code = 'VILLA' THEN
                549
            WHEN code = 'OOGP' THEN
                542
            WHEN code = 'ADO1' THEN
                500
        END AS BGCODE
    INTO #DS
    FROM cvo_cust_designation_codes t1
    WHERE
        code IN ( 'VWEST', 'VILLA', 'FEC-M', 'FEC-A', 'BBG', 'OOGP' )
    ;
    --and (end_date is null OR end_date >= getdate() )
    -- SELECT * FROM #DS
    --
    IF (OBJECT_ID('tempdb.dbo.#DATA') IS NOT NULL)
        DROP TABLE #DATA
        ;
    SELECT *
    INTO #DATA
    FROM
    (
        SELECT
            'AddDesig' AS Action,
            t1.*,
            CASE
                WHEN T2.parent = '000502' THEN
                    'BBG'
                WHEN T2.parent = '000502' THEN
                    'FEC'
                WHEN T2.parent = '000563' THEN
                    'VWEST'
                WHEN T2.parent = '000549' THEN
                    'VILLA'
                WHEN T2.parent = '000542' THEN
                    'OOGP'
                WHEN T2.parent = '000500' THEN
                    'ADO1'
            END AS GROUP_NAME,
            T2.parent AS AR_Parent,
            child AS AR_Child,
            T3.address_name,
            T3.territory_code AS Terr
        FROM
            #DS t1
            FULL OUTER JOIN arnarel T2
                ON t1.DesCust = T2.child
                   AND t1.BGCODE = T2.parent
            JOIN armaster T3
                ON T2.child = T3.customer_code
        WHERE
            parent IN ( 502, 550, 563, 549, 542 )
            AND T3.address_type = 0
            AND
            (
                DesCust IS NULL
                OR child IS NULL
            )
        UNION ALL
        SELECT
            'EndDesig' AS Action,
            t1.DesCust,
            t1.code,
            t1.description,
            t1.start_date,
            t1.end_date,
            t1.BGCODE,
            CASE
                WHEN T2.parent = '000502' THEN
                    'BBG'
                WHEN T2.parent = '000502' THEN
                    'FEC'
                WHEN T2.parent = '000563' THEN
                    'VWEST'
                WHEN T2.parent = '000549' THEN
                    'VILLA'
                WHEN T2.parent = '000542' THEN
                    'OOGP'
                WHEN T2.parent = '000500' THEN
                    'ADO1'
            END AS GROUP_NAME,
            T2.parent AS AR_Parent,
            child AS AR_Child,
            T3.address_name,
            T3.territory_code AS Terr
        FROM
            #DS t1
            FULL OUTER JOIN arnarel T2
                ON t1.DesCust = T2.child
                   AND t1.BGCODE = T2.parent
            JOIN armaster T3
                ON t1.DesCust = T3.customer_code
        WHERE
            code IN ( 'bbg', 'fec', 'vwest', 'villa', 'OOGP', 'ADO1' )
            AND T3.address_type = 0
            AND t1.end_date IS NULL
            AND
            (
                DesCust IS NULL
                OR child IS NULL
            )
    ) tmp
    ;

    SELECT
        t1.Action,
        t1.BGCODE,
        t1.end_date,
        t1.start_date,
        t1.description,
        t1.code,
        t1.DesCust,
        t1.GROUP_NAME,
        t1.AR_Parent,
        t1.AR_Child,
        t1.address_name,
        t1.Terr,
        ISNULL(
        (
            SELECT code
            FROM cvo_cust_designation_codes t2
            WHERE
                ISNULL(t1.DesCust, t1.AR_Child) = t2.customer_code
                AND primary_flag = 1
                AND
                (
                    end_date IS NULL
                    OR end_date <= GETDATE()
                )
        ),
                  ''
              ) CurPrimary,
        (
            SELECT COUNT(customer_code)
            FROM
                cvo_cust_designation_codes t2
                JOIN cvo_designation_codes t3
                    ON t2.code = t3.code
            WHERE
                ISNULL(t1.DesCust, t1.AR_Child) = t2.customer_code
                AND t3.rebate = 'y'
                AND
                (
                    end_date IS NULL
                    OR end_date <= GETDATE()
                )
                AND t2.code <> ISNULL(t1.code,
                                         ISNULL(
                                         (
                                             SELECT code
                                             FROM cvo_cust_designation_codes t2
                                             WHERE
                                                 ISNULL(t1.DesCust, t1.AR_Child) = t2.customer_code
                                                 AND primary_flag = 1
                                                 AND
                                                 (
                                                     end_date IS NULL
                                                     OR end_date <= GETDATE()
                                                 )
                                         ),
                                                   ''
                                               )
                                     )
        ) NumOtherPossPrimary
    FROM #DATA t1
    ;


    -- -- INSERT NEW DESIGNATIONS
    INSERT INTO cvo_cust_designation_codes
    (
        customer_code, code, description, date_reqd, start_date, end_date, primary_flag
    )
    SELECT
        AR_Child AS CUSTOMER_CODE,
        GROUP_NAME AS CODE,
        (
            SELECT description
            FROM cvo_designation_codes t2
            WHERE t1.group_name = t2.code
        ) AS DESCRIPTION,
        1 AS date_reqd,
        DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())) AS START_DATE,
        NULL AS END_DATE,
        CASE
            WHEN
        (
            SELECT COUNT(customer_code)
            FROM cvo_cust_designation_codes T11
            WHERE
                T1.AR_CHILD = T11.customer_code
                AND primary_flag = 1
        ) >= 1 THEN
                0
            ELSE
                1
        END AS PRIMARY_FLAG
    FROM #DATA T1
    WHERE GROUP_NAME IS NOT NULL
    ;

    -- -- SET END DATE FOR ENDING DESIGNATIONS
    UPDATE T1
    SET end_date = DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE()))
    FROM cvo_cust_designation_codes T1
    WHERE
        code IN
        (
            SELECT DISTINCT code FROM #DATA
        )
        AND customer_code IN
            (
                SELECT DISTINCT DesCust FROM #DATA
            )
        AND end_date IS NULL
    ;
GO
