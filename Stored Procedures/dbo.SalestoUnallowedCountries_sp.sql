SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		elabarbera
-- Create date: 2/25/2013
-- Description:	By Brand Do Not Sell To Country Report
-- EXEC salestounallowedcountries_sp '6/12/2017', '04/4/2018'
-- EXEC dbo.SSRS_BrandDoNotSellToCountry_sp '6/12/2017', '04/4/2018'

-- 022015 - OP ok's sales to Ecuador and El Salvador
-- 123015 - Add Bermuda ME and Guatemala ET as ok to sell
-- 093016 - add customer name per BL request
-- 021617 - ADD REVO AND sm 
-- =============================================
CREATE PROCEDURE [dbo].[SalestoUnallowedCountries_sp]
    @DateFrom DATETIME ,
    @DateTo DATETIME
AS
    BEGIN
        SET NOCOUNT ON;

-- 2013 do not sell to counties list
--DECLARE @DateFrom DATETIME
--DECLARE @DateTo DATETIME
--SET @F = Convert(varchar(10),getdate() -1,101)
--SET @T = DATEADD(MINUTE,-1,DATEADD(D,1,@F))

        IF ( OBJECT_ID('TEMP.DBO.#LIST') IS NOT NULL )
            DROP TABLE #LIST;
        SELECT DISTINCT
                ship_to_country_cd AS Ctry ,
                t4.description ,
                category AS Brand ,
                t1.type ,
                t1.status ,
                t1.order_no ,
                t1.ext ,
                cust_code ,
                t1.ship_to ,
                t1.ship_to_name ,
                ship_to_region ,
                date_entered ,
                date_shipped ,
                total_amt_order ,
                SUM(ordered) QtyOrd ,
                SUM(shipped) QtyShip,
				isr.pa
        INTO    #LIST
        FROM    orders_all t1 ( NOLOCK )
                JOIN ord_list t2 ( NOLOCK ) ON t1.order_no = t2.order_no
                                               AND t1.ext = t2.order_ext
                JOIN inv_master t3 ( NOLOCK ) ON t2.part_no = t3.part_no
                JOIN gl_country t4 ( NOLOCK ) ON t4.country_code = t1.ship_to_country_cd
				LEFT OUTER JOIN dbo.cvo_intl_sell_rights AS isr (NOLOCK) ON isr.country_code = t4.country_code AND isr.brand = t3.category

        WHERE   t1.status <> 'v'
                AND t1.type = 'i'
				AND t3.category IN ('et','op','izod','revo','sm','jmc')
                AND date_entered BETWEEN @DateFrom AND @DateTo

        GROUP BY ship_to_country_cd ,
                t4.description ,
                category ,
                t1.type ,
                t1.status ,
                t1.order_no ,
                t1.ext ,
                cust_code ,
                t1.ship_to ,
				t1.ship_to_name,
				ship_to_region ,
                date_entered ,
                date_shipped ,
                total_amt_order,
				isr.pa
				;


        SELECT  Ctry ,
                description ,
                l.Brand ,
                type ,
                status ,
                order_no ,
                ext ,
                cust_code ,
                ship_to ,
				ship_to_name,
                ship_to_region ,
                date_entered ,
				CASE WHEN ISNULL(l.pa,0) = 1 THEN 'PA' ELSE '' end AS NeedsApproval,
                date_shipped ,
                total_amt_order ,
                QtyOrd ,
                QtyShip,
				l.pa
        FROM    #LIST l
				WHERE 1 = ISNULL(l.pa,1)
				ORDER BY ctry, brand, l.date_entered DESC
                

				;

    END;








GO
GRANT EXECUTE ON  [dbo].[SalestoUnallowedCountries_sp] TO [public]
GO
