SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_3pl_create_sales_order]
	@cust_code     	varchar(8) ,
	@ship_to       	varchar(10),
	@user_id	varchar(50),
	@begin_date_range varchar(15),
	@end_date_range	  varchar(15)
AS

DECLARE	@apply_date 	int,		@entered_date		int,		@home_type		varchar(8),	
	@oper_type	varchar(8),	@order_no		int,		@order_ext		int,
	@req_ship_date	datetime,	@sch_ship_date		datetime, 	@date_entered		datetime,
	@attention	varchar(40), 	@phone			varchar(20), 	@terms			varchar(10), 
	@routing	varchar(20),	@salesperson		varchar(40),	@ship_to_name		varchar(40),
	@cash_flag	char(1),	@remit_key		varchar(10),	@tax_rate		decimal(20, 8),
	@sales_comm	decimal(20, 8),	@total_tax		decimal(20, 8),	@total_discount		decimal(20, 8),
	@gross_sales	decimal(20, 8),	@curr_factor		decimal(20, 8),	@oper_factor		decimal(20, 8),
	@currency	varchar(8),	@ship_to_add_1		varchar(40),	@ship_to_add_2		varchar(40),
	@ship_to_add_3	varchar(40),	@ship_to_add_4		varchar(40),	@ship_to_add_5		varchar(40),
	@ship_to_city	varchar(40),	@ship_to_region		varchar(40),	@ship_to_state		varchar(40),
	@ship_to_zip	varchar(40),	@posting_code		varchar(10),	@curr_key		varchar(10), 
	@curr_type	char(1),	@taxable		decimal(20, 8),	@gl_rev_acct		varchar(50),
	@fob		varchar(10),	@line_no		int,		@price			decimal(20, 8),
	@part_no	varchar(30),	@location		varchar(10),	@description		varchar(255),
	@tax_id		varchar(10),	@ordered		decimal(20, 8), @shipped		decimal(20, 8),
	@price_type 	char(1),	@cost   	   	decimal(20, 8), @std_cost   		decimal(20, 8),
	@temp_price 	decimal(20, 8), @cr_ordered 	   	decimal(20, 8),	@cr_shipped 		decimal(20, 8),
	@discount   	decimal(20, 8), @std_direct_dolrs  	decimal(20, 8), @std_ovhd_dolrs  	decimal(20, 8),
	@std_util_dolrs decimal(20, 8), @service_agreement_flag char(1), 	@inv_available_flag 	char(1),
	@create_po_flag int, 		@payment_code 		varchar(15),	@note			varchar(255)


SELECT @order_ext       = 0,		 
       @req_ship_date   = GETDATE(),
       @sch_ship_date   = GETDATE(),
       @date_entered    = GETDATE(),
       @entered_date    = DATEDIFF(D, '1901-01-01', GETDATE()) + 693976,
       @apply_date      = DATEDIFF(D, '1901-01-01', GETDATE()) + 693976,
       @attention       = NULL,
       @phone	        = NULL,
       @salesperson     = NULL

SELECT 	@ship_to_name  	= address_name,
       	@ship_to_add_1 	= addr1,
       	@ship_to_add_2	= addr2,
       	@ship_to_add_3 	= addr3,
       	@ship_to_add_4 	= addr4,
       	@ship_to_add_5 	= addr5,
       	@ship_to_city  	= city,
       	@ship_to_region = territory_code,
       	@ship_to_state 	= state,
       	@ship_to_zip   	= postal_code,
       	@tax_id        	= tax_code,
       	@terms         	= terms_code,
       	@fob	      	= fob_code,
       	@posting_code  	= posting_code,
       	@home_type     	= rate_type_home,
       	@oper_type     	= rate_type_oper,
	@payment_code	= payment_code,
	@routing	= ship_via_code,
	@remit_key	= ISNULL(remit_code, ''),
	@curr_type	= CAST(ISNULL(one_cur_cust, 0) AS CHAR(1))
  FROM armaster
 WHERE customer_code 	= @cust_code
   AND ship_to_code  	= @ship_to

SELECT @currency = (SELECT TOP 1 currency FROM #order)
SELECT @location = location FROM #order WHERE line_no = 1

--Until eBackoffice tables field sizes are increased, only insert the userid (instead of domain\user)
SELECT @user_id = login_id FROM #temp_who

--orders INSERTS
	IF @payment_code = 'CASH'
		SELECT @cash_flag 	= 'Y'
	ELSE
		SELECT @cash_flag 	= 'N'
	SELECT @tax_rate	= 0
	SELECT @sales_comm 	= 0
	SELECT @total_tax 	= 0
	SELECT @total_discount 	= 0
	SELECT @gross_sales 	= 0
	SELECT @curr_factor 	= 1
	SELECT @oper_factor 	= 1
	SELECT @curr_key 	= @currency
--ord_list INSERTS
	SELECT @sales_comm      = 0
	SELECT TOP 1 @taxable   = ar.default_tax_type FROM arco ar ( nolock ) , glco gl ( nolock ) WHERE ar.company_id = gl.company_id	
	SELECT @gl_rev_acct     = i.sales_acct_code FROM in_account i , locations l WHERE l.aracct_code =i.acct_code AND l.location = @location AND ( i.void is null or i.void ='N' )

-----------------------------------------------------------------
	EXEC fs_curate_sp @apply_date, @currency, @home_type, @oper_type   

	IF (SELECT valid_shipto_flag FROM arcust (NOLOCK) WHERE customer_code = @cust_code) <> 1
	BEGIN
		ROLLBACK TRAN
		RAISERROR ('Invalid customer', 16, 1)
		RETURN -1
	END 

	UPDATE next_order_num SET last_no = last_no + 1 
	
	SELECT @order_no = last_no FROM next_order_num 

	SELECT @note = '3PL Date Range: ' + @begin_date_range + ' thru ' + @end_date_range

	INSERT INTO orders 
	(	    order_no, ext, cust_code, ship_to, req_ship_date, sch_ship_date, date_entered, who_entered, status, 
		    attention, phone, terms, routing, total_invoice, salesperson, tax_perc, invoice_no, fob, freight, printed, 
		    discount, label_no, ship_to_name, ship_to_add_1, ship_to_add_2, ship_to_city, ship_to_state, ship_to_zip, 
		    ship_to_region, total_amt_order, tax_id, cash_flag, special_instr, type, note, void, changed, remit_key, 
		    forwarder_key, freight_to, sales_comm, freight_allow_pct, back_ord_flag, route_code, route_no, cr_invoice_no, 
		    location, ship_to_country, total_tax, total_discount, f_note, blanket, gross_sales, curr_factor, curr_key, 
		    curr_type, ship_to_add_3, bill_to_key, load_no, ship_to_add_4, ship_to_add_5, oper_factor, tot_ord_tax, 
		    tot_ord_disc, tot_ord_freight, posting_code, rate_type_home, rate_type_oper, hold_reason, dest_zone_code, 
		    orig_no, orig_ext, multiple_flag, user_code, user_priority, user_category, consolidate_flag, blanket_amt
	)
	VALUES 
	(    	    @order_no, @order_ext, @cust_code, @ship_to, @req_ship_date, @sch_ship_date, @date_entered, SUBSTRING(@user_id, 1, 20), 'N', 
		    @attention, @phone, @terms, @routing, 0, @salesperson, @tax_rate, 0, @fob, 0, 'N', 
		    0, 0, @ship_to_name, @ship_to_add_1, @ship_to_add_2, @ship_to_city, @ship_to_state, @ship_to_zip, 
		    @ship_to_region, 0, @tax_id, @cash_flag, ' ', 'I', @note, 'N', 'N', @remit_key, 
                    '', '', @sales_comm, 0, '0', '', 0, 0, 
                    @location, ' ', @total_tax, @total_discount, '', 'N', @gross_sales, @curr_factor, @curr_key, 
		    @curr_type, @ship_to_add_3, @cust_code, 0, @ship_to_add_4, @ship_to_add_5, @oper_factor, 0, 
		    0, 0, @posting_code, @home_type, @oper_type, '', ' ',
		    0, 0, 'N', SUBSTRING(@user_id, 1, 8), '', '', 1, 0 --SCR#50225 04/22/08
	)
	
	INSERT INTO mod_orders (order_no, order_ext) VALUES (@order_no,  @order_ext)

	SELECT @ordered    = 1, 
               @shipped    = 0,
	       @price_type = 'X'

	SELECT  @cost       		= 0,
		@std_cost   		= 0,
		@temp_price 		= 0, 
		@cr_ordered 		= 0, 
		@cr_shipped 		= 0, 
		@discount   		= 0,
		@std_direct_dolrs 	= 0, 
		@std_ovhd_dolrs         = 0, 
		@std_util_dolrs         = 0, 
		@create_po_flag         = 0,
		@service_agreement_flag = 'N', 
		@inv_available_flag     = 'Y'

-- 	DECLARE ord_list_cursor CURSOR LOCAL FOR 
-- 		SELECT line_no, location, line_part, line_part_desc, price, currency FROM #order ORDER BY line_no
-- 	OPEN ord_list_cursor
-- 	FETCH NEXT FROM ord_list_cursor INTO @line_no, @location, @part_no, @description, @price, @currency
-- 	WHILE (@@FETCH_STATUS = 0)
-- 	BEGIN		

	SET @line_no = 0
	WHILE (@line_no >= 0)
	BEGIN
		SELECT @line_no = ISNULL((SELECT MIN(line_no) FROM #order WHERE line_no > @line_no), -1)
		IF @line_no = -1 
			BREAK

		SELECT @location = location, @part_no = line_part, @description = line_part_desc, @price = price
		  FROM #order
		 WHERE line_no = @line_no

		INSERT INTO ord_list 
		(	order_no, order_ext, line_no, location, part_no, [description], time_entered, ordered, shipped, price, price_type, 
			note, status, cost, who_entered, sales_comm, temp_price, cr_ordered, cr_shipped, discount, uom, conv_factor, void, 
			std_cost, cubic_feet, printed, lb_tracking, labor, direct_dolrs, ovhd_dolrs, util_dolrs, taxable, qc_flag, part_type, 
			orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, weight_ea, display_line, curr_price, oper_price, 
			std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, service_agreement_flag, inv_available_flag, create_po_flag 
		) 
		VALUES 
		(	@order_no, @order_ext, @line_no, @location, @part_no, @description, @date_entered, @ordered, @shipped, @price, @price_type,
			'', 'N', @cost, SUBSTRING(@user_id, 1, 20), @sales_comm, @temp_price, @cr_ordered, @cr_shipped, @discount, 'EA', 1, 'N', 
			@std_cost, 0, 'N', 'N', 0, 0, 0, 0, @taxable, 'N', 'M', 
			@part_no, '2', @gl_rev_acct, 0, @tax_id, 0, @line_no, @price, @price, 
			@std_direct_dolrs, @std_ovhd_dolrs, @std_util_dolrs, @service_agreement_flag, @inv_available_flag, @create_po_flag  
		)
	END

-- 		FETCH NEXT FROM ord_list_cursor INTO @line_no, @location, @part_no, @description, @price, @currency
-- 	END 
-- 	CLOSE      ord_list_cursor
-- 	DEALLOCATE ord_list_cursor

	--Do we want to insert into: Ord_Rep?
	--Customer Sales Rep
	INSERT INTO ord_rep (order_no, order_ext, salesperson, sales_comm, percent_flag, exclusive_flag, split_flag, display_line)
		SELECT  @order_no, @order_ext, cust_rep.salesperson, cust_rep.sales_comm, cust_rep.percent_flag,
			cust_rep.exclusive_flag, cust_rep.split_flag, 1
		FROM {oj cust_rep LEFT OUTER JOIN arsalesp ON cust_rep.salesperson = arsalesp.salesperson_code}     
		WHERE ( dbo.cust_rep.customer_key = @cust_code )  
		ORDER BY cust_rep.salesperson ASC  

	--Do we want to insert into: Ord_Payment?
	INSERT INTO ord_payment (order_no, order_ext, seq_no, trx_desc, date_doc, payment_code, amt_payment, prompt1_inp, prompt2_inp, prompt3_inp, prompt4_inp, amt_disc_taken, cash_acct_code, doc_ctrl_num)
		VALUES (@order_no, @order_ext, 1, '', getdate(), @payment_code, 0.00000000, '', '', '', '', 0.00000000, '', '' )

	--SCR#50225 04/22/08
	CREATE TABLE #arcrchk (  customer_code		varchar(8), check_credit_limit		smallint,
		 credit_limit		float, limit_by_home		smallint)
	--SCR#50225 04/22/08

	EXEC fs_calculate_oetax_wrap @order_no,  @order_ext
	EXEC fs_updordtots           @order_no,  @order_ext 	
	EXEC fs_archklmt_sp_wrap     @cust_code, @entered_date, @order_no, @order_ext

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_create_sales_order] TO [public]
GO
