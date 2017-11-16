SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_nc_prepare_cust_import_sp] (@id INT)
AS
begin

/* 

STATUS CODES ARE NEW, PROCESSING, IN REVIEW, COMPLETE, FAILED

EXEC cvo_nc_prepare_cust_import_sp 2

	   -- UPDATE dbo.cvo_new_customer_req SET Upload_msg = null, customer_code = '', status = 'NEW'
	   -- UPDATE CVO_NEW_CUSTOMER_REQ SET STATUS = 'PROCESSING', upload_msg = null, customer_code = '' WHERE ID = 2
	   -- SELECT * FROM cvo_new_customer_req
		-- select * From cvo_cust_import order by row_id desc
*/

SET NOCOUNT ON;

DECLARE @status VARCHAR(20) ,
        @territory VARCHAR(10) ,
        @rep_code VARCHAR(10) ,
        @rep_email VARCHAR(100) ,
        @customer_name VARCHAR(100) ,
        @account_req_type VARCHAR(100) ,
        @contact_name VARCHAR(100) ,
        @contact_phone VARCHAR(50) ,
        @req_data VARCHAR(2000) , -- JSON string
        @datetime DATETIME ,
        @customer_code VARCHAR(12);

IF ( OBJECT_ID('tempdb.dbo.#req_data') IS NOT NULL )
    DROP TABLE #req_data;


CREATE TABLE #req_data
    (
        element_id INT NOT NULL,            /* internal surrogate primary key gives the order of parsing and the list order */
        sequenceNo INT NULL,                /* the place in the sequence for the element */
        parent_ID INT,                      /* if the element has a parent then it is in this column. The document is the ultimate parent, so you can get the structure from recursing from the document */
        Object_ID INT,                      /* each list or object has an object id. This ties all elements to a parent. Lists are treated as objects here */
        NAME NVARCHAR(2000),                /* the name of the object, null if it hasn't got one */
        StringValue NVARCHAR(MAX) NOT NULL, /*the string representation of the value of the element. */
        ValueType VARCHAR(10) NOT NULL /* the declared type of the value represented as a string in StringValue*/
    );

-- for testing
--DECLARE @id INT;
--SELECT @id = 1;

SELECT @status = ncr.status ,
       @territory = ncr.territory ,
       @rep_code = ncr.rep_code ,
       @rep_email = ncr.rep_email ,
       @customer_name = ncr.customer_name ,
       @account_req_type = ncr.account_req_type ,
       @contact_name = ncr.contact_name ,
       @contact_phone = ncr.contact_phone ,
       @req_data = ncr.req_data ,
       @datetime = ncr.datetime ,
       @customer_code = ncr.customer_code
FROM   dbo.cvo_new_customer_req AS ncr
WHERE  id = @id AND ISNULL(ncr.customer_code,'') = '' AND NCR.STATUS = 'PROCESSING';

IF @@rOWCOUNT = 0 
BEGIN
SELECT 'No items found to import'
RETURN
end


UPDATE dbo.cvo_new_customer_req SET Upload_msg = NULL WHERE ID = @ID


-- SELECT @req_data
-- TRUNCATE TABLE #req_data
INSERT #req_data ( element_id ,
                   sequenceNo ,
                   parent_ID ,
                   Object_ID ,
                   NAME ,
                   StringValue ,
                   ValueType )
       SELECT element_id ,
              sequenceNo ,
              parent_ID ,
              Object_ID ,
              NAME ,
              StringValue ,
              ValueType
       FROM   dbo.parseJSON(@req_data);


INSERT dbo.cvo_cust_import ( customer_code ,
                             ship_to_code ,
                             cust_name ,
                             addr1 ,
                             addr2 ,
                             addr3 ,
                             addr4 ,
                             city ,
                             state ,
                             postal_code ,
                             country ,
                             customer_type ,
                             POP_POB ,
                             attention_name ,
                             attention_phone ,
                             attention_email ,
                             contact_name ,
                             contact_phone ,
                             contact_email ,
                             fax_number ,
                             tax_code ,
                             terms_code ,
                             fob_code ,
                             territory_code ,
                             fin_chg_code ,
                             price_code ,
                             payment_code ,
                             statement_flag ,
                             statement_cycle ,
                             credit_limit ,
                             aging_limit ,
                             aging_check ,
                             aging_allowance ,
                             ship_complete ,
                             BO_RX_sc_flag ,
                             BO_non_RX_sc_flag ,
                             currency_code ,
                             carrier ,
                             rx_carrier ,
                             bo_carrier ,
                             add_cases ,
                             add_pattern ,
                             patterns_first ,
                             cons_shipments ,
                             rx_consolidated ,
                             allow_subs ,
                             commission ,
                             comm_perc ,
                             door ,
                             residential ,
                             user_category ,
                             credit_for_rets ,
                             freight_chg_flag ,
                             chargebacks ,
                             print_cm ,
                             co_op_eligible ,
                             co_op_thres_flag ,
                             co_op_thres_amt ,
                             co_op_rate ,
                             co_op_notes ,
                             metal_plastic ,
                             suns_optical ,
                             max_dollars ,
                             url ,
                             process ,
                             errormessage )
       SELECT '' ,                                    -- customer_code - varchar(8)
              '' ,                                    -- ship_to_code - varchar(8)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'customer_name' ) ,    -- cust_name - varchar(40)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'addr_1' ) ,           -- addr1 - varchar(40)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'addr_2' ) ,           -- addr2 - varchar(40)
              '' ,                                    -- addr3 - varchar(40)
              '' ,                                    -- addr4 - varchar(40)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'city' ) ,             -- city - varchar(40)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'state' ) ,            -- state - varchar(40)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'zip' ) ,              -- postal_code - varchar(15)
              ISNULL((   SELECT country_code FROM dbo.gl_country AS gc 
					WHERE gc.description = (SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'country' )) , ''),          -- country - varchar(3)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'cust_type' ) ,                     -- customer_type - varchar(40)
              'POB' ,                                 -- POP_POB - varchar(40)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'attn_name' ) ,        -- attention_name - varchar(40)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'attn_phone' ) ,       -- attention_phone - varchar(30)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'attn_email' ) ,       -- attention_email - varchar(255)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'contact_name' ) ,     -- contact_name - varchar(40)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'contact_phone' ) ,    -- contact_phone - varchar(30)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'contact_email' ) ,    -- contact_email - varchar(255)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'fax' ) ,              -- fax_number - varchar(30)
              'AVATAX' ,                              -- tax_code - varchar(8)
              'NET30' ,                               -- terms_code - varchar(8)
              'DEST' ,                                    -- fob_code - varchar(8)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'terr' ) ,             -- territory_code - varchar(8)
              'LATE' ,                                    -- fin_chg_code - varchar(8)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'discount' ) ,         -- price_code - varchar(8)
              'CHECK' ,                                    -- payment_code - varchar(8)
              '' ,                                    -- statement_flag - varchar(5) 1
              '' ,                                    -- statement_cycle - varchar(8) stmt25
              '' ,                                    -- credit_limit - varchar(20) 0
              '' ,                                    -- aging_limit - varchar(20) 30
              '' ,                                    -- aging_check - varchar(20) 30
              '' ,                                    -- aging_allowance - varchar(20) 0
              '' ,                                    -- ship_complete - varchar(5) 0
              '' ,                                    -- BO_RX_sc_flag - varchar(5) 0
              '' ,                                    -- BO_non_RX_sc_flag - varchar(5) 0
              '' ,                                    -- currency_code - varchar(8) USD
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'carrier' ) ,          -- carrier - varchar(8)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'carrier_rx' ) ,       -- rx_carrier - varchar(8)
              (   SELECT StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'carrier_bo' ) ,       -- bo_carrier - varchar(8)
              (   SELECT 1 -- StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'add_case' ) ,         -- add_cases - varchar(5) Y
              (   SELECT 0 -- StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'add_pattern' ) ,      -- add_pattern - varchar(5) N
              '' ,                                    -- patterns_first - varchar(5) 0
              (   SELECT 0 --  StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'consolidate_ship' ) , -- cons_shipments - varchar(5) 0/N
              (   SELECT 0 -- StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'consolidate_rx' ) ,   -- rx_consolidated - varchar(5) 0/N
              (   SELECT 0 -- StringValue
                  FROM   #req_data AS rd
                  WHERE  NAME = 'allow_sub' ) ,        -- allow_subs - varchar(5) 0/N
              '' ,                                    -- commission - varchar(5) 0/N (override)
              '' ,                                    -- comm_perc - varchar(10) 0
              '' ,                                    -- door - varchar(5) 1/Y
              '' ,                                    -- residential - varchar(5) 0/N
              '' ,                                    -- user_category - varchar(10) no default
              '' ,                                    -- credit_for_rets - varchar(5) 0
              '' ,                                    -- freight_chg_flag - varchar(5) 0
              '' ,                                    -- chargebacks - varchar(5) 0/N
              '' ,                                    -- print_cm - varchar(5) 1/Y
              '' ,                                    -- co_op_eligible - varchar(5) 0/N
              '' ,                                    -- co_op_thres_flag - varchar(5) N
              '' ,                                    -- co_op_thres_amt - varchar(20) 0
              '' ,                                    -- co_op_rate - varchar(20) 0
              '' ,                                    -- co_op_notes - varchar(255) ?? what is this ??
              '' ,                                    -- metal_plastic - varchar(5) 0/N
              '' ,                                    -- suns_optical - varchar(5) 0/N
              '' ,                                    -- max_dollars - varchar(20) 0
              '' ,                                    -- url - varchar(255)
              0 ,                                     -- process - int
              '';                                     -- errormessage - varchar(255)


IF ( OBJECT_ID('tempdb.dbo.#result') IS NOT NULL )
    DROP TABLE #result;
CREATE TABLE #result
    (
        row_id INT ,
        customer_code VARCHAR(12) ,
        ship_to_code VARCHAR(12) ,
        msg VARCHAR(5000)
    );

INSERT #result
EXEC dbo.cvo_upload_cust_sp;

UPDATE ncr
SET    ncr.status = CASE WHEN r.customer_code = '' THEN 'FAILED'
                         ELSE 'COMPLETE'
                    END ,
       ncr.customer_code = r.customer_code ,
       ncr.upload_msg = r.msg
FROM   dbo.cvo_new_customer_req AS ncr 
       CROSS JOIN #result r
	   WHERE id = @id;

END

GRANT EXECUTE ON cvo_nc_prepare_cust_import_sp TO public

GO
GRANT EXECUTE ON  [dbo].[cvo_nc_prepare_cust_import_sp] TO [public]
GO
