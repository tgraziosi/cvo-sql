SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_add_soft_alloc_line_sp]	@soft_alloc_no	int,
											@order_no		int,
											@order_ext		int,
											@line_no		int,
											@location		varchar(10),
											@part_no		varchar(30),
											@quantity		decimal(20,8),
											@kit_part		smallint,
											@add_case		smallint,
											@add_pattern	smallint,
											@deleted		smallint,
											@customer_code	varchar(10),
											@ship_to		varchar(10),
											@inv_avail		smallint = NULL -- v1.4	
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- v1.1
	IF @soft_alloc_no = -99
		RETURN

	-- declarations
	DECLARE	@case_part		varchar(30),
			@pattern_part	varchar(30),
			@change			smallint,
			@is_case		smallint,
			@is_pattern		smallint,
			@original_qty	decimal(20,8),
			@original_part	varchar(30),
			@existing_line	int,
			@case_qty		decimal(20,8),	-- v1.8
			@row_id			INT				-- v2.2

	-- If quantity entered is zero then treat as delete	
	IF @quantity = 0
		SET	@deleted = 1

	-- Initialize the change flag
	SET @change = 0

	-- check if this order has been hard allocated
	IF (@order_no != 0)
	BEGIN
		IF (EXISTS(SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')) 
			OR (EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status IN (-1,-2)))
			OR (EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND status IN (-1,-2)))
			OR (EXISTS(SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status = 'P')) -- v3.8
			SET @change = 1
	END

	-- check for a header soft alloc record, if it does not exist then create it with a status of 1 so it does not get allocated yet
	-- if this is a new record then the soft alloc no is sent in otherwise it will be the order no and ext
	-- if the status is -1 then it is currently being processed by the hard allocation routine
	IF NOT EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status > -1)
	BEGIN
		INSERT	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		VALUES (@soft_alloc_no, @order_no, @order_ext, @location, 0, 1)
	END

	-- This is an add or update
	IF (@deleted = 0) -- Add or update
	BEGIN
		-- if a kit part is being added because of a custom frame then do not need to check for cases and patterns
		IF (@kit_part = 0) -- Non Kit part
		BEGIN
			-- If the line number passed in is -1 then its a promo part being added
			IF (@line_no = -1) -- Promo part
			BEGIN 
				IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no AND order_ext = @order_ext 
							AND	part_no = @part_no AND status > -1)
				BEGIN
					INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
														kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
					VALUES (@soft_alloc_no, @order_no, @order_ext, @line_no, @location, @part_no, @quantity, @kit_part, @change, @deleted, 0, 0, 1, 1)			
				END
				RETURN
			END

			IF (@line_no = -2) -- Pop gift part
			BEGIN 
				IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no AND order_ext = @order_ext 
							AND	part_no = @part_no AND status > -1)
				BEGIN
					INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
														kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
					VALUES (@soft_alloc_no, @order_no, @order_ext, @line_no, @location, @part_no, @quantity, @kit_part, @change, @deleted, 0, 0, 2, 1)			
				END
				RETURN
			END


			IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no AND order_ext = @order_ext 
						AND line_no = @line_no AND status > -1) -- Existing record
			BEGIN
				SELECT	@is_case = is_case,
						@is_pattern = is_pattern,
						@original_qty = quantity,
						@original_part = part_no
				FROM	dbo.cvo_soft_alloc_det (NOLOCK) 
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		line_no = @line_no
				AND		status > -1

				IF (@original_part <> @part_no) -- The user has changed the part
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND part_no = @original_part)
					BEGIN

						-- v2.2							
						SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
									AND order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND status > -1


						UPDATE	dbo.cvo_soft_alloc_det  WITH (ROWLOCK)
						SET		part_no = @part_no,
								quantity = @quantity,
								deleted = 0, -- v1.3					
								inv_avail = @inv_avail, -- v1.4
								change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
						WHERE	soft_alloc_no = @soft_alloc_no
						AND		order_no = @order_no 
						AND		order_ext = @order_ext 
						AND		line_no = @line_no
						AND		status > -1	
						AND		row_id = @row_id	-- v2.2	

						-- v2.8 Start
						IF (@add_case = 1) -- Update the case 
						BEGIN
							-- Find the case for the original part
							SELECT	@case_part = ISNULL(a.part_no,'')
							FROM	dbo.inv_master_add a (NOLOCK)
							JOIN	dbo.inv_list b (NOLOCK)
							ON		a.part_no = b.part_no
							JOIN	dbo.inv_master_add c (NOLOCK)
							ON		a.part_no = c.field_1
							WHERE	c.part_no = @original_part
							AND		b.location = @location
							AND		b.void = 'N'

							-- Does the case part exist
							IF (@case_part != '')
							BEGIN 
								-- if the case already exist then update else insert
								IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no AND order_ext = @order_ext 
												AND part_no = @case_part AND is_case = 1 AND status > -1)
								BEGIN						
									SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
												AND order_no = @order_no AND order_ext = @order_ext AND part_no = @case_part AND status > -1 AND is_case = 1

									UPDATE	dbo.cvo_soft_alloc_det  WITH (ROWLOCK)
									SET		quantity = quantity - @quantity,
											change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
									WHERE	soft_alloc_no = @soft_alloc_no
									AND		order_no = @order_no 
									AND		order_ext = @order_ext 
									AND		part_no = @case_part
									AND		is_case = 1
									AND		status > -1
									AND		row_id = @row_id	-- v2.2		

									UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
									SET		deleted = 1
									WHERE	row_id = @row_id
									AND		quantity <= 0
								END
							END
						END

						IF (@add_pattern = 1) -- Need to check for patterns - normally only on insert but the user may have changed the part
						BEGIN
							-- Find the pattern for this part
							SELECT	@pattern_part = ISNULL(a.part_no,'')
							FROM	dbo.inv_master_add a (NOLOCK)
							JOIN	dbo.inv_list b (NOLOCK)
							ON		a.part_no = b.part_no
							JOIN	dbo.inv_master_add c (NOLOCK)
							ON		a.part_no = c.field_4
							WHERE	c.part_no = @original_part
							AND		b.location = @location
							AND		b.void = 'N'

							-- Does the pattern part exist
							IF (@pattern_part != '')
							BEGIN
								-- Pattern Tracking
								IF NOT EXISTS (SELECT 1 FROM cvo_pattern_tracking (NOLOCK) WHERE customer_code = @customer_code
												AND ship_to = @ship_to AND pattern = @pattern_part)
								BEGIN
									IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no 
												AND order_ext = @order_ext AND part_no = @pattern_part AND is_pattern = 1 AND status > -1)
									BEGIN
									SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
												AND order_no = @order_no AND order_ext = @order_ext AND part_no = @pattern_part AND status > -1 AND is_pattern = 1

										UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
										SET		quantity = quantity - @quantity,
												change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
										WHERE	soft_alloc_no = @soft_alloc_no
										AND		order_no = @order_no 
										AND		order_ext = @order_ext 
										AND		part_no = @pattern_part
										AND		is_pattern = 1
										AND		status > -1
										AND		row_id = @row_id	

										UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
										SET		deleted = 1
										WHERE	row_id = @row_id
										AND		quantity <= 0

									END
								END
							END					
						END
						-- v2.8 End
					END
					ELSE
					BEGIN
						INSERT	dbo.cvo_soft_alloc_det  WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
															kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) -- v3.1
						VALUES (@soft_alloc_no, @order_no, @order_ext, @line_no, @location, @part_no, @quantity, @kit_part, @change, @deleted, 0, 0, 0, 1, CASE WHEN @add_case = 1 THEN 'Y' ELSE NULL END) -- v3.1
					END

				END -- End original_part <> part_no

				IF (@is_case = 0 AND @is_pattern = 0) -- This is a part line
				BEGIN

					
					-- v1.6 Start
					-- START v1.9
					/*IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no <> @soft_alloc_no AND order_no = @order_no 
									AND order_ext = @order_ext AND line_no = @line_no AND part_no = @part_no AND quantity = @quantity AND status IN (-1,-2))*/
					IF EXISTS (SELECT 1 FROM dbo.ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND part_no = @part_no 
								AND ordered = @quantity)
					AND EXISTS (SELECT SUM(qty) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND part_no = @part_no 
									HAVING SUM(qty) = @quantity)
--						AND EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND part_no = @part_no)
					-- END v1.9
					BEGIN

						SELECT	@original_qty = 0

						SELECT	@original_qty = ordered
						FROM	dbo.ord_list (NOLOCK)
						WHERE	order_no = @order_no 
						AND		order_ext = @order_ext 
						AND		line_no = @line_no
						AND		part_no = @part_no

						IF EXISTS(SELECT 1 FROM cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no AND order_ext = @order_ext 
												AND line_no = @line_no AND part_no = @part_no AND status > -1)
						BEGIN
							SELECT	@original_qty = quantity
							FROM	dbo.cvo_soft_alloc_det (NOLOCK)
							WHERE	soft_alloc_no = @soft_alloc_no
							AND		order_no = @order_no 
							AND		order_ext = @order_ext 
							AND		line_no = @line_no
							AND		part_no = @part_no
							AND		status > -1
						END

						IF (@original_qty IS NULL)
							SET @original_qty = 0


						-- Remove the record
						DELETE	dbo.cvo_soft_alloc_det 
						WHERE	soft_alloc_no = @soft_alloc_no 
						AND		order_no = @order_no 
						AND		order_ext = @order_ext
						AND		line_no = @line_no
						AND		part_no = @part_no	
						AND		status = 1

						IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no)
							DELETE dbo.cvo_soft_alloc_hdr WHERE soft_alloc_no = @soft_alloc_no

						-- START v1.8
						IF (@add_case = 1) -- Update the case 
						BEGIN
							-- Find the case for this part
							SELECT	@case_part = ISNULL(a.part_no,'')
							FROM	dbo.inv_master_add a (NOLOCK)
							JOIN	dbo.inv_list b (NOLOCK)
							ON		a.part_no = b.part_no
							JOIN	dbo.inv_master_add c (NOLOCK)
							ON		a.part_no = c.field_1
							WHERE	c.part_no = @part_no
							AND		b.location = @location
							AND		b.void = 'N'

							-- Does the case part exist
							IF (@case_part != '')
							BEGIN 
								-- if the case already exist then update else insert
								IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no AND order_ext = @order_ext 
												AND part_no = @case_part AND is_case = 1 AND status > -1)
								BEGIN
									
									-- Get case line number
									SELECT
										@existing_line = line_no	
									FROM 
										dbo.cvo_soft_alloc_det (NOLOCK)
									WHERE 
										soft_alloc_no = @soft_alloc_no 
										AND order_no = @order_no 
										AND order_ext = @order_ext 
										AND part_no = @case_part 
										AND	location = @location
										AND is_case = 1 
										AND status > -1
									
									SET @case_qty = dbo.f_calculate_case_sa_qty (@order_no,@order_ext,@soft_alloc_no,@case_part,@part_no,@line_no,@original_qty,@quantity)

									-- Is the new qty the same as the ord_list qty, if so delete
									IF EXISTS (SELECT 1 FROM dbo.ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @existing_line 
												AND part_no = @case_part AND ordered = @case_qty)
										AND EXISTS (SELECT SUM(qty) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @case_part
														AND line_no = @existing_line HAVING SUM(qty) = @quantity)	
									BEGIN
										-- Remove any records that are zero quantity
										DELETE	dbo.cvo_soft_alloc_det
										WHERE	soft_alloc_no = @soft_alloc_no
										AND		order_no = @order_no 
										AND		order_ext = @order_ext 
										AND		part_no = @case_part
										AND		line_no = @existing_line
										AND		is_case = 1
										AND		status > -1
									END
									ELSE
									BEGIN
										-- v2.2							
										SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK)WHERE soft_alloc_no = @soft_alloc_no
													AND order_no = @order_no AND order_ext = @order_ext AND part_no = @case_part AND status > -1 AND is_case = 1

										UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
										SET		quantity = ISNULL(@case_qty,0), -- v3.3
												change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
										WHERE	soft_alloc_no = @soft_alloc_no
										AND		order_no = @order_no 
										AND		order_ext = @order_ext 
										AND		part_no = @case_part
										AND		is_case = 1
										AND		status > -1
										AND		row_id = @row_id	-- v2.2
									END
								END
								ELSE
								BEGIN
									SET @existing_line = 0

									SELECT	@existing_line = line_no
									FROM	dbo.cvo_soft_alloc_det (NOLOCK)
									WHERE	order_no = @order_no
									AND		order_ext = @order_ext
									AND		location = @location
									AND		part_no = @case_part
									AND		is_case = 1
									AND		status IN (-1,-2)

									IF ISNULL(@existing_line,0) = 0
									BEGIN  
										SELECT	@existing_line = line_no
										FROM	dbo.ord_list (NOLOCK)
										WHERE	order_no = @order_no
										AND		order_ext = @order_ext
										AND		location = @location
										AND		part_no = @case_part
									END

									IF @existing_line IS NULL
										SET @existing_line = 0

									-- Calculate qty
									SET @case_qty = dbo.f_calculate_case_sa_qty (@order_no,@order_ext,@soft_alloc_no,@case_part,@part_no,@line_no,@original_qty,@quantity)

									INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
																		kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
									VALUES (@soft_alloc_no, @order_no, @order_ext, @existing_line, @location, @case_part, ISNULL(@case_qty,0), @kit_part, @change, @deleted, 1, 0, 0, 1)  -- v3.3
									-- END v1.7
								END
							END
						END
						-- END v1.8

						RETURN								
					END
					-- v1.6 End
					-- v2.2							
					SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
								AND order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND part_no = @part_no AND status > -1

					-- v2.7 Start
					IF (@original_part <> @part_no)
					BEGIN	
							SET @original_qty = 0
					END
					ELSE
					BEGIN
						SELECT	@original_qty = quantity
						FROM	dbo.cvo_soft_alloc_det (NOLOCK)
						WHERE	soft_alloc_no = @soft_alloc_no
						AND		order_no = @order_no 
						AND		order_ext = @order_ext 
						AND		line_no = @line_no
						AND		part_no = @part_no
						AND		status > -1
						AND		row_id = @row_id
					END
					-- v2.7 End

					UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
					SET		quantity = @quantity,
							deleted = 0, -- v1.2
							inv_avail = @inv_avail, -- v1.4
							change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
					WHERE	soft_alloc_no = @soft_alloc_no
					AND		order_no = @order_no 
					AND		order_ext = @order_ext 
					AND		line_no = @line_no
					AND		part_no = @part_no
					AND		status > -1
					AND		row_id = @row_id	-- v2.2	
					

					IF (@add_case = 1) -- Increment the cases 
					BEGIN
						-- Find the case for this part
						SELECT	@case_part = ISNULL(a.part_no,'')
						FROM	dbo.inv_master_add a (NOLOCK)
						JOIN	dbo.inv_list b (NOLOCK)
						ON		a.part_no = b.part_no
						JOIN	dbo.inv_master_add c (NOLOCK)
						ON		a.part_no = c.field_1
						WHERE	c.part_no = @part_no
						AND		b.location = @location
						AND		b.void = 'N'

						-- Does the case part exist
						IF (@case_part != '')
						BEGIN 
							-- if the case already exist then update else insert
							IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no AND order_ext = @order_ext 
											AND part_no = @case_part AND is_case = 1 AND status > -1 )
							BEGIN
								-- v2.2							
								SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
										AND order_no = @order_no AND order_ext = @order_ext AND part_no = @case_part AND status > -1 AND is_case = 1

								SET @case_qty = dbo.f_calculate_case_sa_qty (@order_no,@order_ext,@soft_alloc_no,@case_part,@part_no,@line_no,@original_qty,@quantity)
								
								SET @existing_line = 0

								SELECT	@existing_line = line_no
								FROM	dbo.ord_list (NOLOCK)
								WHERE	order_no = @order_no
								AND		order_ext = @order_ext
								AND		location = @location
								AND		part_no = @part_no
								AND		line_no = @line_no
						
								UPDATE	dbo.cvo_soft_alloc_det  WITH (ROWLOCK)
								SET		-- v3.7 quantity = ISNULL(@case_qty,0),  -- v3.3 --quantity + @quantity, --(@quantity - @original_qty),
										quantity = CASE WHEN ISNULL(@case_qty,0) < 0 THEN @quantity ELSE ISNULL(@case_qty,0) END,  -- v3.3 --quantity + @quantity, --(@quantity - @original_qty), -- v3.7
										deleted = 0, -- v2.0
										change = CASE change WHEN 2 THEN 1 ELSE @change END, -- v2.2 v3.0
										case_adjust = CASE WHEN ISNULL(@case_qty,0) < 0 THEN 0 ELSE case_adjust END -- v3.7
								WHERE	soft_alloc_no = @soft_alloc_no
								AND		order_no = @order_no 
								AND		order_ext = @order_ext 
								AND		part_no = @case_part
								AND		is_case = 1
								AND		status > -1
								AND		row_id = @row_id	-- v2.2
							END
							ELSE
							BEGIN
								SET @existing_line = 0

								SELECT	@existing_line = line_no
								FROM	dbo.cvo_soft_alloc_det (NOLOCK)
								WHERE	order_no = @order_no
								AND		order_ext = @order_ext
								AND		location = @location
								AND		part_no = @case_part
								AND		is_case = 1
								AND		status IN (-1,-2)

								IF ISNULL(@existing_line,0) = 0
								BEGIN  
									SELECT	@existing_line = line_no
									FROM	dbo.ord_list (NOLOCK)
									WHERE	order_no = @order_no
									AND		order_ext = @order_ext
									AND		location = @location
									AND		part_no = @case_part
								END

								IF @existing_line IS NULL
									SET @existing_line = 0

								-- START v1.7
								-- Calculate qty
								SET @case_qty = dbo.f_calculate_case_sa_qty (@order_no,@order_ext,@soft_alloc_no,@case_part,@part_no,@line_no,@original_qty,@quantity)


								INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
																	kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
								VALUES (@soft_alloc_no, @order_no, @order_ext, @existing_line, @location, @case_part, ISNULL(@case_qty,0), @kit_part, @change, @deleted, 1, 0, 0, 1)  -- v3.3
								-- END v1.7
							END
						END
					END

					IF (@add_pattern = 1) -- Need to check for patterns - normally only on insert but the user may have changed the part
					BEGIN
						-- Find the pattern for this part
						SELECT	@pattern_part = ISNULL(a.part_no,'')
						FROM	dbo.inv_master_add a (NOLOCK)
						JOIN	dbo.inv_list b (NOLOCK)
						ON		a.part_no = b.part_no
						JOIN	dbo.inv_master_add c (NOLOCK)
						ON		a.part_no = c.field_4
						WHERE	c.part_no = @part_no
						AND		b.location = @location
						AND		b.void = 'N'

						-- Does the pattern part exist
						IF (@pattern_part != '')
						BEGIN
							-- Pattern Tracking
							IF NOT EXISTS (SELECT 1 FROM cvo_pattern_tracking (NOLOCK) WHERE customer_code = @customer_code
											AND ship_to = @ship_to AND pattern = @pattern_part)
							BEGIN
								IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no 
											AND order_ext = @order_ext AND part_no = @pattern_part AND is_pattern = 1 AND status > -1)
								BEGIN
									INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
																	kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
									VALUES (@soft_alloc_no, @order_no, @order_ext, 0, @location, @pattern_part, 1, @kit_part, @change, @deleted, 0, 1, 0, 1)
								END
							END
						END					
					END
				END

				IF (@is_case = 1 OR @is_pattern = 1) -- This is a case or pattern line - user has manually updated the quantity	
				BEGIN
					-- v2.2							
					SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
								AND order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND status > -1

					-- v3.2
					IF (@is_case = 1)
						SET @case_qty = dbo.f_calculate_case_sa_qty (@order_no,@order_ext,@soft_alloc_no,@part_no,'',@line_no,0,0)
				
					UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
					SET		quantity = @quantity,
							case_adjust = ISNULL(case_adjust,0) + ISNULL(CASE WHEN @is_case = 1 THEN @quantity - @case_qty ELSE 0 END,0), -- v3.2  -- v3.3
							inv_avail = @inv_avail, -- v1.4
							change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
					WHERE	soft_alloc_no = @soft_alloc_no
					AND		order_no = @order_no 
					AND		order_ext = @order_ext 
					AND		line_no = @line_no
					AND		status > -1
					AND		row_id = @row_id	-- v2.2
				END
			END
			ELSE
			BEGIN -- New record
				-- Add the soft allocation record for the line added
				SELECT	@original_qty = 0

				SELECT	@original_qty = ordered
				FROM	dbo.ord_list (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		line_no = @line_no
				AND		part_no = @part_no

				IF (@original_qty IS NULL)
					SET @original_qty = 0

				-- v3.2 Start
				SET @is_case = 0
				SET @is_pattern = 0
				IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @part_no AND type_code = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE'))
					SET @is_case = 1
				ELSE
				BEGIN
					IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @part_no AND type_code = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_PATTERN'))
						SET @is_pattern = 1
				END

				INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
													kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, inv_avail, add_case_flag) -- v3.1
				VALUES (@soft_alloc_no, @order_no, @order_ext, @line_no, @location, @part_no, @quantity, @kit_part, @change, @deleted, @is_case, @is_pattern, 0, 1, @inv_avail, CASE WHEN @add_case = 1 THEN 'Y' ELSE NULL END) -- v3.1
				-- v3.2 End

				-- Need to add the related parts - cases and patterns - note polarized will be added directly to the client 
				-- These are not consolidated until order save
				IF (@add_case = 1)
				BEGIN
					-- Find the case for this part
					SELECT	@case_part = ISNULL(a.part_no,'')
					FROM	dbo.inv_master_add a (NOLOCK)
					JOIN	dbo.inv_list b (NOLOCK)
					ON		a.part_no = b.part_no
					JOIN	dbo.inv_master_add c (NOLOCK)
					ON		a.part_no = c.field_1
					WHERE	c.part_no = @part_no
					AND		b.location = @location
					AND		b.void = 'N'

					-- Does the case part exist
					IF (@case_part != '')
					BEGIN
						IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no 
									AND order_ext = @order_ext AND part_no = @case_part AND is_case = 1 AND	status > -1 AND deleted = 0) -- v1.5
						BEGIN
							

							SET @case_qty = dbo.f_calculate_case_sa_qty (@order_no,@order_ext,@soft_alloc_no,@case_part,@part_no,@line_no,@original_qty,@quantity)

							-- v2.2							
							SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
										AND order_no = @order_no AND order_ext = @order_ext AND part_no = @case_part AND status > -1 AND is_case = 1


							UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
							SET		quantity = ISNULL(@case_qty,0),	-- v2.4
							--SET		quantity = quantity + @quantity,	
							-- END v1.7
									change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
							WHERE	soft_alloc_no = @soft_alloc_no
							AND		order_no = @order_no 
							AND		order_ext = @order_ext 
							AND		part_no = @case_part
							AND		is_case = 1
							AND		status > -1
							AND		row_id = @row_id	-- v2.2
						END
						ELSE
						BEGIN
							-- START v3.4
							SET @existing_line = NULL
							--SET @existing_line = 0

							SELECT	@existing_line = a.line_no
							FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
							JOIN	ord_list b (NOLOCK)
							ON		a.order_no = b.order_no
							AND		a.order_ext = b.order_ext
							AND		a.line_no = b.line_no
							AND		a.part_no = b.part_no
							WHERE	a.order_no = @order_no
							AND		a.order_ext = @order_ext
							AND		a.location = @location
							AND		a.part_no = @case_part
							AND		a.is_case = 1
							--AND		a.status IN (-1,-2)
							AND		a.status = -1
							AND		a.deleted = 0 -- v1.5
				
							IF (@existing_line IS NULL)
							BEGIN	

								-- Now -2's are deleted, need to check tdc_soft_alloc_table
								SELECT @existing_line = a.line_no  
								FROM dbo.tdc_soft_alloc_tbl a (NOLOCK)  
								JOIN ord_list b (NOLOCK)  
								ON  a.order_no = b.order_no  
								AND  a.order_ext = b.order_ext  
								AND  a.line_no = b.line_no  
								AND  a.part_no = b.part_no 
								INNER JOIN cvo_ord_list c (NOLOCK)
								ON  a.order_no = c.order_no  
								AND  a.order_ext = c.order_ext  
								AND  a.line_no = c.line_no  
								WHERE a.order_no = @order_no  
								AND  a.order_ext = @order_ext  
								AND  a.location = @location  
								AND  a.part_no = @case_part  
								AND  c.is_case = 1  
								AND  a.order_type = 'S'

								IF (@existing_line IS NULL)
									SET @existing_line = 0
							END
							-- END v3.4

							-- v1.5 Start
							IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND location = @location
											AND part_no = @case_part AND is_case = 1 AND status IN (2) AND deleted = 0) 
							BEGIN
								IF ISNULL(@existing_line,0) = 0
								BEGIN  
								SELECT	@existing_line = line_no
									FROM	dbo.ord_list (NOLOCK)
									WHERE	order_no = @order_no
									AND		order_ext = @order_ext
									AND		location = @location
									AND		part_no = @case_part
								END

								IF @existing_line IS NULL
									SET @existing_line = 0

								IF NOT EXISTS (SELECT 1 FROM dbo.ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext
												AND location = @location AND part_no = @case_part)
									SET @existing_line = 0
							END
							-- v1.5 End

							-- START v1.7
							-- Calculate qty
							SET @case_qty = dbo.f_calculate_case_sa_qty (@order_no,@order_ext,@soft_alloc_no,@case_part,@part_no,@line_no,@original_qty,@quantity)


							INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
														kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
							VALUES (@soft_alloc_no, @order_no, @order_ext, @existing_line, @location, @case_part, ISNULL(@case_qty,0), @kit_part, @change, @deleted, 1, 0, 0, 1)  -- v3.3
							-- END v1.7
						END
					END
				END

				IF (@add_pattern = 1)
				BEGIN
					-- Find the pattern for this part
					SELECT	@pattern_part = ISNULL(a.part_no,'')
					FROM	dbo.inv_master_add a (NOLOCK)
					JOIN	dbo.inv_list b (NOLOCK)
					ON		a.part_no = b.part_no
					JOIN	dbo.inv_master_add c (NOLOCK)
					ON		a.part_no = c.field_4
					WHERE	c.part_no = @part_no
					AND		b.location = @location
					AND		b.void = 'N'

					-- Does the pattern part exist
					IF (@pattern_part != '')
					BEGIN
						-- Pattern Tracking
						IF NOT EXISTS (SELECT 1 FROM cvo_pattern_tracking (NOLOCK) WHERE customer_code = @customer_code
										AND ship_to = @ship_to AND pattern = @pattern_part)
						BEGIN
							IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no 
										AND order_ext = @order_ext AND part_no = @pattern_part AND is_pattern = 1 AND status > -1 AND deleted = 0) -- v1.5
							BEGIN
								INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
																kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
								VALUES (@soft_alloc_no, @order_no, @order_ext, 0, @location, @pattern_part, 1, @kit_part, @change, @deleted, 0, 1, 0, 1)
							END
						END
					END					
				END
			END
		END
		ELSE
		BEGIN -- kit part
			IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no 
									AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no AND kit_part = 1 AND status > -1 AND deleted = 0) -- v1.5 -- v2.9 add line_no
			BEGIN

				SELECT	@original_qty = quantity
				FROM	dbo.cvo_soft_alloc_det (NOLOCK) 
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		line_no = @line_no
				AND		kit_part = 1
				AND		status > -1

				-- v2.2							
				SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
							AND order_no = @order_no AND order_ext = @order_ext AND part_no = @case_part AND status > -1 AND kit_part = 1

				UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
				SET		quantity = quantity + (@quantity - ISNULL(@original_qty,0)),  -- v3.3
						inv_avail = @inv_avail, -- v1.4
						change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		part_no = @case_part
				AND		kit_part = 1	
				AND		status > -1
				AND		row_id = @row_id	-- v2.2
			END
			ELSE
			BEGIN		
				-- Add the soft allocation record for the kit part 
				INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
													kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, inv_avail)
				VALUES (@soft_alloc_no, @order_no, @order_ext, @line_no, @location, @part_no, @quantity, @kit_part, @change, @deleted, 0, 0, 0, 1, @inv_avail)
			END
		END	-- End kit part
	END -- End update or Add	
	ELSE
	BEGIN -- Delete
		-- if the order has already been hard allocated then create an adjustment allocation otherwise just remove the record
		SET @change = 1 -- v1.2
		IF (@change = 1) 
		BEGIN -- post hard allocation
			IF (@kit_part = 0) -- Non Kit part
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
								AND order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND status > -1)
				BEGIN
					INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
														kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
					VALUES (@soft_alloc_no, @order_no, @order_ext, @line_no, @location, @part_no, @quantity, @kit_part, @change, @deleted, 0, 0, 0, 1)
				END
				ELSE
				BEGIN
					SELECT	@is_case = is_case,
							@is_pattern = is_pattern,
							@original_qty = quantity
					FROM	dbo.cvo_soft_alloc_det (NOLOCK) 
					WHERE	soft_alloc_no = @soft_alloc_no
					AND		order_no = @order_no 
					AND		order_ext = @order_ext 
					AND		line_no = @line_no
					AND		status > -1

					IF (@is_case = 0 AND @is_pattern = 0) -- This is a part line
					BEGIN
						-- v2.5 Start
						IF NOT EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND part_no = @part_no)
						BEGIN
							DELETE	cvo_soft_alloc_det
							WHERE	order_no = @order_no 
							AND		order_ext = @order_ext 
							AND		line_no = @line_no 
							AND		part_no = @part_no
						END
						ELSE
						BEGIN
							-- v2.2							
							SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
										AND order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND status > -1


							UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
							SET		quantity = 0,
									deleted = 1,
									change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
							WHERE	soft_alloc_no = @soft_alloc_no
							AND		order_no = @order_no 
							AND		order_ext = @order_ext 
							AND		line_no = @line_no
							AND		status > -1
							AND		row_id = @row_id	-- v2.2
						END
						-- v2.5 End
					END
				END

				IF (@add_case = 1) -- Increment the cases - do not need to do the patterns as the quantity is always 1 per part
				BEGIN
					-- Find the case for this part
					SELECT	@case_part = ISNULL(a.part_no,'')
					FROM	dbo.inv_master_add a (NOLOCK)
					JOIN	dbo.inv_list b (NOLOCK)
					ON		a.part_no = b.part_no
					JOIN	dbo.inv_master_add c (NOLOCK)
					ON		a.part_no = c.field_1
					WHERE	c.part_no = @part_no
					AND		b.location = @location
					AND		b.void = 'N'

					-- Does the case part exist
					IF (@case_part != '')
					BEGIN 
						IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
										AND order_no = @order_no AND order_ext = @order_ext AND part_no = @case_part AND status > -1)
						BEGIN
							SET		@original_qty = NULL
							SELECT	@existing_line = line_no,
									@original_qty = ordered
							FROM	ord_list (NOLOCK)
							WHERE	order_no = @order_no 
							AND		order_ext = @order_ext 
							AND		part_no = @case_part

							/* -- v2.6
							INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
																kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
							VALUES (@soft_alloc_no, @order_no, @order_ext, @existing_line, @location, @case_part, @quantity, @kit_part, @change, @deleted, 1, 0, 0, 1)
							*/
							-- START v2.1 - code not required
							-- v2.6 Start

							-- v3.5 Start
							IF (@existing_line IS NOT NULL)
							BEGIN

								IF (ISNULL(@original_qty,0) - @quantity) > 0  -- v3.3
								BEGIN
									INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
																		kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
									VALUES (@soft_alloc_no, @order_no, @order_ext, @existing_line, @location, @case_part, (ISNULL(@original_qty,0) - @quantity), @kit_part, @change, 0, 1, 0, 0, 1)  -- v3.3
								END
								ELSE
								BEGIN
									INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
																		kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
									VALUES (@soft_alloc_no, @order_no, @order_ext, @existing_line, @location, @case_part, @quantity, @kit_part, @change, @deleted, 1, 0, 0, 1)

								END
							END
							-- v3.5 End
							-- v2.6 End
							-- END v2.1
						END
						ELSE
						BEGIN
							-- v2.2							
							SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
										AND order_no = @order_no AND order_ext = @order_ext AND part_no = @case_part AND status > -1 AND is_case = 1

							SET		@original_qty = 0

							SET @case_qty = dbo.f_calculate_case_sa_qty (@order_no,@order_ext,@soft_alloc_no,@case_part,@part_no,@line_no,@original_qty,0)

							-- START v2.0
							UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
							SET		quantity = ISNULL(CASE WHEN @case_qty <= 0 THEN 0 ELSE @case_qty END,0),  -- v3.3 -- @case_qty, -- - @quantity, --quantity - @original_qty,
									deleted = CASE WHEN @case_qty <= 0 THEN 1 ELSE 0 END, -- v1.2
									change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
							-- SET	quantity = quantity - @quantity,
							--		deleted = CASE WHEN (quantity - @quantity) <= 0 THEN 1 ELSE 0 END -- v1.2
							-- END v2.0
							WHERE	soft_alloc_no = @soft_alloc_no
							AND		order_no = @order_no 
							AND		order_ext = @order_ext 
							AND		part_no = @case_part
							AND		is_case = 1
							AND		status > -1
							AND		row_id = @row_id	-- v2.2
						END
					END
				END

				IF (@add_pattern = 1)
				BEGIN
					-- Find the pattern for this part
					SELECT	@pattern_part = ISNULL(a.part_no,'')
					FROM	dbo.inv_master_add a (NOLOCK)
					JOIN	dbo.inv_list b (NOLOCK)
					ON		a.part_no = b.part_no
					JOIN	dbo.inv_master_add c (NOLOCK)
					ON		a.part_no = c.field_4
					WHERE	c.part_no = @part_no
					AND		b.location = @location
					AND		b.void = 'N'

					-- Does the pattern part exist
					IF (@pattern_part != '')
					BEGIN
						-- if the pattern is used by another part then do not remove
						IF NOT EXISTS ( SELECT 1 FROM dbo.inv_master_add a (NOLOCK) JOIN dbo.cvo_soft_alloc_det b (NOLOCK)
									ON a.part_no = b.part_no WHERE b.soft_alloc_no = @soft_alloc_no AND a.field_4 = @pattern_part 
									AND a.part_no <> @part_no AND status > -1)
						BEGIN
							IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
											AND order_no = @order_no AND order_ext = @order_ext AND part_no = @pattern_part AND status > -1)
							BEGIN
								SELECT	@existing_line = line_no,
										@original_qty = ordered
								FROM	ord_list (NOLOCK)
								WHERE	order_no = @order_no 
								AND		order_ext = @order_ext 
								AND		part_no = @pattern_part

								INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
																	kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
								VALUES (@soft_alloc_no, @order_no, @order_ext, @existing_line, @location, @pattern_part, @quantity, @kit_part, @change, @deleted, 0, 1, 0, 1)
								IF (@original_qty - @quantity) > 0
								BEGIN
									INSERT	dbo.cvo_soft_alloc_det WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
																		kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)
									VALUES (@soft_alloc_no, @order_no, @order_ext, @existing_line, @location, @pattern_part, (ISNULL(@original_qty,0) - @quantity), @kit_part, @change, @deleted, 1, 0, 0, 1)  -- v3.3
								END
							END
							ELSE
							BEGIN
								-- v2.2							
								SELECT @row_id = MAX(row_id) 
								FROM dbo.cvo_soft_alloc_det  (NOLOCK)
								WHERE soft_alloc_no = @soft_alloc_no
								AND		order_no = @order_no 
								AND		order_ext = @order_ext 
								AND		part_no = @pattern_part
								AND		is_pattern = 1
								AND		status > -1

								UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
								SET		deleted = 1,
										change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
								WHERE	soft_alloc_no = @soft_alloc_no
								AND		order_no = @order_no 
								AND		order_ext = @order_ext 
								AND		part_no = @pattern_part
								AND		is_pattern = 1
								AND		status > -1
								AND		row_id = @row_id	-- v2.2
							END
						END
					END
				END

				IF (@is_case = 1 OR @is_pattern = 1) -- This is a case or pattern line - user has manually updated the quantity	
				BEGIN
					-- v2.2							
					SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
								AND order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND status > -1

					UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
					SET		deleted = 1,
							change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
					WHERE	soft_alloc_no = @soft_alloc_no
					AND		order_no = @order_no 
					AND		order_ext = @order_ext 
					AND		line_no = @line_no
					AND		status > -1
					AND		row_id = @row_id	-- v2.2
				END
			END -- end non kit
			ELSE
			BEGIN
				-- v2.2							
				SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
							AND order_no = @order_no AND order_ext = @order_ext AND	line_no = @line_no
							AND	kit_part = 1 AND status > -1

				
				UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
				SET		deleted = 1,
						change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		line_no = @line_no
				AND		kit_part = 1
				AND		status > -1
				AND		row_id = @row_id	-- v2.2
			END 
		END -- End Change
		ELSE
		BEGIN -- Delete without any allocations
			IF (@kit_part = 0)
			BEGIN
				SELECT	@is_case = is_case,
						@is_pattern = is_pattern,
						@original_qty = quantity
				FROM	dbo.cvo_soft_alloc_det (NOLOCK) 
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		line_no = @line_no
				AND		status > -1

				IF (@is_case = 0 AND @is_pattern = 0)
				BEGIN
					DELETE	dbo.cvo_soft_alloc_det 
					WHERE	soft_alloc_no = @soft_alloc_no 
					AND		order_no = @order_no 
					AND		order_ext = @order_ext 
					AND		line_no = @line_no 
					AND		status > -1
			
					IF (@add_case = 1) -- Increment the cases - do not need to do the patterns as the quantity is always 1 per part
					BEGIN
						-- Find the case for this part
						SELECT	@case_part = ISNULL(a.part_no,'')
						FROM	dbo.inv_master_add a (NOLOCK)
						JOIN	dbo.inv_list b (NOLOCK)
						ON		a.part_no = b.part_no
						JOIN	dbo.inv_master_add c (NOLOCK)
						ON		a.part_no = c.field_1
						WHERE	c.part_no = @part_no
						AND		b.location = @location
						AND		b.void = 'N'

						-- Does the case part exist
						IF (@case_part != '')
						BEGIN 
							-- v2.2							
							SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
										AND order_no = @order_no AND order_ext = @order_ext AND part_no = @case_part AND status > -1 AND is_case = 1

							UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
							SET		quantity = quantity - ISNULL(@original_qty,0),  -- v3.3
									change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
							WHERE	soft_alloc_no = @soft_alloc_no
							AND		order_no = @order_no 
							AND		order_ext = @order_ext 
							AND		part_no = @case_part
							AND		is_case = 1
							AND		status > -1
							AND		row_id = @row_id	-- v2.2

							DELETE	dbo.cvo_soft_alloc_det
							WHERE	soft_alloc_no = @soft_alloc_no
							AND		order_no = @order_no 
							AND		order_ext = @order_ext 
							AND		part_no = @case_part 
							AND		is_case = 1 
							AND		quantity <= 0
							AND		status > -1
						END
					END

					IF (@add_pattern = 1)
					BEGIN
						-- Find the pattern for this part
						SELECT	@pattern_part = ISNULL(a.part_no,'')
						FROM	dbo.inv_master_add a (NOLOCK)
						JOIN	dbo.inv_list b (NOLOCK)
						ON		a.part_no = b.part_no
						JOIN	dbo.inv_master_add c (NOLOCK)
						ON		a.part_no = c.field_4
						WHERE	c.part_no = @part_no
						AND		b.location = @location
						AND		b.void = 'N'

						-- Does the pattern part exist
						IF (@pattern_part != '')
						BEGIN
							-- if the pattern is used by another part then do not remove
							IF NOT EXISTS ( SELECT 1 FROM dbo.inv_master_add a (NOLOCK) JOIN dbo.cvo_soft_alloc_det b (NOLOCK)
										ON a.part_no = b.part_no WHERE b.soft_alloc_no = @soft_alloc_no AND a.field_4 = @pattern_part 
										AND a.part_no <> @part_no AND status > -1)
							BEGIN
								DELETE	dbo.cvo_soft_alloc_det 
								WHERE	soft_alloc_no = @soft_alloc_no
								AND		order_no = @order_no 
								AND		order_ext = @order_ext 
								AND		part_no = @pattern_part 
								AND		is_pattern = 1 
								AND		status > -1
							END
						END
					END
				END

				IF (@is_case = 1 OR @is_pattern = 1) -- This is a case or pattern line - user has manually updated the quantity	
				BEGIN
					-- v2.2							
					SELECT @row_id = MAX(row_id) FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no
								AND order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND status > -1

	
					UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
					SET		deleted = 1,
							change = CASE change WHEN 2 THEN 1 ELSE @change END -- v2.2 v3.0
					WHERE	soft_alloc_no = @soft_alloc_no
					AND		order_no = @order_no 
					AND		order_ext = @order_ext 
					AND		line_no = @line_no
					AND		status > -1
					AND		row_id = @row_id	-- v2.2
				END				
			END -- End Non Kit
			ELSE
			BEGIN
				DELETE	dbo.cvo_soft_alloc_det 
				WHERE	soft_alloc_no = @soft_alloc_no 
				AND		order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		line_no = @line_no 
				AND		kit_part = 1
				AND		status > -1
			END
		END -- End Change
	END -- End Delete

	-- If no records exist in the soft allocation detail then remove the header record
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status > -1)
	BEGIN
		DELETE dbo.cvo_soft_alloc_hdr WHERE soft_alloc_no = @soft_alloc_no AND status > -1
	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_add_soft_alloc_line_sp] TO [public]
GO
