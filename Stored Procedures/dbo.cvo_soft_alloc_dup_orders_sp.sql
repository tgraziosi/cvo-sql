SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_soft_alloc_dup_orders_sp]	@order_no		int,
												@order_ext		int,
												@location		varchar(10),
												@customer_code	varchar(10),
												@new_order_no	int OUTPUT
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@new_soft_alloc_no	int,
			@promo_id			varchar(20),
			@promo_level		varchar(30),
			@free_shipping		varchar(30),
			@freight_amt		decimal(20,8),
			@tot_ord_freight	decimal(20,8),
			@weight				decimal(20,8),
			@zip				varchar(15),
			@routing			varchar(10),
			@freight_allow_type	varchar(10),
			@order_value		decimal(20,8),
			@freight_charge		smallint--, 
-- v1.9		@polarized			VARCHAR(30)

-- v1.9	SET @polarized = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_POLARIZED') 

	-- Get the next system number for soft allocation
	BEGIN TRAN
		UPDATE	dbo.cvo_soft_alloc_next_no
		SET		next_no = next_no + 1
	COMMIT TRAN	
	SELECT	@new_soft_alloc_no = next_no
	FROM	dbo.cvo_soft_alloc_next_no

	-- Get the next order number
	BEGIN TRAN
		UPDATE	dbo.next_order_num  
		SET		last_no = last_no + 1 
	COMMIT TRAN
	SELECT @new_order_no = last_no  
	FROM dbo.next_order_num 
	
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
	SELECT	@new_order_no, 0, cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,date_entered,cust_po,who_entered,'N',attention,phone,terms,routing,special_instr,
			invoice_date,total_invoice,total_amt_order,salesperson,tax_id,tax_perc,invoice_no,fob,freight,'N',discount,label_no,cancel_date,new,ship_to_name,
			ship_to_add_1,ship_to_add_2,ship_to_add_3,ship_to_add_4,ship_to_add_5,ship_to_city,ship_to_state,ship_to_zip,ship_to_country,ship_to_region,cash_flag,type,back_ord_flag,
			freight_allow_pct,route_code,route_no,date_printed,date_transfered,cr_invoice_no,who_picked,note,void,void_who,void_date,changed,remit_key,forwarder_key,freight_to,
			sales_comm,freight_allow_type,cust_dfpa,location,total_tax,total_discount,f_note,invoice_edi,edi_batch,post_edi_date,blanket,gross_sales,load_no,
			curr_key,curr_type,curr_factor,bill_to_key,oper_factor,tot_ord_tax,tot_ord_disc,tot_ord_freight,posting_code,rate_type_home,rate_type_oper,
			reference_code,hold_reason,dest_zone_code,orig_no,orig_ext,tot_tax_incl,process_ctrl_num,batch_code,tot_ord_incl,barcode_status,multiple_flag,
			so_priority_code,FO_order_no,blanket_amt,user_priority,user_category,from_date,to_date,consolidate_flag,proc_inv_no,sold_to_addr1,sold_to_addr2,
			sold_to_addr3,sold_to_addr4,sold_to_addr5,sold_to_addr6,user_code,user_def_fld1,user_def_fld2,user_def_fld3,user_def_fld4,user_def_fld5,user_def_fld6,
			user_def_fld7,user_def_fld8,user_def_fld9,user_def_fld10,user_def_fld11,user_def_fld12,eprocurement_ind,sold_to,sopick_ctrl_num,organization_id,
			last_picked_dt,internal_so_ind,ship_to_country_cd,sold_to_city,sold_to_state,sold_to_zip,sold_to_country_cd,tax_valid_ind,addr_valid_ind
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- cvo_orders_all
	INSERT INTO CVO_orders_all(order_no,ext,add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
								commission_pct, stage_hold, prior_hold, credit_approved, invoice_note, commission_override, email_address, upsell_flag, must_go_today, written_by) 	-- v1.2	v1.6 v1.7 v1.8 v2.0 v2.2
	SELECT	@new_order_no, 0, add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
			commission_pct, stage_hold, prior_hold, credit_approved, invoice_note, commission_override, email_address, upsell_flag, must_go_today, written_by -- v1.2 v1.6 v1.7 v1.8 v2.0 v2.2
	FROM	cvo_orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- v2.1 Start
	INSERT	ord_rep (order_no, order_ext, salesperson, sales_comm, percent_flag, exclusive_flag, split_flag, note, display_line,
		primary_rep, include_rx, brand, brand_split, brand_excl, commission, brand_exclude, promo_id, rx_only, startdate, enddate) -- v2.2
	SELECT	@new_order_no, 0, salesperson, sales_comm, percent_flag, exclusive_flag, split_flag, note, display_line,
		primary_rep, include_rx, brand, brand_split, brand_excl, commission, brand_exclude, promo_id, rx_only, startdate, enddate -- v2.2	
	FROM	ord_rep (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN -1  
	END  
	-- v2.1 End

		-- ord_list
	INSERT	ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
								temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
								ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
								oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,
								inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
								unpicked_dt)
	SELECT	@new_order_no, 0, line_no, location, part_no, description, time_entered, ordered, 0, price, price_type, note, 'N', cost, 
			who_entered, sales_comm, temp_price, temp_type, cr_ordered, cr_shipped, discount, uom, conv_factor, void, void_who, void_date, 
			std_cost, cubic_feet, 'N', lb_tracking, labor, direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code, 
			qc_no, rejected, part_type, orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, display_line, 
			std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id, ship_to, service_agreement_flag,
			inv_available_flag, create_po_flag, load_group_no, return_code, user_count, cust_po, organization_id, picked_dt, who_picked_id, 
			printed_dt, who_unpicked_id, unpicked_dt
	FROM	ord_list  (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- cvo_ord_list
	INSERT INTO CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
											is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame) -- v1.3
	SELECT	@new_order_no, 0, a.line_no,a.add_case,a.add_pattern,a.from_line_no,a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
											a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, a.free_frame -- v1.3		
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
	SELECT	@new_order_no, 0, line_no, location, part_no, part_type, ordered, 0, 'N', lb_tracking, cr_ordered, cr_shipped, uom,conv_factor,
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

	-- Soft allocation header
	INSERT INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
	VALUES (@new_soft_alloc_no, @new_order_no, 0, @location, 0, 0)		

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- Soft allocation detail
	IF OBJECT_ID('tempdb..#cvo_soft_alloc_det') IS NOT NULL
		DROP TABLE #cvo_soft_alloc_det

	CREATE TABLE #cvo_soft_alloc_det (
		location		varchar(10),
		line_no			int NOT NULL,
		part_no			varchar(30) NOT NULL,
		quantity		decimal(20,8),
		kit_part		smallint NOT NULL,
		is_case			smallint NOT NULL,
		is_pattern		smallint NOT NULL,
		is_pop_gift		smallint NOT NULL,
		add_case		smallint NULL) -- v1.4

	IF OBJECT_ID('tempdb..#updates') IS NOT NULL
		DROP TABLE #updates

	CREATE TABLE #updates (
		line_no		int,
		row_id		int)

	-- v1.1 Start
	CREATE TABLE #splits (
		order_no		int,
		order_ext		int,
		line_no			int,
		location		varchar(10),
		part_no			varchar(30),
		has_case		int,
		has_pattern		int,
		has_polarized	int,
		case_part		varchar(30),
		pattern_part	varchar(30),
		polarized_part	varchar(30),
		quantity		decimal(20,8),
		part_type		varchar(20),
		alloc_qty		decimal(20,8),
		auto_po			smallint)

	INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
						pattern_part, polarized_part, quantity, part_type, alloc_qty, auto_po)
	SELECT	a.order_no,
			a.order_ext,
			a.line_no,
			a.location,
			a.part_no,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN 1 ELSE 0 END,
-- v1.5		CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN c.field_1 ELSE '' END,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN fc.case_part ELSE '' END, -- v1.5
-- v1.5		CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN c.field_4 ELSE '' END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN fc.pattern_part ELSE '' END, -- v1.5
-- v1.9		CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN @polarized ELSE '' END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN fc.polarized_part ELSE '' END, -- v1.9
			a.ordered, 
			d.type_code, 0.0,
			ISNULL(a.create_po_flag,0)
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	inv_master_add c (NOLOCK)
	ON		a.part_no = c.part_no
	LEFT JOIN cvo_ord_list_fc fc (NOLOCK) -- v1.5
	ON		a.order_no = fc.order_no -- v1.5
	AND		a.order_ext = fc.order_ext -- v1.5
	AND		a.line_no = fc.line_no -- v1.5
	JOIN	inv_master d (NOLOCK)
	ON		a.part_no = d.part_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	ORDER BY a.line_no

	INSERT	#cvo_soft_alloc_det (location, line_no, part_no, quantity,  
										kit_part, is_case, is_pattern, is_pop_gift, add_case) -- v1.4
	SELECT	location, line_no, part_no, quantity, 0, CASE WHEN part_type = 'CASE' THEN 1 ELSE 0 END,
			CASE WHEN part_type = 'PATTERN' THEN 1 ELSE 0 END, 0, has_case -- v1.4
	FROM	#splits

	UPDATE	a
	SET		kit_part = 1
	FROM	#cvo_soft_alloc_det a
	JOIN	cvo_ord_list_kit b (NOLOCK)
	ON		a.line_no = b.line_no
	AND		a.part_no = b.part_no
	WHERE	b.order_no = @order_no
	AND		b.order_ext = @order_ext
	AND		b.replaced = 'S'

	UPDATE	a
	SET		is_pop_gift = 1
	FROM	#cvo_soft_alloc_det a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.line_no = b.line_no
	WHERE	b.order_no = @order_no
	AND		b.order_ext = @order_ext
	AND		b.is_pop_gif = 1
	
	/*
	INSERT	#cvo_soft_alloc_det (location, line_no, part_no, quantity,  
										kit_part, is_case, is_pattern, is_pop_gift)
	SELECT	a.location, a.line_no, a.part_no, SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),
				 a.kit_part, a.is_case, a.is_pattern, a.is_pop_gift
	FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	GROUP BY a.location, a.line_no, a.part_no, a.kit_part, a.is_case, a.is_pattern,
				a.is_pop_gift
	HAVING SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END) <> 0

	INSERT	#updates
	SELECT	line_no, MAX(row_id) 
	FROM	dbo.cvo_soft_alloc_det (NOLOCK) 
	WHERE	order_no = @order_no 
	AND		order_ext = @order_ext 
	AND		change = 1
	GROUP BY line_no

	UPDATE	a
	SET		quantity = b.quantity
	FROM	#cvo_soft_alloc_det a
	JOIN	cvo_soft_alloc_det b (NOLOCK)
	ON		a.line_no = b.line_no
	AND		a.part_no = b.part_no
	JOIN	#updates c
	ON		b.line_no = c.line_no
	AND		b.row_id = c.row_id
	WHERE	b.order_no = @order_no
	AND		b.order_ext = @order_ext
	*/
	-- v1.1 End
	INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) -- v1.4
	SELECT	@new_soft_alloc_no, @new_order_no, 0, a.line_no, a.location, a.part_no, a.quantity, a.kit_part, 0, 0, a.is_case, a.is_pattern,
				a.is_pop_gift, 0, CASE WHEN a.add_case = 1 THEN 'Y' ELSE NULL END -- v1.4
	FROM	#cvo_soft_alloc_det a (NOLOCK)

	DROP TABLE #cvo_soft_alloc_det
	DROP TABLE #updates

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- v1.9 Start
	CREATE TABLE #cvo_ord_list_fc (
		order_no		int, 
		order_ext		int, 
		line_no			int, 
		polarized_part	varchar(30) NULL)

	INSERT	#cvo_ord_list_fc
	SELECT	@new_order_no, order_ext, line_no, polarized_part
	FROM	cvo_ord_list_fc (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	-- v1.9 End

	-- v1.5 Start
	DELETE	cvo_ord_list_fc
	WHERE	order_no = @new_order_no
	AND		order_ext = 0

	INSERT	dbo.cvo_ord_list_fc (order_no, order_ext, line_no, part_no, case_part, pattern_part)
	SELECT	a.order_no, a.order_ext, a.line_no, a.part_no, ISNULL(inv.field_1,''), ISNULL(inv.field_4,'')
	FROM	ord_list a (NOLOCK)
	JOIN	inv_master b (NOLOCK)
	ON		a.part_no = b.part_no
	JOIN	inv_master_add inv (NOLOCK)
	ON		b.part_no = inv.part_no
	WHERE	a.order_no = @new_order_no
	AND		a.order_ext = 0	
	AND		b.type_code IN ('FRAME','SUN')
	ORDER BY a.order_no, a.order_ext, a.line_no
	-- v1.5 End

	-- v1.9 Start
	UPDATE	a
	SET		polarized_part = b.polarized_part
	FROM	dbo.cvo_ord_list_fc a
	JOIN	#cvo_ord_list_fc b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no

	DROP TABLE #cvo_ord_list_fc
	-- v1.9 End

	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_dup_orders_sp] TO [public]
GO
