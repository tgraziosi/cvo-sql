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

exec cvo_hello_customer_sp '010879', '5599984076', null, null

exec cvo_hello_customer_sp '039226', '8024425530', null, null

exec cvo_hello_customer_sp '054421' , '41673985399', null, null

*/

    BEGIN
        SET NOCOUNT ON;

        DECLARE @ship_to VARCHAR(12);
        DECLARE @today DATETIME, @r12start DATETIME, @r12end datetime;

        SELECT @today = enddate FROM cvo_date_range_vw WHERE period = 'today'
		SELECT @r12start = begindate, @r12end = enddate FROM dbo.cvo_date_range_vw AS drv WHERE period = 'rolling 12 ty'

		
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
              status_desc VARCHAR(80) NULL ,
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
              cust_po_num VARCHAR(20) ,
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
                  cust_po_num ,
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
                                     THEN 'On Hold '+ ISNULL((SELECT ao.hold_reason FROM dbo.adm_oehold AS ao WHERE AO.hold_code = O.HOLD_REASON),'')
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
                        FROM    orders o (NOLOCK)
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
                                     THEN 'On Hold '+ ISNULL((SELECT ao.hold_reason FROM dbo.adm_oehold AS ao WHERE AO.hold_code = O.HOLD_REASON),'')
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
                        FROM    orders o (NOLOCK)
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
            AR_Status = CASE WHEN dbo.f_cvo_get_buying_group_name(dbo.f_cvo_get_buying_group(ar.customer_code, @today)) > '' 
								THEN 'Buying Group: '+dbo.f_cvo_get_buying_group_name(dbo.f_cvo_get_buying_group(ar.customer_code, @today))
									+ CASE WHEN cc.CC_Status='BG' THEN ': On Hold' ELSE '' end
							 WHEN arbal.Ar_balance > ar.credit_limit AND ar.check_credit_limit = 1 THEN 'Over Credit Limit'
							 WHEN arbal.Ar_balance < 0 THEN 'Credit Balance'
							 WHEN arbal.pd_balance > 0 THEN 'Past Due > 30 Days'
							 ELSE 'Current' END,
			arbal.Ar_balance,
			-- SPACE(30) AS AR_Status , -- future
			designations.desig Active_designations,
			CASE WHEN ISNULL(cl.CL_Status,0) = 1 THEN 'Yes' ELSE 'No' END AS  cl_status,
			cl.prog_frames_sold,
			ar.ship_via_code st_carrier,
			car.rx_carrier,
			car.bo_carrier,
			ar.price_code discount_code,
			rr.RAretpct,
			--
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
            JOIN armaster ar (nolock) ON ar.customer_code = i.cust_code
                                AND ar.ship_to_code = i.ship_to
			JOIN dbo.CVO_armaster_all AS car (nolock) ON car.customer_code = ar.customer_code AND car.ship_to = ar.ship_to_code
            JOIN arsalesp slp (NOLOCK) ON slp.salesperson_code = ar.salesperson_code
            LEFT OUTER JOIN 
			( SELECT DISTINCT
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
			LEFT OUTER JOIN 
			( SELECT  distinct RIGHT(c.customer_code, 5) MergeCust ,
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
			LEFT OUTER JOIN
			( SELECT  customer_code, SUM(balance) Ar_balance, 
									 SUM(CASE WHEN age_bucket > 1 THEN balance ELSE 0 end) pd_balance
							   FROM     #aging
                               WHERE    age_bucket <> 0 -- dont include future due amounts
							   GROUP BY customer_code
             ) arbal ON arbal.customer_code = ar.customer_code
			LEFT OUTER JOIN
			(SELECT customer_code, 	CC_Status = IsNull(status_code,'') 
				FROM	cc_cust_status_hist (NOLOCK) 
				WHERE	clear_date is NULL 
				AND		customer_code = @cust  
			) cc ON cc.customer_code = ar.customer_code		
			LEFT OUTER JOIN
			(SELECT customer, CL_Status = MAX(iscl), SUM(CASE WHEN promo_id <> '' THEN qsales ELSE 0 END) prog_frames_sold
			FROM cvo_sbm_details (nolock)
			JOIN inv_master i (NOLOCK) ON i.part_no = dbo.cvo_sbm_details.part_no
			WHERE yyyymmdd >= DATEADD(YEAR,-1,@today) 
			AND i.type_code IN ('frame','sun')
			GROUP BY customer
			) cl ON cl.customer = ar.customer_code
			LEFT OUTER JOIN
            (SELECT 	customer, RAretpct = CASE WHEN facts.grosssales = 0 THEN 0 ELSE facts.rareturns/facts.grosssales END
				from	
				(
				SELECT customer,
				SUM(ISNULL(sbm.asales,0)) - SUM(ISNULL((CASE WHEN return_code='exc' THEN sbm.areturns ELSE 0 end),0))  grosssales, 
				SUM(CASE WHEN ISNULL(sbm.return_code,'') = '' THEN ISNULL(sbm.areturns,0) ELSE 0 END) rareturns
				from
				cvo_sbm_details sbm (NOLOCK)
				WHERE 1=1 
				AND sbm.yyyymmdd BETWEEN @r12start AND @r12end
				GROUP BY sbm.customer
				) AS facts 
			) rr ON rr.customer = ar.customer_code

			;

GO
GRANT EXECUTE ON  [dbo].[cvo_hello_customer_sp] TO [public]
GO
