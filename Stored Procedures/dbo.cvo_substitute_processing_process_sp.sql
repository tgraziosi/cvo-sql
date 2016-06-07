SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 - CT 03/06/13 - Processes substitutes from Substitute Processing screen
v1.1 - CT 09/10/13 - Issue #1392 - Move note from order line to order header
v1.2 - CT 09/10/13 - Change case log message to be based on config setting
v1.3 - CB 14/09/2015 - #1550 - Add location
v1.4 - CB 10/11/2015 - Fix for list price
v1.5 - CB 04/02/2016 - #1588 Add flat dollar discount to promos
v1.6 - CB 31/05/2016 - Include orders on hold
Returns:	0 = Sucess
			-1 = Nothing marked to process
			1 = Not all orders processed
			2 = No orders processed

EXEC dbo.cvo_substitute_processing_process_sp	@spid = @@SPID
*/
CREATE PROC [dbo].[cvo_substitute_processing_process_sp] @spid	INT = @@SPID

AS
BEGIN

	DECLARE @order_no				INT,
			@ext					INT,
			@line_no				INT,
			@rec_id					INT,
			@qty					DECIMAL(20,8),
			@part_no				VARCHAR(30),
			@promo_id				VARCHAR(20),
			@promo_level			VARCHAR(30),
			@replacement_part_no	VARCHAR(30),
			@part_desc				VARCHAR(255),
			@location				VARCHAR(10),
			@data					VARCHAR(1000),
			@std_cost				DECIMAL(20,8),
			@uom					CHAR(2),
			@lb_tracking			CHAR(1),
			@std_labor				DECIMAL(20,8), 
			@std_direct_dolrs		DECIMAL(20,8), 
			@std_ovhd_dolrs			DECIMAL(20,8), 
			@std_util_dolrs			DECIMAL(20,8), 
			@taxable				INT, 
			@weight_ea				DECIMAL(20,8), 
			@cubic_feet				DECIMAL(20,8),
			@labor					DECIMAL(20,8),
			@qc_flag				CHAR(1),
			@price_qty				DECIMAL(20,8),
			@cust_code				VARCHAR(10), 
			@ship_to				VARCHAR(10),
			@nat_cur_code			VARCHAR(8),
			@plevel					CHAR(1), 
			@price					DECIMAL(20,8),
			@list_price				DECIMAL(20,8),
			@case					VARCHAR(30),
			@replacement_case		VARCHAR(30),
			@replacement_case_desc	VARCHAR(255),
			@row_id					INT,
			@case_line_no			INT,
			@case_qty				DECIMAL(20,8),
			@back_ord_flag			CHAR(1),
			@gl_rev_acct			VARCHAR(32),
			@sales_acct_code		VARCHAR(32),
			@part_sales_acct_code	VARCHAR(32),
			@ship_to_region			CHAR(2),
			@tax_code				VARCHAR(8),
			@soft_alloc_no			INT,
			@inv_available			SMALLINT,
			@qty_available			DECIMAL(20,8),
			@discount				DECIMAL(20,8),
			@log_msg				VARCHAR(1000),
			@log_level				SMALLINT,
			@brand					VARCHAR(10),
			@category				VARCHAR(10),
			@list					CHAR(1),
			@price_override			CHAR(1),
			@promo_price			DECIMAL(20,8),
			@promo_disc				DECIMAL(20,8),
			@price_type				CHAR(1),
			@curr_price				DECIMAL(20,8),
			@oper_price				DECIMAL(20,8),
			@orders_processed		SMALLINT,
			@replacement_pattern	VARCHAR(30),
			@promo_price_disc		decimal(20,8), -- v1.5
			@status					char(1) -- v1.6



	-- Logging
	SELECT @log_level = CASE value_str WHEN 'Y' THEN 1 ELSE 0 END FROM config WHERE flag = 'SUBSTITUTE_PROC_LOG'
	EXEC dbo.cvo_substitute_processing_log_sp 'Starting processing'

	SET @orders_processed = 0 -- False

	-- Check if there is anything to process
	IF NOT EXISTS(SELECT 1 FROM dbo.cvo_substitute_processing_det (NOLOCK) WHERE spid = @spid AND process = 1)
	BEGIN
		-- Log
		EXEC dbo.cvo_substitute_processing_log_sp 'No records marked for processing'
		SELECT -1
		RETURN
	END

	-- v1.3 SET @location = '001'

	CREATE TABLE #price (plevel CHAR(1), price decimal(20,8), next_qty decimal(20,8),  
	   next_price decimal(20,8), promo_price decimal(20,8), sales_comm decimal(20,8),  
	   qloop INT, quote_level INT, quote_curr VARCHAR(10)) 

	-- Get replacement part no info
	SELECT
		@replacement_part_no = b.part_no,
		@part_desc = b.[description],
		@std_cost = c.std_cost,
		@uom = b.uom,
		@lb_tracking = b.lb_tracking,
		@std_labor = c.std_labor, 
		@std_direct_dolrs = c.std_direct_dolrs, 
		@std_ovhd_dolrs = c.std_ovhd_dolrs, 
		@std_util_dolrs = c.std_util_dolrs, 
		@taxable = b.taxable, 
		@weight_ea = b.weight_ea,
		@cubic_feet = b.cubic_feet, 
		@labor = b.labor,
		@qc_flag = b.qc_flag,
		@list_price = e.price,
		@replacement_case = f.field_1,
		@replacement_pattern = f.field_4,
		@location = a.location -- v1.3
	FROM
		dbo.cvo_substitute_processing_hdr a (NOLOCK)
	INNER JOIN
		dbo.inv_master b (NOLOCK)
	ON
		a.replacement_part_no = b.part_no
	INNER JOIN
		dbo.inv_list c (NOLOCK)
	ON	
		b.part_no = c.part_no
	INNER JOIN 
		dbo.adm_inv_price d (NOLOCK)  
	ON  
		b.part_no = d.part_no  
	INNER JOIN 
		dbo.adm_inv_price_det e (NOLOCK)  
	ON  
		d.inv_price_id = e.inv_price_id  
	INNER JOIN
		dbo.inv_master_add f (NOLOCK)
	ON	
		b.part_no = f.part_no
	WHERE
		a.spid = @spid
		AND c.location = a.location -- v1.4 @location
		AND d.active_ind = 1 

	-- Get replacement case's description
	IF ISNULL(@replacement_case,'') <> ''
	BEGIN
		SELECT
			@replacement_case_desc = [description]
		FROM
			dbo.inv_master (NOLOCK)
		WHERE
			part_no = @replacement_case

		-- Log
		SET @log_msg = 'Replacement part: ' + @replacement_part_no + ', case: ' + @replacement_case+ ', pattern: '  + @replacement_pattern 
		EXEC dbo.cvo_substitute_processing_log_sp @log_msg
	END
	ELSE
	BEGIN
		-- Log
		SET @log_msg = 'Replacement part: ' + @replacement_part_no + ', no case'
		EXEC dbo.cvo_substitute_processing_log_sp @log_msg
	END

	-- Get info for calculation account code for replacement case
	SELECT	@sales_acct_code = a.sales_acct_code
	FROM	inv_list i (nolock)
	JOIN	in_account a (nolock)
	ON		a.acct_code = i.acct_code
	WHERE	i.part_no = @replacement_case
	AND		i.location = @location
	AND		( i.void is null or i.void = 'N' )

	-- Get info for calculation account code for replacement case
	SELECT	@part_sales_acct_code = a.sales_acct_code
	FROM	inv_list i (nolock)
	JOIN	in_account a (nolock)
	ON		a.acct_code = i.acct_code
	WHERE	i.part_no = @replacement_part_no
	AND		i.location = @location
	AND		( i.void is null or i.void = 'N' )

	-- Get original part info
	SELECT TOP 1
		--@case = b.field_1,
		@category = c.type_code, 
		@brand = c.category 
	FROM
		dbo.cvo_substitute_processing_det a (NOLOCK)
	INNER JOIN
		dbo.inv_master_add b (NOLOCK)
	ON
		a.part_no = b.part_no
	INNER JOIN
		dbo.inv_master c (NOLOCK)
	ON
		a.part_no = c.part_no
	ORDER BY 
		rec_id

	-- Log
	--SET @log_msg = 'Part case: ' + ISNULL(@case, 'NONE') + ' category: ' + @category + ' brand: ' + @brand 
	SET @log_msg = 'Part category: ' + @category + ' brand: ' + @brand 
	EXEC dbo.cvo_substitute_processing_log_sp @log_msg

	SET @rec_id = 0

	-- Loop through records marked to process
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext,
			@line_no = line_no,	
			@qty = qty,
			@part_no = part_no,
			@promo_id = promo_id,
			@promo_level = promo_level
		FROM 
			dbo.cvo_substitute_processing_det (NOLOCK) 
		WHERE	
			spid = @spid
			AND process = 1
			AND rec_id > @rec_id
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Log
		SET @log_msg = 'Order: ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@ext AS VARCHAR(3)) + ' line: ' + CAST(@line_no AS VARCHAR(5)) + ' qty: ' + CAST(CAST(@qty AS INT) AS VARCHAR(5)) + ' part: ' + @part_no
		EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

		-- Check if order is ok to process
		IF EXISTS (SELECT 1 FROM cvo_soft_alloc_det WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND [status] IN (-1,1))
		BEGIN
			INSERT INTO dbo.cvo_substitute_processing_error (
				spid,
				order_no,
				ext,
				line_no,
				reason)
			SELECT
				@@SPID,
				@order_no,
				@ext,
				@line_no,
				'Order is being processed by another user'

			-- Log
			SET @log_msg = 'Order: ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@ext AS VARCHAR(3)) + ' is being processed by another user.'
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
		END
		ELSE
		BEGIN

			-- Get case for this order
			SELECT TOP 1
				@case = case_part
			FROM
				dbo.cvo_ord_list_fc (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- Log
			SET @log_msg = 'Part case: ' + ISNULL(@case, 'NONE') 
			-- START v1.2
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
			--EXEC dbo.cvo_substitute_processing_log_sp @log_msg
			-- END v1.2

			-- Get qty across order for part
			SELECT 
				@price_qty = SUM(ordered) 
			FROM 
				dbo.ord_list (NOLOCK) 
			WHERE 
				order_no = @order_no 
				AND order_ext = @ext 
				AND location = @location 
				AND part_no = @replacement_part_no
			
			-- Get order info
			SELECT
				@cust_code = cust_code, 
				@ship_to = ship_to,
				@nat_cur_code = curr_key,
				@back_ord_flag = back_ord_flag,
				@ship_to_region = LEFT(ship_to_region,2),
				@tax_code= tax_id,
				@status = status -- v1.6
			FROM
				dbo.orders_all (NOLOCK)
			WHERE 
				order_no = @order_no 
				AND ext = @ext 

			DELETE FROM #price

			SELECT @price_qty = ISNULL(@price_qty,0) + @qty	

			-- If customer doesn't pricing doesn't exist, if part is set to list price only set qty = 0 to force list price
			IF EXISTS (SELECT 1 FROM dbo.f_customer_pricing_exists (@cust_code,@ship_to ,@replacement_part_no, @price_qty) WHERE retval = 0)
			BEGIN
				IF EXISTS (SELECT 1 FROM dbo.inv_master_add (NOLOCK) WHERE	part_no = @replacement_part_no AND ISNULL(field_33,'N') = 'Y') 
				BEGIN
					SET @price_qty = 0
				END

			END
			
			--SELECT @cust_code cust, @ship_to ship_to, @replacement_part_no pn, @location loc, @qty qty, @nat_cur_code curr_key into dbo.ct_sub_data

			-- Get price
			INSERT INTO #price EXEC dbo.fs_get_price	@cust = @cust_code,
														@shipto = @ship_to,
														@clevel = '1',
														@pn = @replacement_part_no,
														@loc = @location,
														@plevel = '1',
														@qty = @price_qty,
														@pct = 0,
														@curr_key = @nat_cur_code,
														@curr_factor = 1,
														@svc_agr = 'N'  
			
			SELECT
				@price = price,
				@plevel = plevel
			FROM
				#price	

			
			-- Log
			SET @log_msg = 'Price: ' + CAST(CAST(@price AS MONEY) AS VARCHAR(10)) + ' price level: ' + @plevel
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level


			-- Get GL account
			SET @gl_rev_acct = SUBSTRING(@part_sales_acct_code,1,4) + @ship_to_region + SUBSTRING(@part_sales_acct_code,7,7) 

			-- Log
			SET @log_msg = 'GL Account: ' + ISNULL(@gl_rev_acct,'')
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level


			-- Get pricing info for this line
			SELECT
				@discount = discount,
				@price_type = price_type,
				@curr_price = curr_price,
				@oper_price = oper_price
			FROM
				dbo.ord_list (NOLOCK)
			WHERE 
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- If a manually entered price then keep this
			IF @price_type = 'X' 
			BEGIN
				SET @plevel = 'X'
				-- Log
				SET @log_msg = 'Line has manually changed price'
				EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
			END 

			-- If manually discounted
			IF @price_type = 'Q' and ISNULL(@discount,0) <> 0
			BEGIN
				SET @plevel = 'Q'
				-- Log
				SET @log_msg = 'Line has manually entered discount'
				EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
			END

			-- Promo pricing
			IF (ISNULL(@promo_id,'') <> '') AND (@price_type <> 'X')  AND (@price_type <> 'Q')
			BEGIN
				-- Log
				SET @log_msg = 'Promo: ' + @promo_id + '-' + @promo_level
				EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

				-- Did the original part qualify for promo pricing?
				SELECT TOP 1
					@list = ISNULL(list,'N'),
					@price_override = ISNULL(price_override,'N'),
					@promo_price = price,
					@promo_disc = ISNULL(discount_per,0),
					@promo_price_disc = ISNULL(discount_price_per,0) -- v1.5

				FROM
					dbo.cvo_line_discounts (NOLOCK)
				WHERE
					promo_id = @promo_id
					AND promo_level = @promo_level
					AND ((ISNULL(brand,'') = '') OR (ISNULL(brand,'') <> @brand))
					AND ((ISNULL(category,'') = '') OR (ISNULL(category,'') <> @category))
				ORDER BY
					line_no

				IF @@ROWCOUNT = 1
				BEGIN
					-- Fixed price
					IF ISNULL(@price_override,'N') = 'Y'
					BEGIN
						SET @price = @promo_price
						SET @plevel = 'Y'
						
						-- Log
						SET @log_msg = 'Promo: Fixed Price - ' + CAST(CAST(@promo_price  AS MONEY) AS VARCHAR(10))
						EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

					END
					ELSE
					BEGIN
						IF @list = 'Y'
						BEGIN
							-- v1.5 Start
							IF (@promo_price_disc > 0)
							BEGIN
								IF (@promo_price_disc >= @list_price)
								BEGIN
									SET @discount = 100
									SET @price = 0
								END
								ELSE
								BEGIN
									SET @discount = 100 - (((@list_price - @promo_price_disc) / @list_price) * 100)
									SET @price = @list_price
								END
							END
							ELSE
							BEGIN
								SET @discount = @promo_disc
								SET @price = @list_price
							END
							-- v1.5 End
							-- Log
							SET @log_msg = 'Promo: List discount - ' + CAST(CAST(@discount AS MONEY) AS VARCHAR(10))
							EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
						END
						ELSE
						BEGIN
							-- v1.5 Start
							IF (@promo_price_disc > 0)
							BEGIN
								IF (@promo_price_disc >= @curr_price)
								BEGIN
									SET @discount = 100
								END
								ELSE
								BEGIN
									SET @discount = 100 - (((@curr_price - @promo_price_disc) / @curr_price) * 100)
								END
							END
							ELSE
							BEGIN
								SET @discount = @promo_disc
							END
							-- v1.5 End
							-- Log
							SET @log_msg = 'Promo: Customer discount - ' + CAST(CAST(@discount AS MONEY) AS VARCHAR(10))
							EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
						END
					END

				END

			END
			

			-- Update ord_list
			UPDATE
				ord_list
			SET
				part_no = @replacement_part_no,
				[description] = @part_desc,
				price = @price,
				--price_type = CASE price_type WHEN '1' THEN @plevel ELSE price_type END, 
				price_type = @plevel,
				temp_price = @price,
				temp_type = @plevel,
				cost = @std_cost,
				uom = @uom,
				cubic_feet = @cubic_feet,
				lb_tracking = @lb_tracking,
				labor = @labor,
				direct_dolrs = @std_direct_dolrs, 
				ovhd_dolrs = @std_ovhd_dolrs, 
				util_dolrs = @std_util_dolrs, 
				--std_direct_dolrs = @std_direct_dolrs, 
				--std_ovhd_dolrs = @std_ovhd_dolrs, 
				--std_util_dolrs = @std_util_dolrs, 
				taxable = @taxable, 
				weight_ea = @weight_ea, 
				qc_flag = @qc_flag,
				curr_price = CASE @plevel WHEN 'X' THEN @curr_price ELSE @price END,
				oper_price = CASE @plevel WHEN 'X' THEN @oper_price ELSE @price END,
				orig_part_no = @replacement_part_no,
				inv_available_flag = 'Y',
				gl_rev_acct = @gl_rev_acct,
				discount = ISNULL(@discount,0)
				-- START v1.1
				--,note = (CASE ISNULL(note,'') WHEN '' THEN '' ELSE note + CHAR(13) + CHAR(10) END) + 'Please Note: Item ' + @part_no + ' was replaced with ' + @replacement_part_no + '.'
				-- END v1.1
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no
			
			-- Log
			SET @log_msg = 'Frame - ord_list updated'
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

			-- START v1.1
			-- Add note to order header
			UPDATE 
				dbo.orders_all 
			SET
				note = (CASE ISNULL(note,'') WHEN '' THEN '' ELSE note + CHAR(13) + CHAR(10) END) + 'Please Note: Item ' + @part_no + ' was replaced with ' + @replacement_part_no + '.'
			WHERE
				order_no = @order_no
				AND ext = @ext
			-- END v1.1
	
			-- Delete existing ord_list_kit records
			DELETE FROM 
				dbo.ord_list_kit 
			WHERE 
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- Insert new ord_list_kit records
			INSERT INTO dbo.ord_list_kit(
				order_no,
				order_ext,
				line_no,
				location,
				part_no,
				part_type,
				ordered,
				shipped,
				[status],
				lb_tracking,
				cr_ordered,
				cr_shipped,
				uom,
				conv_factor,
				cost,
				labor,
				direct_dolrs,
				ovhd_dolrs,
				util_dolrs,
				note,
				qty_per,
				qc_flag,
				qc_no,
				[description])
			SELECT
				@order_no,
				@ext,
				@line_no,
				@location,
				a.part_no,
				b.[status],
				@qty,
				0,
				@status, -- v1.6 'N',
				b.lb_tracking,
				0,
				0,
				b.uom,
				1,
				c.std_cost,
				b.labor,
				c.std_direct_dolrs,
				c.std_ovhd_dolrs,
				c.std_util_dolrs,
				NULL,
				a.qty,
				b.qc_flag,
				0,
				b.[description]
			FROM
				dbo.what_part a (NOLOCK)
			INNER JOIN
				dbo.inv_master b (NOLOCK)
			ON
				a.part_no = b.part_no
			INNER JOIN
				dbo.inv_list c (NOLOCK)
			ON	
				b.part_no = c.part_no
			WHERE
				a.asm_no = @replacement_part_no
				AND c.location = @location

			-- Log
			SET @log_msg = 'Frame - ord_list_kit updated'
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

			

			-- Update cvo_ord_list
			UPDATE
				dbo.cvo_ord_list
			SET
				is_amt_disc = CASE ISNULL(@discount,0) WHEN 0 THEN 'N' ELSE 'Y' END, 
				amt_disc = @price * (ISNULL(@discount,0)/100),
				list_price = @list_price,
				orig_list_price = @list_price
			WHERE 
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- Log
			SET @log_msg = 'Frame - cvo_ord_list updated'
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

			-- Delete existing cvo_ord_list_kit records
			DELETE FROM 
				dbo.cvo_ord_list_kit 
			WHERE 
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- Insert new records into cvo_ord_list_kit
			INSERT cvo_ord_list_kit(
				order_no,
				order_ext,
				line_no,
				location,
				part_no,
				replaced,
				new1,
				part_no_original)
			SELECT
				order_no,
				order_ext,
				line_no,
				location,
				part_no,
				'N',
				'N',
				part_no
			FROM
				dbo.ord_list_kit (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no
		
			-- Log
			SET @log_msg = 'Frame - cvo_ord_list_kit updated'
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

			-- Update cvo_soft_alloc_det
			SET @row_id = 0

			SELECT TOP 1 
				@row_id = row_id 
			FROM
				dbo.cvo_soft_alloc_det (NOLOCK)
			WHERE 
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no 
				AND [status] IN (0,-3,-4) 
			ORDER BY 
				row_id DESC

			IF ISNULL(@row_id,0) <> 0
			BEGIN
				UPDATE
					dbo.cvo_soft_alloc_det
				SET
					part_no = @replacement_part_no,
					inv_avail = 1
				WHERE
					row_id = @row_id

				-- Log
				SET @log_msg = 'Frame - cvo_soft_alloc_det updated'
				EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

			END
			ELSE
			BEGIN
				-- Log
				SET @log_msg = 'Frame - cvo_soft_alloc_det record not found'
				EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
			END

			-- Update the case
			IF ISNULL(@case,'') <> ISNULL(@replacement_case,'')
			BEGIN
				-- Does the part add a case
				IF EXISTS(SELECT 1 FROM dbo.cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND ISNULL(add_case,'N') = 'Y')
				BEGIN

					-- If the original part have a case
					IF ISNULL(@case,'') <> ''
					BEGIN
						-- Find the case line details
						SELECT
							@case_line_no = a.line_no,
							@case_qty = a.ordered
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
							AND a.part_no = @case
							AND b.is_case = 1
							AND (a.ordered - a.shipped) >= @qty
					END
					ELSE
					BEGIN
						SET @case_line_no = -1
					END

					-- Found case line (or no case for the original)
					IF ISNULL(@case_line_no,0) <> 0
					BEGIN
						IF (@case_qty > @qty) OR (@case_line_no = -1)
						BEGIN
							-- If original part has case
							IF @case_line_no > 0
							BEGIN
								-- Decrement existing line in ord_list
								UPDATE 
									dbo.ord_list
								SET
									ordered = ordered - @qty
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @case_line_no

								-- Log
								SET @log_msg = 'Case - ord_list decremeted line:' + CAST(@case_line_no AS VARCHAR(5))
								EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

								-- Decrement existing line in cvo_soft_alloc_det
								UPDATE 
									dbo.cvo_soft_alloc_det
								SET
									quantity = quantity - @qty
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @case_line_no

								-- Log
								SET @log_msg = 'Case - cvo_soft_alloc_det decremeted line:' + CAST(@case_line_no AS VARCHAR(5))
								EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
							END

							-- If new part has case
							IF ISNULL(@replacement_case,'') <> ''
							BEGIN
								SET @case_line_no = 0

								-- Check if this case is already on the order
								SELECT 
									@case_line_no = a.line_no
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
									AND a.part_no = @replacement_case
									AND b.is_case = 1

								IF ISNULL(@case_line_no,0) <> 0
								BEGIN
									-- Case line already exists, update it
									UPDATE
										dbo.ord_list
									SET
										ordered = ordered + @qty
									WHERE
										order_no = @order_no
										AND order_ext = @ext
										AND line_no = @case_line_no

									-- Log
									SET @log_msg = 'Case - ord_list qty updated on existing line:' + CAST(@case_line_no AS VARCHAR(5))
									EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

									-- Soft alloc records
									SELECT TOP 1 
										@row_id = row_id 
									FROM
										dbo.cvo_soft_alloc_det (NOLOCK)
									WHERE 
										order_no = @order_no
										AND order_ext = @ext
										AND line_no = @case_line_no 
										AND [status] IN (0,-3,-4) 
										AND is_case = 1
									ORDER BY 
										row_id DESC

									IF ISNULL(@row_id,0) <> 0
									BEGIN
										UPDATE
											dbo.cvo_soft_alloc_det
										SET
											quantity = quantity + @qty
										WHERE
											row_id = @row_id

										-- Log
										SET @log_msg = 'Case - cvo_soft_alloc_det qty updated on existing line'
										EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
									END
									ELSE
									BEGIN
										-- Add soft_alloc_det record
										SELECT TOP 1 
											@soft_alloc_no = soft_alloc_no 
										FROM
											dbo.cvo_soft_alloc_det (NOLOCK)
										WHERE 
											order_no = @order_no
											AND order_ext = @ext
											AND line_no = @line_no 
											AND [status] IN (0,-3,-4) 
										ORDER BY 
											soft_alloc_no DESC

										IF ISNULL(@soft_alloc_no,0) <> 0
										BEGIN
											-- Check if case is available
											EXEC @qty_available = dbo.cvo_backorder_processing_available_stock_sp @location, @replacement_case								
											SET @inv_available = NULL
											IF @qty_available >= @qty
											BEGIN
												SET @inv_available = 1
											END
								

											INSERT dbo.cvo_soft_alloc_det(
												soft_alloc_no,
												order_no,
												order_ext,
												line_no,
												part_no,
												location,
												quantity,
												kit_part,
												change,
												deleted,
												is_case,
												is_pattern,
												is_pop_gift,
												[status],
												inv_avail,
												case_adjust)
											SELECT
												@soft_alloc_no,
												@order_no,
												@ext,
												@case_line_no,
												@replacement_case,
												@location,
												dbo.f_calculate_case_sa_qty (@order_no,@ext,@soft_alloc_no,@replacement_case,@part_no,@line_no,0,@qty),
												0,
												0,
												0,
												1,
												0,
												0,
												0,
												@inv_available,
												0

											-- Log
											SET @log_msg = 'Case - new cvo_soft_alloc_det record created'
											EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

										END
										ELSE
										BEGIN
											-- Log
											SET @log_msg = 'Case - cannot find soft alloc number'
											EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
				
										END				
									END
									
								END 
								ELSE
								BEGIN
									SELECT @case_line_no = MAX(line_no) + 1 FROM dbo.ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext

									SET @gl_rev_acct = SUBSTRING(@sales_acct_code,1,4) + @ship_to_region + SUBSTRING(@sales_acct_code,7,7) 

									-- Add new ord_list line
									INSERT INTO dbo.ord_list (order_no, order_ext, line_no, location, part_no, description, time_entered, ordered, shipped, price,
											price_type, note, status, cost, who_entered, sales_comm, temp_price, temp_type, cr_ordered, cr_shipped,
											discount, uom, conv_factor, void, void_who, void_date, std_cost, cubic_feet, printed, lb_tracking, labor,
											direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code, qc_no, rejected, part_type,
											orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, display_line,
											std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id, ship_to,
											service_agreement_flag, inv_available_flag, create_po_flag, load_group_no, return_code, user_count,
											cust_po, organization_id, picked_dt, who_picked_id, printed_dt, who_unpicked_id, unpicked_dt)
									SELECT	@order_no, @ext, @case_line_no, @location, @replacement_case, @replacement_case_desc, getdate(), @qty, 
											0, -- shipped 
											0.0, -- price
											'Y', -- price_type
											'', -- note  
											@status, -- v1.6'N', 
											c.std_cost, SUSER_SNAME(), 
											0.0, -- sales _comm
											0.0, -- temp_price
											1, -- temp_type
											0, -- cr_ordered
											0, -- cr_shipped
											0.0, -- discount
											b.uom, 
											1.0, -- conv_factor
											'N', -- void
											NULL, -- void_who
											NULL, -- void_date
											0.0, -- std_cost
											0.0, -- cubic_feet
											'N', -- printed
											b.lb_tracking,
											c.std_labor, c.std_direct_dolrs, c.std_ovhd_dolrs, c.std_util_dolrs, b.taxable, b.weight_ea, b.qc_flag,
											NULL, -- reason_code
											0, -- qc_no,
											0.0, -- rejected
											b.status,
											b.part_no, @back_ord_flag, @gl_rev_acct,
											0.0, -- total_tax
											@tax_code, 
											0.0, -- curr_price
											0.0, -- oper_price 
											@case_line_no, -- display_line
											c.std_direct_dolrs, c.std_ovhd_dolrs, c.std_util_dolrs,
											NULL, -- reference_code
											'', -- contract
											NULL, -- agreement_id
											NULL, -- ship_to
											'N', -- service_agreement_flag
											'Y', -- inv_available_flag
											0, -- create_po
											NULL, NULL, NULL, NULL, --load_group_no, return_code, user_count, cust_po
											'CVO', -- organisation_id
											NULL, NULL, NULL, NULL, NULL --picked_dt, who_picked_id, printed_dt, who_unpicked_id, unpicked_dt
									FROM	
										dbo.inv_master b (NOLOCK)
									JOIN	
										dbo.inv_list c (NOLOCK)
									ON		
										b.part_no = c.part_no
									WHERE
										c.location = @location
										AND b.part_no = @replacement_case

									-- Log
									SET @log_msg = 'Case - new ord_list record created, line:' + CAST(@case_line_no AS VARCHAR(5))
									EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
									
									-- Add cvo_ord_list record
									INSERT INTO dbo.CVO_ord_list (order_no, order_ext, line_no, add_case, add_pattern, from_line_no, is_case, is_pattern, add_polarized,
																	is_polarized, is_pop_gif, is_amt_disc, amt_disc, is_customized, promo_item, list_price, free_frame) 
									SELECT	@order_no, @ext, @case_line_no, 'N', 'N', 0, 1, 0, 'N', 
												0, 0, 'N', 0.0, 'N', 'N', 0.0, 0 

									-- Log
									SET @log_msg = 'Case - new cvo_ord_list record created'
									EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

									-- Add soft_alloc_det record
									SELECT TOP 1 
										@soft_alloc_no = soft_alloc_no 
									FROM
										dbo.cvo_soft_alloc_det (NOLOCK)
									WHERE 
										order_no = @order_no
										AND order_ext = @ext
										AND line_no = @line_no 
										AND [status] IN (0,-3,-4) 
									ORDER BY 
										soft_alloc_no DESC

									IF ISNULL(@soft_alloc_no,0) <> 0
									BEGIN
										-- Check if case is available
										EXEC @qty_available = dbo.cvo_backorder_processing_available_stock_sp @location, @replacement_case								
										SET @inv_available = NULL
										IF @qty_available >= @qty
										BEGIN
											SET @inv_available = 1
										END
																		
										INSERT dbo.cvo_soft_alloc_det(
											soft_alloc_no,
											order_no,
											order_ext,
											line_no,
											part_no,
											location,
											quantity,
											kit_part,
											change,
											deleted,
											is_case,
											is_pattern,
											is_pop_gift,
											[status],
											inv_avail,
											case_adjust)
										SELECT
											@soft_alloc_no,
											@order_no,
											@ext,
											@case_line_no,
											@replacement_case,
											@location,
											@qty,
											0,
											0,
											0,
											1,
											0,
											0,
											0,
											@inv_available,
											0

										-- Log
										SET @log_msg = 'Case - new cvo_soft_alloc_det record created'
										EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

									END
									ELSE
									BEGIN
										-- Log
										SET @log_msg = 'Case - cannot find soft alloc number'
										EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
			
									END
								END				
							END
						END
						ELSE
						BEGIN
							-- If new part has case
							IF ISNULL(@replacement_case,'')	<> ''
							BEGIN
								-- Update existing line to new case
								UPDATE
									ord_list
								SET
									part_no = @replacement_case,
									[description] = @replacement_case_desc,
									ordered = @qty
								WHERE
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @case_line_no

								-- Log
								SET @log_msg = 'Case - updated part number on ord_list record, line:' + CAST(@case_line_no AS VARCHAR(5))
								EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

								-- Update soft alloc record
								SET @row_id = 0

								SELECT TOP 1 
									@row_id = row_id 
								FROM
									dbo.cvo_soft_alloc_det (NOLOCK)
								WHERE 
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @case_line_no 
									AND [status] IN (0,-3,-4) 
								ORDER BY 
									row_id DESC

								IF ISNULL(@row_id,0) <> 0
								BEGIN
									UPDATE
										dbo.cvo_soft_alloc_det
									SET
										part_no = @replacement_case,
										quantity = @qty
									WHERE
										row_id = @row_id

									-- Log
									SET @log_msg = 'Case - updated part number on cvo_soft_alloc_det record'
									EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
								END
								ELSE
								BEGIN
									-- Log
									SET @log_msg = 'Case - soft alloc record not found'
									EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
								END

							END
							ELSE
							BEGIN
								-- New part has no case
								-- Delete original case line
								DELETE FROM dbo.ord_list WHERE order_no = @order_no	AND order_ext = @ext AND line_no = @case_line_no

								-- Log
								SET @log_msg = 'Case - ord_list record deleted, line:' + CAST(@case_line_no AS VARCHAR(5))
								EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
							

								-- Mark soft alloc record as deleted
								SET @row_id = 0

								SELECT TOP 1 
									@row_id = row_id 
								FROM
									dbo.cvo_soft_alloc_det (NOLOCK)
								WHERE 
									order_no = @order_no
									AND order_ext = @ext
									AND line_no = @case_line_no 
									AND [status] IN (0,-3,-4) 
								ORDER BY 
									row_id DESC

								IF ISNULL(@row_id,0) <> 0
								BEGIN
									UPDATE
										dbo.cvo_soft_alloc_det
									SET
										deleted = 1
									WHERE
										row_id = @row_id

									-- Log
									SET @log_msg = 'Case - cvo_soft_alloc_det record marked as deleted'
									EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
								END
							END
						END
					END 
					ELSE
					BEGIN
						-- Log
						SET @log_msg = 'Case - original case line not found'
						EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
					END
				END
				ELSE 
				BEGIN
					-- Log
					SET @log_msg = 'Case - original line did not have case'
					EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
				END
			END
			ELSE
			BEGIN
				-- Log
				SET @log_msg = 'Case - original and replacement the same'
				EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
			END

			-- Update cvo_ord_list_fc
			UPDATE
				dbo.cvo_ord_list_fc
			SET
				part_no = @replacement_part_no,
				case_part = @replacement_case,
				pattern_part = @replacement_pattern
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- Log
			SET @log_msg = 'cvo_ord_list_fc updated'
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

			/*
			-- Calc tax for RX orders
			IF EXISTS (SELECT 1 FROM dbo.orders_all WHERE order_no = @order_no AND ext = @ext AND LEFT(user_category,2) = 'RX')
			BEGIN
				exec fs_calculate_oetax_wrap @order_no, @ext, 0, 1 
			END 
	
			-- Log
			SET @log_msg = 'Called tax calc'
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
			*/

			-- Update order totals
			EXEC fs_updordtots @ordno = @order_no,	@ordext = @ext
			
			-- Log
			SET @log_msg = 'Called order totals update'
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level
		

			-- Write to tdc_log
			SET @data = 'Line ' + CAST(@line_no AS VARCHAR(5)) + ': '  + @part_no + ' replaced with ' + @replacement_part_no

			INSERT INTO dbo.tdc_log (
				tran_date,
				UserID,
				trans_source,
				module,
				trans,
				tran_no,
				tran_ext,
				part_no,
				lot_ser,
				bin_no,
				location,
				quantity,
				data) 										
			SELECT 
				GETDATE(), 
				SUSER_SNAME(), 
				'BO', 
				'ADM', 
				'SUBSTITUTE PROCESSING', 
				CAST(@order_no AS VARCHAR(20)),
				CAST(@ext AS VARCHAR(5)),
				@replacement_part_no, 
				'', 
				'', 
				@location, 
				CAST(CAST(@qty AS INT) AS VARCHAR(20)), 
				@data

			-- Log
			SET @log_msg = 'TDC log record created'
			EXEC dbo.cvo_substitute_processing_log_sp @log_msg, @log_level

			SET @orders_processed = 1 -- True
		END
	END

	IF EXISTS (SELECT 1 FROM dbo.cvo_substitute_processing_error (NOLOCK) WHERE spid = @spid)
	BEGIN
		IF @orders_processed = 1 
		BEGIN
			-- Some orders processed
			SELECT 1
		END
		ELSE
		BEGIN
			-- No orders processed
			SELECT 2
		END
		RETURN
	END

	SELECT 0

	-- Log
	EXEC dbo.cvo_substitute_processing_log_sp 'Processing complete'
END

GO

GRANT EXECUTE ON  [dbo].[cvo_substitute_processing_process_sp] TO [public]
GO
