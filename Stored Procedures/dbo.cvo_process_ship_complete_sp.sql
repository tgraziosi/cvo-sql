SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- EXEC dbo.cvo_process_ship_complete_sp 1420112, 0
CREATE PROC [dbo].[cvo_process_ship_complete_sp] @order_no	int,
											 @order_ext int
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@row_id			int,
			@last_row_id	int,
			@location		varchar(10),
			@part_no		varchar(30),
			@qty			decimal(20,8),
			@in_stock		decimal(20,8),
			@in_stock_ex	decimal(20,8),  
			@alloc_qty		decimal(20,8),  
			@quar_qty		decimal(20,8),  
			@sa_qty			decimal(20,8),
			@status			varchar(8),
			@hold_reason	varchar(30),
			@hardalloc_qty	DECIMAL(20,8), -- v1.2
			@max_soft_alloc	int -- v1.5

	-- Working Tables
	CREATE TABLE #ship_complete (
		row_id		int IDENTITY(1,1),
		order_no	int,
		order_ext	int,
		location	varchar(10),
		part_no		varchar(30),
		qty			decimal(20,8),
		avail_flag	int)

	CREATE TABLE #wms_ret ( location  varchar(10),    
		part_no		varchar(30),    
		allocated_qty decimal(20,8),    
		quarantined_qty decimal(20,8),    
		apptype		varchar(20))    

	-- Insert working data
	INSERT	#ship_complete (order_no, order_ext, location, part_no, qty, avail_flag)
	-- START v1.3
	SELECT	order_no, order_ext, location, part_no, SUM(ordered - shipped), 1
	--SELECT	order_no, order_ext, location, part_no, SUM(ordered), 1
	-- END v1.3
	FROM	dbo.ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	GROUP BY order_no, order_ext, location, part_no

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@location = location,
			@part_no = part_no,
			@qty = qty
	FROM	#ship_complete
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN
		-- Initialize			
		SET @in_stock = 0  
		SET @in_stock_ex = 0  
		SET @alloc_qty = 0  
		SET @quar_qty = 0  
		SET @sa_qty = 0 
		SET @hardalloc_qty = 0 -- v1.2

		-- START v1.2
		-- Get qty hard allocated for the part
		SELECT
			@hardalloc_qty = SUM(qty) 
		FROM 
			dbo.tdc_soft_alloc_tbl (NOLOCK)
		WHERE 
			order_no = @order_no 
			AND order_ext = @order_ext 
			AND order_type = 'S' 
			AND part_no = @part_no
			AND location = @location

		-- Remove it from qty required
		SET @qty = @qty - ISNULL(@hardalloc_qty,0)

		-- Only check this part if there is qty required
		IF @qty > 0
		BEGIN
		-- END v1.2
		
		   -- Get the qty in stock  
		   SELECT	@in_stock = SUM(qty)  
		   FROM		lot_bin_stock (NOLOCK)  
		   WHERE	location = @location    
		   AND		part_no = @part_no			

		   SELECT	@in_stock_ex = SUM(a.qty) - ISNULL(SUM(b.qty),0.0)  
		   FROM		cvo_lot_bin_stock_exclusions a (NOLOCK)  
		   LEFT JOIN (SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) b   
		   ON		a.location = b.location  
		   AND		a.part_no = b.part_no  
		   AND		a.bin_no = b.bin_no  
		   WHERE	a.location = @location    
		   AND		a.part_no = @part_no   

			SET  @in_stock = ISNULL(@in_stock,0) - ISNULL(@in_stock_ex,0)  

			DELETE #wms_ret    
	  
			INSERT #wms_ret    
			EXEC tdc_get_alloc_qntd_sp @location, @part_no    
			  
			SELECT	@alloc_qty = allocated_qty,    
					@quar_qty = quarantined_qty    
			FROM	#wms_ret    

			IF (@in_stock IS NULL)    
				SET @in_stock = 0    
			  
			IF (@alloc_qty IS NULL)    
				SET @alloc_qty = 0    
			  
			IF (@quar_qty IS NULL)    
				SET @quar_qty = 0  

			-- v1.5 Start
			SET @max_soft_alloc = 0

			SELECT	@max_soft_alloc = soft_alloc_no
			FROM	cvo_soft_alloc_hdr (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext

			IF (@max_soft_alloc = 0)
				SET @max_soft_alloc = 99999999
			-- v1.5 End

			SELECT	@sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)    
			FROM	dbo.cvo_soft_alloc_det a (NOLOCK)    
			WHERE	a.status NOT IN (-2, -3) -- v1.4 IN (0, 1, -1)    
			AND		(CAST(a.order_no AS varchar(10)) + CAST(a.order_ext AS varchar(5))) <> (CAST(@order_no AS varchar(10)) + CAST(@order_ext AS varchar(5)))      
			AND		a.location = @location    
			AND		a.part_no = @part_no   
			AND		a.soft_alloc_no <  @max_soft_alloc -- v1.5

			IF (@sa_qty IS NULL)    
				SET @sa_qty = 0    
			  
			-- Compare - if no stock available then mark the record    
			IF ((@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) < @qty)   
			BEGIN    
				-- Return stock no available
				-- As this is the test at save we only need to find one line that is not available
				SELECT	@status = status,
						@hold_reason = hold_reason
				FROM	orders_all (NOLOCK)
				WHERE	order_no = @order_no
				AND		ext = @order_ext

				IF (@status = 'A') 
				BEGIN
					IF (@hold_reason <> 'SC' )
					BEGIN
						UPDATE	cvo_orders_all
						SET		prior_hold = 'SC' -- v1.1
						WHERE	order_no = @order_no
						AND		ext = @order_ext
					END
					SELECT 0
					RETURN -1
				END

				IF (@status IN ('C','H','B'))
				BEGIN
					UPDATE	cvo_orders_all
					SET		prior_hold = 'SC'
					WHERE	order_no = @order_no
					AND		ext = @order_ext

					SELECT 0
					RETURN -1
				END

				IF (@status = 'N')					
				BEGIN
					UPDATE	orders_all
					SET		status = 'A',
							hold_reason = 'SC'
					WHERE	order_no = @order_no
					AND		ext = @order_ext

					SELECT -1
					RETURN -1
				END

			END 

		-- START v1.2
		END
		-- END v1.2 

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@location = location,
				@part_no = part_no,
				@qty = qty
		FROM	#ship_complete
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END

	SELECT 0
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_process_ship_complete_sp] TO [public]
GO
