
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 13/08/12 - Created
-- v1.1 CT 13/09/12 - Corrected logic for buying group orders
-- v1.2 CT 05/11/13 - Issue #864 - Printing promo credit details
-- v1.3 CT 24/04/14 - Issue #572 - when joining between carton hdr and detail, join on order number as well as carton no
-- v1.4 CB 05/05/2015 - Issue #1538 - Not displaying free frames correctly for BGs
-- v1.5 CB 15/07/2015 - Fix for v1.4
-- v1.6 CB 03/12/2015 - Fix for BG customer set to regular invoice
-- requires temp table
/*
CREATE TABLE #detail(
	part_no			VARCHAR(30) NULL,
	pack_qty		DECIMAL(20,8) NULL,
	ordered			DECIMAL(20,8) NULL,
	qty_short		DECIMAL(20,8) NULL,
	list_price		DECIMAL(20,2) NULL,
	gross_price		DECIMAL(20,2) NULL, 
	net_price		DECIMAL(20,2) NULL, 
	ext_net_price	DECIMAL(20,2) NULL,
	discount_amount DECIMAL(20,2) NULL, 
	discount_pct	DECIMAL(20,2) NULL,
	note			VARCHAR(10)  NULL,
	is_credit		SMALLINT NULL,
	is_free			smallint)
*/

CREATE PROC [dbo].[cvo_get_pack_list_details_sp] (	@order_no	INT,
												@order_ext	INT,
												@location	VARCHAR(10),
												@inv_option varchar(8) = '0') -- v1.6
		
AS
BEGIN

	DECLARE @rec_key			INT,
			@part_no			VARCHAR(30),
			@line_no			INT,
			@list_price			DECIMAL(20,2),
			@gross_price		DECIMAL(20,2), 
			@net_price			DECIMAL(20,2), 
			@ext_net_price		DECIMAL(20,2),
			@discount_amount	DECIMAL(20,2), 
			@discount_pct		DECIMAL(20,2),
			@qty_short			DECIMAL(20,8),
			@ordered			DECIMAL(20,8),
			@pack_qty			DECIMAL(20,8),
			@note				VARCHAR(10),
			-- START v1.1
			@buying_group		VARCHAR(8),
			@bg_order			smallint
			-- END v1.1

	-- Create temp table
	CREATE TABLE #parts(
		rec_key			INT IDENTITY (1,1) NOT NULL,
		part_no			VARCHAR(30) NULL,
		line_no			INT NULL,
		pack_qty		DECIMAL(20,8) NULL,
		ordered			DECIMAL(20,8) NULL,
		qty_short		DECIMAL(20,8) NULL,
		list_price		DECIMAL(20,2) NULL,
		gross_price		DECIMAL(20,2) NULL, 
		net_price		DECIMAL(20,2) NULL, 
		ext_net_price	DECIMAL(20,2) NULL,
		discount_amount DECIMAL(20,2) NULL, 
		discount_pct	DECIMAL(20,2) NULL,
		note			VARCHAR(10),
		is_free			smallint NULL) -- v1.4

	-- START v1.1 - see if this is a buying group order
	SET @buying_group = NULL
	SET @bg_order = 0

	SELECT 
		@buying_group = buying_group 
	FROM 
		dbo.CVO_orders_all (NOLOCK) 
	WHERE 
		order_no = @order_no 
		AND ext = @order_ext 
		AND buying_group IS NOT NULL 
		AND buying_group <> ''
	
	IF ISNULL(@buying_group,'') = ''
	BEGIN
		SET @bg_order = 0
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.arcust (NOLOCK) WHERE customer_code = @buying_group AND addr_sort1 = 'Buying Group')
		BEGIN
			SET @bg_order = 1
		END
		ELSE
		BEGIN
			SET @bg_order = 0
		END
	END
	-- END v1.1


	-- Add details from carton
	INSERT INTO #parts(
		part_no,
		line_no,
		pack_qty)
	SELECT
		a.part_no,
		a.line_no,
		a.pack_qty 
	FROM 
		dbo.tdc_carton_detail_tx a (NOLOCK) 
	INNER JOIN
		dbo.tdc_carton_tx b (NOLOCK)	
	ON
		a.carton_no = b.carton_no
		-- START v1.3
		 AND a.order_no = b.order_no
		AND a.order_ext = b.order_ext									
		-- END v1.3
	WHERE 
		a.order_no = @order_no 
		AND a.order_ext = @order_ext 
		AND b.order_type = 'S'  

	-- Add details not picked
	INSERT INTO #parts(
		part_no,
		line_no,
		pack_qty)	
	SELECT
		part_no,
		line_no,
		0
	FROM 
		dbo.ord_list (NOLOCK)																			
	WHERE 
		order_no = @order_no 
		AND order_ext = @order_ext 
		AND shipped = 0	

	-- v1.4 Start
	UPDATE	a
	SET		is_free = ISNULL(b.free_frame,0)
	FROM	#parts a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.line_no = b.line_no
	WHERE	b.order_no = @order_no
	AND		b.order_ext = @order_ext
	-- v1.4 End

	-- Loop through lines and get details
	SET @rec_key = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_key = rec_key,
			@part_no = part_no,
			@line_no = line_no,
			@pack_qty = pack_qty
		FROM
			#parts
		WHERE
			rec_key > @rec_key
		ORDER BY
			rec_key

		IF @@ROWCOUNT = 0
			BREAK

		-- Get Total Ordered Qty for the Item on the Order
		SELECT 
			@ordered = ordered,
			@qty_short = (ordered - shipped) 
		FROM 
			dbo.ord_list (NOLOCK)  
		WHERE 
			order_no  = @order_no  
			AND order_ext = @order_ext   
			AND part_no   = @part_no 
			AND line_no	= @line_no 
	            
		SET @list_price      = 0
		SET @gross_price     = 0
		SET @ext_net_price   = 0
		SET @net_price	   = 0
		SET @discount_amount = 0
		SET @discount_pct	   = 0

		-- START v1.1
		--IF EXISTS(SELECT buying_group FROM CVO_orders_all WHERE order_no = @order_no AND ext = @order_ext AND buying_group is not null AND buying_group != '' )
		IF @bg_order = 1
		-- END v1.1
		BEGIN
				-- v1.6 Start
				IF (@inv_option = '0')
				BEGIN

					SELECT	
						@gross_price	= CAST(ROUND(@pack_qty * (l.curr_price - ROUND(c.amt_disc,2)),2,1) AS DECIMAL(20,2)),
						@net_price		= CAST(ROUND((l.curr_price - ROUND(c.amt_disc,2)),2,1) AS DECIMAL(20,2)),							
						@ext_net_price	= CAST((@pack_qty * ROUND((l.curr_price - ROUND(c.amt_disc,2)),2,1)) AS DECIMAL(20,2)),							
						@discount_amount	=CAST(((c.list_price - l.curr_price) + ROUND(c.amt_disc,2)) AS DECIMAL(20,2)), 
						@discount_pct	= CASE l.price WHEN 0 THEN 0				
										  ELSE CASE c.list_price WHEN 0 THEN 0
										  ELSE CAST(ROUND((((c.list_price - (l.curr_price - ROUND(c.amt_disc,2))) / c.list_price) * 100),2,1) AS DECIMAL(20,2)) END END, 
						@list_price		= CAST(c.list_price AS DECIMAL(20,2)),
						@note		= SUBSTRING(IsNull(l.note,''),1,10)		
						-- v1.5 End
					FROM   
						dbo.ord_list l (NOLOCK)
					LEFT OUTER JOIN 
						dbo.cvo_ord_list c (NOLOCK) 
					ON 
						l.order_no = c.order_no 
						AND l.order_ext = c.order_ext 
						AND l.line_no = c.line_no
					WHERE  
						l.order_no  = @order_no 
						AND l.order_ext = @order_ext 
						AND l.part_no = @part_no   
						AND l.line_no = @line_no
				
				END
				ELSE
				BEGIN
					SELECT	
						@list_price	= CAST(c.list_price	AS DECIMAL(20,2)),
						@note     = SUBSTRING(IsNull(l.note,''),1,10),
						-- v1.5 Start
						@discount_pct	= CASE l.price WHEN 0 THEN 0				
										  ELSE CASE c.list_price WHEN 0 THEN 0
										  ELSE CAST(ROUND((((c.list_price - (l.curr_price - ROUND(c.amt_disc,2))) / c.list_price) * 100),2,1) AS DECIMAL(20,2)) END END
						-- v1.5 End
					FROM   
						dbo.ord_list l (NOLOCK)
					LEFT OUTER JOIN 
						dbo.cvo_ord_list c (NOLOCK) 
					ON 
						l.order_no = c.order_no 
						AND l.order_ext = c.order_ext 
						AND l.line_no = c.line_no
					WHERE  
						l.order_no  = @order_no 
						AND l.order_ext = @order_ext 
						AND l.part_no = @part_no   
						AND l.line_no = @line_no
						AND l.location  = @Location	
			    END
				-- v1.6 End
		END
		ELSE
		BEGIN
			IF EXISTS(SELECT 1 FROM dbo.ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext and line_no = @line_no
										 AND part_no = @part_no AND location = @Location AND shipped > 0)
			BEGIN
				SELECT 
					@gross_price	= CAST(ROUND(@pack_qty * (l.curr_price - ROUND(c.amt_disc,2)),2,1) AS DECIMAL(20,2)),
					@net_price		= CAST(ROUND((l.curr_price - ROUND(c.amt_disc,2)),2,1) AS DECIMAL(20,2)),							
					@ext_net_price	= CAST((@pack_qty * ROUND((l.curr_price - ROUND(c.amt_disc,2)),2,1)) AS DECIMAL(20,2)),							
					@discount_amount	=CAST(((c.list_price - l.curr_price) + ROUND(c.amt_disc,2)) AS DECIMAL(20,2)), 
					@discount_pct	= CASE l.price WHEN 0 THEN 0				
									  ELSE CASE c.list_price WHEN 0 THEN 0
									  ELSE CAST(ROUND((((c.list_price - (l.curr_price - ROUND(c.amt_disc,2))) / c.list_price) * 100),2,1) AS DECIMAL(20,2)) END END, 
					@list_price		= CAST(c.list_price AS DECIMAL(20,2)),
					@note		= SUBSTRING(IsNull(l.note,''),1,10)						
				FROM 
					dbo.ord_list l (NOLOCK)
				LEFT OUTER JOIN 
					cvo_ord_list c (NOLOCK) 
				ON 
					l.order_no = c.order_no 
					AND l.order_ext = c.order_ext 
					AND l.line_no = c.line_no
				WHERE  
					l.order_no  = @order_no   
					AND l.order_ext = @order_ext 
					AND l.part_no   = @part_no  
					AND l.line_no = @line_no 
					AND l.location  = @Location
			END
			ELSE
			BEGIN		
				SELECT @gross_price	= 0, @net_price	= 0, @discount_amount = 0, @discount_pct = 0, @list_price = 0, @note = ''
			END
		END

		-- Update record in temp table
		UPDATE 
			#parts
		SET
			ordered = @ordered,
			qty_short = @qty_short,
			list_price = @list_price,
			gross_price = @gross_price, 
			net_price = @net_price, 
			ext_net_price = @ext_net_price,
			discount_amount = @discount_amount, 
			discount_pct = @discount_pct,
			note = @note
		WHERE
			rec_key = @rec_key	

	END

select * from #parts

	-- v1.4 Start
	IF @bg_order = 1
	BEGIN
		UPDATE	#parts
		SET		discount_amount = list_price,
				discount_pct = 100
		WHERE	is_free = 1
	END
	-- v1.4 End

	-- Group data
	INSERT INTO #detail (
		part_no,
		pack_qty,
		ordered,
		qty_short,
		list_price,
		gross_price, 
		net_price, 
		ext_net_price,
		discount_amount, 
		discount_pct,
		note,
		is_credit, -- v1.2
		is_free) -- v1.4	
	SELECT 
		part_no,
		SUM(pack_qty),
		SUM(ordered),
		SUM(qty_short),
		list_price,
		SUM(gross_price), 
		net_price, 
		SUM(ext_net_price),
		discount_amount, 
		discount_pct,
		note,
		0, -- v1.2
		is_free -- v1.4
	FROM
		#parts
	GROUP BY
		part_no,
		list_price,
		net_price, 
		discount_amount, 
		discount_pct,
		note,
		is_free -- v1.4

	-- START v1.2
	-- Insert any promo credits into details
	EXEC cvo_pack_list_debit_promo_details_sp @order_no, @order_ext
	-- END v1.2
END
GO

GRANT EXECUTE ON  [dbo].[cvo_get_pack_list_details_sp] TO [public]
GO
