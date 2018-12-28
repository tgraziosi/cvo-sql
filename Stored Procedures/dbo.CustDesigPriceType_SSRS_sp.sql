SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		ELABARBERA
-- Create date: 3/25/2013
-- Description:	Listing of Customers in Designation Codes that do not match appropriate Discount Price Types
-- EXEC CustDesigPriceType_SSRS_sp
-- =============================================
CREATE PROCEDURE [dbo].[CustDesigPriceType_SSRS_sp]
AS
    BEGIN

        SET NOCOUNT ON;

-- Get Designation Codes, into one field  (Where Designations date range is in report date range
        IF ( OBJECT_ID('tempdb.dbo.#CustDesig') IS NOT NULL )
            DROP TABLE dbo.#CustDesig;
            WITH    C AS ( SELECT   customer_code ,
                                    code
                           FROM     cvo_cust_designation_codes (NOLOCK)
                         )
            SELECT DISTINCT
                    customer_code ,
                    STUFF(( SELECT  '; ' + code
                            FROM    cvo_cust_designation_codes (NOLOCK)
                            WHERE   customer_code = C.customer_code
                                    AND ( end_date IS NULL
                                          OR end_date >= GETDATE()
                                        )
                          FOR
                            XML PATH('')
                          ), 1, 1, '') AS Desigs
            INTO    #CustDesig
            FROM    C;
--  select * from #CustDesig

        DECLARE @BBCODE VARCHAR(5);
        SET @BBCODE = 'BB' + RIGHT(DATEPART(YEAR, GETDATE()), 2);

        IF ( OBJECT_ID('tempdb.dbo.#CustMatch') IS NOT NULL )
            DROP TABLE dbo.#CustMatch;
        SELECT  CASE WHEN status_type = '1' THEN 'Active'
                     ELSE 'INActive'
                END AS Status ,
                territory_code ,
                t1.customer_code ,
                address_name ,
                addr2 ,
                CASE WHEN addr3 LIKE '%, __ %' THEN ''
                     ELSE addr3
                END AS addr3 ,
                city ,
                state ,
                postal_code AS zip ,
                price_code ,
                tt.rebate ,
                t1.code AS PriCode ,
                Desigs AS AllDesigs ,
                CASE WHEN t4.parent = t1.customer_code THEN ''
                     ELSE parent
                END AS PARENT ,
                added_by_user_name ,
                added_by_date ,
                CASE WHEN modified_by_user_name BETWEEN '1' AND '900'
                     THEN USER_NAME
                     ELSE ISNULL(modified_by_user_name, '')
                END AS modified_by_user_name ,
                modified_by_date
        INTO    #CustMatch
        FROM    cvo_cust_designation_codes (NOLOCK) t1
                JOIN cvo_designation_codes (NOLOCK) tt ON t1.code = tt.code
                JOIN armaster_all (NOLOCK) t2 ON t1.customer_code = t2.customer_code
                JOIN #CustDesig t3 ON t1.customer_code = t3.customer_code
                JOIN artierrl (NOLOCK) t4 ON t1.customer_code = t4.rel_cust
                LEFT OUTER JOIN CVO_Control..SMUSERS T5 ON RTRIM(t2.modified_by_user_name) = CAST(T5.USER_ID AS VARCHAR(30))
        WHERE   t2.address_type = 0
                AND tt.rebate = 'y'
                AND ( end_date IS NULL
                      OR end_date >= GETDATE()
                    )
                AND ( ( t1.code LIKE '%opt%'
                        AND price_code <> 'O'
                        AND t1.customer_code = t4.parent
                      )
                      OR ( t1.code LIKE 'i-%'
                           AND price_code NOT IN ( 'B', 'D', 'D1' )
                         )
                      OR ( t1.code IN ( 'VWEST', 'VILLA', 'FEC-M', 'FEC-A', 'BBG' )
                           AND price_code NOT IN ( 'D', 'D1' )
                         )
                      OR ( t1.code IN ( 'PRI', 'VT', 'OOGP', 'FEC-A', 'BBG' )
                           AND price_code NOT IN ( 'D', 'D1' )
                         )
                      OR ( t1.code LIKE '%@BBCode%'
                           AND price_code <> 'D'
                         )
                      OR ( t1.code LIKE '%PEARLE%'
                           AND price_code <> 'P'
                           AND t1.customer_code = t4.parent
                         ) -- 7/8/2016 PER MS REQUEST - 8/22/2016 - only if not in BG
                      OR (t1.code = 'TPG'       
                            AND price_code <> 'D'
                         ) -- 11/15/2018 per JB request
                    )
                AND primary_flag = 1
        ORDER BY t1.customer_code ,
                t1.code;

        DELETE  FROM #CustMatch
        WHERE   PriCode LIKE 'FEC%'
                AND PARENT <> '000550';
-- SELECT * FROM #CustMatch

        IF ( OBJECT_ID('tempdb.dbo.#ContrCust') IS NOT NULL )
            DROP TABLE dbo.#ContrCust;
        SELECT DISTINCT
                customer_key
        INTO    #ContrCust
        FROM    c_quote
        WHERE   ship_to_no <> '*type*'
                AND ( date_expires IS NULL
                      OR date_expires > GETDATE()
                    );

        SELECT DISTINCT
                t1.* ,
                ISNULL(ROUND(( SELECT   SUM(anet)
                               FROM     dbo.cvo_sbm_details t2
                               WHERE    t1.customer_code = t2.customer
                                        AND t2.year = DATEPART(YEAR,
                                                              GETDATE() - 1)
                             ), 2), '') LY_TYD_NetSales ,
                ISNULL(ROUND(( SELECT   SUM(anet)
                               FROM     dbo.cvo_sbm_details t2
                               WHERE    t1.customer_code = t2.customer
                                        AND t2.yyyymmdd BETWEEN DATEADD(YEAR,
                                                              -1, GETDATE())
                                                        AND   GETDATE()
                             ), 2), '') R12_NetSales ,
                CASE WHEN customer_key IS NOT NULL THEN 'Y'
                     ELSE ''
                END AS 'CntrPrc' ,
                ( SELECT TOP 1
                            Audit_Date
                  FROM      cvo_cust_designation_codes_audit DCA
                  WHERE     DCA.customer_code = t1.customer_code
                  ORDER BY  Audit_Date DESC
                ) AS DesigAuditDate ,
                ( SELECT TOP 1
                            User_ID
                  FROM      cvo_cust_designation_codes_audit DCA
                  WHERE     DCA.customer_code = t1.customer_code
                  ORDER BY  Audit_Date DESC
                ) AS DesigUserMod ,
                ( SELECT TOP 1
                            field_from
                  FROM      CVOARMasterAudit CAA
                  WHERE     CAA.field_name = 'Price_Code'
                            AND CAA.customer_code = t1.customer_code
                  ORDER BY  audit_date DESC
                ) AS PriceFrom ,
                ( SELECT TOP 1
                            field_to
                  FROM      CVOARMasterAudit CAA
                  WHERE     CAA.field_name = 'Price_Code'
                            AND CAA.customer_code = t1.customer_code
                  ORDER BY  audit_date DESC
                ) AS PriceTo ,
                ( SELECT TOP 1
                            user_id
                  FROM      CVOARMasterAudit CAA
                  WHERE     CAA.field_name = 'Price_Code'
                            AND CAA.customer_code = t1.customer_code
                  ORDER BY  audit_date DESC
                ) AS PriceUserMod ,
                ( SELECT TOP 1
                            audit_date
                  FROM      CVOARMasterAudit CAA
                  WHERE     CAA.field_name = 'Price_Code'
                            AND CAA.customer_code = t1.customer_code
                  ORDER BY  audit_date DESC
                ) AS PriceAuditDate
        FROM    #CustMatch t1
                LEFT JOIN #ContrCust t3 ON t1.customer_code = t3.customer_key
        ORDER BY PriCode ,
                price_code;

-- EXEC CustDesigPriceType_SSRS_sp

    END;





GO
