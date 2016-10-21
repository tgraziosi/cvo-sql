SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 6/3/2013
-- Description:	List Customers and Designations with no Primary
-- EXEC CVO_Cust_NoPriDesigDet_ssrs_SP 
-- =============================================
CREATE PROCEDURE [dbo].[CVO_Cust_NoPriDesigDet_ssrs_SP]
AS
    BEGIN
        SET NOCOUNT ON;

        SELECT DISTINCT
                t3.address_name AS CustName ,
                t1.customer_code ,
                t1.code ,
                t1.description ,
                t1.date_reqd ,
                t1.start_date ,
                t1.end_date ,
                t1.primary_flag ,
                ROW_NUMBER() OVER ( PARTITION BY t1.customer_code ORDER BY t1.customer_code, t1.code ) AS Num ,
                ISNULL(( SELECT parent
                         FROM   arnarel t2
                         WHERE  t1.customer_code = t2.child
                       ), '') AS Parent ,
                t3.territory_code AS Terr ,
                ( SELECT    SUM(rolling12net)
                  FROM      cvo_rad_shipto t2
                  WHERE     t1.customer_code = t2.customer
                            AND t2.yyyymmdd = CONVERT(VARCHAR(25), DATEADD(dd,
                                                              -( DAY(GETDATE())
                                                              - 1 ), GETDATE()), 101)
                ) AS R12 ,
                t3.price_code ,
                a.Item ,
                a.Audit_Date ,
                a.User_ID AS UpdateUser
--(SELECT ITEM FROM cvo_cust_designation_codes_audit a where a.id = ca.id) as ITEM,
--(SELECT Audit_Date FROM cvo_cust_designation_codes_audit a WHERE a.id = ca.id) as AUDIT_DATE,
--(SELECT user_ID FROM cvo_cust_designation_codes_audit a WHERE a.id=ca.id) as UpdateUser
        FROM    cvo_cust_designation_codes t1
                JOIN cvo_designation_codes t2 ON t1.code = t2.code
                JOIN armaster t3 ON t1.customer_code = t3.customer_code
                LEFT OUTER JOIN ( SELECT    customer_code ,
                                            MAX(ID) id
                                  FROM      cvo_cust_designation_codes_audit
                                  GROUP BY  customer_code
                                ) ca ON ca.customer_code = t1.customer_code
                LEFT OUTER JOIN dbo.cvo_cust_designation_codes_audit AS a ON a.ID = ca.id
        WHERE   t1.customer_code IN (
                SELECT  customer_code
                FROM    cvo_cust_designation_codes t1
                        JOIN cvo_designation_codes t2 ON t1.code = t2.code
                WHERE   t2.rebate = 'y'
                GROUP BY customer_code
                HAVING  SUM(primary_flag) = 0 )
                AND t3.address_type = 0
                AND t2.rebate = 'y'
                AND ( end_date IS NULL
                      OR end_date > GETDATE()
                    )
        ORDER BY customer_code ,
                code;

    END;




GO
