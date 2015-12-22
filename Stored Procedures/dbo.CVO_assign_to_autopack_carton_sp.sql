SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC CVO_assign_to_autopack_carton_sp @order_no =, @order_ext = , @line_no = , @part_no = , @qty = 
-- v1.1 CT 30/07/12 - Fixed logic if multiple case lines are passed in before frames
-- v1.2 CT 10/08/12 - Fix for orders with frames and no cases
-- v1.3 CT 16/08/12 - Do not split orders lines across cartons if less than max)
-- v1.4 CT 24/09/12 - Stop zero qty lines being added to orders with multiple cartons which are not full
-- v1.5 CB 24/09/12 - Modify to work with soft allocation
-- v1.6 CT 03/10/12 - Code to reorganise cartons after a delete has been moved to cvo_remove_order_from_autopack_carton_sp
-- v1.7	CT 05/10/12 - Performance changes

CREATE PROC [dbo].[CVO_assign_to_autopack_carton_sp] (	@order_no	INT,
													@order_ext	INT,
													@line_no	INT,
													@part_no	VARCHAR(30),
													@qty		DECIMAL (20,8))
AS
BEGIN
	DECLARE @carton_id					INT,
			@free_space					INT,
			@frame_line_no				INT,
			@autopack_id				INT,
			@qty_on_line				DECIMAL(20,8),
			@remaining_qty				DECIMAL(20,8),
			@case_link					INT,
			@frame_link					INT,
			@qty_to_apply				INT,
			@case_line_no				INT,
			@part_type					VARCHAR(10),
			@os_qty						DECIMAL(20,8),
			@max_carton_id				INT,
			@case_link_deleted_line_no	INT,
			@max_qty					DECIMAL(20,8) -- v1.3
		

	SET @carton_id = 0
	SET @frame_line_no = 0

	-- START v1.7 
	-- Create temporary version of carton table
	CREATE TABLE #CVO_autopack_carton (
		autopack_id INT NOT NULL,
		carton_id	INT NOT NULL,
		order_no	INT NOT NULL,
		order_ext	INT NOT NULL,
		line_no		INT NOT NULL,
		part_no		VARCHAR(30) NOT NULL,
		part_type	VARCHAR(10) NOT NULL,
		case_link	INT NULL,
		case_link_deleted_line_no INT NULL,
		frame_link	INT NULL,
		frame_link_deleted_line_no INT NULL,
		qty			DECIMAL(20,8) NOT NULL,
		picked		DECIMAL(20,8) NOT NULL,
		carton_no	INT NULL)
	
	-- Create temporary table for carton free space
	CREATE TABLE #CVO_carton_free_space (
		carton_id	INT NOT NULL,
		free_space	DECIMAL(20,8) NOT NULL)	
	-- END v1.7

	-- Check this is a valid stock order
	IF NOT EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND [type] = 'I' AND LEFT(user_category,2) = 'ST' AND location < '100')	
	BEGIN
		RETURN
	END

	-- v1.3 - Gte maximum qty for a carton
	SELECT @max_qty = CAST(value_str AS DECIMAL(20,8)) FROM dbo.tdc_config (NOLOCK) WHERE mod_owner = 'GEN' AND [function] = 'STOCK_ORDER_CARTON_QTY'  

	-- Get part type
	SELECT @part_type = type_code FROM dbo.inv_master (NOLOCK) WHERE part_no = @part_no

	-- If this isn't a valid part type then return
	IF @part_type <> 'FRAME' AND @part_type <> 'SUN' AND @part_type <> 'CASE'
	BEGIN
		RETURN
	END

	-- If qty > 0 Then this is a new record ( <0 = removed record)
	IF @qty > 0
	BEGIN
		-- If this is a CASE linked to a frame, find the carton for the frame and put the stock in that one
		IF @part_type = 'CASE' 
		BEGIN
			SELECT 
				@frame_line_no = from_line_no 
			FROM 
			-- v1.5	dbo.cvo_ord_list (NOLOCK) 
				#cvo_ord_list -- v1.5 - working table created by CVO_create_fc_relationship_sp
			WHERE 
				order_no = @order_no
				AND order_ext = @order_ext
				AND line_no = @line_no
				AND is_case = 1
		END

		SET @remaining_qty = @qty

		IF (@part_type = 'CASE' ) AND (ISNULL(@frame_line_no,0) <> 0)
		BEGIN
			
			SET @frame_line_no = 0

			SELECT 
				TOP 1 @frame_line_no = from_line_no 
			FROM 
			-- v1.5	dbo.cvo_ord_list (NOLOCK) 
				#cvo_ord_list -- v1.5 - working table created by CVO_create_fc_relationship_sp
			WHERE 
				order_no = @order_no
				AND order_ext = @order_ext
				AND line_no = @line_no
				AND is_case = 1
				AND	from_line_no > @frame_line_no
				AND @remaining_qty > 0
				ORDER BY from_line_no
			
			WHILE @@ROWCOUNT <> 0
			BEGIN

				SET @autopack_id = 0
				SET @case_link = NULL

				-- Loop through cartons for the frame line and assign the relevant number of cases to it
				WHILE 1=1
				BEGIN
					SELECT  TOP 1
						@autopack_id = autopack_id,
						@carton_id = carton_id,
						@qty_on_line = qty,
						@case_link = case_link,
						@case_link_deleted_line_no = case_link_deleted_line_no
					FROM 
						dbo.CVO_autopack_carton (NOLOCK) 
					WHERE 
						order_no = @order_no 
						AND order_ext = @order_ext
						AND line_no = @frame_line_no
						AND autopack_id > @autopack_id
						AND part_type <> 'CASE'
					ORDER BY
						autopack_id

					IF @@ROWCOUNT = 0
						BREAK

					-- If there is already a case line, check if the full qty for the frame line has been assigned
					IF @case_link IS NOT NULL AND @case_link_deleted_line_no IS NULL
					BEGIN
						-- How much is outstanding on the case line
						SELECT
							@os_qty = @qty_on_line - qty
						FROM 
							dbo.CVO_autopack_carton (NOLOCK)
						WHERE
							autopack_id = @case_link

						-- If not fully assigned then add some cases on
						IF @os_qty <> 0
						BEGIN

							IF @os_qty >= @remaining_qty
							BEGIN
								SET @qty_to_apply = @remaining_qty
								SET @remaining_qty = 0
							END
							ELSE
							BEGIN
								SET @qty_to_apply = @os_qty
								SET @remaining_qty = @remaining_qty - @os_qty
							END
						
							-- Update the case line
							UPDATE
								dbo.CVO_autopack_carton
							SET
								qty = qty + @qty_to_apply
							WHERE
								autopack_id = @case_link
						END
					END
					ELSE
					BEGIN
						IF @qty_on_line >= @remaining_qty
						BEGIN
							SET @qty_to_apply = @remaining_qty
							SET @remaining_qty = 0
						END
						ELSE
						BEGIN
							SET @qty_to_apply = @qty_on_line
							SET @remaining_qty = @remaining_qty - @qty_on_line
						END
					
						-- Create a new line for the case
						INSERT dbo.CVO_autopack_carton(
							carton_id,
							order_no,
							order_ext,
							line_no,
							part_no,
							part_type,
							frame_link,
							qty,
							picked)
						SELECT
							@carton_id,
							@order_no,
							@order_ext,
							@line_no,
							@part_no,
							@part_type,
							@autopack_id,
							@qty_to_apply,
							0
						
						SELECT @case_link = @@IDENTITY
						
						-- Update frame line to link to case
						UPDATE
							dbo.CVO_autopack_carton
						SET
							case_link = @case_link,
							case_link_deleted_line_no = NULL
						WHERE
							autopack_id = @autopack_id
					END
					SET @case_link = NULL

					IF @remaining_qty = 0
						BREAK
				END
				
				SELECT 
					TOP 1 @frame_line_no = from_line_no 
				FROM 
				-- v1.5	dbo.cvo_ord_list (NOLOCK) 
					#cvo_ord_list -- v1.5 - working table created by CVO_create_fc_relationship_sp
				WHERE 
					order_no = @order_no
					AND order_ext = @order_ext
					AND line_no = @line_no
					AND is_case = 1
					AND	from_line_no > @frame_line_no
					AND @remaining_qty > 0
					ORDER BY from_line_no
			
			END

			-- START v1.1
			-- Assign the remaing stock to open carton(s)
			IF @remaining_qty > 0
			BEGIN

				-- START v1.7 - load temp table
				DELETE FROM #CVO_autopack_carton

				INSERT INTO 
					#CVO_autopack_carton
				SELECT 
					* 
				FROM 
					dbo.CVO_autopack_carton (NOLOCK) 
				WHERE 
					order_no = @order_no 
					AND order_ext = @order_ext
				ORDER BY 
					autopack_id

				DELETE FROM #CVO_carton_free_space
				
				INSERT #CVO_carton_free_space(
					carton_id,
					free_space)
				SELECT
					carton_id,
					dbo.f_return_autopack_carton_free_space(carton_id)
				FROM
					#CVO_autopack_carton
				GROUP BY
					carton_id
				ORDER BY
					carton_id
				-- END v1.7

				SET @carton_id = 0
				WHILE 1=1
				BEGIN
			
					-- START v1.7
					IF @remaining_qty > @max_qty
					BEGIN
						SELECT TOP 1 
							@carton_id = a.carton_id,
							@free_space  = b.free_space -- dbo.f_return_autopack_carton_free_space(carton_id)
						FROM 
							--dbo.CVO_autopack_carton (NOLOCK) 
							#CVO_autopack_carton a	
						INNER JOIN
							#CVO_carton_free_space b
						ON
							a.carton_id = b.carton_id
						WHERE 
							a.order_no = @order_no 
							AND a.order_ext = @order_ext
							-- START v1.3 
							AND b.free_space > 0
							--AND dbo.f_return_autopack_carton_free_space(carton_id) > 0
							-- END v1.3
							AND a.carton_id > @carton_id
						ORDER BY
							a.carton_id
					END
					ELSE
					BEGIN
						SELECT TOP 1 
							@carton_id = a.carton_id,
							@free_space  = b.free_space -- dbo.f_return_autopack_carton_free_space(carton_id)
						FROM 
							--dbo.CVO_autopack_carton (NOLOCK) 
							#CVO_autopack_carton a	
						INNER JOIN
							#CVO_carton_free_space b
						ON
							a.carton_id = b.carton_id	
						WHERE 
							a.order_no = @order_no 
							AND a.order_ext = @order_ext
							-- START v1.3 
							AND @remaining_qty <= b.free_space --dbo.f_return_autopack_carton_free_space(carton_id)
							--AND @remaining_qty <= dbo.f_return_autopack_carton_free_space(carton_id)
							-- END v1.3
							AND a.carton_id > @carton_id
						ORDER BY
							a.carton_id
					END
					-- END v1.7

					IF @@ROWCOUNT = 0 
						BREAK
						
					-- If there is free space, assign stock to it
					IF ISNULL(@free_space,0) > 0
					BEGIN
						-- How much can we fit in this carton
						IF @free_space >= @remaining_qty
						BEGIN
							SET @qty_to_apply = @remaining_qty
							SET @remaining_qty = 0
						END
						ELSE
						BEGIN
							SET @qty_to_apply = @free_space
							SET @remaining_qty = @remaining_qty - @free_space
						END

						-- If there is already an entry for this line_no then use it, if not create a new one
						SET @autopack_id = 0

						SELECT 
							@autopack_id = MAX(autopack_id) 
						FROM 
							dbo.CVO_autopack_carton (NOLOCK) 
						WHERE 
							carton_id = @carton_id 
							AND order_no = @order_no 
							AND order_ext = @order_ext 
							AND line_no = @line_no

						IF ISNULL(@autopack_id,0) <> 0
						BEGIN
							UPDATE
								dbo.CVO_autopack_carton
							SET
								qty = qty + @qty_to_apply
							WHERE
								autopack_id = @autopack_id
						END
						ELSE
						BEGIN

							-- Create new record in carton
							INSERT dbo.CVO_autopack_carton(
								carton_id,
								order_no,
								order_ext,
								line_no,
								part_no,
								part_type,
								frame_link,
								qty,
								picked)
							SELECT
								@carton_id,
								@order_no,
								@order_ext,
								@line_no,
								@part_no,
								@part_type,
								NULL,
								@qty_to_apply,
								0
						END
					END	
					
					-- START v1.4
					IF @remaining_qty = 0
						BREAK
					-- END v1.4

					-- START v1.7
					UPDATE
						#CVO_carton_free_space
					SET
						free_space = dbo.f_return_autopack_carton_free_space(carton_id)
					WHERE
						carton_id = @carton_id
					-- END v1.7

				END
			END
			-- END v1.1

			-- Assign the remaing stock to a new carton(s)
			IF @remaining_qty > 0
			BEGIN
				WHILE 1=1
				BEGIN
					-- Create a new carton
					SELECT @free_space = @max_qty -- v1.7
					--SELECT 	@carton_id = MAX(carton_id) + 1 FROM dbo.CVO_autopack_carton (NOLOCK) 
					
					IF ISNULL(@carton_id,0) = 0
					BEGIN
						SET @carton_id = 1
					END

					-- Get the free space in the carton
					SELECT @free_space = dbo.f_return_autopack_carton_free_space(@carton_id)

					IF @free_space >= @remaining_qty
					BEGIN
						SET @qty_to_apply = @remaining_qty
						SET @remaining_qty = 0
					END
					ELSE
					BEGIN
						SET @qty_to_apply = @free_space
						SET @remaining_qty = @remaining_qty - @free_space
					END

					-- Create record
					INSERT dbo.CVO_autopack_carton(
						carton_id,
						order_no,
						order_ext,
						line_no,
						part_no,
						part_type,
						qty,
						picked)
					SELECT
						@carton_id,
						@order_no,
						@order_ext,
						@line_no,
						@part_no,
						@part_type,
						@qty_to_apply,
						0

					-- If there isn't any qty remaining then drop out of loop
					IF @remaining_qty = 0
						BREAK
					
				END
			END

			-- v1.7
			DROP TABLE #CVO_autopack_carton
			DROP TABLE #CVO_carton_free_space
			
			-- Finished processing the case line so exit
			RETURN
		END
			
		SET @case_line_no = 0	-- v1.1

		-- Does this order line have a case line linked to it
		IF @part_type <> 'CASE'
		BEGIN
			SET @remaining_qty = @qty	-- v1.2
			SELECT 
				@case_line_no = line_no 
			FROM 
			-- v1.5	dbo.cvo_ord_list (NOLOCK) 
				#cvo_ord_list -- v1.5 - working table created by CVO_create_fc_relationship_sp
			WHERE 
				order_no = @order_no
				AND order_ext = @order_ext
				AND from_line_no = @line_no
				AND is_case = 1	
		END
	
		-- START v1.1
		-- Check if there are any cases already in the carton for this line
		IF @part_type <> 'CASE' AND ISNULL(@case_line_no,0) <> 0
		BEGIN
			--SET @remaining_qty = @qty	-- v1.2
			SET @qty_to_apply = 0
			SET @carton_id = 0
			
			-- START v1.7 - load temp table
			DELETE FROM #CVO_autopack_carton

			INSERT INTO 
				#CVO_autopack_carton
			SELECT 
				* 
			FROM 
				dbo.CVO_autopack_carton (NOLOCK) 
			WHERE 
				order_no = @order_no 
				AND order_ext = @order_ext
			ORDER BY 
				autopack_id

			DELETE FROM #CVO_carton_free_space
			
			INSERT #CVO_carton_free_space(
				carton_id,
				free_space)
			SELECT
				carton_id,
				dbo.f_return_autopack_carton_free_space_frame(carton_id,@case_line_no)
			FROM
				#CVO_autopack_carton
			GROUP BY
				carton_id
			ORDER BY
				carton_id
			-- END v1.7

			WHILE 1=1
			BEGIN
				
				-- START v1.7
				IF @remaining_qty > @max_qty
				BEGIN
				SELECT TOP 1 
					@carton_id = a.carton_id,
					@free_space  = b.free_space, --dbo.f_return_autopack_carton_free_space_frame(carton_id,@case_line_no),
					@case_link = a.autopack_id
				FROM 
					--dbo.CVO_autopack_carton (NOLOCK) 
					#CVO_autopack_carton a	
				INNER JOIN
					#CVO_carton_free_space b
				ON
					a.carton_id = b.carton_id
				WHERE 
					a.order_no = @order_no 
					AND a.order_ext = @order_ext 
					AND a.line_no = @case_line_no
					-- START v1.3 
					AND b.free_space > 0
					-- AND dbo.f_return_autopack_carton_free_space_frame(carton_id, @case_line_no) > 0
					-- END v1.3
					AND a.carton_id > @carton_id
				ORDER BY
					a.carton_id
				END
				ELSE
					BEGIN
						SELECT TOP 1 
						@carton_id = a.carton_id,
						@free_space  = b.free_space, --dbo.f_return_autopack_carton_free_space_frame(carton_id,@case_line_no),
						@case_link = a.autopack_id
					FROM 
						--dbo.CVO_autopack_carton (NOLOCK) 
						#CVO_autopack_carton a	
					INNER JOIN
						#CVO_carton_free_space b
					ON
						a.carton_id = b.carton_id
					WHERE 
						a.order_no = @order_no 
						AND a.order_ext = @order_ext 
						AND a.line_no = @case_line_no
						-- START v1.3 
						AND @remaining_qty <= b.free_space
						--AND @remaining_qty <= dbo.f_return_autopack_carton_free_space_frame(carton_id,@case_line_no)
						-- AND dbo.f_return_autopack_carton_free_space_frame(carton_id, @case_line_no) > 0
						-- END v1.3
						AND a.carton_id > @carton_id
					ORDER BY
						a.carton_id
				END
				-- END v1.7

				IF @@ROWCOUNT = 0
					BREAK

				-- Create new record in carton
				INSERT dbo.CVO_autopack_carton(
					carton_id,
					order_no,
					order_ext,
					line_no,
					part_no,
					part_type,
					case_link,
					qty,
					picked)
				SELECT
					@carton_id,
					@order_no,
					@order_ext,
					@line_no,
					@part_no,
					@part_type,
					@case_link,
					@qty_to_apply,
					0
				
				SELECT @frame_link = @@IDENTITY
			
				-- Update case record
				UPDATE
					dbo.CVO_autopack_carton
				SET
					frame_link = @frame_link,
					frame_link_deleted_line_no = NULL
				WHERE
					autopack_id = @case_link

				-- START v1.4
				IF @remaining_qty = 0
					BREAK
				-- END v1.4

				-- START v1.7
				UPDATE
					#CVO_carton_free_space
				SET
					free_space = dbo.f_return_autopack_carton_free_space_frame(carton_id,@case_line_no)
				WHERE
					carton_id = @carton_id
				-- END v1.7
			END
		END
		-- END v1.1

		-- v1.7 - only do this if remaining_qty > 0
		IF @remaining_qty > 0
		BEGIN
			SET @qty_to_apply = 0
			SET @carton_id = 0

			-- START v1.7
			DELETE FROM #CVO_autopack_carton

			INSERT INTO 
				#CVO_autopack_carton
			SELECT 
				* 
			FROM 
				dbo.CVO_autopack_carton (NOLOCK) 
			WHERE 
				order_no = @order_no 
				AND order_ext = @order_ext
			ORDER BY 
				autopack_id

			DELETE FROM #CVO_carton_free_space
			
			INSERT #CVO_carton_free_space(
				carton_id,
				free_space)
			SELECT
				carton_id,
				dbo.f_return_autopack_carton_free_space(carton_id)
			FROM
				#CVO_autopack_carton
			GROUP BY
				carton_id
			ORDER BY
				carton_id
			-- END v1.7

			-- Loop through cartons for this order which have space
			WHILE 1=1
			BEGIN
						
				-- START v1.7
				IF @remaining_qty > @max_qty
				BEGIN		
					SELECT TOP 1 
						@carton_id = a.carton_id,
						@free_space  = b.free_space --dbo.f_return_autopack_carton_free_space(carton_id)
					FROM 
						--dbo.CVO_autopack_carton (NOLOCK) 
						#CVO_autopack_carton a	
					INNER JOIN
						#CVO_carton_free_space b
					ON
						a.carton_id = b.carton_id
					WHERE 
						a.order_no = @order_no 
						AND a.order_ext = @order_ext
						-- START v1.3 
						AND b.free_space > 0
						--AND dbo.f_return_autopack_carton_free_space(carton_id) > 0
						-- END v1.3 
						AND a.carton_id > @carton_id
					ORDER BY
						a.carton_id
				END
				ELSE
				BEGIN
					SELECT TOP 1 
						@carton_id = a.carton_id,
						@free_space  = b.free_space -- dbo.f_return_autopack_carton_free_space(carton_id)
					FROM 
						--dbo.CVO_autopack_carton (NOLOCK) 
						#CVO_autopack_carton a	
					INNER JOIN
						#CVO_carton_free_space b
					ON
						a.carton_id = b.carton_id
					WHERE 
						a.order_no = @order_no 
						AND a.order_ext = @order_ext
						-- START v1.3 
						AND @remaining_qty <= b.free_space
						--AND @remaining_qty <= dbo.f_return_autopack_carton_free_space(carton_id)
						--AND dbo.f_return_autopack_carton_free_space(carton_id) > 0
						-- END v1.3 
						AND a.carton_id > @carton_id
					ORDER BY
						a.carton_id
				END
				-- END v1.7

				IF @@ROWCOUNT = 0 
					BREAK
					
				-- If there is free space, assign stock to it
				IF ISNULL(@free_space,0) > 0
				BEGIN
					-- How much can we fit in this carton
					IF @free_space >= @remaining_qty
					BEGIN
						SET @qty_to_apply = @remaining_qty
						SET @remaining_qty = 0
					END
					ELSE
					BEGIN
						SET @qty_to_apply = @free_space
						SET @remaining_qty = @remaining_qty - @free_space
					END

					-- If there is already an entry for this line_no then use it, if not create a new one
					SET @autopack_id = 0

					SELECT 
						@autopack_id = MAX(autopack_id) 
					FROM 
						dbo.CVO_autopack_carton (NOLOCK) 
					WHERE 
						carton_id = @carton_id 
						AND order_no = @order_no 
						AND order_ext = @order_ext 
						AND line_no = @line_no

					IF ISNULL(@autopack_id,0) <> 0
					BEGIN
						UPDATE
							dbo.CVO_autopack_carton
						SET	
							qty = qty + @qty_to_apply
						WHERE
							autopack_id = @autopack_id
					END
					ELSE
					BEGIN

						-- Is there already a case line for this frame?
						IF @part_type <> 'CASE'
						BEGIN
							SELECT 
								@case_link = autopack_id
							FROM
								dbo.CVO_autopack_carton (NOLOCK) 
							WHERE 
								carton_id = @carton_id 
								AND order_no = @order_no 
								AND order_ext = @order_ext 
								AND line_no = @case_line_no
						END

						-- Create new record in carton
						INSERT dbo.CVO_autopack_carton(
							carton_id,
							order_no,
							order_ext,
							line_no,
							part_no,
							part_type,
							case_link,
							qty,
							picked)
						SELECT
							@carton_id,
							@order_no,
							@order_ext,
							@line_no,
							@part_no,
							CASE @part_type WHEN 'CASE' THEN 'XCASE' ELSE @part_type END,
							CASE @part_type WHEN 'CASE' THEN NULL ELSE @case_link END,
							@qty_to_apply,
							0
						
						SELECT @frame_link = @@IDENTITY
				
						-- If there's a case record update it to link to frame
						IF (@part_type <> 'CASE') AND (ISNULL(@case_link,0) <> 0)
						BEGIN
							UPDATE
								dbo.CVO_autopack_carton
							SET
								frame_link = @frame_link,
								frame_link_deleted_line_no = NULL
							WHERE
								autopack_id = @case_link
						END
					END
		
				END

				-- START v1.4
				IF @remaining_qty = 0
					BREAK
				-- END v1.4

				-- START v1.7
				UPDATE
					#CVO_carton_free_space
				SET
					free_space = dbo.f_return_autopack_carton_free_space_frame(carton_id,@case_line_no)
				WHERE
					carton_id = @carton_id
				-- END v1.7
			END
		END -- v1.7

		-- Assign the remaing stock to a new carton(s)
		IF @remaining_qty > 0
		BEGIN
			WHILE 1=1
			BEGIN
				-- Create a new carton
				SELECT 	@carton_id = MAX(carton_id) + 1 FROM dbo.CVO_autopack_carton (NOLOCK) 
				
				IF ISNULL(@carton_id,0) = 0
				BEGIN
					SET @carton_id = 1
				END

				-- Get the free space in the carton
				SELECT @free_space = @max_qty  -- v1.7
				--SELECT @free_space = dbo.f_return_autopack_carton_free_space(@carton_id)

				IF @free_space >= @remaining_qty
				BEGIN
					SET @qty_to_apply = @remaining_qty
					SET @remaining_qty = 0
				END
				ELSE
				BEGIN
					SET @qty_to_apply = @free_space
					SET @remaining_qty = @remaining_qty - @free_space
				END

				-- Create record
				INSERT dbo.CVO_autopack_carton(
					carton_id,
					order_no,
					order_ext,
					line_no,
					part_no,
					part_type,
					qty,
					picked)
				SELECT
					@carton_id,
					@order_no,
					@order_ext,
					@line_no,
					@part_no,
					CASE @part_type WHEN 'CASE' THEN 'XCASE' ELSE @part_type END,
					@qty_to_apply,
					0

				-- If there isn't any qty remaining then drop out of loop
				IF @remaining_qty = 0
					BREAK
				
			END
		END
	END
	ELSE
	BEGIN	-- ** DELETION **
		-- Find the line for this deletion and update it
		SET @remaining_qty = ABS(@qty)
		SELECT @carton_id = ISNULL(MAX(carton_id),0) + 1 FROM dbo.CVO_autopack_carton (NOLOCK)		

		-- If part type is case check if it's linked to a frame
		IF @part_type = 'CASE' 
		BEGIN
			SELECT 
				@frame_line_no = from_line_no 
			FROM 
			-- v1.5	dbo.cvo_ord_list (NOLOCK) 
				#cvo_ord_list -- v1.5 - working table created by CVO_create_fc_relationship_sp
			WHERE 
				order_no = @order_no
				AND order_ext = @order_ext
				AND line_no = @line_no
				AND is_case = 1
		END

		IF (@part_type = 'CASE' ) AND (ISNULL(@frame_line_no,0) <> 0)
		BEGIN

			WHILE 1=1
			BEGIN
				-- loop through cartons that contain this case and corresponding frame
				SELECT TOP 1
					@carton_id = a.carton_id
				FROM 
					dbo.CVO_autopack_carton a (NOLOCK)
				LEFT JOIN
					dbo.CVO_autopack_carton b (NOLOCK)
				ON
					a.carton_id = b.carton_id
					AND a.order_no = b.order_no
					AND a.order_ext = b.order_ext
					AND a.autopack_id <> b.autopack_id
				WHERE
					a.order_no = @order_no
					AND a.order_ext = @order_ext
					AND a.line_no = @line_no
					AND ((ISNULL(b.line_no,0) = 1) OR (((b.line_no IS NULL) OR (ISNULL(b.line_no,0) <> a.frame_link_deleted_line_no)) AND a.frame_link_deleted_line_no = 1))
					AND a.picked = 0
					AND a.part_type = 'CASE'
					AND a.carton_id < @carton_id
				ORDER BY
					a.carton_id DESC

				IF @@ROWCOUNT = 0
					BREAK

				-- Loop through lines in this carton
				SELECT @autopack_id = ISNULL(MAX(autopack_id) + 1,0) FROM dbo.CVO_autopack_carton (NOLOCK)	
	
				WHILE 1=1
				BEGIN
					SELECT TOP 1
						@autopack_id = a.autopack_id,
						@qty_on_line = a.qty
					FROM 
						dbo.CVO_autopack_carton a (NOLOCK)
					LEFT JOIN
						dbo.CVO_autopack_carton b (NOLOCK)
					ON
						a.carton_id = b.carton_id
						AND a.order_no = b.order_no
						AND a.order_ext = b.order_ext
						AND a.autopack_id = b.case_link
						AND a.autopack_id <> b.autopack_id
					WHERE
						a.order_no = @order_no
						AND a.order_ext = @order_ext
						AND a.line_no = @line_no
						AND ((ISNULL(b.line_no,0) = 1) OR (((b.line_no IS NULL) OR (ISNULL(b.line_no,0) <> a.frame_link_deleted_line_no)) AND a.frame_link_deleted_line_no = 1))
						AND a.picked = 0
						AND a.autopack_id < @autopack_id
						AND a.carton_id = @carton_id
					ORDER BY
						a.autopack_id DESC

					IF @@ROWCOUNT = 0
						BREAK

					IF @qty_on_line >= @remaining_qty
					BEGIN
						SET @qty_to_apply = @remaining_qty
						SET @remaining_qty = 0
					END
					ELSE
					BEGIN
						SET @qty_to_apply = @qty_on_line
						SET @remaining_qty = @remaining_qty - @qty_on_line
					END

					-- Update record
					UPDATE
						dbo.CVO_autopack_carton
					SET
						qty = qty - @qty_to_apply
					WHERE
						autopack_id = @autopack_id

					-- If the qty on this line is now zero delete it
					IF EXISTS (SELECT 1 FROM dbo.CVO_autopack_carton (NOLOCK) WHERE	autopack_id = @autopack_id AND qty = 0)
					BEGIN
						DELETE FROM dbo.CVO_autopack_carton WHERE	autopack_id = @autopack_id AND qty = 0
					END
				
					IF @remaining_qty = 0
						BREAK

				END

				IF @remaining_qty = 0
					BREAK
			END
		END
		
		IF @remaining_qty <> 0
		BEGIN
		
			SELECT @carton_id = ISNULL(MAX(carton_id),0) + 1 FROM dbo.CVO_autopack_carton (NOLOCK)	
			WHILE 1=1
			BEGIN
				-- loop through cartons that contain this part
				SELECT TOP 1
					@carton_id = carton_id
				FROM 
					dbo.CVO_autopack_carton (NOLOCK)
				WHERE
					order_no = @order_no
					AND order_ext = @order_ext
					AND line_no = @line_no
					AND picked = 0
					AND carton_id < @carton_id
				ORDER BY
					carton_id DESC

				IF @@ROWCOUNT = 0
					BREAK

				-- Loop through lines in this carton
				SELECT @autopack_id = ISNULL(MAX(autopack_id) + 1,0) FROM dbo.CVO_autopack_carton (NOLOCK)	
				WHILE 1=1
				BEGIN
					SELECT TOP 1
						@autopack_id = autopack_id,
						@qty_on_line = qty
					FROM 
						dbo.CVO_autopack_carton (NOLOCK)
					WHERE
						order_no = @order_no
						AND order_ext = @order_ext
						AND line_no = @line_no
						AND picked = 0
						AND autopack_id < @autopack_id
						AND carton_id = @carton_id
					ORDER BY
						autopack_id DESC

					IF @@ROWCOUNT = 0
						BREAK

					IF @qty_on_line >= @remaining_qty
					BEGIN
						SET @qty_to_apply = @remaining_qty
						SET @remaining_qty = 0
					END
					ELSE
					BEGIN
						SET @qty_to_apply = @qty_on_line
						SET @remaining_qty = @remaining_qty - @qty_on_line
					END

					-- Update record
					UPDATE
						dbo.CVO_autopack_carton
					SET
						qty = qty - @qty_to_apply
					WHERE
						autopack_id = @autopack_id

					-- If the qty on this line is now zero delete it
					IF EXISTS (SELECT 1 FROM dbo.CVO_autopack_carton (NOLOCK) WHERE	autopack_id = @autopack_id AND qty = 0)
					BEGIN
						DELETE FROM dbo.CVO_autopack_carton WHERE autopack_id = @autopack_id AND qty = 0
					END
				
					IF @remaining_qty = 0
						BREAK

				END

				IF @remaining_qty = 0
					BREAK
			END
		END

		-- START v1.6
		/*
		-- If there are any cartons for this order that are now not full then reorganise
		SET @carton_id = 0
		SELECT @max_carton_id = MAX(carton_id) FROM dbo.CVO_autopack_carton (NOLOCK) WHERE order_no = @order_no	AND order_ext = @order_ext

		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@carton_id = carton_id
			FROM
				dbo.CVO_autopack_carton (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @order_ext
				AND dbo.f_return_autopack_carton_free_space(carton_id) > 0
				AND carton_id <> @max_carton_id
				AND carton_id > @carton_id
			ORDER BY 
				carton_id

			IF @@ROWCOUNT = 0
				BREAK

			EXEC cvo_reorganise_autopack_carton_free_space_sp @carton_id


		END
		*/
		-- END v1.6
			
	END

	-- v1.7
	DROP TABLE #CVO_autopack_carton
	DROP TABLE #CVO_carton_free_space

END

GO
GRANT EXECUTE ON  [dbo].[CVO_assign_to_autopack_carton_sp] TO [public]
GO
