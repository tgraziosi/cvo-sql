SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
DECLARE @qty_required	DECIMAL(20,8),
		@qty_available	DECIMAL(20,8),
		@qty_assigned	DECIMAL(20,8),
		@qty_unassigned	DECIMAL(20,8),
		@qty_remaining	DECIMAL(20,8)

EXEC dbo.cvo_substitute_processing_select_sp	@order_no_from = 1419230,
												@order_no_to = NULL,
												@ext_from = NULL,
												@ext_to = NULL,
												@sch_ship_from = NULL,
												@sch_ship_to = NULL,
												@customer_type = '', -- comma separated list
												@allow_substitutes = 0,
												@order_type = '', -- comma separated list
												@part_no = 'CBBLA5100',
												@replacement_part_no = 'BC810GOL5916',
												@balance_order = 0

SELECT @qty_required, @qty_available, @qty_assigned, @qty_unassigned, @qty_remaining


*/
CREATE PROC [dbo].[cvo_substitute_processing_select_sp] @order_no_from			INT = NULL,
													@order_no_to			INT = NULL,
													@ext_from				INT = NULL,
													@ext_to					INT = NULL,
													@sch_ship_from			DATETIME = NULL,
													@sch_ship_to			DATETIME = NULL,
													@customer_type			VARCHAR(500) = '', -- comma separated list
													@allow_substitutes		SMALLINT = 0,
													@order_type				VARCHAR(500) = '', -- comma separated list
													@part_no				VARCHAR(30),
													@replacement_part_no	VARCHAR(30),
													@balance_order			SMALLINT = 0,
													@location				varchar(10), -- v1.1 
													@territory_from			varchar(10), -- v1.2
													@territory_to			varchar(10) -- v1.2

AS
BEGIN

	DECLARE	@qty_required	DECIMAL(20,8),
			@qty_available	DECIMAL(20,8),
			@qty_assigned	DECIMAL(20,8),
			@qty_unassigned	DECIMAL(20,8),
			@qty_remaining	DECIMAL(20,8), 
			@rec_id			INT,
			-- v1.1 @location		VARCHAR(10),
			@qty			DECIMAL(20,8)
			

	-- v1.1 SET @location = '001'

	-- Create temporary tables
	CREATE TABLE #customer_type(
		customer_type VARCHAR(40))

	CREATE TABLE #order_type(
		order_type VARCHAR(10))

	CREATE TABLE #orders(
		order_no		INT,
		ext				INT,
		line_no			INT,
		part_no			VARCHAR(30),
		qty				DECIMAL(20,8),
		order_type		VARCHAR(10),
		so_priority		VARCHAR(1),
		order_type_sort	SMALLINT,
		priority_sort	SMALLINT,
		backorder_sort	SMALLINT,
		[type]			CHAR(1),
		customer		VARCHAR(8),
		customer_name	VARCHAR(40),
		ship_date		DATETIME,
		customer_type	VARCHAR(40),
		promo_id		VARCHAR(20),
		promo_level		VARCHAR(30))

	CREATE TABLE #selected_orders(
		rec_id			INT IDENTITY(1,1),
		order_no		INT,
		ext				INT,
		line_no			INT,
		part_no			VARCHAR(30),
		qty				DECIMAL(20,8),
		order_type		VARCHAR(10),
		so_priority		VARCHAR(1),
		order_type_sort	SMALLINT,
		priority_sort	SMALLINT,
		backorder_sort	SMALLINT,
		[type]			CHAR(1),
		customer		VARCHAR(8),
		customer_name	VARCHAR(40),
		ship_date		DATETIME,
		customer_type	VARCHAR(40),
		promo_id		VARCHAR(20),
		promo_level		VARCHAR(30),
		process			SMALLINT
		)

	-- Populate customer type table from parameter
	INSERT INTO #customer_type(
		customer_type)
	SELECT 
		ListItem 
	FROM 
		dbo.f_comma_list_to_table (@customer_type)

	IF @@ROWCOUNT = 0
	BEGIN
		-- Load all customer types
		INSERT INTO #customer_type(
			customer_type)
		SELECT DISTINCT
			customer_type
		FROM
			dbo.cvo_customer_type_vw (NOLOCK)
	END

	-- Populate order type table from parameter
	INSERT INTO #order_type(
		order_type)
	SELECT 
		ListItem 
	FROM 
		dbo.f_comma_list_to_table (@order_type)

	IF @@ROWCOUNT = 0
	BEGIN
		-- Load all customer types
		INSERT INTO #order_type(
			order_type)
		SELECT 
			category_code
		FROM
			dbo.so_usrcateg (NOLOCK)
		WHERE
			ISNULL(void,'N') <> 'V'
	END

	-- Load working table
	INSERT INTO #orders(
		order_no,
		ext,
		line_no,
		part_no,
		qty,
		order_type,
		so_priority,
		order_type_sort,
		priority_sort,
		backorder_sort,
		[type],
		customer,
		customer_name,
		ship_date,
		customer_type,
		promo_id,
		promo_level)
	SELECT
		a.order_no,
		a.ext,
		b.line_no,
		b.part_no,
		b.ordered - (b.shipped + ISNULL(f.qty,0)),
		a.user_category,
		ISNULL(a.so_priority_code,''),
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
		c.address_name,
		a.sch_ship_date,
		c.addr_sort1 as customer_type,
		g.promo_id,
		g.promo_level
	FROM
		dbo.orders_all a (NOLOCK)
	INNER JOIN
		dbo.ord_list b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.order_ext
	INNER JOIN
		dbo.armaster_all c (NOLOCK)
	ON
		a.cust_code = c.customer_code
	INNER JOIN
		dbo.cvo_armaster_all d (NOLOCK)
	ON
		c.customer_code = d.customer_code
		AND c.ship_to_code = d.ship_to
	INNER JOIN
		#customer_type e (NOLOCK)
	ON
		ISNULL(c.addr_sort1,'') =  e.customer_type
	LEFT JOIN
		dbo.cvo_hard_allocated_vw f (NOLOCK)
	ON
		b.order_no = f.order_no
		AND b.order_ext = f.order_ext
		AND b.line_no = f.line_no
		AND f.order_type = 'S'
	INNER JOIN
		dbo.cvo_orders_all g (NOLOCK)
	ON
		a.order_no = g.order_no
		AND a.ext = g.ext
	INNER JOIN
		#order_type h
	ON
		a.user_category = h.order_type
	INNER JOIN
		dbo.cvo_ord_list i (NOLOCK)
	ON
		b.order_no = i.order_no
		AND b.order_ext = i.order_ext
		AND b.line_no = i.line_no
	WHERE
-- v1.2	a.[status] = 'N'
		a.status IN ('A','B','C','N') -- v1.2
		--AND a.ext > 0 -- backorders only
		AND c.address_type = 0
		AND ((ISNULL(@allow_substitutes,0) = 0) OR (ISNULL(@allow_substitutes,0) = 1 AND ISNULL(d.allow_substitutes,0) = 1))
		--AND b.ordered > (b.shipped + ISNULL(f.qty,0))
		AND b.ordered > b.shipped 
		AND f.order_no IS NULL
		AND a.location = @location
		AND b.part_no = @part_no
		AND (@order_no_from IS NULL OR a.order_no >= @order_no_from)
		AND (@order_no_to IS NULL OR a.order_no <= @order_no_to)
		AND (@ext_from IS NULL OR a.ext >= @ext_from)
		AND (@ext_to IS NULL OR a.ext <= @ext_to)
		AND (@sch_ship_from IS NULL OR a.sch_ship_date >= @sch_ship_from)
		AND (@sch_ship_to IS NULL OR a.sch_ship_date <= @sch_ship_to)
		AND ISNULL(i.is_customized,'N') = 'N'
		AND b.part_type = 'P'
		AND a.ship_to_region >= @territory_from AND a.ship_to_region <= @territory_to -- v1.3

	-- If balance order is on, then remove any orders which also contain the replacement part (on any extension)
	IF ISNULL(@balance_order,0) = 1
	BEGIN
		DELETE FROM 
			#orders
		WHERE
			order_no IN (SELECT DISTINCT order_no FROM dbo.ord_list WHERE part_no = @replacement_part_no AND ISNULL(void,'N') = 'N') 
	END

	-- Load into selected table in priority order
	INSERT INTO #selected_orders(
		order_no,
		ext,
		line_no,
		part_no,
		qty,
		order_type,
		so_priority,
		order_type_sort,
		priority_sort,
		backorder_sort,
		[type],
		customer,
		customer_name,
		ship_date,
		customer_type,
		promo_id,
		promo_level,
		process)
	SELECT
		order_no,
		ext,
		line_no,
		part_no,
		qty,
		order_type,
		so_priority,
		order_type_sort,
		priority_sort,
		backorder_sort,
		[type],
		customer,
		customer_name,
		ship_date,
		customer_type,
		promo_id,
		promo_level,
		0
	FROM
		#orders
	ORDER BY
		backorder_sort,
		order_type_sort,
		priority_sort,
		order_no,
		ext,
		line_no

	-- Get the qty of the replacement part
	EXEC @qty_available = dbo.cvo_backorder_processing_available_stock_sp @location, @replacement_part_no
		

	-- Loop through the orders and assign the stock
	SELECT	@qty_remaining = @qty_available,
			@qty_assigned = 0,
			@rec_id = 0	

	WHILE 1=1
	BEGIN

		IF @qty_remaining <= 0 
			BREAK

		SELECT TOP 1
			@rec_id = rec_id,
			@qty = qty
		FROM
			#selected_orders
		WHERE
			rec_id > @rec_id
			AND qty <= @qty_remaining
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		SELECT	@qty_assigned = @qty_assigned + @qty,
				@qty_remaining = @qty_remaining - @qty
		
		-- Update record
		UPDATE
			#selected_orders
		SET
			process = 1
		WHERE
			rec_id = @rec_id
	END

	-- Calculate final figures
	SELECT @qty_required = SUM(qty) FROM #selected_orders
	SET @qty_unassigned = @qty_required - @qty_assigned
	

	-- Clear old records from processing tables
	DELETE FROM dbo.cvo_substitute_processing_hdr WHERE spid = @@SPID
	DELETE FROM dbo.cvo_substitute_processing_det WHERE spid = @@SPID
	DELETE FROM dbo.cvo_substitute_processing_error WHERE spid = @@SPID
	
	INSERT INTO dbo.cvo_substitute_processing_hdr (
		spid,
		replacement_part_no,	
		qty_required,
		qty_available,
		qty_assigned,
		qty_unassigned,
		qty_remaining,
		location) -- v1.1
	SELECT
		@@SPID,
		UPPER(@replacement_part_no),	
		ISNULL(@qty_required,0),
		ISNULL(@qty_available,0),
		ISNULL(@qty_assigned,0),
		ISNULL(@qty_unassigned,0),
		ISNULL(@qty_remaining,0),
		@location -- v1.1


	-- Select out results into processing tables
	INSERT INTO dbo.cvo_substitute_processing_det (
		spid,
		order_no,
		ext,
		line_no,
		part_no,
		qty,
		order_type,
		so_priority,
		order_type_sort,
		priority_sort,
		backorder_sort,
		[type],
		customer,
		customer_name,
		ship_date,
		customer_type,
		promo_id,
		promo_level,
		process)
	SELECT
		@@SPID,
		order_no,
		ext,
		line_no,
		part_no,
		qty,
		order_type,
		so_priority,
		order_type_sort,
		priority_sort,
		backorder_sort,
		[type],
		customer,
		customer_name,
		ship_date,
		customer_type,
		promo_id,
		promo_level,
		process	
	FROM
		#selected_orders
	ORDER BY
		rec_id	

	SELECT COUNT(1) FROM dbo.cvo_substitute_processing_det (NOLOCK) WHERE spid = @@SPID

END

GO
GRANT EXECUTE ON  [dbo].[cvo_substitute_processing_select_sp] TO [public]
GO
