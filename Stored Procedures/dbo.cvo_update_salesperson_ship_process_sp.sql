SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_update_salesperson_ship_process_sp]
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@row_id			int,
			@last_row_id	int,
			@order_no		int,
			@order_ext		int,
			@trx_ctrl_num	varchar(16),
			@salesperson	varchar(10),
			@territory		varchar(10),
			@commission		decimal(20,8),
			@today			int,
			@old_salesperson varchar(10) -- v1.2

	-- Working Tables
	CREATE TABLE #cvo_ship_process (
		row_id			int IDENTITY(1,1), -- v1.1
		order_no		int,
		order_ext		int,
		trx_ctrl_num	varchar(16),
		salesperson		varchar(10),
		territory		varchar(10))
		
	-- Get the records to process
-- v1.1	INSERT	#cvo_ship_process (row_id, order_no, order_ext, trx_ctrl_num, salesperson, territory)
	INSERT	#cvo_ship_process (order_no, order_ext, trx_ctrl_num, salesperson, territory) -- v1.1
	SELECT	-- v1.1row_id, 
			order_no, 
			order_ext, 
			'', 
			new_salesperson_code, 
			new_territory_code
	FROM	dbo.cvo_update_salesperson_ship
	WHERE	process = 'Y'

	-- Get the trx_ctrl_num from AR
	UPDATE	a
	SET		trx_ctrl_num = b.trx_ctrl_num
	FROM	#cvo_ship_process a
	JOIN	artrx b (NOLOCK)
	ON		(CAST(a.order_no as varchar(20)) + '-' + CAST(a.order_ext as varchar(10))) = b.order_ctrl_num

	UPDATE	a
	SET		trx_ctrl_num = b.trx_ctrl_num
	FROM	#cvo_ship_process a
	JOIN	arinpchg b (NOLOCK)
	ON		(CAST(a.order_no as varchar(20)) + '-' + CAST(a.order_ext as varchar(10))) = b.order_ctrl_num

	-- v1.1 Start
	INSERT	#cvo_ship_process (order_no, order_ext, trx_ctrl_num, salesperson, territory)
	SELECT	a.order_no, a.order_ext, b.trx_ctrl_num, a.salesperson, a.territory
	FROM	#cvo_ship_process a
	LEFT JOIN artrx b (NOLOCK)
	ON		(CAST(a.order_no as varchar(20)) + '-' + CAST(a.order_ext as varchar(10))) = b.order_ctrl_num
	WHERE	a.trx_ctrl_num <> b.trx_ctrl_num

	INSERT	#cvo_ship_process (order_no, order_ext, trx_ctrl_num, salesperson, territory)
	SELECT	a.order_no, a.order_ext, b.trx_ctrl_num, a.salesperson, a.territory
	FROM	#cvo_ship_process a
	LEFT JOIN arinpchg b (NOLOCK)
	ON		(CAST(a.order_no as varchar(20)) + '-' + CAST(a.order_ext as varchar(10))) = b.order_ctrl_num
	WHERE	a.trx_ctrl_num <> b.trx_ctrl_num
	-- v1.1 End

select * from #cvo_ship_process


	-- Update the records
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext, 
			@trx_ctrl_num = trx_ctrl_num, 
			@salesperson = salesperson, 
			@territory = territory
	FROM	#cvo_ship_process
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		-- v1.2 Start
		SELECT	@old_salesperson = salesperson
		FROM	orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		ext = @order_ext
		-- v1.2 End

		-- Update the orders
		UPDATE	orders_all
		SET		salesperson = @salesperson,
				ship_to_region = @territory
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		-- v1.2 Start
		UPDATE	ord_rep
		SET		salesperson = @salesperson
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		salesperson = @old_salesperson
		-- v1.2 End

		-- Update the commission
		SELECT	@commission = dbo.f_get_order_commission(@order_no,@order_ext)

		IF (@commission IS NULL)
			SET @commission = 0

		UPDATE	cvo_orders_all
		SET		commission_pct = @commission
		WHERE	order_no = @order_no
		AND		ext = @order_ext
		
		-- Update AR
		UPDATE	arinpchg_all
		SET		salesperson_code = @salesperson,
				territory_code = @territory
		WHERE	trx_ctrl_num = @trx_ctrl_num

		UPDATE	arinpage
		SET		salesperson_code = @salesperson,
				territory_code = @territory
		WHERE	trx_ctrl_num = @trx_ctrl_num
		
		UPDATE	artrx_all
		SET		salesperson_code = @salesperson,
				territory_code = @territory
		WHERE	trx_ctrl_num = @trx_ctrl_num
		
		UPDATE	artrxage
		SET		salesperson_code = @salesperson,
				territory_code = @territory
		WHERE	trx_ctrl_num = @trx_ctrl_num


		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext, 
				@trx_ctrl_num = trx_ctrl_num, 
				@salesperson = salesperson, 
				@territory = territory
		FROM	#cvo_ship_process
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END

	-- Update activity and summary for salesperson and territory
	EXEC aractsum_sp 0, 0, 0, 1, 1, 0, 0, 0, 1, 1 

	-- Update activity and aging if they are switched on
	IF EXISTS (SELECT 1 FROM arco (NOLOCK) WHERE aractslp_flag = 1 OR aractter_flag = 1)
	BEGIN
		SELECT	@today = DATEDIFF(DAY, '01/01/1900', GETDATE())+693596
		EXEC arageact_sp @today, 0, 0, 1, 1,'', '', '<First>', '<Last>', '<First>', '<Last>','<First>', '<Last>', 0, 1, 1, 1
	END

	-- Clear the processing table
	DELETE	cvo_update_salesperson_ship
	WHERE	process = 'Y'

	-- Clean up
	DROP TABLE #cvo_ship_process

END
GO
GRANT EXECUTE ON  [dbo].[cvo_update_salesperson_ship_process_sp] TO [public]
GO
