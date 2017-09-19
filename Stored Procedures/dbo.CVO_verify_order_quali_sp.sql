SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1		CT	20/05/11 - Routine was using ord_list which wasn't written before this was called on first order save, change it to use cvo_ord_list_temp
-- v1.2		CT	20/05/11 - Routine is being called before orders table is written, pass the info as parameters instead of getting it from the table
-- v1.3		CT	31/05/11 - 68668-U52685ENT - When failing qualification, return the reason the order failed
-- v1.4		TM	06/20/11 - Set return code if any rows have failed rather than reading through the table
-- v1.5		CT	01/07/11 - Rewrote logic	
-- v1.6		CT	06/07/11 - Corrected logic for testing for 2 colors
-- v1.7		CT	06/07/11 - Added logic for Gender
-- v1.8		CT	06/07/11 - If no brand or category is set, min/max qty should only be calculated against FRAME and SUN
-- v1.9		CT	07/07/11 - Additional Gender check - if promo contains gender then order fails if it contains a gender not on the promo
-- v1.10	CT	07/07/11 - Corrected logic for two colors
-- v1.11	CB	21/02/12 - Return all or error messages
-- v1.12	CB	24/02/12 - Fix - Use the promo passed in
-- v1.13	CB  29/02/12 - Default min qty to - 999999
-- v1.14	CT	21/06/12 - Use colour code (category_5) instead of colour description (field_3)
-- v1.15	CT	29/10/12 - Return 1 if promo qualifies, 0 if not
-- v1.16	CT	06/02/13 - CVO-CF-37 - Additional qualification criteria of attribute
-- v1.17	CT	12/02/13 - Attribute change - all frame/suns on order must have attribute defined for the qualification line for the line to pass
-- v1.18	CT	13/02/13 - Change to how gender is stored against a promo
-- v1.19	CT	28/02/13 - Free frames logic
-- v1.20	CB	08/04/13 - Issue #1196 - When 2 colours is set it must be all styles within the brand/category must have at least 2 colours
-- v1.21	CT	03/07/13 - Fix to stop duplicate free frame lines from being written for subscription promos
-- v1.22	CT	07/08/13 - Issue #864 - If promo is a drawdown, then store which line qualifications passed
-- v1.23	CT	07/01/14 - Issue #1435 - For 2 colour check, only evaluate order lines which are FRAME/SUN if there is no category specified in the query
-- v1.24	CB	12/05/2016 - Fix issue with attribute check
-- v1.25	CB	05/04/2017 - Fix issue with multiple free frame layers
-- v1.26	CB	12/09/2017 - #1648 - Combine promo lines

CREATE PROCEDURE [dbo].[CVO_verify_order_quali_sp]	@order_no INT = 0, 
													@ext INT = 0,  
													@promo_id			VARCHAR(30),	-- v1.2
													@promo_level		VARCHAR(30),	-- v1.2
													@customer			VARCHAR(30),	-- v1.2
													@sub_check			SMALLINT = 0	-- v1.15
AS
BEGIN
		DECLARE	@id					INT,
				@start_date			DATETIME,
				@end_date			DATETIME,
				@achived			INT,
				@qty_only			INT,
				@rows_found			VARCHAR(3),
				@cond1				VARCHAR(1),
				@cond2				VARCHAR(1),
				@brand				VARCHAR(30),
				@category			VARCHAR(30),
				@max				INT,
				@counter			INT,
				@brand_found		INT,
				@category_found		INT,
				@brand_exclude		VARCHAR(1),						-- TLM Fix
				@category_exclude	VARCHAR(1),						-- TLM Fix
				@condition			VARCHAR(MAX),
				@total_qty_brand	DECIMAL(20, 8),
				@total_qty_categoty	DECIMAL(20, 8),
				@total_qty_all		DECIMAL(20, 8),					-- v1.4
				@min_qty			DECIMAL(20, 8),
				@max_qty			DECIMAL(20, 8),
				@two_colors			VARCHAR(1),
				@SQL_X				VARCHAR(8000),
				@fail_reason		varchar(200),	-- v1.3
				@brand_on_order		char(1),		-- v1.5
				@category_on_order	char(1),		-- v1.5
				@combo_on_order		char(1),		-- v1.5
				@combo_found		INT,			-- v1.5
				@or_fail_reason		varchar(200),	-- v1.5
				@and_fail_reason	varchar(MAX),	-- v1.5 -- v1.11
				@and				char(1),		-- v1.5
				@total_qty_combo	DECIMAL(20,8),	-- v1.5
				@gender_found		INT,			-- v1.7
				-- START v1.18
				--@gender				VARCHAR(15),-- v1.7
				@gender_check		SMALLINT,		
				-- END v1.18
				@excluded_gender	INT,			-- v1.9
				-- START v1.16
				@attribute			SMALLINT,		
				@line_no			INT,
				-- END v1.16
				@combine			char(1) -- v1.26
				

		SET NOCOUNT ON

		SET @fail_reason = ''	-- v1.3

		CREATE TABLE #cvo_order_qualifications(
			id					INT IDENTITY(1,1),
			line_no				INT,
			brand				VARCHAR(30),
			category			VARCHAR(30),
			min_qty				INT,
			max_qty				INT,
			two_colors			VARCHAR(1),
			and_				VARCHAR(1),
			or_					VARCHAR(1),
			rows_found			VARCHAR(3),
			brand_exclude		VARCHAR(1),						-- TLM Fix
			category_exclude	VARCHAR(1),						-- TLM Fix
			gender				VARCHAR(15),					-- v1.7
			attribute			SMALLINT,						-- v1.16
			gender_check		SMALLINT,						-- v1.18
			-- START v1.19
			free_frames			SMALLINT,						
			ff_min_qty			INT,
			ff_min_frame		SMALLINT,
			ff_min_sun			SMALLINT,
			ff_max_free_qty		INT,
			ff_max_free_frame	SMALLINT,
			ff_max_free_sun		SMALLINT,
			ff_actual_qty		DECIMAL(20,8),
			-- END v1.19
			combine				char(1) -- v1.26
		)

		CREATE TABLE #ord_list (
			part_no		VARCHAR(30),
			brand		VARCHAR(30),
			category	VARCHAR(30),
			ordered		DECIMAL(20, 8),
			color		VARCHAR(40),
			style		VARCHAR(40),							-- 2 Colors per Style
			gender		VARCHAR(15),							-- v1.7
			attribute	VARCHAR(10)								-- v1.16
		)


-- Add in for running in SQL

/*
INSERT INTO CVO_ord_list_temp 
select a.order_no, a.order_ext, a.part_no, a.ordered, b.is_pop_gif from ord_list a inner join
cvo_ord_list b on a.order_no = b.order_no and a.order_ext = b.order_ext and a.line_no = b.line_no
where a.order_no = @order_no and a.order_ext = @ext
*/



		-- v1.12
--		SELECT	@promo_id = promo_id, @promo_level = promo_level
--		FROM	CVO_orders_all (NOLOCK)
--		WHERE	order_no = @order_no AND ext = @ext

		INSERT INTO #cvo_order_qualifications(
				line_no,		brand,		category,		
				min_qty,		max_qty,	two_colors, 
				and_,			or_, 		rows_found,
				brand_exclude,	category_exclude,				-- TLM Fix
				gender,											-- v1.7
				attribute,										-- v1.16
				gender_check,									-- v1.18
				-- START v1.19
				free_frames,						
				ff_min_qty,
				ff_min_frame,
				ff_min_sun,
				ff_max_free_qty,
				ff_max_free_frame,
				ff_max_free_sun,	
				-- END v1.19
				combine -- v1.26
		)
		SELECT	line_no,		brand,		category,
				IsNull(min_qty,-9999999),	IsNull(max_qty,999999999),	two_colors, -- v1.13
				and_,			or_,		'0=1', brand_exclude,  category_exclude,
				gender,	-- v1.7										
				ISNULL(attribute,0),							-- v1.16
				ISNULL(gender_check,0),							-- v1.18
				-- START v1.19
				ISNULL(free_frames,0),						
				ISNULL(ff_min_qty,0),
				ISNULL(ff_min_frame,0),
				ISNULL(ff_min_sun,0),
				ISNULL(ff_max_free_qty,0),
				ISNULL(ff_max_free_frame,0),
				ISNULL(ff_max_free_sun,0),	
				-- END v1.19
				ISNULL(combine,'N') -- v1.26
		FROM	CVO_order_qualifications (NOLOCK)
		WHERE	promo_id = @promo_id AND
				promo_level = @promo_level
		ORDER BY line_no

		UPDATE #cvo_order_qualifications SET max_qty = 999999999 WHERE max_qty = 0
		
		-- v1.5 - if a line is neither AND nor OR set to AND
		UPDATE #cvo_order_qualifications SET and_ = 'Y' WHERE and_ = 'N' AND or_ = 'N'



		-- START v1.1
		INSERT INTO #ord_list (part_no, brand, category, ordered, color, style, gender, attribute)		-- v1.7 & v1.16

		-- START v1.14
		-- SELECT l.part_no, i.category, i.type_code, l.ordered, ia.field_3, ia.field_2, category_2		-- v1.7
		SELECT l.part_no, i.category, i.type_code, l.ordered, ia.category_5, ia.field_2, category_2, ISNULL(ia.field_32,'')		-- v1.7 & v1.16
		-- END v1.14

		FROM CVO_ord_list_temp l (NOLOCK)
			INNER JOIN inv_master i (NOLOCK) ON l.part_no = i.part_no
			INNER JOIN inv_master_add ia (NOLOCK) ON l.part_no = ia.part_no
		WHERE l.order_no = @order_no AND l.order_ext = @ext --AND l.is_pop_gif = 0
		-- END v1.1
		
		-- START v1.2
		/*
		SELECT @promo_id = c.promo_id, @promo_level = c.promo_level, @customer = o.cust_code
		FROM orders_all o
			INNER JOIN CVO_orders_all c ON o.order_no = c.order_no AND o.ext = c.ext
		WHERE o.order_no = @order_no AND o.ext = @ext
		*/
		-- END v1.2

		SELECT @qty_only = 0

		SELECT	@id = MIN(id)
		FROM	#cvo_order_qualifications

		WHILE (@id IS NOT NULL)
		BEGIN

	

			SELECT	@brand = brand, @category = category, @brand_exclude = brand_exclude, @category_exclude = category_exclude,
					@min_qty = IsNull(min_qty,0), @max_qty = IsNull(max_qty,999999999), @two_colors = two_colors,
					@and = and_,	-- v1.5
					-- START v1.18
					--@gender = gender,	-- v1.7
					@gender_check = gender_check,
					-- END v1.18
					-- START v1.16
					@attribute = attribute, 
					@line_no = line_no,
					-- END v1.16
					@combine = combine -- v1.26
			FROM 	#cvo_order_qualifications
			WHERE	id = @id

			SELECT @achived = 0

			--	Does the entered order contain the given brand or category of product
			-- START v1.5
			SET @brand_on_order	= 'N'		-- v1.5
			SET @category_on_order = 'N'	-- v1.5
			SET @combo_on_order	= 'N'		-- v1.5
			SET @brand_found = 0			-- v1.5
			SET @category_found = 0			-- v1.5
			SET @combo_found = 0			-- v1.5
			SET @gender_found = 0			-- v1.7

			-- Check the brand only
			IF LTRIM(RTRIM(ISNULL(@brand,''))) <> '' AND LTRIM(RTRIM(ISNULL(@category,''))) = ''
			BEGIN
				-- check if the order contains the brand
				SELECT @brand_found = COUNT(*) FROM #ord_list WHERE brand = @brand

				-- START v1.16 - combine gender and attribute check
				-- START v1.7 - check order for gender
				-- START v1.18
				IF (ISNULL(@gender_check,0) <> 0) OR (ISNULL(@attribute,0) <> 0)
				--IF (ISNULL(@gender,'') <> '') OR (ISNULL(@attribute,0) <> 0)
				-- END v1.18
				--IF ISNULL(@gender,'') <> '' 
				BEGIN
					IF @brand_exclude = 'N'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							brand = @brand 
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))
						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE brand = @brand AND gender = @gender
					END
					ELSE
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							brand <> @brand 
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))
						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE brand <> @brand AND gender = @gender
					END
				END
				-- END v1.16
				ELSE
				BEGIN
					SET @gender_found = 1
				END
				-- END v1.7
	
				IF @brand_found > 0 
				BEGIN
					SET @brand_on_order	= 'Y'
				END
				ELSE
				BEGIN
					SET @brand_on_order	= 'N'
				END

				IF @brand_on_order <> @brand_exclude
				BEGIN
					-- START v1.7 - Gender
					IF ISNULL(@gender_found,0) = 0
					BEGIN
						SELECT @achived = 0
						IF @and = 'Y'
						BEGIN
							-- START v1.16
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								--SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required gender (' + UPPER(@gender) + ').'
								-- START v1.18
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
								-- SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								-- END v1.18
							END
							ELSE
							BEGIN
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
							END
							
						END
						ELSE
						BEGIN
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									-- START v1.18
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									--SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									--SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
									-- END v1.18
							END
							ELSE
							BEGIN	
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute.'
							END
							-- END v1.16
						END
					END		
					ELSE
					BEGIN
						SELECT @achived = 1
					END
					-- END v1.7
				END
				ELSE
				BEGIN
					SELECT @achived = 0
					IF @brand_exclude = 'Y'
					BEGIN
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason = 'Order does not qualify for promotion - order contains an excluded brand (' + UPPER(@brand) + ').'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason = 'Order does not qualify for promotion - order contains an excluded brand (' + UPPER(@brand) + ').'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order contains an excluded brand (' + UPPER(@brand) + ').'
						END
					END
					ELSE
					BEGIN
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain a required brand (' + UPPER(@brand) + ').'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain a required brand (' + UPPER(@brand) + ').'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) +  'Order does not qualify for promotion - order does not contain a required brand (' + UPPER(@brand) + ').'
						END
					END
				END
			END
			

			-- Check category only
-- v1.26	IF (LTRIM(RTRIM(ISNULL(@category,''))) <> '') AND (LTRIM(RTRIM(ISNULL(@brand,''))) = '') 
			IF (LTRIM(RTRIM(ISNULL(@category,''))) <> '') AND (LTRIM(RTRIM(ISNULL(@brand,''))) = '' AND @combine = 'N') -- v1.26 
			BEGIN
				-- check if the order contains the category
				SELECT @category_found = COUNT(*) FROM #ord_list WHERE category = @category
				
				-- START v1.16 - combine gender and attribute check
				-- START v1.7 - check order for gender
				-- START v1.18
				IF (ISNULL(@gender_check,0) <> 0) OR (ISNULL(@attribute,0) <> 0)
				--IF (ISNULL(@gender,'') <> '') OR (ISNULL(@attribute,0) <> 0)
				-- END v1.18
				--IF ISNULL(@gender,'') <> '' 
				BEGIN
					IF @category_exclude = 'N'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							category = @category 
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))
						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category = @category AND gender = @gender
					END
					ELSE
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							category <> @category 
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))
						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category <> @category AND gender = @gender
					END
				END
				-- END v1.16
				ELSE
				BEGIN
					SET @gender_found = 1
				END
				-- END v1.7

				IF @category_found > 0 
				BEGIN
					SET @category_on_order	= 'Y'
				END
				ELSE
				BEGIN
					SET @category_on_order	= 'N'
				END
				IF @category_on_order <> @category_exclude
				BEGIN
					-- START v1.7 - Gender
					IF ISNULL(@gender_found,0) = 0
					BEGIN
						SELECT @achived = 0
						IF @and = 'Y'
						BEGIN
							-- START v1.16
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								--SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required gender (' + UPPER(@gender) + ').'
								-- START v1.18
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
								-- SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								-- END v1.18
							END
							ELSE
							BEGIN
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
							END
						END
						ELSE
						BEGIN
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									-- START v1.18
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									--SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									-- SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
									-- END v1.18
							END
							ELSE
							BEGIN	
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute.'
							END
							-- END v1.16
						END
					END	
					ELSE
					BEGIN
						SELECT @achived = 1
					END	
					-- END v1.7
				END
				ELSE
				BEGIN
					SELECT @achived = 0
					IF @category_on_order = 'Y'
					BEGIN
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason = 'Order does not qualify for promotion - order contains an excluded category (' + UPPER(@category) + ').'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason = 'Order does not qualify for promotion - order contains an excluded category (' + UPPER(@category) + ').'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order contains an excluded category (' + UPPER(@category) + ').'
						END
					END
					ELSE
					BEGIN
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain a required category (' + UPPER(@category) + ').'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain a required category (' + UPPER(@category) + ').'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain a required category (' + UPPER(@category) + ').'
						END
					END
				END
			END
					
			-- Check brand/category
-- v1.26	IF (LTRIM(RTRIM(ISNULL(@category,''))) <> '') AND (LTRIM(RTRIM(ISNULL(@brand,''))) <> '') 
			IF (LTRIM(RTRIM(ISNULL(@category,''))) <> '') AND (LTRIM(RTRIM(ISNULL(@brand,''))) <> '' AND @combine = 'N') -- v1.26 
			BEGIN
				-- check if the order contains the combo
				SELECT @combo_found = COUNT(*) FROM #ord_list WHERE category = @category and brand = @brand

				-- START v1.16 - combine gender and attribute check
				-- START v1.7 - check order for gender
				-- START v1.18
				IF (ISNULL(@gender_check,0) <> 0) OR (ISNULL(@attribute,0) <> 0)
				--IF (ISNULL(@gender,'') <> '') OR (ISNULL(@attribute,0) <> 0)
				-- END v1.18
				--IF ISNULL(@gender,'') <> '' 
				BEGIN
					IF @category_exclude = 'N' AND @brand_exclude = 'N'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							brand = @brand 
							AND category = @category
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))

						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category = @category AND brand = @brand AND gender = @gender
					END

					IF @category_exclude = 'N' AND @brand_exclude = 'Y'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							brand <> @brand 
							AND category = @category
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))

						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category = @category AND brand <> @brand AND gender = @gender
					END

					IF @category_exclude = 'Y' AND @brand_exclude = 'N'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							brand = @brand 
							AND category <> @category
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))
						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category <> @category AND brand = @brand AND gender = @gender
					END
				
					IF @category_exclude = 'Y' AND @brand_exclude = 'Y'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							brand <> @brand 
							AND category <> @category
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))

						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category <> @category AND brand <> @brand AND gender = @gender
					END		
				END
				-- END v1.16
				ELSE
				BEGIN
					SET @gender_found = 1
				END
				-- END v1.7

				IF @combo_found > 0 
				BEGIN
					SET @combo_on_order	= 'Y'
				END
				ELSE
				BEGIN
					SET @combo_on_order	= 'N'
				END

				IF (@combo_on_order <> @category_exclude AND @combo_on_order <> @brand_exclude) OR (@combo_on_order = 'N' AND (@category_exclude = 'Y' OR @brand_exclude = 'Y'))
				BEGIN
					-- START v1.7 - Gender
					IF ISNULL(@gender_found,0) = 0
					BEGIN
						SELECT @achived = 0
						IF @and = 'Y'
						BEGIN
							-- START v1.16
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								--SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required gender (' + UPPER(@gender) + ').'
								-- START v1.18
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
								--SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								-- END v1.18
							END
							ELSE
							BEGIN
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
							END	
						END
						ELSE
						BEGIN
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									-- START v1.18
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									--SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									--SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
									-- END v1.18
							END
							ELSE
							BEGIN	
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute.'
							END
							-- END v1.16
						END
					END	
					ELSE
					BEGIN
						SELECT @achived = 1
					END	
					-- END v1.7
				END
				ELSE
				BEGIN
					SELECT @achived = 0
					IF @combo_on_order = 'Y'
					BEGIN
						IF @and = 'Y' 
						BEGIN
							SET @and_fail_reason = 'Order does not qualify for promotion - order contains an excluded brand/category combination.'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason = 'Order does not qualify for promotion - order contains an excluded brand/category combination.'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order contains an excluded brand/category combination.'
						END
					END
					ELSE
					BEGIN
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain a required brand/category combination.'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain a required brand/category combination.'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain a required brand/category combination.'
						END
					END
				END
			END
			
			-- If there is no brand or category 
			IF (LTRIM(RTRIM(ISNULL(@category,''))) = '') AND (LTRIM(RTRIM(ISNULL(@brand,''))) = '') 
			BEGIN
				-- START v1.16 - combine gender and attribute check
				-- START v1.7 - check order for gender
				-- START v1.18
				IF (ISNULL(@gender_check,0) <> 0) OR (ISNULL(@attribute,0) <> 0)
				--IF (ISNULL(@gender,'') <> '') OR (ISNULL(@attribute,0) <> 0)
				-- END v1.18
				--IF ISNULL(@gender,'') <> '' 
				BEGIN
					SELECT 
						@gender_found = COUNT(1) 
					FROM 
						#ord_list 
					WHERE 
						-- START v1.18
						((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																		  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
						--((ISNULL(@gender,'') = '') OR (gender = @gender)) 
						-- END v1.18
						AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																		  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))
						-- SELECT @gender_found = COUNT(1) FROM #ord_list WHERE gender = @gender
				-- END v1.16
					IF ISNULL(@gender_found,0) = 0
					BEGIN
						SELECT @achived = 0
						IF @and = 'Y'
						BEGIN
							-- START v1.16
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								--SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required gender (' + UPPER(@gender) + ').'
								-- START v1.18
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
								--SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								-- END v1.18
							END
							ELSE
							BEGIN
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
							END
						END
						ELSE
						BEGIN
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									-- START v1.18
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									--SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									--SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
									-- END v1.18
							END
							ELSE
							BEGIN	
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute.'
							END
							-- END v1.16
						END
					END		
					ELSE
					BEGIN
						SELECT @achived = 1
					END	
					
				END
				ELSE
				BEGIN
					SET @achived = 1
				END
				-- END v1.7
			END

			-- v1.26 Start Implement Combine
			IF (LTRIM(RTRIM(ISNULL(@category,''))) <> '') AND (LTRIM(RTRIM(ISNULL(@brand,''))) = '' AND @combine = 'Y') -- v1.26 
			BEGIN
				-- check if the order contains the category
				SELECT @category_found = COUNT(*) FROM #ord_list WHERE category IN (
					SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND line_no = @line_no)
				
				-- START v1.16 - combine gender and attribute check
				-- START v1.7 - check order for gender
				-- START v1.18
				IF (ISNULL(@gender_check,0) <> 0) OR (ISNULL(@attribute,0) <> 0)
				--IF (ISNULL(@gender,'') <> '') OR (ISNULL(@attribute,0) <> 0)
				-- END v1.18
				--IF ISNULL(@gender,'') <> '' 
				BEGIN
					IF @category_exclude = 'N'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							category IN (SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND line_no = @line_no) 
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))
						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category = @category AND gender = @gender
					END
					ELSE
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							--category <> @category 
							(category NOT IN (SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND line_no = @line_no))
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))
						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category <> @category AND gender = @gender
					END
				END
				-- END v1.16
				ELSE
				BEGIN
					SET @gender_found = 1
				END
				-- END v1.7

				IF @category_found > 0 
				BEGIN
					SET @category_on_order	= 'Y'
				END
				ELSE
				BEGIN
					SET @category_on_order	= 'N'
				END
				IF @category_on_order <> @category_exclude
				BEGIN
					-- START v1.7 - Gender
					IF ISNULL(@gender_found,0) = 0
					BEGIN
						SELECT @achived = 0
						IF @and = 'Y'
						BEGIN
							-- START v1.16
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								--SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required gender (' + UPPER(@gender) + ').'
								-- START v1.18
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
								-- SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								-- END v1.18
							END
							ELSE
							BEGIN
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
							END
						END
						ELSE
						BEGIN
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									-- START v1.18
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									--SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									-- SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
									-- END v1.18
							END
							ELSE
							BEGIN	
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute.'
							END
							-- END v1.16
						END
					END	
					ELSE
					BEGIN
						SELECT @achived = 1
					END	
					-- END v1.7
				END
				ELSE
				BEGIN
					SELECT @achived = 0
					IF @category_on_order = 'Y'
					BEGIN
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason = 'Order does not qualify for promotion - order contains an excluded category (' + UPPER(@category) + ').'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason = 'Order does not qualify for promotion - order contains an excluded category (' + UPPER(@category) + ').'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order contains an excluded category (' + UPPER(@category) + ').'
						END
					END
					ELSE
					BEGIN
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain a required category (' + UPPER(@category) + ').'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain a required category (' + UPPER(@category) + ').'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain a required category (' + UPPER(@category) + ').'
						END
					END
				END
			END

			IF (LTRIM(RTRIM(ISNULL(@category,''))) <> '') AND (LTRIM(RTRIM(ISNULL(@brand,''))) <> '' AND @combine = 'Y') 
			BEGIN
				-- check if the order contains the combo
				SELECT @combo_found = COUNT(*) FROM #ord_list WHERE brand = @brand AND category IN (
					SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no)

				-- START v1.16 - combine gender and attribute check
				-- START v1.7 - check order for gender
				-- START v1.18
				IF (ISNULL(@gender_check,0) <> 0) OR (ISNULL(@attribute,0) <> 0)
				--IF (ISNULL(@gender,'') <> '') OR (ISNULL(@attribute,0) <> 0)
				-- END v1.18
				--IF ISNULL(@gender,'') <> '' 
				BEGIN
					IF @category_exclude = 'N' AND @brand_exclude = 'N'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							brand = @brand 
							AND category IN (SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no)
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))

						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category = @category AND brand = @brand AND gender = @gender
					END

					IF @category_exclude = 'N' AND @brand_exclude = 'Y'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							brand <> @brand 
							AND category IN (SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no)
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))

						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category = @category AND brand <> @brand AND gender = @gender
					END

					IF @category_exclude = 'Y' AND @brand_exclude = 'N'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							brand = @brand 
							AND category NOT IN (SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no)
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))
						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category <> @category AND brand = @brand AND gender = @gender
					END
				
					IF @category_exclude = 'Y' AND @brand_exclude = 'Y'
					BEGIN
						SELECT 
							@gender_found = COUNT(1) 
						FROM 
							#ord_list 
						WHERE 
							brand <> @brand 
							AND category NOT IN (SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no)
							-- START v1.18
							AND ((ISNULL(@gender_check,0) = 0) OR (gender IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))) 
							--AND ((ISNULL(@gender,'') = '') OR (gender = @gender)) 
							-- END v1.18
							AND ((ISNULL(@attribute,0) = 0) OR (attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O')))

						--SELECT @gender_found = COUNT(1) FROM #ord_list WHERE category <> @category AND brand <> @brand AND gender = @gender
					END		
				END
				-- END v1.16
				ELSE
				BEGIN
					SET @gender_found = 1
				END
				-- END v1.7

				IF @combo_found > 0 
				BEGIN
					SET @combo_on_order	= 'Y'
				END
				ELSE
				BEGIN
					SET @combo_on_order	= 'N'
				END

				IF (@combo_on_order <> @category_exclude AND @combo_on_order <> @brand_exclude) OR (@combo_on_order = 'N' AND (@category_exclude = 'Y' OR @brand_exclude = 'Y'))
				BEGIN
					-- START v1.7 - Gender
					IF ISNULL(@gender_found,0) = 0
					BEGIN
						SELECT @achived = 0
						IF @and = 'Y'
						BEGIN
							-- START v1.16
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								--SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required gender (' + UPPER(@gender) + ').'
								-- START v1.18
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
								--SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								-- END v1.18
							END
							ELSE
							BEGIN
								SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
							END	
						END
						ELSE
						BEGIN
							-- START v1.18
							IF ISNULL(@gender_check,0) <> 0
							--IF ISNULL(@gender,'') <> ''
							-- END v1.18
							BEGIN
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									-- START v1.18
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									--SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender combination.'
									--SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute/gender (' + UPPER(@gender) + ') combination.'
									-- END v1.18
							END
							ELSE
							BEGIN	
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain required attribute.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain required attribute.'
							END
							-- END v1.16
						END
					END	
					ELSE
					BEGIN
						SELECT @achived = 1
					END	
					-- END v1.7
				END
				ELSE
				BEGIN
					SELECT @achived = 0
					IF @combo_on_order = 'Y'
					BEGIN
						IF @and = 'Y' 
						BEGIN
							SET @and_fail_reason = 'Order does not qualify for promotion - order contains an excluded brand/category combination.'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason = 'Order does not qualify for promotion - order contains an excluded brand/category combination.'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order contains an excluded brand/category combination.'
						END
					END
					ELSE
					BEGIN
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason = 'Order does not qualify for promotion - order does not contain a required brand/category combination.'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason = 'Order does not qualify for promotion - order does not contain a required brand/category combination.'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order does not contain a required brand/category combination.'
						END
					END
				END
			END


			-- v1.26 End

			
			/*

			SELECT @brand_found = COUNT(*) FROM #ord_list WHERE brand = @brand
			SELECT @category_found = COUNT(*) FROM #ord_list WHERE category = @category

			IF (LEN(RTRIM(ISNULL(@brand,' '))) = ' ' AND LEN(RTRIM(ISNULL(@category,' '))) = ' ')
				SELECT @qty_only = 1
				GOTO Step_cont

			IF (LEN(RTRIM(@brand))>0 AND LEN(RTRIM(@category))>0)
				IF (@brand_found > 0 AND @category_found > 0)
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						SELECT @achived = 0
						SET @fail_reason = 'Order does not qualify for promotion - order does not contain the correct brand or category.'  -- v1.3
					END
				ELSE
				IF (@brand_found > 0 OR @category_found > 0)
				BEGIN
					SELECT @achived = 1
				END
				ELSE
				BEGIN
					SELECT @achived = 0
					SET	@fail_reason = 'Order does not qualify for promotion - order does not contain the correct brand or category.'  -- v1.3
			END

			IF @brand_exclude = 'Y'
			BEGIN
				IF @brand_found > 0
				BEGIN
					SELECT @achived = 0
					SET @fail_reason = 'Order does not qualify for promotion - order contains incorrect brand.'  -- v1.3
				END
				ELSE
				BEGIN
					SELECT @achived = 1
				END
			END

			IF @category_exclude = 'Y'
			BEGIN
				IF @category_found > 0
				BEGIN
					SELECT @achived = 0
					SET @fail_reason = 'Order does not qualify for promotion - order contains incorrect category.'  -- v1.3
				END
				ELSE
				BEGIN
					SELECT @achived = 1
				END
			END
			
	Step_Cont:
	*/
	-- END v1.5

			--	Does the entered order have a minimum or maximum ordered quantity of the selected brand or category
			SELECT @total_qty_brand = IsNull(SUM(ordered),0) FROM #ord_list WHERE brand = @brand

			-- v1.26 Start
			IF (@combine = 'Y')
			BEGIN
				SELECT @total_qty_categoty = IsNull(SUM(ordered),0) FROM #ord_list WHERE category IN (
					SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no)
			END
			ELSE
			BEGIN
				SELECT @total_qty_categoty = IsNull(SUM(ordered),0) FROM #ord_list WHERE category = @category
			END
			-- v1.26 End

			SELECT @total_qty_all = IsNull(SUM(ordered),0) FROM #ord_list WHERE category IN ('FRAME','SUN')	-- v1.8

			-- v1.26 Start
			IF (@combine = 'Y')
			BEGIN
				SELECT @total_qty_combo = IsNull(SUM(ordered),0) FROM #ord_list WHERE brand = @brand AND category IN (
					SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no)
			END
			ELSE
			BEGIN
				SELECT @total_qty_combo = IsNull(SUM(ordered),0) FROM #ord_list WHERE brand = @brand AND category = @category	-- v1.5
			END
			-- v1.26 End

			IF @achived = 1 OR @qty_only = 1
			BEGIN
				--IF (LEN(RTRIM(ISNULL(@brand,' '))) = ' ' AND LEN(RTRIM(ISNULL(@category,' '))) = ' ')
				IF (LTRIM(RTRIM(ISNULL(@brand,''))) = '' AND LTRIM(RTRIM(ISNULL(@category,''))) = '')		-- v1.5
				BEGIN
					IF (@total_qty_all >= IsNull(@min_qty,0) AND @total_qty_all <= IsNull(@max_qty,999999999))							-- v1.4
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						IF NOT (@and = 'N' AND @achived = 1) -- v1.25 Start
						BEGIN
							SELECT @achived = 0
							-- START v1.5
							IF @and = 'Y'
							BEGIN
								SET @and_fail_reason = 'Order does not qualify for promotion - mimimum/maximum order quantity.'  
							END
							ELSE
							BEGIN
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									SET @or_fail_reason = 'Order does not qualify for promotion - mimimum/maximum order quantity.'  
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - mimimum/maximum order quantity.'  
							END
							-- END v1.5
						END -- v1.25
					END
				END
				ELSE
				--IF (LEN(RTRIM(@brand)) > '' AND LEN(RTRIM(@category)) > '')
				IF (LTRIM(RTRIM(@brand)) > '' AND LTRIM(RTRIM(@category)) > '')	-- v1.5
				BEGIN
					--IF ((@total_qty_brand >= IsNull(@min_qty,0) AND	@total_qty_brand <= IsNull(@max_qty,999999999)) AND													-- TLM
					--	(@total_qty_categoty >= IsNull(@min_qty,0) AND @total_qty_categoty <= IsNull(@max_qty,999999999)))		-- TLM
					IF (@total_qty_combo >= IsNull(@min_qty,0) AND	@total_qty_combo <= IsNull(@max_qty,999999999)) -- v1.5
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						IF NOT (@and = 'N' AND @achived = 1) -- v1.25 Start
						BEGIN
							SELECT @achived = 0
							-- START v1.5
							IF @and = 'Y'
							BEGIN
								SET @and_fail_reason = 'Order does not qualify for promotion - mimimum/maximum ordered quantity of the brand/category combination.'
							END
							ELSE
							BEGIN
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									SET @or_fail_reason = 'Order does not qualify for promotion - mimimum/maximum ordered quantity of the brand/category combination.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - mimimum/maximum ordered quantity of the brand/category combination.'
							END
							-- END v1.5
						END -- v1.25 End
					END
				END
				ELSE
				--IF (LEN(RTRIM(@brand)) > '' OR LEN(RTRIM(@category)) > '')
				IF (LTRIM(RTRIM(@brand)) > '' OR LTRIM(RTRIM(@category)) > '')	-- v1.5
				BEGIN
					IF ((@total_qty_brand >= IsNull(@min_qty,0) AND @total_qty_brand <= IsNull(@max_qty,999999999)) OR	-- TLM												-- TLM
						(@total_qty_categoty >= IsNull(@min_qty,0) AND @total_qty_categoty <= IsNull(@max_qty,999999999)))		-- TLM
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						IF NOT (@and = 'N' AND @achived = 1) -- v1.25 Start
						BEGIN
							SELECT @achived = 0
							-- START v1.5
							IF @and = 'Y'
							BEGIN
								SET @and_fail_reason =  'Order does not qualify for promotion - mimimum/maximum ordered quantity of the brand or category.'
							END
							ELSE
							BEGIN
								IF ISNULL(@or_fail_reason,'') = '' -- v1.11
									SET @or_fail_reason =  'Order does not qualify for promotion - mimimum/maximum ordered quantity of the brand or category.'
								ELSE
									SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - mimimum/maximum ordered quantity of the brand or category.'
							END
							-- END v1.5
						END -- v1.25 End
					END
				END
			END

			--	Does the entered order have at least 2 colores of the selected brand or category.
			IF ( @two_colors = 'Y' AND @achived = 1 )
			BEGIN
				-- START v1.10
				-- Test for 2 colours based on the brand/category settings for the rule
				
				-- Brand Only
				IF ISNULL(@brand,'') <> '' AND ISNULL(@category,'') = ''
				BEGIN
					
					SELECT TOP 1 @brand_found = COUNT(DISTINCT(color)) FROM #ord_list WHERE brand = @brand 
					-- START v1.23
					AND category IN ('FRAME','SUN')
					-- END v1.23
					GROUP BY style ORDER BY COUNT(DISTINCT(color)) ASC -- v1.20 Change from DESC

					IF @brand_found >= 2
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						SELECT @achived = 0
						-- START v1.5
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason =  'Order does not qualify for promotion - order must contain at least two colors for each style of brand ' + UPPER(@brand) + '.'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason =  'Order does not qualify for promotion - order must contain at least two colors for each style of brand ' + UPPER(@brand) + '.'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) +  'Order does not qualify for promotion - order must contain at least two colors for each style of brand ' + UPPER(@brand) + '.'					
						END
						-- END v1.5
					END
				END
				
				-- Category Only
				IF ISNULL(@brand,'') = '' AND ISNULL(@category,'') <> ''
				BEGIN
					-- v1.26 Start
					IF (@combine = 'Y')
					BEGIN
						SELECT TOP 1 @category_found = COUNT(DISTINCT(color)) FROM #ord_list WHERE category IN (
							SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no)
						GROUP BY style ORDER BY COUNT(DISTINCT(color)) ASC -- v1.20 Change from DESC
					END
					ELSE
					BEGIN
						SELECT TOP 1 @category_found = COUNT(DISTINCT(color)) FROM #ord_list WHERE category = @category GROUP BY style ORDER BY COUNT(DISTINCT(color)) ASC -- v1.20 Change from DESC
					END
					-- v1.26 End

					IF @category_found >= 2
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						SELECT @achived = 0
						-- START v1.5
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason =  'Order does not qualify for promotion - order must contain at least two colors for each style of category ' + UPPER(@category) + '.'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason =  'Order does not qualify for promotion - order must contain at least two colors for each style of category ' + UPPER(@category) + '.'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order must contain at least two colors for each style of category ' + UPPER(@category) + '.'
						END
						-- END v1.5
					END
				END	

				-- Category and Brand
				IF ISNULL(@brand,'') <> '' AND ISNULL(@category,'') <> ''
				BEGIN
					SELECT TOP 1 @brand_found = COUNT(DISTINCT(color)) FROM #ord_list WHERE brand = @brand 
					-- START v1.23
					AND category IN ('FRAME','SUN')
					-- END v1.23
					GROUP BY style ORDER BY COUNT(DISTINCT(color)) ASC -- v1.20 Change from DESC
					
					-- v1.26 Start
					IF (@combine = 'Y')
					BEGIN
						SELECT TOP 1 @category_found = COUNT(DISTINCT(color)) FROM #ord_list WHERE category IN (
							SELECT category FROM cvo_promo_order_category (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no)
						GROUP BY style ORDER BY COUNT(DISTINCT(color)) ASC -- v1.20 Change from DESC
					END
					ELSE
					BEGIN
						SELECT TOP 1 @category_found = COUNT(DISTINCT(color)) FROM #ord_list WHERE category = @category GROUP BY style ORDER BY COUNT(DISTINCT(color)) ASC -- v1.20 Change from DESC
					END
					-- v1.26 End
					
					IF (@brand_found >= 2 AND @category_found >= 2)
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						SELECT @achived = 0
						-- START v1.5
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason =  'Order does not qualify for promotion - order must contain at least two colors for each style of the brand/category combination.'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason =  'Order does not qualify for promotion - order must contain at least two colors for each style of the brand/category combination.'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order must contain at least two colors for each style of the brand/category combination.'							
						END
						-- END v1.5
					END
				END	
				
				-- No Category or Brand
				IF ISNULL(@brand,'') = '' AND ISNULL(@category,'') = ''
				BEGIN
					SELECT TOP 1 @brand_found = COUNT(DISTINCT(color)) FROM #ord_list
					-- START v1.23
					WHERE category IN ('FRAME','SUN')
					-- END v1.23
					ORDER BY COUNT(DISTINCT(color)) ASC -- v1.20 Change from DESC
									
					IF @brand_found >= 2
					BEGIN
						SELECT @achived = 1
					END
					ELSE
					BEGIN
						SELECT @achived = 0
						-- START v1.5
						IF @and = 'Y'
						BEGIN
							SET @and_fail_reason =  'Order does not qualify for promotion - order must contain at least two colors for each style.'
						END
						ELSE
						BEGIN
							IF ISNULL(@or_fail_reason,'') = '' -- v1.11
								SET @or_fail_reason =  'Order does not qualify for promotion - order must contain at least two colors for each style.'
							ELSE
								SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order must contain at least two colors for each style.'
						END
						-- END v1.5
					END
				END	
			END
			-- END v1.10	

			-- START v1.17
			-- Check if any frames/suns on order have attributes not defined for qualification line
			IF (ISNULL(@attribute,0) <> 0) AND (@achived = 1)
			BEGIN
				-- v1.24 Start
				--IF EXISTS (SELECT 1 FROM #ord_list WHERE category IN ('FRAME','SUN') AND attribute NOT IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
				--															  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))
				IF NOT EXISTS (SELECT 1 FROM #ord_list WHERE category IN ('FRAME','SUN') AND attribute IN (SELECT attribute FROM dbo.cvo_promotions_attribute (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))
				-- v1.24 End
				BEGIN
					SELECT @achived = 0
					IF @and = 'Y'
					BEGIN
						SET @and_fail_reason =  'Order does not qualify for promotion - order contains excluded attributes.'
					END
					ELSE
					BEGIN
						IF ISNULL(@or_fail_reason,'') = ''
							SET @or_fail_reason =  'Order does not qualify for promotion - order contains excluded attributes.'
						ELSE
							SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order contains excluded attributes.'
					END
				END
			END
			-- END v1.17	

			-- START v1.18
			-- Check if any frames/suns on order have genders not defined for qualification line
			IF (ISNULL(@gender_check,0) <> 0) AND (@achived = 1)
			BEGIN
				IF EXISTS (SELECT 1 FROM #ord_list WHERE category IN ('FRAME','SUN') AND gender NOT IN (SELECT gender FROM dbo.cvo_promotions_gender (NOLOCK) 
																			  WHERE promo_id = @promo_id AND promo_level = @promo_level and line_no = @line_no AND line_type = 'O'))
				BEGIN
					SELECT @achived = 0
					IF @and = 'Y'
					BEGIN
						SET @and_fail_reason =  'Order does not qualify for promotion - order contains excluded genders.'
					END
					ELSE
					BEGIN
						IF ISNULL(@or_fail_reason,'') = '' 
							SET @or_fail_reason =  'Order does not qualify for promotion - order contains excluded genders.'
						ELSE
							SET @or_fail_reason = @or_fail_reason + CHAR(13) + CHAR(10) + 'Order does not qualify for promotion - order contains excluded genders.'
					END
				END
			END
			-- END v1.18							

			-- Verify if conditions were achived	
			IF IsNULL(@achived,0) > 0 
			BEGIN
				UPDATE #cvo_order_qualifications SET rows_found = '1=1'
				WHERE id = @id
			END

			SELECT	@id = MIN(id)
			FROM	#cvo_order_qualifications
			WHERE	id > @id
		END

		-- START v1.18 - code no longer required
		/*
		-- START v1.9 - if promo contains gender then order fails if it contains a gender not on the promo
		IF EXISTS (SELECT 1 FROM #cvo_order_qualifications WHERE ISNULL(gender,'') <> '')
		BEGIN
			-- Loop through genders on order - if any aren't on promo then fail
			SET @gender = ''
			SET @excluded_gender = 0			

			WHILE 1=1
			BEGIN
				SELECT TOP 1
					@gender = ISNULL(gender,'')
				FROM
					#ord_list
				WHERE
					ISNULL(gender,'') > @gender					
				ORDER BY
					gender

				IF @@ROWCOUNT = 0
					Break


				-- Check if gender is on promo
				IF NOT EXISTS (SELECT 1 FROM #cvo_order_qualifications WHERE ISNULL(gender,'') = @gender)
				BEGIN
					SET @excluded_gender = 1

					-- To show this has failed create a #cvo_order_qualifications record
					INSERT INTO #cvo_order_qualifications (
						line_no,
						brand,
						category,
						and_,
						rows_found,
						gender)
					SELECT
						-1,
						'*EXCLUDED*',
						'*GENDER*',
						'Y',
						'0=1',
						@gender

					-- Only store the error message if there isn't already one
					IF ISNULL(@and_fail_reason,'') = ''
					BEGIN
						SET @and_fail_reason =  'Order does not qualify for promotion - order contains an excluded gender (' + UPPER(@gender) + ').'
					END
		
					Break
				END
			END
			-- If ok create a #cvo_order_qualifications record to show this
			IF @excluded_gender = 0
			BEGIN
				INSERT INTO #cvo_order_qualifications (
						line_no,
						brand,
						category,
						and_,
						rows_found,
						gender)
					SELECT
						-1,
						'*EXCLUDED*',
						'*GENDER*',
						'Y',
						'1=1',
						''

			END
		END
		-- END v1.9
		*/
		-- END v1.18

		CREATE TABLE #t(r INT)
		
		/*   -- v1.4
		SELECT @condition = 'IF '
		SELECT @counter = 0

		SELECT	@max = COUNT(*)	FROM #cvo_order_qualifications

		SELECT	@id = MIN(id)
		FROM	#cvo_order_qualifications		

		WHILE (@id IS NOT NULL)
		BEGIN
			SELECT	@rows_found = rows_found, @cond1 = and_, @cond2 = or_
			FROM 	#cvo_order_qualifications
			WHERE	id = @id
			
			SELECT @counter = @counter + 1

			SELECT @condition = @condition + @rows_found 
			
			IF @cond1 = 'Y' AND @counter <> @max
				SELECT @condition = @condition + ' AND '
			ELSE
				IF @cond2 = 'Y' AND @counter <> @max
					SELECT @condition = @condition + ' OR '

			SELECT	@id = MIN(id)
			FROM	#cvo_order_qualifications
			WHERE	id > @id
		END 

		IF @max > 0
			BEGIN
				select @SQL_X = @condition + ' INSERT INTO #t VALUES(1) ELSE INSERT INTO #t VALUES (0)'
				EXEC (@SQL_X)
			END
		ELSE
			BEGIN
				select @SQL_X = 'INSERT INTO #t VALUES (0)'
				EXEC (@SQL_X)
			END
*/
		-- START v1.5 - amended logic (new OR logic statement)
		-- if any ANDs are false then fail
		IF (select count(*) from #cvo_order_qualifications where rows_found = '0=1' and and_ = 'Y') > 0		-- v1.4
		BEGIN																								-- v1.4
			INSERT INTO #t VALUES(0)																		-- v1.4	
			SET @fail_reason = @and_fail_reason																-- v1.5															
		END																									-- v1.4
		ELSE	
		BEGIN	
			-- if at least 1 OR is true then pass															-- v1.4
			IF (select count(*) from #cvo_order_qualifications where rows_found = '1=1' and or_ = 'Y') = 1	-- v1.4
			BEGIN																							-- v1.4
				INSERT INTO #t VALUES(1)																	-- v1.4
				SET @fail_reason = ''																		-- v1.5															
			END																								-- v1.4
			ELSE
			BEGIN	
				-- if all the ORs are false then fail
				IF ((select count(*) from #cvo_order_qualifications where rows_found = '0=1' and or_ = 'Y') <> 0 ) AND
				((select count(*) from #cvo_order_qualifications where rows_found = '0=1' and or_ = 'Y') = (select count(*) from #cvo_order_qualifications where or_ = 'Y'))			
				BEGIN																						-- v1.4
					INSERT INTO #t VALUES(0)																-- v1.4	
					SET @fail_reason = @or_fail_reason														-- v1.5	
				END	
				ELSE																						-- v1.4
				BEGIN																						-- v1.4
					INSERT INTO #t VALUES (1)																-- v1.4
					SET @fail_reason = ''																	-- v1.5
				END	
			END
		END																									-- v1.4

	-- END v1.5

		-- START v1.19
		-- If there are free frame qualification lines which have passed, then hold them in table for later calculation

		-- START v1.21
		DELETE FROM CVO_free_frame_qualified WHERE SPID = @@SPID AND promo_id = @promo_id AND promo_level = @promo_level
		-- END v1.21

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
			promo_level,
			min_qty, -- v1.25
			max_qty, -- v1.25
			combine) -- v1.26
		SELECT DISTINCT -- v1.21
			@@SPID,
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
			@promo_level,
			min_qty, -- v1.25
			max_qty, -- v1.25
			combine -- v1.26
		FROM 
			#cvo_order_qualifications 
		WHERE 
			rows_found = '1=1' 
			AND free_frames = 1
		-- END v1.19

		-- START v1.22 - If promo is a drawdown, then store which line qualifications passed
		IF EXISTS (SELECT 1 FROM dbo.cvo_promotions (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND ISNULL(drawdown_promo,0) = 1)
		BEGIN
			DELETE FROM dbo.CVO_drawdown_promo_qualified_lines WHERE SPID = @@SPID AND promo_id = @promo_id AND promo_level = @promo_level

			INSERT INTO dbo.CVO_drawdown_promo_qualified_lines (
				SPID,
				promo_id,
				promo_level,	
				line_no,
				brand,
				category,
				gender_check,
				attribute,
				brand_exclude,
				category_exclude)
			SELECT DISTINCT 
				@@SPID,
				@promo_id,
				@promo_level,
				line_no,
				brand,
				category,
				gender_check,
				attribute,
				brand_exclude,
				category_exclude
			FROM 
				#cvo_order_qualifications 
			WHERE 
				rows_found = '1=1' 
		END
		-- END v1.22

		-- START v1.15
		IF @sub_check = 0
		BEGIN
			SELECT r as code, CASE r WHEN 0 THEN @fail_reason ELSE '' END as reason FROM #t	-- v1.3
		END
		-- END v1.15
	
	-- for debug
/*	
	SELECT @fail_reason
	SELECT * FROM #cvo_order_qualifications
	SELECT * FROM #ord_list
*/	
		-- START v1.15
		IF @sub_check = 0
		BEGIN
			DELETE FROM CVO_ord_list_temp WHERE order_no = @order_no AND order_ext = @ext
		END
		-- END v1.15

		DROP TABLE #cvo_order_qualifications
		--DROP TABLE #t	-- v1.15
		DROP TABLE #ord_list

		-- START v1.15
		IF @sub_check = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM #t WHERE r = 1)
			BEGIN
				DROP TABLE #t
				RETURN 1
			END
			ELSE
			BEGIN
				DROP TABLE #t
				RETURN 0
			END
		END		-- END v1.15
END

GO
GRANT EXECUTE ON  [dbo].[CVO_verify_order_quali_sp] TO [public]
GO
