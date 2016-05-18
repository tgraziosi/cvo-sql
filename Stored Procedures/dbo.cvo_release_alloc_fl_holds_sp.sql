SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_release_alloc_fl_holds_sp]
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @row_id			int,
			@last_row_id	int,
			@soft_alloc_no	int,
			@order_no		int,
			@order_ext		int,
			@rc				int,
			@prior_hold		varchar(20), -- v1.2
			@msg			varchar(50) -- v1.2

	-- WORKING TABLES
	CREATE TABLE #fl_orders (
		row_id			int IDENTITY(1,1),
		soft_alloc_no	int,
		order_no		int,
		order_ext		int,
		process			int,
		prior_hold		varchar(20)) -- v1.2

	CREATE TABLE #cf_check (
		result	varchar(10))

	CREATE TABLE #exclusions (
		order_no		int,
		order_ext		int,
		has_line_exc	int NULL)

	-- Insert working data
	INSERT	#fl_orders (soft_alloc_no, order_no, order_ext, process, prior_hold)
	SELECT	c.soft_alloc_no,
			a.order_no, 
			a.ext,
			0,
			ISNULL(b.prior_hold,'') -- v1.2
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.ext
	JOIN	cvo_soft_alloc_hdr c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.type = 'I'
	AND		a.status = 'A'
	AND		a.hold_reason = 'FL'
-- v1.2	AND		ISNULL(b.prior_hold,'') = ''
	AND		a.order_no > 1420973
	ORDER BY a.order_no, a.ext	 

	-- Step 1 - Check stock
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@soft_alloc_no = soft_alloc_no,
			@order_no = order_no,
			@order_ext = order_ext
	FROM	#fl_orders
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
			
	WHILE (@@ROWCOUNT <> 0)
	BEGIN
	
		-- Custom Frame Check
		TRUNCATE TABLE #exclusions

		EXEC cvo_soft_alloc_CF_BO_check_sp @soft_alloc_no, @order_no, @order_ext

		IF EXISTS (SELECT 1 FROM #exclusions WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			UPDATE	#fl_orders
			SET		process = -1
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@soft_alloc_no = soft_alloc_no,
					@order_no = order_no,
					@order_ext = order_ext
			FROM	#fl_orders
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END
		
		TRUNCATE TABLE #exclusions
		
		EXEC cvo_check_fl_stock_pre_allocation_sp @order_no, @order_ext
		
		IF EXISTS (SELECT 1 FROM #exclusions WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			UPDATE	#fl_orders
			SET		process = -1
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@soft_alloc_no = soft_alloc_no,
					@order_no = order_no,
					@order_ext = order_ext
			FROM	#fl_orders
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@soft_alloc_no = soft_alloc_no,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#fl_orders
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	DELETE	#fl_orders
	WHERE	process = -1

	-- Step 2 - Release Hold & Allocate
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@prior_hold = prior_hold -- v1.2
	FROM	#fl_orders
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
			
	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		-- v1.2 Start
		IF (@prior_hold <> '')
		BEGIN
			INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
			SELECT	GETDATE() , 'FL HOLD RELEASE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
					'STATUS:N/RELEASE FL USER HOLD; HOLD REASON:' 
			FROM	orders_all a (NOLOCK)
			WHERE	a.order_no = @order_no
			AND		a.ext = @order_ext

			UPDATE	orders_all
			SET		hold_reason = @prior_hold
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			UPDATE	cvo_orders_all
			SET		prior_hold = NULL
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			SET @msg = 'STATUS:A/PRIOR HOLD; HOLD REASON:' + @prior_hold
	
			INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
			SELECT	GETDATE() , 'FL HOLD RELEASE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' , @msg
			FROM	orders_all a (NOLOCK)
			WHERE	a.order_no = @order_no
			AND		a.ext = @order_ext

			UPDATE	#fl_orders
			SET		process = -4
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@prior_hold = prior_hold -- v1.2
			FROM	#fl_orders
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END
		-- v1.2 End

		UPDATE	orders_all
		SET		status = 'N',
				hold_reason = ''
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		-- v1.1 Start
		INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
		SELECT	GETDATE() , 'FL HOLD RELEASE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
				'STATUS:N/RELEASE FL USER HOLD; HOLD REASON:' 
		FROM	orders_all a (NOLOCK)
		WHERE	a.order_no = @order_no
		AND		a.ext = @order_ext
		-- v1.1 End

		IF EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr a (NOLOCK) JOIN cvo_orders_all b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.ext
						WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND b.allocation_date > getdate() AND a.status = -3)
		BEGIN

			UPDATE	#fl_orders
			SET		process = -2
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@prior_hold = prior_hold -- v1.2
			FROM	#fl_orders
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END

		IF EXISTS (SELECT 1 FROM dbo.orders_all a (NOLOCK) INNER JOIN dbo.cvo_soft_alloc_hdr b (NOLOCK) ON a.order_no = b.order_no
					AND a.ext = b.order_ext WHERE a.order_no = @order_no AND a.ext = @order_ext AND b.status = 0 
					AND CONVERT(varchar(10),ISNULL(a.sch_ship_date,GETDATE()),121) > CONVERT(varchar(10),GETDATE(),121)) 
		BEGIN

			UPDATE	#fl_orders
			SET		process = -3
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@prior_hold = prior_hold -- v1.2
			FROM	#fl_orders
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END

		EXEC @rc = tdc_order_after_save @order_no, @order_ext   

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@prior_hold = prior_hold -- v1.2
		FROM	#fl_orders
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
			
	END

	-- Clean up
	DROP TABLE #fl_orders
	DROP TABLE #cf_check
	DROP TABLE #exclusions
	

END
GO
GRANT EXECUTE ON  [dbo].[cvo_release_alloc_fl_holds_sp] TO [public]
GO
