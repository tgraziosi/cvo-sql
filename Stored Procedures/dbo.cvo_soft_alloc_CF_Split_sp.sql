
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_soft_alloc_CF_Split_sp]	@soft_alloc_no	int,
											@order_no		int,
											@order_ext		int,
											@customer_code	varchar(10)
AS
BEGIN

	-- Directives
	SET NOCOUNT ON
	
	-- Declarations
	DECLARE	@id					int,
			@last_id			int,
			@line_no			int,
			@location			varchar(10),
			@part_no			varchar(30),
			@in_stock			decimal(20,8),
			@alloc_qty			decimal(20,8),
			@quar_qty			decimal(20,8),
			@sa_qty				decimal(20,8),
			@new_ext			int,
			@qty				decimal(20,8),
			@polarized_part		varchar(30),
			@case_part			varchar(30),
			@pattern_part		varchar(30),
			@new_soft_alloc_no	int,
			@last_new_ext		int,
			@promo_id			varchar(20),
			@promo_level		varchar(30),
			@free_shipping		varchar(30),
			@tot_ord_freight	decimal(20,8),
			@weight				decimal(20,8),
			@zip				varchar(15),
			@routing			varchar(10),
			@freight_allow_type	varchar(10),
			@order_value		decimal(20,8),
			@freight_charge		smallint,
			@freight_amt		decimal(20,8),
			@ord_qty			decimal(20,8) -- v1.1

	-- Initialize
-- v3.2	SELECT	@polarized_part = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'DEF_RES_TYPE_POLARIZED'
-- v3.2	IF @polarized_part IS NULL
-- v3.2		SET @polarized_part = 'CVZDEMRM'

	-- Create Working Table
	CREATE TABLE #cf_break (id			int identity(1,1),
							location	varchar(10),
							line_no		int,
							part_no		varchar(30),
							qty			decimal(20,8),
							avail_qty	decimal(20,8), -- v1.2
							orig_qty	decimal(20,8), -- v1.2
							no_stock	int)

	CREATE TABLE #cf_break_kit 
						   (id			int identity(1,1),
							location	varchar(10),
							qty			decimal(20,8), -- v1.1
							avail_qty	decimal(20,8), -- v1.2
							kit_line_no	int,
							kit_part_no	varchar(30),
							no_stock	int)

	CREATE TABLE #wms_ret ( location		varchar(10),
							part_no			varchar(30),
							allocated_qty	decimal(20,8),
							quarantined_qty	decimal(20,8),
							apptype			varchar(20))	

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
							material		smallint,
							part_type		varchar(20),
							new_ext			int)

	CREATE TABLE #part_splits (
							line_no		int,
							part_no		varchar(30),
							quantity	decimal(20,8))

	CREATE TABLE #lines_to_delete (
							order_ext	int,
							line_no		int,
							quantity	decimal(20,8))

	INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
						pattern_part, polarized_part, quantity, material, part_type, new_ext)
	SELECT	a.order_no,
			a.order_ext,
			a.line_no,
			a.location,
			a.part_no,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN 1 ELSE 0 END,
-- v2.1		CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN c.field_1 ELSE '' END,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN fc.case_part ELSE '' END, -- v2.1
-- v2.1		CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN c.field_4 ELSE '' END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN fc.pattern_part ELSE '' END, -- v2.1
-- v3.2		CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN @polarized_part ELSE '' END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN fc.polarized_part ELSE '' END, -- v3.2
			a.ordered,
			CASE WHEN LEFT(c.field_10,5) = 'metal' THEN 1 ELSE CASE WHEN LEFT(c.field_10,7) = 'plastic' THEN 2 ELSE 0 END END,
			d.type_code,
			0
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	inv_master_add c (NOLOCK)
	ON		a.part_no = c.part_no
	LEFT JOIN cvo_ord_list_fc fc (NOLOCK) -- v2.1
	ON		a.order_no = fc.order_no -- v2.1
	AND		a.order_ext = fc.order_ext -- v2.1
	AND		a.line_no = fc.line_no -- v2.1
	JOIN	inv_master d (NOLOCK)
	ON		a.part_no = d.part_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	ORDER BY a.line_no

	-- Get a list of the custom frame breaks from the order
	INSERT	#cf_break (location, line_no, part_no, qty, avail_qty, orig_qty, no_stock) -- v1.2 add available qty
	SELECT	DISTINCT a.location,
			a.line_no,
			a.part_no,
			a.ordered,
			a.ordered, -- v1.2 default to ordered qty
			a.ordered, -- v1.2 default to ordered qty
			0
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list_kit b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.replaced = 'S'

	INSERT	#cf_break_kit (location, qty, avail_qty, kit_line_no, kit_part_no, no_stock) -- v1.1 add qty -- v1.2 add available qty
	SELECT	b.location,
			b.ordered, -- v1.1
			b.ordered, -- v1.2 default to ordered
			a.line_no,
			a.part_no,
			0
	FROM	cvo_ord_list_kit a (NOLOCK)
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		a.replaced = 'S'

	IF EXISTS (SELECT 1 FROM #cf_break) -- Test for substitution at frame level
	BEGIN
		SET @last_id = 0

		SELECT	TOP 1 @id = id,
				@location = location,
				@line_no = line_no,
				@part_no = part_no,
				@ord_qty = qty -- v1.1
		FROM	#cf_break
		WHERE	id > @last_id
		ORDER BY id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			-- Inventory - in stock
			-- START v2.4
			SELECT	@in_stock = in_stock - ISNULL(replen_qty,0)
			--SELECT	@in_stock = in_stock
			-- END v2.4
			FROM	inventory (NOLOCK)
			WHERE	location = @location
			AND		part_no = @part_no

			-- WMS - allocated and quarantined
			INSERT	#wms_ret
			EXEC tdc_get_alloc_qntd_sp @location, @part_no

			SELECT	@alloc_qty = allocated_qty,
					@quar_qty = quarantined_qty
			FROM	#wms_ret

			IF (@alloc_qty IS NULL)
				SET @alloc_qty = 0

			IF (@quar_qty IS NULL)
				SET @quar_qty = 0

			DELETE	#wms_ret

			-- Soft Allocation - commited quantity
			/* v1.4 Start
			SELECT	@sa_qty = ISNULL(CASE WHEN SUM(b.qty) IS NULL 
									THEN SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END) 
									ELSE SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END) - SUM(b.qty) END,0)
			FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
			LEFT JOIN
					dbo.tdc_soft_alloc_tbl b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			AND		a.part_no = b.part_no
			WHERE	a.status IN (0, 1, -1, -3)
			AND		a.soft_alloc_no <> @soft_alloc_no
			AND		a.location = @location
			AND		a.part_no = @part_no
			AND		ISNULL(b.order_type,'S') = 'S' */

			SELECT	@sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)
			FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
			-- START v2.5
			WHERE	a.status IN (0, 1, -1, -4)
			-- WHERE	a.status IN (0, 1, -1)
			-- END v2.5
			AND		a.soft_alloc_no <> @soft_alloc_no
			AND		a.location = @location
			AND		a.part_no = @part_no
			-- v1.4 End

			IF (@sa_qty IS NULL)
				SET @sa_qty = 0

			-- Compare - if no stock available then mark the record
			IF ((@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) < @ord_qty) -- <= 0) v1.1 Check against order quantity
			BEGIN
				UPDATE	#cf_break
				SET		no_stock = 1,
						avail_qty = (@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) -- v1.2
				WHERE	id = @id

			END

			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@location = location,
					@line_no = line_no,
					@part_no = part_no,
					@ord_qty = qty -- v1.1
			FROM	#cf_break
			WHERE	id > @last_id
			ORDER BY id ASC

		END
	END

	IF EXISTS (SELECT 1 FROM #cf_break_kit) -- Test for substitution at kit level
	BEGIN
		SET @last_id = 0

		SELECT	TOP 1 @id = id,
				@location = location,
				@ord_qty = qty, -- v1.1
				@line_no = kit_line_no,
				@part_no = kit_part_no
		FROM	#cf_break_kit
		WHERE	id > @last_id
		ORDER BY id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN

			-- Inventory - in stock
			-- START v2.4
			SELECT	@in_stock = in_stock - ISNULL(replen_qty,0)
			--SELECT	@in_stock = in_stock
			-- END v2.4
			FROM	inventory (NOLOCK)
			WHERE	location = @location
			AND		part_no = @part_no

			-- WMS - allocated and quarantined
			INSERT	#wms_ret
			EXEC tdc_get_alloc_qntd_sp @location, @part_no

			SELECT	@alloc_qty = allocated_qty,
					@quar_qty = quarantined_qty
			FROM	#wms_ret

			IF (@alloc_qty IS NULL)
				SET @alloc_qty = 0

			IF (@quar_qty IS NULL)
				SET @quar_qty = 0

			DELETE	#wms_ret

			-- Soft Allocation - commited quantity
			/* v1.4 Start
			SELECT	@sa_qty = ISNULL(CASE WHEN SUM(b.qty) IS NULL 
									THEN SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END) 
									ELSE SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END) - SUM(b.qty) END,0)
			FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
			LEFT JOIN
					dbo.tdc_soft_alloc_tbl b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			AND		a.part_no = b.part_no
			WHERE	a.status IN (0, 1, -1, -3)
			AND		a.soft_alloc_no <> @soft_alloc_no
			AND		a.location = @location
			AND		a.part_no = @part_no
			AND		ISNULL(b.order_type,'S') = 'S' */

			SELECT	@sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)
			FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
			-- START v2.5
			WHERE	a.status IN (0, 1, -1, -4)
			--WHERE	a.status IN (0, 1, -1)
			-- END v2.5
			AND		a.soft_alloc_no <> @soft_alloc_no
			AND		a.location = @location
			AND		a.part_no = @part_no
			-- v1.4 End

			IF (@sa_qty IS NULL)
				SET @sa_qty = 0

			-- Compare - if no stock available then mark the record
			IF ((@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) < @ord_qty) -- <= 0) v1.1 Check against order quantity
			BEGIN
				UPDATE	#cf_break_kit
				SET		no_stock = 1,
						avail_qty = (@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) -- v1.2
				WHERE	id = @id

			END

			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@location = location,
					@ord_qty = qty, -- v1.1
					@line_no = kit_line_no,
					@part_no = kit_part_no
			FROM	#cf_break_kit
			WHERE	id > @last_id
			ORDER BY id ASC

		END
	END

	-- Mark the frame record if no stock available for the substitution
	UPDATE	a
	SET		no_stock = 1
	FROM	#cf_break a
	JOIN	#cf_break_kit b
	ON		a.line_no = b.kit_line_no
	WHERE	b.no_stock = 1

	-- v1.2 Start Mark the CF with qty of what can be fulfilled
	CREATE TABLE #cf_break_kit_min (
			kit_line_no	int,
			qty			decimal(20,8))

	INSERT	#cf_break_kit_min
	SELECT	kit_line_no,
			MIN(avail_qty)
	FROM	#cf_break_kit
	GROUP BY kit_line_no

	UPDATE	a
	SET		avail_qty = b.qty
	FROM	#cf_break a
	JOIN	#cf_break_kit_min b
	ON		a.line_no = b.kit_line_no
	WHERE	a.no_stock = 1
	AND		b.qty < a.avail_qty

	UPDATE	#cf_break -- If none are available then its the whole order
	SET		avail_qty = qty
	WHERE	avail_qty <= 0

	DROP TABLE #cf_break_kit_min

	IF EXISTS (SELECT 1 FROM #cf_break WHERE avail_qty < qty) -- Is some of the CF available
	BEGIN
		-- Then create a second record for the split, one record for the qty that can be fulfilled and one for the qty not available
		UPDATE	#cf_break
		SET		qty = avail_qty
		WHERE	avail_qty < qty

		INSERT	#cf_break (location, line_no, part_no, qty, avail_qty, orig_qty, no_stock)
		SELECT	location, line_no, part_no, orig_qty - avail_qty, avail_qty, orig_qty, no_stock
		FROM	#cf_break
		WHERE	avail_qty < orig_qty

		-- v1.3 Start - Keep ext 0 if part qty available
		UPDATE	#cf_break
		SET		no_stock = 0
		WHERE	avail_qty = qty
		-- v1.3 End

	END
	-- v1.2 End

	-- Test for no stock
	IF EXISTS (SELECT 1 FROM #cf_break WHERE no_stock = 1)
	BEGIN

		-- v2.8 Start
		EXEC CVO_UnAllocate_sp @order_no, @order_ext, 0, '', 1

		-- v2.8 End

		-- Split out the lines where no stock is available

		SET @last_id = 0

		SELECT	TOP 1 @id = id,
				@location = location,
				@line_no = line_no,
				@part_no = part_no,
				@qty = qty
		FROM	#cf_break
		WHERE	id > @last_id
		AND		no_stock = 1
		ORDER BY id ASC

		WHILE @@ROWCOUNT <> 0
		BEGIN
	
			-- Get the next ext number
			SELECT	@new_ext = MAX(ext) + 1
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no

			DELETE #part_splits

			-- Split the order header
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
			SELECT	order_no, @new_ext, cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,date_entered,cust_po,who_entered,status,attention,phone,terms,routing,special_instr,
					invoice_date,total_invoice,total_amt_order,salesperson,tax_id,tax_perc,invoice_no,fob,freight,printed,discount,label_no,cancel_date,new,ship_to_name,
					ship_to_add_1,ship_to_add_2,ship_to_add_3,ship_to_add_4,ship_to_add_5,ship_to_city,ship_to_state,ship_to_zip,ship_to_country,ship_to_region,cash_flag,type,back_ord_flag,
					freight_allow_pct,route_code,route_no,date_printed,date_transfered,cr_invoice_no,who_picked,note,void,void_who,void_date,changed,remit_key,forwarder_key,freight_to,
					sales_comm,freight_allow_type,cust_dfpa,location,total_tax,total_discount,f_note,invoice_edi,edi_batch,post_edi_date,blanket,gross_sales,load_no,
					curr_key,curr_type,curr_factor,bill_to_key,oper_factor,tot_ord_tax,tot_ord_disc,tot_ord_freight,posting_code,rate_type_home,rate_type_oper,
					reference_code,hold_reason,dest_zone_code,orig_no,orig_ext,tot_tax_incl,process_ctrl_num,batch_code,tot_ord_incl,barcode_status,multiple_flag,
					-- START v2.0
					'3',FO_order_no,blanket_amt,user_priority,user_category,from_date,to_date,consolidate_flag,proc_inv_no,sold_to_addr1,sold_to_addr2,
					-- so_priority_code,FO_order_no,blanket_amt,user_priority,user_category,from_date,to_date,consolidate_flag,proc_inv_no,sold_to_addr1,sold_to_addr2,
					-- END v2.0
					sold_to_addr3,sold_to_addr4,sold_to_addr5,sold_to_addr6,user_code,user_def_fld1,user_def_fld2,user_def_fld3,user_def_fld4,user_def_fld5,user_def_fld6,
					user_def_fld7,1,user_def_fld9,user_def_fld10,user_def_fld11,user_def_fld12,eprocurement_ind,sold_to,sopick_ctrl_num,organization_id, -- user_def_fld8 = 1 this denotes CF break split
					last_picked_dt,internal_so_ind,ship_to_country_cd,sold_to_city,sold_to_state,sold_to_zip,sold_to_country_cd,tax_valid_ind,addr_valid_ind
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			-- cvo_orders_all
			INSERT INTO CVO_orders_all(order_no,ext,add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
										commission_pct, stage_hold, prior_hold, credit_approved, invoice_note, commission_override, email_address, st_consolidate, upsell_flag) 	-- v1.6	v2.7 v2.9 v3.0 v3.1
			SELECT	order_no, @new_ext, add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
					commission_pct, stage_hold, prior_hold, credit_approved, invoice_note, commission_override, email_address, st_consolidate, upsell_flag -- v1.6 v2.7 v2.9 v3.0 v3.1
			FROM	cvo_orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			-- v10.5 Start
			INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
			SELECT	GETDATE() , a.who_entered , 'BO' , 'ADM' , 'ORDER CREATION' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
					'STATUS:N/CF SPLIT ORDER'
			FROM	orders_all a (NOLOCK)
			WHERE	a.order_no = @order_no 
			AND		a.ext = @new_ext 
			-- v10.5 End

			-- ord_list for frames and suns
			INSERT	ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
										temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
										ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
										oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,
										inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
										unpicked_dt)
			SELECT	order_no, @new_ext, a.line_no,a.location,a.part_no,a.description,a.time_entered,@qty,a.shipped,a.price,a.price_type,a.note,a.status,a.cost,a.who_entered,a.sales_comm,
										a.temp_price,a.temp_type,a.cr_ordered,a.cr_shipped,a.discount,a.uom,a.conv_factor,a.void,a.void_who,a.void_date,a.std_cost,a.cubic_feet,a.printed,a.lb_tracking,a.labor,a.direct_dolrs,
										a.ovhd_dolrs,a.util_dolrs,a.taxable,a.weight_ea,a.qc_flag,a.reason_code,a.qc_no,a.rejected,a.part_type,a.orig_part_no,a.back_ord_flag,a.gl_rev_acct,a.total_tax,a.tax_code,a.curr_price,
										a.oper_price,a.display_line,a.std_direct_dolrs,a.std_ovhd_dolrs,a.std_util_dolrs,a.reference_code,a.contract,a.agreement_id,a.ship_to,a.service_agreement_flag,
										a.inv_available_flag,a.create_po_flag,a.load_group_no,a.return_code,a.user_count,a.cust_po,a.organization_id,a.picked_dt,a.who_picked_id,a.printed_dt,a.who_unpicked_id,
										a.unpicked_dt
			FROM	ord_list a (NOLOCK)
			JOIN	#cf_break b
			ON		a.part_no = b.part_no
			AND		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.id = @id
			ORDER BY a.line_no

			-- Keep track of the updates
			INSERT	#lines_to_delete (order_ext, line_no, quantity)
			SELECT	@order_ext, @line_no, @qty

			-- Work the quantity of case, patterns etc required
			SET @case_part = NULL
		
			SELECT	@case_part = case_part
			FROM	#splits
			WHERE	line_no = @line_no
			AND		part_no = @part_no
			AND		has_case = 1

			IF (ISNULL(@case_part,'') > '')
			BEGIN
				INSERT	#part_splits (line_no, part_no, quantity)
				SELECT	line_no,
						part_no,
						@qty
				FROM	#splits 
				WHERE	part_no = @case_part
			END

			SET @pattern_part = NULL

			SELECT	@pattern_part = pattern_part
			FROM	#splits
			WHERE	line_no = @line_no
			AND		part_no = @part_no
			AND		has_pattern = 1

			IF (ISNULL(@pattern_part,'') > '')
			BEGIN
				INSERT	#part_splits (line_no, part_no, quantity)
				SELECT	line_no,
						part_no,
						@qty
				FROM	#splits 
				WHERE	part_no = @pattern_part
			END
			
			SET @polarized_part = NULL

			SELECT	@polarized_part = polarized_part
			FROM	#splits
			WHERE	line_no = @line_no
			AND		part_no = @part_no
			AND		has_polarized = 1

			IF (ISNULL(@polarized_part,'') > '')
			BEGIN
				INSERT	#part_splits (line_no, part_no, quantity)
				SELECT	line_no,
						part_no,
						@qty
				FROM	#splits 
				WHERE	part_no = @polarized_part
			END

			-- ord_list for cases, patterns etc
			INSERT	ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered, ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
										temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
										ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
										oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,
										inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
										unpicked_dt)
			SELECT	order_no, @new_ext, a.line_no,a.location,a.part_no,a.description,a.time_entered,b.quantity,a.shipped,a.price,a.price_type,a.note,a.status,a.cost,a.who_entered,a.sales_comm,
										a.temp_price,a.temp_type,a.cr_ordered,a.cr_shipped,a.discount,a.uom,a.conv_factor,a.void,a.void_who,a.void_date,a.std_cost,a.cubic_feet,a.printed,a.lb_tracking,a.labor,a.direct_dolrs,
										a.ovhd_dolrs,a.util_dolrs,a.taxable,a.weight_ea,a.qc_flag,a.reason_code,a.qc_no,a.rejected,a.part_type,a.orig_part_no,a.back_ord_flag,a.gl_rev_acct,a.total_tax,a.tax_code,a.curr_price,
										a.oper_price,a.display_line,a.std_direct_dolrs,a.std_ovhd_dolrs,a.std_util_dolrs,a.reference_code,a.contract,a.agreement_id,a.ship_to,a.service_agreement_flag,
										a.inv_available_flag,a.create_po_flag,a.load_group_no,a.return_code,a.user_count,a.cust_po,a.organization_id,a.picked_dt,a.who_picked_id,a.printed_dt,a.who_unpicked_id,
										a.unpicked_dt
			FROM	ord_list a (NOLOCK)
			JOIN	#part_splits b
			ON		a.part_no = b.part_no
			AND		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			ORDER BY a.line_no

			-- Keep track of the updates
			INSERT	#lines_to_delete (order_ext, line_no, quantity)
			SELECT	@order_ext, line_no, quantity
			FROM	#part_splits

			-- cvo_ord_list for frames and suns
			INSERT INTO CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
													is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame) -- v1.8
			SELECT	order_no, @new_ext, a.line_no,a.add_case,a.add_pattern,a.from_line_no,a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
													a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, a.free_frame -- v1.8		
			FROM	cvo_ord_list a (NOLOCK)
			JOIN	#cf_break b
			ON		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.id = @id
			ORDER BY a.line_no

			-- cvo_ord_list for cases, patterns etc
			INSERT INTO CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
													is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame) -- v1.8
			SELECT	order_no, @new_ext, a.line_no,a.add_case,a.add_pattern,a.from_line_no,a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
													a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, a.free_frame -- v1.8		

			FROM	cvo_ord_list a (NOLOCK)
			JOIN	#part_splits b
			ON		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			ORDER BY a.line_no

			-- ord_list_kit
			INSERT INTO ord_list_kit (order_no,order_ext,line_no,location,part_no,part_type,ordered,shipped,status,lb_tracking,cr_ordered,cr_shipped,uom,conv_factor,
												cost,labor,direct_dolrs,ovhd_dolrs,util_dolrs,note,qty_per,qc_flag,qc_no,description)
			SELECT	order_no, @new_ext, a.line_no, a.location,a.part_no,a.part_type,@qty,a.shipped,a.status,a.lb_tracking,a.cr_ordered,a.cr_shipped,a.uom,conv_factor,
						a.cost,a.labor,a.direct_dolrs,a.ovhd_dolrs,a.util_dolrs,a.note,a.qty_per,a.qc_flag,a.qc_no,a.description
			FROM	ord_list_kit a (NOLOCK)
			JOIN	#cf_break b
			ON		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.id = @id
			ORDER BY a.line_no

			-- CVO_ord_list_kit
			INSERT INTO CVO_ord_list_kit(order_no,order_ext,line_no,location,part_no,replaced,new1,part_no_original)
			SELECT	order_no,@new_ext,a.line_no,a.location,a.part_no,a.replaced,a.new1,a.part_no_original		
			FROM	cvo_ord_list_kit a (NOLOCK)
			JOIN	#cf_break b
			ON		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.id = @id
			ORDER BY a.line_no

			-- START v2.6
			-- Drawdown promo
			INSERT INTO dbo.CVO_debit_promo_customer_det(
				hdr_rec_id,
				order_no,
				ext,
				line_no,
				credit_amount,
				posted)
			SELECT
				a.hdr_rec_id,
				a.order_no,
				@new_ext,
				a.line_no,
				a.credit_amount,
				0
			FROM
				dbo.CVO_debit_promo_customer_det a (NOLOCK)
			INNER JOIN	
				dbo.ord_list b (NOLOCK)
			ON	
				a.order_no = b.order_no
				AND a.ext = b.order_ext	 
				AND a.line_no = b.line_no
			WHERE
				a.order_no = @order_no   
				AND a.ext = @order_ext
				AND a.line_no IN (SELECT line_no FROM dbo.ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @new_ext)
			-- END v2.6

			-- Soft Allocation hdr
			UPDATE	dbo.cvo_soft_alloc_next_no
			SET		next_no = next_no + 1

			SELECT	@new_soft_alloc_no = next_no
			FROM	dbo.cvo_soft_alloc_next_no

			INSERT	dbo.cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
			VALUES (@new_soft_alloc_no, @order_no, @new_ext, @location, 0, 0)		

			-- Soft Allocation det
			-- Frames and suns
			INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
															kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) -- v1.9
			SELECT	DISTINCT @new_soft_alloc_no, @order_no, @new_ext, a.line_no, a.location, a.part_no, @qty, a.kit_part, 0, 0, a.is_case, a.is_pattern, 0, 0, add_case_flag -- v1.9
			FROM	cvo_soft_alloc_det a (NOLOCK)
			JOIN	#cf_break b
			ON		a.line_no = b.line_no
--			AND		a.part_no = b.part_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.id = @id			

			-- Cases, patterns and polarized
			INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
															kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
			SELECT	@new_soft_alloc_no, @order_no, @new_ext, a.line_no, a.location, a.part_no, b.quantity, a.kit_part, 0, 0, a.is_case, a.is_pattern, 0, 0
			FROM	cvo_soft_alloc_det a (NOLOCK)
			JOIN	#part_splits b
			ON		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext

			SET @last_id = @id

			SELECT	TOP 1 @id = id,
					@location = location,
					@line_no = line_no,
					@part_no = part_no,
					@qty = qty
			FROM	#cf_break
			WHERE	id > @last_id
			AND		no_stock = 1
			ORDER BY id ASC
		END
	END		

	-- Update the existing order to remove lines and update quantities
	CREATE TABLE #cf_updates (
							order_ext	int,
							line_no		int,
							quantity	decimal(20,8))

	INSERT	#cf_updates (order_ext, line_no, quantity)
	SELECT	order_ext, line_no, SUM(quantity)
	FROM	#lines_to_delete
	GROUP BY order_ext, line_no

	UPDATE	b
	SET		quantity = 0
	FROM	ord_list a (NOLOCK)
	JOIN	#cf_updates b
	ON		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.ordered - b.quantity <= 0
	

	-- Flag the header as having a CF split
	UPDATE	orders_all
	SET		user_def_fld8 = 1
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	-- Remove the lines that have been split out
	-- ord_list
	DELETE	a
	FROM	ord_list a
	JOIN	#cf_updates b
	ON		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		b.quantity = 0

	-- cvo_ord_list
	DELETE	a
	FROM	cvo_ord_list a
	JOIN	#cf_updates b
	ON		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		b.quantity = 0

	-- ord_list_kit
	DELETE	a
	FROM	ord_list_kit a
	JOIN	#cf_updates b
	ON		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		b.quantity = 0

	-- cvo_ord_list_kit
	DELETE	a
	FROM	cvo_ord_list_kit a
	JOIN	#cf_updates b
	ON		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		b.quantity = 0

	-- cvo_soft_alloc_det
	DELETE	a
	FROM	cvo_soft_alloc_det a
	JOIN	#cf_updates b
	ON		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		b.quantity = 0

	-- Update quantities for those line that have been changed - cases, patterns etc
	-- ord_list
	UPDATE	a
	SET		ordered = a.ordered - b.quantity
	FROM	ord_list a
	JOIN	#cf_updates b
	ON		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		b.quantity <> 0

	-- cvo_ord_list
	UPDATE	a
	SET		ordered = a.ordered - b.quantity
	FROM	ord_list_kit a
	JOIN	#cf_updates b
	ON		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		b.quantity <> 0

	-- cvo_soft_alloc_det
	UPDATE	a
	SET		quantity = a.quantity - b.quantity
	FROM	cvo_soft_alloc_det a
	JOIN	#cf_updates b
	ON		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		b.quantity <> 0

	-- Check if any orders now do not have any lines
	UPDATE	a
	SET		status = 'V',
			void = 'V',
			void_who = 'CF',
			void_date = GETDATE()
	FROM	orders_all a
	LEFT JOIN
			ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	WHERE	a.order_no = @order_no
	AND		a.ext = @order_ext
	AND		b.order_no IS NULL
	AND		b.order_ext IS NULL

	-- v1.5 Start
	INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
	SELECT	GETDATE() , a.who_entered , 'BO' , 'ADM' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
			'STATUS:V/VOIDED'
	FROM	orders_all a (NOLOCK)
	LEFT JOIN
			ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	WHERE	a.order_no = @order_no
	AND		a.ext = @order_ext
	AND		b.order_no IS NULL
	AND		b.order_ext IS NULL	
	-- v1.5 End


	DELETE	a
	FROM	cvo_soft_alloc_hdr a
	LEFT JOIN
			ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.order_no IS NULL
	AND		b.order_ext IS NULL

	DELETE	a
	FROM	cvo_soft_alloc_det a
	LEFT JOIN
			ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.order_no IS NULL
	AND		b.order_ext IS NULL

	-- START v2.6
	-- Update drawdown promo amoun for customer
	EXEC dbo.cvo_debit_promo_apply_credit_for_splits_sp @order_no, @new_ext
	-- END v2.6


	-- Recalc freight, tax and totals
	SET	@last_new_ext = -1

	SELECT	TOP 1 @new_ext = order_ext
	FROM	cvo_soft_alloc_hdr (NOLOCK)
	WHERE	order_no = @order_no
	AND		status = 0
	AND		order_ext > @last_new_ext
	ORDER BY order_ext ASC 

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- If its not been allocated then manually call the freight calculation
		SELECT	@promo_id = ISNULL(promo_id,''),
				@promo_level = ISNULL(promo_level,''),
				@free_shipping = ISNULL(free_shipping,'N')
		FROM	cvo_orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		ext = @new_ext

		IF @promo_id > '' AND @free_shipping = 'Y'
		BEGIN
			UPDATE	orders_all
			SET		tot_ord_freight = 0
			WHERE	order_no = @order_no
			AND		ext = @new_ext
		END
		ELSE
		BEGIN

			SELECT	@tot_ord_freight = tot_ord_freight,
					@zip = ship_to_zip,
					@routing = routing,
					@freight_allow_type	= ISNULL(freight_allow_type,''),
					@order_value = total_amt_order
			FROM	dbo.orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @new_ext

			SELECT	@weight	= SUM(ordered * ISNULL(weight_ea,0.0))
			FROM	dbo.ord_list (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @new_ext

			SELECT	@freight_charge = ISNULL(freight_charge,0)
			FROM	cvo_armaster_all (NOLOCK)
			WHERE	customer_code = @customer_code
			AND		address_type = 0

			IF @freight_charge = 1
			BEGIN
				-- START v2.3
				IF NOT EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @new_ext AND LEFT(user_category,2) IN ('ST','DO'))
				BEGIN
					EXEC dbo.CVO_GetFreight_tot_sp @order_no, @new_ext, @tot_ord_freight, @zip, @weight, @routing, @freight_allow_type, @order_value, @freight_amt OUTPUT

					UPDATE	orders_all
					SET		tot_ord_freight = @freight_amt
					WHERE	order_no = @order_no
					AND		ext = @new_ext
				END
				-- END v2.3
			END
			ELSE
			BEGIN
				UPDATE	orders
				SET		tot_ord_freight = 0.00, -- v1.7 Need to set to zero - was NULL
						freight_allow_type = 'FRTOVRID'
				WHERE	order_no = @order_no
				AND		ext = @new_ext
			END
		END
		
		-- If its not been allocated then manually call the tax calculation
		-- v2.2 Start
		IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @new_ext AND LEFT(user_category,2) = 'RX')
		BEGIN		
			EXEC dbo.fs_calculate_oetax_wrap @order_no, @new_ext, 0, -1
		END
		-- v2.2 End

		-- Manually call the update order totals
		EXEC dbo.fs_updordtots @order_no, @new_ext

		-- v3.2 Start
		CREATE TABLE #cvo_ord_list_fc (
			order_no		int, 
			order_ext		int, 
			line_no			int, 
			polarized_part	varchar(30) NULL)

		INSERT	#cvo_ord_list_fc
		SELECT	order_no, @new_ext, line_no, polarized_part
		FROM	cvo_ord_list_fc (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		-- v3.2 End

		-- v2.1 Start
		DELETE	cvo_ord_list_fc
		WHERE	order_no = @order_no
		AND		order_ext = @new_ext

		INSERT	dbo.cvo_ord_list_fc (order_no, order_ext, line_no, part_no, case_part, pattern_part)
		SELECT	a.order_no, a.order_ext, a.line_no, a.part_no, ISNULL(inv.field_1,''), ISNULL(inv.field_4,'')
		FROM	ord_list a (NOLOCK)
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		JOIN	inv_master_add inv (NOLOCK)
		ON		b.part_no = inv.part_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @new_ext	
		AND		b.type_code IN ('FRAME','SUN')
		ORDER BY a.order_no, a.order_ext, a.line_no
		-- v2.1 End

		-- v3.2 Start
		UPDATE	a
		SET		polarized_part = b.polarized_part
		FROM	dbo.cvo_ord_list_fc a
		JOIN	#cvo_ord_list_fc b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
	
		DROP TABLE #cvo_ord_list_fc
		-- v3.2 End

		SET	@last_new_ext = @new_ext

		SELECT	TOP 1 @new_ext = order_ext
		FROM	cvo_soft_alloc_hdr (NOLOCK)
		WHERE	order_no = @order_no
		AND		status = 0
		AND		order_ext > @last_new_ext
		ORDER BY order_ext ASC 

	END

	
	DROP TABLE #cf_updates
	DROP TABLE #lines_to_delete
	DROP TABLE #cf_break
	DROP TABLE #cf_break_kit
	DROP TABLE #wms_ret
	DROP TABLE #splits
	DROP TABLE #part_splits
END
GO

GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_CF_Split_sp] TO [public]
GO
