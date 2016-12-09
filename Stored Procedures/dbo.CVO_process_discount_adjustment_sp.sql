SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 CT 01/07/2013 - Created
v1.1 CB 31/10/2016 - #1616 Hold Processing

*/
CREATE PROCEDURE [dbo].[CVO_process_discount_adjustment_sp]	
AS
BEGIN
	DECLARE @rec_id			INT,
			@cust_code		VARCHAR(10),
			@order_no		INT,
			@ext			INT,
			@line_no		INT,
			@std_price		DECIMAL(20,8),
			@promo_disc		DECIMAL(20,8),
			@packed_credit	DECIMAL(20,8),
			@status			CHAR(1),
			@error_no		SMALLINT,
			@error_desc		VARCHAR(1000),
			@juliandate		INT,
			@retval			INT,
			@prior_hold		VARCHAR(10),
			@promo_id		VARCHAR(20),
			@promo_level	VARCHAR(30),
			@order_type		VARCHAR(10), 
			@ship_to		VARCHAR(10),
			@trx_ctrl_num	VARCHAR(16)

	SET NOCOUNT ON

	-- Loop through all unpacked order lines
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext,
			@line_no = line_no,
			@std_price = std_price,
			@promo_disc = ISNULL(promo_disc,0)
		FROM
			dbo.CVO_discount_adjustment_results (NOLOCK)
		WHERE
			process = 1
			AND [status] < 'R'
			AND rec_id > @rec_id
			AND spid = @@SPID
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK
	
		-- Update ord_list record
		UPDATE
			dbo.ord_list
		SET
			price = @std_price,
			temp_price = @std_price, 
			curr_price = @std_price, 
			oper_price = @std_price,
			discount = @promo_disc
		WHERE
			order_no = @order_no
			AND order_ext = @ext
			AND line_no = @line_no
			
		-- Update cvo_ord_list record
		UPDATE
			dbo.cvo_ord_list
		SET
			amt_disc = CASE @promo_disc WHEN 0 THEN 0 ELSE @std_price * (@promo_disc/100) END 
		WHERE
			order_no = @order_no
			AND order_ext = @ext
			AND line_no = @line_no

		-- Write audit record
		INSERT INTO CVO_discount_adjustment_audit(
			adjustment_date,
			[user_id],
			date_from,
			date_to,
			price_class,
			order_no,
			ext,
			line_no,
			[status],
			part_no,
			original_price,
			original_discount,
			new_price,
			new_discount,
			[action])
		SELECT
			GETDATE(),
			SUSER_SNAME(),
			date_from,
			date_to,
			UPPER(price_class),
			order_no,
			ext,
			line_no,
			[status],
			part_no,
			orig_price,
			discount,
			std_price,
			promo_disc,
			'OC'
		FROM
			dbo.CVO_discount_adjustment_results (NOLOCK)
		WHERE
			rec_id = @rec_id
	END

	-- Loop though unpacked orders and recalculate order totals
	SET @order_no = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@order_no = order_no
		FROM	
			dbo.CVO_discount_adjustment_results (NOLOCK)
		WHERE
			process = 1
			AND [status] < 'R'
			AND order_no > @order_no
			AND spid = @@SPID
		ORDER BY
			order_no

		IF @@ROWCOUNT = 0
			BREAK

		-- Loop through extensions
		SET @ext = -1
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@ext = ext,
				@status = [status],
				@cust_code = cust_code,
				@promo_id = promo_id,
				@promo_level = promo_level
			FROM	
				dbo.CVO_discount_adjustment_results (NOLOCK)
			WHERE
				process = 1
				AND [status] < 'R'
				AND order_no = @order_no
				AND ext > @ext
				AND spid = @@SPID
			ORDER BY
				ext

			IF @@ROWCOUNT = 0
				BREAK

			-- Get order details
			SELECT
				@order_type = user_category,
				@ship_to = ship_to
			FROM
				dbo.orders_all (NOLOCK)
			WHERE
				order_no = @order_no
				AND ext = @ext

			-- Refresh order totals
			--EXEC dbo.fs_calculate_oetax_wrap @ord = @order_no, @ext = @ext, @batch_call = -1 
			--EXEC dbo.fs_calculate_oetax_wrap @ord = @order_no, @ext = @ext, @batch_call = 1
			EXEC dbo.fs_calculate_oetax_wrap @order_no, @ext, 0, 1
			EXEC fs_updordtots @ordno = @order_no, @ordext = @ext

			

			-- Check if order now applies for a subscription promo
			IF ISNULL(@promo_id,'') = '' AND @status <= 'N'
			BEGIN
				EXEC CVO_check_for_subscription_promo_wrap_sp	@customer_code	= @cust_code, 
																@order_no = @order_no, 
																@ext = @ext, 
																@order_type = @order_type, 
																@ship_to = @ship_to,
																@promo_id = @promo_id OUTPUT,
																@promo_level = @promo_level OUTPUT


				IF ISNULL(@promo_id,'') <> '' AND ISNULL(@promo_level,'') <> ''
				BEGIN
					-- Apply promo
					EXEC dbo.CVO_apply_promo_sp	@order_no, @ext, @promo_id, @promo_level
					
					IF @@ERROR <> 0
					BEGIN
						SELECT -1, 'Error - ' + CAST(@@ERROR AS VARCHAR(10))
						RETURN
					END

					-- Place on promo hold
					IF @status <> 'N'
					BEGIN
						-- If already on hold then store the hold reason
						
						-- v1.1 Start
						-- Push existing hold back
						INSERT	cvo_so_holds
						SELECT	order_no, ext, ISNULL(hold_reason,''),
								dbo.f_get_hold_priority(ISNULL(hold_reason,''),''),
								SUSER_NAME(),
								GETDATE()
						FROM	orders_all (NOLOCK)
						WHERE	order_no = @order_no
						AND		ext = @ext
						AND		ISNULL(hold_reason,'') > ''

						--UPDATE
						--	dbo.cvo_orders_all 
						--SET
						--	prior_hold = CASE ISNULL(prior_hold,'') WHEN '' THEN 'PROMOHLD' ELSE prior_hold END
						--WHERE 
						--	order_no = @order_no
						--	AND ext = @ext

						UPDATE	dbo.orders_all
						SET		[status] = 'A',
								hold_reason = 'PROMOHLD'
						WHERE	order_no = @order_no
						AND		ext = @ext

						INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data )   
						SELECT GETDATE() , suser_name() , 'BO' , 'DISCADJ' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,  
						'STATUS:A/USER HOLD; HOLD REASON: PROMOHLD'
						FROM 
							dbo.orders_all a (NOLOCK)  
						JOIN 
							dbo.cvo_orders_all b (NOLOCK)  
						ON  
							a.order_no = b.order_no  
							AND a.ext = b.ext  
						WHERE 
							a.order_no = @order_no      
							AND a.ext = @ext 
						-- v1.1 End
					END
					ELSE 
					BEGIN
						UPDATE
							dbo.orders_all
						SET
							[status] = 'A',
							hold_reason = 'PROMOHLD'
						WHERE
							order_no = @order_no
							AND ext = @ext

						-- Write log
						INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data )   
						SELECT GETDATE() , suser_name() , 'BO' , 'DISCADJ' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,  
						'STATUS:A/USER HOLD; HOLD REASON: PROMOHLD'
						FROM 
							dbo.orders_all a (NOLOCK)  
						JOIN 
							dbo.cvo_orders_all b (NOLOCK)  
						ON  
							a.order_no = b.order_no  
							AND a.ext = b.ext  
						WHERE 
							a.order_no = @order_no      
							AND a.ext = @ext 
  

					END
				
					-- Refresh order totals
					EXEC dbo.fs_calculate_oetax_wrap @order_no, @ext, 0, 1
					EXEC fs_updordtots @ordno = @order_no, @ordext = @ext
						
				END
			END

			-- If on credit hold, check if the order can now be taken off
			IF @status = 'C'
			BEGIN
				-- Check for credit hold
				SELECT @juliandate = datediff(day, '01/01/1900', getdate())+693596
				EXEC @retval = dbo.cvo_fs_archklmt_sp_wrap @customer_code = @cust_code, @date_entered = @juliandate, @ordno = @order_no, @ordext = @ext

				-- No longer on credit hold
				IF @retval = 0
				BEGIN
					-- Write log
					INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data )   
					SELECT GETDATE() , suser_name() , 'BO' , 'DISCADJ' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,  
					'STATUS:N/RELEASE CREDIT HOLD'
					FROM 
						dbo.orders_all a (NOLOCK)  
					JOIN 
						dbo.cvo_orders_all b (NOLOCK)  
					ON  
						a.order_no = b.order_no  
						AND a.ext = b.ext  
					WHERE 
						a.order_no = @order_no      
						AND a.ext = @ext 

					-- Is there a prior hold?
					-- v1.1 Start
					SET @prior_hold = ''
					SELECT	@prior_hold = hold_reason
					FROM	cvo_next_so_hold_vw (NOLOCK)
					WHERE	order_no = @order_no
					AND		order_ext = @ext

					--SELECT 
					--	@prior_hold = ISNULL(prior_hold,'')
					--FROM 
					--	dbo.cvo_orders_all (NOLOCK)
					--WHERE 
					--	order_no = @order_no
					--	AND ext = @ext
					-- v1.1 End

					IF ISNULL(@prior_hold,'') <> ''
					BEGIN
						SET @status = 'A'
					END
					ELSE
					BEGIN
						SET @status = 'N'	
					END
					
					-- Update order status
					UPDATE
						dbo.orders_all
					SET
						[status] = @status,
						hold_reason = CASE @status WHEN 'A' THEN @prior_hold ELSE '' END
					WHERE
						order_no = @order_no
						AND ext = @ext
								
					IF ISNULL(@prior_hold,'') <> ''
					BEGIN

						-- Write log
						INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data )   
						SELECT GETDATE() , suser_name() , 'BO' , 'DISCADJ' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,  
						'STATUS:A/USER HOLD; HOLD REASON:' + LTRIM(RTRIM(@prior_hold))  
						FROM 
							dbo.orders_all a (NOLOCK)  
						JOIN 
							dbo.cvo_orders_all b (NOLOCK)  
						ON  
							a.order_no = b.order_no  
							AND a.ext = b.ext  
						WHERE 
							a.order_no = @order_no      
							AND a.ext = @ext 
  
						-- Remove prior hold information
						-- v1.1 Start
						DELETE	cvo_so_holds
						WHERE	order_no = @order_no
						AND		order_ext = @ext
						AND		hold_reason = @prior_hold

						--UPDATE
						--	dbo.cvo_orders_all 
						--SET
						--	prior_hold = NULL
						--WHERE 
						--	order_no = @order_no
						--	AND ext = @ext
						-- v1.1 End
					END
					
				END

			END

		END

	END

	-- Process packed orders
	SELECT 
		@cust_code = cust_code,
		@packed_credit = SUM(price_diff) 
	FROM 
		dbo.CVO_discount_adjustment_results (NOLOCK)
	WHERE 
		process = 1 
		AND [status] >= 'R'	
		AND spid = @@SPID
		AND ISNULL(price_diff,0) <> 0
	GROUP BY
		cust_code

	-- Create credit memo
	IF ISNULL(@packed_credit,0) > 0
	BEGIN
		SET @error_no = 0
		EXEC CVO_discount_adjustment_credit_memo_sp	@cust_code, @packed_credit, @error_no OUTPUT, @error_desc OUTPUT, @trx_ctrl_num OUTPUT

		IF @@ERROR <> 0 
		BEGIN
			SELECT 1, @error_desc
			RETURN
		END
	END

	-- Write audit records
	INSERT INTO CVO_discount_adjustment_audit(
		adjustment_date,
		[user_id],
		date_from,
		date_to,
		price_class,
		order_no,
		ext,
		line_no,
		[status],
		part_no,
		original_price,
		original_discount,
		new_price,
		new_discount,
		[action],
		trx_ctrl_num)
	SELECT
		GETDATE(),
		SUSER_SNAME(),
		date_from,
		date_to,
		UPPER(price_class),
		order_no,
		ext,
		line_no,
		[status],
		part_no,
		orig_price,
		discount,
		std_price,
		promo_disc,
		'CM',
		@trx_ctrl_num
	FROM
		dbo.CVO_discount_adjustment_results (NOLOCK)
	WHERE
		process = 1 
		AND [status] >= 'R'	
		AND spid = @@SPID
		AND ISNULL(price_diff,0) <> 0

	SELECT 0,'Complete'

END
GO
GRANT EXECUTE ON  [dbo].[CVO_process_discount_adjustment_sp] TO [public]
GO
