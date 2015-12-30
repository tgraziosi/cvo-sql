SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_soft_alloc_RD_Split_sp]	@soft_alloc_no	int,
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
			@release_date		datetime,
			@last_release_date	datetime,
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
			@ord_qty			decimal(20,8),
			@split_number		int,
			@alt_line			int,
			@has_case			int,
			@has_pattern		int,
			@has_polarized		int,
			@max_row			int ,
			@last_split			int,
			@ship_date			datetime

	-- Initialize
	SELECT	@polarized_part = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'DEF_RES_TYPE_POLARIZED'
	IF @polarized_part IS NULL
		SET @polarized_part = 'CVZDEMRM'

	-- Create Working Table
	CREATE TABLE #rd_split (row_id			int IDENTITY(1,1),
							release_date	datetime,
							line_no			int,
							cf_part			int,
							split_number	int)
	
	CREATE TABLE #splits (	row_id			int IDENTITY(1,1),
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
							orig_qty		decimal(20,8),
							part_type		varchar(20),
							new_ext			int,
							release_date	datetime,
							split_number	int)

	CREATE TABLE #lines_to_delete (
							order_no	int,
							order_ext	int,
							line_no		int,
							quantity	decimal(20,8),
							orig_qty	decimal(20,8),
							qty_left	decimal(20,8))

	CREATE TABLE #lines_to_process (
							row_id			int IDENTITY(1,1),
							split_number	int,
							line_no			int,
							quantity		decimal(20,8))


	-- Processing

	-- Get the lines with future release dates inc parts
	INSERT	#rd_split (release_date, line_no, cf_part, split_number)
	SELECT	a.field_26, b.line_no, 0, 0
	FROM	inv_master_add a (NOLOCK)
	JOIN	ord_list b (NOLOCK)
	ON		a.part_no = b.part_no
	WHERE	b.order_no = @order_no
	AND		b.order_ext = @order_ext
	AND		a.field_26 IS NOT NULL	
	AND		a.field_26 > GETDATE()
	UNION
	SELECT	DISTINCT a.field_26, b.line_no, 1, 0
	FROM	inv_master_add a (NOLOCK)
	JOIN	ord_list_kit b (NOLOCK)
	ON		a.part_no = b.part_no
	JOIN	cvo_ord_list_kit c (NOLOCK)
	ON		b.order_no = c.order_no
	AND		b.order_ext = c.order_ext
	AND		b.line_no = c.line_no
	AND		b.part_no = c.part_no
	WHERE	b.order_no = @order_no
	AND		b.order_ext = @order_ext
	AND		c.replaced = 'S'
	AND		a.field_26 IS NOT NULL	
	AND		a.field_26 > GETDATE()
	ORDER BY a.field_26 ASC
	
	IF (@@ROWCOUNT = 0)
	BEGIN
		DROP TABLE #rd_split
		DROP TABLE #splits
		DROP TABLE #lines_to_delete
		DROP TABLE #lines_to_process
	
		RETURN
	END

	-- v1.1 Start
	SELECT	@ship_date = sch_ship_date
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF NOT EXISTS (SELECT 1 FROM #rd_split WHERE release_date > @ship_date) -- change from >= to > -- tag 12/16
	BEGIN
		DROP TABLE #rd_split
		DROP TABLE #splits
		DROP TABLE #lines_to_delete
		DROP TABLE #lines_to_process
	
		RETURN
	END
	-- v1.1 End

	SELECT	@new_ext = MAX(ext)
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	
	-- Give each release date a new ext
	SET @last_release_date = '1900-01-01'

	SELECT	TOP 1 @release_date = release_date
	FROM	#rd_split
	WHERE	release_date > @last_release_date
	ORDER BY release_date ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		SET @new_ext = @new_ext + 1

		UPDATE	#rd_split
		SET		split_number = @new_ext
		WHERE	release_date = @release_date

		SET @last_release_date = @release_date

		SELECT	TOP 1 @release_date = release_date
		FROM	#rd_split
		WHERE	release_date > @last_release_date
		ORDER BY release_date ASC

	END

	-- Prepare data for processing
	INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
						pattern_part, polarized_part, quantity, orig_qty, part_type, new_ext, release_date, split_number)
	SELECT	a.order_no,
			a.order_ext,
			a.line_no,
			a.location,
			a.part_no,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN fc.case_part ELSE '' END, 
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN fc.pattern_part ELSE '' END, 
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN @polarized_part ELSE '' END,
			a.ordered,
			a.ordered,
			d.type_code,
			0,
			c.field_26,
			0			
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	inv_master_add c (NOLOCK)
	ON		a.part_no = c.part_no
	LEFT JOIN cvo_ord_list_fc fc (NOLOCK) 
	ON		a.order_no = fc.order_no 
	AND		a.order_ext = fc.order_ext 
	AND		a.line_no = fc.line_no 
	JOIN	inv_master d (NOLOCK)
	ON		a.part_no = d.part_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	ORDER BY a.line_no

	SELECT	@new_ext = MAX(ext)
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no

	UPDATE	a
	SET		split_number = b.split_number
	FROM	#splits a
	JOIN	#rd_split b
	ON		a.line_no = b.line_no

	UPDATE	a
	SET		split_number = c.split_number
	FROM	#splits a
	JOIN	inv_master_add b (NOLOCK)
	ON		a.part_no = b.field_35
	JOIN	#splits c
	ON		b.part_no = c.part_no

	UPDATE	a
	SET		split_number = b.split_number
	FROM	#splits a
	JOIN	#splits b
	ON		a.case_part = b.part_no
	WHERE	a.part_type IN ('FRAME','SUN')
	AND		b.part_type = 'CASE'
	AND		b.split_number > @new_ext
	
	-- Test for splits
	IF NOT EXISTS (SELECT 1 FROM #splits WHERE split_number > @new_ext)
	BEGIN
		DROP TABLE #rd_split
		DROP TABLE #splits
		DROP TABLE #lines_to_delete
		DROP TABLE #lines_to_process
	
		RETURN
	END

	SELECT	@max_row = MAX(row_id)
	FROM	#splits

	-- Move cases, patterns, polarized items to relevant ext
	SET @last_id = 0

	SELECT	TOP 1 @id = row_id,
			@line_no = line_no,
			@part_no = part_no,
			@qty = quantity,
			@split_number = split_number,
			@has_case = has_case,
			@has_pattern = has_pattern,
			@has_polarized = has_polarized,
			@case_part = case_part,
			@pattern_part = pattern_part,
			@polarized_part = polarized_part
	FROM	#splits
	WHERE	row_id > @last_id
	AND		part_type in ('FRAME','SUN')
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0 AND @id <= @max_row)
	BEGIN

		IF(@split_number > @new_ext)
		BEGIN
			IF (@has_case = 1)
			BEGIN
				SELECT	TOP 1 @alt_line = line_no
				FROM	#splits
				WHERE	part_no = @case_part
				AND		split_number >= @new_ext
				ORDER BY line_no

				IF NOT EXISTS (SELECT 1 FROM #splits WHERE part_no = @case_part AND split_number = @split_number)
				BEGIN
					INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
							pattern_part, polarized_part, quantity, orig_qty, part_type, new_ext, release_date, split_number)			
					SELECT	order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part,
							pattern_part, polarized_part, @qty, 0, part_type, new_ext, release_date, @split_number
					FROM	#splits
					WHERE	line_no = @alt_line
					AND		part_no = @case_part
					AND		row_id <= @max_row
				END
				ELSE
				BEGIN
					UPDATE	#splits
					SET		quantity = quantity + @qty
					WHERE	line_no = @alt_line
					AND		part_no = @case_part	
					AND		split_number = @split_number
				END

				IF EXISTS (SELECT 1 FROM #splits WHERE line_no = @alt_line AND part_no = @case_part	
						AND split_number = @new_ext)
				BEGIN
					UPDATE	#splits
					SET		quantity = quantity - @qty
					WHERE	line_no = @alt_line
					AND		part_no = @case_part	
					AND		split_number = @new_ext
				END
				ELSE
				BEGIN
					UPDATE	#splits
					SET		quantity = quantity - @qty
					WHERE	line_no = @alt_line
					AND		part_no = @case_part	
					AND		split_number = @split_number
				END
			END
			IF (@has_pattern = 1)
			BEGIN
				SELECT	TOP 1 @alt_line = line_no
				FROM	#splits
				WHERE	part_no = @pattern_part
				AND		split_number >= @new_ext
				ORDER BY line_no

				IF NOT EXISTS (SELECT 1 FROM #splits WHERE part_no = @pattern_part AND split_number = @split_number)
				BEGIN
					INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
							pattern_part, polarized_part, quantity, orig_qty, part_type, new_ext, release_date, split_number)			
					SELECT	order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part,
							pattern_part, polarized_part, @qty, 0, part_type, new_ext, release_date, @split_number
					FROM	#splits
					WHERE	line_no = @alt_line
					AND		part_no = @pattern_part
					AND		row_id <= @max_row
				END
				ELSE
				BEGIN
					UPDATE	#splits
					SET		quantity = quantity + @qty
					WHERE	line_no = @alt_line
					AND		part_no = @pattern_part	
					AND		split_number = @split_number
				END

				IF EXISTS (SELECT 1 FROM #splits WHERE line_no = @alt_line AND part_no = @pattern_part	
						AND split_number = @new_ext)
				BEGIN
					UPDATE	#splits
					SET		quantity = quantity - @qty
					WHERE	line_no = @alt_line
					AND		part_no = @pattern_part	
					AND		split_number = @new_ext
				END
				ELSE
				BEGIN
					UPDATE	#splits
					SET		quantity = quantity - @qty
					WHERE	line_no = @alt_line
					AND		part_no = @pattern_part	
					AND		split_number = @split_number
				END
			END
			IF (@has_polarized = 1)
			BEGIN
				SELECT	TOP 1 @alt_line = line_no
				FROM	#splits
				WHERE	part_no = @polarized_part
				AND		split_number >= @new_ext
				ORDER BY line_no

				IF NOT EXISTS (SELECT 1 FROM #splits WHERE part_no = @polarized_part AND split_number = @split_number)
				BEGIN
					INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
							pattern_part, polarized_part, quantity, orig_qty, part_type, new_ext, release_date, split_number)			
					SELECT	order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part,
							pattern_part, polarized_part, @qty, 0, part_type, new_ext, release_date, @split_number
					FROM	#splits
					WHERE	line_no = @alt_line
					AND		part_no = @polarized_part
					AND		row_id <= @max_row
				END
				ELSE
				BEGIN
					UPDATE	#splits
					SET		quantity = quantity + @qty
					WHERE	line_no = @alt_line
					AND		part_no = @polarized_part	
					AND		split_number = @split_number
				END

				IF EXISTS (SELECT 1 FROM #splits WHERE line_no = @alt_line AND part_no = @polarized_part	
						AND split_number = @new_ext)
				BEGIN
					UPDATE	#splits
					SET		quantity = quantity - @qty
					WHERE	line_no = @alt_line
					AND		part_no = @polarized_part	
					AND		split_number = @new_ext
				END
				ELSE
				BEGIN
					UPDATE	#splits
					SET		quantity = quantity - @qty
					WHERE	line_no = @alt_line
					AND		part_no = @polarized_part	
					AND		split_number = @split_number
				END
			END
		END

		SET @last_id = @id

		SELECT	TOP 1 @id = row_id,
				@line_no = line_no,
				@part_no = part_no,
				@qty = quantity,
				@split_number = split_number,
				@has_case = has_case,
				@has_pattern = has_pattern,
				@has_polarized = has_polarized,
				@case_part = case_part,
				@pattern_part = pattern_part,
				@polarized_part = polarized_part
		FROM	#splits
		WHERE	row_id > @last_id
		AND		part_type in ('FRAME','SUN')
		ORDER BY row_id ASC
	END

	-- Get list of lines to deletes
	INSERT	#lines_to_delete (order_no, order_ext, line_no, quantity, orig_qty)
	SELECT	@order_no,
			@new_ext, 
			line_no,
			orig_qty - quantity,
			orig_qty
	FROM	#splits
	WHERE	quantity < orig_qty

	INSERT	#lines_to_delete (order_no, order_ext, line_no, quantity, orig_qty)
	SELECT	@order_no,
			@new_ext, 
			line_no,
			orig_qty - quantity,
			orig_qty
	FROM	#splits
	WHERE	orig_qty = quantity
	AND		split_number > @new_ext

	UPDATE	#lines_to_delete
	SET		qty_left = CASE quantity WHEN 0 THEN 0 ELSE orig_qty - quantity END

	-- Create new extension orders
	INSERT	#lines_to_process (split_number, line_no, quantity)
	SELECT	split_number,
			line_no,
			quantity
	FROM	#splits
	WHERE	split_number > @new_ext
	ORDER BY split_number, line_no

	-- Check if the order is allocated
	IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext
				AND	order_type = 'S')
	BEGIN
		EXEC CVO_UnAllocate_sp @order_no, @order_ext, 0, '', 1
	END

	SET @last_id = 0
	SET @last_split = 0

	SELECT	TOP 1 @id = row_id,
			@split_number = split_number,
			@line_no = line_no,
			@qty = quantity			
	FROM	#lines_to_process
	WHERE	row_id > @last_id
	ORDER BY row_id ASC	

	WHILE(@@ROWCOUNT <> 0)
	BEGIN
		IF (@split_number <> @last_split)
		BEGIN
			IF (@last_split <> 0)
			BEGIN
				EXEC dbo.cvo_debit_promo_apply_credit_for_splits_sp @order_no, @last_split
			END

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
			SELECT	order_no, @split_number, cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,date_entered,cust_po,who_entered,'A',attention,phone,terms,routing,special_instr,
					invoice_date,total_invoice,total_amt_order,salesperson,tax_id,tax_perc,invoice_no,fob,freight,printed,discount,label_no,cancel_date,new,ship_to_name,
					ship_to_add_1,ship_to_add_2,ship_to_add_3,ship_to_add_4,ship_to_add_5,ship_to_city,ship_to_state,ship_to_zip,ship_to_country,ship_to_region,cash_flag,type,back_ord_flag,
					freight_allow_pct,route_code,route_no,date_printed,date_transfered,cr_invoice_no,who_picked,note,void,void_who,void_date,changed,remit_key,forwarder_key,freight_to,
					sales_comm,freight_allow_type,cust_dfpa,location,total_tax,total_discount,f_note,invoice_edi,edi_batch,post_edi_date,blanket,gross_sales,load_no,
					curr_key,curr_type,curr_factor,bill_to_key,oper_factor,tot_ord_tax,tot_ord_disc,tot_ord_freight,posting_code,rate_type_home,rate_type_oper,
					reference_code,'RD',dest_zone_code,orig_no,orig_ext,tot_tax_incl,process_ctrl_num,batch_code,tot_ord_incl,barcode_status,multiple_flag,
					so_priority_code,FO_order_no,blanket_amt,user_priority,user_category,from_date,to_date,consolidate_flag,proc_inv_no,sold_to_addr1,sold_to_addr2,
					sold_to_addr3,sold_to_addr4,sold_to_addr5,sold_to_addr6,user_code,user_def_fld1,user_def_fld2,user_def_fld3,user_def_fld4,user_def_fld5,user_def_fld6,
					user_def_fld7,user_def_fld8,user_def_fld9,user_def_fld10,user_def_fld11,user_def_fld12,eprocurement_ind,sold_to,sopick_ctrl_num,organization_id,
					last_picked_dt,internal_so_ind,ship_to_country_cd,sold_to_city,sold_to_state,sold_to_zip,sold_to_country_cd,tax_valid_ind,addr_valid_ind
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			-- cvo_orders_all
			INSERT INTO CVO_orders_all(order_no,ext,add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
										commission_pct, stage_hold, prior_hold, credit_approved, invoice_note, commission_override, email_address, st_consolidate, upsell_flag) 
			SELECT	order_no, @split_number, add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
					commission_pct, stage_hold, prior_hold, credit_approved, invoice_note, commission_override, email_address, 0, upsell_flag 
			FROM	cvo_orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
			SELECT	GETDATE() , a.who_entered , 'BO' , 'ADM' , 'ORDER CREATION' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
					'STATUS:A/RD SPLIT ORDER'
			FROM	orders_all a (NOLOCK)
			WHERE	a.order_no = @order_no 
			AND		a.ext = @split_number 

			-- Soft Allocation hdr
			UPDATE	dbo.cvo_soft_alloc_next_no
			SET		next_no = next_no + 1

			SELECT	@new_soft_alloc_no = next_no
			FROM	dbo.cvo_soft_alloc_next_no

			INSERT	dbo.cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
			SELECT  @new_soft_alloc_no, order_no, @split_number, location, 0, 0
			FROM	dbo.cvo_soft_alloc_hdr (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext

			INSERT	dbo.cvo_soft_alloc_no_assign
			SELECT	@order_no, @split_number, @new_soft_alloc_no

			SET @last_split = @split_number
		END

		-- ord_list for frames and suns
		INSERT	ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
										temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
										ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
										oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,
										inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
										unpicked_dt)
		SELECT	order_no, @split_number, a.line_no,a.location,a.part_no,a.description,a.time_entered,@qty,a.shipped,a.price,a.price_type,a.note,'A',a.cost,a.who_entered,a.sales_comm,
									a.temp_price,a.temp_type,a.cr_ordered,a.cr_shipped,a.discount,a.uom,a.conv_factor,a.void,a.void_who,a.void_date,a.std_cost,a.cubic_feet,a.printed,a.lb_tracking,a.labor,a.direct_dolrs,
									a.ovhd_dolrs,a.util_dolrs,a.taxable,a.weight_ea,a.qc_flag,a.reason_code,a.qc_no,a.rejected,a.part_type,a.orig_part_no,a.back_ord_flag,a.gl_rev_acct,a.total_tax,a.tax_code,a.curr_price,
									a.oper_price,a.display_line,a.std_direct_dolrs,a.std_ovhd_dolrs,a.std_util_dolrs,a.reference_code,a.contract,a.agreement_id,a.ship_to,a.service_agreement_flag,
									a.inv_available_flag,a.create_po_flag,a.load_group_no,a.return_code,a.user_count,a.cust_po,a.organization_id,a.picked_dt,a.who_picked_id,a.printed_dt,a.who_unpicked_id,
									a.unpicked_dt
		FROM	ord_list a (NOLOCK)
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.line_no = @line_no

		-- cvo_ord_list for frames and suns
		INSERT INTO CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
												is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame) 
		SELECT	order_no, @split_number, a.line_no,a.add_case,a.add_pattern,a.from_line_no,a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
												a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, a.free_frame 
		FROM	cvo_ord_list a (NOLOCK)
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.line_no = @line_no

		-- ord_list_kit
		INSERT INTO ord_list_kit (order_no,order_ext,line_no,location,part_no,part_type,ordered,shipped,status,lb_tracking,cr_ordered,cr_shipped,uom,conv_factor,
											cost,labor,direct_dolrs,ovhd_dolrs,util_dolrs,note,qty_per,qc_flag,qc_no,description)
		SELECT	order_no, @split_number, a.line_no, a.location,a.part_no,a.part_type,a.ordered,a.shipped,'A',a.lb_tracking,a.cr_ordered,a.cr_shipped,a.uom,conv_factor,
					a.cost,a.labor,a.direct_dolrs,a.ovhd_dolrs,a.util_dolrs,a.note,a.qty_per,a.qc_flag,a.qc_no,a.description
		FROM	ord_list_kit a (NOLOCK)
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.line_no = @line_no

		-- CVO_ord_list_kit
		INSERT INTO CVO_ord_list_kit(order_no,order_ext,line_no,location,part_no,replaced,new1,part_no_original)
		SELECT	order_no, @split_number,a.line_no,a.location,a.part_no,a.replaced,a.new1,a.part_no_original		
		FROM	cvo_ord_list_kit a (NOLOCK)
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.line_no = @line_no

		-- Drawdown promo
		INSERT INTO dbo.CVO_debit_promo_customer_det(hdr_rec_id, order_no, ext, line_no, credit_amount, posted)
		SELECT	a.hdr_rec_id, a.order_no, @split_number, a.line_no, a.credit_amount, 0
		FROM	dbo.CVO_debit_promo_customer_det a (NOLOCK)
		JOIN	dbo.ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext	 
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no   
		AND		a.ext = @order_ext
		AND		a.line_no = @line_no

		-- Soft Allocation det
		INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
														kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) 
		SELECT	DISTINCT @new_soft_alloc_no, @order_no, @split_number, a.line_no, a.location, a.part_no, @qty, a.kit_part, 0, 0, a.is_case, a.is_pattern, 0, 0, add_case_flag 
		FROM	cvo_soft_alloc_det a (NOLOCK)
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.line_no = @line_no

		SET @last_id = @id

		SELECT	TOP 1 @id = row_id,
				@split_number = split_number,
				@line_no = line_no,
				@qty = quantity			
		FROM	#lines_to_process
		WHERE	row_id > @last_id
		ORDER BY row_id ASC	

	END		

	-- Update the existing order to remove lines and update quantities
	IF (OBJECT_ID('tempdb..#temp_who') IS NULL)   
	BEGIN
		CREATE TABLE #temp_who (
			who			VARCHAR(50) NOT NULL,
			login_id	VARCHAR(50) NOT NULL)
	END

	UPDATE	cvo_soft_alloc_det
	SET		change = 1
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	UPDATE	a
	SET		ordered = b.qty_left
	FROM	ord_list a (NOLOCK)
	JOIN	#lines_to_delete b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	b.qty_left > 0
	
	-- Remove the lines that have been split out
	-- cvo_ord_list
	DELETE	a
	FROM	cvo_ord_list a
	JOIN	#lines_to_delete b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.qty_left = 0

	-- ord_list_kit
	DELETE	a
	FROM	ord_list_kit a
	JOIN	#lines_to_delete b 
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.qty_left = 0

	-- cvo_ord_list_kit
	DELETE	a
	FROM	cvo_ord_list_kit a
	JOIN	#lines_to_delete b 
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.qty_left = 0

	-- cvo_soft_alloc_det
	DELETE	a
	FROM	cvo_soft_alloc_det a
	JOIN	#lines_to_delete b 
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.qty_left = 0

	-- ord_list
	DELETE	a
	FROM	ord_list a
	JOIN	#lines_to_delete b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.qty_left = 0


	-- ord_list_kit
	UPDATE	a
	SET		ordered = b.ordered 
	FROM	ord_list_kit a
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = b.order_ext
	AND		a.ordered <> b.ordered

	-- cvo_soft_alloc_det
	UPDATE	a
	SET		quantity = b.ordered
	FROM	cvo_soft_alloc_det a
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_no = @order_ext
	AND		a.quantity <> b.ordered

	-- Check if any orders now do not have any lines
	IF NOT EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
	BEGIN
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

	END	


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
				IF NOT EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @new_ext AND LEFT(user_category,2) IN ('ST','DO'))
				BEGIN
					EXEC dbo.CVO_GetFreight_tot_sp @order_no, @new_ext, @tot_ord_freight, @zip, @weight, @routing, @freight_allow_type, @order_value, @freight_amt OUTPUT

					UPDATE	orders_all
					SET		tot_ord_freight = @freight_amt
					WHERE	order_no = @order_no
					AND		ext = @new_ext
				END
			END
			ELSE
			BEGIN
				UPDATE	orders
				SET		tot_ord_freight = 0.00, 
						freight_allow_type = 'FRTOVRID'
				WHERE	order_no = @order_no
				AND		ext = @new_ext
			END
		END
		
		-- If its not been allocated then manually call the tax calculation
		IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @new_ext AND LEFT(user_category,2) = 'RX')
		BEGIN		
			EXEC dbo.fs_calculate_oetax_wrap @order_no, @new_ext, 0, -1
		END

		-- Manually call the update order totals
		EXEC dbo.fs_updordtots @order_no, @new_ext

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

		SET	@last_new_ext = @new_ext

		SELECT	TOP 1 @new_ext = order_ext
		FROM	cvo_soft_alloc_hdr (NOLOCK)
		WHERE	order_no = @order_no
		AND		status = 0
		AND		order_ext > @last_new_ext
		ORDER BY order_ext ASC 

	END

	DROP TABLE #rd_split
	DROP TABLE #splits
	DROP TABLE #lines_to_delete
	DROP TABLE #lines_to_process

	IF (OBJECT_ID('tempdb..#temp_who') IS NOT NULL)   
	BEGIN
		DROP TABLE #temp_who
	END


END
GO
GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_RD_Split_sp] TO [public]
GO
