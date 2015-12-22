SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

    
    --  Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
    CREATE PROCEDURE 
[dbo].[EAI_create_rma] (@FO_RMAID VARCHAR(50))
    AS
    BEGIN
    DECLARE @acct_code VARCHAR(8)
    DECLARE @clevel CHAR(1)
    DECLARE @counter int, @c_part_no VARCHAR(30), @c_line_no int, @c_time_entered datetime    -- rev 2
    DECLARE @Distribution_Installed CHAR(3)
    DECLARE @dummyint int
    DECLARE @dummyVARCHAR VARCHAR(10)
    DECLARE @dummydecimal DECIMAL(20,8)
    DECLARE @dummychar CHAR(1)
    DECLARE @curr_key VARCHAR(10)
    DECLARE @curr_factor DECIMAL(20,8)
    DECLARE @cust_code VARCHAR(20)
    DECLARE @err_desc VARCHAR(255)
    DECLARE @err_no int
    DECLARE @location VARCHAR(10)
    DECLARE @loop int
    DECLARE @new_batch_code VARCHAR(16)
    DECLARE @new_rma_no int
    DECLARE @orig_order_no int
    DECLARE @orig_order_ext int
    DECLARE @ord_location VARCHAR(10)
    DECLARE @ol_loop int
    DECLARE @part_no VARCHAR(30)
    DECLARE @part_type CHAR(1)
    DECLARE @pct DECIMAL(20,8)
    DECLARE @price DECIMAL(20,8)
    DECLARE @qty DECIMAL(20,8)
    DECLARE @rev_flag int
    DECLARE @serv_agr CHAR(1), @gl_rev_acct VARCHAR(32)                    -- rev 2
    DECLARE @shipto VARCHAR(10)
    DECLARE @SP_Result INT
    DECLARE @tot_amt_ordered DECIMAL(20,8)
    DECLARE @tot_ord_disc DECIMAL(20,8)
    DECLARE @tot_tax DECIMAL(20,8)
    DECLARE @row_amt DECIMAL(20,8), @row_qty DECIMAL(20,8)                    -- rev 4
    DECLARE @userid INT
    --    
    -- Initialize.
    --
    SELECT @tot_amt_ordered = 0.0, 
           @tot_ord_disc = 0.0, 
           @tot_tax = 0.0
    SELECT @err_no = 0
    SELECT @userid = [user_id] 
            FROM [CVO_Control]..[smusers] 
            WHERE [user_name] = SUSER_SNAME()
    --
    -- Do some validation.
    --  
    IF NOT EXISTS (SELECT armaster.customer_code FROM armaster, EAI_RMAHeader erh (NOLOCK) WHERE erh.FO_cust_code = armaster.ddid AND erh.FO_RMAID = @FO_RMAID)
        BEGIN    
        SELECT @err_desc = 'This customer does not exist'
        SELECT @err_no = 100
        SELECT error = @err_no,
               error_desc = @err_desc
        RETURN
        END
    IF NOT EXISTS (SELECT * FROM EAI_RMAHeader WHERE FO_RMAID = @FO_RMAID)
        BEGIN
        SELECT @err_desc = 'Order: ' + @FO_RMAID + ' does not exist'
        SELECT @err_no = 110
        SELECT error = @err_no,
               error_desc = @err_desc
        RETURN
        END
    IF NOT EXISTS (SELECT * FROM EAI_RMADetail WHERE FO_RMAID = @FO_RMAID)
        BEGIN
        SELECT @err_desc = 'Order: ' + @FO_RMAID + ' does not have any detail lines associated with it.'
        SELECT @err_no = 120
        SELECT error = @err_no,
               error_desc = @err_desc
        RETURN
        END 
    --    
    CREATE table #t_orders  
            (FO_RMAID VARCHAR(50),
             FO_cust_code VARCHAR(50),    
             order_no int DEFAULT 0, 
             ext int DEFAULT 0, 
             cust_code VARCHAR (10),
             clevel CHAR(1),
             ship_to VARCHAR(10),
             date_entered datetime, 
             who_entered VARCHAR(20),
             status CHAR(1) DEFAULT 'N', 
             attention VARCHAR(40), 
             phone VARCHAR(20), 
             terms VARCHAR(10), 
             routing VARCHAR(20),
             special_instr VARCHAR(255), 
             salesperson VARCHAR(10), 
             tax_id VARCHAR(10) , 
             invoice_no int DEFAULT 0, 
             fob VARCHAR(10), 
             printed CHAR(1) DEFAULT 'N', 
             discount DECIMAL(20,8), 
             ship_to_name VARCHAR(40), 
             ship_to_add_1 VARCHAR(40), 
             ship_to_add_2 VARCHAR(40),
             ship_to_add_3 VARCHAR(40),
             ship_to_add_4 VARCHAR(40),    -- rev 4 
             ship_to_city VARCHAR(40),    -- rev 2
             ship_to_state VARCHAR(2), 
             ship_to_zip VARCHAR(10), 
             ship_to_region VARCHAR(10), 
             cash_flag CHAR(1) DEFAULT 'N', 
             type CHAR(1) DEFAULT 'C', 
             cr_invoice_no int, 
             changed CHAR(1) DEFAULT 'Y', 
             location VARCHAR(10), 
             blanket CHAR(1), 
             curr_key VARCHAR(10), 
             curr_type CHAR(1) DEFAULT 1, 
             curr_factor DECIMAL(20,8) DEFAULT 1.0, 
             billto_key VARCHAR(10), 
             tot_ord_tax DECIMAL(20,8) DEFAULT 0,     
             tot_ord_disc DECIMAL(20,8) DEFAULT 0, 
             tot_ord_freight DECIMAL(20,8) DEFAULT 0,
             posting_code VARCHAR(10), 
             rate_type_home VARCHAR(8), 
             rate_type_oper VARCHAR(8), 
             dest_zone_code VARCHAR(8), 
             note VARCHAR(255), 
             orig_no int, 
             orig_ext int, 
             req_ship_date datetime, 
             sch_ship_date datetime,
             total_amt_order DECIMAL(20,8) DEFAULT 0,
             curr_row int identity(1,1),
             addr1 VARCHAR(40) NULL DEFAULT '',
             addr2 VARCHAR(40) NULL DEFAULT '',
             addr3 VARCHAR(40) NULL DEFAULT '',
             addr4 VARCHAR(40) NULL DEFAULT '',
             addr5 VARCHAR(40) NULL DEFAULT '',
             addr6 VARCHAR(40) NULL DEFAULT '',
             consolidate_flag INT NULL DEFAULT 0,
	     user_stat VARCHAR (8) DEFAULT '')
    CREATE table #t_ord_list  
            (FO_RMAID VARCHAR(50),
             order_no int DEFAULT 0, 
             order_ext int DEFAULT 0, 
             line_no int, 
             location VARCHAR(10), 
             part_no VARCHAR(30), 
             description VARCHAR(255), 
             time_entered datetime, 
             ordered DECIMAL(20,8) DEFAULT 0, 
             shipped DECIMAL(20,8) DEFAULT 0, 
             price DECIMAL(20,8), 
             price_type CHAR(1) DEFAULT 1, 
             note VARCHAR(255), 
             status CHAR(1) DEFAULT 'N', 
             cost DECIMAL(20,8), 
             who_entered VARCHAR(20), 
             cr_ordered DECIMAL(20,8), 
             cr_shipped DECIMAL(20,8) DEFAULT 0, 
             discount DECIMAL(20,8), 
             uom CHAR(2), 
             conv_factor DECIMAL(20,8), 
             std_cost DECIMAL(20,8),
             cubic_feet DECIMAL(20,8), 
             printed CHAR(1) DEFAULT 'N', 
             lb_tracking CHAR(1), 
             labor DECIMAL(20,8), 
             direct_dolrs DECIMAL(20,8) DEFAULT 0, 
             ovhd_dolrs DECIMAL(20,8) DEFAULT 0, 
             util_dolrs DECIMAL(20,8) DEFAULT 0, 
             taxable int, 
             weight_ea DECIMAL(20,8),  
             qc_flag CHAR(1),
             reason_code VARCHAR(10), 
             part_type CHAR(1), 
             orig_part_no VARCHAR(30), 
             gl_rev_acct VARCHAR(32), 
             total_tax DECIMAL(20,8) DEFAULT 0, 
             tax_code VARCHAR(10), 
             curr_price DECIMAL(20,8), 
             oper_price DECIMAL(20,8), 
             display_line int, 
             std_direct_dolrs DECIMAL(20,8) DEFAULT 0, 
             std_ovhd_dolrs DECIMAL(20,8) DEFAULT 0, 
             std_util_dolrs DECIMAL(20,8) DEFAULT 0, 
             reference_code VARCHAR(32), 
             contract VARCHAR(16), 
             agreement_id VARCHAR(32), 
             ship_to VARCHAR(10),
             service_agreement_flag CHAR(1) DEFAULT 'N',
             orig_line_no int,
             orig_order_no int,
             orig_order_ext int,
             curr_key VARCHAR(10), 
             curr_factor DECIMAL(20,8),
             ol_curr_row int identity (1,1))
    CREATE TABLE #t_ordkit 
            (order_no int,
             order_ext int DEFAULT 0,
             line_no int,
             location VARCHAR(10),
             part_no VARCHAR(30),
             part_type CHAR(1),
             ordered DECIMAL(20,8) DEFAULT 0,
             shipped DECIMAL(20,8) DEFAULT 0,
             status CHAR(1) DEFAULT 'N',
             lb_tracking CHAR(1) DEFAULT 'N',
             cr_ordered DECIMAL(20,8),
             cr_shipped DECIMAL(20,8) DEFAULT 0,
             uom CHAR(2),
             conv_factor DECIMAL(20,8),
             cost DECIMAL(20,8) DEFAULT 0,
             labor DECIMAL(20,8) DEFAULT 0,
             direct_dolrs DECIMAL(20,8) DEFAULT 0,
             ovhd_dolrs DECIMAL(20,8) DEFAULT 0,
             util_dolrs DECIMAL(20,8) DEFAULT 0,
             note VARCHAR(255),
             qty_per DECIMAL(20,8),
             qc_flag CHAR(1),
             qc_no int DEFAULT 0,
             description VARCHAR(40) )
    CREATE TABLE #t_price
            (plevel CHAR(1), 
             price DECIMAL(20,8), 
             nextqty DECIMAL(20,8),
             nextprice DECIMAL(20,8), 
             promo DECIMAL(20,8),
             sales_comm DECIMAL(20,8),
             quote_loop# int,
             quote_level int, 
             curr_key VARCHAR(10) )
    SELECT @part_type = ''
    IF EXISTS (SELECT part_no FROM EAI_RMADetail erd WHERE erd.FO_RMAID = @FO_RMAID AND erd.part_no not in (SELECT part_no FROM inv_master))
        BEGIN
        /* rev 2 -- if the part doesn't exist, set it as a miscellaneous item */
        SELECT @part_type = 'M'
        END 
    IF EXISTS (SELECT * FROM EAI_RMAKit erk WHERE erk.FO_RMAID = @FO_RMAID AND erk.part_no not in (SELECT part_no FROM inv_master))
        BEGIN
        SELECT @err_desc =  'Part No. - ' + ( SELECT min(part_no) FROM EAI_RMAKit erk WHERE erk.part_no not in (SELECT part_no FROM inv_master)) + ' in Custom Kit does not exist'
        SELECT @err_no = 130
        SELECT error = @err_no,
               error_desc = @err_desc
        RETURN
        END
    BEGIN TRAN
    INSERT INTO #t_orders (FO_RMAID, FO_cust_code,
                           location, 
                           cust_code, clevel, ship_to, date_entered, who_entered,    /*a*/
                           attention, phone, terms, routing, special_instr, salesperson, tax_id, fob,  discount, ship_to_name,    /*b*/
                           ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4, ship_to_city, ship_to_state,
                           ship_to_zip, ship_to_region,    /*c, rev 1*/ /* rev 4 */
                           cr_invoice_no,  blanket, curr_key, curr_factor, billto_key, posting_code, rate_type_home,         /*d*/
                           rate_type_oper, dest_zone_code, note, orig_no, orig_ext, req_ship_date, sch_ship_date)            /*e*/
            SELECT distinct erh.FO_RMAID, FO_cust_code,                                /*a*/
                    ISNULL((SELECT il.location FROM inv_list il WHERE il.part_no = erd.part_no AND il.location = ar.location_code), (SELECT il.location FROM inv_list il WHERE il.part_no = erd.part_no AND il.location = ar.alt_location_code)),
                    arm.customer_code, ar.price_level, arm.ship_to_code, erh.date_entered, erh.who_entered,
                    ar.attention_name, ar.attention_phone, ar.terms_code, arm.route_code, ar.special_instr,         /*b*/
                    ar.salesperson_code, ar.tax_code,  ar.fob_code,  ar.trade_disc_percent,    ar.customer_name,
                    ar.addr1, ar.addr2, ar.addr3, ar.addr4,        /* rev 8 */
                    ar.city, Left(ar.state, 2), ar.postal_code, ar.territory_code,            /*c, rev 1*/
                    ISNULL((SELECT o.invoice_no FROM orders o WHERE o.order_no = eox.BO_order_no AND o.ext = eox.BO_order_ext), 0), /*d*/
                    ISNULL((SELECT o.blanket FROM orders o WHERE o.order_no = eox.BO_order_no AND o.ext = eox.BO_order_ext),'N'),
                    erh.curr_key, erd.curr_factor, arm.customer_code, ar.posting_code, ar.rate_type_home,
                    ar.rate_type_oper, ar.dest_zone_code, ISNULL(erh.note, ar.note), ISNULL(eox.BO_order_no, 0),         /*e*/
                    ISNULL(eox.BO_order_ext,0), 
                    ISNULL((SELECT o.req_ship_date FROM orders o WHERE o.order_no = eox.BO_order_no AND ext = eox.BO_order_ext),getdate()+1),
                    ISNULL((SELECT o.sch_ship_date FROM orders o WHERE o.order_no = eox.BO_order_no AND ext = eox.BO_order_ext),getdate()+1)
                    FROM EAI_RMAHeader erh, arcust ar, armaster arm,
                         EAI_RMADetail erd LEFT OUTER JOIN EAI_ord_xref eox 
                         ON (   erd.FO_orig_sales_order_id = eox.FO_order_no )
                    WHERE erh.FO_cust_code = arm.ddid 
                            AND arm.customer_code = ar.customer_code 
                            AND erh.FO_RMAID = @FO_RMAID
                            AND erh.FO_RMAID = erd.FO_RMAID 
    
    IF (@@error > 0) BEGIN
        ROLLBACK TRAN
        SELECT @err_desc = 'EAI_Create_rma:  error in first insert to t_orders'
        SELECT @err_no = 140
        SELECT error = @err_no,
               error_desc = @err_desc
        RETURN
        END
    UPDATE [#t_orders]
            SET [consolidate_flag] = [arcust].[consolidated_invoices],
                [addr1] = ISNULL([arcust].[addr1], ''),    
                [addr2] = ISNULL([arcust].[addr2], ''),
                [addr3] = ISNULL([arcust].[addr3], ''),    
                [addr4] = ISNULL([arcust].[addr4], ''),    
                [addr5] = ISNULL([arcust].[addr5], ''),    
                [addr6] = ISNULL([arcust].[addr6], '')
            FROM [#t_orders] 
            INNER JOIN [arcust]
                    ON [#t_orders].[cust_code] = [arcust].[customer_code]    
    UPDATE [#t_orders]
            SET [user_stat] = [so_usrstat].[user_stat_code]
            FROM [#t_orders] 
            INNER JOIN [so_usrstat]
                    ON [#t_orders].[status] = [so_usrstat].[status_code]
            WHERE [so_usrstat].[default_flag] = 1            
    UPDATE #t_orders 
            SET location = (ISNULL(location, (SELECT min(il.location) FROM inv_list il, EAI_RMADetail erd WHERE il.part_no = erd.part_no )))
            WHERE FO_RMAID = @FO_RMAID
    SELECT @loop = ISNULL((SELECT min(curr_row) FROM #t_orders),0)
    WHILE @loop > 0
        BEGIN
        SELECT @new_rma_no = last_no + 1 FROM next_order_num
        UPDATE next_order_num SET last_no = @new_rma_no
        UPDATE #t_orders SET order_no = @new_rma_no WHERE curr_row = @loop
        SELECT @ord_location = location, @orig_order_no = orig_no, @orig_order_ext = orig_ext, @curr_key = curr_key,
               @cust_code = cust_code, @clevel = clevel, @shipto = ship_to
                FROM #t_orders WHERE curr_row = @loop
        /* rev 2 -- if the part doesn't exist, set it as a miscellaneous item */
        If (@part_type <> 'M') 
            BEGIN    -- insert information FROM inv_master
            INSERT INTO #t_ord_list (FO_RMAID, order_no, orig_line_no, location, part_no, description, time_entered,  
                                     price,  note, cost, who_entered, cr_ordered, discount, uom, conv_factor, std_cost,
                                     cubic_feet, lb_tracking, labor,  taxable, weight_ea, qc_flag,
                                     part_type, orig_part_no, tax_code, curr_price, oper_price, display_line, 
                                     ship_to, orig_order_no, orig_order_ext, curr_key, curr_factor)
                    SELECT erd.FO_RMAID, @new_rma_no, erd.line_no, @ord_location, erd.part_no, im.description, erd.date_entered, 
                           erd.curr_price ,  im.note, im.std_cost, erd.who_entered, erd.cr_ordered,ISNULL(ar.trade_disc_percent, 0.0), 
                           im.uom, im.conv_factor, im.std_cost, im.cubic_feet, im.lb_tracking, im.labor, 
                           im.taxable, im.weight_ea, im.qc_flag, im.status, erd.part_no, ar.tax_code, erd.curr_price,    
                           (erd.curr_price * erd.curr_factor), erd.line_no, arm.ship_to_code, @orig_order_no, @orig_order_ext,
                           @curr_key, erd.curr_factor               
                            FROM #t_orders erh, EAI_RMADetail erd LEFT OUTER JOIN EAI_ord_xref eox  
                                 ON ( erd.FO_orig_sales_order_id = eox.FO_order_no ) , 
                                 inv_master im,  inv_list il, arcust ar, armaster arm
                            WHERE erh.FO_cust_code = arm.ddid 
                                    AND arm.customer_code = ar.customer_code 
                                    AND erh.FO_RMAID = @FO_RMAID
                                    AND erh.FO_RMAID = erd.FO_RMAID 
                                    AND erd.part_no = im.part_no 
                                    AND erh.location = @ord_location 
                                    AND il.part_no = im.part_no 
                                    AND il.location = @ord_location 
            IF ((@@error > 0) 
                    or (@@rowcount = 0)) 
                BEGIN
                ROLLBACK TRAN
                SELECT @err_desc = 'EAI_Create_rma:  error in insert to #t_ord_list'
                SELECT @err_no = 150
                SELECT error = @err_no,
                       error_desc = @err_desc
                RETURN
                END
            END 
        ELSE    -- insert DEFAULT information as a miscellaneous item
            BEGIN
            INSERT INTO #t_ord_list 
                    (FO_RMAID, order_no, orig_line_no, location, part_no, description, time_entered,  
                     price,  note, cost, who_entered, cr_ordered, discount, uom, conv_factor,
                     std_cost, cubic_feet, lb_tracking, labor,  taxable, weight_ea, qc_flag, part_type, orig_part_no,
                     tax_code, curr_price, oper_price, display_line, ship_to, orig_order_no,
                     orig_order_ext, curr_key, curr_factor, 
                     ordered, shipped, direct_dolrs, ovhd_dolrs, util_dolrs, total_tax, 
                     std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs)
                   SELECT erd.FO_RMAID, @new_rma_no, erd.line_no, @ord_location, erd.part_no, 'miscellaneous part', erd.date_entered,
                          erd.curr_price, '', 0, erd.who_entered, erd.cr_ordered, ISNULL(ar.trade_disc_percent, 0.0), 'EA', 1,
                          0, 0, (case when (len(erd.serial_no) > 0) THEN 'Y' else 'N' END), 0, 0, 0, 'N', 'M', erd.part_no, 
                          ar.tax_code, erd.curr_price, (erd.curr_price * erd.curr_factor), erd.line_no, arm.ship_to_code, 
                          @orig_order_no, @orig_order_ext, @curr_key, erd.curr_factor,
                          0, 0, 0, 0, 0, 0, 0, 0, 0              
                           FROM #t_orders erh, EAI_RMADetail erd, arcust ar, armaster arm
                           WHERE erh.FO_cust_code = arm.ddid 
                                   AND arm.customer_code = ar.customer_code 
                                   AND erh.FO_RMAID = @FO_RMAID
                                   AND erh.FO_RMAID = erd.FO_RMAID 
                                   AND erh.location = @ord_location 
    
            IF (@@error > 0) 
                BEGIN
                ROLLBACK TRAN
                SELECT @err_desc = 'EAI_Create_rma:  error in insert to #t_ord_list'
                SELECT @err_no = 160
                SELECT error = @err_no,
                       error_desc = @err_desc
                RETURN
                END
            END
        -- first UPDATE all the info you can from the old order
        -- rev 2:  consolidated the UPDATEs
        UPDATE #t_ord_list 
                SET #t_ord_list.orig_line_no = ISNULL(ol.line_no, 0),
                    #t_ord_list.ordered = ISNULL(ol.ordered,0),
                    #t_ord_list.shipped = ISNULL(ol.shipped,0),
                    #t_ord_list.direct_dolrs = ISNULL(ol.direct_dolrs,0), 
                    #t_ord_list.ovhd_dolrs = ISNULL(ol.ovhd_dolrs,0),
                    #t_ord_list.util_dolrs = ISNULL(ol.util_dolrs,0),
                    #t_ord_list.orig_part_no = ISNULL(ol.orig_part_no, #t_ord_list.part_no),
                    #t_ord_list.gl_rev_acct = ISNULL(ol.gl_rev_acct,''),
                       -- if the curr_price is blank THEN see if the old order has a price
                    #t_ord_list.curr_price = (case when ((#t_ord_list.curr_price=0) or (#t_ord_list.curr_price IS NULL)) 
                        THEN ISNULL(ol.curr_price,0) END),
                    -- if the price is blank THEN see if the old order has a price
                    #t_ord_list.price = (case when ((#t_ord_list.price = 0) or (#t_ord_list.price IS NULL)) 
                        THEN ISNULL(ol.price,0) END),
                    -- oper_price
                    #t_ord_list.oper_price = (case when ((#t_ord_list.oper_price = 0 or #t_ord_list.oper_price IS NULL)) 
                        THEN ISNULL(ol.oper_price,0) END),
                    -- total tax
                    #t_ord_list.total_tax = (case when ((#t_ord_list.total_tax = 0 or #t_ord_list.total_tax IS NULL))
                        THEN ISNULL(ol.total_tax,0) END)
                FROM ord_list ol
                WHERE #t_ord_list.orig_order_no = ol.order_no 
                        AND #t_ord_list.orig_order_ext = ol.order_ext 
                        AND #t_ord_list.part_no = ol.part_no 
                        AND #t_ord_list.location = ol.location 
                        AND ISNULL(#t_ord_list.ship_to,0) = ISNULL(ol.ship_to,0)
    
        IF (@@error > 0) 
            BEGIN
            ROLLBACK TRAN
            SELECT @err_desc = 'EAI_Create_rma:  error in UPDATE to #t_ord_list'
            SELECT @err_no = 170
            SELECT error = @err_no,
                   error_desc = @err_desc
            RETURN
            END
        -- now we get the account info. This is defaulting to the returns account codes.
        -- rev 2--if there was a gl_rev_acct from the previous order, use that. otherwise, get one here
        SELECT @gl_rev_acct = ISNULL(RTRIM(gl_rev_acct),'') 
                FROM #t_ord_list
        IF (@gl_rev_acct = '') 
            BEGIN
            SELECT @rev_flag = ISNULL(MIN(default_rev_flag),1) 
                    FROM arco
            /* 01/31/01 MRD #6.1.2.12 - start */
            IF @rev_flag = 1
                --which means that this is a item accounts must be used.
                BEGIN
                IF @part_type <> 'M'
                    BEGIN
                    UPDATE #t_ord_list 
                            SET gl_rev_acct = (SELECT sales_return_code FROM in_account ia, inv_list il WHERE #t_ord_list.part_no = il.part_no AND #t_ord_list.location = il.location AND il.acct_code = ia.acct_code)
                    IF (@@error > 0) 
                        BEGIN
                        SELECT @err_desc = 'EAI_Create_rma:  error in updating gl_rev_acct'
                        SELECT @err_no = 175
                        SELECT error = @err_no,
                                error_desc = @err_desc
                        RETURN
                        END
                    END 
                ELSE
                    BEGIN
                    SELECT @serv_agr = (case when (EXISTS(SELECT 'X' FROM service_agreement WHERE item_id = @part_no)) THEN 'Y' else 'N' END)
                    IF @serv_agr = 'Y'
                        -- service agreement item
                        BEGIN
                        UPDATE #t_ord_list 
                                SET gl_rev_acct = (SELECT gl_ret_acct FROM service_agreement WHERE #t_ord_list.part_no = service_agreement.item_id) 
                        IF (@@error > 0) 
                            BEGIN
                            SELECT @err_desc = 'EAI_Create_rma:  error in updating gl_rev_acct'
                            SELECT @err_no = 180
                            SELECT error = @err_no,
                                   error_desc = @err_desc
                            RETURN
                            END
                        END
                    END
                END 
            /* 01/31/01 MRD #6.1.2.12 - end */
            ELSE -- which means that this is a customer return accounts are to be used
                BEGIN
                UPDATE #t_ord_list SET gl_rev_acct = (SELECT MIN(sales_ret_acct_code) FROM araccts a, #t_orders t WHERE t.posting_code = a.posting_code)    
                IF (@@error > 0) 
                    BEGIN
                    ROLLBACK TRAN
                    SELECT @err_desc = 'EAI_Create_rma:  error in updating gl_rev_acct'
                    SELECT @err_no = 190
                    SELECT error = @err_no,
                           error_desc = @err_desc
                    RETURN
                    END
                END
            END
        --rev 2:  UPDATE the #t_ord_list.line_no to be numeric
        DECLARE c_ord_list CURSOR for
        SELECT part_no, orig_line_no, time_entered 
                FROM #t_ord_list
                ORDER BY orig_line_no, part_no ASC
        OPEN c_ord_list
        SELECT @counter = 1
        FETCH c_ord_list 
                into @c_part_no, @c_line_no, @c_time_entered
        WHILE @@Fetch_status = 0 
            BEGIN
            UPDATE #t_ord_list 
                    SET line_no = @counter 
                    WHERE part_no = @c_part_no 
                            AND orig_line_no = @c_line_no 
                            AND time_entered = @c_time_entered
            SELECT @counter = @counter + 1
            fetch c_ord_list 
                    into @c_part_no, @c_line_no, @c_time_entered
            END    
        CLOSE c_ord_list
        DEALLOCATE c_ord_list
        -- rev 2:  if display_line is 0, THEN UPDATE it to use the line_no
        UPDATE #t_ord_list SET display_line = line_no
        SELECT @ol_loop = ISNULL(min(tol.ol_curr_row),0) 
                FROM #t_ord_list tol 
                WHERE (ISNULL(tol.price,0) = 0
                        AND ISNULL(tol.curr_price,0) = 0 
                        AND ISNULL(tol.oper_price,0) = 0) 
        IF (@@error > 0) 
            BEGIN
            ROLLBACK TRAN
            SELECT @err_desc = 'EAI_Create_rma:  error in finding the #t_ord_list loop'
            SELECT @err_no = 200
            SELECT error = @err_no,
                   error_desc = @err_desc
            RETURN
            END
        WHILE @ol_loop > 0
            BEGIN
            SELECT @part_no = part_no, @location = location, @qty = cr_ordered, @curr_factor = curr_factor
                    FROM #t_ord_list 
                    WHERE ol_curr_row = @ol_loop
            SELECT @serv_agr = (case when (EXISTS(SELECT 'X' FROM service_agreement WHERE item_id = @part_no)) THEN 'Y' else 'N' END)
            INSERT INTO #t_price 
            EXEC dbo.fs_get_price @cust_code, 
                                  @shipto, 
                                  @clevel, 
                                  @part_no, 
                                  @location, 
                                  1, 
                                  @qty, 
                                  @pct, 
                                  @curr_key, 
                                  @curr_factor, 
                                  @serv_agr
            SELECT @price = price FROM #t_price
            --this is updating all the currency types to the same
            /* only do UPDATE if there is no price for that row */
            UPDATE #t_ord_list 
                    SET curr_price = ISNULL(@price,0), price = ISNULL(@price,0), oper_price = ISNULL(@price,0) 
                    WHERE part_no = @part_no 
                            AND location = @location 
                            AND ISNULL(ship_to,0) = ISNULL(@shipto, 0)
                            AND ol_curr_row = @ol_loop
            IF (@@error > 0)
                BEGIN
                ROLLBACK tran
                SELECT @err_desc = 'EAI_Create_rma:  error in updating price'
                SELECT @err_no = 210
                SELECT error = @err_no,
                       error_desc = @err_desc
                RETURN
                END
            SELECT @ol_loop = ISNULL(min(tol.ol_curr_row),0) 
                    FROM #t_ord_list tol 
                    WHERE (ISNULL(tol.price,0) = 0 
                            AND ISNULL(tol.curr_price,0) = 0 
                            AND ISNULL(tol.oper_price,0) = 0) 
                            AND tol.ol_curr_row > @ol_loop
            END
        -- rev 2: consolidated these UPDATEs
        UPDATE #t_ord_list 
                SET    --if the direct dolrs is blank, get the information from the inv_list table
                    #t_ord_list.direct_dolrs = (case when (#t_ord_list.direct_dolrs = 0 or #t_ord_list.direct_dolrs IS NULL)
                    THEN (ISNULL(il.avg_direct_dolrs, 0)) END),
                    -- std_direct_dolrs
                    #t_ord_list.std_direct_dolrs = (case when (#t_ord_list.std_direct_dolrs = 0 or #t_ord_list.std_direct_dolrs IS NULL)
                        THEN (ISNULL(il.std_direct_dolrs, 0)) END),
                    -- same as above but for ovhd_dolrs
                    #t_ord_list.ovhd_dolrs = (case when (#t_ord_list.ovhd_dolrs = 0 or #t_ord_list.ovhd_dolrs IS NULL)
                        THEN (ISNULL(il.avg_ovhd_dolrs, 0)) END),
                    -- std_ovhd_dolrs
                    #t_ord_list.std_ovhd_dolrs = (case when (#t_ord_list.std_ovhd_dolrs = 0 or #t_ord_list.std_ovhd_dolrs IS NULL)
                        THEN (ISNULL(il.std_ovhd_dolrs, 0)) END),
                      -- same as above but for util_dolrs
                    #t_ord_list.util_dolrs = (case when (#t_ord_list.util_dolrs = 0 or #t_ord_list.util_dolrs IS NULL)
                        THEN (ISNULL(il.avg_util_dolrs, 0)) END),
                    -- std_util_dolrs
                    #t_ord_list.std_util_dolrs = (case when (#t_ord_list.std_util_dolrs = 0 or #t_ord_list.std_util_dolrs IS NULL)
                        THEN (ISNULL(il.std_util_dolrs, 0)) END)
                FROM inv_list il 
                WHERE #t_ord_list.part_no = il.part_no 
                        AND #t_ord_list.location = il.location 
        IF (@@error > 0) 
            BEGIN
            ROLLBACK tran
            SELECT @err_desc = 'EAI_Create_rma:  error in updating #t_ord_list'
            SELECT @err_no = 220
            SELECT error = @err_no,
                   error_desc = @err_desc
            RETURN
            END
        SELECT @part_type = part_type 
                FROM #t_ord_list 
                WHERE ol_curr_row = @loop
        IF (@part_type = 'C') -- if part is of type 'C' - Custom Kit
            BEGIN
            -- now UPDATE the kit info.
            INSERT INTO #t_ordkit (order_no, line_no, location ,part_no, part_type, 
                          lb_tracking, cr_ordered, uom, conv_factor,note, qty_per, qc_flag, description)
                    SELECT @new_rma_no, erk.line_no, @ord_location, erk.part_no, im.status, 
                           im.lb_tracking, tol.cr_ordered, im.uom, im.conv_factor, im.note, erk.qty_per, im.qc_flag, im.description
                            FROM EAI_RMAKit erk, inv_master im, #t_ord_list tol
                            WHERE erk.FO_RMAID = tol.FO_RMAID 
                                    AND erk.line_no = tol.line_no 
                                    AND erk.part_no = im.part_no
            IF (@@rowcount = 0)
                BEGIN
                ROLLBACK TRAN
                SELECT @err_desc = 'Custom Kit has no items'
                SELECT @err_no = 230
                SELECT error = @err_no,
                       error_desc = @err_desc
                RETURN
                END
            UPDATE #t_ordkit 
                    SET #t_ordkit.labor = ISNULL(olk.labor,0), 
                        #t_ordkit.direct_dolrs = ISNULL(olk.direct_dolrs,0),
                        #t_ordkit.ovhd_dolrs = ISNULL(olk.ovhd_dolrs,0), 
                        #t_ordkit.util_dolrs = ISNULL(olk.util_dolrs,0)
                    FROM ord_list_kit olk,  #t_ord_list tol
                    WHERE olk.order_no = tol.orig_order_no 
                            AND olk.order_ext = tol.orig_order_ext 
                            AND olk.line_no = tol.orig_line_no
            END
        /* rev 4 */
        SELECT @row_amt = ISNULL(#t_ord_list.price,0), 
               @row_qty = ISNULL(#t_ord_list.cr_ordered, 0) 
                FROM #t_ord_list 
                WHERE ol_curr_row = @loop
        SELECT @tot_amt_ordered = @tot_amt_ordered + ISNULL((@row_amt * @row_qty),0)
        /* end rev 4 */    
        SELECT @tot_ord_disc = @tot_amt_ordered * (SELECT discount FROM #t_orders WHERE curr_row = @loop) / 100     -- rev 3: make it a percentage 
        SELECT @tot_tax = sum(ISNULL(#t_ord_list.total_tax,0)) FROM #t_ord_list WHERE ol_curr_row = @loop
        UPDATE #t_orders 
                SET total_amt_order = @tot_amt_ordered, 
                    tot_ord_disc = @tot_ord_disc, 
                    tot_ord_tax = @tot_tax
                WHERE curr_row = @loop
        SELECT @loop = ISNULL((SELECT min(curr_row) FROM #t_orders WHERE curr_row > @loop),0)
        END
    INSERT INTO orders 
            (order_no, ext, cust_code, ship_to, date_entered, who_entered, status, attention, phone, terms, routing,
             special_instr, salesperson, tax_id, invoice_no, fob, printed, discount, ship_to_name, ship_to_add_1, ship_to_add_2,
             ship_to_add_3, ship_to_add_4, ship_to_state, ship_to_zip, ship_to_region, cash_flag, type,  cr_invoice_no, changed, 
             location, blanket, curr_key, curr_type, curr_factor, bill_to_key, tot_ord_tax, tot_ord_disc, tot_ord_freight,
             posting_code, rate_type_home, rate_type_oper, dest_zone_code, note, orig_no, orig_ext, req_ship_date, sch_ship_date,
             total_amt_order, back_ord_flag, freight_allow_pct, route_no, void, invoice_edi, user_code)
            SELECT order_no, ext, cust_code, ship_to, date_entered, who_entered, status, attention, phone, terms, routing,
                   special_instr, salesperson, tax_id, invoice_no, fob, printed, discount, ship_to_name, ship_to_add_1, ship_to_add_2,
                   ship_to_add_3, ship_to_add_4, ship_to_state, ship_to_zip, ship_to_region, cash_flag, type, cr_invoice_no, changed, 
                   location, blanket, curr_key, curr_type, curr_factor, billto_key, tot_ord_tax, tot_ord_disc, tot_ord_freight,
                   posting_code, rate_type_home, rate_type_oper, dest_zone_code, note, orig_no, orig_ext, req_ship_date, sch_ship_date,
                   total_amt_order, 0, 0, 0, 'N', 'N', user_stat
                    FROM #t_orders
    IF (@@error > 0) 
        BEGIN
        rollback tran
        SELECT @err_desc = 'EAI_Create_rma:  error in updating orders'
        SELECT @err_no = 240
        SELECT error = @err_no,
               error_desc = @err_desc
        RETURN
        END
    INSERT INTO ord_list (order_no, order_ext, line_no, location, part_no, 
                          description, time_entered, ordered, shipped, price, 
                          price_type, note, status, cost, who_entered, 
                          cr_ordered, cr_shipped, discount, uom, conv_factor, 
                          std_cost, cubic_feet, printed, lb_tracking, labor, 
                          direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, 
                          qc_flag, reason_code, part_type, orig_part_no, gl_rev_acct, 
                          total_tax, tax_code, curr_price, oper_price, display_line, 
                          std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, 
                          agreement_id, ship_to, service_agreement_flag, sales_comm, back_ord_flag,
                          create_po_flag, load_group_no, return_code, user_count)
            SELECT order_no, order_ext, line_no, location, part_no, 
                   description, time_entered, ordered, shipped, price, 
                   price_type, note, status, cost, who_entered, 
                   cr_ordered, cr_shipped, discount, uom, conv_factor, 
                   std_cost, cubic_feet, printed, lb_tracking, labor, 
                   direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, 
                   qc_flag, reason_code, part_type, orig_part_no, gl_rev_acct, 
                   total_tax, tax_code, curr_price, oper_price, display_line, 
                   std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, 
                   agreement_id, ship_to, service_agreement_flag, 0.0, 'N',
                   0, 0, '', 0
                    FROM #t_ord_list
    IF (@@error > 0) 
        BEGIN
        rollback tran
        SELECT @err_desc = 'EAI_Create_rma:  error in updating ord_list'
        SELECT @err_no = 250
        SELECT error = @err_no,
               error_desc = @err_desc
        RETURN
        END
    IF (@part_type = 'C') -- if part is of type 'C' - Custom Kit
        BEGIN
        INSERT INTO ord_list_kit 
                (order_no,order_ext,line_no,
                 location ,part_no ,part_type ,ordered ,shipped ,status ,lb_tracking ,cr_ordered ,
                 cr_shipped ,uom,conv_factor,cost ,labor ,direct_dolrs ,ovhd_dolrs ,util_dolrs ,note ,qty_per ,
                 qc_flag ,qc_no ,description )
                SELECT order_no,order_ext,line_no,
                       location ,part_no ,part_type ,ordered ,shipped ,status ,lb_tracking ,cr_ordered ,
                       cr_shipped ,uom,conv_factor,cost ,labor ,direct_dolrs ,ovhd_dolrs ,util_dolrs ,note ,qty_per ,
                       qc_flag ,qc_no ,description 
            FROM #t_ordkit
        IF (@@error > 0) 
            BEGIN
            rollback tran
            SELECT @err_desc= 'EAI_Create_rma:  error in updating ord_list_kit'
            SELECT @err_no = 250
            SELECT error = @err_no,
                   error_desc = @err_desc    
            RETURN
            END
        END
    DROP TABLE #t_orders
    DROP TABLE #t_ord_list
    DROP TABLE #t_ordkit
    SELECT error = @err_no
    COMMIT TRAN
    END    
GO
GRANT EXECUTE ON  [dbo].[EAI_create_rma] TO [public]
GO
