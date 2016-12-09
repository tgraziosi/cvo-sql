SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CB 20/04/2016 - #1584 - Add discount amount
-- v1.1 CB 09/05/2016 - Need to add cvo_ord_list record
-- v1.2 CB 16/05/2016 - Add acct code from config
-- v1.3 CB 28/10/2016 - #1616 Hold Processing
-- EXEC dbo.cvo_add_promo_discount_line_sp 1421198, 0

CREATE PROC [dbo].[cvo_add_promo_discount_line_sp]	@order_no		int,
												@order_ext		int																						
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@promo_discount		decimal(20,8),
			@ship_to_region		varchar(2),
			@max_line			int,
			@max_display_line	int,
			@gl_rev_acct		varchar(32),
			@status				char(1),
			@userid				varchar(50),
			@tax_code			varchar(10),
			@back_ord_flag		smallint,
			@location			varchar(10),
			@promo_id			varchar(40),
			@promo_level		varchar(40),
			@hold_reason		varchar(20),	
			@prior_hold			varchar(20),
			@line_no			int, -- v1.1	
			@acct_code			varchar(32) -- v1.2

	SELECT	@promo_id = promo_id,
			@promo_level = promo_level,
			@prior_hold = ISNULL(prior_hold,'')
	FROM	cvo_orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (ISNULL(@promo_id, '') = '')
		RETURN 

	-- v1.2 Start
	SELECT	@acct_code = value_str
	FROM	config (NOLOCK)
	WHERE	flag = 'PROMO_$DISC_ACCT'
	
	IF (@acct_code IS NULL OR @acct_code = '')
		SET @acct_code = '4500000000000'
	-- v1.2 End


	SELECT	@promo_discount = ISNULL(order_discount_amount,0)
	FROM	cvo_promotions (NOLOCK)
	WHERE	promo_id = @promo_id
	AND		promo_level = @promo_level

	IF (@promo_discount <> 0)
	BEGIN

		SELECT	@ship_to_region = LEFT(ship_to_region,2),
				@status = status,
				@userid = who_entered,
				@tax_code = tax_id,
				@back_ord_flag = back_ord_flag,
				@location = location,
				@hold_reason = hold_reason
		FROM	orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		-- v1.3 Start
		IF (@hold_reason = 'PROMOHLD')
			RETURN 

		IF EXISTS (SELECT 1 FROM cvo_so_holds (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND hold_reason = 'PROMOHLD')
			RETURN

--		IF (@hold_reason = 'PROMOHLD' OR @prior_hold = 'PROMOHLD')
--			RETURN
		-- v1.3 End

		IF EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = 'PROMOTION DISCOUNT')
		BEGIN
			-- v1.1 Start
			SELECT	@line_no = line_no
			FROM	ord_list (NOLOCK) 
			WHERE	order_no = @order_no 
			AND		order_ext = @order_ext 
			AND		part_no = 'PROMOTION DISCOUNT'
			-- v1.1 End

			DELETE	ord_list 
			WHERE	order_no = @order_no 
			AND		order_ext = @order_ext 
			AND		part_no = 'PROMOTION DISCOUNT'

			-- v1.1 Start
			DELETE	cvo_ord_list
			WHERE	order_no = @order_no 
			AND		order_ext = @order_ext 
			AND		line_no = @line_no
			-- v1.1 End
		END

		SELECT	@max_line = ISNULL(MAX(line_no),0) + 1
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		SELECT	@max_display_line = ISNULL(MAX(display_line),0) + 1
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		IF @max_display_line IS NULL
			SET @max_display_line = 1

		IF @max_line IS NULL
			SET @max_line = 1

		-- v1.2 Start
--		SELECT	@gl_rev_acct = MIN( i.sales_acct_code ) 
--		FROM	in_account i (NOLOCK)  
--		JOIN	locations l (NOLOCK) 
--		ON		l.aracct_code = i.acct_code 
--		AND		l.location = @location 
--		AND		(i.void is null or i.void = 'N') 
		-- v1.2 End
	
		SET @gl_rev_acct = SUBSTRING(@gl_rev_acct,1,4) + @ship_to_region + SUBSTRING(@gl_rev_acct,7,7)

		INSERT INTO dbo.ord_list  WITH (ROWLOCK) (order_no, order_ext, line_no, location, part_no, description, time_entered, ordered, shipped, price,
									price_type, note, status, cost, who_entered, sales_comm, temp_price, temp_type, cr_ordered, cr_shipped,
									discount, uom, conv_factor, void, void_who, void_date, std_cost, cubic_feet, printed, lb_tracking, labor,
									direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code, qc_no, rejected, part_type,
									orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, display_line,
									std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id, ship_to,
									service_agreement_flag, inv_available_flag, create_po_flag, load_group_no, return_code, user_count,
									cust_po, organization_id, picked_dt, who_picked_id, printed_dt, who_unpicked_id, unpicked_dt)
		SELECT	@order_no, @order_ext, @max_line, @location, 'PROMOTION DISCOUNT', 'PROMOTION DISCOUNT', GETDATE(), 1, 0, (@promo_discount * -1), 'Y', '', @status, 0, @userid, 
				0.0, 0.0, NULL, 0, 0, 0.0, 'EA', 1.0, 'N', NULL, NULL, 0.0, 0.0, 'N', 'N', 0, 0, 0, 0, 1, 0, 'N', NULL, 0, 0.0, 'M', 'PROMOTION DISCOUNT', @back_ord_flag, 
				@acct_code, 0.0, @tax_code, (@promo_discount * -1), (@promo_discount * -1), @max_display_line, 0, 0, 0, NULL, '', NULL, NULL, 'N', 'Y', 0, NULL, -- v1.2
				NULL, NULL, NULL, 'CVO', NULL, NULL, NULL, NULL, NULL 

		-- v1.1 Start
		INSERT	dbo.cvo_ord_list  WITH (ROWLOCK) (order_no, order_ext, line_no, add_case, add_pattern, from_line_no, is_case, is_pattern, add_polarized, is_polarized, is_pop_gif,
									is_amt_disc, amt_disc, is_customized, promo_item, list_price, orig_list_price, free_frame, due_date, upsell_flag)
		SELECT	@order_no, @order_ext, @max_line, 'N', 'N', 0, 0, 0, 'N', 0, 0, 'N', 0, 'N', 'N', 0, 0, 0, NULL, NULL
		-- v1.1 End

		EXEC dbo.fs_calculate_oetax_wrap @order_no, @order_ext, 0, -1
		EXEC dbo.fs_updordtots @order_no, @order_ext

	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_add_promo_discount_line_sp] TO [public]
GO
