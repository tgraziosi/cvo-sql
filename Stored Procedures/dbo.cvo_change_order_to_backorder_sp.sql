SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*  
Copyright (c) 2012 Epicor Software (UK) Ltd  
Name:   cvo_change_order_to_backorder_sp    
Project ID:  Issue 680  
Type:   Stored Procedure  
Description: Creates a copy of the order passed in, with same order number, but passed in order ext.  Voids existing order  
Developer:  Chris Tyler  
  
History  
-------  
v1.0	19/07/12 CT Original version  
v1.1	18/09/12 CB Add in soft allocation  
v1.2	16/10/12 CB Fix issue of voiding leaving behind soft alloc record
v1.3	02/11/12 CB Issue #951 - Change who_entered to 'outofstock'
v1.4	04/12/12 CT Add invoice notes
v1.5	01/03/13 CT New field on cvo_ord_list (free_frame)
v1.6	11/06/13 CB Issue #1043 - POP Backorder freight  
v1.7	12/07/13 CT Issue #1338 - Write frame/case relationship for new order
v1.8	10/07/13 CB Issue #927 - Buying Group Switching
v1.9	18/11/13 CT Issue #1417 - If order contains a custom frame then don't set the bo_hold flag
v1.10	10/02/14 CT Issue #864 - If order has a drawdown promo on it then apply this to backorder
v1.11	12/02/14 CB Issue #1302 - Commission Override
v1.12	11/11/14 CT Issue #1505 - Add email address
tag		4/28/2015 - add rowlock to update statements
v1.13 CB 21/08/2015 - Issue #1563 - Upsell flag
v1.14 CB 25/01/2016 - Add missing column
v1.15 CB 26/01/2016 - #1581 2nd Polarized Option
v1.16 CB 23/05/2016 - Ensure contract is not null
v1.17 CB 20/06/2016 - Issue #1602 - Must Go Today flag
v1.18 CB 31/10/2016 - #1616 Hold Processing
v1.19 CB 29/11/2018 - #1502 Multi Salesrep



-- EXEC dbo.cvo_change_order_to_backorder_sp 1419759,0,1  
  
*/  
  
CREATE PROC [dbo].[cvo_change_order_to_backorder_sp] @order_no  int,  
             @order_ext  int,  
             @new_order_ext int   
AS  
BEGIN  
	-- Directives  
	SET NOCOUNT ON  
  
	 -- Declarations  
	DECLARE @promo_id			varchar(20),  
			@promo_level		varchar(30),  
			@free_shipping		varchar(30),  
			@freight_amt		decimal(20,8),  
			@tot_ord_freight	decimal(20,8),  
			@weight				decimal(20,8),  
			@zip				varchar(15),  
			@routing			varchar(10),  
			@freight_allow_type varchar(10),  
			@order_value		decimal(20,8),  
			@freight_charge		smallint,
			@cust_code			varchar(10),	-- v1.8  
			@is_drawdown		SMALLINT,		-- v1.10
			@hdr_rec_id			INT,			-- v1.10
			@promo_amount		DECIMAL(20,8)	-- v1.10
			
  
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
	SELECT order_no, @new_order_ext, cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,date_entered,cust_po,'outofstock', -- v1.3 who_entered,
		status,attention,phone,terms,routing,special_instr,  
		invoice_date,total_invoice,total_amt_order,salesperson,tax_id,tax_perc,invoice_no,fob,freight,printed,discount,label_no,cancel_date,new,ship_to_name,  
		ship_to_add_1,ship_to_add_2,ship_to_add_3,ship_to_add_4,ship_to_add_5,ship_to_city,ship_to_state,ship_to_zip,ship_to_country,ship_to_region,cash_flag,type,back_ord_flag,  
		freight_allow_pct,route_code,route_no,date_printed,date_transfered,cr_invoice_no,who_picked,note,void,void_who,void_date,changed,remit_key,forwarder_key,freight_to,  
		sales_comm,freight_allow_type,cust_dfpa,location,total_tax,total_discount,f_note,invoice_edi,edi_batch,post_edi_date,blanket,gross_sales,load_no,  
		curr_key,curr_type,curr_factor,bill_to_key,oper_factor,tot_ord_tax,tot_ord_disc,tot_ord_freight,posting_code,rate_type_home,rate_type_oper,  
		reference_code,hold_reason,dest_zone_code,orig_no,orig_ext,tot_tax_incl,process_ctrl_num,batch_code,tot_ord_incl,barcode_status,multiple_flag,  
		so_priority_code,FO_order_no,blanket_amt,user_priority,user_category,from_date,to_date,consolidate_flag,proc_inv_no,sold_to_addr1,sold_to_addr2,  
		sold_to_addr3,sold_to_addr4,sold_to_addr5,sold_to_addr6,user_code,user_def_fld1,user_def_fld2,user_def_fld3,user_def_fld4,user_def_fld5,user_def_fld6,  
		user_def_fld7,user_def_fld8,user_def_fld9,user_def_fld10,user_def_fld11,user_def_fld12,eprocurement_ind,sold_to,sopick_ctrl_num,organization_id,  
		last_picked_dt,internal_so_ind,ship_to_country_cd,sold_to_city,sold_to_state,sold_to_zip,sold_to_country_cd,tax_valid_ind,addr_valid_ind  
	FROM orders_all (NOLOCK)  
	WHERE order_no = @order_no  
	AND  ext = @order_ext  
  
	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN -1  
	END  

	-- v1.18 Start
	INSERT	cvo_so_holds (order_no, order_ext, hold_reason, hold_priority, hold_user, hold_date)
	SELECT	order_no, @new_order_ext, hold_reason, hold_priority, hold_user, hold_date
	FROM	cvo_so_holds (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	DELETE	cvo_so_holds
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	-- v1.18 End  

	-- v1.8 Start
	SELECT	@cust_code = cust_code
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext
	-- v1.8 End
  
	-- cvo_orders_all  
	INSERT INTO CVO_orders_all(order_no,ext,add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,  
		commission_pct, stage_hold, prior_hold, credit_approved, replen_inv, xfer_no, stock_move, stock_move_cust_code,  
		stock_move_ship_to, stock_move_replace_inv, stock_move_order_no, stock_move_ext, stock_move_ri_order_no, stock_move_ri_ext, invoice_note, commission_override, email_address, upsell_flag,     -- v1.4 v1.11 v1.12 v1.13
		st_consolidate, must_go_today) -- v1.14 v1.17
	SELECT order_no, @new_order_ext, add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,dbo.f_cvo_get_buying_group(@cust_code,GETDATE()), allocation_date, -- v1.8 
		commission_pct, stage_hold, prior_hold, credit_approved, replen_inv, xfer_no, stock_move, stock_move_cust_code,  
		stock_move_ship_to, stock_move_replace_inv, stock_move_order_no, stock_move_ext, stock_move_ri_order_no, stock_move_ri_ext, invoice_note, commission_override, email_address, upsell_flag, -- v1.4 v1.11  v1.12 v1.13
		st_consolidate, must_go_today -- v1.14 v1.17
	FROM cvo_orders_all (NOLOCK)  
	WHERE order_no = @order_no  
	AND  ext = @order_ext  
  
	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN -1  
	END  

	-- v1.19 Start
	INSERT	ord_rep (order_no, order_ext, salesperson, sales_comm, percent_flag, exclusive_flag, split_flag, note, display_line,
		primary_rep, include_rx, brand, brand_split, brand_excl, commission)
	SELECT	order_no, @new_order_ext, salesperson, sales_comm, percent_flag, exclusive_flag, split_flag, note, display_line,
		primary_rep, include_rx, brand, brand_split, brand_excl, commission	
	FROM	ord_rep (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN -1  
	END  
	-- v1.19 End
  
	-- ord_list  
	INSERT ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,  
		temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,  
		ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,  
		oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,  
		inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,  
		unpicked_dt)  
	SELECT order_no, @new_order_ext, line_no, location, part_no, description, time_entered, ordered, 0, price, price_type, note, status, cost, 'outofstock', -- v1.3 who_entered, 
		sales_comm, temp_price, temp_type, cr_ordered, cr_shipped, discount, uom, conv_factor, void, void_who, void_date,   
		std_cost, cubic_feet, printed, lb_tracking, labor, direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code,   
		qc_no, rejected, part_type, orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, display_line,   
		std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, ISNULL(contract,''), agreement_id, ship_to, service_agreement_flag,  -- v1.16
		inv_available_flag, create_po_flag, load_group_no, return_code, user_count, cust_po, organization_id, picked_dt, who_picked_id,   
		printed_dt, who_unpicked_id, unpicked_dt  
	FROM ord_list  (NOLOCK)  
	WHERE order_no = @order_no  
	AND  order_ext = @order_ext  
  
	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN -1  
	END  
  
	-- cvo_ord_list  
	INSERT INTO CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,  
		is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame)  -- v1.5
	SELECT order_no, @new_order_ext, a.line_no,a.add_case,a.add_pattern,a.from_line_no,a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,  
		a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, a.free_frame  -- v1.5    
	FROM cvo_ord_list a (NOLOCK)  
	WHERE order_no = @order_no  
	AND  order_ext = @order_ext  
  
	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN -1  
	END  

	-- ord_list_kit  
	INSERT INTO ord_list_kit (order_no,order_ext,line_no,location,part_no,part_type,ordered,shipped,status,lb_tracking,cr_ordered,cr_shipped,uom,conv_factor,  
		cost,labor,direct_dolrs,ovhd_dolrs,util_dolrs,note,qty_per,qc_flag,qc_no,description)  
	SELECT order_no, @new_order_ext, line_no, location, part_no, part_type, ordered, 0, status, lb_tracking, cr_ordered, cr_shipped, uom,conv_factor,  
		cost, labor, direct_dolrs, ovhd_dolrs, util_dolrs, note, qty_per, qc_flag, qc_no, description  
	FROM ord_list_kit (NOLOCK)  
	WHERE order_no = @order_no  
	AND  order_ext = @order_ext  

	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN -1  
	END  
  
	-- CVO_ord_list_kit  
	INSERT INTO CVO_ord_list_kit(order_no,order_ext,line_no,location,part_no,replaced,new1,part_no_original)  
	SELECT order_no, @new_order_ext , line_no, location, part_no, replaced, new1, part_no_original    
	FROM cvo_ord_list_kit (NOLOCK)  
	WHERE order_no = @order_no  
	AND  order_ext = @order_ext  
  
	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN -1  
	END  

	-- START v1.7
	-- cvo_ord_list_fc
	INSERT	dbo.cvo_ord_list_fc (order_no, order_ext, line_no, part_no, case_part, pattern_part, polarized_part) -- v1.15
	SELECT	order_no, @new_order_ext, line_no, part_no, case_part, pattern_part, polarized_part -- v1.15
	FROM	cvo_ord_list_fc (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext	
	ORDER BY order_no, order_ext, line_no
	-- END v1.7

  
	-- v1.6 Start
	IF NOT EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN inv_master b (NOLOCK) ON a.part_no = b.part_no
				WHERE a.order_no = @order_no AND a.order_ext = @new_order_ext AND b.type_code IN ('FRAME','SUN'))
	BEGIN
		UPDATE	orders_all with (rowlock) -- tag
		SET		tot_ord_freight = 0,
				freight_allow_type = 'FRTOVRID',
				routing = 'UPSGR'
		WHERE	order_no = @order_no
		AND		ext = @new_order_ext
	END
	-- v1.6 End

	-- START v1.10
	SET @is_drawdown = 0

	-- Get promo
	SELECT
		@promo_id = promo_id,
		@promo_level = promo_level
	FROM
		dbo.cvo_orders_all (NOLOCK)
	WHERE
		order_no = @order_no   
		AND ext = @order_ext   

	-- Check it's a drawdown promo
	IF EXISTS (SELECT 1 FROM dbo.cvo_promotions (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND ISNULL(drawdown_promo,0) = 1)
	BEGIN
		SET @is_drawdown = 1 

		-- Copy drawdown detail records
		INSERT INTO dbo.CVO_debit_promo_customer_det(
			hdr_rec_id,
			order_no,
			ext,
			line_no,
			credit_amount,
			posted)
		SELECT
			hdr_rec_id,
			order_no,
			@new_order_ext,
			line_no,
			credit_amount,
			0
		FROM
			dbo.CVO_debit_promo_customer_det (NOLOCK)
		WHERE
			order_no = @order_no   
			AND ext = @order_ext  
	END
	-- END v1.10

	-- Void existing order  
	UPDATE   
		dbo.orders_all  with (rowlock) -- tag  
	SET   
		[status] = 'V',   
		void = 'V',   
		void_who = LEFT(SUSER_SNAME(),20),   
		void_date = GETDATE(),   
		hold_reason = ''   
	WHERE   
		order_no = @order_no   
		AND ext = @order_ext   
  
	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN -1  
	END  
  
	-- START v1.10
	IF @is_drawdown = 1
	BEGIN
		-- Apply drawdown amount to promo
		SELECT
			@hdr_rec_id = hdr_rec_id,
			@promo_amount = SUM(credit_amount)
		FROM
			dbo.CVO_debit_promo_customer_det (NOLOCK)
		WHERE
			order_no = @order_no 
			AND ext = @new_order_ext
			AND posted = 0
		GROUP BY
			hdr_rec_id

		IF (ISNULL(@hdr_rec_id,0) <> 0) AND (ISNULL(@promo_amount,0) > 0)
		BEGIN
			-- Update header record
			UPDATE
				dbo.CVO_debit_promo_customer_hdr with (rowlock) -- tag
			SET
				available = ISNULL(available,0) - @promo_amount,
				open_orders = ISNULL(open_orders,0) + @promo_amount
			WHERE
				hdr_rec_id = @hdr_rec_id
		END
	END
	-- END v1.10

	-- v1.1 Implement soft allocation  
	EXEC dbo.cvo_soft_alloc_backorder_sp 0, @order_no, @order_ext, @new_order_ext  
	-- v1.2 Start  
	DELETE cvo_soft_alloc_hdr WHERE order_no = @order_no AND order_ext = @order_ext
	DELETE cvo_soft_alloc_det WHERE order_no = @order_no AND order_ext = @order_ext
	-- v1.2 End
	
	-- START v1.9
	-- If order contains a custom frame then remove bo_hold flag from soft alloc hdr
	IF EXISTS (SELECT 1 FROM dbo.cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @new_order_ext AND is_customized = 'S')
	BEGIN
		UPDATE
			dbo.cvo_soft_alloc_hdr with (rowlock) -- tag
		SET
			bo_hold = 0
		WHERE
			order_no = @order_no 
			AND order_ext = @new_order_ext
	END
	-- END v1.9

	RETURN 0  
END  

GO
GRANT EXECUTE ON  [dbo].[cvo_change_order_to_backorder_sp] TO [public]
GO
