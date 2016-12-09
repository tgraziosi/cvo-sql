SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_Release_Ship_Complete]
AS
BEGIN
	-- Declarations
	DECLARE	@order_no		int,
			@ext			int,
			@row_id			int,
			@last_row_id	int,
			@iRet			int,
			@hold_reason	varchar(30)
			
	-- Create working table to hold orders to process
	CREATE TABLE #sc_orders (
			row_id		int IDENTITY(1,1),
			order_no	int,
			ext			int)

	-- Insert the orders to process
	INSERT	#sc_orders (order_no, ext)
	SELECT	order_no, ext
	FROM	dbo.orders_all (NOLOCK)
	WHERE	status = 'A'
	AND		hold_reason = 'SC'
	ORDER BY order_no, ext
	
	-- Run through all the ship complete hold orders
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@ext = ext
	FROM	#sc_orders
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Call the release routine
		EXEC @iRet = dbo.cvo_process_ship_complete_sp @order_no, @ext

		IF (@iRet = 0)
		BEGIN
			-- v1.3 Start
			INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			SELECT	GETDATE(), SUSER_NAME(), 'BO', 'SHIP COMPLETE', 'ORDER UPDATE', @order_no, @ext, '', '', '', '', '', 'STATUS:N/RELEASE SHIP COMPLETE HOLD; HOLD REASON:'					
			-- v1.3 End


			-- START v1.2
			EXEC @iRet = dbo.cvo_process_release_date_sp @order_no, @ext, 1 -- v1.3

			-- v1.3 Start			
			-- Doesn't need to be on release date hold
			--IF (@iRet = 0)
			--BEGIN

			SET @hold_reason = ''

			SELECT	@hold_reason = hold_reason
			FROM	cvo_next_so_hold_vw (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @ext

			--SELECT	@hold_reason = ISNULL(prior_hold,'') 
			--FROM	cvo_orders_all (NOLOCK)
			--WHERE	order_no = @order_no
			--AND		ext = @ext
		
			IF (@hold_reason > '')
			BEGIN

				UPDATE	orders_all WITH (ROWLOCK)
				SET		status = CASE WHEN @hold_reason IN ('CL','PD') THEN 'C' ELSE 'A' END,
						hold_reason = @hold_reason
				WHERE	order_no = @order_no
				AND		ext = @ext

				DELETE	cvo_so_holds
				WHERE	order_no = @order_no
				AND		order_ext = @ext
				AND		hold_reason = @hold_reason

				INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
				SELECT	GETDATE(), SUSER_NAME(), 'BO', 'SHIP COMPLETE', 'ORDER UPDATE', @order_no, @ext, '', '', '', '', '', 'STATUS:A/PROMOTE USER HOLD; HOLD REASON: ' + @hold_reason		
				UPDATE	orders_all
				SET		hold_reason = @hold_reason
				WHERE	order_no = @order_no
				AND		ext = @ext

				--UPDATE	cvo_orders_all
				--SET		prior_hold = ''
				--WHERE	order_no = @order_no
				--AND		ext = @ext
			END
			/*
				ELSE
				BEGIN
					UPDATE	orders_all
					SET		hold_reason = '',
							status = 'N'
					WHERE	order_no = @order_no
					AND		ext = @ext
				END
			END
			ELSE
			BEGIN
				-- Change to release date hold
				UPDATE	orders_all
				SET		hold_reason = 'RD'
				WHERE	order_no = @order_no
				AND		ext = @ext
			END
			-- END v1.2
			*/
			-- v1.3 End

		END

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@ext = ext
		FROM	#sc_orders
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	DROP TABLE #sc_orders

	RETURN
END
GO
GRANT EXECUTE ON  [dbo].[CVO_Release_Ship_Complete] TO [public]
GO
