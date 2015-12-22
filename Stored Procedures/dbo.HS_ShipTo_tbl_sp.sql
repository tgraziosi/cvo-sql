SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 2/20/2013
-- Description:	Handshake ShipTo Customer Data
-- 071213 - tag - create table instead of temp table
-- EXEC HS_ShipTo_tbl_sp
-- select * From hs_shipto_tbl
-- =============================================
CREATE PROCEDURE [dbo].[HS_ShipTo_tbl_sp] 
AS
BEGIN

	SET NOCOUNT ON;

-- PULL LIST FOR SHIP_TO  (Ship_to's)
IF(OBJECT_ID('dbo.HS_Shipto_tbl') is not null)
-- drop table HS_Shipto_tbl
truncate table HS_Shipto_tbl

INSERT INTO HS_Shipto_tbl
SELECT customer_code as cust_id, 
(SELECT addr1 FROM ARMASTER T2 WHERE T1.customer_code=t2.customer_code and ship_to_code='') as cust_name, ship_to_code as ship_id, addr2 as ship_street, CASE WHEN addr3 LIKE '%, __ %' THEN '' ELSE ADDR3 END AS ship_street2, city as ship_city, state as ship_state, postal_code as ship_postcode, country_code as ship_country, contact_phone as ship_phone, tlx_twx as ship_fax, addr1 as ship_name, '0' as is_default,
added_by_date, isnull(modified_by_date,added_by_date) modified_by_date
-- INTO HS_Shipto_tbl
FROM armaster T1
WHERE territory_code not like ('908%')
AND territory_code not like ('909%')
AND territory_code not like ('8%')
AND STATUS_TYPE=1
AND ADDRESS_TYPE=1
and addr1  not like '%do not%'

-- PULL LIST FOR SHIP_TO  (Customer's)
INSERT INTO HS_Shipto_tbl
SELECT customer_code as cust_id, 
addr1 as cust_name, 
'' as ship_id, 
--'D' as ship_id, 
addr2 as ship_street, CASE WHEN addr3 LIKE '%, __ %' THEN '' ELSE ADDR3 END AS ship_street2, city as ship_city, state as ship_state, postal_code as ship_postcode, country_code as ship_country, contact_phone as ship_phone, tlx_twx as ship_fax, addr1 as ship_name, '1' as is_default,
added_by_date, isnull(modified_by_date,added_by_date) modified_by_date
FROM armaster T1
WHERE territory_code not like ('908%')
AND territory_code not like ('909%')
AND territory_code not like ('8%')
AND STATUS_TYPE=1
AND ADDRESS_TYPE=0
and addr1  not like '%do not%'
AND ( ISNULL(VALID_SHIPTO_FLAG,0) = 1 )
-- REMOVE SHIPS THAT MAIN CUST IS INACTIVE
--DELETE FROM #hs_ship where #hs_ship.ship_id<>'d' and (select count(ship_id) from #hs_ship t2 where #hs_ship.cust_id=t2.cust_id and T2.ship_id='d')<'1' 
--

-- DISPLAY RESULTS FOR SHIPTO
-- select * from #HS_Ship  where ship_id <>'d'  order by CUST_ID, SHIP_ID 

-- grant all on dbo.hs_shipto_tbl to public

END

GO
GRANT EXECUTE ON  [dbo].[HS_ShipTo_tbl_sp] TO [public]
GO
