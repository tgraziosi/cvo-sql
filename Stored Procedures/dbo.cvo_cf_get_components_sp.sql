SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_cf_get_components_sp] @user_spid int,
										 @custom_kit int,
										 @soft_alloc_no int
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@row_id				int,
			@last_row_id		int,
			@component_type		varchar(20),
			@orig_component		varchar(30),
			@required_qty		decimal(20,8),
			@location			varchar(10),
			@order_part_type	varchar(5),
			@order_part_no		varchar(30),
			@line_no			int,
			@category			varchar(20),
			@style				varchar(30),
			@attribute			varchar(30),
			@alternate_done		int,
			@qty_in_stock		decimal(20,8),
			@sa_qty				decimal(20,8),
			@colour				varchar(40),
			@prev_colour		varchar(40),
			@order_by			int,
			@last_component		varchar(20),
			@orig_row			int

	-- WORKING TABLES
	CREATE TABLE #data_in (
		row_id			int IDENTITY(1,1),
		location		varchar(10),
		order_part_type	varchar(5),
		order_part_no	varchar(30),
		line_no			int,
		orig_row		int,
		component_type	varchar(20),
		orig_component	varchar(30),
		required_qty	decimal(20,8),
		category		varchar(20),
		attribute		varchar(20),
		style			varchar(30),
		show_all_styles	int)

	CREATE TABLE #cvo_cf_process_select (
		row_id			int IDENTITY(1,1),
		user_spid		int,
		location		varchar(10),	
		order_part_type	varchar(5),
		order_part_no	varchar(30),	
		line_no			int,
		orig_row		int,
		component_type	varchar(20) NULL,
		orig_component	varchar(30) NULL,
		repl_component	varchar(30) NULL,
		comp_desc		varchar(100) NULL,
		required_qty	decimal(20,8),
		available_qty	decimal(20,8) NULL,
		attribute		varchar(20) NULL,
		category		varchar(20) NULL,
		style			varchar(30) NULL,
		show_all_styles	int NULL,
		all_type		int NULL,
		colour			varchar(40) NULL,
		size_code		varchar(20) NULL,
		selected		int NULL)

	CREATE TABLE #cvo_cf_process_select_order (
		row_id			int IDENTITY(1,1),
		user_spid		int,
		location		varchar(10),	
		order_part_type	varchar(5),
		order_part_no	varchar(30),	
		line_no			int,
		orig_row		int,
		component_type	varchar(20) NULL,
		orig_component	varchar(30) NULL,
		repl_component	varchar(30) NULL,
		comp_desc		varchar(100) NULL,
		required_qty	decimal(20,8),
		available_qty	decimal(20,8) NULL,
		attribute		varchar(20) NULL,
		category		varchar(20) NULL,
		style			varchar(30) NULL,
		show_all_styles	int NULL,
		all_type		int NULL,
		colour			varchar(40) NULL,
		size_code		varchar(20) NULL,
		selected		int NULL)

	-- v1.1 Start
	CREATE TABLE #available_stock (
		location	varchar(10),
		part_no		varchar(30),
		qty			decimal(20,8))

	CREATE TABLE #excluded_bins (
		location	varchar(10),
		part_no		varchar(30),
		qty			decimal(20,8))

	CREATE TABLE #allocated_qty (
		location	varchar(10),
		part_no		varchar(30),
		qty			decimal(20,8))

	CREATE TABLE #quarantined_qty (
		location	varchar(10),
		part_no		varchar(30),
		qty			decimal(20,8))

	CREATE TABLE #sa_allocated_qty (
		location	varchar(10),
		part_no		varchar(30),
		qty			decimal(20,8))

	CREATE TABLE #sa_allocated_qty2 (
		location	varchar(10),
		part_no		varchar(30),
		qty			decimal(20,8))

--	CREATE TABLE #sa_qty (
--		qty		decimal(20,8))
	-- v1.1 End

	-- PROCESSING
	IF (@custom_kit = 0)
	BEGIN
		INSERT	#data_in (location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, required_qty, category, style, attribute)
		SELECT	a.location, a.order_part_type, a.order_part_no, a.line_no, a.orig_row, b.category_3, a.orig_component, a.required_qty, c.category, b.field_2, 
				CASE WHEN UPPER(ISNULL(b.field_32,'')) = 'NONE' THEN '' ELSE ISNULL(b.field_32,'') END
		FROM	cvo_cf_process_select a (NOLOCK)
		JOIN	inv_master_add b (NOLOCK)
		ON		a.orig_component = b.part_no
		JOIN	inv_master c (NOLOCK)
		ON		a.orig_component = c.part_no
		JOIN	category_3 d (NOLOCK)
		ON		b.category_3 = d.category_code
		WHERE	a.user_spid = @user_spid
		AND		d.cf_process = 'Y'
		AND		d.void = 'N'

		DELETE	cvo_cf_process_select
		WHERE	user_spid = @user_spid

		CREATE INDEX #data_in_ind0 ON #data_in(row_id)
	
		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@location = location,
				@order_part_type = @order_part_type,
				@order_part_no = order_part_no,
				@line_no = line_no,
				@orig_row = orig_row,
				@component_type = component_type,
				@orig_component = orig_component,
				@required_qty = required_qty,
				@category = category,
				@style = UPPER(style),
				@attribute = attribute
		FROM	#data_in
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN
			
			IF (@attribute <> '')
			BEGIN
			-- #1 Insert standard replacement components
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, 
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, @component_type, @orig_component,
						b.part_no, a.description, @required_qty, 0, ISNULL(b.field_32,''), @category, @style, 0, 0, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				WHERE	a.category = @category
				AND		b.category_3 = @component_type
				AND		UPPER(b.field_2) = @style
				AND		a.part_no <> @orig_component
				AND		a.void = 'N'
				AND		b.field_32 = @attribute

				-- v1.7 Start
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, 
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, @component_type, @orig_component,
						b.part_no, a.description, @required_qty, 0, ISNULL(b.field_32,''), a.category, b.field_2, 1, 1, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				LEFT JOIN #cvo_cf_process_select e
				ON		a.part_no = e.repl_component
				WHERE	a.category = @category
				AND		b.category_3 = @component_type
				AND		UPPER(b.field_2) <> @style
				AND		a.part_no <> @orig_component
				AND		a.void = 'N'
				AND		b.field_32 = @attribute
				-- v1.7 End

			END
			ELSE
			BEGIN							
				-- #1 Insert standard replacement components
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, 
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, @component_type, @orig_component,
						b.part_no, a.description, @required_qty, 0, ISNULL(b.field_32,''), @category, @style, 0, 0, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				WHERE	a.category = @category
				AND		b.category_3 = @component_type
				AND		UPPER(b.field_2) = @style
				AND		a.part_no <> @orig_component
				AND		a.void = 'N'
			END
			-- #2 For all style Option 
			-- Check if attribute restriction at part level
			SET @alternate_done = 0
			IF EXISTS (SELECT 1 FROM cvo_alternate_attributes (NOLOCK) WHERE part_no = @order_part_no)
			BEGIN
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc,
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, @component_type, @orig_component,
						b.part_no, a.description, @required_qty, 0, ISNULL(b.field_32,''), a.category, b.field_2, 1, 1, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				JOIN	cvo_alternate_attributes c (NOLOCK)
				ON		b.field_32 = c.attributes
				LEFT JOIN #cvo_cf_process_select e
				ON		a.part_no = e.repl_component
				WHERE	b.category_3 = @component_type
				AND		c.part_no = @order_part_no	
				AND		a.part_no <> @orig_component
				AND		a.void = 'N'
				AND		e.repl_component IS NULL
			
				SET @alternate_done = 1

			END

			IF (@alternate_done = 0)
			BEGIN

				SELECT	@attribute = ISNULL(field_32,'')
				FROM	inv_master_add (NOLOCK)
				WHERE	part_no = @order_part_no

				-- Check if attribute restriction at attribute level only if no part restriction
				IF EXISTS (SELECT 1 FROM cvo_alternate_attributes (NOLOCK) WHERE attribute_key = @attribute)
				BEGIN
					INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc,
								required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
					SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, @component_type, @orig_component,
							b.part_no, a.description, @required_qty, 0, ISNULL(b.field_32,''), a.category, b.field_2, 1, 2, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0
					FROM	inv_master a (NOLOCK)
					JOIN	inv_master_add b (NOLOCK)
					ON		a.part_no = b.part_no
					JOIN	cvo_alternate_attributes c (NOLOCK)
					ON		b.field_32 = c.attributes
					LEFT JOIN #cvo_cf_process_select e -- v1.3
					ON		a.part_no = e.repl_component -- v1.3
					WHERE	b.category_3 = @component_type
					AND		c.attribute_key = @attribute
					AND		a.part_no <> @orig_component
					AND		a.void = 'N'
					AND		e.repl_component IS NULL -- v1.3

					SET @alternate_done = 1
				END
			END

			IF (@alternate_done = 0)
			BEGIN
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc,
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, @component_type, @orig_component,
						b.part_no, a.description, @required_qty, 0, ISNULL(b.field_32,''), a.category, b.field_2, 1, 3, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				JOIN	inv_alternates i (NOLOCK)
				ON		a.part_no = i.alt_part
				LEFT JOIN #cvo_cf_process_select e -- v1.3
				ON		a.part_no = e.repl_component -- v1.3
				WHERE	b.category_3 = @component_type
				AND		a.part_no <> @orig_component
				AND		i.part_no = @orig_component	
				AND		a.void = 'N'
				AND		i.alt_type = 'C'	
				AND		e.repl_component IS NULL -- v1.3
			END

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@location = location,
					@order_part_type = @order_part_type,
					@order_part_no = order_part_no,
					@line_no = line_no,
					@orig_row = orig_row, 
					@component_type = component_type,
					@orig_component = orig_component,
					@required_qty = required_qty,
					@category = category,
					@style = UPPER(style),
					@attribute = attribute
			FROM	#data_in
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

		END

		CREATE INDEX #cvo_cf_process_select_ind0 ON #cvo_cf_process_select(row_id)

		-- v1.1 Start
		CREATE INDEX #cvo_cf_process_select_ind2 ON #cvo_cf_process_select(location, orig_component)

		INSERT	#excluded_bins
		SELECT	a.location, a.part_no, a.qty     
		FROM	dbo.f_get_excluded_bins(1) a
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component

		INSERT	#available_stock
		SELECT	a.location, a.part_no, (a.in_stock - ISNULL(b.qty,0))
		FROM	cvo_inventory2 a (NOLOCK)
		LEFT JOIN #excluded_bins b
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component

		INSERT	#allocated_qty
		SELECT	a.location, a.part_no, SUM(qty)
		FROM	tdc_soft_alloc_tbl a (NOLOCK)
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component
		GROUP BY a.location, a.part_no

		UPDATE	a
		SET		qty = a.qty - b.qty
		FROM	#available_stock a
		JOIN	#allocated_qty b
		ON		a.location = b.location
		AND		a.part_no = b.part_no

		INSERT	#quarantined_qty
		SELECT	a.location, a.part_no, SUM(a.qty)
		FROM	lot_bin_stock a (NOLOCK)
		JOIN	tdc_bin_master b (NOLOCK)  
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component
		WHERE	b.usage_type_code = 'QUARANTINE'
		GROUP BY a.location, a.part_no 


		UPDATE	a
		SET		qty = a.qty - b.qty
		FROM	#available_stock a
		JOIN	#quarantined_qty b
		ON		a.location = b.location
		AND		a.part_no = b.part_no

		INSERT	#sa_allocated_qty
		SELECT	a.location, a.part_no, SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN CASE WHEN a.deleted = 1 THEN (ISNULL((b.qty),0) * -1) ELSE ISNULL((b.qty),0) END ELSE 0 END)
		FROM	dbo.cvo_soft_alloc_det a (NOLOCK)  
		LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b  
		ON		a.order_no = b.order_no  
		AND		a.order_ext = b.order_ext  
		AND		a.part_no = b.part_no  
		AND		a.line_no = b.line_no  
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component
		WHERE	a.status IN (0, 1)  
		AND		a.soft_alloc_no = @soft_alloc_no
		GROUP BY a.location, a.part_no

		UPDATE	a
		SET		qty = a.qty - b.qty
		FROM	#available_stock a
		JOIN	#sa_allocated_qty b
		ON		a.location = b.location
		AND		a.part_no = b.part_no

		INSERT	#sa_allocated_qty2
		SELECT	a.location, a.part_no, SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN ISNULL((b.qty),0) ELSE 0 END)
		FROM	dbo.cvo_soft_alloc_det a (NOLOCK)  
		LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b  
		ON		a.order_no = b.order_no  
		AND		a.order_ext = b.order_ext  
		AND		a.part_no = b.part_no  
		AND		a.line_no = b.line_no  
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component
		WHERE	a.status NOT IN (-2,-3)
		AND		a.soft_alloc_no < @soft_alloc_no
		GROUP BY a.location, a.part_no

		UPDATE	a
		SET		qty = a.qty - b.qty
		FROM	#available_stock a
		JOIN	#sa_allocated_qty2 b
		ON		a.location = b.location
		AND		a.part_no = b.part_no

		UPDATE	a
		SET		available_qty = b.qty
		FROM	#cvo_cf_process_select a
		JOIN	#available_stock b
		ON		a.location = b.location
		AND		a.repl_component = b.part_no

/*
		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@location = location,
				@orig_component = repl_component
		FROM	#cvo_cf_process_select
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN		
			SET @qty_in_stock = 0
			SET @sa_qty = 0

			EXEC CVO_AvailabilityInStock_sp	@orig_component, @location, @qty_in_stock OUTPUT

			DELETE	#sa_qty 

			INSERT	#sa_qty
			EXEC	dbo.cvo_get_available_stock_sp @soft_alloc_no, @location, @orig_component

			SELECT	@sa_qty = qty
			FROM	#sa_qty

			IF (@sa_qty IS NULL)
				SET @sa_qty = 0

			SET @qty_in_stock = (@qty_in_stock - @sa_qty)
			IF @qty_in_stock < 0
				SET @qty_in_stock = 0

			UPDATE	#cvo_cf_process_select 
			SET		available_qty = @qty_in_stock
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@location = location,
					@orig_component = repl_component
			FROM	#cvo_cf_process_select
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		END
*/
		-- v1.1 End
	END

	IF (@custom_kit = 1)
	BEGIN

		INSERT	#data_in (location, order_part_type, order_part_no, line_no, orig_row, component_type, required_qty, category, style, attribute)
		SELECT	a.location, a.order_part_type, a.order_part_no, a.line_no, a.orig_row, b.category_3, a.required_qty, c.category, b.field_2, 
				CASE WHEN UPPER(ISNULL(b.field_32,'')) = 'NONE' THEN '' ELSE ISNULL(b.field_32,'') END
		FROM	cvo_cf_process_select a (NOLOCK)
		JOIN	inv_master_add b (NOLOCK)
		ON		a.order_part_no = b.part_no
		JOIN	inv_master c (NOLOCK)
		ON		a.order_part_no = c.part_no
		WHERE	a.user_spid = @user_spid

		DELETE	cvo_cf_process_select
		WHERE	user_spid = @user_spid
	
		CREATE INDEX #data_in_ind2 ON #data_in(row_id)

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@location = location,
				@order_part_type = @order_part_type,
				@order_part_no = order_part_no,
				@line_no = line_no,
				@orig_row = orig_row,  
				@component_type = component_type,
				@orig_component = orig_component,
				@required_qty = required_qty,
				@category = category,
				@style = UPPER(style),
				@attribute = attribute
		FROM	#data_in
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			IF (@attribute <> '')
			BEGIN
				-- #1 Insert standard replacement components
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc,
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, b.category_3, '',
						b.part_no, a.description, e.qty, 0, ISNULL(b.field_32,''), @category, @style, 0, 0, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				JOIN	category_3 d (NOLOCK)
				ON		b.category_3 = d.category_code
				JOIN	cvo_cf_required_parts e (NOLOCK)
				ON		b.category_3 = e.part_type
				WHERE	a.category = @category
				-- v1.2 AND		b.field_2 = @style
				AND		((UPPER(b.field_2) = @style AND d.style_ind = 'N') OR d.style_ind = 'Y') -- v1.2
				AND		a.void = 'N'
				AND		d.cf_process = 'Y'
				AND		d.void = 'N'
				AND		e.part_no = @order_part_no
				AND		((b.field_32 = @attribute AND d.style_ind = 'N') OR d.style_ind = 'Y') -- v1.6				
				-- v1.6 AND		b.field_32 = @attribute
						
				-- #1.5 Insert standard replacement components - Optional
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc,
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, b.category_3, '',
						b.part_no, a.description, 0, 0, ISNULL(b.field_32,''), @category, @style, 0, 0, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				JOIN	category_3 d (NOLOCK)
				ON		b.category_3 = d.category_code
				LEFT JOIN #cvo_cf_process_select c
				ON		b.part_no = c.repl_component
				WHERE	a.category = @category
				-- v1.2 AND		b.field_2 = @style
				AND		((UPPER(b.field_2) = @style AND d.style_ind = 'N') OR d.style_ind = 'Y') -- v1.2
				AND		a.void = 'N'
				AND		d.cf_process = 'Y'
				AND		d.void = 'N'
				AND		c.repl_component IS NULL
				AND		((b.field_32 = @attribute AND d.style_ind = 'N') OR d.style_ind = 'Y') -- v1.6				
				-- v1.6 AND		b.field_32 = @attribute
			END
			ELSE
			BEGIN
				-- #1 Insert standard replacement components
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc,
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, b.category_3, '',
						b.part_no, a.description, e.qty, 0, ISNULL(b.field_32,''), @category, @style, 0, 0, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				JOIN	category_3 d (NOLOCK)
				ON		b.category_3 = d.category_code
				JOIN	cvo_cf_required_parts e (NOLOCK)
				ON		b.category_3 = e.part_type
				WHERE	a.category = @category
				-- v1.2 AND		b.field_2 = @style
				AND		((UPPER(b.field_2) = @style AND d.style_ind = 'N') OR d.style_ind = 'Y') -- v1.2
				AND		a.void = 'N'
				AND		d.cf_process = 'Y'
				AND		d.void = 'N'
				AND		e.part_no = @order_part_no
						
				-- #1.5 Insert standard replacement components - Optional
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc,
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, b.category_3, '',
						b.part_no, a.description, 0, 0, ISNULL(b.field_32,''), @category, @style, 0, 0, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				JOIN	category_3 d (NOLOCK)
				ON		b.category_3 = d.category_code
				LEFT JOIN #cvo_cf_process_select c
				ON		b.part_no = c.repl_component
				WHERE	a.category = @category
				-- v1.2 AND		b.field_2 = @style
				AND		((UPPER(b.field_2) = @style AND d.style_ind = 'N') OR d.style_ind = 'Y') -- v1.2
				AND		a.void = 'N'
				AND		d.cf_process = 'Y'
				AND		d.void = 'N'
				AND		c.repl_component IS NULL
			END

			-- #2 For all style Option 
			-- Check if attribute restriction at part level
			SET @alternate_done = 0
			IF EXISTS (SELECT 1 FROM cvo_alternate_attributes (NOLOCK) WHERE part_no = @order_part_no)
			BEGIN
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, 
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, b.category_3, '',
						b.part_no, a.description, e.qty, 0, ISNULL(b.field_32,''), a.category, b.field_2, 1, 1, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0 -- v1.5
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				JOIN	cvo_alternate_attributes c (NOLOCK)
				ON		b.field_32 = c.attributes
				JOIN	category_3 d (NOLOCK)
				ON		b.category_3 = d.category_code
				JOIN	cvo_cf_required_parts e (NOLOCK)
				ON		b.category_3 = e.part_type
				LEFT JOIN #cvo_cf_process_select f -- v1.3
				ON		a.part_no = f.repl_component -- v1.3
				WHERE	c.part_no = @order_part_no	
				AND		a.void = 'N'
				AND		d.cf_process = 'Y'
				AND		d.void = 'N'
				AND		e.part_no = @order_part_no
				AND		f.repl_component IS NULL -- v1.3

				-- v1.8 Start	
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, 
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, b.category_3, '',
						b.part_no, a.description, 0, 0, ISNULL(b.field_32,''), a.category, b.field_2, 1, 1, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0 -- v1.5
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				JOIN	cvo_alternate_attributes c (NOLOCK)
				ON		b.field_32 = c.attributes
				JOIN	category_3 d (NOLOCK)
				ON		b.category_3 = d.category_code
				LEFT JOIN #cvo_cf_process_select f -- v1.3
				ON		a.part_no = f.repl_component -- v1.3
				WHERE	c.part_no = @order_part_no	
				AND		a.void = 'N'
				AND		d.cf_process = 'Y'
				AND		d.void = 'N'
				AND		f.repl_component IS NULL -- v1.3
				-- v1.8 End

			
				SET @alternate_done = 1

			END

			IF (@alternate_done = 0)
			BEGIN

				SELECT	@attribute = ISNULL(field_32,'')
				FROM	inv_master_add (NOLOCK)
				WHERE	part_no = @order_part_no

				-- Check if attribute restriction at attribute level only if no part restriction
				IF EXISTS (SELECT 1 FROM cvo_alternate_attributes (NOLOCK) WHERE attribute_key = @attribute)
				BEGIN
					INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, 
								required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
					SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, b.category_3, '',
							b.part_no, a.description, e.qty, 0, ISNULL(b.field_32,''), a.category, b.field_2, 1, 2, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0 -- v1.5
					FROM	inv_master a (NOLOCK)
					JOIN	inv_master_add b (NOLOCK)
					ON		a.part_no = b.part_no
					JOIN	cvo_alternate_attributes c (NOLOCK)
					ON		b.field_32 = c.attributes
					JOIN	category_3 d (NOLOCK)
					ON		b.category_3 = d.category_code
					JOIN	cvo_cf_required_parts e (NOLOCK)
					ON		b.category_3 = e.part_type
					LEFT JOIN #cvo_cf_process_select f -- v1.3
					ON		a.part_no = f.repl_component -- v1.3
					WHERE	c.attribute_key = @attribute
					AND		a.void = 'N'
					AND		d.cf_process = 'Y'
					AND		d.void = 'N'
					AND		e.part_no = @order_part_no
					AND		f.repl_component IS NULL -- v1.3
			
					-- v1.8 Start
					INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, 
								required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
					SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, b.category_3, '',
							b.part_no, a.description, e.qty, 0, ISNULL(b.field_32,''), a.category, b.field_2, 1, 2, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0 -- v1.5
					FROM	inv_master a (NOLOCK)
					JOIN	inv_master_add b (NOLOCK)
					ON		a.part_no = b.part_no
					JOIN	cvo_alternate_attributes c (NOLOCK)
					ON		b.field_32 = c.attributes
					JOIN	category_3 d (NOLOCK)
					ON		b.category_3 = d.category_code
					LEFT JOIN #cvo_cf_process_select f -- v1.3
					ON		a.part_no = f.repl_component -- v1.3
					WHERE	c.attribute_key = @attribute
					AND		a.void = 'N'
					AND		d.cf_process = 'Y'
					AND		d.void = 'N'
					AND		f.repl_component IS NULL -- v1.3
					-- v1.8 End

					SET @alternate_done = 1
				END
			END

			IF (@alternate_done = 0)
			BEGIN
				INSERT	#cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, 
							required_qty, available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
				SELECT	@user_spid, @location, @order_part_type, @order_part_no, @line_no, @orig_row, b.category_3, '',
						b.part_no, a.description, e.qty, 0, ISNULL(b.field_32,''), a.category, b.field_2, 1, 3, ISNULL(b.field_3,''), ISNULL(b.field_8,''), 0 -- v1.5
				FROM	inv_master a (NOLOCK)
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				JOIN	inv_alternates i (NOLOCK)
				ON		a.part_no = i.alt_part
				JOIN	category_3 d (NOLOCK)
				ON		b.category_3 = d.category_code
				JOIN	cvo_cf_required_parts e (NOLOCK)
				ON		b.category_3 = e.part_type
				JOIN	#cvo_cf_process_select f
				ON		f.repl_component = i.part_no
				WHERE	a.void = 'N'
				AND		i.alt_type = 'C'
				AND		d.cf_process = 'Y'
				AND		d.void = 'N'
				AND		e.part_no = @order_part_no
			END

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@location = location,
					@order_part_type = @order_part_type,
					@order_part_no = order_part_no,
					@line_no = line_no,
					@orig_row = orig_row,  
					@component_type = component_type,
					@orig_component = orig_component,
					@required_qty = required_qty,
					@category = category,
					@style = UPPER(style),
					@attribute = attribute
			FROM	#data_in
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

		END

		CREATE INDEX #cvo_cf_process_select_ind2 ON #cvo_cf_process_select(row_id)

		-- v1.1 Start
		CREATE INDEX #cvo_cf_process_select_ind3 ON #cvo_cf_process_select(location, orig_component)

		INSERT	#excluded_bins
		SELECT	a.location, a.part_no, a.qty     
		FROM	dbo.f_get_excluded_bins(1) a
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component

		INSERT	#available_stock
		SELECT	a.location, a.part_no, (a.in_stock - ISNULL(b.qty,0))
		FROM	cvo_inventory2 a (NOLOCK)
		LEFT JOIN #excluded_bins b
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component

		INSERT	#allocated_qty
		SELECT	a.location, a.part_no, SUM(qty)
		FROM	tdc_soft_alloc_tbl a (NOLOCK)
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component
		GROUP BY a.location, a.part_no

		UPDATE	a
		SET		qty = a.qty - b.qty
		FROM	#available_stock a
		JOIN	#allocated_qty b
		ON		a.location = b.location
		AND		a.part_no = b.part_no

		INSERT	#quarantined_qty
		SELECT	a.location, a.part_no, SUM(a.qty)
		FROM	lot_bin_stock a (NOLOCK)
		JOIN	tdc_bin_master b (NOLOCK)  
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component
		WHERE	b.usage_type_code = 'QUARANTINE'
		GROUP BY a.location, a.part_no 


		UPDATE	a
		SET		qty = a.qty - b.qty
		FROM	#available_stock a
		JOIN	#quarantined_qty b
		ON		a.location = b.location
		AND		a.part_no = b.part_no

		INSERT	#sa_allocated_qty
		SELECT	a.location, a.part_no, SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN CASE WHEN a.deleted = 1 THEN (ISNULL((b.qty),0) * -1) ELSE ISNULL((b.qty),0) END ELSE 0 END)
		FROM	dbo.cvo_soft_alloc_det a (NOLOCK)  
		LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b  
		ON		a.order_no = b.order_no  
		AND		a.order_ext = b.order_ext  
		AND		a.part_no = b.part_no  
		AND		a.line_no = b.line_no  
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component
		WHERE	a.status IN (0, 1)  
		AND		a.soft_alloc_no = @soft_alloc_no
		GROUP BY a.location, a.part_no

		UPDATE	a
		SET		qty = a.qty - b.qty
		FROM	#available_stock a
		JOIN	#sa_allocated_qty b
		ON		a.location = b.location
		AND		a.part_no = b.part_no

		INSERT	#sa_allocated_qty2
		SELECT	a.location, a.part_no, SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN ISNULL((b.qty),0) ELSE 0 END)
		FROM	dbo.cvo_soft_alloc_det a (NOLOCK)  
		LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b  
		ON		a.order_no = b.order_no  
		AND		a.order_ext = b.order_ext  
		AND		a.part_no = b.part_no  
		AND		a.line_no = b.line_no  
		JOIN	#cvo_cf_process_select c
		ON		a.location = c.location
		AND		a.part_no = c.repl_component
		WHERE	a.status NOT IN (-2,-3)
		AND		a.soft_alloc_no < @soft_alloc_no
		GROUP BY a.location, a.part_no

		UPDATE	a
		SET		qty = a.qty - b.qty
		FROM	#available_stock a
		JOIN	#sa_allocated_qty2 b
		ON		a.location = b.location
		AND		a.part_no = b.part_no

		UPDATE	a
		SET		available_qty = b.qty
		FROM	#cvo_cf_process_select a
		JOIN	#available_stock b
		ON		a.location = b.location
		AND		a.repl_component = b.part_no
/*
		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@location = location,
				@orig_component = repl_component
		FROM	#cvo_cf_process_select
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN		
			SET @qty_in_stock = 0
			SET @sa_qty = 0

			EXEC CVO_AvailabilityInStock_sp	@orig_component, @location, @qty_in_stock OUTPUT

			DELETE	#sa_qty 

			INSERT	#sa_qty
			EXEC	dbo.cvo_get_available_stock_sp @soft_alloc_no, @location, @orig_component

			SELECT	@sa_qty = qty
			FROM	#sa_qty

			IF (@sa_qty IS NULL)
				SET @sa_qty = 0

			SET @qty_in_stock = (@qty_in_stock - @sa_qty)
			IF @qty_in_stock < 0
				SET @qty_in_stock = 0

			UPDATE	#cvo_cf_process_select 
			SET		available_qty = @qty_in_stock
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@location = location,
					@orig_component = repl_component
			FROM	#cvo_cf_process_select
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		END
*/
		-- v1.1 End
	END

	CREATE TABLE #cf_set_req (
		component_type	varchar(20),
		req_qty			decimal(20,8))

	INSERT	#cf_set_req
	SELECT	component_type, MAX(required_qty)
	FROM	#cvo_cf_process_select
	GROUP BY component_type

	UPDATE	a
	SET		required_qty = b.req_qty
	FROM	#cvo_cf_process_select a
	JOIN	#cf_set_req b
	ON		a.component_type = b.component_type
	WHERE	a.required_qty <> b.req_qty

	DROP TABLE #cf_set_req

	INSERT	#cvo_cf_process_select_order (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, required_qty, 
				available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected)
	SELECT	user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, required_qty, 
			available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, selected 
	FROM	#cvo_cf_process_select
	ORDER BY show_all_styles, category, style, size_code, colour, repl_component -- v1.4
-- v1.4ORDER BY category, style, size_code, colour, repl_component

	CREATE INDEX #cvo_cf_process_select_order_ind1 ON #cvo_cf_process_select_order(row_id)

	SET @last_row_id = 0
	SET @prev_colour = ''
	SET @order_by = 0
	SET @last_component = ''

	SELECT	TOP 1 @row_id = row_id,
			@colour = colour,
-- v1.1		@component_type = CASE WHEN LEFT(component_type,7) = 'TEMPLE-' THEN 'TEMPLE-' ELSE component_type END
			@component_type = CASE WHEN (component_type = 'TEMPLE-L' OR component_type = 'TEMPLE-R') THEN 'TEMPLE' ELSE component_type END -- v1.1
	FROM	#cvo_cf_process_select_order		
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		IF (@prev_colour <> '' AND @prev_colour <> @colour AND @component_type = @last_component)
		BEGIN
			INSERT	dbo.cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, required_qty, 
						available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, order_by, selected)
			SELECT	@user_spid, '', '', 'BLANK_LINE', 0, 0, @component_type, '', '', '', 0, 0, '', '', '', 0, 0, '', '', @order_by, 0

			SET @order_by = @order_by + 1

		END

		INSERT	dbo.cvo_cf_process_select (user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, required_qty, 
					available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, order_by, selected)
		SELECT	user_spid, location, order_part_type, order_part_no, line_no, orig_row, component_type, orig_component, repl_component, comp_desc, required_qty, 
					available_qty, attribute, category, style, show_all_styles, all_type, colour, size_code, @order_by, selected
		FROM	#cvo_cf_process_select_order
		WHERE	row_id = @row_id

		SET @order_by = @order_by + 1
		SET @prev_colour = @colour

		SET @last_component = @component_type

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@colour = colour,
-- v1.1			@component_type = CASE WHEN LEFT(component_type,7) = 'TEMPLE-' THEN 'TEMPLE-' ELSE component_type END
				@component_type = CASE WHEN (component_type = 'TEMPLE-L' OR component_type = 'TEMPLE-R') THEN 'TEMPLE' ELSE component_type END -- v1.1
		FROM	#cvo_cf_process_select_order		
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END
	
	DROP TABLE #cvo_cf_process_select
	DROP TABLE #cvo_cf_process_select_order
	DROP TABLE #data_in
	-- v1.1 Start
	--DROP TABLE #sa_qty
	DROP TABLE #available_stock 
	DROP TABLE #excluded_bins 
	DROP TABLE #allocated_qty
	DROP TABLE #quarantined_qty 
	DROP TABLE #sa_allocated_qty 
	DROP TABLE #sa_allocated_qty2 
	-- v1.1 End

	SELECT	* 
	FROM	cvo_cf_process_select 
	WHERE	user_spid = @user_spid
	ORDER BY order_by

END
GO
GRANT EXECUTE ON  [dbo].[cvo_cf_get_components_sp] TO [public]
GO
