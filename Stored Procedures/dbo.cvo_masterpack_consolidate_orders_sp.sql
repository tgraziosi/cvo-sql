SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
CREATE TABLE #allocated_orders(
	order_no INT,
	ext INT)


INSERT INTO #allocated_orders SELECT 1420174, 0
INSERT INTO #allocated_orders SELECT 1420175, 0
INSERT INTO #allocated_orders SELECT 1420176, 0
INSERT INTO #allocated_orders SELECT 1420177, 0
INSERT INTO #allocated_orders SELECT 1420178, 0
*/

-- v1.0 CT 02/04/2014 - Issue #572 - Masterpack consolidation of orders
-- v1.1 CT 23/05/2014 - Issue #572 - If backorder consolidation, only consolidate orders that have allocated
-- v1.2 CT 17/12/2014 - Issue #572 - For backorder processing, only consolidate orders with a status of 'N'

CREATE PROC [dbo].[cvo_masterpack_consolidate_orders_sp]  @type VARCHAR(2)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @cust_code			VARCHAR(10),
			@ship_to			VARCHAR(10),
			@carrier			VARCHAR(20),
			@ship_date			DATETIME,
			@consolidation_no	INT,
			@rec_id				INT,
			@current_date		DATETIME,
			@row_id				INT,
			@max_charge			DECIMAL(20,8),
			@order_value		DECIMAL(20,8)

	-- Create temporary tables
	CREATE TABLE #masterpack_orders(
		rec_id				INT IDENTITY(1,1),
		order_no			INT,
		ext					INT,
		cust_code			VARCHAR(10),
		ship_to				VARCHAR(10),
		carrier				VARCHAR(20),
		ship_date			DATETIME,
		[status]			CHAR(1))

	CREATE TABLE #masterpack_group(
		rec_id				INT IDENTITY(1,1),
		cust_code			VARCHAR(10),
		ship_to				VARCHAR(10),
		carrier				VARCHAR(20),
		ship_date			DATETIME,
		cnt					INT)

	CREATE TABLE #consolidate_picks(
		consolidation_no	INT,
		order_no			INT,
		ext					INT)


	SET @current_date = GETDATE()

	-- Populate orders table
	-- START v1.1
	IF @type = 'BO'
	BEGIN
		INSERT INTO #masterpack_orders(
			order_no,
			ext,
			cust_code,
			ship_to,
			carrier,
			ship_date,
			[status])
		SELECT
			a.order_no,
			a.ext,
			a.cust_code,
			a.ship_to,
			a.routing,
			CASE @type WHEN 'BO' THEN @current_date ELSE a.sch_ship_date END, -- BO processing doesn't group on this field
			a.[status]
		FROM
			dbo.orders_all a (NOLOCK)
		INNER JOIN
			#allocated_orders b
		ON
			a.order_no = b.order_no
			AND a.ext = b.ext
		INNER JOIN
			(SELECT DISTINCT order_no, order_ext FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' AND order_no <> 0) c
		ON
			b.order_no = c.order_no
			AND b.ext = c.order_ext
		WHERE
			a.[type] = 'I'
			AND ISNULL(a.sold_to,'') = '' -- Don't consolidate global labs
			-- START v1.2
			AND a.status = 'N'
			-- END v1.2
	END
	ELSE
	BEGIN
		INSERT INTO #masterpack_orders(
			order_no,
			ext,
			cust_code,
			ship_to,
			carrier,
			ship_date,
			[status])
		SELECT
			a.order_no,
			a.ext,
			a.cust_code,
			a.ship_to,
			a.routing,
			CASE @type WHEN 'BO' THEN @current_date ELSE a.sch_ship_date END, -- BO processing doesn't group on this field
			a.[status]
		FROM
			dbo.orders_all a (NOLOCK)
		INNER JOIN
			#allocated_orders b
		ON
			a.order_no = b.order_no
			AND a.ext = b.ext
		WHERE
			a.[type] = 'I'
			AND ISNULL(a.sold_to,'') = '' -- Don't consolidate global labs	
	END
	-- END v1.1

	IF @@ROWCOUNT = 0
	BEGIN
		DROP TABLE #masterpack_orders
		DROP TABLE #masterpack_group
		DROP TABLE #consolidate_picks
		RETURN
	END

	-- Check if any of the orders have an existing consolidation set open for them, if so rebuild the set based on the new allocation
	SET @rec_id = 0

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = a.rec_id,
			@consolidation_no = c.consolidation_no,
			@carrier = c.carrier
		FROM
			#masterpack_orders a
		INNER JOIN
			dbo.cvo_masterpack_consolidation_det b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.ext = b.order_ext
		INNER JOIN
			dbo.cvo_masterpack_consolidation_hdr c (NOLOCK)
		ON
			b.consolidation_no = c.consolidation_no
		WHERE
			a.rec_id > @rec_id
			AND a.[status] <= 'N'
			AND ISNULL(c.shipped,0) = 0
		ORDER BY
			a.rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Clear and rebuild consolidated pick records
		DELETE FROM #consolidate_picks

		INSERT INTO #consolidate_picks(
			consolidation_no,
			order_no,
			ext)
		SELECT
			consolidation_no,
			order_no,
			order_ext
		FROM
			dbo.cvo_masterpack_consolidation_det b (NOLOCK)
		WHERE
			consolidation_no = @consolidation_no

		EXEC dbo.cvo_masterpack_unconsolidate_pick_records_sp @consolidation_no
		EXEC dbo.cvo_masterpack_consolidate_pick_records_sp @consolidation_no

		-- BackOrders - USPS logic
		IF @type = 'BO' AND @carrier = 'USPS'
		BEGIN
			-- Get max charge
			SELECT 
				@max_charge = max_charge 
			FROM 
				dbo.cvo_carriers (NOLOCK)
			WHERE 
				carrier = 'USPS'

			-- Get allocated value of orders
			SELECT	
				@order_value = SUM((a.curr_price * b.qty) - CASE WHEN a.discount <> 0 THEN (a.curr_price * (a.discount / 100) * b.qty) ELSE 0 END)  
			FROM	
				dbo.ord_list a (NOLOCK)
			INNER JOIN	
				dbo.tdc_soft_alloc_tbl b (NOLOCK)
			ON		
				a.order_no = b.order_no
				AND	a.order_ext = b.order_ext 
				AND	a.line_no = b.line_no
			INNER JOIN
				dbo.cvo_masterpack_consolidation_det c (NOLOCK)
			ON
				a.order_no = c.order_no
				AND a.order_ext = c.order_ext
			WHERE
				c.consolidation_no = @consolidation_no
				AND	b.order_type = 'S'

			-- If the value is over max charge then change carrier on order to UPSGR
			IF ISNULL(@order_value,0) > ISNULL(@max_charge,0)
			BEGIN
				-- Update orders
				UPDATE
					a
				SET
					routing = 'UPSGR'
				FROM
					dbo.orders_all a
				INNER JOIN
					dbo.cvo_masterpack_consolidation_det b (NOLOCK)
				ON
					a.order_no = b.order_no
					AND a.ext = b.order_ext
				WHERE
					b.consolidation_no = @consolidation_no

				-- Update header table
				UPDATE
					dbo.cvo_masterpack_consolidation_hdr
				SET
					carrier = 'UPSGR'
				WHERE
					consolidation_no = @consolidation_no
			END
		END 

		-- Remove recrd from temp table
		DELETE FROM #masterpack_orders WHERE rec_id = @rec_id

	END


	-- Group them
	INSERT INTO #masterpack_group(
		cust_code,
		ship_to,
		carrier,
		ship_date,
		cnt)
	SELECT
		cust_code,
		ship_to,
		carrier,
		ship_date,
		COUNT(1)
	FROM
		#masterpack_orders
	GROUP BY
		cust_code,
		ship_to,
		carrier,
		ship_date
	HAVING 
		COUNT(1) > 1

	IF @@ROWCOUNT = 0
	BEGIN
		DROP TABLE #masterpack_orders
		DROP TABLE #masterpack_group
		DROP TABLE #consolidate_picks
		RETURN
	END

	-- Loop through and assign consolidation numbers
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		-- Get next group record to action
		SELECT TOP 1
			@rec_id = rec_id,
			@cust_code = cust_code,
			@ship_to = ship_to,
			@carrier = carrier,
			@ship_date = ship_date
		FROM
			#masterpack_group
		WHERE
			rec_id > @rec_id
		ORDER BY 
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		SET @consolidation_no = NULL

		-- Check if there is a consolidation set open for them
		SELECT TOP 1
			@consolidation_no = consolidation_no
		FROM
			dbo.cvo_masterpack_consolidation_hdr (NOLOCK)
		WHERE
			[type] = @type
			AND cust_code = @cust_code
			AND ship_to = @ship_to
			AND carrier = @carrier
			AND ISNULL(ship_date,@current_date) = @ship_date 
			AND closed = 0

		-- If we haven't found a consolidation set, create a new one
		IF @consolidation_no IS NULL
		BEGIN
			BEGIN TRAN

			UPDATE
				dbo.cvo_next_consolidation_no
			SET
				last_no = last_no + 1

			SELECT 
				@consolidation_no = last_no
			FROM
				dbo.cvo_next_consolidation_no (NOLOCK)
			
			COMMIT TRAN
		END

		-- BackOrders - USPS logic
		IF @type = 'BO' AND @carrier = 'USPS'
		BEGIN
			-- Get max charge
			SELECT 
				@max_charge = max_charge 
			FROM 
				dbo.cvo_carriers (NOLOCK)
			WHERE 
				carrier = 'USPS'

			-- Get allocated value of orders
			SELECT	
				@order_value = SUM((a.curr_price * b.qty) - CASE WHEN a.discount <> 0 THEN (a.curr_price * (a.discount / 100) * b.qty) ELSE 0 END)  
			FROM	
				dbo.ord_list a (NOLOCK)
			INNER JOIN	
				dbo.tdc_soft_alloc_tbl b (NOLOCK)
			ON		
				a.order_no = b.order_no
				AND	a.order_ext = b.order_ext 
				AND	a.line_no = b.line_no
			INNER JOIN
				#masterpack_orders c
			ON
				a.order_no = c.order_no
				AND a.order_ext = c.ext
			WHERE
				c.cust_code = @cust_code
				AND c.ship_to = @ship_to
				AND c.carrier = @carrier
				AND c.ship_date = @ship_date
				AND	b.order_type = 'S'

			-- If the value is over max charge then change carrier on order to UPSGR
			IF ISNULL(@order_value,0) > ISNULL(@max_charge,0)
			BEGIN
				-- Update orders
				UPDATE
					a
				SET
					routing = 'UPSGR'
				FROM
					dbo.orders_all a
				INNER JOIN
					#masterpack_orders b
				ON
					a.order_no = b.order_no
					AND a.ext = b.ext
				WHERE
					b.cust_code = @cust_code
					AND b.ship_to = @ship_to
					AND b.carrier = @carrier
					AND b.ship_date = @ship_date

				-- Update temp table
				UPDATE
					#masterpack_orders
				SET
					carrier = 'UPSGR'
				WHERE
					cust_code = @cust_code
					AND ship_to = @ship_to
					AND carrier = @carrier
					AND ship_date = @ship_date

				-- Update variable
				SET @carrier = 'UPSGR'
			END


		END

		-- Create header record
		INSERT INTO dbo.cvo_masterpack_consolidation_hdr(
			consolidation_no,
			[type],
			cust_code,
			ship_to,
			carrier,
			ship_date,
			closed,
			shipped)
		SELECT
			@consolidation_no,
			@type,
			@cust_code,
			@ship_to,
			@carrier,
			CASE @type WHEN 'BO' THEN NULL ELSE @ship_date END, -- don't store ship date for BO sets
			CASE @type WHEN 'BO' THEN 1 ELSE 0 END, -- auto close BO sets
			0

		-- Create detail records
		INSERT INTO dbo.cvo_masterpack_consolidation_det(
			consolidation_no,
			order_no,
			order_ext)
		SELECT
			@consolidation_no,
			order_no,
			ext
		FROM
			#masterpack_orders
		WHERE
			cust_code = @cust_code
			AND ship_to = @ship_to
			AND carrier = @carrier
			AND ship_date = @ship_date
		
		-- Consolidate pick records for this set
		DELETE FROM #consolidate_picks

		INSERT INTO #consolidate_picks(
			consolidation_no,
			order_no,
			ext)
		SELECT
			@consolidation_no,
			order_no,
			ext
		FROM
			#masterpack_orders
		WHERE
			cust_code = @cust_code
			AND ship_to = @ship_to
			AND carrier = @carrier
			AND ship_date = @ship_date
		
		EXEC dbo.cvo_masterpack_consolidate_pick_records_sp @consolidation_no
		
	END

	DROP TABLE #masterpack_orders
	DROP TABLE #masterpack_group
	DROP TABLE #consolidate_picks
END

GO
GRANT EXECUTE ON  [dbo].[cvo_masterpack_consolidate_orders_sp] TO [public]
GO
