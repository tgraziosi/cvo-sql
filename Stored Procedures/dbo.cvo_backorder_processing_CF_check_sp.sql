SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 28/11/2013 - Issue #1406 - check to see if the pick tickets awaiting printing have unavailable custom frame lines (based on logic in cvo_soft_alloc_CF_check_sp)

CREATE PROC [dbo].[cvo_backorder_processing_CF_check_sp]	@template_code VARCHAR(30)
AS
BEGIN  
	  
	 -- Directives  
	 SET NOCOUNT ON  
	  
	   
	 -- Declarations  
	 DECLARE @order_no   int,  
			@order_ext   int,  
			@soft_alloc_no  int,  
			@last_soft_alloc_no int,  
			@id     int,  
			@last_id   int,  
			@line_no   int,  
			@location   varchar(10),  
			@part_no   varchar(30),  
			@in_stock   decimal(20,8), 
			@in_stock_ex decimal(20,8), 
			@alloc_qty   decimal(20,8),  
			@quar_qty   decimal(20,8),  
			@sa_qty    decimal(20,8),  
			@qty    decimal(20,8),
			@replen_qty	DECIMAL(20,8) 
	  
	 -- Create Working Table  
	 CREATE TABLE #cf_break (id    int identity(1,1),  
		   soft_alloc_no int,  
		   location  varchar(10),  
		   line_no   int,  
		   part_no   varchar(30),  
		   qty    decimal(20,8),  
		   no_stock  int)  

	 CREATE INDEX #cf_break_ind0 ON #cf_break(id,soft_alloc_no,line_no,no_stock) 
	  
	 CREATE TABLE #cf_break_kit   
			 (id    int identity(1,1),  
		   soft_alloc_no int,  
		   location  varchar(10),  
		   qty    decimal(20,8),
		   kit_line_no  int,  
		   kit_part_no  varchar(30),  
		   no_stock  int)  

	CREATE INDEX #cf_break_kit_ind0 ON #cf_break_kit(id,soft_alloc_no,kit_line_no,no_stock) 
	  
	 CREATE TABLE #wms_ret ( location  varchar(10),  
		   part_no   varchar(30),  
		   allocated_qty decimal(20,8),  
		   quarantined_qty decimal(20,8),  
		   apptype   varchar(20))  
	  
	 CREATE TABLE #cf_allocs (  
		   soft_alloc_no int,  
		   order_no  int,  
		   order_ext  int,  
		   no_stock  int)  

	 CREATE index #cf_allocs_ind0 ON #cf_allocs (soft_alloc_no) 
	   
	 
	 CREATE TABLE #cf_allocs_line (  
		   order_no  int,  
		   order_ext  int,  
		   line_no   int,  
		   no_stock  int)   

	  
	CREATE INDEX #cf_allocs_line_ind0 ON #cf_allocs_line(order_no,order_ext,line_no,no_stock) 
	 
		  
	INSERT #cf_allocs (
		soft_alloc_no,
		order_no, 
		order_ext, 
		no_stock)  
	SELECT DISTINCT 
		c.soft_alloc_no,
		a.order_no,  
		a.ext,  
		0  
	FROM 
		dbo.CVO_backorder_processing_pick_tickets a (NOLOCK)  
	INNER JOIN 
		dbo.cvo_ord_list b (NOLOCK)  
	ON  
		a.order_no = b.order_no  
		AND  a.ext = b.order_ext
	INNER JOIN
		(	SELECT MIN(soft_alloc_no) soft_alloc_no, order_no, order_ext 
			FROM dbo.cvo_soft_alloc_hdr c (NOLOCK)
			GROUP BY order_no, order_ext) c
	ON  
		a.order_no = c.order_no  
		AND  a.ext = c.order_ext
	WHERE 
		a.template_code = @template_code
		AND a.printed = 0
		AND a.is_transfer = 0
		AND  b.is_customized = 'S'  
	  
	  
	SET @last_soft_alloc_no = 0  
	  
	SELECT TOP 1 
		@soft_alloc_no = soft_alloc_no,  
		@order_no = order_no,  
		@order_ext = order_ext  
	FROM 
		#cf_allocs  
	WHERE 
		soft_alloc_no > @last_soft_alloc_no  
	ORDER BY 
		soft_alloc_no ASC  
	  
	WHILE @@ROWCOUNT <> 0  
	BEGIN  
	  
		DELETE #cf_break  
		DELETE #cf_break_kit  
	  
		-- Get a list of the custom frame breaks from the order  
		INSERT #cf_break (
			soft_alloc_no, 
			location, 
			line_no, 
			part_no, 
			qty, 
			no_stock)  
		SELECT DISTINCT 
			@soft_alloc_no,  
			a.location,  
			a.line_no,  
			a.part_no,  
			a.ordered,  
			0  
		FROM 
			dbo.ord_list a (NOLOCK)  
		INNER JOIN 
			dbo.cvo_ord_list_kit b (NOLOCK)  
		ON  
			a.order_no = b.order_no  
			AND a.order_ext = b.order_ext  
			AND a.line_no = b.line_no  
		WHERE 
			a.order_no = @order_no  
			AND a.order_ext = @order_ext  
			AND b.replaced = 'S'  
	  
		INSERT #cf_break_kit (
			soft_alloc_no, 
			location, 
			qty, 
			kit_line_no, 
			kit_part_no, 
			no_stock) 
		SELECT 
			@soft_alloc_no,  
			b.location,  
			b.ordered,
			a.line_no,  
			a.part_no,  
			0  
		FROM 
			dbo.cvo_ord_list_kit a (NOLOCK)  
		INNER JOIN 
			dbo.ord_list b (NOLOCK)  
		ON  
			a.order_no = b.order_no  
			AND a.order_ext = b.order_ext  
			AND a.line_no = b.line_no  
		WHERE 
			a.order_no = @order_no  
			AND a.order_ext = @order_ext  
			AND a.replaced = 'S'  
	  
		IF EXISTS (SELECT 1 FROM #cf_break) -- Test for substitution at frame level  
		BEGIN  
			SET @last_id = 0  
	  
			SELECT TOP 1 
				@id = id,  
				@location = location,  
				@line_no = line_no,  
				@part_no = part_no,  
				@qty = qty 
			FROM 
				#cf_break  
			WHERE 
				id > @last_id  
			ORDER BY 
				id ASC  
	  
			WHILE @@ROWCOUNT <> 0  
			BEGIN  
			
				SET @in_stock = 0  
				SET @in_stock_ex = 0 
				SET @alloc_qty = 0  
				SET @quar_qty = 0  
				SET @sa_qty = 0  
	    
	  
				SELECT	
					@in_stock = SUM(qty)
				FROM	
					dbo.lot_bin_stock (NOLOCK)
				WHERE	
					location = @location  
					AND	part_no = @part_no  

				SELECT	
					@in_stock_ex = SUM(qty)
				FROM	
					dbo.cvo_lot_bin_stock_exclusions (NOLOCK)
				WHERE	
					location = @location  
					AND	part_no = @part_no  

				SET	 @in_stock = ISNULL(@in_stock,0) - ISNULL(@in_stock_ex,0)
		
				SET @replen_qty = 0
				SELECT	
					@replen_qty = ISNULL(replen_qty,0) 
				FROM 
					dbo.inventory (NOLOCK)  
				WHERE 
					location = @location  
					AND part_no = @part_no 

				SET @in_stock = @in_stock - @replen_qty


	  
				-- WMS - allocated and quarantined  
				DELETE #wms_ret  

				INSERT #wms_ret  
				EXEC tdc_get_alloc_qntd_sp @location, @part_no  

				SELECT 
					@alloc_qty = allocated_qty,  
					@quar_qty = quarantined_qty  
				FROM 
					#wms_ret  

				IF (@alloc_qty IS NULL)  
				BEGIN
					SET @alloc_qty = 0  
				END

				IF (@quar_qty IS NULL)  
				BEGIN
					SET @quar_qty = 0  
				END
	      
				SELECT 
					@sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)  
				FROM 
					dbo.cvo_soft_alloc_det a (NOLOCK)  
				WHERE 
					a.status IN (0, 1, -1, -4) 
					AND a.soft_alloc_no < @soft_alloc_no 
					AND a.location = @location  
				AND  a.part_no = @part_no  

	  
				IF (@sa_qty IS NULL)  
				BEGIN
					SET @sa_qty = 0  
				END
	  
				-- Compare - if no stock available then mark the record  
				IF ((@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) < @qty) 
				BEGIN  
					UPDATE 
						#cf_break  
					SET  
						no_stock = 1  
					WHERE 
						id = @id  
		   
		 
					INSERT #cf_allocs_line (order_no, order_ext, line_no, no_stock)  
					SELECT @order_no, @order_ext, @line_no, 1  

	  
				END  
	  
				SET @last_id = @id  
		  
				SELECT TOP 1 
					@id = id,  
					@location = location,  
					@line_no = line_no,  
					@part_no = part_no,  
					@qty = qty 
				FROM 
					#cf_break  
				WHERE 
					id > @last_id  
				ORDER BY 
					id ASC  
		  
			END  
		END  
	  
		IF EXISTS (SELECT 1 FROM #cf_break_kit) -- Test for substitution at kit level  
		BEGIN  
			SET @last_id = 0  
	  
			SELECT TOP 1 
				@id = id,  
				@location = location,  
				@qty = qty, -- v1.1  
				@line_no = kit_line_no,  
				@part_no = kit_part_no  
			FROM 
				#cf_break_kit  
			WHERE 
				id > @last_id  
			ORDER BY 
				id ASC  
	  
			WHILE @@ROWCOUNT <> 0  
			BEGIN  
		  
				SET @in_stock = 0  
				SET @in_stock_ex = 0 
				SET @alloc_qty = 0  
				SET @quar_qty = 0  
				SET @sa_qty = 0  
	 
				SELECT	
					@in_stock = SUM(qty)
				FROM	
					dbo.lot_bin_stock (NOLOCK)
				WHERE	
					location = @location  
					AND	part_no = @part_no  

				SELECT	
					@in_stock_ex = SUM(qty)
				FROM	
					dbo.cvo_lot_bin_stock_exclusions (NOLOCK)
				WHERE	
					location = @location  
					AND	part_no = @part_no  

				SET	 @in_stock = ISNULL(@in_stock,0) - ISNULL(@in_stock_ex,0)

				SET @replen_qty = 0
				SELECT	
					@replen_qty = ISNULL(replen_qty,0) 
				FROM 
					dbo.inventory (NOLOCK)  
				WHERE 
					location = @location  
					AND part_no = @part_no 

				SET @in_stock = @in_stock - @replen_qty
		 
				-- WMS - allocated and quarantined  
				DELETE #wms_ret  
	    
				INSERT #wms_ret  
				EXEC tdc_get_alloc_qntd_sp @location, @part_no  
		  
				SELECT 
					@alloc_qty = allocated_qty,  
					@quar_qty = quarantined_qty  
				FROM 
					#wms_ret  
		  
				IF (@alloc_qty IS NULL)  
				BEGIN
					SET @alloc_qty = 0  
				END

				IF (@quar_qty IS NULL)  
				BEGIN
					SET @quar_qty = 0  
				END
	  
	    
				SELECT 
					@sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)  
				FROM 
					dbo.cvo_soft_alloc_det a (NOLOCK)  
				WHERE 
					a.status IN (0, 1, -1, -4) 
					AND a.soft_alloc_no < @soft_alloc_no 
					AND a.location = @location  
					AND a.part_no = @part_no  

		  
				IF (@sa_qty IS NULL)  
				BEGIN
					SET @sa_qty = 0  
				END
	  
				-- Compare - if no stock available then mark the record  
				IF ((@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) < @qty) 
				BEGIN  
					UPDATE 
						#cf_break_kit  
					SET  
						no_stock = 1  
					WHERE 
						id = @id  
		  
				
					INSERT #cf_allocs_line (order_no, order_ext, line_no, no_stock)  
					SELECT @order_no, @order_ext, @line_no, 1  
			
		  
				END  
	  
				SET @last_id = @id  
		  
				SELECT TOP 1 
					@id = id,  
					@location = location,  
					@qty = qty, 
					@line_no = kit_line_no,  
					@part_no = kit_part_no  
				FROM 
					#cf_break_kit  
				WHERE 
					id > @last_id  
				ORDER BY 
					id ASC  
		  
			END  
		END  
	  
		-- Mark the frame record if no stock available for the substitution  
		UPDATE 
			a  
		SET  
			no_stock = 1  
		FROM 
			#cf_break a  
		INNER JOIN 
			#cf_break_kit b  
		ON  
			a.soft_alloc_no = b.soft_alloc_no  
			AND a.line_no = b.kit_line_no  
		WHERE 
			b.no_stock = 1  

		-- Mark the data to be returned to show no stock is available  
		UPDATE 
			a  
		SET  
			no_stock = 1  
		FROM 
			#cf_allocs a  
		JOIN 
			#cf_break b  
		ON  
			a.soft_alloc_no = b.soft_alloc_no  
		WHERE 
			b.no_stock = 1  

		SET @last_soft_alloc_no = @soft_alloc_no  
	  
		SELECT TOP 1 
			@soft_alloc_no = soft_alloc_no,  
			@order_no = order_no,  
			@order_ext = order_ext  
		FROM 
			#cf_allocs  
		WHERE 
			soft_alloc_no > @last_soft_alloc_no  
		ORDER BY 
			soft_alloc_no ASC  
	END   
	  
	INSERT #exclusions (order_no, order_ext)  
	SELECT order_no, order_ext FROM #cf_allocs WHERE no_stock = 1  
	  
	-- Does the order have regular frames and is ship complete  
	UPDATE 
		a  
	SET  
		has_line_exc = 1  
	FROM 
		#exclusions a  
	INNER JOIN 
		#cf_allocs b  
	ON  
		a.order_no = b.order_no  
		AND a.order_ext = b.order_ext  
	INNER JOIN 
		cvo_ord_list c (NOLOCK)  
	ON 
		a.order_no = c.order_no  
		AND a.order_ext = c.order_ext  
	INNER JOIN 
		orders_all o (NOLOCK)  
	ON  
		a.order_no = o.order_no  
		AND a.order_ext = o.ext  
	WHERE 
		c.is_case = 0   
		AND c.is_pattern = 0   
		AND c.is_polarized = 0   
		AND c.is_pop_gif = 0   
		AND c.is_customized = 'N'  
		AND o.back_ord_flag = 1  
	  
	-- Record which lines need to be excluded from the allocation  
	INSERT #line_exclusions (
		order_no, 
		order_ext, 
		line_no)  
	SELECT DISTINCT 
		a.order_no, 
		a.order_ext, 
		a.line_no  
	FROM 
		dbo.cvo_ord_list a (NOLOCK)  
	INNER JOIN 
		#exclusions b  
	ON  
		a.order_no = b.order_no  
		AND a.order_ext = b.order_ext  
	INNER JOIN 
		#cf_allocs_line c  
	ON  
		a.order_no = c.order_no  
		AND a.order_ext = c.order_ext  
		AND a.line_no = c.line_no  
	WHERE 
		a.is_case = 0   
		AND a.is_pattern = 0   
		AND a.is_polarized = 0   
		AND a.is_pop_gif = 0   
		AND a.is_customized = 'S'  
		AND c.no_stock = 1  
	  
	 
	  
	DELETE 
		#exclusions  
	WHERE 
		ISNULL(has_line_exc,0) = 1  

	DROP TABLE #cf_allocs  
	DROP TABLE #cf_break  
	DROP TABLE #cf_break_kit  
	DROP TABLE #wms_ret  
	DROP TABLE #cf_allocs_line 
  
END  
GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_CF_check_sp] TO [public]
GO
