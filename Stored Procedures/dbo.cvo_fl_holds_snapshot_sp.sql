SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_fl_holds_snapshot_sp] @order_no int,
										 @order_ext int,
										 @fill_perc decimal(20,8)
AS
BEGIN
	-- DIREDCTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @line_no		int,
			@part_no		varchar(30),
			@ordered		decimal(20,8),
			@location		varchar(10),
			@soft_alloc_no	int,
			@sa_qty			decimal(20,8),
			@alloc_qty		decimal(20,8),
			@in_stock		decimal(20,8),
			@in_stock_na	decimal(20,8),
			@quar_qty		decimal(20,8)

	-- WORKING TABLES
	 CREATE TABLE #wms_ret ( location  varchar(10),  
		   part_no   varchar(30),  
		   allocated_qty decimal(20,8),  
		   quarantined_qty decimal(20,8),  
		   apptype   varchar(20))  


	INSERT	dbo.cvo_fl_holds_snapshot (order_no, order_ext, fill_perc)
	SELECT	@order_no, @order_ext, @fill_perc

	SET @line_no = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @line_no = line_no,
				@part_no = part_no,
				@ordered = ordered,
				@location = location
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no > @line_no	
		ORDER BY line_no ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		SET @in_stock = 0
		SET @in_stock_na = 0
		SET @alloc_qty = 0
		SET @quar_qty = 0
		SET @sa_qty	= 0

		SELECT	@in_stock = SUM(qty)
		FROM	lot_bin_stock (NOLOCK)
		WHERE	location = @location  
		AND		part_no = @part_no  
	
		SELECT	@in_stock_na = SUM(qty)
		FROM	cvo_lot_bin_stock_exclusions (NOLOCK)
		WHERE	location = @location  
		AND		part_no = @part_no  

		DELETE #wms_ret  
	  
		INSERT #wms_ret  
		EXEC tdc_get_alloc_qntd_sp @location, @part_no  
	  
		SELECT @alloc_qty = allocated_qty,  
		  @quar_qty = quarantined_qty  
		FROM #wms_ret  

		IF (@in_stock IS NULL)  
		 SET @in_stock = 0  

		IF (@in_stock_na IS NULL)  
		 SET @in_stock_na = 0  
	  
		IF (@alloc_qty IS NULL)  
		 SET @alloc_qty = 0  
	  
		IF (@quar_qty IS NULL)  
		 SET @quar_qty = 0  

		SET @soft_alloc_no = NULL

		SELECT	@soft_alloc_no = soft_alloc_no
		FROM	cvo_soft_alloc_no_assign (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		IF (@soft_alloc_no IS NULL)
			SET @soft_alloc_no = 99999999

		SET @sa_qty = 0

		SELECT	@sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)  
		FROM	dbo.cvo_soft_alloc_det a (NOLOCK)  
		WHERE	a.status NOT IN (-2,-3)
		AND		(CAST(a.order_no AS varchar(10)) + CAST(a.order_ext AS varchar(5))) <> (CAST(@order_no AS varchar(10)) + CAST(@order_ext AS varchar(5)))    
		AND		a.location = @location  
		AND		a.part_no = @part_no
		AND		a.soft_alloc_no < @soft_alloc_no 

		IF (@sa_qty IS NULL)  
			SET @sa_qty = 0  

		INSERT	dbo.cvo_fl_holds_snapshot (order_no, order_ext, line_no, part_no, ordered, in_stock, in_stock_na, quar_qty, alloc_qty, soft_alloc_qty, calc_qty)
		SELECT	@order_no, @order_ext, @line_no, @part_no, @ordered, @in_stock, @in_stock_na, @quar_qty, @alloc_qty, @sa_qty, (@in_stock - (@alloc_qty + @quar_qty + @sa_qty + @in_stock_na))   

		INSERT	dbo.cvo_fl_holds_snapshot (order_no, order_ext, line_no, part_no, bin_no, bin_qty, bin_type, non_alloc_flag)
		SELECT	@order_no, @order_ext, @line_no, @part_no, a.bin_no, a.qty, b.usage_type_code, CASE WHEN b.bm_udef_e = 1 THEN 'Y' ELSE 'N' END
		FROM	lot_bin_stock a (NOLOCK)
		JOIN	tdc_bin_master b (NOLOCK)
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		WHERE	a.location = @location
		AND		a.part_no = @part_no		
	END
		
END
GO
