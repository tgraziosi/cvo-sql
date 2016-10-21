SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		elabarbera
-- Create date: 2/25/2013
-- Description:	By Brand Do Not Sell To Country Report
-- EXEC SSRS_BrandDoNotSellToCountry_sp '4/1/2014','6/1/2014'
-- 022015 - OP ok's sales to Ecuador and El Salvador
-- 123015 - Add Bermuda ME and Guatemala ET as ok to sell
-- 093016 - add customer name per BL request
-- =============================================
CREATE PROCEDURE [dbo].[SSRS_BrandDoNotSellToCountry_sp]
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
                SUM(shipped) QtyShip
        INTO    #LIST
        FROM    orders_all t1 ( NOLOCK )
                JOIN ord_list t2 ( NOLOCK ) ON t1.order_no = t2.order_no
                                               AND t1.ext = t2.order_ext
                JOIN inv_master t3 ( NOLOCK ) ON t2.part_no = t3.part_no
                JOIN gl_country t4 ( NOLOCK ) ON t4.country_code = t1.ship_to_country_cd
        WHERE   t1.status <> 'v'
                AND t1.type = 'i'
-- default list ('CH','ET','IZOD','IZX','OP','JMC','ME')
                AND ( ( ship_to_country_cd IN ( 'CF', 'ZA' )
                        AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                          'ME' )
                      )  --africa
                      OR ( ship_to_country_cd IN ( 'AI' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --anguilla
                      OR ( ship_to_country_cd IN ( 'AG' )
                           AND category IN ( 'ME' )
                         )  --antigua & barbuda (Antilles)
                      OR ( ship_to_country_cd IN ( 'AR' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP' )
                         )  --argentina
--OR (ship_to_country_cd in ('AW') and category in () )  --ARUBA  ALL
                      OR ( ship_to_country_cd IN ( 'AU' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --AUSTRALIA
                      OR ( ship_to_country_cd IN ( 'AT' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --AUSTRA
--OR (ship_to_country_cd in ('BS') and category in () )  --BAHAMAS  ALL
--OR (ship_to_country_cd in ('BB') and category in () )  --BARBADOS  ALL
                      OR ( ship_to_country_cd IN ( '' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP' )
                         )  --BARBUDA
                      OR ( ship_to_country_cd IN ( 'BE' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --BELGIUM
                      OR ( ship_to_country_cd IN ( 'BZ' )
                           AND category IN ( 'IZOD', 'IZX' )
                         )  --BELIZE
-- OR (ship_to_country_cd in ('BM') and category in ('ME') )  --BERMUDA -- all as of 123115
                      OR ( ship_to_country_cd IN ( 'BO' )
                           AND category IN ( 'ET', 'OP' )
                         )  --BOLIVIA
                      OR ( ship_to_country_cd IN ( 'BQ' )
                           AND category IN ( 'IZOD', 'IZX' )
                         )  --BONAIRE
                      OR ( ship_to_country_cd IN ( 'BR' )
                           AND category IN ( 'ET', 'OP', 'ME' )
                         )  --BRAZIL
                      OR ( ship_to_country_cd IN ( 'VG' )
                           AND category IN ( 'ME' )
                         )  -- BRITISH VIRGIN ISLANDS
                      OR ( ship_to_country_cd IN ( 'BG' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --BULGARIA 
                      OR ( ship_to_country_cd IN ( 'CA' )
                           AND category IN ( 'ME' )
                         )  --CANADA 
-- CARRIBBEAN (see individual countries)
--OR (ship_to_country_cd in ('KY') and category in () )  --CAYMAN ISL  ALL
                      OR ( ship_to_country_cd IN ( 'CL' )
                           AND category IN ( 'ET', 'OP' )
                         )  --CHILIE
                      OR ( ship_to_country_cd IN ( 'CO' )
                           AND category IN ( 'ET', 'OP' )
                         )  --COLUMBIA
-- OR (ship_to_country_cd in ('CR') and category in ('OP') )  --COSTA RICA - OP ok to CR 02/29/2016
--OR (ship_to_country_cd in ('CW') and category in () )  --curaco  ALL
                      OR ( ship_to_country_cd IN ( 'CZ' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --czech rep
                      OR ( ship_to_country_cd IN ( 'DK' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --denmark
                      OR ( ship_to_country_cd IN ( 'DM' )
                           AND category IN ( 'ME' )
                         )  --dominica (Antillies)
                      OR ( ship_to_country_cd IN ( 'DO' )
                           AND category IN ( 'ET', 'OP' )
                         )  --dominican republic
--OR (ship_to_country_cd in ('EC') and category in ('ET','OP') )  --ecuador -- 022015
--OR (ship_to_country_cd in ('SV') and category in ('OP') )  --el salvador -- 022015
                      OR ( ship_to_country_cd IN ( 'EC' )
                           AND category IN ( 'ET' )
                         )  --ecuador -- 022015
-- OR (ship_to_country_cd in ('SV') and category in () )  --el salvador all -- 022015
                      OR ( ship_to_country_cd IN ( 'EE' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --estonia 
                      OR ( ship_to_country_cd IN ( 'FI' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --finland
                      OR ( ship_to_country_cd IN ( 'Fr' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --france
                      OR ( ship_to_country_cd IN ( 'GF' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --french guiana
                      OR ( ship_to_country_cd IN ( 'DE' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --gremany
                      OR ( ship_to_country_cd IN ( 'GR' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --greece
--OR (ship_to_country_cd in ('GD') and category in () )   --grenada all
                      OR ( ship_to_country_cd IN ( 'GT' )
                           AND category IN ( 'OP' )
                         )  --guatemala
                      OR ( ship_to_country_cd IN ( 'GY' )
                           AND category IN ( 'IZOD', 'IZX' )
                         )  --guyana
                      OR ( ship_to_country_cd IN ( 'HT' )
                           AND category IN ( 'IZOD', 'IZX' )
                         )  --haiti
                      OR ( ship_to_country_cd IN ( 'HN' )
                           AND category IN ( 'ET', 'OP' )
                         )  --honduras
                      OR ( ship_to_country_cd IN ( 'HU' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --hungry
                      OR ( ship_to_country_cd IN ( 'IE' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --IRELAND
                      OR ( ship_to_country_cd IN ( 'IT' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --ITALY
--OR (ship_to_country_cd in ('JM') and category in () )  --JAMAICA  ALL
                      OR ( ship_to_country_cd IN ( 'JP' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --JAPAN
                      OR ( ship_to_country_cd IN ( 'LV' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --LATVIA
                      OR ( ship_to_country_cd IN ( 'LT' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --LITHUANIA
                      OR ( ship_to_country_cd IN ( 'LU' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --LUXEMBOURG
                      OR ( ship_to_country_cd IN ( 'MT' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --MALTA
--OR (ship_to_country_cd in ('MX') and category in () ) -- MEXCO ALL
                      OR ( ship_to_country_cd IN ( 'NL' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --NETHERLANDS
                      OR ( ship_to_country_cd IN ( 'NI' )
                           AND category IN ( 'ET', 'OP' )
                         )  --NICARAGUA
                      OR ( ship_to_country_cd IN ( 'PA' )
                           AND category IN ( 'OP' )
                         )  --PANAMA
                      OR ( ship_to_country_cd IN ( 'PY' )
                           AND category IN ( 'ET', 'OP' )
                         )  --PARAGUAY
                      OR ( ship_to_country_cd IN ( 'PE' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP' )
                         )  --PERU
                      OR ( ship_to_country_cd IN ( 'PH' )
                           AND category IN ( 'ET', 'OP', 'ME' )
                         )  --PHILIPPINES
                      OR ( ship_to_country_cd IN ( 'PL' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --POLAND
                      OR ( ship_to_country_cd IN ( 'PT' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --PORTUGAL
--OR (ship_to_country_cd in ('PR') and category in () )   --PUERTO RICO  ALL
                      OR ( ship_to_country_cd IN ( 'RO' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --Romania
                      OR ( ship_to_country_cd IN ( 'SK' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --slovakia
                      OR ( ship_to_country_cd IN ( 'SI' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --slovenia
                      OR ( ship_to_country_cd IN ( 'ES' )
                           AND category IN ( 'CH', 'ET', 'IZOD', 'IZX', 'OP',
                                             'ME' )
                         )  --spain
                      OR ( ship_to_country_cd IN ( 'LC' )
                           AND category IN ( 'ME' )
                         )  --st. lucia  ALL
                      OR ( ship_to_country_cd IN ( 'SX' )
                           AND category IN ( 'IZOD', 'IZX', 'ME' )
                         )  --st. maarten Dutch
                      OR ( ship_to_country_cd IN ( 'MF' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'ME' )
                         )  --st. martin (French)
                      OR ( ship_to_country_cd IN ( 'VC' )
                           AND category IN ( 'ME' )
                         )  --Saint Vincent and the Grenadines  ALL
--OR (ship_to_country_cd in ('SR') and category in () )  --suriname  ALL
                      OR ( ship_to_country_cd IN ( 'TW' )
                           AND category IN ( 'CH', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --taiwan
--OR (ship_to_country_cd in ('TT') and category in () )  -- trinidad and tobago ALL
                      OR ( ship_to_country_cd IN ( 'GB' )
                           AND category IN ( 'ET', 'OP', 'ME' )
                         )  --UK
                      OR ( ship_to_country_cd IN ( 'UY' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP' )
                         )  --Uruguay
                      OR ( ship_to_country_cd IN ( 'VE' )
                           AND category IN ( 'ET', 'OP' )
                         )  --Venezuela
--OR (ship_to_country_cd in ('VI') and category in () )  --us virgin islands  ALL
                      OR ( ship_to_country_cd IN ( 'CU' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --cuba -- caribbean
                      OR ( ship_to_country_cd IN ( 'GP' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --guadeloupe -- caribbean
                      OR ( ship_to_country_cd IN ( 'MQ' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --martinique-- caribbean
                      OR ( ship_to_country_cd IN ( 'MS' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --montserrat-- caribbean
                      OR ( ship_to_country_cd IN ( 'BL' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --sant barthemeley-- caribbean
                      OR ( ship_to_country_cd IN ( 'KN' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --st kitts and nevis-- caribbean
                      OR ( ship_to_country_cd IN ( 'TC' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --turks and caicos-- caribbean
                      OR ( ship_to_country_cd IN ( 'UM' )
                           AND category IN ( 'ET', 'IZOD', 'IZX', 'OP', 'ME' )
                         )  --US Minor Outlying Islands
                    )
--and date_entered between '1/1/2013' and '3/1/2013'  
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
                total_amt_order
        ORDER BY ship_to_country_cd ,
                t4.description ,
                category ,
                date_entered DESC;

        SELECT  Ctry ,
                description ,
                Brand ,
                type ,
                status ,
                order_no ,
                ext ,
                cust_code ,
                ship_to ,
				ship_to_name,
                ship_to_region ,
                date_entered ,
                CASE WHEN Brand = 'ME'
                          AND Ctry IN ( 'AI', 'AG', 'MS', 'BM', 'VG', 'DM',
                                        'BL', 'KN', 'SX', 'MF', 'TC', 'VC',
                                        'LC' ) THEN 'NPA'
                     ELSE ''
                END AS NeedsApproval ,
                date_shipped ,
                total_amt_order ,
                QtyOrd ,
                QtyShip
        FROM    #LIST;

    END;



GO
