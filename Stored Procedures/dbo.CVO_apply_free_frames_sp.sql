SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 02/07/2013 - Created
v1.1 CB 19/06/2014 - Peformance



*/
CREATE PROCEDURE [dbo].[CVO_apply_free_frames_sp]	@order_no		INT, 
												@ext			INT, 
												@promo_id		VARCHAR(20),
												@promo_level	VARCHAR(30),
												@soft_alloc_no	INT
																  
AS
BEGIN
	DECLARE @line_no		INT,
			@free_qty		DECIMAL(20,8),
			@split			SMALLINT,
			@line_qty		DECIMAL(20,8),
			@new_line_no	INT,
			@curr_price		DECIMAL(20,8),
			@add_case		SMALLINT,
			@add_pattern	SMALLINT,
			@location		VARCHAR(10),
			@part_no		VARCHAR(30),
			@customer_code	VARCHAR(10),
			@ship_to		VARCHAR(10),
			@inv_avail		SMALLINT,
			@available		DECIMAL(20,8),
			@soft_alloc		DECIMAL(20,8)
			

	SET NOCOUNT ON

	-- Reset all free frame lines on the order
	UPDATE
		a
	SET
		discount = 0
	FROM
		dbo.ord_list a  WITH (ROWLOCK)
	INNER JOIN
		dbo.cvo_ord_list b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.order_ext = b.order_ext 
		AND a.line_no = b.line_no
	WHERE
		a.order_no = @order_no
		AND a.order_ext = @ext
		AND ISNULL(b.free_frame,0) = 1
		AND a.discount = 100

	UPDATE
		dbo.cvo_ord_list  WITH (ROWLOCK)
	SET
		free_frame = 0,
		amt_disc = 0
	WHERE
		order_no = @order_no
		AND order_ext = @ext
		AND ISNULL(free_frame,0) = 1


	-- Check if there are any free frame qualifiations passed
	IF NOT EXISTS (SELECT 1 FROM dbo.CVO_free_frame_qualified (NOLOCK) WHERE SPID = @@SPID)
	BEGIN
		RETURN
	END

	-- Clear out working table for this SPID
	DELETE FROM CVO_free_frame_apply WHERE SPID = @@SPID

	-- Get order header detail
	SELECT
		@customer_code = cust_code,
		@ship_to = ship_to
	FROM 
		dbo.orders_all (NOLOCK)
	WHERE
		order_no = @order_no
		AND ext = @ext

	-- Load working table
	INSERT INTO CVO_free_frame_apply  WITH (ROWLOCK)(
		SPID,
		line_no,
		part_no,
		ordered,
		brand,
		category,
		style,
		gender,
		attribute,
		is_free,
		free_qty,
		split,
		price)
	SELECT
		@@SPID,
		a.line_no,
		a.part_no,
		a.ordered,
		'',
		'',
		'',
		'',
		'',
		0,
		0,
		0,
		a.curr_price - ISNULL(b.amt_disc,0)
	FROM
		dbo.ord_list a (NOLOCK)
	INNER JOIN
		dbo.cvo_ord_list b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.order_ext = b.order_ext 
		AND a.line_no = b.line_no
	WHERE
		a.order_no = @order_no
		AND a.order_ext = @ext
	
	-- Call the routine to calculate which frames should be given free
	EXEC dbo.CVO_promotions_free_frames_sp @promo_id, @promo_level, @@SPID, 0

	-- Loop through free frames
	SET @line_no = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1 
			@line_no = line_no,
			@free_qty = free_qty,
			@split = split
		FROM
			dbo.cvo_free_frame_apply (NOLOCK)
		WHERE
			SPID = @@SPID
			AND is_free = 1
			AND line_no > @line_no
		ORDER BY
			line_no

		IF @@ROWCOUNT = 0
			BREAK

		-- Get line details
		SELECT 
			@part_no = a.part_no,
			@location = a.location,
			@line_qty = a.ordered,
			@curr_price = a.curr_price,
			@add_case = CASE ISNULL(b.add_case,'N') WHEN 'Y' THEN 1 ELSE 0 END,
			@add_pattern = CASE ISNULL(b.add_pattern,'N') WHEN 'Y' THEN 1 ELSE 0 END
		FROM
			dbo.ord_list a (NOLOCK)
		INNER JOIN
			dbo.cvo_ord_list b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.order_ext = b.order_ext 
			AND a.line_no = b.line_no
		WHERE
			a.order_no = @order_no
			AND a.order_ext = @ext
			AND a.line_no = @line_no

		-- Full line is free
		IF @split = 0
		BEGIN
			UPDATE
				dbo.ord_list  WITH (ROWLOCK)
			SET
				discount = 100
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			UPDATE
				dbo.cvo_ord_list  WITH (ROWLOCK)
			SET
				free_frame = 1,
				amt_disc = @curr_price
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no
		END
		
		-- Split line
		IF @split = 1
		BEGIN
			SET @line_qty = @line_qty - @free_qty

			-- Create new line for remaining amount
			SELECT
				@new_line_no = MAX(line_no) + 1
			FROM
				dbo.ord_list (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @ext

			-- Create ord_list entry
			INSERT ord_list  WITH (ROWLOCK)(
				order_no,order_ext,  line_no,  location,    
				part_no, description,  time_entered,  ordered,    
				shipped, price,   price_type,  note,    
				status,  cost,   who_entered,  sales_comm,    
				temp_price, temp_type,  cr_ordered,  cr_shipped,    
				discount, uom,   conv_factor,  void,    
				void_who, void_date,  std_cost,  cubic_feet,    
				printed, lb_tracking,  labor,   direct_dolrs,    
				ovhd_dolrs, util_dolrs,  taxable,  weight_ea,    
				qc_flag, reason_code,  qc_no,   rejected,    
				part_type, orig_part_no,  back_ord_flag,  gl_rev_acct,    
				total_tax, tax_code,  curr_price,  oper_price,    
				display_line, std_direct_dolrs, std_ovhd_dolrs,  std_util_dolrs,    
				reference_code, ship_to, service_agreement_flag,                      
				agreement_id,   create_po_flag, load_group_no, return_code, 
				user_count, cust_po)    
			SELECT 
				order_no, order_ext,   @new_line_no,  location,    
				part_no, description,  time_entered,  @line_qty,    
				0,  price,   price_type,  note,    
				'N',  cost,   who_entered,  sales_comm,    
				temp_price, temp_type,  cr_ordered,  cr_shipped,    
				discount, uom,   conv_factor,  void,    
				void_who, void_date,  std_cost,  cubic_feet,    
				printed, lb_tracking,  labor,   direct_dolrs,    
				ovhd_dolrs, util_dolrs,  taxable,  weight_ea,    
				qc_flag, reason_code,  qc_no,   rejected,    
				part_type, orig_part_no,  back_ord_flag,  gl_rev_acct,    
				0,  tax_code,  curr_price,  oper_price,    
				@new_line_no, std_direct_dolrs, std_ovhd_dolrs,  std_util_dolrs,    
				reference_code, ship_to, service_agreement_flag,                 
				agreement_id,   create_po_flag, 0, return_code, 
				user_count,	cust_po    
			FROM 
				dbo.ord_list (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- Create cvo_ord_list entry
			INSERT INTO CVO_ord_list  WITH (ROWLOCK)(    
				order_no,  order_ext,  line_no, add_case,    
				add_pattern, from_line_no, is_case, is_pattern,    
				add_polarized, is_polarized, is_pop_gif,  
				is_amt_disc, amt_disc, is_customized, promo_item, list_price, orig_list_price,
				free_frame)    
			SELECT  
				order_no, order_ext, @new_line_no, add_case,    
				add_pattern, from_line_no, is_case, is_pattern, 
				add_polarized, is_polarized, is_pop_gif,  
				is_amt_disc, amt_disc, is_customized, promo_item, list_price, orig_list_price,
				0
			FROM 
				dbo.CVO_ord_list (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- Create ord_list_kit entry
			INSERT ord_list_kit  WITH (ROWLOCK)( 
				order_no, order_ext, line_no,    
				location, part_no, part_type,    
				ordered, shipped,  status,    
				lb_tracking, cr_ordered, cr_shipped,    
				uom,  conv_factor, cost,    
				labor,  direct_dolrs, ovhd_dolrs,    
				util_dolrs, note,  qty_per,    
				qc_flag, qc_no,  description )  
			SELECT 
				order_no, order_ext,  @new_line_no,    
				location, part_no, part_type,    
				@line_qty,  0,  'N',    
				lb_tracking, cr_ordered, cr_shipped,    
				uom,  conv_factor, cost,    
				labor,  direct_dolrs, ovhd_dolrs,    
				util_dolrs, note,  qty_per,    
				qc_flag, qc_no,  description   -- mls 9/6/00 SCR 24091    
			FROM 
				dbo.ord_list_kit (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- Create cvo_ord_list_kit entry
			INSERT INTO cvo_ord_list_kit  WITH (ROWLOCK)(    
			order_no,  order_ext,  line_no, location,  
			part_no, replaced, new1, part_no_original)    
			SELECT  
				order_no,  order_ext,  @new_line_no, location,  
				part_no, replaced, new1, part_no_original    
			FROM 
				dbo.cvo_ord_list_kit  (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no 

			-- Update existing line
			UPDATE
				dbo.ord_list   WITH (ROWLOCK)
			SET
				ordered = @free_qty,
				discount = 100
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no 

			UPDATE
				dbo.cvo_ord_list  WITH (ROWLOCK)
			SET
				free_frame = 1,
				amt_disc = @curr_price
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- Get inv available from existing soft alloc line
			SELECT	
				@inv_avail = inv_avail
			FROM
				dbo.cvo_soft_alloc_det (NOLOCK)
			WHERE
				soft_alloc_no = @soft_alloc_no
				AND order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no
				AND kit_part = 0 


			-- Update frame/case relationship
			IF EXISTS (SELECT 1 FROM dbo.cvo_ord_list_fc (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no)
			BEGIN
				INSERT INTO dbo.cvo_ord_list_fc  WITH (ROWLOCK)(
					order_no,
					order_ext,
					line_no,
					part_no,
					case_part,
					pattern_part)
				SELECT
					order_no,
					order_ext,
					@new_line_no,
					part_no,
					case_part,
					pattern_part
				FROM 
					dbo.cvo_ord_list_fc (NOLOCK) 
				WHERE 
					order_no = @order_no 
					AND order_ext = @ext 
					AND line_no = @line_no

			END


			-- Update soft alloc line for existing line
			EXEC cvo_add_soft_alloc_line_sp @soft_alloc_no = @soft_alloc_no, @order_no = @order_no, @order_ext = @ext, @line_no = @line_no, @location = @location, @part_no = @part_no,
											@quantity = @free_qty, @kit_part = 0, @add_case = @add_case, @add_pattern = @add_pattern, @deleted = 0, @customer_code = @customer_code, 
											@ship_to = @ship_to, @inv_avail = @inv_avail		


			-- Create soft alloc line for new line 
			EXEC cvo_add_soft_alloc_line_sp @soft_alloc_no = @soft_alloc_no, @order_no = @order_no, @order_ext = @ext, @line_no = @new_line_no, @location = @location, @part_no = @part_no,
											@quantity = @line_qty, @kit_part = 0, @add_case = @add_case, @add_pattern = @add_pattern, @deleted = 0, @customer_code = @customer_code, 
											@ship_to = @ship_to, @inv_avail = @inv_avail		


		END
	END
	
	-- Clear out working tables for this SPID
	DELETE FROM CVO_free_frame_apply WHERE SPID = @@SPID
	DELETE FROM CVO_free_frame_qualified WHERE SPID = @@SPID



END

GO
GRANT EXECUTE ON  [dbo].[CVO_apply_free_frames_sp] TO [public]
GO
