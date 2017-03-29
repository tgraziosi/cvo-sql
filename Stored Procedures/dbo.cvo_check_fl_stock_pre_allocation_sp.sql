SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_check_fl_stock_pre_allocation_sp]	@order_no_in int,
														@order_ext_in int														
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@row_id				int,
			@last_row_id		int,
			@line_row_id		int,
			@last_line_row_id	int,
			@order_no			int,
			@order_ext			int,
			@location			varchar(10),
			@line_no			int,
			@part_no			varchar(30),
			@qty				decimal(20,8),
			@in_stock		decimal(20,8),
			@in_stock_ex	decimal(20,8),
			@alloc_qty		decimal(20,8),
			@quar_qty		decimal(20,8),
			@sa_qty			decimal(20,8),
			@soft_alloc_no	int, -- v1.1
			@total_ordered	decimal(20,8), -- v1.2
			@total_available decimal(20,8), -- v1.2
			@perc			decimal(20,8) -- v1.2

	-- Create working tables 
	CREATE TABLE #order_hdr (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		no_stock		int,
		perc_available	decimal(20,8)) -- v1.2

	CREATE TABLE #order_det (
		line_row_id		int IDENTITY(1,1),
		location		varchar(10),
		line_no			int,
		part_no			varchar(30),
		qty				decimal(20,8),
		no_stock		int)

	 CREATE TABLE #wms_ret ( location  varchar(10),  
		   part_no   varchar(30),  
		   allocated_qty decimal(20,8),  
		   quarantined_qty decimal(20,8),  
		   apptype   varchar(20))  

	-- Populate working table with orders that will be processed by the soft allocation routine
	INSERT	#order_hdr (order_no, order_ext, no_stock, perc_available) -- v1.2
	SELECT	@order_no_in, @order_ext_in, 0, 0 -- v1.2

	IF (@@ROWCOUNT = 0) -- No records to process
		RETURN

	CREATE INDEX #order_hdr_ind0 ON #order_hdr (row_id, order_no, order_ext)

	SET	@last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext
	FROM	#order_hdr
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		DELETE #order_det

		INSERT	#order_det (location, line_no, part_no, qty, no_stock)
		SELECT	a.location,
				a.line_no,
				a.part_no,
				a.ordered - a.shipped, -- v1.2
				0
		FROM	ord_list a (NOLOCK)
		JOIN	inv_master b (NOLOCK) -- v1.3
		ON		a.part_no = b.part_no -- v1.3
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		b.type_code IN ('FRAME','SUN') -- v1.3
		ORDER BY a.line_no

		SET @last_line_row_id = 0
	
		SELECT	TOP 1 @line_row_id = line_row_id,
				@location = location,
				@line_no = line_no,
				@part_no = part_no,
				@qty = qty
		FROM	#order_det
		WHERE	line_row_id > @last_line_row_id
		ORDER BY line_row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			SET @in_stock = 0
			SET @in_stock_ex = 0
			SET @alloc_qty = 0
			SET @quar_qty = 0
			SET @sa_qty	= 0

			-- Get the qty in stock
			SELECT	@in_stock = SUM(qty)
			FROM	lot_bin_stock (NOLOCK)
			WHERE	location = @location  
			AND		part_no = @part_no  
		
			-- Get qty in non allocatable bins
			-- v1.1 Start
			-- v1.5 Start
			SELECT	@in_stock_ex = SUM(qty)
			FROM	cvo_lot_bin_stock_exclusions (NOLOCK)
			WHERE	location = @location  
			AND		part_no = @part_no  

--			SELECT	@in_stock_ex = SUM(a.qty) - ISNULL(SUM(b.qty),0.0)
--			FROM	cvo_lot_bin_stock_exclusions a (NOLOCK)
--			LEFT JOIN (SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) b 
--			ON		a.location = b.location
--			AND		a.part_no = b.part_no
--			AND		a.bin_no = b.bin_no
--			WHERE	a.location = @location  
--			AND		a.part_no = @part_no  
			-- v1.5 End
			-- v1.1 End


--			 Set the in_tock figure
			SET	 @in_stock = ISNULL(@in_stock,0) - ISNULL(@in_stock_ex,0)
  
			-- WMS - allocated and quarantined  
			DELETE #wms_ret  
		  
			INSERT #wms_ret  
			EXEC tdc_get_alloc_qntd_sp @location, @part_no  
		  
			SELECT @alloc_qty = allocated_qty,  
			  @quar_qty = quarantined_qty  
			FROM #wms_ret  

			IF (@in_stock IS NULL)  
			 SET @in_stock = 0  
		  
			IF (@alloc_qty IS NULL)  
			 SET @alloc_qty = 0  
		  
			IF (@quar_qty IS NULL)  
			 SET @quar_qty = 0  

			-- v1.1 Start
			 SELECT @soft_alloc_no = soft_alloc_no
			 FROM	cvo_soft_alloc_hdr (NOLOCK)
			 WHERE	order_no = @order_no
			 AND	order_ext = @order_ext

			 IF (@soft_alloc_no IS NULL)
				SET @soft_alloc_no = 999999999
			-- v1.1 End  

			SELECT @sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)  
			FROM	dbo.cvo_soft_alloc_det a (NOLOCK)  
-- v1.4		WHERE	a.status IN (0, 1, -1)  
			WHERE	a.status NOT IN (-2,-3) --  v1.4
			AND		(CAST(a.order_no AS varchar(10)) + '-' + CAST(a.order_ext AS varchar(5))) <> (CAST(@order_no AS varchar(10)) + '-' + CAST(@order_ext AS varchar(5)))    
			AND		a.location = @location  
			AND		a.part_no = @part_no
			AND		a.soft_alloc_no < @soft_alloc_no -- v1.1
  
			IF (@sa_qty IS NULL)  
			 SET @sa_qty = 0  
		  
			-- Compare - if no stock available then mark the record  
			IF ((@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) < @qty) 
			BEGIN  
				UPDATE #order_det  
				SET  no_stock = 1  
				WHERE line_row_id = @line_row_id  
			END

			SET @last_line_row_id = @line_row_id
		
			SELECT	TOP 1 @line_row_id = line_row_id,
					@location = location,
					@line_no = line_no,
					@part_no = part_no,
					@qty = qty
			FROM	#order_det
			WHERE	line_row_id > @last_line_row_id
			ORDER BY line_row_id ASC
		END

		-- Check if any of the details can be allocated
		IF EXISTS (SELECT 1 FROM #order_det WHERE no_stock = 1)
		BEGIN
			UPDATE	#order_hdr
			SET		no_stock = 1
			WHERE	row_id = @row_id

			-- v1.2 Start
			SELECT	@total_ordered = SUM(qty)
			FROM	#order_det
			
			SELECT	@total_available = SUM(qty)
			FROM	#order_det
			WHERE	no_stock = 0


			IF (@total_available > 0)
			BEGIN
				SELECT	@perc = (@total_available / @total_ordered) * 100.00
			END
			ELSE
			BEGIN
				SELECT	@perc = 0
			END
			UPDATE	#order_hdr
			SET		perc_available = @perc
			WHERE	row_id = @row_id
		END
		ELSE
		BEGIN
			UPDATE	#order_hdr
			SET		perc_available = 100
			WHERE	row_id = @row_id		
		END
		-- v1.2 End

		SET	@last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#order_hdr
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	-- Insert in to the exclusions any order where no stock is available
	INSERT #exclusions (order_no, order_ext, perc_available) -- v1.2
	SELECT order_no, order_ext, perc_available FROM #order_hdr WHERE no_stock = 1 -- v1.2
  
-- Clean up
DROP TABLE #order_hdr
DROP TABLE #order_det
DROP TABLE #wms_ret

END
GO
GRANT EXECUTE ON  [dbo].[cvo_check_fl_stock_pre_allocation_sp] TO [public]
GO
