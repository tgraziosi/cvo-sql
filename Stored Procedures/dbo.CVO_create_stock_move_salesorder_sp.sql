SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 18/07/2012 - Create a stock move sales order for TBB order processing
-- v1.1 CT 09/08/2012 - Write order number to note on credit return
-- v1.2 CT 18/09/2012 - Corrections to list_price and amt_disc on cvo_ord_list
-- v1.3	CT 18/09/2012 - Note is now written by calling routine
-- v1.4	CT 28/02/2013 - New field on cvo_ord_list (free_frame)
-- v1.5 CB 16/07/2013 - Issue #927 - Buying Group Switching
-- v1.6 CT 03/12/2013 - Removed hardcoded apply date
-- v1.7 CB 06/01/2015 - Fix issue with st_consolidate not being populated
CREATE PROC [dbo].[CVO_create_stock_move_salesorder_sp] (@order_no INT, @order_ext INT, @cust_code VARCHAR(10), @ship_to VARCHAR(10))  
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@new_order_no			INT,
			@ship_complete_flag		SMALLINT,
			@so_priority_code		CHAR(1),
			@tax_code				VARCHAR(8),
			@ship_to_name			VARCHAR(40),
			@ship_to_add_1			VARCHAR(40),
			@ship_to_add_2			VARCHAR(40),
			@ship_to_add_3			VARCHAR(40),
			@ship_to_add_4			VARCHAR(40),
			@ship_to_add_5			VARCHAR(40),
			@ship_to_city			VARCHAR(40),
			@ship_to_state			VARCHAR(40),
			@ship_to_zip			VARCHAR(15),
			@ship_to_country		VARCHAR(40),
			@terms_code				VARCHAR(8),       
			@fob_code				VARCHAR(8),
			@territory_code			VARCHAR(8),
			@salesperson_code		VARCHAR(8),  
			@trade_disc_percent		FLOAT,
			@ship_via_code			VARCHAR(8),    
			@short_name				VARCHAR(10), 
			@nat_cur_code			VARCHAR(8),     
			@one_cur_cust			SMALLINT,
			@rate_type_home			VARCHAR(8),   
			@rate_type_oper			VARCHAR(8),
			@remit_code				VARCHAR(10),     	
			@forwarder_code			VARCHAR(10),
			@freight_to_code		VARCHAR(10),  
			@dest_zone_code			VARCHAR(8),
			@note					VARCHAR(255),             
			@special_instr			VARCHAR(255),
			@payment_code			VARCHAR(8),     
			@posting_code			VARCHAR(8),
			@price_level			CHAR(1),      
			@price_code				VARCHAR(8),
			@contact_name			VARCHAR(40),
			@contact_phone			VARCHAR(30),
			@status_type			SMALLINT,
			@error					INT, 
			@home_rate				FLOAT, 
			@oper_rate				FLOAT,
			@apply_date				INT,
			@consolidated_invoices	INT,
			@country_code			VARCHAR(3),
			@freight_type			VARCHAR(10),
			@line_no				INT,
			@pn						VARCHAR(30),
			@loc					VARCHAR(10),
			@qty					DECIMAL (20,8),
			@plevel					CHAR(1), 
			@price					DECIMAL(20,8),
			@price_qty				DECIMAL(20,8),
			@new_user_code			VARCHAR(8)

	-- Get user codes
	SELECT @new_user_code = user_stat_code FROM dbo.so_usrstat (NOLOCK) WHERE status_code = 'N' AND default_flag = 1 AND void = 'N'		

	-- Get zero freight freight type
	SELECT @freight_type = value_str FROM dbo.config WHERE flag = 'FRTHTYPE'

	-- Get the next order number
	BEGIN TRAN
		UPDATE	dbo.next_order_num  
		SET		last_no = last_no + 1 
	COMMIT TRAN
	SELECT @new_order_no = last_no  
	FROM dbo.next_order_num

	-- Get customer details
	SELECT 
		@consolidated_invoices = consolidated_invoices,
		@ship_complete_flag = ship_complete_flag,
		@so_priority_code = so_priority_code,
		@tax_code = tax_code,
		@ship_to_name = address_name,
		@ship_to_add_1 = addr2,
		@ship_to_add_2 = addr3,
		@ship_to_add_3 = addr4,
		@ship_to_add_4 = addr5,
		@ship_to_add_5 = addr6,
		@ship_to_city = city,
		@ship_to_state = [state],
		@ship_to_zip = postal_code,
		@ship_to_country = country,
		@terms_code	= terms_code,       
		@fob_code = fob_code,
		@territory_code	= territory_code,
		@salesperson_code = salesperson_code,  
		@trade_disc_percent	= trade_disc_percent,
		@ship_via_code	= ship_via_code,   
		@short_name = short_name,
		@nat_cur_code = nat_cur_code,
		@one_cur_cust = one_cur_cust,
		@rate_type_home = rate_type_home,   
		@rate_type_oper = rate_type_oper,
		@remit_code = remit_code,     	
		@forwarder_code = forwarder_code,
		@freight_to_code = freight_to_code,  
		@dest_zone_code	= dest_zone_code,
		@note = note,
		@special_instr = special_instr,
		@payment_code = payment_code,
		@posting_code = posting_code,
		@price_level = price_level,      
		@price_code = price_code,
		@contact_name = contact_name,
		@contact_phone = contact_phone,
		@status_type = status_type,
		@country_code = country_code
	FROM
		dbo.armaster_all (NOLOCK)
	WHERE
		address_type = 0
		AND customer_code = @cust_code

	-- If there is a ship to then update with the details from there
	IF ISNULL(@ship_to,'') <> ''
	BEGIN
 
		SELECT 
			@so_priority_code = so_priority_code,
			@tax_code = tax_code,
			@ship_to_name = address_name,
			@ship_to_add_1 = addr2,
			@ship_to_add_2 = addr3,
			@ship_to_add_3 = addr4,
			@ship_to_add_4 = addr5,
			@ship_to_add_5 = addr6,
			@ship_to_city = city,
			@ship_to_state = [state],
			@ship_to_zip = postal_code,
			@ship_to_country = country,
			@terms_code	= terms_code,       
			@fob_code = CASE ISNULL(fob_code,'') WHEN '' THEN @fob_code ELSE fob_code END,
			@territory_code	= territory_code,
			@salesperson_code = salesperson_code,  
			@ship_via_code	= ship_via_code,   
			@short_name = short_name,
			@nat_cur_code = nat_cur_code,
			@one_cur_cust = one_cur_cust,
			@remit_code = remit_code,     	
			@forwarder_code = forwarder_code,
			@freight_to_code = freight_to_code,  
			@dest_zone_code	= dest_zone_code,
			@note = note,
			@special_instr = special_instr,
			@price_level = price_level,      
			@contact_name = contact_name,
			@contact_phone = contact_phone,
			@status_type = status_type,
			@country_code = country_code
		FROM
			dbo.armaster_all (NOLOCK)
		WHERE
			address_type = 1
			AND customer_code = @cust_code
			AND ship_to_code = @ship_to
	END
 
	-- Get exchange rate
	SELECT @apply_date = datediff(day, '01/01/1900', getdate())+693596

	EXEC dbo.cvo_curate_sp	@apply_date = @apply_date, -- 734701, -- v1.6
							@from_currency = @nat_cur_code,
							@home_type = @rate_type_home,
							@oper_type = @rate_type_oper, 
							@error = @error OUTPUT, 
							@home_rate = @home_rate OUTPUT, 
							@oper_rate = @oper_rate OUTPUT 

	
	-- Copy the data from from the order to a new order
	INSERT INTO orders_all  (order_no,ext,cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,date_entered,cust_po,who_entered,status,attention,phone,terms,routing,special_instr,
											invoice_date,total_invoice,total_amt_order,salesperson,tax_id,tax_perc,invoice_no,fob,freight,printed,discount,label_no,cancel_date,new,ship_to_name,
											ship_to_add_1,ship_to_add_2,ship_to_add_3,ship_to_add_4,ship_to_add_5,ship_to_city,ship_to_state,ship_to_zip,ship_to_country,ship_to_region,cash_flag,type,back_ord_flag,
											freight_allow_pct,route_code,route_no,date_printed,date_transfered,cr_invoice_no,who_picked,note,void,void_who,void_date,changed,remit_key,forwarder_key,freight_to,
											sales_comm,freight_allow_type,cust_dfpa,location,total_tax,total_discount,f_note,invoice_edi,edi_batch,post_edi_date,blanket,gross_sales,load_no,
											curr_key,curr_type,curr_factor,bill_to_key,oper_factor,tot_ord_tax,tot_ord_disc,tot_ord_freight,posting_code,rate_type_home,rate_type_oper,
											reference_code,hold_reason,dest_zone_code,orig_no,orig_ext,tot_tax_incl,process_ctrl_num,batch_code,tot_ord_incl,barcode_status,multiple_flag,
											so_priority_code,FO_order_no,blanket_amt,user_priority,user_category,from_date,to_date,consolidate_flag,proc_inv_no,sold_to_addr1,sold_to_addr2,
											sold_to_addr3,sold_to_addr4,sold_to_addr5,sold_to_addr6,user_code,user_def_fld1,user_def_fld2,user_def_fld3,user_def_fld4,user_def_fld5,user_def_fld6,
											user_def_fld7,user_def_fld8,user_def_fld9,user_def_fld10,user_def_fld11,user_def_fld12,eprocurement_ind,sold_to,sopick_ctrl_num,organization_id,
											last_picked_dt,internal_so_ind,ship_to_country_cd,sold_to_city,sold_to_state,sold_to_zip,sold_to_country_cd,tax_valid_ind,addr_valid_ind)
	SELECT	@new_order_no, 0, @cust_code,@ship_to,GETDATE(),GETDATE(),NULL,GETDATE(),cust_po,who_entered,'N',@contact_name,@contact_phone,@terms_code,routing,@special_instr,
			NULL,total_invoice,total_amt_order,@salesperson_code,@tax_code,tax_perc,NULL,@fob_code,0,'N',0,0,NULL,NULL,@ship_to_name,
			@ship_to_add_1,@ship_to_add_2,@ship_to_add_3,@ship_to_add_4,@ship_to_add_5,@ship_to_city,@ship_to_state,@ship_to_zip,@ship_to_country,@territory_code,'N','I',@ship_complete_flag,
			0,'',0,NULL,NULL,0,NULL,@note,'N',NULL,NULL,'N','',@forwarder_code,@freight_to_code,
			0,@freight_type,NULL,location,0,0,'','N',NULL,NULL,'N',0,0,
			@nat_cur_code,0,@home_rate,@cust_code,@oper_rate,0,0,'0',@posting_code,@rate_type_home,@rate_type_oper,
			NULL,'',@dest_zone_code,0,0,0,'',0,0,NULL,'N',
			@so_priority_code,NULL,0,'','ST-TB',NULL,NULL,@consolidated_invoices,'',NULL,NULL,
			NULL,NULL,NULL,NULL,@new_user_code,'','SO',CONVERT(VARCHAR(20),GETDATE(),101) + ' ' + CONVERT(VARCHAR(8),GETDATE(),114) + ' ' + who_entered,'',0,0,
			0,0,0,0,0,0,0,NULL,'','CVO',
			NULL,0,@country_code,NULL,NULL,NULL,NULL,0,NULL
	FROM	dbo.orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- cvo_orders_all
	INSERT INTO CVO_orders_all(order_no,ext,add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
								commission_pct, stage_hold, prior_hold, credit_approved, replen_inv, st_consolidate) -- v1.7 		
	SELECT	@new_order_no, 0, 'N','N',NULL,NULL,'N','N',1,dbo.f_cvo_get_buying_group(@cust_code,GETDATE()), GETDATE(), -- v1.5
			NULL, 0, NULL, NULL,0, 0 -- v1.7
	FROM	dbo.orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

		-- ord_list
	INSERT	ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
								temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
								ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
								oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,
								inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
								unpicked_dt)
	SELECT	@new_order_no, 0, line_no, location, part_no, description, GETDATE(), cr_ordered, 0, price, price_type, '', 'N', cost, 
			who_entered, sales_comm, temp_price, temp_type, 0, 0, discount, uom, conv_factor, void, void_who, void_date, 
			std_cost, cubic_feet, 'N', 'N', labor, direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, NULL, 
			qc_no, rejected, 'M', part_no, @ship_complete_flag, gl_rev_acct, total_tax, @tax_code, curr_price, oper_price, display_line, 
			std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id, ship_to, service_agreement_flag,
			inv_available_flag, 0, load_group_no, NULL, user_count, NULL, organization_id, NULL, NULL, 
			NULL, NULL, NULL
	FROM	dbo.ord_list  (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- cvo_ord_list
	INSERT INTO CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
											is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame) -- v1.4
	SELECT	@new_order_no, 0, a.line_no,'N','N',ISNULL(a.from_line_no,0),a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
											a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, 0 -- v1.4		
	FROM	cvo_ord_list a (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- ord_list_kit
	INSERT INTO ord_list_kit (order_no,order_ext,line_no,location,part_no,part_type,ordered,shipped,status,lb_tracking,cr_ordered,cr_shipped,uom,conv_factor,
										cost,labor,direct_dolrs,ovhd_dolrs,util_dolrs,note,qty_per,qc_flag,qc_no,description)
	SELECT	@new_order_no, 0, line_no, location, part_no, 'M', cr_ordered, 0, 'N', 'N', 0, 0, uom,conv_factor,
			cost, labor, direct_dolrs, ovhd_dolrs, util_dolrs, note, qty_per, qc_flag, qc_no, description
	FROM	ord_list_kit (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- CVO_ord_list_kit
	INSERT INTO CVO_ord_list_kit(order_no,order_ext,line_no,location,part_no,replaced,new1,part_no_original)
	SELECT	@new_order_no, 0 , line_no, location, part_no, replaced, new1, part_no_original		
	FROM	cvo_ord_list_kit (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- Update order lines for customer pricing and additional part details
	CREATE TABLE #price (plevel CHAR(1), price decimal(20,8), next_qty decimal(20,8),  
       next_price decimal(20,8), promo_price decimal(20,8), sales_comm decimal(20,8),  
       qloop INT, quote_level INT, quote_curr VARCHAR(10))  

	SET @line_no = -1
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@line_no = line_no,
			@pn = part_no,
			@loc = location
		FROM
			dbo.ord_list
		WHERE
			order_no = @new_order_no 
			AND order_ext = 0
			AND line_no > @line_no
		ORDER BY 
			line_no
		
		IF @@ROWCOUNT = 0
			BREAK
		
		-- Get qty across order for part
		SELECT @qty = SUM(ordered) FROM dbo.ord_list where order_no = @new_order_no AND order_ext = 0 AND location = @loc AND part_no = @pn
		
		DELETE FROM #price

		SELECT @price_qty = @qty	
		-- If customer doesn't pricing doesn't exist, if part is set to list price only set qty = 0 to force list price
		IF EXISTS (SELECT 1 FROM dbo.f_customer_pricing_exists (@cust_code,@ship_to ,@pn, @qty) WHERE retval = 0)
		BEGIN
			IF EXISTS (SELECT 1 FROM dbo.inv_master_add (NOLOCK) WHERE	part_no = @pn AND ISNULL(field_33,'N') = 'Y') 
			BEGIN
				SET @price_qty = 0
			END

		END
		
		-- Get price
		INSERT INTO #price EXEC dbo.fs_get_price	@cust = @cust_code,
													@shipto = @ship_to,
													@clevel = '1',
													@pn = @pn,
													@loc = @loc,
													@plevel = '1',
													@qty = @price_qty,
													@pct = 0,
													@curr_key = @nat_cur_code,
													@curr_factor = 1,
													@svc_agr = 'N'  
		
		SELECT
			@price = price,
			@plevel = plevel
		FROM
			#price	

		UPDATE
			a
		SET
			price = @price,
			price_type = @plevel,
			temp_price = @price,
			temp_type = @plevel,
			conv_factor = @home_rate,
			curr_price = CASE WHEN @home_rate >= 1 THEN @price * @home_rate ELSE @price / @home_rate END,
			oper_price = CASE WHEN @oper_rate >= 1 THEN @price * @oper_rate ELSE @price / @oper_rate END,
			cost = b.avg_cost,
			ovhd_dolrs = b.std_ovhd_dolrs,
			util_dolrs = b.std_util_dolrs,	
			weight_ea = c.weight_ea,
			cubic_feet = c.cubic_feet,
			direct_dolrs = b.std_direct_dolrs,
			labor = b.labor
		FROM 
			dbo.ord_list a
		INNER JOIN
			dbo.inventory b (NOLOCK)
		ON
			a.part_no = b.part_no
			AND a.location = b.location	
		INNER JOIN
			dbo.inv_master c (NOLOCK)
		ON
			a.part_no = c.part_no		
		WHERE
			a.order_no = @new_order_no 
			AND a.order_ext = 0
			AND a.line_no = @line_no
	END

	DROP TABLE #price

	-- START v1.2
	UPDATE 
		a
	SET 
		list_price = d.price,
		amt_disc = 0 
	FROM 
		dbo.cvo_ord_list a  
	INNER JOIN 
		dbo.ord_list b (NOLOCK)  
	ON  
		a.order_no = b.order_no  
		AND a.order_ext = b.order_ext  
		AND  a.line_no = b.line_no  
	INNER JOIN 
		dbo.adm_inv_price c (NOLOCK)  
	ON  
		b.part_no = c.part_no  
	INNER JOIN 
		dbo.adm_inv_price_det d (NOLOCK)  
	ON  
		c.inv_price_id = d.inv_price_id  
	WHERE 
		c.active_ind = 1 
		AND a.order_no = @new_order_no
		AND a.order_ext = 0
	-- END v1.2

	-- Auto ship
	UPDATE
		dbo.ord_list
	SET
		shipped = ordered,
		[status] = 'P'
	WHERE
		order_no = @new_order_no
		AND order_ext = 0

	UPDATE
		dbo.orders_all
	SET
		[status] = 'P',
		printed = 'P'
	WHERE
		order_no = @new_order_no
		AND ext = 0

	UPDATE
		dbo.ord_list
	SET
		[status] = 'R'
	WHERE
		order_no = @new_order_no
		AND order_ext = 0

	UPDATE
		dbo.orders_all
	SET
		date_shipped = GETDATE(),
		[status] = 'R',
		printed = 'R'
	WHERE
		order_no = @new_order_no
		AND ext = 0
	

	EXEC dbo.fs_calculate_oetax_wrap @ord = @new_order_no,@ext = 0,@batch_call = -1 
	EXEC fs_updordtots @ordno = @new_order_no,@ordext = 0

	-- START v1.3
	/*
	-- v1.1 - Write note to originating credit return
	UPDATE
		dbo.orders_all
	SET
		note = (CASE ISNULL(note,'') WHEN '' THEN '' ELSE note + CHAR(13) + CHAR(10) END) + 'Stock Move Sales Order: ' + CAST (@new_order_no AS VARCHAR(10)) + '-0'
	WHERE
		order_no = @order_no
		AND ext = @order_ext
	*/
	-- END v1.3

	RETURN @new_order_no

END
GO
GRANT EXECUTE ON  [dbo].[CVO_create_stock_move_salesorder_sp] TO [public]
GO
