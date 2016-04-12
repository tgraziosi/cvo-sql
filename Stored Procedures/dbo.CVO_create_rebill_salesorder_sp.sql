SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- exec CVO_create_rebill_salesorder_sp 1420857, 0, 'ST-RB', 'sa'

CREATE PROC [dbo].[CVO_create_rebill_salesorder_sp]	@order_no int, 
												@order_ext int, 
												@user_category varchar(10),
												@who_entered varchar(50) 
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@new_order_no			int,
			@freight_type			varchar(10),
			@new_user_code			varchar(8)

	-- Get user codes
	SELECT @new_user_code = user_stat_code FROM dbo.so_usrstat (NOLOCK) WHERE status_code = 'N' AND default_flag = 1 AND void = 'N'		

	-- Get zero freight freight type
	SELECT @freight_type = value_str FROM dbo.config WHERE flag = 'FRTHTYPE'

	-- Get the next order number
	UPDATE	dbo.next_order_num  
	SET		last_no = last_no + 1 

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
	SELECT	@new_order_no, 0, cust_code, ship_to,GETDATE(),GETDATE(),NULL,GETDATE(),cust_po,@who_entered,'N',attention,phone,terms,routing,special_instr,
			NULL,total_invoice,total_amt_order,salesperson,tax_id,tax_perc,NULL,fob,0,'N',0,0,NULL,NULL,ship_to_name,
			ship_to_add_1,ship_to_add_2,ship_to_add_3,ship_to_add_4,ship_to_add_5,ship_to_city,ship_to_state,ship_to_zip,ship_to_country,ship_to_region,'N','I',back_ord_flag,
			0,'',0,NULL,NULL,0,NULL,note,'N',NULL,NULL,'N','',forwarder_key,freight_to,
			0,freight_allow_type,NULL,location,0,0,'','N',NULL,NULL,'N',0,0,
			curr_key,0,oper_factor,bill_to_key,oper_factor,0,0,'0',posting_code,rate_type_home,rate_type_oper,
			NULL,'',dest_zone_code,0,0,0,'',0,0,NULL,'N',
			'5',NULL,0,'',@user_category,NULL,NULL,0,'',NULL,NULL,
			NULL,NULL,NULL,NULL,@new_user_code,'','SO',CONVERT(VARCHAR(20),GETDATE(),101) + ' ' + CONVERT(VARCHAR(8),GETDATE(),114) + ' ' + @who_entered,'',0,0,
			0,0,0,0,0,0,0,NULL,'','CVO',
			NULL,0,ship_to_country_cd,NULL,NULL,NULL,NULL,0,NULL
	FROM	dbo.orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		SELECT -1
		RETURN
	END

	-- cvo_orders_all
	INSERT INTO CVO_orders_all(order_no,ext,add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
								commission_pct, stage_hold, prior_hold, credit_approved, replen_inv, st_consolidate, email_address, GSH_released, upsell_flag) 
	SELECT	@new_order_no, 0, 'N','N',NULL,NULL,'N','N',1,buying_group, GETDATE(), 
			NULL, 0, NULL, NULL,0, 0, NULL, 0, 0 
	FROM	dbo.CVO_orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		SELECT -1
		RETURN
	END

		-- ord_list
	INSERT	ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
								temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
								ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
								oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,
								inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
								unpicked_dt)
	SELECT	@new_order_no, 0, line_no, location, part_no, description, GETDATE(), cr_ordered, 0, price, price_type, '', 'N', cost, 
			@who_entered, sales_comm, temp_price, temp_type, 0, 0, discount, uom, conv_factor, void, void_who, void_date, 
			std_cost, cubic_feet, 'N', 'N', labor, direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, NULL, 
			qc_no, rejected, 'M', part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, display_line, 
			std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id, ship_to, service_agreement_flag,
			inv_available_flag, 0, load_group_no, NULL, user_count, NULL, organization_id, NULL, NULL, 
			NULL, NULL, NULL
	FROM	dbo.ord_list  (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		SELECT -1
		RETURN
	END

	-- cvo_ord_list
	INSERT INTO CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
											is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame, due_date, upsell_flag) 
	SELECT	@new_order_no, 0, a.line_no,'N','N',ISNULL(a.from_line_no,0),a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
											a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, 0, NULL, 0 
	FROM	cvo_ord_list a (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		SELECT -1
		RETURN
	END
	

	EXEC dbo.fs_calculate_oetax_wrap @ord = @new_order_no,@ext = 0,@batch_call = 1 
	EXEC fs_updordtots @ordno = @new_order_no,@ordext = 0

	SELECT @new_order_no
	RETURN

END
GO
GRANT EXECUTE ON  [dbo].[CVO_create_rebill_salesorder_sp] TO [public]
GO
