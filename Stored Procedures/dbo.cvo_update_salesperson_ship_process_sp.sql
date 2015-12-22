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
			@today			int

	-- Working Tables
	CREATE TABLE #cvo_ship_process (
		row_id			int,
		order_no		int,
		order_ext		int,
		trx_ctrl_num	varchar(16),
		salesperson		varchar(10),
		territory		varchar(10))
		
	-- Get the records to process
	INSERT	#cvo_ship_process (row_id, order_no, order_ext, trx_ctrl_num, salesperson, territory)
	SELECT	row_id, 
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

		-- Update the orders
		UPDATE	orders_all
		SET		salesperson = @salesperson,
				ship_to_region = @territory
		WHERE	order_no = @order_no
		AND		ext = @order_ext

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
