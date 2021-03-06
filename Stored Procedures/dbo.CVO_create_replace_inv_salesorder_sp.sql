SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 18/07/2012 - Create an inventory replacement sales order for TBB order processing
-- v1.1 CT 19/07/2012 - Set part type to 'P'
-- v1.2 CT 09/08/2012 - Write order number to note on credit return
-- v1.3 CT 09/08/2012 - Default shipping method to USPS	
-- v1.4 CT 18/09/2012 - Corrections to list_price and amt_disc on cvo_ord_list
-- v1.5	CT 18/09/2012 - Note is now written by calling routine
-- v1.6 CB 02/10/2012 - Add soft allocation
-- v1.7	CT 28/02/2013 - New field on cvo_ord_list (free_frame)
-- v1.8 CB 11/06/2013 - Issue #965 - Tax Calculation
-- v1.9 CB 16/07/2013 - Issue #927 - Buying Group Switching
-- v2.0 CB 06/01/2015 - Fix issue with st_consolidate not being populated
-- v2.1 CB 10/04/2019 Performance
CREATE PROC [dbo].[CVO_create_replace_inv_salesorder_sp] (@order_no INT, @order_ext INT)  
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@new_order_no		INT,
			@ship_complete_flag	SMALLINT,
			@so_priority_code	CHAR(1),
			@tax_code			VARCHAR(8),
			@freight_type		VARCHAR(10),
			@retval				SMALLINT,
			@cust_code			VARCHAR(8),
			@juliandate			INT,
			@new_user_code		VARCHAR(8),
			@hold_user_code		VARCHAR(8),
			@user_hold_user_code VARCHAR(8), -- v2.1
			@line_no			INT,
			@bg					varchar(10), -- v2.1
			@status_code		varchar(10) -- v2.1

	-- Get user codes
	SELECT @new_user_code = user_stat_code FROM dbo.so_usrstat (NOLOCK) WHERE status_code = 'N' AND default_flag = 1 AND void = 'N'
	SELECT @hold_user_code = user_stat_code FROM dbo.so_usrstat (NOLOCK) WHERE status_code = 'C' AND default_flag = 1 AND void = 'N'
	SELECT @user_hold_user_code = user_stat_code FROM dbo.so_usrstat (NOLOCK) WHERE status_code = 'A' AND default_flag = 1 AND void = 'N' -- v2.1

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
		@cust_code = a.customer_code,
		@ship_complete_flag = a.ship_complete_flag,
		@so_priority_code = a.so_priority_code,
		@tax_code = a.tax_code
	FROM
		dbo.armaster_all a (NOLOCK)
	INNER JOIN
		dbo.orders_all b (NOLOCK)
	ON
		a.customer_code = b.cust_code
	WHERE
		a.address_type = 0
		AND b.order_no = @order_no
		AND	b.ext = @order_ext

	-- If there is a ship to then update with the details from there
	IF EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND ISNULL(ship_to,'') <> '') -- v2.1
	BEGIN
 
		SELECT 
			@so_priority_code = a.so_priority_code,
			@tax_code = a.tax_code
		FROM
			dbo.armaster_all a (NOLOCK)
		INNER JOIN
			dbo.orders_all b (NOLOCK)
		ON
			a.customer_code = b.cust_code
			AND a.ship_to_code = b.ship_to
		WHERE
			a.address_type = 1
			AND b.order_no = @order_no
			AND	b.ext = @order_ext	
	END

	-- Copy the data from from the order to a new order
	-- v2.1
	INSERT INTO orders_all WITH (ROWLOCK) (order_no,ext,cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,date_entered,cust_po,who_entered,status,attention,phone,terms,routing,special_instr,
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
	SELECT	@new_order_no, 0, cust_code,ship_to,GETDATE(),GETDATE(),NULL,GETDATE(),cust_po,who_entered,'N',attention,phone,terms,'USPS',special_instr,	-- v1.3
			invoice_date,total_invoice,total_amt_order,salesperson,@tax_code,tax_perc,invoice_no,fob,0,'N',discount,label_no,cancel_date,new,ship_to_name,
			ship_to_add_1,ship_to_add_2,ship_to_add_3,ship_to_add_4,ship_to_add_5,ship_to_city,ship_to_state,ship_to_zip,ship_to_country,ship_to_region,cash_flag,'I',@ship_complete_flag,
			freight_allow_pct,route_code,route_no,date_printed,date_transfered,cr_invoice_no,who_picked,note,void,void_who,void_date,changed,remit_key,forwarder_key,freight_to,
			sales_comm,@freight_type,cust_dfpa,'001',total_tax,total_discount,f_note,invoice_edi,edi_batch,post_edi_date,blanket,gross_sales,load_no,
			curr_key,0,curr_factor,bill_to_key,oper_factor,tot_ord_tax,tot_ord_disc,'0',posting_code,rate_type_home,rate_type_oper,
			reference_code,'',dest_zone_code,orig_no,orig_ext,tot_tax_incl,process_ctrl_num,batch_code,tot_ord_incl,barcode_status,multiple_flag,
			@so_priority_code,FO_order_no,0,user_priority,'ST',from_date,to_date,consolidate_flag,proc_inv_no,sold_to_addr1,sold_to_addr2,
			sold_to_addr3,sold_to_addr4,sold_to_addr5,sold_to_addr6,@new_user_code,user_def_fld1,'SO',CONVERT(VARCHAR(20),GETDATE(),101) + ' ' + CONVERT(VARCHAR(8),GETDATE(),114) + ' ' + who_entered,user_def_fld4,user_def_fld5,user_def_fld6,
			user_def_fld7,user_def_fld8,user_def_fld9,user_def_fld10,user_def_fld11,user_def_fld12,eprocurement_ind,sold_to,sopick_ctrl_num,organization_id,
			last_picked_dt,internal_so_ind,ship_to_country_cd,sold_to_city,sold_to_state,sold_to_zip,sold_to_country_cd,tax_valid_ind,addr_valid_ind
	FROM	dbo.orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- cvo_orders_all
	-- v2.1
	INSERT INTO CVO_orders_all WITH (ROWLOCK) (order_no,ext,add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
								commission_pct, stage_hold, prior_hold, credit_approved, replen_inv, st_consolidate) -- v2.0 		
	SELECT	@new_order_no, 0, 'N','N',NULL,NULL,'N','N',1,dbo.f_cvo_get_buying_group(cust_code,GETDATE()), GETDATE(), -- v1.9
			NULL, 0, NULL, NULL,0, 0 -- v2.0
	FROM	dbo.orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

		-- ord_list
	-- v2.1
	INSERT	ord_list WITH (ROWLOCK) (order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
								temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
								ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
								oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,
								inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
								unpicked_dt)
	SELECT	@new_order_no, 0, line_no, '001', part_no, description, GETDATE(), cr_ordered, 0, price, price_type, '', 'N', cost, who_entered, sales_comm, 
			temp_price, temp_type, 0, 0, discount, uom, conv_factor, void, void_who, void_date, std_cost, cubic_feet, 'N', lb_tracking, labor, direct_dolrs, 
			ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, NULL, qc_no, rejected, 'P', part_no, @ship_complete_flag, gl_rev_acct, total_tax, @tax_code, curr_price, -- v1.1
			oper_price, display_line, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id, ship_to, service_agreement_flag,
			inv_available_flag, 0, load_group_no, NULL, user_count, NULL, organization_id, NULL, NULL, NULL, NULL, 
			NULL
	FROM	dbo.ord_list  (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- cvo_ord_list
	-- v2.1
	INSERT INTO CVO_ord_list WITH (ROWLOCK) (order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
											is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame) -- v1.7
	SELECT	@new_order_no, 0, a.line_no,'N','N',ISNULL(a.from_line_no,0),a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
											a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, 0 -- v1.7		
	FROM	cvo_ord_list a (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- ord_list_kit
	-- v2.1
	INSERT INTO ord_list_kit WITH (ROWLOCK) (order_no,order_ext,line_no,location,part_no,part_type,ordered,shipped,status,lb_tracking,cr_ordered,cr_shipped,uom,conv_factor,
										cost,labor,direct_dolrs,ovhd_dolrs,util_dolrs,note,qty_per,qc_flag,qc_no,description)
	SELECT	@new_order_no, 0, line_no, '001', part_no, 'P', cr_ordered, 0, 'N', lb_tracking, 0, 0, uom,conv_factor,	-- v1.1
			cost, labor, direct_dolrs, ovhd_dolrs, util_dolrs, note, qty_per, qc_flag, qc_no, description
	FROM	ord_list_kit (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- CVO_ord_list_kit
	-- v2.1
	INSERT INTO CVO_ord_list_kit WITH (ROWLOCK) (order_no,order_ext,line_no,location,part_no,replaced,new1,part_no_original)
	SELECT	@new_order_no, 0 , line_no, '001', part_no, replaced, new1, part_no_original		
	FROM	cvo_ord_list_kit (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@@ERROR <> 0)
	BEGIN
		RETURN -1
	END

	-- Update part details on lines
	SET @line_no = -1
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@line_no = line_no
		FROM
			dbo.ord_list (NOLOCK) -- v2.1
		WHERE
			order_no = @new_order_no 
			AND order_ext = 0
			AND line_no > @line_no
		ORDER BY 
			line_no
		
		IF @@ROWCOUNT = 0
			BREAK

		UPDATE
			a WITH (ROWLOCK) -- v2.1
		SET
			temp_price = price,
			temp_type = price_type,
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
			dbo.cvo_inventory2 b (NOLOCK) -- v2.1
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

	-- START v1.4
	UPDATE 
		a WITH (ROWLOCK) -- v2.1
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
	-- END v1.4

-- v1.8	EXEC dbo.fs_calculate_oetax_wrap @ord = @new_order_no,@ext = 0,@batch_call = -1 
	EXEC fs_updordtots @ordno = @new_order_no,@ordext = 0

	-- v2.1 Start
	SELECT	@bg = buying_group
	FROM	CVO_orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (ISNULL(@bg,'') <> '')
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM cc_cust_status_hist (NOLOCK) WHERE customer_code = @bg AND status_code <> '')
		BEGIN
			SELECT @juliandate = datediff(day, '01/01/1900', getdate())+693596
			EXEC @retval = dbo.cvo_fs_archklmt_sp_wrap @customer_code = @cust_code, @date_entered = @juliandate, @ordno = @new_order_no, @ordext = 0
		END
		ELSE
		BEGIN
			SELECT TOP 1 @status_code = status_code FROM cc_cust_status_hist (NOLOCK) WHERE customer_code = @bg AND status_code <> '' ORDER BY date DESC
			UPDATE	dbo.orders_all WITH (ROWLOCK)
			SET		[status] = 'A',
					user_code = @hold_user_code,
					hold_reason = @status_code
			WHERE	order_no = @new_order_no
			AND		ext = 0

			SET @retval = 0
		END
	END
	ELSE
	BEGIN
		-- Check for credit hold
		SELECT @juliandate = datediff(day, '01/01/1900', getdate())+693596
		EXEC @retval = dbo.cvo_fs_archklmt_sp_wrap @customer_code = @cust_code, @date_entered = @juliandate, @ordno = @new_order_no, @ordext = 0
	END 
	-- v2.1

	IF @retval <> 0 
	BEGIN
		UPDATE
			dbo.orders_all WITH (ROWLOCK) -- v2.1
		SET
			[status] = 'C',
			user_code = @hold_user_code,
			hold_reason = CASE @retval WHEN -1 THEN 'CL' ELSE 'PD' END
		WHERE
			order_no = @new_order_no
			AND ext = 0
	END
	
--	EXEC tdc_order_after_save_wrap @new_order_no,0
    EXEC  dbo.cvo_create_soft_alloc_sp	@new_order_no, 0

	-- START v1.5
	/*
	-- v1.2 - Write note to originating credit return
	UPDATE
		dbo.orders_all
	SET
		note = (CASE ISNULL(note,'') WHEN '' THEN '' ELSE note + CHAR(13) + CHAR(10) END) + 'Inventory Replacement Sales Order: ' + CAST (@new_order_no AS VARCHAR(10)) + '-0'
	WHERE
		order_no = @order_no
		AND ext = @order_ext
	*/
	-- END v1.5

	RETURN @new_order_no

END
GO
GRANT EXECUTE ON  [dbo].[CVO_create_replace_inv_salesorder_sp] TO [public]
GO
