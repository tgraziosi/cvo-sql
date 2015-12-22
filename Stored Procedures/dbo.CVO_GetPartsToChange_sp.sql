SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- 3/25/2015 - tag - use new config CF_BY_COLL to select temples

CREATE PROCEDURE  [dbo].[CVO_GetPartsToChange_sp]	@glass	VARCHAR(30),
											@glass_qty  DECIMAL(20, 8) = 0,
											@part_no1 VARCHAR(30), 
											@qty1 DECIMAL(20, 8) = 0,
											@part_no_original_1 VARCHAR(30) = NULL,
											@qty_per_1 DECIMAL(20, 8) = 0,
											@row_1	INT,
											@location VARCHAR(10),
											@part_no2 VARCHAR(30) = NULL,
											@qty2 DECIMAL(20, 8) = 0,
											@part_no_original_2 VARCHAR(30) = NULL,
											@qty_per_2 DECIMAL(20, 8) = 0,
											@row_2	INT,
											@part_no3 VARCHAR(30) = NULL,
											@qty3 DECIMAL(20, 8) = 0,
											@part_no_original_3 VARCHAR(30) = NULL,
											@qty_per_3 DECIMAL(20, 8) = 0,
											@row_3	INT,
											@part_no4 VARCHAR(30) = NULL,
											@qty4 DECIMAL(20, 8) = 0,
											@part_no_original_4 VARCHAR(30) = NULL,
											@qty_per_4 DECIMAL(20, 8) = 0,
											@row_4	INT,
											@part_no5 VARCHAR(30) = NULL,
											@qty5 DECIMAL(20, 8) = 0,
											@part_no_original_5 VARCHAR(30) = NULL,
											@qty_per_5 DECIMAL(20, 8) = 0,
											@row_5	INT,
											@part_no6 VARCHAR(30) = NULL,
											@qty6 DECIMAL(20, 8) = 0,
											@part_no_original_6 VARCHAR(30) = NULL,
											@qty_per_6 DECIMAL(20, 8) = 0,
											@row_6	INT,
											@part_no7 VARCHAR(30) = NULL,
											@qty7 DECIMAL(20, 8) = 0,
											@part_no_original_7 VARCHAR(30) = NULL,
											@qty_per_7 DECIMAL(20, 8) = 0,
											@row_7	INT,
											@part_no8 VARCHAR(30) = NULL,
											@qty8 DECIMAL(20, 8) = 0,
											@part_no_original_8 VARCHAR(30) = NULL,
											@qty_per_8 DECIMAL(20, 8) = 0,
											@row_8	INT,
											@part_no9 VARCHAR(30) = NULL,
											@qty9 DECIMAL(20, 8) = 0,
											@part_no_original_9 VARCHAR(30) = NULL,
											@qty_per_9 DECIMAL(20, 8) = 0,
											@row_9	INT,
											@part_no10 VARCHAR(30) = NULL, 
											@qty10 DECIMAL(20, 8) = 0,
											@part_no_original_10 VARCHAR(30) = NULL,
											@qty_per_10 DECIMAL(20, 8) = 0,
											@row_10	INT,
											@all_styles	SMALLINT = 0, -- v1.3 
											@soft_alloc_no INT  = 0 -- v10.0

AS
											
BEGIN
	DECLARE	@part_no			VARCHAR(30),
			@part_no_o			VARCHAR(30),
			@part_no_temp		VARCHAR(30),
			@brand				VARCHAR(30),
			@brand_glass		VARCHAR(30),
			@part_type			VARCHAR(30),
			@qty				DECIMAL(20, 8),
			@qty_per			DECIMAL(20, 8),
			@qty_in_stock		DECIMAL(20, 8),
			@id_temp			INT,
			@id					INT,
			@there_is_left		INT,
			@there_is_right		INT,
			@show_pairs			INT,
			@row				INT,
			@temples_left_count INT,
			@temples_left_exist	INT,
			@temples_right_count INT,
			@temples_right_exist INT,
			@temples_pair_count	INT,
			@temples_pair_exist	INT,
			@style				VARCHAR(30),	-- v1.2
			@sa_qty				decimal(20,8),	-- v10.0
			@rec_id				INT,			-- v10.2
			@colour				VARCHAR(40),	-- v10.2
			@prev_colour		VARCHAR(40)
			-- 032515
			, @cf_by_coll		varchar(255)

	CREATE TABLE #parts_qts (
		id					INT IDENTITY(1,1),
		part_no				VARCHAR(30),
		qty					DECIMAL(20, 8),
		part_no_original	VARCHAR(30),
		qty_per				DECIMAL(20, 8),
		row					INT
	)
	
	CREATE TABLE #components_parts (
		component			VARCHAR(255),
		part_no				VARCHAR(30),
		new					INT DEFAULT 0,
		part_no_original	VARCHAR(30),
		qty_per				DECIMAL(20, 8),
		row					INT,
		part_type			VARCHAR(100),
		qty					DECIMAL (20, 8)
	)

	CREATE TABLE #components_parts2 (
		id			INT IDENTITY(1,1),
		part_no		VARCHAR(30),
		qty			DECIMAL (20, 8)
	)
	
	-- START v10.2
	-- Create extra temporary tables for new sort
	CREATE TABLE #components_parts_sort (
		rec_id				INT IDENTITY (1,1),
		component			VARCHAR(255),
		part_no				VARCHAR(30),
		new					INT DEFAULT 0,
		part_no_original	VARCHAR(30),
		qty_per				DECIMAL(20, 8),
		row					INT,
		part_type			VARCHAR(100),
		qty					DECIMAL (20, 8),
		style				VARCHAR(10),
		temple				INT,
		colour				VARCHAR(40)	
	)

	CREATE TABLE #output (
		rec_id				INT IDENTITY (1,1),
		component			VARCHAR(255),
		part_no				VARCHAR(30),
		new					INT DEFAULT 0,
		part_no_original	VARCHAR(30),
		qty_per				DECIMAL(20, 8),
		row					INT,
		part_type			VARCHAR(100),
		qty					DECIMAL (20, 8)
	)
	-- END v10.2

	-- v10.0
	CREATE TABLE #sa_qty (
		qty		decimal(20,8))

	INSERT INTO #parts_qts(part_no, qty, part_no_original, qty_per, row)
	SELECT @part_no1, @qty1, @part_no_original_1, @qty_per_1, @row_1

	IF ISNULL(@part_no2, '') <> ''
		INSERT INTO #parts_qts(part_no, qty, part_no_original, qty_per, row)
		SELECT @part_no2, @qty2, @part_no_original_2, @qty_per_2, @row_2

	IF ISNULL(@part_no3, '') <> ''
		INSERT INTO #parts_qts(part_no, qty, part_no_original, qty_per, row)
		SELECT @part_no3, @qty3, @part_no_original_3, @qty_per_3, @row_3

	IF ISNULL(@part_no4, '') <> ''
		INSERT INTO #parts_qts(part_no, qty, part_no_original, qty_per, row)
		SELECT @part_no4, @qty4, @part_no_original_4, @qty_per_4, @row_4

	IF ISNULL(@part_no5, '') <> ''
		INSERT INTO #parts_qts(part_no, qty, part_no_original, qty_per, row)
		SELECT @part_no5, @qty5, @part_no_original_5, @qty_per_5, @row_5

	IF ISNULL(@part_no6, '') <> ''
		INSERT INTO #parts_qts(part_no, qty, part_no_original, qty_per, row)
		SELECT @part_no6, @qty6, @part_no_original_6, @qty_per_6, @row_6

	IF ISNULL(@part_no7, '') <> ''
		INSERT INTO #parts_qts(part_no, qty, part_no_original, qty_per, row)
		SELECT @part_no7, @qty7, @part_no_original_7, @qty_per_7, @row_7

	IF ISNULL(@part_no8, '') <> ''
		INSERT INTO #parts_qts(part_no, qty, part_no_original, qty_per, row)
		SELECT @part_no8, @qty8, @part_no_original_8, @qty_per_8, @row_8

	IF ISNULL(@part_no9, '') <> ''
		INSERT INTO #parts_qts(part_no, qty, part_no_original, qty_per, row)
		SELECT @part_no9, @qty9, @part_no_original_9, @qty_per_9, @row_9

	IF ISNULL(@part_no10, '') <> ''
		INSERT INTO #parts_qts(part_no, qty, part_no_original, qty_per, row)
		SELECT @part_no10, @qty10, @part_no_original_10, @qty_per_10, @row_10

	/*Select the glass' brand*/
	SELECT @brand_glass = i.category
	FROM inv_master i
	WHERE i.part_no = @glass

	-- 032515
	-- check if this brand is to break by collection, or style (default)

	select @cf_by_coll = ISNULL(value_str, '') from config (NOLOCK) where flag = 'CF_BY_COLL'  
	if charindex(@brand_glass, @cf_by_coll) > 0  select @cf_by_coll = @brand_glass


	/* Verify if there are temples right and left to change. if yes, then show pairs. */
	SELECT @there_is_left = 0, @there_is_right = 0

	SELECT	@id_temp = MIN(id)
	FROM	#parts_qts

	WHILE (@id_temp IS NOT NULL)
	BEGIN
		SELECT	@part_no = part_no
		FROM	#parts_qts
		WHERE	id = @id_temp

		SELECT @part_type = ia.category_3,
				@style = ia.field_2 -- v1.2
		FROM inv_master i INNER JOIN inv_master_add ia ON i.part_no = ia.part_no
		WHERE i.part_no = @part_no

		IF @part_type = 'Temple-L'
			SELECT @there_is_left = 1 

		IF @part_type = 'Temple-R'
			SELECT @there_is_right = 1

		SELECT	@id_temp = MIN(id)
		FROM	#parts_qts
		WHERE	id > @id_temp
	END

--  v1.0 Do not show pairs
--	IF @there_is_left = 1 AND @there_is_right = 1
--		SELECT @show_pairs = 1
--	ELSE
		SELECT @show_pairs = 0
	
	/* Insert compatibles parts if there is enough inventory*/
	SELECT	@id_temp = MIN(id)
	FROM	#parts_qts

	WHILE (@id_temp IS NOT NULL)
	BEGIN
		SELECT	@part_no = part_no, @qty = qty, @part_no_o = part_no_original, @qty_per = qty_per, @row = row
		FROM	#parts_qts
		WHERE	id = @id_temp

		SELECT @brand = i.category,  @part_type = ia.category_3
		FROM inv_master i INNER JOIN inv_master_add ia ON i.part_no = ia.part_no
		WHERE i.part_no = @part_no

		IF (@part_type = 'Temple-L' OR  @part_type = 'Temple-R') AND @show_pairs = 1
		BEGIN
			-- START v1.3
			IF @all_styles = 1
-- 032515
			BEGIN
				if @cf_by_coll = @brand
				begin
					INSERT INTO #components_parts2 
					SELECT i.part_no, 0
					FROM inv_master i INNER JOIN inv_master_add ia ON i.part_no = ia.part_no
					WHERE i.part_no <> @part_no AND @brand = i.category 
					AND (@part_type = ia.category_3 OR ia.category_3 = 'Temple-P')
					AND i.void = 'N' -- v10.1
				end
				else
				begin
					INSERT INTO #components_parts2 
					SELECT i.alt_part, 0
					FROM inv_alternates i (NOLOCK)
					JOIN inv_master inv (NOLOCK) -- v10.1
					ON	i.part_no = inv.part_no -- v10.1
					WHERE i.part_no = @part_no 
					AND i.alt_type = 'C'
					AND inv.void = 'N' -- v10.1
				end
-- end 032515
			END
			ELSE
			BEGIN
			-- END v1.3
				INSERT INTO #components_parts2 
				SELECT i.part_no, 0
				FROM inv_master i INNER JOIN inv_master_add ia ON i.part_no = ia.part_no
				WHERE i.part_no <> @part_no AND @brand = i.category AND (@part_type = ia.category_3 OR ia.category_3 = 'Temple-P')
				AND @style = ia.field_2 -- v1.2
				AND i.void = 'N' -- v10.1
			END
		END
		ELSE
		BEGIN
			-- START v1.3
			IF @all_styles = 1
			-- 032515
			BEGIN
				if @cf_by_coll = @brand
				begin
					INSERT INTO #components_parts2 
					SELECT i.part_no, 0
					FROM inv_master i INNER JOIN inv_master_add ia ON i.part_no = ia.part_no
					WHERE i.part_no <> @part_no AND @brand = i.category AND @part_type = ia.category_3
					AND i.void = 'N' -- v10.1
				end
				else
				begin
					INSERT INTO #components_parts2 
					SELECT i.alt_part, 0
					FROM inv_alternates i (NOLOCK)
					JOIN inv_master inv (NOLOCK) -- v10.1
					ON	i.part_no = inv.part_no -- v10.1
					WHERE i.part_no = @part_no 
					AND i.alt_type = 'C'
					AND inv.void = 'N' -- v10.1
				end
				-- 032515
			END
			ELSE
			BEGIN
			-- END v1.3
				INSERT INTO #components_parts2 
				SELECT i.part_no, 0
				FROM inv_master i INNER JOIN inv_master_add ia ON i.part_no = ia.part_no
				WHERE i.part_no <> @part_no AND @brand = i.category AND @part_type = ia.category_3
				AND @style = ia.field_2 -- v1.2
				AND i.void = 'N' -- v10.1
			END
		END

		SELECT @id = MIN(id)
		FROM #components_parts2

		WHILE (@id IS NOT NULL)
		BEGIN
			SELECT	@part_no_temp = part_no
			FROM	#components_parts2
			WHERE	id = @id

			EXEC	CVO_AvailabilityInStock_sp	@part_no_temp, @location, @qty_in_stock OUTPUT

			-- v10.0 Start
			DELETE	#sa_qty 
			INSERT	#sa_qty
			EXEC	dbo.cvo_get_available_stock_sp @soft_alloc_no, @location, @part_no_temp

			SELECT	@sa_qty = qty
			FROM	#sa_qty

			IF @sa_qty IS NULL
				SET @sa_qty = 0

			SET @qty_in_stock = (@qty_in_stock - @sa_qty)
			IF @qty_in_stock < 0
				SET @qty_in_stock = 0
			-- v10.0 End

			UPDATE	#components_parts2 SET qty = @qty_in_stock
			WHERE	id = @id		

			SELECT	@id = MIN(id)
			FROM	#components_parts2
			WHERE	id > @id
		END

		INSERT INTO #components_parts (component, part_no, new, part_no_original, qty_per, row, part_type, qty)
		SELECT	@part_no, c.part_no, 0, @part_no_o, @qty_per, @row, ia.category_3, c.qty
		FROM	#components_parts2 c
		LEFT JOIN inv_master_add ia ON c.part_no = ia.part_no
-- v1.1	WHERE	c.qty >= @qty
		
		DELETE FROM #components_parts2
		
		SELECT	@id_temp = MIN(id)
		FROM	#parts_qts
		WHERE	id > @id_temp
	END

	/*	If temple left and right were selected and there is not inventory neither pairs avaliables.
		System needs to look up glasses for the same brand and show them in the list.
	*/
	IF @show_pairs = 1  --Show_pairs means that user selected temple left and temple right to replace
	BEGIN
		SELECT @temples_left_exist = 0, @temples_right_exist = 0, @temples_pair_exist = 0

		/*Verify if there is temples left*/
		SELECT @temples_left_count = COUNT(*) FROM #components_parts WHERE part_type = 'Temple-L'

		IF @temples_left_count > 0 
			SELECT @temples_left_exist = 1
						
		/*Verify if there is temples rigt*/
		SELECT @temples_right_count = COUNT(*) FROM #components_parts WHERE part_type = 'Temple-R'

		IF @temples_right_count > 0 
			SELECT @temples_right_exist = 1

		/*Verify if there is temples pairs*/
		SELECT @temples_pair_count = COUNT(*) FROM #components_parts WHERE part_type = 'Temple-P'

		IF @temples_pair_count > 0 
			SELECT @temples_pair_exist = 1
		
		IF @temples_left_exist = 0 AND @temples_right_exist = 0 AND @temples_pair_exist = 0
		BEGIN
			DELETE FROM #components_parts2

			INSERT INTO #components_parts2 
			SELECT i.part_no, 0
			FROM inv_master i 
			WHERE i.part_no <> @glass AND i.category = @brand_glass AND (UPPER(i.type_code) in ('FRAME', 'SUN'))

			SELECT @id = MIN(id)
			FROM #components_parts2

			WHILE (@id IS NOT NULL)
			BEGIN
				SELECT	@part_no_temp = part_no
				FROM	#components_parts2
				WHERE	id = @id

				EXEC	CVO_AvailabilityInStock_sp	@part_no_temp, @location, @qty_in_stock OUTPUT

				-- v10.0 Start
				DELETE	#sa_qty 
				INSERT	#sa_qty
				EXEC	dbo.cvo_get_available_stock_sp @soft_alloc_no, @location, @part_no_temp

				SELECT	@sa_qty = qty
				FROM	#sa_qty

				IF @sa_qty IS NULL
					SET @sa_qty = 0

				SET @qty_in_stock = (@qty_in_stock - @sa_qty)
				IF @qty_in_stock < 0
					SET @qty_in_stock = 0
				-- v10.0 End

				UPDATE	#components_parts2 SET qty = @qty_in_stock
				WHERE	id = @id		

				SELECT	@id = MIN(id)
				FROM	#components_parts2
				WHERE	id > @id
			END

			DELETE FROM #components_parts

			INSERT INTO #components_parts (component, part_no, new, part_no_original, qty_per, row, part_type, qty)
			SELECT	'No temples or pairs, you can select a glass...', c.part_no, 0, '', 1, 1, 'GLASS', c.qty
			FROM	#components_parts2 c
			LEFT JOIN inv_master_add ia ON c.part_no = ia.part_no
			WHERE	c.qty >= @glass_qty
			
		END
	END

	-- START v10.2
	-- Load results into sort table sorting by style, temple, colour, part_no
	INSERT INTO #components_parts_sort(
		component,
		part_no,
		new,
		part_no_original,
		qty_per,
		row,
		part_type,
		qty,
		style,
		temple,
		colour)
	SELECT
		a.component,
		a.part_no,
		a.new,
		a.part_no_original,
		a.qty_per,
		a.row,
		a.part_type,
		a.qty,
		b.category,
		CAST(c.field_8 AS INT),
		c.field_3
	FROM
		#components_parts a
	INNER JOIN
		dbo.inv_master b (NOLOCK)
	ON
		a.part_no = b.part_no
	INNER JOIN
		dbo.inv_master_add c (NOLOCK)
	ON
		a.part_no = c.part_no
	ORDER BY
		b.category,
		-- 032515
		c.field_2,
		CAST(c.field_8 AS INT),
		c.field_3,
		a.part_no

	-- Load into final output table, inserting blank lines when colour changes
	SET @rec_id = 0
	SET @colour = ''
	SET @prev_colour = ''

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@colour = colour
		FROM 
			#components_parts_sort
		WHERE
			rec_id > @rec_id
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- If colour has changed insert a blank line
		IF @prev_colour <> '' AND @prev_colour <> @colour
		BEGIN
			INSERT INTO #output(
				component,
				part_no,
				new,
				part_no_original,
				qty_per,
				row,
				part_type,
				qty)
			SELECT
				'',
				'',
				0,
				'',
				0,
				0,
				'BLANK_LINE',
				0	
		END
	
		-- Insert record into output table	
		INSERT INTO #output(
			component,
			part_no,
			new,
			part_no_original,
			qty_per,
			row,
			part_type,
			qty)
		SELECT
			component,
			part_no,
			new,
			part_no_original,
			qty_per,
			row,
			part_type,
			qty
		FROM
			#components_parts_sort
		WHERE
			rec_id = @rec_id

		SET @prev_colour = @colour
	END

	/*Show list*/
	--SELECT component, part_no, new, part_no_original, qty_per, row, part_type, qty FROM #components_parts
	SELECT component, part_no, new, part_no_original, qty_per, row, part_type, qty FROM #output ORDER BY rec_id 	

	DROP TABLE #components_parts_sort
	DROP TABLE #output
	-- END v10.2

	DROP TABLE #components_parts
	DROP TABLE #components_parts2
	
END
GO
GRANT EXECUTE ON  [dbo].[CVO_GetPartsToChange_sp] TO [public]
GO
