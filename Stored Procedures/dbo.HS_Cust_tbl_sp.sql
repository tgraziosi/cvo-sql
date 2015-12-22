SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 2/20/2013
-- Description:	Handshake Main Customer Data
-- EXEC hs_cust_tbl_sp
-- select * From hs_cust_tbl
-- tag - 071213 - create a regular table instead of temp table
-- tag - 8/21/2015 - add sales rep customer accounts
-- =============================================

CREATE PROCEDURE [dbo].[HS_Cust_tbl_sp] 
AS
BEGIN

	SET NOCOUNT ON;
	
	IF(OBJECT_ID('tempdb.dbo.#AllTerr') is not null) DROP table dbo.#AllTerr
      ;WITH C AS 
			( SELECT DISTINCT ar.territory_code, ar.customer_code 
			from
            ( SELECT DISTINCT territory_code FROM armaster (NOLOCK) 
			   WHERE dbo.calculate_region_fn(territory_code) < '800') Terr
			   join
			( SELECT distinct customer_code, territory_code FROM armaster (nolock) ) ar
			  ON terr.territory_code = ar.territory_code
			)	
            select Distinct customer_code,
                              STUFF ( ( SELECT distinct ',' + territory_code
                              FROM armaster (nolock)
                              WHERE customer_code = C.customer_code
                             FOR XML PATH ('') ), 1, 1, ''  ) AS AllTerr
      INTO #AllTerr
      FROM C

	  -- add sales rep customers too - 8/19/2015
	  INSERT INTO #allterr  (customer_code, AllTerr)
	  SELECT DISTINCT ISNULL(employee_code,'') customer_code, territory_code
	  FROM arsalesp (NOLOCK) 
	  WHERE ISNULL(employee_code,'') > ''
	  AND status_type = 1
	  AND NOT EXISTS(SELECT 1 FROM #allterr WHERE #allterr.customer_code = ISNULL(employee_code,'') )

	  -- SELECT * FROM #allterr

-- PULL LIST FOR CUSTOMERS
IF(OBJECT_ID('dbo.hs_cust_tbl') is not null)
truncate table hs_cust_tbl

INSERT INTO dbo.hs_cust_tbl
        ( id ,
          name ,
          contact ,
          email ,
          bill_name ,
          bill_street ,
          bill_street2 ,
          bill_city ,
          bill_state ,
          bill_postcode ,
          bill_country ,
          bill_phone ,
          bill_fax ,
          ship_street ,
          ship_street2 ,
          ship_city ,
          ship_state ,
          ship_postcode ,
          ship_country ,
          ship_phone ,
          ship_fax ,
          paymentTerms ,
          shippingMethod ,
          customerGroup ,
          userGroup ,
          taxID ,
          added_by_date ,
          modified_by_date
        )
SELECT t1.customer_code as id, 
addr1 as name,
contact_name as contact,
email = CASE WHEN (contact_email LIKE '%cvoptical.com'
				OR contact_email LIKE '%refused%')
			THEN ''
			ELSE REPLACE(LOWER(ISNULL(contact_email,'')),';',',')
			END,

-- LOWER(contact_email) email,
addr1 as bill_name,
addr2 as bill_street,
CASE WHEN addr3 LIKE '%, __ %' THEN '' ELSE ADDR3 END AS bill_street2,
city as bill_city,
state as bill_state,
postal_code as bill_postcode,
country_code as bill_country,
contact_phone as bill_phone,
tlx_twx as bill_fax,

CASE WHEN ( isnull(VALID_SHIPTO_FLAG,1) = 1) THEN addr2 ELSE '' END as ship_street,
CASE WHEN ( isnull(VALID_SHIPTO_FLAG,1) = 1) THEN (CASE WHEN addr3 LIKE '%, __ %' THEN '' ELSE ADDR3 END) END AS ship_street2,
CASE WHEN ( isnull(VALID_SHIPTO_FLAG,1) = 1) THEN city ELSE '' END as ship_city,
CASE WHEN ( isnull(VALID_SHIPTO_FLAG,1) = 1) THEN state ELSE '' END as ship_state,
CASE WHEN ( isnull(VALID_SHIPTO_FLAG,1) = 1) THEN postal_code ELSE '' END as ship_postcode,
CASE WHEN ( isnull(VALID_SHIPTO_FLAG,1) = 1) THEN country_code ELSE '' END as ship_country,
CASE WHEN ( isnull(VALID_SHIPTO_FLAG,1) = 1) THEN contact_phone ELSE '' END as ship_phone,
CASE WHEN ( isnull(VALID_SHIPTO_FLAG,1) = 1) THEN tlx_twx ELSE '' END as ship_fax,
UPPER(terms_code) as paymentTerms,
ship_via_code as shippingMethod,
'CVO' as customerGroup,
-- (select AllTerr from #AllTerr t12 where t1.customer_code=t12.customer_code) as userGroup,
#allterr.allterr as userGroup,
'' as taxID,
-- 071213 - tag -  add for HS sync
added_by_date,
modified_by_date

-- INTO hs_cust_tbl
FROM armaster t1 (nolock)
INNER JOIN #allterr (nolock) on t1.customer_code = #allterr.customer_code
WHERE 1=1
--AND dbo.calculate_region_fn(t1.territory_code) < '800'
--territory_code not like ('908%')
--AND territory_code not like ('909%')
--AND territory_code not like ('8%')
AND STATUS_TYPE=1
AND ADDRESS_TYPE=0

-- UPDaTE EMAIL FIELD
--UPDATE hs_cust_tbl SET email = '' where email is null
--UPDATE hs_cust_tbl SET email = '' where email like '%@cvoptical.com'
--UPDATE hs_cust_tbl SET email = '' where email like '%REFUSED%'
--UPDATE hs_cust_tbl SET email = REPLACE(EMAIL,'; ',', ')
--UPDATE hs_cust_tbl SET email = REPLACE(EMAIL,';',', ')
---- DISPLAY RESULTS FOR CUSTOMER
--select * from hs_cust_tbl where name like '%zigman%'
--SELECT * FROM #allterr WHERE customer_code = '051228'

-- grant all on dbo.hs_cust_tbl to public
END


GO
GRANT EXECUTE ON  [dbo].[HS_Cust_tbl_sp] TO [public]
GO
