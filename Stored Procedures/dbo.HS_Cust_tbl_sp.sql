SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 2/20/2013
-- Description:	Handshake Main Customer Data
-- EXEC hs_cust_tbl_sp
-- select * From hs_cust_tbl where modified_by_date > '10/18/2016'
-- tag - 071213 - create a regular table instead of temp table
-- tag - 8/21/2015 - add sales rep customer accounts
-- tag - 10/18/2016 - use insert/update logic instead of rebuild
-- =============================================

CREATE PROCEDURE [dbo].[HS_Cust_tbl_sp] 
AS
BEGIN 

	SET NOCOUNT ON;
	
	DECLARE @today DATETIME
	SELECT @today  = GETDATE()

	
	IF(OBJECT_ID('#userGroup') is not null) DROP table t#AllTerr
      ;WITH C AS 
			( SELECT DISTINCT ar.territory_code, ar.customer_code 
			from
            ( SELECT DISTINCT territory_code FROM arterr (NOLOCK) 
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
      INTO #userGroup
      FROM C

	  -- add sales rep customers too - 8/19/2015
	  INSERT INTO #userGroup  (customer_code, AllTerr)
	  SELECT DISTINCT ISNULL(employee_code,'') customer_code, territory_code
	  FROM arsalesp (NOLOCK) 
	  WHERE ISNULL(employee_code,'') > ''
	  AND status_type = 1
	  AND NOT EXISTS(SELECT 1 FROM #userGroup WHERE #userGroup.customer_code = ISNULL(employee_code,'') )

	  INSERT INTO #userGroup (customer_code, allterr) VALUES ('052834','I-Sales')

	  -- 2/3/2017 - updated territory list
	  -- 3/16/2017 - new list per email

	  UPDATE #userGroup SET AllTerr = allterr + ',I-Sales'
	  WHERE allterr LIKE '%50534%'
	  OR allterr LIKE '%20202%'
		 OR customer_code = '052931'
		 OR customer_code = '053318'
		 OR customer_code = '014910'

-- for Phil for VE - 032717
	  UPDATE #userGroup SET AllTerr = allterr + ',20206'
	  WHERE customer_code = '014443'

	  --UPDATE #userGroup SET allterr = allterr + ',50530' -- removed 6/14/17 - territory no longer empty KM will not be servicing
	  --WHERE AllTerr LIKE '%50510%'

	  -- SELECT * FROM #userGroup

-- PULL LIST FOR CUSTOMERS
--IF(OBJECT_ID('dbo.hs_cust_tbl') is not null)
--truncate table hs_cust_tbl

IF(OBJECT_ID('#hs') is not null) DROP table #hs



SELECT ar.customer_code as id, 
addr1 as name,
contact_name as contact,
email = CASE WHEN (contact_email LIKE '%cvoptical.com'
				OR contact_email LIKE '%refused%')
			THEN ''
			ELSE REPLACE(LOWER(ISNULL(contact_email,'')),';',',')
			END,
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
#userGroup.allterr as userGroup,
'' as taxID,
ISNULL(ar.addr_sort1,'') AccountType,
openar = CASE WHEN saat.BG_CODE <> '' THEN 'Buying Group: '+saat.BG_CODE
			  WHEN saat.bal > saat.CREDIT_LIMIT THEN 'Over Credit Limit'
			  WHEN saat.bal < 0 THEN 'Credit Balance'
			  WHEN saat.ar30+saat.ar60+ar90+ar120+ar150 <> 0 THEN 'Past Due > 30 Days'
			  ELSE 'Current' end	,
designations.desig AS designations,
lastst.laststdate laststdate,

-- 071213 - tag -  add for HS sync
added_by_date,
modified_by_date

INTO #hs

FROM armaster ar (nolock)
INNER JOIN #userGroup (nolock) on ar.customer_code = #userGroup.customer_code
LEFT OUTER JOIN dbo.SSRS_ARAging_Temp AS saat on saat.CUST_CODE = ar.customer_code
LEFT OUTER JOIN ( SELECT    c.customer_code ,
                            RIGHT(c.customer_code, 5) MergeCust ,
                            STUFF(( SELECT  '; ' + code
                                    FROM    cvo_cust_designation_codes x (NOLOCK)
                                    WHERE   customer_code = c.customer_code
                                            AND ISNULL(start_date, @today) <= @today
                                            AND ISNULL(end_date, @today) >= @today
											ORDER BY x.primary_flag desc, x.code asc
                                    FOR
                                    XML PATH('')
                                    ), 1, 1, '') desig
                    FROM      dbo.cvo_cust_designation_codes (NOLOCK) c
                ) AS designations ON designations.MergeCust = RIGHT(ar.customer_code,5)
LEFT OUTER JOIN
( SELECT cust_code, MAX(date_entered) laststdate
FROM orders o 
WHERE status = 't' AND type = 'i' 
	AND LEFT(o.USER_category,2) = 'st' 
	AND RIGHT(o.user_category,2) <> 'rb'
GROUP BY o.cust_code
) lastst ON lastst.cust_code = ar.customer_code

WHERE 1=1
AND STATUS_TYPE=1
AND ADDRESS_TYPE=0

UPDATE h SET
	   -- h.id,
       h.name = #hs.name,
       h.contact  = #hs.contact,
       h.email = #hs.email ,
       h.bill_name = #hs.bill_name ,
       h.bill_street = #hs.bill_street,
       h.bill_street2 = #hs.bill_street2,
       h.bill_city = #hs.bill_city,
       h.bill_state = #hs.bill_state,
       h.bill_postcode = #hs.bill_postcode,
       h.bill_country = #hs.bill_country,
       h.bill_phone = #hs.bill_phone,
       h.bill_fax = #hs.bill_fax,
       h.ship_street = #hs.ship_street,
       h.ship_street2 = #hs.ship_street2,
       h.ship_city = #hs.ship_city,
       h.ship_state = #hs.ship_state,
       h.ship_postcode = #hs.ship_postcode,
       h.ship_country = #hs.ship_country ,
       h.ship_phone =#hs.ship_phone,
       h.ship_fax = #hs.ship_fax,
       h.paymentTerms = #hs.paymentterms,
       h.shippingMethod = #hs.shippingmethod,
       h.customerGroup = #hs.customergroup,
       h.userGroup = #hs.usergroup,
       h.taxID = #hs.taxid,
	   h.accounttype = #hs.AccountType,
	   h.openar = #hs.openar,
	   h.designations = #hs.designations,
	   h.laststdate =  #hs.laststdate,
       -- h.added_by_date,
	   h.modified_by_date = GETDATE(),
	   modified_flag = 1
-- SELECT *
FROM #hs 
JOIN dbo.hs_cust_tbl AS h ON h.id = #hs.id
WHERE
       h.name <> #hs.name or
       h.contact  <> #hs.contact or
       h.email <> #hs.email  or
       h.bill_name <> #hs.bill_name  or
       h.bill_street <> #hs.bill_street or
       h.bill_street2 <> #hs.bill_street2 or
       h.bill_city <> #hs.bill_city or
       h.bill_state <> #hs.bill_state or
       h.bill_postcode <> #hs.bill_postcode or
       h.bill_country <> #hs.bill_country or
       h.bill_phone <> #hs.bill_phone or
       h.bill_fax <> #hs.bill_fax or
       h.ship_street <> #hs.ship_street or
       h.ship_street2 <> #hs.ship_street2 or
       h.ship_city <> #hs.ship_city or
       h.ship_state <> #hs.ship_state or
       h.ship_postcode <> #hs.ship_postcode or
       h.ship_country <> #hs.ship_country  or
       h.ship_phone <> #hs.ship_phone or
       h.ship_fax <> #hs.ship_fax or
       h.paymentTerms <> #hs.paymentterms or
       h.shippingMethod <> #hs.shippingmethod or
       h.customerGroup <> #hs.customergroup or
       h.userGroup <> #hs.usergroup or
       h.taxID <> #hs.taxid OR 
	   ISNULL(h.accounttype,'') <> ISNULL(#hs.AccountType,'') OR
			   ISNULL(h.openar,'') <> ISNULL(#hs.openar,'') or
	   ISNULL(h.designations,'') <> ISNULL(#hs.designations,'') OR 
	   ISNULL(h.laststdate,'1/1/1900') <>  ISNULL(#hs.laststdate,'1/1/1900') 


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
		  accounttype,
		  openar,
		  designations,
		  laststdate,
          added_by_date ,
          modified_by_date,
		  modified_flag
        )
SELECT h.id ,
       h.name ,
       h.contact ,
       h.email ,
       h.bill_name ,
       h.bill_street ,
       h.bill_street2 ,
       h.bill_city ,
       h.bill_state ,
       h.bill_postcode ,
       h.bill_country ,
       h.bill_phone ,
       h.bill_fax ,
       h.ship_street ,
       h.ship_street2 ,
       h.ship_city ,
       h.ship_state ,
       h.ship_postcode ,
       h.ship_country ,
       h.ship_phone ,
       h.ship_fax ,
       h.paymentTerms ,
       h.shippingMethod ,
       h.customerGroup ,
       h.userGroup ,
       h.taxID ,
	   h.AccountType,
	   h.openar,
	   h.designations,
	   h.laststdate,
       GETDATE() added_by_date ,
       NULL modified_by_date,
	   1 modified_flag
	   FROM dbo.#hs AS h
	WHERE NOT EXISTS (SELECT 1 FROM dbo.hs_cust_tbl AS hct WHERE hct.id = h.id)




END















GO

GRANT EXECUTE ON  [dbo].[HS_Cust_tbl_sp] TO [public]
GO
