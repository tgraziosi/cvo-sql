SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_armaster_fixup_sp]
AS
BEGIN

    SET NOCOUNT ON;

    -- exec cvo_armaster_fixup_sp

    -- UPDATE DOORS ON NEW ENTERED BILL TO CUSTOMERS
    UPDATE t2
    SET t2.door = 1
    FROM armaster_all t1 (NOLOCK)
        JOIN CVO_armaster_all t2 (ROWLOCK)
            ON t1.customer_code = t2.customer_code
               AND t1.ship_to_code = t2.ship_to
    WHERE t2.door IS NULL
          AND
          (
              t2.ship_to = ''
              OR t1.address_type = 0
          );

    UPDATE t2
    SET t2.door = 0
    FROM armaster_all t1 (NOLOCK)
        JOIN CVO_armaster_all t2 (ROWLOCK)
            ON t1.customer_code = t2.customer_code
               AND t1.ship_to_code = t2.ship_to
    WHERE t2.door IS NULL
          AND
          (
              t2.ship_to <> ''
              OR t1.address_type = 1
          );




    -- FIX CONSISTENCY ON CASE
    UPDATE armaster WITH (ROWLOCK)
    SET addr_sort1 = CASE
                         WHEN addr_sort1 = 'Buying Group' THEN
                             'Buying Group'
                         WHEN addr_sort1 = 'Customer' THEN
                             'Customer'
                         WHEN addr_sort1 = 'Distributor' THEN
                             'Distributor'
                         WHEN addr_sort1 = 'Employee' THEN
                             'Employee'
                         WHEN addr_sort1 = 'Intl Retailer' THEN
                             'Intl Retailer'
                         WHEN addr_sort1 = 'Key Account' THEN
                             'Key Account'
                         ELSE
                             addr_sort1
                     END;

    -- UPDATE GLOBAL_LABS
    UPDATE armaster WITH (ROWLOCK)
    SET addr_sort1 = 'GLOBAL_LAB'
    WHERE address_type = 9
          AND addr_sort1 <> 'GLOBAL_LAB'; -- and ship_via_code not like '3%'

    -- FIND MISMATCHED CUSTOMERS & SHIPTOS IN CUSTOMER TYPE (ADDR_SORT1)
    --SELECT CUSTOMER_CODE, SHIP_TO_CODE, ADDR_SORT1, (SELECT TOP 1 ADDR_SORT1 FROM ARMASTER ARM WHERE ARM.CUSTOMER_CODE=ARS.CUSTOMER_CODE AND ADDRESS_TYPE=0) ADDR_SORT1_MAST  FROM ARMASTER ARS WHERE ADDRESS_TYPE=1 AND ADDR_SORT1 <> (SELECT TOP 1 ADDR_SORT1 FROM ARMASTER ARM WHERE ARM.CUSTOMER_CODE=ARS.CUSTOMER_CODE AND ADDRESS_TYPE=0)

    -- UPDATE MISMATCHED CUSTOMERS & SHIPTOS IN CUSTOMER TYPE (ADDR_SORT1)
    UPDATE ARS
    SET addr_sort1 =
        (
            SELECT TOP 1
                   addr_sort1
            FROM armaster ARM (NOLOCK)
            WHERE ARM.customer_code = ARS.customer_code
                  AND address_type = 0
        )
    FROM armaster ARS WITH (ROWLOCK)
    WHERE address_type = 1
          AND addr_sort1 <>
          (
              SELECT TOP 1
                     addr_sort1
              FROM armaster ARM (NOLOCK)
              WHERE ARM.customer_code = ARS.customer_code
                    AND address_type = 0
          );

    -- update consolidated invoices flag on customer master --- never to be used

    UPDATE armaster WITH (ROWLOCK)
    SET consolidated_invoices = 0
    WHERE consolidated_invoices <> 0;

    -- update tax_code - only US accounts are set to AVATAX, all others s/b NOTAX
    UPDATE armaster WITH (ROWLOCK)
    SET tax_code = 'NOTAX'
    WHERE country_code <> 'us'
          AND tax_code <> 'notax';

    -- UPDATE TO CHECK WHERE MAIN ACCOUNT IS CLOSED OR NONEWBUSINESS AND SET SHIPTO'S TO MATCH
    UPDATE t1
    SET status_type =
        (
            SELECT t11.status_type
            FROM armaster t11
            WHERE t1.customer_code = t11.customer_code
                  AND address_type = 0
        )
    FROM armaster t1 WITH (ROWLOCK)
    WHERE address_type = 1
          AND
          (
              SELECT t11.status_type
              FROM armaster t11 (NOLOCK)
              WHERE t1.customer_code = t11.customer_code
                    AND address_type = 0
          ) <> 1
          AND t1.status_type <>
          (
              SELECT t11.status_type
              FROM armaster t11 (NOLOCK)
              WHERE t1.customer_code = t11.customer_code
                    AND address_type = 0
          );

    -- UPDATE BLANK ATTENTION NAME ON BILL TO ACCOUNTS TO READ ACCOUNTS PAYABLE
    UPDATE armaster WITH (ROWLOCK)
    SET attention_name = 'ACCOUNTS PAYABLE'
    WHERE address_type = 0
          AND attention_name = '';

    -- SET PAID ON BILLED TO ALL CUSTOMERS  *( UNIL WE HAVE A REP THAT GETS PAID ON PAID AGAIN )*
    UPDATE armaster WITH (ROWLOCK)
    SET addr_sort3 = 'POB'
    WHERE addr_sort3 <> 'POB';

    -- REMOVE broken cvo_armaster_all rows where they don't exist in armaster_all

    -- tag 082914 - use more efficient code below
    -- delete cvo_armaster_all 
    -- from cvo_armaster_all t1 join (SELECT t1.customer_code, T1.ship_to FROM cvo_armaster_all T1 FULL OUTER JOIN armaster T2 ON t1.customer_code=t2.customer_code and t1.ship_to=t2.ship_to_code WHERE T2.ship_to_code IS NULL) t2 on t1.customer_code=t2.customer_code and t1.ship_to=t2.ship_to

    IF EXISTS
    (
        SELECT 1
        FROM CVO_armaster_all car
            LEFT OUTER JOIN armaster ar
                ON ar.customer_code = car.customer_code
                   AND ar.ship_to_code = car.ship_to
        WHERE ar.customer_code IS NULL
    )
        DELETE
        --	SELECT * FROM 
        CVO_armaster_all WITH (ROWLOCK)
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM armaster ar
            WHERE CVO_armaster_all.customer_code = ar.customer_code
                  AND CVO_armaster_all.ship_to = ar.ship_to_code
        );

    -- UPDATE WHERE STATE IS IN US AND COUNTRY CODE IS BLANK
    UPDATE armaster WITH (ROWLOCK)
    SET country_code = 'US'
    WHERE country_code <> 'us'
          AND state IN ( 'AK', 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DC', 'DE', 'FL', 'GA', 'HI', 'IA', 'ID', 'IL',
                         'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MS', 'MT', 'NC', 'ND', 'NE',
                         'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT',
                         'VA', 'VT', 'WA', 'WI', 'WV', 'WY'
                       );

    -- Fix the Aging Bucket limit brackets - default to over 30 days
    UPDATE armaster WITH (ROWLOCK)
    SET aging_limit_bracket = 1
    WHERE status_type = 1
          AND address_type = 0
          AND check_aging_limit = 1
          AND aging_limit_bracket <> 1;

    /*
-- commented out by EL on 3/18/2014 until the 0 and 9 issues are fixed.
-- Set End Dates for Designations where the customer is closed/NoNewBusiness 
update  t2
set end_date = getdate(),
from armaster t1
join cvo_cust_designation_codes t2 on t1.customer_code=t2.customer_code
where status_type in ('2','3') 
and address_type = '0'
and code <> 'KEY'
and end_date is null
*/

    -- update NULL values in cvo_armaster_all to NO (0)
    UPDATE CVO_armaster_all WITH (ROWLOCK)
    SET allow_substitutes = 0
    WHERE allow_substitutes IS NULL;

    -- tag - 082914
    -- fixup added by date on armaster for ship-tos

    UPDATE ar
    SET added_by_date = DATEADD(dd, DATEDIFF(dd, 0, FirstOrder), 0)
    -- select ar.customer_code, ar.ship_to_code, added_by_date, dateadd(dd, datediff(dd, 0 , FirstOrder), 0)
    FROM armaster ar (ROWLOCK)
        JOIN
        (
            SELECT cust_code,
                   ship_to,
                   MIN(date_entered) FirstOrder
            FROM orders_all t2 (NOLOCK)
            GROUP BY cust_code,
                     ship_to
        ) AS o
            ON ar.customer_code = o.cust_code
               AND ar.ship_to_code = o.ship_to
    WHERE o.FirstOrder < ar.added_by_date;


    -- TAG - 091714
    -- fix blank territory codes in armaster and orders

    UPDATE ar
    SET ar.territory_code = sp.territory_code
    -- select ar.salesperson_code, AR.TERRITORY_CODE ,sp.TERRITORY_CODE, SP.TERRITORY_CODE 
    FROM armaster ar WITH (ROWLOCK)
        JOIN arsalesp sp (NOLOCK)
            ON ar.salesperson_code = sp.salesperson_code
    WHERE ar.territory_code = ''
          AND ar.territory_code <> sp.territory_code;

    UPDATE o
    SET o.ship_to_region = ar.territory_code
    -- select o.order_no, o.ext, o.salesperson, ar.salesperson_code, o.ship_to_region, ar.territory_code,  * 
    FROM armaster ar WITH (NOLOCK)
        JOIN orders o (ROWLOCK)
            ON ar.customer_code = o.cust_code
               AND ar.ship_to_code = o.ship_to
    WHERE o.ship_to_region <> ar.territory_code
          AND o.ship_to_region = '';

    -- 11/13/2017

    UPDATE ar
    SET salesperson_code = 'BangsLi'
    -- select territory_code, salesperson_code, * 
    FROM armaster ar
    WHERE territory_code = '20215'
          AND ar.salesperson_code <> 'BangsLi';

    UPDATE ar
    SET salesperson_code = 'CobbWh'
    -- select territory_code, salesperson_code, * 
    FROM armaster ar
    WHERE territory_code = '70775'
          AND ar.salesperson_code <> 'CobbWh';

    -- 9/18/2018 - special territory commission rate for Tom Lyon

    UPDATE car
    SET commission = 25.5,
        car.commissionable = 1
    -- SELECT car.* 
    FROM armaster ar
        JOIN CVO_armaster_all car
            ON car.customer_code = ar.customer_code
               AND car.ship_to = ar.ship_to_code
    WHERE ar.status_type = 1
          AND ar.territory_code = '40432'
          AND ar.salesperson_code = 'LyonTo'
          AND
          (
              ISNULL(car.commission, 0) <> 25.5
              OR ISNULL(car.commissionable, 0) <> 1
          );


    /*
update o set o.territory_code = ar.territory_code
-- select o.doc_ctrl_num, o.salesperson_code, ar.salesperson_code, o.territory_code, ar.territory_code,  * 
from armaster ar  
join artrx o  on ar.customer_code = o.customer_code and ar.ship_to_code = o.ship_to_code
where o.territory_code <> ar.territory_code
and o.territory_code = '' and o.trx_type in (2031,2032)
*/

    -- Ship-to rx consolidate flag has to be zero - 8/2/2016

    UPDATE co
    SET rx_consolidate = 0
    -- SELECT * 
    FROM CVO_armaster_all co (ROWLOCK)
    WHERE ship_to > ''
          AND rx_consolidate > 0;

    -- 11/29/2016 - If a designation has ended, unmark it as primary

    UPDATE cdc
    SET primary_flag = 0
    -- SELECT * 
    FROM dbo.cvo_cust_designation_codes AS cdc (ROWLOCK)
    WHERE cdc.primary_flag = 1
          AND ISNULL(cdc.end_date, GETDATE()) < GETDATE();

    -- 1/15/2018 - DON'T ALLOW A SHIP-TO-CODE ON A BILL-TO CUSTOMER

    UPDATE car
    SET ship_to = ''
    -- select *
    FROM armaster ar (NOLOCK)
        JOIN CVO_armaster_all car (ROWLOCK)
            ON car.customer_code = ar.customer_code
               AND car.ship_to = ar.ship_to_code
               AND ar.address_type = 0
               AND ar.ship_to_code <> '';

    UPDATE ar
    SET ship_to_code = ''
    -- SELECT * 
    FROM dbo.armaster_all ar (ROWLOCK)
    WHERE ar.address_type = 0
          AND ar.ship_to_code <> '';

    -- TEMPORARY - ADD AMB DESIGNATIONS

    IF GETDATE()
       BETWEEN '10/1/2018' AND '1/1/2019'
    BEGIN
        ;WITH AMB
         AS (SELECT DISTINCT
                    amb.customer_code
             FROM adm_arcontacts amb
                 LEFT OUTER JOIN dbo.cvo_cust_designation_codes AS cdc
                     ON cdc.customer_code = amb.customer_code
                        AND cdc.code = amb.contact_code
             WHERE amb.contact_code = 'AMB'
                   AND cdc.code IS NULL)
        INSERT dbo.cvo_cust_designation_codes
        (
            customer_code,
            code,
            description,
            date_reqd,
            start_date,
            end_date,
            primary_flag,
            ship_to
        )
        SELECT AMB.customer_code,
               dc.code,
               dc.description,
               dc.date_reqd,
               '10/1/2018',
               '12/31/2018',
               0,
               ''
        FROM AMB
            CROSS JOIN dbo.cvo_designation_codes AS dc
        WHERE dc.code = 'AMB';
    END;

/*
INSERT dbo.cvo_designation_codes
(
    code,
    description,
    date_reqd,
    rebate
)
VALUES
(   'AMB',        -- code - varchar(10)
    'BCBG AMBASSADOR PROGRAM',        -- description - varchar(500)
    1,         -- date_reqd - smallint
    'N'         -- rebate - char(1)
    )
*/



END;







GO
GRANT EXECUTE ON  [dbo].[cvo_armaster_fixup_sp] TO [public]
GO
