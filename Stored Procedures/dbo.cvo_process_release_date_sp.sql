SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- EXEC dbo.cvo_process_release_date_sp 1420223, 0
CREATE PROC [dbo].[cvo_process_release_date_sp] @order_no	int,
											@order_ext	int,
											@check_only	int = 0 -- v1.2
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@status			varchar(8),
			@hold_reason	varchar(30)

	-- Working Tables
	CREATE TABLE #release_date (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		part_no			varchar(30),
		release_date	varchar(10) NULL,
		released_flag	int)

	-- Insert working data
	INSERT	#release_date (order_no, order_ext, part_no, released_flag)
	SELECT	order_no, order_ext, part_no, 1
	FROM	dbo.ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	INSERT	#release_date (order_no, order_ext, part_no, released_flag)
	SELECT	order_no, order_ext, part_no, 1
	FROM	dbo.ord_list_kit (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	-- Update the working table with the recorded release dates from inventory
	UPDATE	a
	SET		release_date = CONVERT(varchar(10),ISNULL(b.field_26,'1900-01-01'),121)
	FROM	#release_date a
	JOIN	inv_master_add b (NOLOCK)
	ON		a.part_no = b.part_no
	
	-- Mark any records that have not been released
	UPDATE	#release_date
	SET		released_flag = 0
	WHERE	release_date > CONVERT(varchar(10),GETDATE(),121)

	-- v1.2 Start
	IF (@check_only = 1)
	BEGIN
		IF EXISTS (SELECT 1 FROM #release_date WHERE released_flag = 0)
		BEGIN
			SELECT -1
			RETURN -1
		END
		ELSE
		BEGIN
			SELECT 0
			RETURN 0
		END			
	END
	ELSE
	BEGIN
		-- Check for any unreleased records
		IF EXISTS (SELECT 1 FROM #release_date WHERE released_flag = 0)
		BEGIN

			SELECT	@status = status,
					@hold_reason = hold_reason
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			IF (@status = 'A') 
			BEGIN
				IF (@hold_reason <> 'RD' )
				BEGIN
					-- v1.3 Start
					INSERT	cvo_so_holds
					SELECT	@order_no, @order_ext, 'RD', dbo.f_get_hold_priority('RD',''),
						SUSER_NAME(), GETDATE()

					--UPDATE	cvo_orders_all WITH (ROWLOCK)
					--SET		prior_hold = 'RD'
					--WHERE	order_no = @order_no
					--AND		ext = @order_ext

					INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
					SELECT	GETDATE(), SUSER_NAME(), 'BO', 'RELEASE DATE', 'ORDER UPDATE', @order_no, @order_ext, '', '', '', '', '', 'ADD HOLD: RD - RELEASE DATE'
					
				END
				-- v1.3 End

				SELECT 0
				RETURN -1
			END

			IF (@status IN ('C','H','B'))
			BEGIN

				-- v1.3 Start
				INSERT	cvo_so_holds
				SELECT	@order_no, @order_ext, 'RD', dbo.f_get_hold_priority('RD',''),
					SUSER_NAME(), GETDATE()

				--UPDATE	cvo_orders_all WITH (ROWLOCK)
				--SET		prior_hold = 'RD'
				--WHERE	order_no = @order_no
				--AND		ext = @order_ext

				INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
				SELECT	GETDATE(), SUSER_NAME(), 'BO', 'RELEASE DATE', 'ORDER UPDATE', @order_no, @order_ext, '', '', '', '', '', 'ADD HOLD: RD - RELEASE DATE'
				-- v1.3 End

				SELECT 0
				RETURN -1
			END

			IF (@status = 'N')					
			BEGIN
				UPDATE	orders_all WITH (ROWLOCK)
				SET		status = 'A',
						hold_reason = 'RD'
				WHERE	order_no = @order_no
				AND		ext = @order_ext

				-- v1.3 Start
				INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
				SELECT	GETDATE(), SUSER_NAME(), 'BO', 'RELEASE DATE', 'ORDER UPDATE', @order_no, @order_ext, '', '', '', '', '', 'STATUS:A/RELEASE DATE; HOLD REASON: RD'					
				-- v1.3 End

				SELECT -1
				RETURN -1
			END
		END
		ELSE
		BEGIN
			-- v1.3 Start
			SET @hold_reason = ''

			SELECT	@hold_reason = hold_reason
			FROM	cvo_next_so_hold_vw (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext

			IF (@hold_reason > '')
			BEGIN

				INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
				SELECT	GETDATE(), SUSER_NAME(), 'BO', 'RELEASE DATE', 'ORDER UPDATE', @order_no, @order_ext, '', '', '', '', '', 'STATUS:N/RELEASE RD USER HOLD; HOLD REASON:'					

				UPDATE	orders_all WITH (ROWLOCK)
				SET		status = CASE WHEN @hold_reason IN ('CL','PD') THEN 'C' ELSE 'A' END,
						hold_reason = @hold_reason
				WHERE	order_no = @order_no
				AND		ext = @order_ext
				AND		hold_reason = 'RD'

				DELETE	cvo_so_holds
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		hold_reason = @hold_reason

				INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
				SELECT	GETDATE(), SUSER_NAME(), 'BO', 'RELEASE DATE', 'ORDER UPDATE', @order_no, @order_ext, '', '', '', '', '', 'STATUS:A/PROMOTE USER HOLD; HOLD REASON: ' + @hold_reason					
			
			END
			ELSE
			BEGIN
				INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
				SELECT	GETDATE(), SUSER_NAME(), 'BO', 'RELEASE DATE', 'ORDER UPDATE', @order_no, @order_ext, '', '', '', '', '', 'STATUS:N/RELEASE RD USER HOLD; HOLD REASON:'					

				UPDATE	orders_all WITH (ROWLOCK)
				SET		status = 'N',
						hold_reason = ''
				WHERE	order_no = @order_no
				AND		ext = @order_ext
				AND		hold_reason = 'RD'
			END
							
			--UPDATE	cvo_orders_all WITH (ROWLOCK)
			--SET		prior_hold = ''
			--WHERE	order_no = @order_no
			--AND		ext = @order_ext
			--AND		prior_hold = 'RD'
			-- v1.3 End

			SELECT 0
			RETURN 0
		END
	END
	-- v1.2 End
END
GO

GRANT EXECUTE ON  [dbo].[cvo_process_release_date_sp] TO [public]
GO
