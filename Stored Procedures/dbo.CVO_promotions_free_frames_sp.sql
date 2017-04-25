SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 28/02/2013 - Calculates the free frames for the order
-- v1.1 CT 04/03/2013 - Corrected calculation for number of free frames
-- v1.2 CT 16/08/2013 - Issue #1360 - use correct field for gender
-- v1.3 CB 05/04/2017 - Fix issue with multiple free frame layers


CREATE PROC [dbo].[CVO_promotions_free_frames_sp] ( @promo_id			VARCHAR(30),	
												@promo_level		VARCHAR(30),
												@spid				INT,
												@override			SMALLINT = 0) 
AS
BEGIN
	DECLARE @rec_id				INT,
			@ff_min_qty			INT,
			@ff_min_frame		SMALLINT,
			@ff_min_sun			SMALLINT,
			@ff_max_free_qty	INT,
			@ff_max_free_frame	SMALLINT,
			@ff_max_free_sun	SMALLINT,
			@brand_exclude		CHAR(1),						
			@category_exclude	CHAR(1),	
			@brand				VARCHAR(30),
			@category			VARCHAR(30),
			@gender_check		SMALLINT,
			@attribute			SMALLINT,
			@promo_line_no		INT,
			@actual_qty			INT,
			@free_qty			INT,
			@line_no			INT,
			@apply_qty			DECIMAL(20,8),
			@split				SMALLINT,
			@qty				DECIMAL(20,8),
			@min_qty			int, -- v1.3
			@max_qty			int -- v1.3

	-- Create temp tables for ord_list records
	CREATE TABLE #ff_ord_list (
			part_no		VARCHAR(30),
			line_no		INT,
			brand		VARCHAR(30),
			category	VARCHAR(30),
			ordered		DECIMAL(20, 8),			
			gender		VARCHAR(15),							
			attribute	VARCHAR(10)								
		)

	CREATE TABLE #selected_ord_list (
			part_no		VARCHAR(30),
			line_no		INT,
			brand		VARCHAR(30),
			category	VARCHAR(30),
			ordered		DECIMAL(20, 8),		
			gender		VARCHAR(15),							
			attribute	VARCHAR(10)								
		)

	-- Load working ord_list table
	INSERT INTO	#ff_ord_list(
		part_no,
		line_no,
		brand,
		category,
		ordered,
		gender,							
		attribute)
	SELECT
		a.part_no,
		a.line_no,
		i.category,
		i.type_code,
		a.ordered,			
		-- START v1.2
		ISNULL(ia.category_2,''),
		--ISNULL(ia.field_2,''),
		-- END v1.2							
		ISNULL(ia.field_32,'')	
	FROM
		dbo.cvo_free_frame_apply a
	INNER JOIN 
		dbo.inv_master i (NOLOCK) ON a.part_no = i.part_no
	INNER JOIN 
		inv_master_add ia (NOLOCK) ON a.part_no = ia.part_no
	WHERE 
		a.SPID = @spid 	

	-- If the promo was overridden then treat all free frame lines as if they qualified
	IF ISNULL(@override,0) = 1
	BEGIN
		DELETE FROM dbo.CVO_free_frame_qualified WHERE SPID = @spid

		INSERT INTO CVO_free_frame_qualified (
			SPID,
			line_no,
			ff_min_qty,
			ff_min_frame,
			ff_min_sun,
			ff_max_free_qty,
			ff_max_free_frame,
			ff_max_free_sun,
			brand,
			category,
			gender_check,
			attribute,
			brand_exclude,
			category_exclude,
			promo_id,
			promo_level)
		SELECT
			@spid,
			line_no,
			ff_min_qty,
			ff_min_frame,
			ff_min_sun,
			ff_max_free_qty,
			ff_max_free_frame,
			ff_max_free_sun,
			brand,
			category,
			gender_check,
			attribute,
			brand_exclude,
			category_exclude,
			@promo_id,
			@promo_level
		FROM 
			dbo.cvo_order_qualifications (NOLOCK)
		WHERE 
			promo_id = @promo_id
			AND promo_level = @promo_level
			AND free_frames = 1
	END

	-- Loop through the order qualifications lines that have passed and are for free frames
	SET @rec_id = 0
	
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@ff_min_qty = ff_min_qty,
			@ff_min_frame = ff_min_frame,
			@ff_min_sun = ff_min_sun,
			@ff_max_free_qty = ff_max_free_qty,
			@ff_max_free_frame = ff_max_free_frame,
			@ff_max_free_sun = ff_max_free_sun,
			@brand_exclude = brand_exclude,
			@category_exclude = category_exclude,
			@brand = brand,
			@category = category,
			@gender_check = gender_check,
			@attribute = attribute,
			@promo_line_no = line_no,
			@min_qty = min_qty, -- v1.3
			@max_qty = max_qty -- v1.3
		FROM
			dbo.CVO_free_frame_qualified (NOLOCK)
		WHERE
			rec_id > @rec_id
			AND SPID = @spid
			AND promo_id = @promo_id
			AND promo_level = @promo_level
		ORDER BY 
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Clear temp ord_list table
		DELETE FROM #selected_ord_list

		-- Load order lines which match
		INSERT INTO	#selected_ord_list(
			part_no,
			line_no,
			brand,
			category,
			ordered,				
			gender,							
			attribute)
		SELECT
			part_no,
			line_no,
			brand,
			category,
			ordered,
			gender,							
			attribute	
		FROM
			#ff_ord_list (NOLOCK)
		WHERE
			((ISNULL(@brand_exclude,'N') = 'N' AND ISNULL(@brand,'') <> '' AND brand = @brand) 
					OR (ISNULL(@brand_exclude,'N') <> 'N' AND ISNULL(@brand,'') <> '' AND brand <> @brand) 
					OR (ISNULL(@brand,'') = ''))
			AND ((ISNULL(@category_exclude,'N') = 'N' AND ISNULL(@category,'') <> '' AND category = @category) 
					OR (ISNULL(@category_exclude,'N') <> 'N' AND ISNULL(@category,'') <> '' AND category <> @category) 
					OR (ISNULL(@category,'') = ''))
			AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'O'))) 
			AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @promo_line_no AND line_type = 'O')))
		
		-- Remove lines which don't meet the min qty frame/sun setting
		DELETE FROM #selected_ord_list WHERE category NOT IN ('FRAME','SUN')
		
		IF @ff_min_frame = 0
		BEGIN
			DELETE FROM #selected_ord_list WHERE category = 'FRAME'
		END

		IF @ff_min_sun = 0
		BEGIN
			DELETE FROM #selected_ord_list WHERE category = 'SUN'
		END
		
		-- Get qty on order
		SELECT
			@actual_qty = CAST(SUM(ordered) AS INT)
		FROM
			#selected_ord_list

		-- v1.3 Start
		IF (@min_qty <> 0 AND @max_qty <> 0)
		BEGIN
			IF (ISNULL(@actual_qty,0) >= @min_qty AND ISNULL(@actual_qty,0) <= @max_qty)
			BEGIN
				-- Does it meet the minimum qty?
				IF ISNULL(@actual_qty,0) > = @ff_min_qty 
				BEGIN
					-- START v1.1
					SET @free_qty = ISNULL(@actual_qty,0) - @ff_min_qty 
					-- SET @free_qty = ISNULL(@actual_qty,0) - (@ff_min_qty - 1)
					-- END v1.1

				
					-- If free qty is greater than max free qty then set to max free qty
					IF @free_qty > @ff_max_free_qty
					BEGIN
						SET @free_qty = @ff_max_free_qty
					END

					-- Loop through lines and apply until free_qty is 0 or no more lines left
					WHILE @free_qty > 0
					BEGIN
						SELECT TOP 1
							@line_no = a.line_no,
							@qty = CASE split WHEN 0 THEN a.ordered ELSE a.ordered - free_qty END
						FROM
							dbo.cvo_free_frame_apply a (NOLOCK)
						INNER JOIN
							#selected_ord_list b (NOLOCK)
						ON
							a.line_no = b.line_no
						WHERE
							a.SPID = @spid
							AND ((a.is_free = 0) OR (a.is_free = 1 AND split = 1))
						ORDER BY
							a.price ASC, 
							a.line_no ASC

						IF @@ROWCOUNT = 0
							BREAK

						IF @free_qty > @qty 
						BEGIN
							SET @free_qty = @free_qty - @qty
							SET @apply_qty = @qty
							SET @split = 0
						END
						ELSE
						BEGIN
							SET @apply_qty = @free_qty
							SET @free_qty = 0
							IF @qty = @apply_qty
							BEGIN
								SET @split = 0
							END
							ELSE
							BEGIN
								SET @split = 1
							END
						END

						-- Update record
						UPDATE
							dbo.cvo_free_frame_apply
						SET
							free_qty = free_qty + @apply_qty,
							split = @split,
							is_free = 1
						WHERE
							SPID = @spid
							AND line_no = @line_no

					END

				END

			END
		END
		ELSE
		BEGIN
			-- Does it meet the minimum qty?
			IF ISNULL(@actual_qty,0) > = @ff_min_qty 
			BEGIN
				-- START v1.1
				SET @free_qty = ISNULL(@actual_qty,0) - @ff_min_qty 
				-- SET @free_qty = ISNULL(@actual_qty,0) - (@ff_min_qty - 1)
				-- END v1.1

			
				-- If free qty is greater than max free qty then set to max free qty
				IF @free_qty > @ff_max_free_qty
				BEGIN
					SET @free_qty = @ff_max_free_qty
				END

				-- Loop through lines and apply until free_qty is 0 or no more lines left
				WHILE @free_qty > 0
				BEGIN
					SELECT TOP 1
						@line_no = a.line_no,
						@qty = CASE split WHEN 0 THEN a.ordered ELSE a.ordered - free_qty END
					FROM
						dbo.cvo_free_frame_apply a (NOLOCK)
					INNER JOIN
						#selected_ord_list b (NOLOCK)
					ON
						a.line_no = b.line_no
					WHERE
						a.SPID = @spid
						AND ((a.is_free = 0) OR (a.is_free = 1 AND split = 1))
					ORDER BY
						a.price ASC, 
						a.line_no ASC

					IF @@ROWCOUNT = 0
						BREAK

					IF @free_qty > @qty 
					BEGIN
						SET @free_qty = @free_qty - @qty
						SET @apply_qty = @qty
						SET @split = 0
					END
					ELSE
					BEGIN
						SET @apply_qty = @free_qty
						SET @free_qty = 0
						IF @qty = @apply_qty
						BEGIN
							SET @split = 0
						END
						ELSE
						BEGIN
							SET @split = 1
						END
					END

					-- Update record
					UPDATE
						dbo.cvo_free_frame_apply
					SET
						free_qty = free_qty + @apply_qty,
						split = @split,
						is_free = 1
					WHERE
						SPID = @spid
						AND line_no = @line_no

				END

			END
		END -- v1.3 End
	END

	-- Return rows to be given for free
	SELECT
		line_no,
		free_qty,
		split	
	FROM
		dbo.cvo_free_frame_apply (NOLOCK)
	WHERE
		SPID = @spid
		AND is_free = 1
	ORDER BY 
		line_no

END
GO
GRANT EXECUTE ON  [dbo].[CVO_promotions_free_frames_sp] TO [public]
GO
