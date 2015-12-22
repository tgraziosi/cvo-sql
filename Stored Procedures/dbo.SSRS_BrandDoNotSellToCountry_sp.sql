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
-- =============================================
CREATE PROCEDURE [dbo].[SSRS_BrandDoNotSellToCountry_sp] 

 @DateFrom datetime,
 @DateTo datetime

AS
BEGIN
	SET NOCOUNT ON;

-- 2013 do not sell to counties list
--DECLARE @DateFrom DATETIME
--DECLARE @DateTo DATETIME
--SET @F = Convert(varchar(10),getdate() -1,101)
--SET @T = DATEADD(MINUTE,-1,DATEADD(D,1,@F))

IF(OBJECT_ID('TEMP.DBO.#LIST') IS NOT NULL)     DROP TABLE #LIST
SELECT DISTINCT ship_to_country_cd as Ctry,t4.Description, category as Brand, t1.Type, t1.Status, t1.order_no, t1.ext, cust_code, t1.ship_to, ship_to_region, date_entered, date_shipped, total_amt_order,SUM(ordered)QtyOrd, SUM(shipped)QtyShip
  INTO #LIST
  FROM orders_all t1 (nolock)
  JOIN ord_list t2 (nolock) on t1.order_no=t2.order_no and t1.ext=t2.order_ext 
  JOIN inv_master t3 (nolock) on t2.part_no=t3.part_no 
  JOIN gl_country t4 (nolock) on t4.country_code=t1.ship_to_country_cd
WHERE t1.status <> 'v'
and t1.type='i'
-- default list ('CH','ET','IZOD','IZX','OP','JMC','ME')
AND ( (ship_to_country_cd in ('CF','ZA') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --africa
OR (ship_to_country_cd in ('AI') and category in ('ET','IZOD','IZX','OP','ME') )  --anguilla
OR (ship_to_country_cd in ('AG') and category in ('ME') )  --antigua & barbuda (Antilles)
OR (ship_to_country_cd in ('AR') and category in ('ET','IZOD','IZX','OP') )  --argentina
--OR (ship_to_country_cd in ('AW') and category in () )  --ARUBA  ALL
OR (ship_to_country_cd in ('AU') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --AUSTRALIA
OR (ship_to_country_cd in ('AT') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --AUSTRA
--OR (ship_to_country_cd in ('BS') and category in () )  --BAHAMAS  ALL
--OR (ship_to_country_cd in ('BB') and category in () )  --BARBADOS  ALL
OR (ship_to_country_cd in ('') and category in ('ET','IZOD','IZX','OP') )  --BARBUDA
OR (ship_to_country_cd in ('BE') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --BELGIUM
OR (ship_to_country_cd in ('BZ') and category in ('IZOD','IZX') )  --BELIZE
OR (ship_to_country_cd in ('BM') and category in ('ME') )  --BERMUDA
OR (ship_to_country_cd in ('BO') and category in ('ET','OP') )  --BOLIVIA
OR (ship_to_country_cd in ('BQ') and category in ('IZOD','IZX') )  --BONAIRE
OR (ship_to_country_cd in ('BR') and category in ('ET','OP','ME') )  --BRAZIL
OR (ship_to_country_cd in ('VG') and category in ('ME') )  -- BRITISH VIRGIN ISLANDS
OR (ship_to_country_cd in ('BG') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --BULGARIA 
OR (ship_to_country_cd in ('CA') and category in ('ME') )  --CANADA 
-- CARRIBBEAN (see individual countries)
--OR (ship_to_country_cd in ('KY') and category in () )  --CAYMAN ISL  ALL
OR (ship_to_country_cd in ('CL') and category in ('ET','OP') )  --CHILIE
OR (ship_to_country_cd in ('CO') and category in ('ET','OP') )  --COLUMBIA
OR (ship_to_country_cd in ('CR') and category in ('OP') )  --COSTA RICA
--OR (ship_to_country_cd in ('CW') and category in () )  --curaco  ALL
OR (ship_to_country_cd in ('CZ') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --czech rep
OR (ship_to_country_cd in ('DK') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --denmark
OR (ship_to_country_cd in ('DM') and category in ('ME') )  --dominica (Antillies)
OR (ship_to_country_cd in ('DO') and category in ('ET','OP') )  --dominican republic
--OR (ship_to_country_cd in ('EC') and category in ('ET','OP') )  --ecuador -- 022015
--OR (ship_to_country_cd in ('SV') and category in ('OP') )  --el salvador -- 022015
OR (ship_to_country_cd in ('EC') and category in ('ET') )  --ecuador -- 022015
-- OR (ship_to_country_cd in ('SV') and category in () )  --el salvador all -- 022015
OR (ship_to_country_cd in ('EE') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --estonia 
OR (ship_to_country_cd in ('FI') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --finland
OR (ship_to_country_cd in ('Fr') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --france
OR (ship_to_country_cd in ('GF') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --french guiana
OR (ship_to_country_cd in ('DE') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --gremany
OR (ship_to_country_cd in ('GR') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --greece
--OR (ship_to_country_cd in ('GD') and category in () )   --grenada all
OR (ship_to_country_cd in ('GT') and category in ('ET','OP') )  --guatemala
OR (ship_to_country_cd in ('GY') and category in ('IZOD','IZX') )  --guyana
OR (ship_to_country_cd in ('HT') and category in ('IZOD','IZX') )  --haiti
OR (ship_to_country_cd in ('HN') and category in ('ET','OP') )  --honduras
OR (ship_to_country_cd in ('HU') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --hungry
OR (ship_to_country_cd in ('IE') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --IRELAND
OR (ship_to_country_cd in ('IT') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --ITALY
--OR (ship_to_country_cd in ('JM') and category in () )  --JAMAICA  ALL
OR (ship_to_country_cd in ('JP') and category in ('ET','IZOD','IZX','OP','ME') )  --JAPAN
OR (ship_to_country_cd in ('LV') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --LATVIA
OR (ship_to_country_cd in ('LT') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --LITHUANIA
OR (ship_to_country_cd in ('LU') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --LUXEMBOURG
OR (ship_to_country_cd in ('MT') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --MALTA
--OR (ship_to_country_cd in ('MX') and category in () ) -- MEXCO ALL
OR (ship_to_country_cd in ('NL') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --NETHERLANDS
OR (ship_to_country_cd in ('NI') and category in ('ET','OP') )  --NICARAGUA
OR (ship_to_country_cd in ('PA') and category in ('OP') )  --PANAMA
OR (ship_to_country_cd in ('PY') and category in ('ET','OP') )  --PARAGUAY
OR (ship_to_country_cd in ('PE') and category in ('ET','IZOD','IZX','OP') )  --PERU
OR (ship_to_country_cd in ('PH') and category in ('ET','OP','ME') )  --PHILIPPINES
OR (ship_to_country_cd in ('PL') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --POLAND
OR (ship_to_country_cd in ('PT') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --PORTUGAL
--OR (ship_to_country_cd in ('PR') and category in () )   --PUERTO RICO  ALL
OR (ship_to_country_cd in ('RO') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --Romania
OR (ship_to_country_cd in ('SK') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --slovakia
OR (ship_to_country_cd in ('SI') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --slovenia
OR (ship_to_country_cd in ('ES') and category in ('CH','ET','IZOD','IZX','OP','ME') )  --spain
OR (ship_to_country_cd in ('LC') and category in ('ME') )  --st. lucia  ALL
OR (ship_to_country_cd in ('SX') and category in ('IZOD','IZX','ME') )  --st. maarten Dutch
OR (ship_to_country_cd in ('MF') and category in ('ET','IZOD','IZX','ME') )  --st. martin (French)
OR (ship_to_country_cd in ('VC') and category in ('ME') )  --Saint Vincent and the Grenadines  ALL
--OR (ship_to_country_cd in ('SR') and category in () )  --suriname  ALL
OR (ship_to_country_cd in ('TW') and category in ('CH','IZOD','IZX','OP','ME') )  --taiwan
--OR (ship_to_country_cd in ('TT') and category in () )  -- trinidad and tobago ALL
OR (ship_to_country_cd in ('GB') and category in ('ET','OP','ME') )  --UK
OR (ship_to_country_cd in ('UY') and category in ('ET','IZOD','IZX','OP') )  --Uruguay
OR (ship_to_country_cd in ('VE') and category in ('ET','OP') )  --Venezuela
--OR (ship_to_country_cd in ('VI') and category in () )  --us virgin islands  ALL
OR (ship_to_country_cd in ('CU') and category in ('ET','IZOD','IZX','OP','ME') )  --cuba -- caribbean
OR (ship_to_country_cd in ('GP') and category in ('ET','IZOD','IZX','OP','ME') )  --guadeloupe -- caribbean
OR (ship_to_country_cd in ('MQ') and category in ('ET','IZOD','IZX','OP','ME') )  --martinique-- caribbean
OR (ship_to_country_cd in ('MS') and category in ('ET','IZOD','IZX','OP','ME') )  --montserrat-- caribbean
OR (ship_to_country_cd in ('BL') and category in ('ET','IZOD','IZX','OP','ME') )  --sant barthemeley-- caribbean
OR (ship_to_country_cd in ('KN') and category in ('ET','IZOD','IZX','OP','ME') )  --st kitts and nevis-- caribbean
OR (ship_to_country_cd in ('TC') and category in ('ET','IZOD','IZX','OP','ME') )  --turks and caicos-- caribbean
OR (ship_to_country_cd in ('UM') and category in ('ET','IZOD','IZX','OP','ME') )  --US Minor Outlying Islands
)
--and date_entered between '1/1/2013' and '3/1/2013'  
and date_entered between @DateFrom and @DateTo
group by ship_to_country_cd,t4.Description, category, t1.Type, t1.Status, t1.order_no, t1.ext, cust_code, t1.ship_to, ship_to_region, date_entered, date_shipped, total_amt_order
order by ship_to_country_cd,t4.description, category, date_entered desc

SELECT 
Ctry, Description, Brand, Type, Status, order_no, ext, cust_code, ship_to, ship_to_region, date_entered, 
CASE WHEN BRAND = 'ME' AND CTRY IN ('AI','AG','MS','BM','VG','DM','BL','KN','SX','MF','TC','VC','LC') THEN 'NPA' ELSE '' END AS NeedsApproval,
date_shipped, total_amt_order, QtyOrd, QtyShip
FROM #LIST

END
GO
