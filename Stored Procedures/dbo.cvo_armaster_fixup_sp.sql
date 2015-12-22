SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[cvo_armaster_fixup_sp]
as

set nocount on

-- exec cvo_armaster_fixup_sp

-- UPDATE DOORS ON NEW ENTERED BILL TO CUSTOMERS
UPDATE T2
SET DOOR='1'
from armaster_all t1 (nolock)
join cvo_armaster_all t2 (rowlock) on t1.customer_code=t2.customer_code and t1.ship_to_code=t2.ship_to
where door is null
and ship_to=''

UPDATE T2
SET DOOR='0'
from armaster_all t1 (nolock)
join cvo_armaster_all t2 (rowlock) on t1.customer_code=t2.customer_code and t1.ship_to_code=t2.ship_to
where door is null
and ship_to<>''




-- FIX CONSISTENCY ON CASE
 update armaster with (rowlock) set addr_sort1 = 
	case when addr_sort1 = 'Buying Group' then 'Buying Group'
		 when addr_sort1 = 'Customer' then 'Customer'
		 when addr_sort1 = 'Distributor' then 'Distributor'
		 when ADDR_SORT1 = 'Employee' then 'Employee'
		 when ADDR_SORT1 = 'Intl Retailer' then 'Intl Retailer'
		 when ADDR_SORT1 = 'Key Account' then 'Key Account'
		 else addr_sort1
		 end

		 -- UPDATE GLOBAL_LABS
 UPDATE ARMASTER with (rowlock)
	SET ADDR_SORT1 = 'GLOBAL_LAB' where address_type=9 
	and addr_sort1 <>'GLOBAL_LAB'-- and ship_via_code not like '3%'

-- FIND MISMATCHED CUSTOMERS & SHIPTOS IN CUSTOMER TYPE (ADDR_SORT1)
--SELECT CUSTOMER_CODE, SHIP_TO_CODE, ADDR_SORT1, (SELECT TOP 1 ADDR_SORT1 FROM ARMASTER ARM WHERE ARM.CUSTOMER_CODE=ARS.CUSTOMER_CODE AND ADDRESS_TYPE=0) ADDR_SORT1_MAST  FROM ARMASTER ARS WHERE ADDRESS_TYPE=1 AND ADDR_SORT1 <> (SELECT TOP 1 ADDR_SORT1 FROM ARMASTER ARM WHERE ARM.CUSTOMER_CODE=ARS.CUSTOMER_CODE AND ADDRESS_TYPE=0)

-- UPDATE MISMATCHED CUSTOMERS & SHIPTOS IN CUSTOMER TYPE (ADDR_SORT1)
UPDATE ARS
SET ADDR_SORT1 = (SELECT TOP 1 ADDR_SORT1 FROM ARMASTER ARM (nolock) 
				  WHERE ARM.CUSTOMER_CODE=ARS.CUSTOMER_CODE AND ADDRESS_TYPE=0)
FROM ARMASTER ARS with (rowlock)
WHERE ADDRESS_TYPE=1 AND ADDR_SORT1 <> 
			(SELECT TOP 1 ADDR_SORT1 FROM ARMASTER ARM (nolock) 
			 WHERE ARM.CUSTOMER_CODE=ARS.CUSTOMER_CODE AND ADDRESS_TYPE=0) 

-- update consolidated invoices flag on customer master --- never to be used

update armaster with (rowlock) set consolidated_invoices = 0 where consolidated_invoices <> 0

-- update tax_code - only US accounts are set to AVATAX, all others s/b NOTAX
UPDATE ARMASTER with (rowlock) SET TAX_CODE='NOTAX' Where country_code <> 'us' and tax_code <>'notax'

-- UPDATE TO CHECK WHERE MAIN ACCOUNT IS CLOSED OR NONEWBUSINESS AND SET SHIPTO'S TO MATCH
update t1 set status_type = (select t11.status_type from armaster t11 where t1.customer_code=t11.customer_code and address_type = 0)
from armaster t1 with (rowlock)
where address_type = 1
and (select t11.status_type from armaster t11 (nolock) where t1.customer_code=t11.customer_code and address_type = 0) <> 1
and t1.status_type <> (select t11.status_type from armaster t11 (nolock) where t1.customer_code=t11.customer_code and address_type = 0)

-- UPDATE BLANK ATTENTION NAME ON BILL TO ACCOUNTS TO READ ACCOUNTS PAYABLE
UPDATE ARMASTER with (rowlock) SET ATTENTION_NAME='ACCOUNTS PAYABLE' WHERE ADDRESS_TYPE=0 AND ATTENTION_NAME =''

-- SET PAID ON BILLED TO ALL CUSTOMERS  *( UNIL WE HAVE A REP THAT GETS PAID ON PAID AGAIN )*
UPDATE ARMASTER with (rowlock) SET ADDR_SORT3 = 'POB' WHERE ADDR_SORT3 <> 'POB'

-- REMOVE broken cvo_armaster_all rows where they don't exist in armaster_all

-- tag 082914 - use more efficient code below
-- delete cvo_armaster_all 
-- from cvo_armaster_all t1 join (SELECT t1.customer_code, T1.ship_to FROM cvo_armaster_all T1 FULL OUTER JOIN armaster T2 ON t1.customer_code=t2.customer_code and t1.ship_to=t2.ship_to_code WHERE T2.ship_to_code IS NULL) t2 on t1.customer_code=t2.customer_code and t1.ship_to=t2.ship_to

	delete 
--	SELECT * FROM 
	cvo_armaster_all  with (rowlock)
	where not exists ( select 1 from armaster ar 
						where cvo_armaster_all.customer_code = ar.customer_code 
					      and cvo_armaster_all.ship_to = ar.ship_to_code)

-- UPDATE WHERE STATE IS IN US AND COUNTRY CODE IS BLANK
UPDATE ARMASTER with (rowlock) SET COUNTRY_CODE='US' WHERE STATE IN ('AK', 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DC', 'DE', 'FL', 'GA', 'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VT', 'WA', 'WI', 'WV','WY') AND COUNTRY_CODE <>'us'

-- Fix the Aging Bucket limit brackets - default to over 30 days
update armaster with (rowlock) set aging_limit_bracket=1 
where status_type = 1 and address_type =0 and check_aging_limit = 1 and aging_limit_bracket <> 1

/*
-- commented out by EL on 3/18/2014 until the 0 and 9 issues are fixed.
-- Set End Dates for Designations where the customer is closed/NoNewBusiness 
update  t2
set end_date = getdate()
from armaster t1
join cvo_cust_designation_codes t2 on t1.customer_code=t2.customer_code
where status_type in ('2','3') 
and address_type = '0'
and code <> 'KEY'
and end_date is null
*/

-- update NULL values in cvo_armaster_all to NO (0)
update cvo_armaster_all with (rowlock) set allow_substitutes = 0 where allow_substitutes is NULL

-- tag - 082914
-- fixup added by date on armaster for ship-tos

Update ar SET added_by_date = dateadd(dd, datediff(dd, 0 , FirstOrder), 0)
-- select ar.customer_code, ar.ship_to_code, added_by_date, dateadd(dd, datediff(dd, 0 , FirstOrder), 0)
FROM armaster ar (rowlock)
join 
(select cust_code, ship_to, min(date_entered) FirstOrder 
from orders_all t2 (nolock) 
group by cust_code, ship_to
) as o 
on ar.customer_code=o.cust_code and ar.ship_to_code=o.ship_to
where o.FirstOrder < ar.added_by_date


-- TAG - 091714
-- fix blank territory codes in armaster and orders

UPDATE AR SET AR.TERRITORY_CODE = SP.TERRITORY_CODE
-- select ar.salesperson_code, AR.TERRITORY_CODE ,sp.TERRITORY_CODE, SP.TERRITORY_CODE 
from armaster ar with (rowlock)
join arsalesp sp (NOLOCK) on ar.salesperson_code = sp.salesperson_code 
where AR.territory_code = '' AND AR.TERRITORY_CODE <> SP.TERRITORY_CODE

update o set o.ship_to_region = ar.territory_code
-- select o.order_no, o.ext, o.salesperson, ar.salesperson_code, o.ship_to_region, ar.territory_code,  * 
from armaster ar with (rowlock) 
join orders o (nolock) on ar.customer_code = o.cust_code and ar.ship_to_code = o.ship_to
where o.ship_to_region <> ar.territory_code
and o.ship_to_region = ''

/*
update o set o.territory_code = ar.territory_code
-- select o.doc_ctrl_num, o.salesperson_code, ar.salesperson_code, o.territory_code, ar.territory_code,  * 
from armaster ar  
join artrx o  on ar.customer_code = o.customer_code and ar.ship_to_code = o.ship_to_code
where o.territory_code <> ar.territory_code
and o.territory_code = '' and o.trx_type in (2031,2032)
*/
GO
GRANT EXECUTE ON  [dbo].[cvo_armaster_fixup_sp] TO [public]
GO
