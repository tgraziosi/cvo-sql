SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1	CT	24/06/2013 - Issue #695 - Don't select void transactions
-- v1.2 CT	25/06/2013 - Issue #695 - Template flag for whether transfers are processed
-- v1.3 CT	12/07/2013 - Issue #695 - Return all parts, not just FRAME/SUN
-- v1.4 CT	15/07/2013 - Issue #695 - Part filter change - only return order lines containing part filter parts
-- v1.5 CT	12/09/2013 - Issue #695 - Exclude orders with a priority of 3
-- v1.6 CT	29/11/2013 - Issue #1406 - Don't update order details pulled in if there is a processed record and an allocate error record
-- v1.7 CT	24/01/2014 - Issue #1406 - Don't include orders with status of A
-- v1.8 CT	19/03/2014 - Issue #1443 - New allocated figures in summary header
-- v1.9 CT	25/06/2014 - Issue #1487 - Don't reinsert records marked as processed.
-- v1.10 CT 19/02/2015 - Issue #1530 - Only include frames and suns in ST/RX header summary 
-- v1.11 CT 10/03/2015 - Issue #1536 - Add summary header figures for transfers
-- v1.12 CT 10/03/2015 - Issue #1536 - When calculating summary header figures, include non ST/RX order figures with ST orders
-- v1.13 CT 10/03/2015 - Issue #1530 - Fix summary header when no frames or suns returned	
-- tag - 041415 - add isnull on select where on priority

-- EXEC cvo_backorder_processing_select_sp 'POTEST1'
CREATE PROC [dbo].[cvo_backorder_processing_select_sp] (@template_code VARCHAR(30))
AS
BEGIN
	DECLARE @location			VARCHAR(10),
			@sch_ship_from		DATETIME,
			@sch_ship_to		DATETIME,
			@so_priority		VARCHAR(1),
			@customer_type		VARCHAR(40),
			@no_of_orders		INT,
			@include_cr_hold	SMALLINT,
			@min_crossdock		INT,
			@rec_id				INT,
			@base_rec_id		INT,
			@order_no			INT,
			@ext				INT,
			@line_no			INT,
			@part_no			VARCHAR(30),
			@type				CHAR(1),
			@allocated			DECIMAL(20,8),
			@stock_allocated	DECIMAL(20,8),
			@po_allocated		DECIMAL(20,8),
			@process			SMALLINT,
			@processed			SMALLINT,
			@stock_locked		SMALLINT,
			@po_locked			SMALLINT,
			@available			DECIMAL(20,8),
			@po_available		DECIMAL(20,8),
			@include_xfer		SMALLINT, -- v1.2
			@update_line		SMALLINT -- v1.6

	-- Load template info
	SELECT
		@location = location,
		@sch_ship_from = sch_ship_from,
		@sch_ship_to = sch_ship_to,
		@so_priority = so_priority,
		@customer_type = customer_type,
		@no_of_orders = no_of_orders,
		@include_cr_hold = include_cr_hold,
		@min_crossdock = min_crossdock,
		@include_xfer = include_xfer -- v1.2
	FROM 
		dbo.CVO_backorder_processing_templates (NOLOCK)
	WHERE 
		template_code = @template_code

	IF @@ROWCOUNT <> 1
	BEGIN
		RETURN
	END

	IF ISNULL(@so_priority,'') = ' '
	BEGIN
		SET @so_priority = NULL
	END
	
	-- Check if orders already exist for this template, 
	-- if so store the orders which have processing against them 
	-- and then clear the table for this template
	CREATE TABLE #backup_orders(
		rec_id			INT IDENTITY (1,1),
		template_code	VARCHAR(30),
		order_no		INT,
		ext				INT,
		line_no			INT,
		part_no			VARCHAR(30),
		location		VARCHAR(10),
		qty				DECIMAL(20,8),
		order_type		VARCHAR(10),
		so_priority		VARCHAR(1),
		[type]			CHAR(1),
		customer		VARCHAR(8),
		customer_name	VARCHAR(40),
		ship_date		DATETIME,
		customer_type	VARCHAR(40),
		promo_id		VARCHAR(20),
		promo_level		VARCHAR(30),
		available		DECIMAL(20,8),
		po_available	DECIMAL(20,8),
		allocated		DECIMAL(20,8),
		stock_allocated	DECIMAL(20,8),
		po_allocated	DECIMAL(20,8),
		process			SMALLINT,
		processed		SMALLINT,
		tran_type_sort	SMALLINT,
		order_type_sort	SMALLINT,
		priority_sort	SMALLINT,
		backorder_sort	SMALLINT,
		stock_locked	SMALLINT,
		po_locked		SMALLINT)

	IF EXISTS(SELECT 1 FROM dbo.CVO_backorder_processing_orders WHERE template_code = @template_code)
	BEGIN
		INSERT INTO #backup_orders(
			template_code,
			order_no,
			ext,
			line_no,
			part_no,
			location,
			qty,
			order_type,
			so_priority,
			[type],
			customer,
			customer_name,
			ship_date,
			customer_type,
			promo_id,
			promo_level,
			available,
			po_available,
			allocated,
			stock_allocated,
			po_allocated,
			process,
			processed,
			tran_type_sort,
			order_type_sort,
			priority_sort,
			backorder_sort,
			stock_locked,
			po_locked)
		SELECT 
			template_code,
			order_no,
			ext,
			line_no,
			part_no,
			location,
			qty,
			order_type,
			so_priority,
			[type],
			customer,
			customer_name,
			ship_date,
			customer_type,
			promo_id,
			promo_level,
			available,
			po_available,
			allocated,
			stock_allocated,
			po_allocated,
			process,
			processed,
			tran_type_sort,
			order_type_sort,
			priority_sort,
			backorder_sort,
			stock_locked,
			po_locked 
		FROM 
			dbo.CVO_backorder_processing_orders  (NOLOCK)
		WHERE 
			template_code = @template_code
			AND (ISNULL(processed,0) <> 0 OR ISNULL(process,0) = 1 OR ISNULL(allocated,0) > 0)

		-- START v1.9
		DELETE FROM #backup_orders WHERE processed = 1
		-- END v1.9

		DELETE FROM dbo.CVO_backorder_processing_orders WHERE template_code = @template_code
	END

	-- Order statuses
	CREATE TABLE #order_status (
		stat CHAR(1))

	INSERT INTO #order_status SELECT 'N'
	-- START v1.7
	--INSERT INTO #order_status SELECT 'A'
	-- END v1.7

	IF ISNULL(@include_cr_hold,0) = 1
	BEGIN
		INSERT INTO #order_status SELECT 'C'
	END

	-- Create working table
	CREATE TABLE #backorders(
		order_no		INT,
		ext				INT,
		line_no			INT,
		part_no			VARCHAR(30),
		location		VARCHAR(10),
		qty				DECIMAL(20,8),
		order_type		VARCHAR(10),
		so_priority		VARCHAR(1),
		tran_type_sort	SMALLINT,
		order_type_sort	SMALLINT,
		priority_sort	SMALLINT,
		backorder_sort	SMALLINT,
		[type]			CHAR(1),
		customer		VARCHAR(8),
		customer_name	VARCHAR(40),
		ship_date		DATETIME,
		customer_type	VARCHAR(40))

	-- Create working table
	CREATE TABLE #orders_selected(
		rec_id			INT IDENTITY(1,1),
		order_no		INT,
		ext				INT,
		line_no			INT, -- v1.4
		tran_type_sort	SMALLINT,
		order_type_sort	SMALLINT,
		priority_sort	SMALLINT,
		backorder_sort	SMALLINT,
		[type]			CHAR(1))

	-- Load orders into table
	INSERT INTO #backorders(
		order_no,
		ext,
		line_no,
		part_no,
		location,
		qty,
		order_type,
		so_priority,
		tran_type_sort,
		order_type_sort,
		priority_sort,
		backorder_sort,
		[type],
		customer,
		customer_name,
		ship_date,
		customer_type)
	SELECT 
		a.order_no,
		a.ext,
		b.line_no,
		b.part_no,
		a.location,
		b.ordered - (b.shipped + ISNULL(e.qty,0)) AS qty,
		a.user_category order_type,
		ISNULL(a.so_priority_code,''),
		0 AS tran_type_sort, -- 0 = SO, 1 = XFER 
		CASE LEFT(a.user_category,2) 
			WHEN 'RX' THEN 0 
			WHEN 'ST' THEN 1 
			ELSE 2 
		END AS order_type_sort,
		CASE ISNULL(a.so_priority_code,'')
			WHEN '1' THEN 1
			WHEN '2' THEN 2
			WHEN '3' THEN 3
			WHEN '4' THEN 4
			WHEN '5' THEN 5
			WHEN '6' THEN 6
			WHEN '7' THEN 7
			WHEN '8' THEN 8
			ELSE 9
		END AS priority_sort,
		CASE a.who_entered
			WHEN 'BACKORDR' THEN 1
			ELSE 0
		END AS backorder_sort,
		'I',
		a.cust_code,
		d.address_name,
		a.sch_ship_date,
		d.addr_sort1
	FROM 
		dbo.orders_all a (NOLOCK)
	INNER JOIN
		dbo.ord_list b (NOLOCK)
	ON	
		a.order_no = b.order_no
		AND a.ext = b.order_ext
	INNER JOIN
		#order_status c
	ON
		a.[status] = c.stat 
	INNER JOIN
		dbo.armaster_all d (NOLOCK)
	ON
		a.cust_code = d.customer_code
	LEFT JOIN
		dbo.cvo_hard_allocated_vw e (NOLOCK)
	ON
		b.order_no = e.order_no
		AND b.order_ext = e.order_ext
		AND b.line_no = e.line_no
		AND e.order_type = 'S'
	INNER JOIN
		dbo.inv_master f (NOLOCK)
	ON
		b.part_no = f.part_no
	INNER JOIN
		dbo.cvo_ord_list g (NOLOCK)
	ON	
		b.order_no = g.order_no
		AND b.order_ext = g.order_ext
		AND b.line_no = g.line_no
	WHERE
		a.type = 'I'
		AND ISNULL(a.void,'N') = 'N' -- v1.1
		AND b.ordered > (b.shipped + ISNULL(e.qty,0))
		AND d.address_type = 0
		-- START v1.3
		--AND f.type_code IN ('FRAME','SUN')
		-- END v1.3
		AND g.is_customized = 'N'
		AND b.part_type = 'P'
		AND NOT (a.status = 'A' AND a.hold_reason IN (SELECT hold_code FROM dbo.cvo_hold_reason_no_autoalloc (NOLOCK))) -- don't include non allocatable hold reasons
		-- Template criteria
		AND a.location = @location
		AND (@sch_ship_from IS NULL OR a.sch_ship_date >= @sch_ship_from)
		AND (@sch_ship_to IS NULL OR a.sch_ship_date <= @sch_ship_to)
		AND (ISNULL(@so_priority,'') = '' OR a.so_priority_code = @so_priority)
		AND (ISNULL(@customer_type,'') = '' OR d.addr_sort1 = @customer_type)
		-- START v1.5
		-- tag 041415
		AND isnull(a.so_priority_code,'') <> '3'
		-- END v1.5

	-- Remove orders which don't match criteria's order type filter
	IF EXISTS (SELECT 1 FROM dbo.CVO_backorder_processing_template_order_types (NOLOCK) WHERE template_code = @template_code)
	BEGIN
		DELETE FROM
			#backorders
		WHERE
			order_type NOT IN (SELECT order_type FROM dbo.CVO_backorder_processing_template_order_types (NOLOCK) 
									WHERE template_code = @template_code)
	END

	-- START v1.2
	IF ISNULL(@include_xfer,0) = 1
	BEGIN
		-- Load transfers
		INSERT INTO #backorders(
			order_no,
			ext,
			line_no,
			part_no,
			location,
			qty,
			order_type,
			so_priority,
			tran_type_sort,
			order_type_sort,
			priority_sort,
			backorder_sort,
			[type],
			customer,
			customer_name,
			ship_date,
			customer_type)
		SELECT 
			a.xfer_no,
			-1,
			b.line_no,
			b.part_no,
			a.from_loc,
			b.ordered - (b.shipped + ISNULL(c.qty,0)) AS qty,
			'XFER' order_type,
			'',
			1 AS tran_type_sort, -- 0 = SO, 1 = XFER 
			0 AS order_type_sort,
			0 AS priority_sort,
			0 AS backorder_sort,
			'X',
			NULL,
			NULL,
			a.sch_ship_date,
			NULL
		FROM 
			dbo.xfers_all a (NOLOCK)
		INNER JOIN
			dbo.xfer_list b (NOLOCK)
		ON	
			a.xfer_no = b.xfer_no
		LEFT JOIN
			dbo.cvo_hard_allocated_vw c (NOLOCK)
		ON
			b.xfer_no = c.order_no
			AND b.line_no = c.line_no
			AND c.order_type = 'T'
		INNER JOIN
			dbo.inv_master d (NOLOCK)
		ON
			b.part_no = d.part_no 
		WHERE
			b.ordered > (b.shipped + ISNULL(c.qty,0))
			AND a.[status] <> 'V' -- v1.1
			-- START v1.3
			--AND d.type_code IN ('FRAME','SUN')
			-- END v1.3
			-- Template criteria
			AND a.from_loc = @location
			AND (@sch_ship_from IS NULL OR a.sch_ship_date >= @sch_ship_from)
			AND (@sch_ship_to IS NULL OR a.sch_ship_date <= DATEADD(d,1,@sch_ship_to))  -- xfers hold time as well so roll on date to next day
	END
	-- END v1.2

	-- Remove order/transfer lines which are fully allocated on other templates
	DELETE FROM
		#backorders 
	FROM
		#backorders a 
	INNER JOIN
		dbo.CVO_backorder_processing_orders b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.ext
		AND a.line_no = b.line_no
		AND a.[type] = b.[type]
	WHERE
		b.template_code <> @template_code
		AND b.qty = b.allocated

	-- Update order/transfer lines which are partially allocated on other templates
	UPDATE
		#backorders 
	SET
		qty = a.qty - b.allocated
	FROM
		#backorders a 
	INNER JOIN
		dbo.CVO_backorder_processing_orders b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.ext
		AND a.line_no = b.line_no
		AND a.[type] = b.[type]
	WHERE
		b.template_code <> @template_code
		AND b.qty <> b.allocated
		AND b.allocated > 0
		AND processed = 0


	-- Only select orders/transfers which match criteria's part filters
	IF EXISTS (SELECT 1 FROM dbo.CVO_backorder_processing_template_part_filter (NOLOCK) WHERE template_code = @template_code)
	BEGIN

		-- Get the list of orders/transfers which contain the parts
		INSERT INTO #orders_selected(
			order_no,
			ext,
			line_no, -- v1.4 
			tran_type_sort,
			backorder_sort,
			order_type_sort,
			priority_sort,
			[type])
		SELECT DISTINCT
			order_no,
			ext,
			line_no, -- v1.4 
			tran_type_sort,
			backorder_sort,
			order_type_sort,
			priority_sort,
			[type]
		FROM
			#backorders
		WHERE
			part_no IN (SELECT part_no FROM dbo.CVO_backorder_processing_template_part_filter (NOLOCK) 
									WHERE template_code = @template_code)
		ORDER BY
			tran_type_sort,
			backorder_sort,
			order_type_sort,
			priority_sort,
			order_no,
			ext
	END
	ELSE	
	BEGIN
		INSERT INTO #orders_selected(
			order_no,
			ext,
			line_no, -- v1.4 
			tran_type_sort,
			backorder_sort,
			order_type_sort,
			priority_sort,
			[type])
		SELECT DISTINCT
			order_no,
			ext,
			line_no, -- v1.4 
			tran_type_sort,
			backorder_sort,
			order_type_sort,
			priority_sort,
			[type]
		FROM
			#backorders
		ORDER BY
			tran_type_sort,
			backorder_sort,
			order_type_sort,
			priority_sort,
			order_no,
			ext
	END

	-- Load results into CVO_backorder_processing_orders
	-- If template has a max number of orders, only return that number
	IF ISNULL(@no_of_orders,0) <> 0
	BEGIN
		INSERT INTO CVO_backorder_processing_orders (
			template_code,
			display_order,
			order_no,
			ext,
			line_no,
			part_no,
			location,
			qty,
			order_type,
			so_priority,
			[type],
			customer,
			customer_name,
			ship_date,
			customer_type,
			promo_id,
			promo_level,
			available,
			po_available,
			allocated,
			stock_allocated,
			po_allocated,
			process,
			processed,
			tran_type_sort,
			order_type_sort,
			priority_sort,
			backorder_sort,
			stock_locked,
			po_locked,
			is_available)
		SELECT
			@template_code,
			a.rec_id,
			b.order_no,
			b.ext,
			b.line_no,
			b.part_no,
			b.location,
			b.qty,
			b.order_type,
			b.so_priority,
			b.[type],
			ISNULL(b.customer,''),
			b.customer_name,
			b.ship_date,
			b.customer_type,
			c.promo_id,
			c.promo_level,
			0,
			0,
			0,
			0,
			0,
			0,
			0,
			b.tran_type_sort,
			b.order_type_sort,
			b.priority_sort,
			b.backorder_sort,
			0,
			0,
			0
		FROM
			#orders_selected a
		INNER JOIN
			#backorders b
		ON
			a.order_no = b.order_no
			AND a.ext = b.ext
			AND a.line_no = b.line_no -- v1.4
			AND a.[type] = b.type
		LEFT JOIN
			dbo.cvo_orders_all c (NOLOCK)
		ON
			a.order_no = c.order_no
			AND a.ext = c.ext
		WHERE
			a.rec_id <= @no_of_orders
		ORDER BY
			a.rec_id
		
	END
	ELSE
	BEGIN
		INSERT INTO CVO_backorder_processing_orders (
			template_code,
			display_order,
			order_no,
			ext,
			line_no,
			part_no,
			location,
			qty,
			order_type,
			so_priority,
			[type],
			customer,
			customer_name,
			ship_date,
			customer_type,
			promo_id,
			promo_level,
			available,
			po_available,
			allocated,
			stock_allocated,
			po_allocated,
			process,
			processed,
			tran_type_sort,
			order_type_sort,
			priority_sort,
			backorder_sort,
			stock_locked,
			po_locked,
			is_available)
		SELECT
			@template_code,
			a.rec_id,
			b.order_no,
			b.ext,
			b.line_no,
			b.part_no,
			b.location,
			b.qty,
			b.order_type,
			b.so_priority,
			b.[type],
			ISNULL(b.customer,''),
			b.customer_name,
			b.ship_date,
			b.customer_type,
			c.promo_id,
			c.promo_level,
			0,
			0,
			0,
			0,
			0,
			0,
			0,
			b.tran_type_sort,
			b.order_type_sort,
			b.priority_sort,
			b.backorder_sort,
			0,
			0,
			0
		FROM
			#orders_selected a
		INNER JOIN
			#backorders b
		ON
			a.order_no = b.order_no
			AND a.ext = b.ext
			AND a.line_no = b.line_no -- v1.4
			AND a.[type] = b.type
		LEFT JOIN
			dbo.cvo_orders_all c (NOLOCK)
		ON
			a.order_no = c.order_no
			AND a.ext = c.ext
		ORDER BY
			a.rec_id
	END

	-- If there are any records backed up then update the current records
	IF EXISTS (SELECT 1 FROM #backup_orders)
	BEGIN
		SET @rec_id = 0

		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@rec_id = rec_id,
				@order_no = order_no,	
				@ext = ext,
				@line_no = line_no,
				@part_no = part_no,
				@type = [type],
				@allocated = allocated,
				@stock_allocated = stock_allocated,
				@po_allocated = po_allocated,
				@process = process,
				@processed = processed,
				@stock_locked = stock_locked,
				@po_locked = po_locked,
				@available = available,
				@po_available = po_available
			FROM
				#backup_orders
			WHERE
				rec_id > @rec_id
			ORDER BY
				rec_id

			IF @@ROWCOUNT = 0
				BREAK

			SET @base_rec_id = NULL

			SELECT 
				@base_rec_id = rec_id 
			FROM 
				dbo.CVO_backorder_processing_orders (NOLOCK)	
			WHERE 
				template_code = @template_code 
				AND order_no = @order_no
				AND ext = @ext
				AND line_no = @line_no
				AND [type] = @type
				AND part_no = @part_no



			-- Update records where the original is marked as processed/to process
			IF ISNULL(@base_rec_id,0) <> 0 --AND @processed = 0
			BEGIN

				-- START v1.6
				-- If the existing record shows as processed, but is also in the allocatione error table
				-- then don't update the new record, as this will need to be reallocated if possible
				SET @update_line = 1 -- true
				IF @processed = 1
				BEGIN
					IF EXISTS (SELECT 1 FROM dbo.CVO_backorder_processing_allocation_issues (NOLOCK) WHERE template_code = @template_code AND order_no = @order_no 
									AND ext = @ext AND line_no = @line_no)	
					BEGIN
						SET @update_line = 0 -- False
					END
				END

				IF @update_line = 1
				BEGIN					
				-- END v1.6
					UPDATE
						dbo.CVO_backorder_processing_orders
					SET
						allocated = @allocated,
						stock_allocated = @stock_allocated,
						po_allocated = @po_allocated,
						process = @process,
						processed = @processed,
						stock_locked = @stock_locked,
						po_locked = @po_locked,
						available = @available,
						po_available = @po_available
					WHERE
						rec_id = @base_rec_id
				-- START v1.6
				END 
				-- END v1.6
			END
			ELSE
			BEGIN
				-- If the record has already been processed then insert it.
				IF @processed <> 0
				BEGIN

					INSERT INTO	dbo.CVO_backorder_processing_orders(
						template_code,
						display_order,
						order_no,
						ext,
						line_no,
						part_no,
						location,
						qty,
						order_type,
						so_priority,
						[type],
						customer,
						customer_name,
						ship_date,
						customer_type,
						promo_id,
						promo_level,
						available,
						po_available,
						allocated,
						stock_allocated,
						po_allocated,
						process,
						processed,
						tran_type_sort,
						order_type_sort,
						priority_sort,
						backorder_sort,
						stock_locked,
						po_locked,
						is_available)
					SELECT
						template_code,
						0,
						order_no,
						ext,
						line_no,
						part_no,
						location,
						qty,
						order_type,
						so_priority,
						[type],
						customer,
						customer_name,
						ship_date,
						customer_type,
						promo_id,
						promo_level,
						available,
						po_available,
						allocated,
						stock_allocated,
						po_allocated,
						process,
						processed,
						tran_type_sort,
						order_type_sort,
						priority_sort,
						backorder_sort,
						stock_locked,
						po_locked,
						1
					FROM
						#backup_orders
					WHERE
						rec_id = @rec_id

				END
			END
		END
	END

	-- Apply stock
	EXEC dbo.cvo_backorder_processing_stock_sp @template_code

	-- Clear out existing summary info
	DELETE dbo.CVO_backorder_processing_summary_hdr WHERE template_code = @template_code
	DELETE dbo.CVO_backorder_processing_summary_det WHERE template_code = @template_code

	-- Write summary information
	-- 1. Header
	INSERT INTO CVO_backorder_processing_summary_hdr(
		template_code,
		total_backorders,
		rx_backorders,
		st_backorders,
		-- START v1.8
		total_allocated,
		rx_allocated,
		st_allocated,
		-- END v1.8
		-- START v1.11
		xfer_backorders,
		xfer_allocated,
		-- END v1.11
		has_assignments)
	-- START v1.10
	SELECT
		a.template_code,
		SUM(a.qty),
		SUM(CASE LEFT(a.order_type,2) WHEN 'RX' THEN a.qty ELSE 0 END),
		-- START v1.12
		SUM(CASE a.[type] WHEN 'I' THEN (CASE LEFT(a.order_type,2) WHEN 'ST' THEN a.qty WHEN 'RX' THEN 0 ELSE a.qty END) ELSE 0 END),
		--SUM(CASE LEFT(a.order_type,2) WHEN 'ST' THEN a.qty ELSE 0 END),
		-- END v1.12
		-- START v1.8
		SUM(a.allocated),
		SUM(CASE LEFT(a.order_type,2) WHEN 'RX' THEN a.allocated ELSE 0 END),
		-- START v1.12
		SUM(CASE a.[type] WHEN 'I' THEN (CASE LEFT(a.order_type,2) WHEN 'ST' THEN a.allocated WHEN 'RX' THEN 0 ELSE a.allocated END) ELSE 0 END),
		--SUM(CASE LEFT(a.order_type,2) WHEN 'ST' THEN a.allocated ELSE 0 END),
		-- END v1.12
		-- END v1.8
		-- START v1.11
		SUM(CASE a.order_type WHEN 'XFER' THEN a.qty ELSE 0 END),
		SUM(CASE a.order_type WHEN 'XFER' THEN a.allocated ELSE 0 END),
		-- END v1.11
		0 
	FROM
		dbo.CVO_backorder_processing_orders a (NOLOCK)
	INNER JOIN
		dbo.inv_master b (NOLOCK)
	ON
		a.part_no = b.part_no
	WHERE
		a.template_code = @template_code
		AND a.processed = 0
		AND b.type_code IN ('FRAME','SUN')
	GROUP BY
		a.template_code

	-- START v1.13
	IF EXISTS (SELECT 1 FROM dbo.CVO_backorder_processing_orders (NOLOCK) WHERE template_code = @template_code AND processed = 0)
	BEGIN
		-- If there are no FRAMES/SUNS returned then the summary header table will be empty, write zero record
		IF NOT EXISTS (SELECT 1 FROM dbo.CVO_backorder_processing_summary_hdr (NOLOCK) WHERE template_code = @template_code)
		BEGIN
			INSERT INTO CVO_backorder_processing_summary_hdr(
			template_code,
			total_backorders,
			rx_backorders,
			st_backorders,
			total_allocated,
			rx_allocated,
			st_allocated,
			xfer_backorders,
			xfer_allocated,
			has_assignments)
		SELECT
			@template_code,
			0,
			0,
			0,
			0,
			0,
			0,
			0,
			0,
			0
		END
	END
	-- END v1.13


	/*
	SELECT
		template_code,
		SUM(qty),
		SUM(CASE LEFT(order_type,2) WHEN 'RX' THEN qty ELSE 0 END),
		SUM(CASE LEFT(order_type,2) WHEN 'ST' THEN qty ELSE 0 END),
		-- START v1.8
		SUM(allocated),
		SUM(CASE LEFT(order_type,2) WHEN 'RX' THEN allocated ELSE 0 END),
		SUM(CASE LEFT(order_type,2) WHEN 'ST' THEN allocated ELSE 0 END),
		-- END v1.8
		0 
	FROM
		dbo.CVO_backorder_processing_orders (NOLOCK)
	WHERE
		template_code = @template_code
		AND processed = 0
	GROUP BY
		template_code
	*/
	-- END v1.10

	-- Check whether the template already has virtual assignments
	IF EXISTS(SELECT 1 FROM dbo.CVO_backorder_processing_orders_ringfenced_stock (NOLOCK) WHERE template_code = @template_code)
	BEGIN
		UPDATE
			dbo.CVO_backorder_processing_summary_hdr
		SET
			has_assignments = 1
		WHERE
			template_code = @template_code
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.CVO_backorder_processing_orders_po_xref (NOLOCK) WHERE template_code = @template_code)
		BEGIN
			UPDATE
				dbo.CVO_backorder_processing_summary_hdr
			SET
				has_assignments = 1
			WHERE
				template_code = @template_code
		END
	END

	-- 2. Detail
	-- i. By part
	INSERT INTO CVO_backorder_processing_summary_det(
		template_code,
		part_no,
		brand,
		style,
		total_backorders,
		rx_backorders,
		rx_filled,
		st_backorders,
		st_filled,
		is_summary,
		process)
	SELECT
		a.template_code,
		a.part_no,
		b.category,
		c.field_2,
		SUM(qty),
		SUM(CASE LEFT(a.order_type,2) WHEN 'RX' THEN a.qty ELSE 0 END),
		SUM(CASE LEFT(a.order_type,2) WHEN 'RX' THEN a.allocated ELSE 0 END),
		SUM(CASE LEFT(a.order_type,2) WHEN 'ST' THEN a.qty ELSE 0 END),
		SUM(CASE LEFT(a.order_type,2) WHEN 'ST' THEN a.allocated ELSE 0 END),
		0,
		0
	FROM
		dbo.CVO_backorder_processing_orders a (NOLOCK)
	INNER JOIN
		dbo.inv_master b (NOLOCK)
	ON
		a.part_no = b.part_no
	INNER JOIN
		dbo.inv_master_add c (NOLOCK)
	ON
		a.part_no = c.part_no
	WHERE
		a.template_code = @template_code
		AND processed = 0
	GROUP BY
		a.template_code,
		a.part_no,
		b.category,
		c.field_2
	
	-- ii. By Style
	INSERT INTO CVO_backorder_processing_summary_det(
		template_code,
		part_no,
		brand,
		style,
		total_backorders,
		rx_backorders,
		rx_filled,
		st_backorders,
		st_filled,
		is_summary,
		process)
	SELECT
		template_code,
		NULL,
		brand,
		style,
		SUM(total_backorders),
		SUM(rx_backorders),
		SUM(rx_filled),
		SUM(st_backorders),
		SUM(st_filled),
		1,
		0
	FROM
		dbo.CVO_backorder_processing_summary_det  (NOLOCK)
	WHERE
		template_code = @template_code
	GROUP BY
		template_code,
		brand,
		style

	IF NOT EXISTS (SELECT 1 FROM dbo.CVO_backorder_processing_orders (NOLOCK) WHERE template_code = @template_code AND processed = 0)
	BEGIN
		SELECT -1
		RETURN -1
	END

	SELECT 0
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_select_sp] TO [public]
GO
