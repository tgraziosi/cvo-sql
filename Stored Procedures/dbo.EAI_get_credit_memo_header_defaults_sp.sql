SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC
[dbo].[EAI_get_credit_memo_header_defaults_sp] @cust_code varchar(10),
                                           @EGCMHD_trx_ctrl_num VARCHAR(16) 
    AS
    BEGIN
    DECLARE @err int, 
            @err_desc varchar(255), 
            @remit_key varchar(10), 
            @back_order_flag varchar(1),
            @blanket varchar(1), 
            @type_code varchar(1), 
            @curr_key varchar(10), 
            @req_ship_date datetime, 
            @sch_ship_date datetime,
            @discount decimal(20,8), 
            @fob varchar(10), 
            @forwarder_key varchar(10),
            @location varchar(10), 
            @posting_code varchar(10), 
            @phone varchar(20),
            @status varchar(1), 
            @tax_id varchar(10), 
            @tax_perc decimal(20, 8),
            @terms varchar(10),
            @trx_ctrl_num VARCHAR(16), 
            @routing varchar(20), 
            @rate_type_home varchar(8),
            @rate_type_oper varchar(8), 
            @curr_factor decimal(20, 8), 
            @oper_factor decimal(20, 8),
            @date_entered datetime, 
            @dflt_ship_to varchar(10), 
            @salesperson varchar(8),
            @retval int, 
            @date_applied int, 
            @nat_cur_code varchar(10), 
            @oper_curr varchar(10), 
            @divop int,
            @consolidate_flag INT,
            @addr1 VARCHAR(40),
            @addr2 VARCHAR(40),
            @addr3 VARCHAR(40),
            @addr4 VARCHAR(40),
            @addr5 VARCHAR(40),
            @addr6 VARCHAR(40),
            @doc_ctrl_num VARCHAR(16),
            @org_id VARCHAR(30)
            
            
            
    SELECT @err = 0
    SELECT @curr_key = home_currency, 
           @oper_curr = oper_currency 
            FROM [glco] (nolock)
    SELECT @remit_key = remit_code,
           @back_order_flag = ISNULL(cast(ship_complete_flag as char(1)), '0'), 
           @curr_key = ISNULL(@curr_key, nat_cur_code), 
           @discount = trade_disc_percent, 
           @fob          = fob_code,
           @forwarder_key = forwarder_code,
           @posting_code = posting_code,
           @phone = contact_phone,
           @tax_id       = tax_code,
           @terms        = terms_code,
           @routing      = ship_via_code,
           @rate_type_home = rate_type_home, 
           @rate_type_oper = rate_type_oper,
           @nat_cur_code = nat_cur_code,
           @consolidate_flag = ISNULL([consolidated_invoices], 0),
           @addr1 = ISNULL([addr1], ''),
           @addr2 = ISNULL([addr2], ''),
           @addr3 = ISNULL([addr3], ''),
           @addr4 = ISNULL([addr4], ''),
           @addr5 = ISNULL([addr5], ''),
           @addr6 = ISNULL([addr6], '')
            FROM [arcust] (NOLOCK)
            WHERE [customer_code] = @cust_code 
    SELECT @salesperson = ''
    SELECT @salesperson = arsalesp.salesperson_code
            from arcust (NOLOCK)
            INNER JOIN arsalesp (NOLOCK)
                    ON [arsalesp].[salesperson_code] = [arcust].[salesperson_code]
            WHERE customer_code = @cust_code 
                    AND arsalesp.ddid IS NOT NULL
    --
    -- Choose a default ship-to in case it is a multi-ship to customer and FO didn't specify
    --
    SELECT @dflt_ship_to = ISNULL(MIN(ship_to_code), NULL) 
            FROM [arshipto] (NOLOCK)
            WHERE [customer_code] = @cust_code 
                    AND [status_type] = 1
    SELECT @date_applied = DATEDIFF(DD, '1/1/1753', GETDATE()) + 639906
    EXEC @retval = [CVO_Control]..mccurate_sp @date_applied, 
                                           @nat_cur_code, 
                                           @curr_key, 
                                           @rate_type_home,
                                           @curr_factor OUTPUT,
                                           0,
                                           @divop OUTPUT
    IF @retval <> 0 
        BEGIN
        SELECT @err = -1,
               @err_desc = CAST(@retval AS VARCHAR)
        SELECT error = @err,
               error_desc = @err_desc
        RETURN
        END
    EXEC @retval = [CVO_Control]..mccurate_sp @date_applied, 
                                           @nat_cur_code, 
                                           @oper_curr, 
                                           @rate_type_oper,
                                           @oper_factor OUTPUT,
                                           0,
                                           @divop OUTPUT
    IF @retval <> 0 
        BEGIN
        SELECT @err = -2,
               @err_desc = CAST(@retval AS VARCHAR)
        SELECT error = @err,
               error_desc = @err_desc
        RETURN
        END
    EXEC @retval = arnewnum_sp 2032,
                               @trx_ctrl_num OUTPUT    
    IF @retval <> 0 
        BEGIN
        SELECT @err = -3,
               @err_desc = CAST(@retval AS VARCHAR)
        SELECT error = @err,
               error_desc = @err_desc
        RETURN
        END
    --
    -- Translate the original invoice's trx_ctrl_num to a doc_ctrl_num to be used as the 
    -- apply_to_num on the credit memo.
    --
    SET @doc_ctrl_num = ''
    SELECT @doc_ctrl_num = ISNULL(doc_ctrl_num, '') , @org_id = org_id
            FROM [artrx] (NOLOCK)
            WHERE [trx_ctrl_num] = @EGCMHD_trx_ctrl_num
    --
    SELECT error = 0,
           error_desc = '',
           remit_key = @remit_key,
           back_order_flag  = @back_order_flag,
           blanket = @blanket, 
           curr_key = @curr_key,
           req_ship_date = @req_ship_date,
           sch_ship_date = @sch_ship_date,
           discount  = @discount,
           fob = @fob,
           forwarder_key = @forwarder_key,
           location  = @location,
           posting_code = @posting_code,
           phone = @phone,
           type_code = @type_code, 
           status = @status,
           tax_id = @tax_id,
           tax_perc = @tax_perc,
           terms = @terms,
           routing = @routing,
           rate_type_home = @rate_type_home,
           rate_type_oper = @rate_type_oper,
           curr_factor = @curr_factor,
           oper_factor = @oper_factor,
           dflt_ship_to = @dflt_ship_to,
           salesperson = @salesperson,
           addr1 = @addr1,
           addr2 = @addr2,
           addr3 = @addr3,
           addr4 = @addr4,
           addr5 = @addr5,
           addr6 = @addr6,
           trx_ctrl_num = @trx_ctrl_num,
           doc_ctrl_num = @doc_ctrl_num,
           org_id   = @org_id
    END
GO
GRANT EXECUTE ON  [dbo].[EAI_get_credit_memo_header_defaults_sp] TO [public]
GO
