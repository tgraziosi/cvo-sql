SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_create_charge_sc_salesorder_sp] (@order_no int, 
													@order_ext int)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@new_order_no			int,
			@ship_complete_flag		smallint,
			@so_priority_code		char(1),
			@tax_code				varchar(8),
			@ship_to_name			varchar(40),
			@ship_to_add_1			varchar(40),
			@ship_to_add_2			varchar(40),
			@ship_to_add_3			varchar(40),
			@ship_to_add_4			varchar(40),
			@ship_to_add_5			varchar(40),
			@ship_to_city			varchar(40),
			@ship_to_state			varchar(40),
			@ship_to_zip			varchar(15),
			@ship_to_country		varchar(40),
			@terms_code				varchar(8),       
			@fob_code				varchar(8),
			@territory_code			varchar(8),
			@salesperson_code		varchar(8),  
			@trade_disc_percent		float,
			@ship_via_code			varchar(8),    
			@short_name				varchar(10), 
			@nat_cur_code			varchar(8),     
			@one_cur_cust			smallint,
			@rate_type_home			varchar(8),   
			@rate_type_oper			varchar(8),
			@remit_code				varchar(10),     	
			@forwarder_code			varchar(10),
			@freight_to_code		varchar(10),  
			@dest_zone_code			varchar(8),
			@note					varchar(255),             
			@special_instr			varchar(255),
			@payment_code			varchar(8),     
			@posting_code			varchar(8),
			@price_level			char(1),      
			@price_code				varchar(8),
			@contact_name			varchar(40),
			@contact_phone			varchar(30),
			@status_type			smallint,
			@error					int, 
			@home_rate				float, 
			@oper_rate				float,
			@apply_date				int,
			@consolidated_invoices	int,
			@country_code			varchar(3),
			@freight_type			varchar(10),
			@line_no				int,
			@pn						varchar(30),
			@loc					varchar(10),
			@qty					decimal (20,8),
			@plevel					char(1), 
			@price					decimal(20,8),
			@price_qty				decimal(20,8),
			@new_user_code			varchar(8),
			@cust_code				varchar(10),
			@str_discount_perc		varchar(10), -- v1.1
			@discount_perc			decimal(20,8) -- v1.1

	-- WORKING TABLES
	CREATE TABLE #sc_lines (
		line_no		int,
		part_no		varchar(30))

	-- Get user codes
	SELECT	@new_user_code = user_stat_code 
	FROM	dbo.so_usrstat (NOLOCK) 
	WHERE	status_code = 'N' 
	AND		default_flag = 1 
	AND		void = 'N'		

	-- Get zero freight freight type
	SELECT	@freight_type = value_str 
	FROM	dbo.config (NOLOCK) 
	WHERE	flag = 'FRTHTYPE'

	-- Get the salesperson account
	SELECT	@cust_code = sc_no
	FROM	cvo_charge_sc (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	-- If account is not set then exit
	IF (ISNULL(@cust_code,'') = '')
	BEGIN
		RETURN
	END

	-- v1.1 Start
	SET @str_discount_perc = NULL
	SELECT	@str_discount_perc = value_str
	FROM	config (NOLOCK)
	WHERE	flag = 'SC - PC DISCOUNT'

	IF (@str_discount_perc IS NULL)
		SET @str_discount_perc = '75'

	IF (ISNUMERIC(@str_discount_perc) = 1)
	BEGIN
		SET @discount_perc = CAST(@str_discount_perc as decimal(20,8))
		SET @discount_perc = (1.00 - (@discount_perc / 100))
	END
	ELSE
	BEGIN
		SET @discount_perc = .25
	END
	-- v1.1 End


	-- Get the details
	INSERT	#sc_lines (line_no, part_no)
	SELECT	line_no, part_no
	FROM	ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	AND		curr_price <> 0
	AND		discount = 100
	
	-- Check for data
	IF (@@ROWCOUNT = 0)
	BEGIN
		DROP TABLE #sc_lines
		RETURN
	END

	-- Get the next order number
	UPDATE	dbo.next_order_num  
	SET		last_no = last_no + 1 
	SELECT @new_order_no = last_no  
	FROM dbo.next_order_num

	-- Get customer details
	SELECT	@consolidated_invoices = consolidated_invoices,
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
	FROM	dbo.armaster_all (NOLOCK)
	WHERE	address_type = 0
	AND		customer_code = @cust_code
 
	-- Get exchange rate
	SELECT @apply_date = datediff(day, '01/01/1900', getdate())+693596

	EXEC dbo.cvo_curate_sp	@apply_date = @apply_date, 
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
	SELECT	@new_order_no, 0, @cust_code,'',GETDATE(),GETDATE(),NULL,GETDATE(),cust_po,who_entered,'N',@contact_name,@contact_phone,@terms_code,routing,@special_instr,
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
								commission_pct, stage_hold, prior_hold, credit_approved, replen_inv, st_consolidate) 
	SELECT	@new_order_no, 0, 'N','N',NULL,NULL,'N','N',1,dbo.f_cvo_get_buying_group(@cust_code,GETDATE()), GETDATE(),
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
	SELECT	@new_order_no, 0, a.line_no, a.location, a.part_no, a.description, GETDATE(), a.ordered, 0, ROUND((a.price * @discount_perc),2), a.price_type, '', 'N', a.cost, -- v1.1 v1.2
			a.who_entered, a.sales_comm, ROUND((a.temp_price * @discount_perc),2), -- v1.1 v1.2
			a.temp_type, 0, 0, 0, a.uom, a.conv_factor, a.void, a.void_who, a.void_date, 
			a.std_cost, a.cubic_feet, 'N', 'N', a.labor, a.direct_dolrs, a.ovhd_dolrs, a.util_dolrs, a.taxable, a.weight_ea, a.qc_flag, NULL, 
			a.qc_no, a.rejected, 'M', a.part_no, @ship_complete_flag, a.gl_rev_acct, a.total_tax, @tax_code, 
			ROUND((a.curr_price * @discount_perc),2), ROUND((a.oper_price * @discount_perc),2), -- v1.1 v1.2
			a.display_line, a.std_direct_dolrs, a.std_ovhd_dolrs, a.std_util_dolrs, a.reference_code, a.contract, a.agreement_id, a.ship_to, 
			a.service_agreement_flag, a.inv_available_flag, 0, a.load_group_no, NULL, a.user_count, NULL, a.organization_id, NULL, NULL, 
			NULL, NULL, NULL
	FROM	dbo.ord_list a (NOLOCK)
	JOIN	#sc_lines b
	ON		a.line_no = b.line_no
	AND		a.part_no = b.part_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext

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
	JOIN	#sc_lines b
	ON		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END


	UPDATE	a
	SET		list_price = d.price,
			amt_disc = 0 
	FROM	dbo.cvo_ord_list a  
	JOIN	dbo.ord_list b (NOLOCK)  
	ON		a.order_no = b.order_no  
	AND		a.order_ext = b.order_ext  
	AND		a.line_no = b.line_no  
	JOIN	dbo.adm_inv_price c (NOLOCK)  
	ON		b.part_no = c.part_no  
	JOIN	dbo.adm_inv_price_det d (NOLOCK)  
	ON		c.inv_price_id = d.inv_price_id  
	WHERE 	c.active_ind = 1 
	AND		a.order_no = @new_order_no
	AND		a.order_ext = 0

	-- Auto ship
	UPDATE	dbo.ord_list
	SET		shipped = ordered,
			[status] = 'P'
	WHERE	order_no = @new_order_no
	AND		order_ext = 0

	UPDATE	dbo.orders_all
	SET		[status] = 'P',
			printed = 'P'
	WHERE	order_no = @new_order_no
	AND		ext = 0

	UPDATE	dbo.ord_list
	SET		[status] = 'R'
	WHERE	order_no = @new_order_no
	AND		order_ext = 0

	UPDATE	dbo.orders_all
	SET		date_shipped = GETDATE(),
			[status] = 'R',
			printed = 'R'
	WHERE	order_no = @new_order_no
	AND		ext = 0
	
	EXEC dbo.fs_calculate_oetax_wrap @ord = @new_order_no,@ext = 0,@batch_call = -1 
	EXEC fs_updordtots @ordno = @new_order_no,@ordext = 0

	UPDATE	cvo_charge_sc	
	SET		sc_order_no = @new_order_no
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	RETURN 

END
GO
GRANT EXECUTE ON  [dbo].[CVO_create_charge_sc_salesorder_sp] TO [public]
GO
