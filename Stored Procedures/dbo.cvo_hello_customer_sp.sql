SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_hello_customer_sp]
    @cust VARCHAR(12) ,
    @phone VARCHAR(20) = NULL ,
    @ship_to_code VARCHAR(12) = NULL ,
    @debug INT = 0
AS /*

exec cvo_hello_customer_sp '030774', '5599984076', null, null

exec cvo_hello_customer_sp '016585', '8024425530', null, null

exec cvo_hello_customer_sp '012808', '41673985399', null, null

*/

    BEGIN
        SET NOCOUNT ON;

        DECLARE @ship_to VARCHAR(12);
        DECLARE @today DATETIME;

        SET @today = GETDATE();
		
        IF OBJECT_ID('tempdb..#cust') IS NOT NULL
            DROP TABLE #cust;
        IF OBJECT_ID('tempdb..#info') IS NOT NULL
            DROP TABLE #info;

        CREATE TABLE #info
            (
              Info VARCHAR(9) ,
              cust_code VARCHAR(10) ,
              ship_to VARCHAR(10) ,
              order_no INT NULL ,
              ext INT NULL ,
              who_entered VARCHAR(20) NULL ,
              date_entered DATETIME NULL ,
              user_category VARCHAR(10) NULL ,
              status_desc VARCHAR(10) NULL ,
              carrier VARCHAR(12) NULL ,
              tracking VARCHAR(255) NULL ,
              total_invoice DECIMAL(20, 8) NULL,
			  hs_order_no VARCHAR(20) null           );
 
        IF OBJECT_ID('tempdb..#aging') IS NOT NULL
            DROP TABLE #aging;

        CREATE TABLE #aging
            (
              customer_code VARCHAR(8) ,
              doc_ctrl_num VARCHAR(16) ,
              date_doc VARCHAR(12) ,
              trx_type INT ,
              amt_net FLOAT(8) ,
              amt_paid_to_date FLOAT(8) ,
              balance FLOAT(8) ,
              on_acct_flag VARCHAR(2) ,
              nat_cur_code VARCHAR(8) ,
              apply_to_num VARCHAR(16) ,
              trx_type_code VARCHAR(8) ,
              trx_ctrl_num VARCHAR(16) ,
              status_code VARCHAR(5) ,
              status_date VARCHAR(12) ,
              [No column name] VARCHAR(20) ,
              age_bucket SMALLINT ,
              date_due VARCHAR(12) ,
              order_ctrl_num VARCHAR(16) ,
              comment_count INT ,
              [rowCount] INT
            );


        INSERT  INTO #aging
                ( customer_code ,
                  doc_ctrl_num ,
                  date_doc ,
                  trx_type ,
                  amt_net ,
                  amt_paid_to_date ,
                  balance ,
                  on_acct_flag ,
                  nat_cur_code ,
                  apply_to_num ,
                  trx_type_code ,
                  trx_ctrl_num ,
                  status_code ,
                  status_date ,
                  [No column name] ,
                  age_bucket ,
                  date_due ,
                  order_ctrl_num ,
                  comment_count ,
                  [rowCount]
                )
                EXEC dbo.cc_open_inv_sp @customer_code = @cust, -- varchar(8)
                    @sort_by = 1, -- tinyint
                    @sort_type = 1, -- tinyint
                    @date_type = 4, -- tinyint
                    @all_org_flag = 1, -- smallint
                    @from_org = 'CVO', -- varchar(30)
                    @to_org = 'CVO';





        SELECT DISTINCT
                ship_to_code
        INTO    #cust
        FROM    armaster ar
        WHERE   ar.status_type = 1
                AND ar.address_type <> 9
				-- AND ar.addr_sort1 <> 'Employee'
                AND ar.customer_code = @cust
                AND ar.ship_to_code = ISNULL(@ship_to_code, ar.ship_to_code)
                AND ar.contact_phone = ISNULL(@phone, ar.contact_phone);

        IF @debug = 1
            SELECT  *
            FROM    #cust AS c;


        SELECT  @ship_to = MIN(ship_to_code)
        FROM    #cust; 

        WHILE @ship_to IS NOT NULL
            BEGIN

                INSERT  INTO #info
                        ( Info, cust_code, ship_to )
                        SELECT  'Info' ,
                                @cust ,
                                @ship_to;

                INSERT  INTO #info
                        SELECT TOP ( 5 )
                                'RX Orders' Info ,
                                o.cust_code ,
                                o.ship_to ,
                                order_no ,
                                ext ,
                                who_entered ,
                                DATEADD(d, DATEDIFF(d, 0, date_entered), 0) date_entered ,
                                user_category ,
                                CASE WHEN o.status IN ( 'a', 'b', 'c' )
                                     THEN 'On Hold'
                                     WHEN o.status IN ( 'n', 'p', 'q' )
                                     THEN 'In Process'
                                     WHEN o.status IN ( 'r', 's', 't' )
                                     THEN 'Shipped'
                                     ELSE ''
                                END AS status_desc ,
                                o.routing carrier ,
                                tracking = ISNULL(( SELECT TOP ( 1 )
                                                            cs_tracking_no
                                                    FROM    tdc_carton_tx c
                                                    WHERE   c.order_no = o.order_no
                                                            AND c.order_ext = o.ext
                                                    ORDER BY c.date_shipped DESC
                                                  ), 'N/A') ,
                                o.total_invoice,
								ISNULL(o.user_def_fld4,'') hs_order_no
                        FROM    orders o
                        WHERE   status <> 'v'
                                AND type = 'I'
                                AND o.user_category LIKE 'rx%'
                                AND RIGHT(o.user_category, 2) <> 'rb'
                                AND o.who_entered <> 'backordr'
                                AND o.cust_code = @cust
                                AND o.ship_to = @ship_to
                        ORDER BY date_entered DESC;

                INSERT  INTO #info
                        SELECT TOP ( 1 )
                                'ST Order' Info ,
                                o.cust_code ,
                                o.ship_to ,
                                order_no ,
                                ext ,
                                who_entered ,
                                DATEADD(d, DATEDIFF(d, 0, date_entered), 0) date_entered ,
                                user_category ,
                                CASE WHEN o.status IN ( 'a', 'b', 'c' )
                                     THEN 'On Hold'
                                     WHEN o.status IN ( 'n', 'p', 'q' )
                                     THEN 'In Process'
                                     WHEN o.status IN ( 'r', 's', 't' )
                                     THEN 'Shipped'
                                     ELSE ''
                                END AS status_desc ,
                                o.routing carrier ,
                                tracking = ISNULL(( SELECT TOP ( 1 )
                                                            cs_tracking_no
                                                    FROM    tdc_carton_tx c
                                                    WHERE   c.order_no = o.order_no
                                                            AND c.order_ext = o.ext
                                                    ORDER BY c.date_shipped DESC
                                                  ), 'N/A') ,
                                o.total_invoice,
								ISNULL(o.user_def_fld4,'') hs_order_no
                        FROM    orders o
                        WHERE   status <> 'v'
                                AND type = 'I'
                                AND o.user_category LIKE 'st%'
                                AND RIGHT(o.user_category, 2) <> 'rb'
                                AND o.who_entered <> 'backordr'
                                AND o.cust_code = @cust
                                AND o.ship_to = @ship_to
                        ORDER BY date_entered DESC;
                INSERT  INTO #info
                        SELECT TOP ( 5 )
                                'Returns' Info ,
                                o.cust_code ,
                                o.ship_to ,
                                order_no ,
                                ext ,
                                who_entered ,
                                DATEADD(d, DATEDIFF(d, 0, date_entered), 0) date_entered ,
                                user_category ,
                                CASE WHEN o.status < 'r' THEN o.hold_reason
                                     WHEN o.status IN ( 'r', 's', 't' )
                                     THEN 'Received'
                                     ELSE ''
                                END AS status_desc ,
                                '' carrier ,
                                tracking = '' ,
                                o.total_invoice,
								ISNULL(o.user_def_fld4,'') hs_order_no
                        FROM    orders o
                        WHERE   status <> 'v'
                                AND type = 'C'
                                --AND o.user_category LIKE 'st%'
                                AND RIGHT(o.user_category, 2) <> 'rb'
                                --AND o.who_entered <> 'backordr'
                                AND o.cust_code = @cust
                                AND o.ship_to = @ship_to
                        ORDER BY date_entered DESC;

                SELECT  @ship_to = MIN(ship_to_code)
                FROM    #cust
                WHERE   ship_to_code > @ship_to;

            END; -- ship-to loop




    END;

    SELECT  ar.customer_code ,
            ar.ship_to_code ,
            ar.address_name ,
            ar.city ,
            ar.state ,
            ar.contact_name ,
            ar.contact_phone ,
            ar.contact_email ,
            slp.salesperson_name ,
            ar.territory_code ,
            ISNULL(rxe.code, 'No') RXE ,
            AR_Status = CAST(( SELECT   ROUND(SUM(balance),2)
                               FROM     #aging
                               WHERE    age_bucket <> 0 -- dont include future due amounts
                             ) AS money) ,
			-- SPACE(30) AS AR_Status , -- future
			designations.desig Active_designations,
            i.Info ,
            i.cust_code ,
            i.ship_to ,
            i.order_no ,
            i.ext ,
            i.who_entered ,
            i.date_entered ,
            i.user_category ,
            i.status_desc ,
            CASE WHEN i.tracking > '' AND tracking <> 'N/A'
                 THEN dbo.f_cvo_get_tracking_url(i.tracking, i.carrier)
                 ELSE 'N/A'
            END tracking ,
            i.total_invoice ,
            oi.doc_ctrl_num,
			i.hs_order_no
    FROM    #info AS i
            JOIN armaster ar ON ar.customer_code = i.cust_code
                                AND ar.ship_to_code = i.ship_to
            JOIN arsalesp slp ON slp.salesperson_code = ar.salesperson_code
            LEFT OUTER JOIN ( SELECT DISTINCT
                                        customer_code ,
                                        code
                              FROM      dbo.cvo_cust_designation_codes AS cdc
                              WHERE     code IN ( 'rx3', 'rx5', 'rx1', 'rx10' )
                                        AND @today BETWEEN ISNULL(cdc.start_date,
                                                              @today)
                                                   AND     ISNULL(cdc.end_date,
                                                              @today)
                            ) rxe ON rxe.customer_code = ar.customer_code
            LEFT OUTER JOIN dbo.orders_invoice AS oi ON oi.order_no = i.order_no
                                                        AND oi.order_ext = i.ext
			LEFT OUTER JOIN ( SELECT  distinct RIGHT(c.customer_code, 5) MergeCust ,
                            STUFF(( SELECT  ', ' + code
                                    FROM    cvo_cust_designation_codes (NOLOCK)
                                    WHERE   customer_code = c.customer_code
                                            AND ISNULL(start_date, @today) <= @today
                                            AND ISNULL(end_date, @today) >= @today
                                    FOR
                                    XML PATH('')
                                    ), 1, 1, '') desig
                    FROM      dbo.cvo_cust_designation_codes (NOLOCK) c
                ) AS designations ON designations.MergeCust = RIGHT(ar.customer_code,5)											
														
			;








GO
GRANT EXECUTE ON  [dbo].[cvo_hello_customer_sp] TO [public]
GO
