SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			cvo_process_out_of_stock_orders_sp		
Project ID:		Issue 680
Type:			Stored Procedure
Description:	Creates back orders for all out of stock orders
Developer:		Chris Tyler

History
-------
v1.0	19/07/12	CT	Original version
v1.1	01/05/13	CT	Take into account stock soft allocated
v1.2	08/05/13	CT	Added logic to check Custom Frames
v1.3	03/05/2016	CB	Record transaction in tdc_log
*/

CREATE PROC [dbo].[cvo_process_out_of_stock_orders_sp]
AS
BEGIN
	DECLARE @order_no	INT,
			@ext		INT,
			@line_no	INT,
			@ordered	DECIMAL (20,8),
			@outofstock	SMALLINT,
			@location	VARCHAR(10),
			@part_no	VARCHAR(30),
			@available	DECIMAL(20,8),
			@new_ext	INT,
			@retval		SMALLINT,
			@soft_alloc_no INT, -- v1.1
			@sa_qty		DECIMAL(20,8) -- v1.1

	SET @order_no = 0
	
	-- v1.1
	CREATE TABLE #soft_alloc_qty (qty decimal(20,8)) 

	-- Loop through orders
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@order_no = a.order_no,
			@ext = a.ext
		FROM
			dbo.orders_all a (NOLOCK)
		INNER JOIN
			dbo.cvo_orders_all b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.ext = b.ext
		LEFT JOIN
			dbo.tdc_soft_alloc_tbl c (NOLOCK)
		ON
			a.order_no = c.order_no
			AND a.ext = c.order_ext
		WHERE
			a.order_no > @order_no
			AND a.type = 'I'
			AND a.[status] = 'N'
			AND a.ext = 0
			AND ISNULL(b.allocation_date,GETDATE()) <= GETDATE()
			AND c.order_no IS NULL
		ORDER BY
			a.order_no

		IF @@ROWCOUNT = 0
			BREAK

		SET @outofstock = 1 -- true
		SET @line_no = -1

		-- If any lines on the order have shipped <> 0 then it's not out of stock
		IF EXISTS (SELECT 1 FROM dbo.ord_list (NOLOCK) WHERE order_no = @order_no and order_ext = @ext AND (([status] > 'N' AND [status] < 'V') OR (shipped <> 0)))
		BEGIN
			SET @outofstock = 0 -- false
		END
		ELSE
		BEGIN
			-- Loop through all lines which are not CASE or PATTERN and check stock
			WHILE 1=1
			BEGIN
				SELECT TOP 1
					@line_no = a.line_no,
					@ordered = a.ordered,
					@location = a.location,
					@part_no = a.part_no
				FROM
					dbo.ord_list a (NOLOCK)
				INNER JOIN
					dbo.inv_master b (NOLOCK)
				ON
					a.part_no = b.part_no
				WHERE
					b.type_code NOT IN ('CASE','PATTERN')
					AND a.order_no = @order_no
					AND a.order_ext = @ext
					AND a.line_no > @line_no
					AND a.ordered > 0
				ORDER BY
					a.line_no

				IF @@ROWCOUNT = 0
					BREAK

				-- START v1.2
				-- If this is a Custom Frame, then check components are in stock
				IF EXISTS (SELECT 1 FROM dbo.cvo_ord_list (NOLOCK) WHERE order_no = @order_no  AND order_ext = @ext AND line_no = @line_no and ISNULL(is_customized,'N') = 'S')
				BEGIN
					EXEC @retval = cvo_soft_alloc_CF_OOS_check_sp @order_no, @ext, @line_no 
					IF @retval = 0
					BEGIN
						SET @outofstock = 0	-- false
						BREAK
					END 
				END
				ELSE
				BEGIN
				-- END v1.2

					-- Check available stock for this part
					SET @available = 0
					EXEC @available = dbo.CVO_CheckAvailabilityInStock_sp   @part_no , @location , 0

					-- START v1.1
					SELECT @soft_alloc_no = MAX(soft_alloc_no) FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext
					
					SET @soft_alloc_no = ISNULL(@soft_alloc_no,-1)
					
					INSERT #soft_alloc_qty  
					EXEC dbo.cvo_get_available_stock_sp @soft_alloc_no, @location, @part_no  

					SELECT @sa_qty = qty FROM #soft_alloc_qty  

					DELETE #soft_alloc_qty  

					SET @available = ISNULL(@available,0) - ISNULL(@sa_qty,0)

					IF ISNULL(@available,0) > 0  
					-- IF ISNULL(@available,0) <> 0 
					-- END v1.1 
					BEGIN
						SET @outofstock = 0	-- false
						BREAK
					END	
				END -- v1.2
			END
		END

		-- If order is out of stock then create a back order and void the existing one
		IF @outofstock = 1
		BEGIN
			BEGIN TRAN
			
			-- Get next extension for this order
			SELECT 
				@new_ext = MAX(ext) + 1
			FROM
				dbo.orders_all (NOLOCK)
			WHERE
				order_no = @order_no

			EXEC @retval = dbo.cvo_change_order_to_backorder_sp	@order_no, @ext, @new_ext
			IF ISNULL(@retval,1) <> 0 
			BEGIN
				ROLLBACK TRAN
			END
			ELSE
			BEGIN
				-- v1.3 Start
				INSERT INTO dbo.tdc_log (tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data) 
				SELECT	GETDATE() , 'OUTOFSTOCK' , 'VB' , 'PLW' , 'OUTOFSTOCK' , @order_no , @ext , '' , '' , '' , '' , '' ,'VOID ORDER' 
				INSERT INTO dbo.tdc_log (tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data) 
				SELECT	GETDATE() , 'OUTOFSTOCK' , 'VB' , 'PLW' , 'OUTOFSTOCK' , @order_no , @new_ext , '' , '' , '' , '' , '' ,'OUT OF STOCK EXT CREATED' 
				-- v1.3 End
				COMMIT TRAN
			END
		END
	END
	
	-- v1.1
	DROP TABLE #soft_alloc_qty
END
GO
GRANT EXECUTE ON  [dbo].[cvo_process_out_of_stock_orders_sp] TO [public]
GO
