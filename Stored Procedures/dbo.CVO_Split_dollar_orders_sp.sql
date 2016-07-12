SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_Split_dollar_orders_sp]	@soft_alloc_no	int,
											@order_no		int,
											@order_ext		int,
											@customer_code	varchar(10),
											@ship_to		varchar(10),
											@user_id		varchar(50)
AS
BEGIN

	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@id				int,
			@last_id		int,
			@part_no		varchar(30),
			@qty			decimal(20,8),
			@metal_plastic	int,
			@sun_opticals	int,
			@polarized_part	varchar(30),
			@max_ext		int,
			@new_ext		int,
			@last_new_ext	int,
			@has_split		smallint,
			@promo_id		varchar(20),
			@promo_level	varchar(30),
			@free_shipping	varchar(30),
			@freight_amt	decimal(20,8),
			@tot_ord_freight	decimal(20,8),
			@weight			decimal(20,8),
			@zip			varchar(15),
			@routing		varchar(10),
			@freight_allow_type	varchar(10),
			@order_value	decimal(20,8),
			@freight_charge	smallint,
			@new_soft_alloc_no int,
			@location		varchar(10),
			@dollar_split	decimal(20,8),
			@line_no		int,
			@quantity		decimal(20,8),
			@price			decimal(20,8),
			@start_ext		int,
			@tmp_qty		decimal(20,8),
			@sum_price		decimal(20,8),
			@orig_ext		int,
			@consumed_price	decimal(20,8), -- v10.3
			@debug			int,
			@ca_ext			int, -- v11.2
			@ca_line		int -- v11.2

	-- Set flag
	SET @debug = 0 -- Set to 0 to switch off before delivery
	SET	@has_split = 0

	SELECT	@location = location
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no

	-- Get the information on how to split
	SELECT	@metal_plastic = ISNULL(metal_plastic,0),
			@sun_opticals = ISNULL(suns_opticals,0),
			@dollar_split = ISNULL(max_dollars,0)
	FROM	cvo_armaster_all (NOLOCK)
	WHERE	customer_code = @customer_code
	AND		ship_to = @ship_to

-- v12.3	SELECT	@polarized_part = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'DEF_RES_TYPE_POLARIZED'
-- v12.3	IF @polarized_part IS NULL
-- v12.3		SET @polarized_part = 'CVZDEMRM'

	-- Get the next ext number
	SELECT	@max_ext = MAX(ext)
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	
	SET	@orig_ext = @max_ext

	-- Create working table
	CREATE TABLE #splits (
		id				int IDENTITY(1,1),
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
		price			decimal(20,8),
		material		smallint,
		part_type		varchar(20),
		new_ext			int,
		keep_ext		int)

	CREATE TABLE #part_splits (
		new_ext		int,
		part_no		varchar(30),
		quantity	decimal(20,8))		

	-- v11.2 Start
	CREATE TABLE #case_adjust (
		ext			int,
		line_no		int,
		part_no		varchar(30),
		quantity	decimal(20,8))	

	INSERT	#case_adjust
	SELECT	order_ext,line_no, part_no, case_adjust
	FROM	cvo_soft_alloc_det (NOLOCK)
	WHERE	order_no = @order_no
	AND		ISNULL(case_adjust,0) <> 0

	-- v11.2 End

	-- Get the info
	INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
						pattern_part, polarized_part, quantity, price, material, part_type, new_ext, keep_ext)
	SELECT	a.order_no,
			a.order_ext,
			a.line_no,
			a.location,
			a.part_no,
			CASE WHEN d.type_code = 'POP' THEN 0 ELSE CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN 1 ELSE 0 END END, -- v11.3
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN 1 ELSE 0 END,
-- v11.4	CASE WHEN d.type_code = 'POP' THEN '' ELSE CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN c.field_1 ELSE '' END END, -- v11.3
			CASE WHEN d.type_code = 'POP' THEN '' ELSE CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN fc.case_part ELSE '' END END, -- v11.3 11.4
-- v11.4	CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN c.field_4 ELSE '' END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN fc.pattern_part ELSE '' END, -- v11.4
-- v12.3	CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN @polarized_part ELSE '' END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN fc.polarized_part ELSE '' END, -- v12.3
			a.ordered,
			a.curr_price,
			CASE WHEN LEFT(c.field_10,5) = 'metal' THEN 1 ELSE CASE WHEN LEFT(c.field_10,7) = 'plastic' THEN 2 ELSE 0 END END,
			d.type_code,
			0, 1
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	inv_master_add c (NOLOCK)
	ON		a.part_no = c.part_no
	LEFT JOIN cvo_ord_list_fc fc (NOLOCK) -- v11.4
	ON		a.order_no = fc.order_no -- v11.4
	AND		a.order_ext = fc.order_ext -- v11.4
	AND		a.line_no = fc.line_no -- v11.4
	JOIN	inv_master d (NOLOCK)
	ON		a.part_no = d.part_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	ORDER BY a.line_no
		
	IF (@max_ext > 0)
	BEGIN
		UPDATE	a
		SET		order_ext = b.order_ext,
				new_ext = b.order_ext,
				quantity = b.ordered
		FROM	#splits a
		JOIN	ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.line_no = b.line_no
		WHERE	b.order_ext > 0
	END

	IF (@dollar_split > 0)
	BEGIN

		IF (@debug = 1)
			SELECT * from #splits
	
		IF EXISTS (SELECT 1 FROM #splits WHERE new_ext > 0)
			SET	@last_new_ext = 0
		ELSE
			SET	@last_new_ext = -1

		SET @start_ext = @last_new_ext + 1

		SELECT	TOP 1 @new_ext = new_ext
		FROM	#splits
		WHERE	new_ext > @last_new_ext
		AND		price <> 0
		ORDER BY new_ext ASC 

		WHILE @@ROWCOUNT <> 0
		BEGIN
		
			IF (SELECT SUM(quantity * price) FROM #splits WHERE new_ext = @new_ext) > @dollar_split
			BEGIN

				IF (@debug = 1)
					SELECT 'LOOP1'

				SET @Last_id = 0

				SELECT	TOP 1 @id = id,
						@line_no = line_no,
						@part_no = part_no,
						@quantity = quantity,
						@price = price
				FROM	#splits
				WHERE	price <> 0
				AND		new_ext = @new_ext
				AND		id > @last_id
				ORDER BY id ASC

				WHILE @@ROWCOUNT <> 0
				BEGIN
					
					IF (@debug = 1)
					BEGIN
						SELECT 'LOOP1'
						SELECT '@line_no',@line_no
						SELECT '@part_no',@part_no
						SELECT '@quantity',@quantity
						SELECT '@price',@price
					END

					IF (@quantity > 1 AND (@quantity * @price > @dollar_split))
					BEGIN

						IF (@debug = 1)
							SELECT '(@quantity > 1 AND (@quantity * @price > @dollar_split))'

						SET @tmp_qty = @quantity

						WHILE @tmp_qty > 1
						BEGIN											
	
							IF (@debug = 1)
							BEGIN
								SELECT '(@tmp_qty * @price > @dollar_split)'
								SELECT '@tmp_qty',@tmp_qty
							END

							IF (@tmp_qty * @price > @dollar_split)
							BEGIN
								SET @tmp_qty = @tmp_qty - 1	

								IF (@debug = 1)
								BEGIN
									SELECT '@tmp_qty = @tmp_qty - 1	'
									SELECT '@tmp_qty',@tmp_qty
								END
							END						
							ELSE
							BEGIN

								INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
										pattern_part, polarized_part, quantity, price, material, part_type, new_ext, keep_ext)
								SELECT	order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
										pattern_part, polarized_part, (@quantity - @tmp_qty), price, material, part_type, new_ext, 0
								FROM	#splits
								WHERE	id = @id

								UPDATE	#splits SET keep_ext = 0 WHERE new_ext = @new_ext

								SET @max_ext = @max_ext + 1

								IF (@debug = 1)
								BEGIN
									SELECT 'INSERT'
									SELECT '@line_no',@line_no
									SELECT '@quantity',@quantity
									SELECT '@tmp_qty',@tmp_qty
								END

								UPDATE	#splits SET new_ext = @max_ext, quantity = @tmp_qty, keep_ext = 0 WHERE id = @id
								BREAK

							END
						END
					END
					SET @Last_id = @id

					SELECT	TOP 1 @id = id,
							@line_no = line_no,
							@part_no = part_no,
							@quantity = quantity,
							@price = price
					FROM	#splits
					WHERE	price <> 0
					AND		new_ext = @new_ext
					AND		id > @last_id
					ORDER BY id ASC

				END

				-- @start_ext
				

				SELECT @Last_id = 0
				SET @sum_price = 0

				SELECT	@sum_price = SUM(quantity * price) FROM #splits WHERE new_ext = @start_ext AND price <> 0
				SET @consumed_price = 0 -- v10.3
				SET @max_ext = @max_ext + 1 -- v10.3

				WHILE (@sum_price > @dollar_split)
				BEGIN

					IF (@debug = 1)
					BEGIN
						SELECT 'LOOP2'
						SELECT '@sum_price',@sum_price
						SELECT '@dollar_split',@dollar_split
					END

					SELECT	TOP 1 @id = id,
							@line_no = line_no,
							@part_no = part_no,
							@quantity = quantity,
							@price = price
					FROM	#splits
					WHERE	price <> 0
					AND		new_ext = @start_ext
					AND		id > @last_id
					ORDER BY id ASC

					WHILE @@ROWCOUNT <> 0
					BEGIN						

						IF (@debug = 1)
						BEGIN
							SELECT 'LOOP2'
							SELECT '@line_no',@line_no
							SELECT '@part_no',@part_no
							SELECT '@quantity',@quantity
							SELECT '@price',@price
						END

						-- If qty is 1 and still over limit then split it
						IF ((@quantity = 1) AND (@quantity * @price) > @dollar_split)
						BEGIN

							IF (@debug = 1)
								SELECT '((@quantity = 1) AND (@quantity * @price) > @dollar_split)'

							UPDATE	#splits SET new_ext = @max_ext, quantity = @quantity, keep_ext = 0 WHERE id = @id	
							SET @sum_price = @sum_price - (@quantity * @price)
							SET @consumed_price = @consumed_price + (@quantity * @price)

							IF (@debug = 1)
							BEGIN
								SELECT 'UPDATE'
								SELECT '@line_no',@line_no
								SELECT '@quantity',@quantity
								SELECT '@consumed_price',@consumed_price
								SELECT '@sum_price',@sum_price
							END

							SET @max_ext = @max_ext + 1

							-- v10.4 Start
							SET @Last_id = @id

							SELECT	TOP 1 @id = id,
									@line_no = line_no,
									@part_no = part_no,
									@quantity = quantity,
									@price = price
							FROM	#splits
							WHERE	price <> 0
							AND		new_ext = @start_ext
							AND		id > @last_id
							ORDER BY id ASC


							CONTINUE
							-- v10.4 End
						END


						-- If qty > 1 then is full qty < limit
						IF ((@quantity > 1) AND ((@consumed_price + (@quantity * @price)) <= @dollar_split))
						BEGIN
							IF (@debug = 1)
								SELECT '(@quantity > 1) AND ((@consumed_price + (@quantity * @price)) <= @dollar_split))'

							UPDATE	#splits SET new_ext = @max_ext, quantity = @quantity, keep_ext = 0 WHERE id = @id	
							SET @sum_price = @sum_price - (@quantity * @price)							
							SET @consumed_price = @consumed_price + (@quantity * @price)

							IF (@debug = 1)
							BEGIN
								SELECT 'UPDATE'
								SELECT '@line_no',@line_no
								SELECT '@quantity',@quantity
								SELECT '@consumed_price',@consumed_price
								SELECT '@sum_price',@sum_price
							END

							-- v10.4 Start
							SET @Last_id = @id

							SELECT	TOP 1 @id = id,
									@line_no = line_no,
									@part_no = part_no,
									@quantity = quantity,
									@price = price
							FROM	#splits
							WHERE	price <> 0
							AND		new_ext = @start_ext
							AND		id > @last_id
							ORDER BY id ASC

							CONTINUE
							-- v10.4 End
						END

						IF ((@quantity > 1) AND ((@consumed_price + (@quantity * @price)) > @dollar_split))
						BEGIN

							IF (@debug = 1)
								SELECT '((@quantity > 1) AND ((@consumed_price + (@quantity * @price)) > @dollar_split))'

							-- v10.6 Start
							-- v10.8 As qty is being decremented in the next section just test against a qty of 1
							IF ((@consumed_price + (1 * @price)) > @dollar_split) -- If the whole amount does not fit then increment the ext 
							BEGIN

								IF (@debug = 1)
									SELECT '((@consumed_price + (1 * @price)) > @dollar_split)'			

								SET @max_ext = @max_ext + 1
								UPDATE	#splits SET new_ext = @max_ext, quantity = @quantity, keep_ext = 0 WHERE id = @id	
								SET @sum_price = @sum_price - (@quantity * @price)							
								SET @consumed_price = 0 -- v10.4
								SET @max_ext = @max_ext + 1

								IF (@debug = 1)
								BEGIN	
									SELECT 'UPDATE'
									SELECT '@line_no',@line_no
									SELECT '@quantity',@quantity
									SELECT '@consumed_price',@consumed_price
									SELECT '@sum_price',@sum_price
								END

								SET @Last_id = @id

								SELECT	TOP 1 @id = id,
										@line_no = line_no,
										@part_no = part_no,
										@quantity = quantity,
										@price = price
								FROM	#splits
								WHERE	price <> 0
								AND		new_ext = @start_ext
								AND		id > @last_id
								ORDER BY id ASC

								CONTINUE
							END
							-- v10.6 End							

							SET @tmp_qty = @quantity - 1

							WHILE @tmp_qty > 0
							BEGIN

								IF (@debug = 1)
									SELECT '@tmp_qty',@tmp_qty

								-- v10.6 Start
								IF (@tmp_qty = 0)
								BEGIN
									BREAK
								END
								-- v10.6 End

								IF ((@consumed_price + (@tmp_qty * @price)) <= @dollar_split)
								BEGIN
									IF (@debug = 1)
										SELECT '((@consumed_price + (@tmp_qty * @price)) <= @dollar_split)'

									UPDATE	#splits SET new_ext = @max_ext, quantity = @tmp_qty, keep_ext = 0 WHERE id = @id	
									SET @sum_price = @sum_price - (@tmp_qty * @price)							
									SET @consumed_price = 0 -- v10.4
									SET @max_ext = @max_ext + 1

-- v10.6 Start								
									IF (@debug = 1)
									BEGIN
										SELECT 'UPDATE'
										SELECT '@line_no',@line_no
										SELECT '@quantity',@quantity
										SELECT '@tmp_qty',@tmp_qty
										SELECT '@consumed_price',@consumed_price
										SELECT '@sum_price',@sum_price
									END
--									IF (@tmp_qty = 1)
--									BEGIN
--										BREAK
--									END
-- v10.6 End
									-- Remainder
									IF (((@quantity - @tmp_qty) * @price) <= @dollar_split)
									BEGIN
										IF (@debug = 1)
											SELECT '(((@quantity - @tmp_qty) * @price) <= @dollar_split)'

										INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
												pattern_part, polarized_part, quantity, price, material, part_type, new_ext, keep_ext)
										SELECT	order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
												pattern_part, polarized_part, @quantity - @tmp_qty, price, material, part_type, @max_ext, 0
										FROM	#splits
										WHERE	id = @id

										SET @sum_price = @sum_price - ((@quantity - @tmp_qty) * @price)	-- v10.9						
										SET @consumed_price = ((@quantity - @tmp_qty) * @price) -- v10.4
										IF (@debug = 1)
										BEGIN
											SELECT 'INSERT'
											SELECT '@line_no',@line_no
											SELECT '@quantity',@quantity
											SELECT '@tmp_qty',@tmp_qty
											SELECT '@consumed_price',@consumed_price
											SELECT '@sum_price',@sum_price

											select * from #splits

										END									

										BREAK

									END

								END									
								SET @tmp_qty = @tmp_qty - 1	
							END	

							-- v10.4 Start
							SET @Last_id = @id

							SELECT	TOP 1 @id = id,
									@line_no = line_no,
									@part_no = part_no,
									@quantity = quantity,
									@price = price
							FROM	#splits
							WHERE	price <> 0
							AND		new_ext = @start_ext
							AND		id > @last_id
							ORDER BY id ASC

							CONTINUE		
							-- v10.4 End	
						END
						
						IF ((@quantity = 1) AND ((@consumed_price + (@quantity * @price)) <= @dollar_split))
						BEGIN
					
							IF (@debug = 1)
								SELECT '((@quantity = 1) AND ((@consumed_price + (@quantity * @price)) <= @dollar_split))'

							UPDATE	#splits SET new_ext = @max_ext, quantity = @quantity, keep_ext = 0 WHERE id = @id	
							SET @sum_price = @sum_price - (@quantity * @price)							
							SET @consumed_price = @consumed_price + (@quantity * @price)

							IF (@debug = 1)
							BEGIN
								SELECT 'UPDATE'
								SELECT '@line_no',@line_no
								SELECT '@quantity',@quantity
								SELECT '@consumed_price',@consumed_price
								SELECT '@sum_price',@sum_price
							END

							-- v10.4 Start
							SET @Last_id = @id

							SELECT	TOP 1 @id = id,
									@line_no = line_no,
									@part_no = part_no,
									@quantity = quantity,
									@price = price
							FROM	#splits
							WHERE	price <> 0
							AND		new_ext = @start_ext
							AND		id > @last_id
							ORDER BY id ASC

							CONTINUE
							-- v10.4 End
						END
						ELSE
						BEGIN
							SET @max_ext = @max_ext + 1
							UPDATE	#splits SET new_ext = @max_ext, quantity = @quantity, keep_ext = 0 WHERE id = @id	
							SET @sum_price = @sum_price - (@quantity * @price)							
							SET @consumed_price = (@quantity * @price)

							IF (@debug = 1)
							BEGIN
								SELECT 'ELSE UPDATE'
								SELECT '@line_no',@line_no
								SELECT '@quantity',@quantity
								SELECT '@consumed_price',@consumed_price
								SELECT '@sum_price',@sum_price
							END	

							-- v10.4 Start
							SET @Last_id = @id

							SELECT	TOP 1 @id = id,
									@line_no = line_no,
									@part_no = part_no,
									@quantity = quantity,
									@price = price
							FROM	#splits
							WHERE	price <> 0
							AND		new_ext = @start_ext
							AND		id > @last_id
							ORDER BY id ASC

							CONTINUE	
							-- v10.4 End
						END

						SET @Last_id = @id

						SELECT	TOP 1 @id = id,
								@line_no = line_no,
								@part_no = part_no,
								@quantity = quantity,
								@price = price
						FROM	#splits
						WHERE	price <> 0
						AND		new_ext = @start_ext
						AND		id > @last_id
						ORDER BY id ASC
					END
				END

				IF (@debug = 1)
					SELECT 'LOOP AGAIN'

				--SET @max_ext = @max_ext + 1
				SELECT @max_ext = MAX(new_ext) + 1 FROM #splits

				UPDATE	#splits SET new_ext = @max_ext, keep_ext = 0 WHERE new_ext = @start_ext AND price <> 0

			END

			SET	@last_new_ext = @new_ext

			SELECT	TOP 1 @new_ext = new_ext
			FROM	#splits
			WHERE	new_ext > @last_new_ext
			AND		price <> 0
			ORDER BY new_ext ASC 

		END

		IF (@debug = 1)
			SELECT * FROM #splits

		-- If any of the original records have been updated then give them a new ext
		SET	@last_new_ext = -1

		SELECT	TOP 1 @new_ext = new_ext
		FROM	#splits
		WHERE	new_ext > @last_new_ext
		AND		price <> 0
		AND		new_ext <= @orig_ext
		AND		keep_ext = 0
		ORDER BY new_ext ASC 

		WHILE @@ROWCOUNT <> 0
		BEGIN		

			SET @max_ext = @max_ext + 1

			UPDATE	#splits
			SET		new_ext = @max_ext
			WHERE	new_ext = @new_ext

			SET	@last_new_ext = @new_ext

			SELECT	TOP 1 @new_ext = new_ext
			FROM	#splits
			WHERE	new_ext > @last_new_ext
			AND		price <> 0
			AND		new_ext <= @orig_ext
			AND		keep_ext = 0
			ORDER BY new_ext ASC 

		END

		-- Now mark up the cases, patterns, etc so they have the correct ext
		INSERT	#part_splits (new_ext, part_no, quantity)
		SELECT	new_ext,
				case_part,
				SUM(quantity)
		FROM	#splits
		WHERE	case_part <> ''
		GROUP BY new_ext, case_part

		INSERT	#part_splits (new_ext, part_no, quantity)
		SELECT	new_ext,
				pattern_part,
				SUM(quantity)
		FROM	#splits
		WHERE	pattern_part <> ''
		GROUP BY new_ext, pattern_part

		INSERT	#part_splits (new_ext, part_no, quantity)
		SELECT	new_ext,
				polarized_part,
				SUM(quantity)
		FROM	#splits
		WHERE	polarized_part <> ''
		GROUP BY new_ext, polarized_part

	END

	IF (@debug = 1)
	BEGIN
		SELECT * FROM #case_adjust
		SELECT * FROM #part_splits
	END
	
	-- v11.2 Start adjust cases
	IF EXISTS (SELECT 1 FROM #case_adjust)
	BEGIN
		SELECT	@ca_ext = MAX(a.new_ext),
				@ca_line = MAX(b.line_no)
		FROM	#part_splits a
		JOIN	#case_adjust b
		ON		a.part_no = b.part_no
		WHERE	(a.quantity + b.quantity) > 0

		UPDATE	#case_adjust
		SET		ext = @ca_ext
		WHERE	line_no = @ca_line

		UPDATE	a 
		SET		quantity = a.quantity + b.quantity
		FROM	#part_splits a
		JOIN	#case_adjust b
		ON		a.part_no = b.part_no
		WHERE	new_ext = @ca_ext

		DELETE	#part_splits
		WHERE	quantity = 0			

		IF (@debug = 1)
		BEGIN
			SELECT * FROM #case_adjust
			SELECT * FROM #part_splits
		END

	END
	-- v11.2 End

	-- v11.3 Add the POP items where the price is zero to the max ext
	SELECT	@ca_ext = MAX(new_ext)
	FROM	#splits
	WHERE	keep_ext = 0

	UPDATE	#splits
	SET		new_ext = @ca_ext,
			keep_ext = 0
	WHERE	part_type = 'POP'
	AND		price = 0
	AND		new_ext = 0
	-- v11.3 End

	IF (@debug = 2)
	BEGIN
		SELECT * FROM #splits
	END


	-- Create working tables
	-- orders_all
	SELECT * INTO #orders_all FROM orders_all WHERE 1 = 2
	-- cvo_orders_all
	SELECT * INTO #cvo_orders_all FROM cvo_orders_all WHERE 1 = 2
	-- ord_list
	CREATE TABLE #ord_list(
		timestamp timestamp NOT NULL,
		order_no int NOT NULL,
		order_ext int NOT NULL,
		line_no int NOT NULL,
		location varchar(10) NULL,
		part_no varchar(30) NOT NULL,
		description varchar(255) NULL,
		time_entered datetime NOT NULL,
		ordered decimal(20, 8) NOT NULL,
		shipped decimal(20, 8) NOT NULL,
		price decimal(20, 8) NOT NULL,
		price_type char(1) NULL,
		note varchar(255) NULL,
		status char(1) NOT NULL,
		cost decimal(20, 8) NOT NULL,
		who_entered varchar(20) NULL,
		sales_comm decimal(20, 8) NOT NULL,
		temp_price decimal(20, 8) NULL,
		temp_type char(1) NULL,
		cr_ordered decimal(20, 8) NOT NULL,
		cr_shipped decimal(20, 8) NOT NULL,
		discount decimal(20, 8) NOT NULL,
		uom char(2) NULL,
		conv_factor decimal(20, 8) NOT NULL,
		void char(1) NULL DEFAULT ('N'),
		void_who varchar(20) NULL,
		void_date datetime NULL,
		std_cost decimal(20, 8) NOT NULL,
		cubic_feet decimal(20, 8) NOT NULL,
		printed char(1) NULL,
		lb_tracking char(1) NULL DEFAULT ('N'),
		labor decimal(20, 8) NOT NULL,
		direct_dolrs decimal(20, 8) NOT NULL,
		ovhd_dolrs decimal(20, 8) NOT NULL,
		util_dolrs decimal(20, 8) NOT NULL,
		taxable int NULL,
		weight_ea decimal(20, 8) NULL,
		qc_flag char(1) NULL DEFAULT ('N'),
		reason_code varchar(10) NULL,
		row_id int IDENTITY(1,1) NOT NULL,
		qc_no int NULL DEFAULT ((0)),
		rejected decimal(20, 8) NULL DEFAULT ((0)),
		part_type char(1) NULL DEFAULT ('P'),
		orig_part_no varchar(30) NULL,
		back_ord_flag char(1) NULL,
		gl_rev_acct varchar(32) NULL,
		total_tax decimal(20, 8) NOT NULL,
		tax_code varchar(10) NULL,
		curr_price decimal(20, 8) NOT NULL,
		oper_price decimal(20, 8) NOT NULL,
		display_line int NOT NULL,
		std_direct_dolrs decimal(20, 8) NULL,
		std_ovhd_dolrs decimal(20, 8) NULL,
		std_util_dolrs decimal(20, 8) NULL,
		reference_code varchar(32) NULL,
		contract varchar(16) NULL,
		agreement_id varchar(32) NULL,
		ship_to varchar(10) NULL,
		service_agreement_flag char(1) NULL,
		inv_available_flag char(1) NOT NULL,
		create_po_flag smallint NULL,
		load_group_no int NULL,
		return_code varchar(10) NULL,
		user_count int NULL,
		cust_po varchar(20) NULL,
		organization_id varchar(30) NULL,
		picked_dt datetime NULL,
		who_picked_id varchar(30) NULL,
		printed_dt datetime NULL,
		who_unpicked_id varchar(30) NULL,
		unpicked_dt datetime NULL) 
	-- cvo_ord_list
	CREATE TABLE #CVO_ord_list(
		order_no int NOT NULL,
		order_ext int NOT NULL,
		line_no int NOT NULL,
		add_case varchar(1) NULL DEFAULT ('N'),
		add_pattern varchar(1) NULL DEFAULT ('N'),
		from_line_no int NULL,
		is_case int NULL DEFAULT ((0)),
		is_pattern int NULL DEFAULT ((0)),
		add_polarized varchar(1) NULL DEFAULT ('N'),
		is_polarized int NULL DEFAULT ((0)),
		is_pop_gif int NULL DEFAULT ((0)),
		is_amt_disc varchar(1) NULL DEFAULT ('N'),
		amt_disc decimal(20, 8) NULL DEFAULT ((0)),
		is_customized varchar(1) NULL DEFAULT ('N'),
		promo_item varchar(1) NULL DEFAULT ('N'),
		list_price decimal(20, 8) NULL DEFAULT ((0)),
		free_frame smallint NULL DEFAULT(0)) -- v11.0 
	-- ord_list_kit 
	CREATE TABLE #ord_list_kit(
		timestamp timestamp NOT NULL,
		order_no int NOT NULL,
		order_ext int NOT NULL,
		line_no int NOT NULL,
		location varchar(10) NULL,
		part_no varchar(30) NOT NULL,
		part_type char(1) NOT NULL,
		ordered decimal(20, 8) NOT NULL,
		shipped decimal(20, 8) NOT NULL,
		status char(1) NOT NULL,
		lb_tracking char(1) NULL,
		cr_ordered decimal(20, 8) NOT NULL,
		cr_shipped decimal(20, 8) NOT NULL,
		uom char(2) NULL,
		conv_factor decimal(20, 8) NOT NULL,
		cost decimal(20, 8) NOT NULL,
		labor decimal(20, 8) NOT NULL,
		direct_dolrs decimal(20, 8) NOT NULL,
		ovhd_dolrs decimal(20, 8) NOT NULL,
		util_dolrs decimal(20, 8) NOT NULL,
		note varchar(255) NULL,
		qty_per decimal(20, 8) NULL,
		qc_flag char(1) NOT NULL,
		qc_no int NOT NULL,
		description varchar(255) NULL,
		row_id int IDENTITY(1,1) NOT NULL)
	-- CVO_ord_list_kit
	CREATE TABLE #CVO_ord_list_kit(
		order_no int NOT NULL,
		order_ext int NOT NULL,
		line_no int NOT NULL,
		location varchar(10) NOT NULL,
		part_no varchar(30) NOT NULL,
		replaced varchar(1) NULL DEFAULT ('N'),
		new1 varchar(1) NULL DEFAULT ('N'),
		part_no_original varchar(30) NULL,
		row_id int IDENTITY(1,1) NOT NULL
) 
	-- Populate the temp tables
	SET	@last_new_ext = 0

	SELECT	TOP 1 @new_ext = new_ext
	FROM	#splits
	WHERE	new_ext <> 0
	AND		(price <> 0 OR part_type = 'POP') -- v11.3
	AND		new_ext > @last_new_ext
	AND		keep_ext = 0
	ORDER BY new_ext ASC 

	WHILE @@ROWCOUNT <> 0
	BEGIN
		-- Set flag
		SET	@has_split = 1

		-- orders_all
		INSERT INTO #orders_all  (order_no,ext,cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,date_entered,cust_po,who_entered,status,attention,phone,terms,routing,special_instr,
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
		SELECT	@order_no, @new_ext, cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,date_entered,cust_po,who_entered,'N',attention,phone,terms,routing,special_instr,
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

		-- cvo_orders_all
		INSERT INTO #CVO_orders_all(order_no,ext,add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
									commission_pct, stage_hold, prior_hold, credit_approved, invoice_note, commission_override, email_address, st_consolidate, upsell_flag, must_go_today)	-- v10.2 v11.8 v12.0 v12.1 v12.2 v12.4
		SELECT	@order_no, @new_ext, add_case,add_pattern,promo_id,promo_level,free_shipping,'Y',flag_print,buying_group, allocation_date, -- v10.7 Force split order
				commission_pct, stage_hold, prior_hold, credit_approved, invoice_note, commission_override, email_address, st_consolidate, upsell_flag, must_go_today -- v10.2 v11.8 v12.0 v12.1 v12.2 v12.4
		FROM	cvo_orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		-- ord_list for frames and suns
		INSERT	#ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
									temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
									ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
									oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,
									inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
									unpicked_dt)
		SELECT	@order_no, @new_ext, a.line_no,a.location,a.part_no,a.description,a.time_entered,b.quantity,a.shipped,a.price,a.price_type,a.note,'N',a.cost,a.who_entered,a.sales_comm,
									a.temp_price,a.temp_type,a.cr_ordered,a.cr_shipped,a.discount,a.uom,a.conv_factor,a.void,a.void_who,a.void_date,a.std_cost,a.cubic_feet,a.printed,a.lb_tracking,a.labor,a.direct_dolrs,
									a.ovhd_dolrs,a.util_dolrs,a.taxable,a.weight_ea,a.qc_flag,a.reason_code,a.qc_no,a.rejected,a.part_type,a.orig_part_no,a.back_ord_flag,a.gl_rev_acct,a.total_tax,a.tax_code,a.curr_price,
									a.oper_price,a.display_line,a.std_direct_dolrs,a.std_ovhd_dolrs,a.std_util_dolrs,a.reference_code,a.contract,a.agreement_id,a.ship_to,a.service_agreement_flag,
									a.inv_available_flag,a.create_po_flag,a.load_group_no,a.return_code,a.user_count,a.cust_po,a.organization_id,a.picked_dt,a.who_picked_id,a.printed_dt,a.who_unpicked_id,
									a.unpicked_dt
		FROM	ord_list a (NOLOCK)
		JOIN	#splits b
		ON		a.part_no = b.part_no
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		b.new_ext = @new_ext
		AND		(b.material <> 0 OR b.part_type = 'POP') -- v11.3
		ORDER BY a.line_no

		-- ord_list for cases, patterns etc
		INSERT	#ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered, ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
									temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
									ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
									oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,
									inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
									unpicked_dt)
		SELECT	@order_no, @new_ext, a.line_no,a.location,a.part_no,a.description,a.time_entered,b.quantity,a.shipped,a.price,a.price_type,a.note,'N',a.cost,a.who_entered,a.sales_comm,
									a.temp_price,a.temp_type,a.cr_ordered,a.cr_shipped,a.discount,a.uom,a.conv_factor,a.void,a.void_who,a.void_date,a.std_cost,a.cubic_feet,a.printed,a.lb_tracking,a.labor,a.direct_dolrs,
									a.ovhd_dolrs,a.util_dolrs,a.taxable,a.weight_ea,a.qc_flag,a.reason_code,a.qc_no,a.rejected,a.part_type,a.orig_part_no,a.back_ord_flag,a.gl_rev_acct,a.total_tax,a.tax_code,a.curr_price,
									a.oper_price,a.display_line,a.std_direct_dolrs,a.std_ovhd_dolrs,a.std_util_dolrs,a.reference_code,a.contract,a.agreement_id,a.ship_to,a.service_agreement_flag,
									a.inv_available_flag,a.create_po_flag,a.load_group_no,a.return_code,a.user_count,a.cust_po,a.organization_id,a.picked_dt,a.who_picked_id,a.printed_dt,a.who_unpicked_id,
									a.unpicked_dt
		FROM	ord_list a (NOLOCK)
		JOIN	#part_splits b
		ON		a.part_no = b.part_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		b.new_ext = @new_ext
		ORDER BY a.line_no
	

		-- cvo_ord_list for frames and suns
		INSERT INTO #CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
												is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame)  -- v11.0
		SELECT	@order_no, @new_ext, a.line_no,a.add_case,a.add_pattern,a.from_line_no,a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
												a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, a.free_frame  -- v11.0		
		FROM	cvo_ord_list a (NOLOCK)
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		b.new_ext = @new_ext
		AND		(b.material <> 0 OR b.part_type = 'POP') -- v11.3
		ORDER BY a.line_no

		-- cvo_ord_list for cases, patterns etc
		INSERT INTO #CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
												is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame)  -- v11.0
		SELECT	@order_no, @new_ext, a.line_no,a.add_case,a.add_pattern,a.from_line_no,a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
												a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, a.free_frame  -- v11.0		

		FROM	cvo_ord_list a (NOLOCK)
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		JOIN	#part_splits c
		ON		b.part_no = c.part_no
		WHERE	a.order_no = @order_no
		AND		c.new_ext = @new_ext
		ORDER BY a.line_no

		-- ord_list_kit
		INSERT INTO #ord_list_kit (order_no,order_ext,line_no,location,part_no,part_type,ordered,shipped,status,lb_tracking,cr_ordered,cr_shipped,uom,conv_factor,
											cost,labor,direct_dolrs,ovhd_dolrs,util_dolrs,note,qty_per,qc_flag,qc_no,description)
		SELECT	@order_no, @new_ext, a.line_no, a.location,a.part_no,a.part_type,b.quantity,a.shipped,'N',a.lb_tracking,a.cr_ordered,a.cr_shipped,a.uom,conv_factor,
					a.cost,a.labor,a.direct_dolrs,a.ovhd_dolrs,a.util_dolrs,a.note,a.qty_per,a.qc_flag,a.qc_no,a.description
		FROM	ord_list_kit a (NOLOCK)
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		b.new_ext = @new_ext
		AND		(b.material <> 0 OR b.part_type = 'POP') -- v11.3
		ORDER BY a.line_no

		-- CVO_ord_list_kit
		INSERT INTO #CVO_ord_list_kit(order_no,order_ext,line_no,location,part_no,replaced,new1,part_no_original)
		SELECT	@order_no,@new_ext,a.line_no,a.location,a.part_no,a.replaced,a.new1,a.part_no_original		
		FROM	cvo_ord_list_kit a (NOLOCK)
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		b.new_ext = @new_ext
		AND		(b.material <> 0 OR b.part_type = 'POP') -- v11.3
		ORDER BY a.line_no

		-- Soft Allocation hdr
		UPDATE	dbo.cvo_soft_alloc_next_no
		SET		next_no = next_no + 1

		SELECT	@new_soft_alloc_no = next_no
		FROM	dbo.cvo_soft_alloc_next_no

		INSERT	dbo.cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		VALUES (@new_soft_alloc_no, @order_no, @new_ext, @location, 0, 0)	

		-- v11.9 Start
		INSERT	cvo_soft_alloc_no_assign
		SELECT	@order_no, @new_ext, @new_soft_alloc_no
		-- v11.9 End	

		-- Soft Allocation det
		INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
														kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) -- v11.1
		SELECT	@new_soft_alloc_no, @order_no, @new_ext, a.line_no, a.location, a.part_no, b.quantity, 0, 0, 0, 0, 0, 0, 0, CASE WHEN b.has_case = 1 THEN 'Y' ELSE NULL END -- v11.1
		FROM	ord_list a (NOLOCK)
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		b.new_ext = @new_ext
		AND		(b.material <> 0 OR b.part_type = 'POP') -- v11.3
		ORDER BY a.line_no

		INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
														kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) -- v11.1
		SELECT	@new_soft_alloc_no, @order_no, @new_ext, a.line_no, a.location, a.part_no, c.quantity, 0, 0, 0, CASE WHEN b.part_type = 'CASE' THEN 1 ELSE 0 END, 
					CASE WHEN b.part_type = 'PATTERN' THEN 1 ELSE 0 END, 0, 0, CASE WHEN b.has_case = 1 THEN 'Y' ELSE NULL END -- v11.1
		FROM	ord_list a (NOLOCK)
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		JOIN	#part_splits c
		ON		b.part_no = c.part_no
		WHERE	a.order_no = @order_no
		AND		c.new_ext = @new_ext
		ORDER BY a.line_no

		-- v11.2 Start
		UPDATE	a
		SET		case_adjust = b.quantity
		FROM	cvo_soft_alloc_det a
		JOIN	#case_adjust b
		ON		a.order_ext = b.ext
		AND		a.line_no = b.line_no
		AND		a.part_no = b.part_no
		WHERE	soft_alloc_no = @new_soft_alloc_no


		-- v11.2 End


		SET	@last_new_ext = @new_ext

		SELECT	TOP 1 @new_ext = new_ext
		FROM	#splits
		WHERE	new_ext <> 0
		AND		(price <> 0 OR part_type = 'POP') -- v11.3
		AND		new_ext > @last_new_ext
		ORDER BY new_ext ASC 
	END

	IF @has_split = 1 -- Insert data into tables
	BEGIN

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
		SELECT	order_no, ext, cust_code,ship_to,req_ship_date,sch_ship_date,date_shipped,date_entered,cust_po,who_entered,status,attention,phone,terms,routing,special_instr,
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
		FROM	#orders_all (NOLOCK)

		IF (@@ERROR <> 0)
		BEGIN
			RETURN
		END

		-- v10.1 Start
		INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
		SELECT	GETDATE() , @user_id , 'BO' , 'ADM' , 'ORDER CREATION' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
				'STATUS:N/SPLIT ORDER'
		FROM	#orders_all a (NOLOCK)
		-- v10.1 End

		-- cvo_orders_all
		INSERT INTO CVO_orders_all(order_no,ext,add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
									commission_pct, stage_hold, prior_hold, credit_approved, invoice_note, commission_override, email_address, st_consolidate, upsell_flag, must_go_today) -- v10.2 v11.8 v12.0 v12.1 v12.2 v12.4
		SELECT	order_no, ext, add_case,add_pattern,promo_id,promo_level,free_shipping,split_order,flag_print,buying_group, allocation_date,
				commission_pct, stage_hold, prior_hold, credit_approved, invoice_note, commission_override, email_address, st_consolidate, upsell_flag, must_go_today -- v10.2 v11.8 v12.0 v12.1 v12.2 v12.4
		FROM	#cvo_orders_all (NOLOCK)

		IF (@@ERROR <> 0)
		BEGIN
			RETURN
		END

		-- ord_list for frames and suns
		INSERT	ord_list (order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,price_type,note,status,cost,who_entered,sales_comm,
									temp_price,temp_type,cr_ordered,cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,lb_tracking,labor,direct_dolrs,
									ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,curr_price,
									oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,reference_code,contract,agreement_id,ship_to,service_agreement_flag,
									inv_available_flag,create_po_flag,load_group_no,return_code,user_count,cust_po,organization_id,picked_dt,who_picked_id,printed_dt,who_unpicked_id,
									unpicked_dt)
		SELECT	a.order_no, a.order_ext, a.line_no,a.location,a.part_no,a.description,a.time_entered,a.ordered,a.shipped,a.price,a.price_type,a.note,a.status,a.cost,a.who_entered,a.sales_comm,
									a.temp_price,a.temp_type,a.cr_ordered,a.cr_shipped,a.discount,a.uom,a.conv_factor,a.void,a.void_who,a.void_date,a.std_cost,a.cubic_feet,a.printed,a.lb_tracking,a.labor,a.direct_dolrs,
									a.ovhd_dolrs,a.util_dolrs,a.taxable,a.weight_ea,a.qc_flag,a.reason_code,a.qc_no,a.rejected,a.part_type,a.orig_part_no,a.back_ord_flag,a.gl_rev_acct,a.total_tax,a.tax_code,a.curr_price,
									a.oper_price,a.display_line,a.std_direct_dolrs,a.std_ovhd_dolrs,a.std_util_dolrs,a.reference_code,a.contract,a.agreement_id,a.ship_to,a.service_agreement_flag,
									a.inv_available_flag,a.create_po_flag,a.load_group_no,a.return_code,a.user_count,a.cust_po,a.organization_id,a.picked_dt,a.who_picked_id,a.printed_dt,a.who_unpicked_id,
									a.unpicked_dt
		FROM	#ord_list a (NOLOCK)

		IF (@@ERROR <> 0)
		BEGIN
			RETURN
		END

		-- cvo_ord_list for frames and suns
		INSERT INTO CVO_ord_list(order_no,order_ext,line_no,add_case,add_pattern,from_line_no,is_case,is_pattern,add_polarized,is_polarized,is_pop_gif,
												is_amt_disc,amt_disc,is_customized,promo_item,list_price, free_frame)  -- v11.0
		SELECT	a.order_no, a.order_ext, a.line_no,a.add_case,a.add_pattern,a.from_line_no,a.is_case,a.is_pattern,a.add_polarized,a.is_polarized,a.is_pop_gif,
												a.is_amt_disc,a.amt_disc,a.is_customized,a.promo_item,a.list_price, a.free_frame  -- v11.0		
		FROM	#cvo_ord_list a (NOLOCK)

		IF (@@ERROR <> 0)
		BEGIN
			RETURN
		END

		-- ord_list_kit
		INSERT INTO ord_list_kit (order_no,order_ext,line_no,location,part_no,part_type,ordered,shipped,status,lb_tracking,cr_ordered,cr_shipped,uom,conv_factor,
											cost,labor,direct_dolrs,ovhd_dolrs,util_dolrs,note,qty_per,qc_flag,qc_no,description)
		SELECT	a.order_no, a.order_ext, a.line_no, a.location,a.part_no,a.part_type,a.ordered,a.shipped,a.status,a.lb_tracking,a.cr_ordered,a.cr_shipped,a.uom,conv_factor,
					a.cost,a.labor,a.direct_dolrs,a.ovhd_dolrs,a.util_dolrs,a.note,a.qty_per,a.qc_flag,a.qc_no,a.description
		FROM	#ord_list_kit a (NOLOCK)

		IF (@@ERROR <> 0)
		BEGIN
			RETURN
		END

		-- CVO_ord_list_kit
		INSERT INTO CVO_ord_list_kit(order_no,order_ext,line_no,location,part_no,replaced,new1,part_no_original)
		SELECT	a.order_no,a.order_ext,a.line_no,a.location,a.part_no,a.replaced,a.new1,a.part_no_original		
		FROM	#cvo_ord_list_kit a (NOLOCK)

		IF (@@ERROR <> 0)
		BEGIN
			RETURN
		END

		-- START v11.7
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
			c.order_ext,
			a.line_no,
			a.credit_amount,
			0
		FROM
			dbo.CVO_debit_promo_customer_det a (NOLOCK)
		INNER JOIN	
			dbo.ord_list b 
		ON	
			a.order_no = b.order_no
			AND a.ext = b.order_ext	 
			AND a.line_no = b.line_no
		INNER JOIN	
			#ord_list c
		ON	
			b.order_no = c.order_no
			AND b.line_no = c.line_no
		WHERE
			b.order_no = @order_no
			AND b.order_ext = @order_ext

		-- Tidy up any lines split across more than 1 extension
		EXEC cvo_debit_promo_check_for_split_lines_sp @order_no, @order_ext
		-- END v11.7

		-- void the original order
		-- v10.5 Start
		IF EXISTS(SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
		BEGIN
			EXEC dbo.cvo_UnAllocate_sp @order_no, @order_ext, 0, @user_id
		END
		-- v10.5 End

		UPDATE	dbo.orders_all
		SET		status = 'V', 
				void = 'V', 
				void_who = @user_id, 
				void_date = GETDATE(), 
				changed = 'Y' 
		WHERE	order_no = @order_no 
		AND		ext = @order_ext 
		AND		status <> 'V'

		IF (@@ERROR <> 0)
		BEGIN
			RETURN
		END

		-- v10.1 Start
		INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
		SELECT	GETDATE() , @user_id , 'BO' , 'ADM' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
				'STATUS:V/VOIDED'
		FROM	orders_all a (NOLOCK)
		WHERE	a.order_no = @order_no 
		AND		a.ext = @order_ext 
		-- v10.1 End


		UPDATE	a
		SET		status = 'V', 
				void = 'V', 
				void_who = @user_id, 
				void_date = GETDATE(), 
				changed = 'Y' 
		FROM	dbo.orders_all a
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext
		WHERE	a.ext <= @orig_ext
		AND		b.keep_ext = 0
		AND		a.status <> 'V'
	

		IF (@@ERROR <> 0)
		BEGIN
			RETURN
		END
		
		DELETE	a
		FROM	dbo.cvo_soft_alloc_hdr a
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		WHERE	a.order_ext <= @orig_ext
		AND		b.keep_ext = 0

		IF (@@ERROR <> 0)
		BEGIN
			RETURN
		END

		DELETE	a
		FROM	dbo.cvo_soft_alloc_det a
		JOIN	#splits b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		WHERE	a.order_ext <= @orig_ext
		AND		b.keep_ext = 0

		IF (@@ERROR <> 0)
		BEGIN
			RETURN
		END

		DELETE	dbo.cvo_soft_alloc_hdr WHERE soft_alloc_no = @soft_alloc_no
		DELETE	dbo.cvo_soft_alloc_det WHERE soft_alloc_no = @soft_alloc_no

		-- Update freight and tax
		SET	@last_new_ext = 0

		SELECT	TOP 1 @new_ext = new_ext
		FROM	#splits
		WHERE	new_ext <> 0
		AND		price <> 0
		AND		new_ext > @last_new_ext
		ORDER BY new_ext ASC 

		WHILE @@ROWCOUNT <> 0
		BEGIN

			-- START v11.7
			-- Update drawdown promo amount for customer
			EXEC dbo.cvo_debit_promo_apply_credit_for_splits_sp @order_no, @new_ext
			-- END v11.7

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
					-- START v11.6
					IF NOT EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @new_ext AND LEFT(user_category,2) IN ('ST','DO'))
					BEGIN

						EXEC dbo.CVO_GetFreight_tot_sp @order_no, @new_ext, @tot_ord_freight, @zip, @weight, @routing, @freight_allow_type, @order_value, @freight_amt OUTPUT

						UPDATE	orders_all
						SET		tot_ord_freight = @freight_amt
						WHERE	order_no = @order_no
						AND		ext = @new_ext
					END
					-- END v11.6
				END
				ELSE
				BEGIN
					UPDATE	orders
					SET		tot_ord_freight = @freight_amt,
							freight_allow_type = 'FRTOVRID'
					WHERE	order_no = @order_no
					AND		ext = @new_ext
				END
			END
			
			-- If its not been allocated then manually call the tax calculation
			-- v11.5 Start
			IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @new_ext AND LEFT(user_category,2) = 'RX')
			BEGIN		
				EXEC dbo.fs_calculate_oetax_wrap @order_no, @new_ext, 0, 1 -- v10.4 last param was -1
			END
			-- v11.5 End

			-- Manually call the update order totals
			EXEC dbo.fs_updordtots @order_no, @new_ext

			-- v12.3 Start
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
			-- v12.3 End

			-- v11.4 Start
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
			-- v11.4 End

			-- v12.3 Start
			UPDATE	a
			SET		polarized_part = b.polarized_part
			FROM	dbo.cvo_ord_list_fc a
			JOIN	#cvo_ord_list_fc b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
		
			DROP TABLE #cvo_ord_list_fc
			-- v12.3 End

			SET	@last_new_ext = @new_ext

			SELECT	TOP 1 @new_ext = new_ext
			FROM	#splits
			WHERE	new_ext <> 0
			AND		price <> 0
			AND		new_ext > @last_new_ext
			ORDER BY new_ext ASC 

		END
	END

	DROP TABLE #splits
	DROP TABLE #orders_all
	DROP TABLE #cvo_orders_all
	DROP TABLE #ord_list
	DROP TABLE #cvo_ord_list
	DROP TABLE #ord_list_kit
	DROP TABLE #cvo_ord_list_kit
	DROP TABLE #case_adjust -- v11.2

END
GO

GRANT EXECUTE ON  [dbo].[CVO_Split_dollar_orders_sp] TO [public]
GO
