SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_CreateBackOrders_sp]	@order_no	int,
										@order_ext	int,
										@WMS		int = 0
AS
BEGIN

	SET NOCOUNT ON

	--Declarations
	DECLARE	@result			int,
			@new_ext		int,
			@split			int,
			@last_ext		int,
			@ext			int,
			@error			int


	-- Check if this order has been split for shipping restrictions
	SET @split = 0
	SET	@error = 0

	IF @WMS = 0
	BEGIN
		-- Need to find out if this order will be split because of shipment restrictions
		IF EXISTS (SELECT 1 FROM dbo.orders_all WHERE order_no = @order_no AND ext = @order_ext
					AND status = 'V')
		BEGIN
			SELECT	@split = CASE WHEN split_order = 'Y' THEN 1 ELSE 0 END
			FROM	dbo.cvo_orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext > @order_ext
		END
	END

	-- create working table
	CREATE TABLE #ext (
			ext int)

	-- This has been called from BO and the order may have been split
	IF @WMS = 0 AND @split = 1
	BEGIN
		INSERT	#ext 
		SELECT	ext
		FROM	dbo.orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		status < 'P'
	END
	ELSE
	BEGIN
		INSERT #ext SELECT @order_ext
	END

	-- Create working tables
	CREATE TABLE #bo_orders (
		order_no	int,
		order_ext	int,
		line_no		int,
		qty			decimal(20,8),
		lineaction	char(1))

	-- Loop through the ext
	SET	@last_ext = -1

	SELECT	TOP 1 @ext = ext
	FROM	#ext
	WHERE	ext > @last_ext
	ORDER BY ext ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Check the order status
		IF NOT EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no
						AND ext = @ext AND status < 'P')
			SET @error = 1

		-- Check this order allows backorders
		IF NOT EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no
						AND ext = @ext AND back_ord_flag = 0)
			SET @error = 1

		-- If there are no allocations then exit
		IF NOT EXISTS (SELECT 1 FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no
						AND order_ext = @ext)
			SET @error = 1

		IF @error = 1
		BEGIN

			SET @error = 0

			DELETE #bo_orders

			SET	@last_ext = @ext

			SELECT	TOP 1 @ext = ext
			FROM	#ext
			WHERE	ext > @last_ext
			ORDER BY ext ASC

			CONTINUE

		END

		DELETE #bo_orders

		-- Bring in the data to process - only where the lines are marked as backorders
		-- and the qty is not allocated
		INSERT #bo_orders (order_no, order_ext, line_no, qty, lineaction)
		SELECT	a.order_no, a.order_ext, a.line_no, a.ordered, 'B'
		FROM	dbo.ord_list a (NOLOCK)
		JOIN	dbo.orders b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.ext
		LEFT JOIN dbo.tdc_soft_alloc_tbl c (NOLOCK)
		ON		a.order_no = c.order_no
		AND		a.order_ext = c.order_ext
		AND		a.line_no = c.line_no
		WHERE	a.back_ord_flag = 0
		AND		b.back_ord_flag = 0
		AND		c.line_no IS NULL
		AND		a.order_no = @order_no
		AND		a.order_ext = @ext
		AND		a.shipped = 0
		AND		b.status < 'P' -- Only orders that are new or on hold

		-- Get lines that are partially allocated
		INSERT #bo_orders (order_no, order_ext, line_no, qty, lineaction)
		SELECT	a.order_no, a.order_ext, a.line_no, (a.ordered - c.qty), 'P'
		FROM	dbo.ord_list a (NOLOCK)
		JOIN	dbo.orders b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.ext
		JOIN	dbo.tdc_soft_alloc_tbl c (NOLOCK)
		ON		a.order_no = c.order_no
		AND		a.order_ext = c.order_ext
		AND		a.line_no = c.line_no
		WHERE	a.back_ord_flag = 0
		AND		b.back_ord_flag = 0
		AND		a.order_no = @order_no
		AND		a.order_ext = @ext
		AND		a.shipped = 0
		AND		(a.ordered - c.qty) > 0
		AND		b.status < 'P' -- Only orders that are new or on hold

		-- Get lines that are fully allocated
		INSERT #bo_orders (order_no, order_ext, line_no, qty, lineaction)
		SELECT	a.order_no, a.order_ext, a.line_no, (a.ordered - c.qty), 'A'
		FROM	dbo.ord_list a (NOLOCK)
		JOIN	dbo.orders b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.ext
		JOIN	dbo.tdc_soft_alloc_tbl c (NOLOCK)
		ON		a.order_no = c.order_no
		AND		a.order_ext = c.order_ext
		AND		a.line_no = c.line_no
		WHERE	a.back_ord_flag = 0
		AND		b.back_ord_flag = 0
		AND		a.order_no = @order_no
		AND		a.order_ext = @ext
		AND		a.shipped = 0
		AND		(a.ordered - c.qty) = 0
		AND		b.status < 'P' -- Only orders that are new or on hold

		-- if all lines and quantites are allocated then there is nothing to do
		IF NOT EXISTS (SELECT 1 FROM #bo_orders WHERE lineaction IN ('B','P'))
		BEGIN
			SET	@last_ext = @ext

			SELECT	TOP 1 @ext = ext
			FROM	#ext
			WHERE	ext > @last_ext
			ORDER BY ext ASC

			CONTINUE

		END
	
		-- If we reach here there are lines to process
		-- Unallocate the order first
		IF @WMS = 0
		BEGIN
			SET @result = 0

			EXEC @result = dbo.cvo_UnAllocate_sp @order_no, @ext

			IF @result <> 0 OR @@ERROR <> 0
			BEGIN
				DROP TABLE #bo_orders
				RETURN
			END
		END

		-- Get the new ext
		SELECT	@new_ext = MAX(ext) + 1
		FROM	dbo.orders (NOLOCK)
		WHERE	order_no = @order_no

		IF @new_ext IS NULL
		BEGIN
			DROP TABLE #bo_orders
			RETURN
		END

		-- Update the lines on the original order where they are partially allocated
		UPDATE	a
		SET		ordered = ordered - b.qty
		FROM	dbo.ord_list a
		JOIN	#bo_orders b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext 
		AND		b.lineaction = 'P'

		-- Update ord_list_kit
		UPDATE	a
		SET		ordered = ordered - b.qty
		FROM	dbo.ord_list_kit a
		JOIN	#bo_orders b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext 
		AND		b.lineaction = 'P'


		-- Create the BackOrder Record
		-- Orders_all
		INSERT INTO dbo.orders_all  (order_no,ext,cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,
									date_entered,cust_po,who_entered,status,attention,phone,terms,routing,special_instr,
									invoice_date,total_invoice,total_amt_order,salesperson,tax_id,tax_perc,
									invoice_no,fob,freight,printed,discount,label_no,cancel_date,new,ship_to_name,
									ship_to_add_1,ship_to_add_2,ship_to_add_3,ship_to_add_4,ship_to_add_5,ship_to_city,
									ship_to_state,ship_to_zip,ship_to_country,ship_to_region,cash_flag,type,back_ord_flag,
									freight_allow_pct,route_code,route_no,date_printed,date_transfered,cr_invoice_no,
									who_picked,note,void,void_who,void_date,changed,remit_key,forwarder_key,freight_to,
									sales_comm,freight_allow_type,cust_dfpa,location,total_tax,total_discount,
									f_note,invoice_edi,edi_batch,post_edi_date,blanket,gross_sales,load_no,
									curr_key,curr_type,curr_factor,bill_to_key,oper_factor,tot_ord_tax,
									tot_ord_disc,tot_ord_freight,posting_code,rate_type_home,rate_type_oper,
									reference_code,hold_reason,dest_zone_code,orig_no,orig_ext,tot_tax_incl,
									process_ctrl_num,batch_code,tot_ord_incl,barcode_status,multiple_flag,
									so_priority_code,FO_order_no,blanket_amt,user_priority,user_category,
									from_date,to_date,consolidate_flag,proc_inv_no,sold_to_addr1,sold_to_addr2,
									sold_to_addr3,sold_to_addr4,sold_to_addr5,sold_to_addr6,user_code,user_def_fld1,
									user_def_fld2,user_def_fld3,user_def_fld4,user_def_fld5,user_def_fld6,
									user_def_fld7,user_def_fld8,user_def_fld9,user_def_fld10,user_def_fld11,
									user_def_fld12,eprocurement_ind,sold_to,sopick_ctrl_num,organization_id,
									last_picked_dt,internal_so_ind,ship_to_country_cd,sold_to_city,sold_to_state,
									sold_to_zip,sold_to_country_cd,tax_valid_ind,addr_valid_ind)
		SELECT	order_no,@new_ext,cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,
				date_entered,cust_po,who_entered,status,attention,phone,terms,routing,special_instr,
				invoice_date,total_invoice,total_amt_order,salesperson,tax_id,tax_perc,
				invoice_no,fob,freight,printed,discount,label_no,cancel_date,new,ship_to_name,
				ship_to_add_1,ship_to_add_2,ship_to_add_3,ship_to_add_4,ship_to_add_5,ship_to_city,
				ship_to_state,ship_to_zip,ship_to_country,ship_to_region,cash_flag,type,back_ord_flag,
				freight_allow_pct,route_code,route_no,date_printed,date_transfered,cr_invoice_no,
				who_picked,note,void,void_who,void_date,changed,remit_key,forwarder_key,freight_to,
				sales_comm,freight_allow_type,cust_dfpa,location,total_tax,total_discount,
				f_note,invoice_edi,edi_batch,post_edi_date,blanket,gross_sales,load_no,
				curr_key,curr_type,curr_factor,bill_to_key,oper_factor,tot_ord_tax,
				tot_ord_disc,tot_ord_freight,posting_code,rate_type_home,rate_type_oper,
				reference_code,hold_reason,dest_zone_code,orig_no,orig_ext,tot_tax_incl,
				process_ctrl_num,batch_code,tot_ord_incl,barcode_status,multiple_flag,
				so_priority_code,FO_order_no,blanket_amt,user_priority,user_category,
				from_date,to_date,consolidate_flag,proc_inv_no,sold_to_addr1,sold_to_addr2,
				sold_to_addr3,sold_to_addr4,sold_to_addr5,sold_to_addr6,user_code,user_def_fld1,
				user_def_fld2,user_def_fld3,user_def_fld4,user_def_fld5,user_def_fld6,
				user_def_fld7,user_def_fld8,user_def_fld9,user_def_fld10,user_def_fld11,
				user_def_fld12,eprocurement_ind,sold_to,sopick_ctrl_num,organization_id,
				last_picked_dt,internal_so_ind,ship_to_country_cd,sold_to_city,sold_to_state,
				sold_to_zip,sold_to_country_cd,tax_valid_ind,addr_valid_ind
		FROM	dbo.orders_all
		WHERE	order_no = @order_no
		AND		ext = @ext

		-- CVO_orders_all
		INSERT INTO dbo.CVO_orders_all(order_no,ext,add_case,add_pattern,promo_id,promo_level,
										free_shipping,split_order,flag_print,buying_group, allocation_date)
		SELECT	order_no,@new_ext,add_case,add_pattern,promo_id,promo_level,
				free_shipping,split_order,flag_print,buying_group, allocation_date
		FROM	dbo.CVO_orders_all
		WHERE	order_no = @order_no
		AND		ext = @ext

		-- Ord_list
		INSERT	dbo.ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered,
							ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
							temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,
							void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
							ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,
							part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
							oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,
							reference_code,contract,agreement_id,ship_to,service_agreement_flag,
							inv_available_flag,create_po_flag,load_group_no,return_code,user_count,
							cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
							unpicked_dt)
		SELECT	a.order_no,@new_ext,a.line_no,a.location,a.part_no,a.description,a.time_entered,
				b.qty,a.shipped,a.price,a.price_type,a.note,a.status,a.cost,a.who_entered,a.sales_comm,
				a.temp_price,a.temp_type,a.cr_ordered,a.cr_shipped,a.discount,a.uom,a.conv_factor,a.void,
				a.void_who,a.void_date,a.std_cost,a.cubic_feet,a.printed,a.lb_tracking,a.labor,a.direct_dolrs,
				a.ovhd_dolrs,a.util_dolrs,a.taxable,a.weight_ea,a.qc_flag,a.reason_code,a.qc_no,a.rejected,
				a.part_type,a.orig_part_no,a.back_ord_flag,a.gl_rev_acct,a.total_tax,a.tax_code,a.curr_price,
				a.oper_price,a.display_line,a.std_direct_dolrs,a.std_ovhd_dolrs,a.std_util_dolrs,
				a.reference_code,a.contract,a.agreement_id,a.ship_to,a.service_agreement_flag,
				a.inv_available_flag,a.create_po_flag,a.load_group_no,a.return_code,a.user_count,
				a.cust_po,a.organization_id,a.picked_dt,a.who_picked_id,a.printed_dt,a.who_unpicked_id,a.unpicked_dt
		FROM	dbo.ord_list a
		JOIN	#bo_orders b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext 
		AND		b.qty > 0
		AND		b.lineaction IN ('B','P')
	

		-- CVO_ord_list
		INSERT INTO dbo.CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,
										is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
										is_amt_disc,amt_disc,is_customized,promo_item,list_price)
		SELECT	a.order_no,@new_ext,a.line_no,a.add_case,a.add_pattern,a.from_line_no,
				a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
				a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price	
		FROM	dbo.CVO_ord_list a
		JOIN	#bo_orders b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext 
		AND		b.qty > 0
		AND		b.lineaction IN ('B','P')

		-- ord_list_kit
		INSERT INTO dbo.ord_list_kit (order_no,order_ext,line_no,location,part_no,part_type,ordered,
									shipped,status,lb_tracking,cr_ordered,cr_shipped,uom,conv_factor,
									cost,labor,direct_dolrs,ovhd_dolrs,util_dolrs,note,qty_per,qc_flag,
									qc_no,description)
		SELECT	a.order_no,@new_ext,a.line_no,a.location,a.part_no,a.part_type,b.qty,
				a.shipped,a.status,a.lb_tracking,a.cr_ordered,a.cr_shipped,a.uom,a.conv_factor,
				a.cost,a.labor,a.direct_dolrs,a.ovhd_dolrs,a.util_dolrs,a.note,a.qty_per,a.qc_flag,
				a.qc_no,a.description
		FROM	dbo.ord_list_kit a
		JOIN	#bo_orders b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext 
		AND		b.qty > 0
		AND		b.lineaction IN ('B','P')


		-- CVO_ord_list_kit
		INSERT INTO dbo.CVO_ord_list_kit(order_no,order_ext,line_no,location,part_no,replaced,new1,part_no_original)
		SELECT	a.order_no,@new_ext,a.line_no,a.location,a.part_no,a.replaced,a.new1,a.part_no_original
		FROM	dbo.CVO_ord_list_kit a
		JOIN	#bo_orders b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext 
		AND		b.qty > 0
		AND		b.lineaction IN ('B','P')

		-- Remove lines from original order where they have been moved to a backorder
		DELETE	a
		FROM	dbo.ord_list a
		JOIN	#bo_orders b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext 
		AND		b.qty > 0
		AND		b.lineaction = 'B'

		DELETE	a
		FROM	dbo.ord_list_kit a
		JOIN	#bo_orders b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext 
		AND		b.qty > 0
		AND		b.lineaction = 'B'

		DELETE	a
		FROM	dbo.cvo_ord_list a
		JOIN	#bo_orders b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext 
		AND		b.qty > 0
		AND		b.lineaction = 'B'

		DELETE	a
		FROM	dbo.cvo_ord_list_kit a
		JOIN	#bo_orders b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext 
		AND		b.qty > 0
		AND		b.lineaction = 'B'


		-- Call standard update totals routine for the original and backorder
		EXEC fs_updordtots @order_no, @ext

		-- This stop the backorder being allocated
		IF @WMS = 0
		BEGIN
			IF OBJECT_ID('tempdb..#temp_so') IS NULL
			BEGIN
				CREATE TABLE #temp_so (
					order_no	int, 
					order_ext	int)
			END
		END


		-- Call standard routine for backorder		
		EXEC fs_updordtots @order_no, @new_ext

		SET	@last_ext = @ext

		SELECT	TOP 1 @ext = ext
		FROM	#ext
		WHERE	ext > @last_ext
		ORDER BY ext ASC
	END

	-- Clean up 
	DROP TABLE #bo_orders
	DROP TABLE #ext

END
GO
GRANT EXECUTE ON  [dbo].[CVO_CreateBackOrders_sp] TO [public]
GO
