SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CVO_Release_Release_Date_Holds_sp]
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
	CREATE TABLE #rd_orders (
			row_id		int IDENTITY(1,1),
			order_no	int,
			ext			int)

	-- Insert the orders to process
	INSERT	#rd_orders (order_no, ext)
	SELECT	order_no, ext
	FROM	dbo.orders_all (NOLOCK)
	WHERE	status = 'A'
	AND		hold_reason = 'RD'
	ORDER BY order_no, ext
	
	-- Run through all the release date hold orders
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@ext = ext
	FROM	#rd_orders
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Call the release routine
		EXEC @iRet = dbo.cvo_process_release_date_sp @order_no, @ext

		IF (@iRet = 0)
		BEGIN
			-- START v1.3
			IF EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND back_ord_flag = 1)
			BEGIN
				-- START v1.2
				EXEC @iRet = dbo.cvo_process_ship_complete_sp @order_no, @ext
			END
			-- END v1.3

			-- Doesn't need to be on ship complete hold
			IF (@iRet = 0)
			BEGIN
				-- v1.4 Start
				SET @hold_reason = ''

				SELECT	@hold_reason = hold_reason
				FROM	cvo_next_so_hold_vw (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @ext

				--SELECT	@hold_reason = ISNULL(prior_hold,'') 
				--FROM	cvo_orders_all (NOLOCK)
				--WHERE	order_no = @order_no
				--AND		ext = @ext
				-- v1.4 end

				IF (@hold_reason > '')
				BEGIN
					-- v1.4 Start
					UPDATE	orders_all
					SET		status = CASE WHEN @hold_reason IN ('CL','PD') THEN 'C' ELSE 'A' END,
							hold_reason = @hold_reason
					WHERE	order_no = @order_no
					AND		ext = @ext

					INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
					SELECT	GETDATE(), SUSER_NAME(), 'BO', 'RELEASE DATE', 'ORDER UPDATE', @order_no, @ext, '', '', '', '', '', 'STATUS:A/PROMOTE USER HOLD; HOLD REASON: ' + @hold_reason		

					DELETE	cvo_so_holds
					WHERE	order_no = @order_no
					AND		order_ext = @ext
					AND		hold_reason = @hold_reason

					--UPDATE	orders_all
					--SET		hold_reason = @hold_reason
					--WHERE	order_no = @order_no
					--AND		ext = @ext

					--UPDATE	cvo_orders_all
					--SET		prior_hold = ''
					--WHERE	order_no = @order_no
					--AND		ext = @ext
					-- v1.4 End
				END
				ELSE
				BEGIN
					UPDATE	orders_all
					SET		hold_reason = '',
							status = 'N'
					WHERE	order_no = @order_no
					AND		ext = @ext
					AND		status <> 'N' -- v1.4

					-- v1.4 Start
					--UPDATE	cvo_orders_all
					--SET		prior_hold = ''
					--WHERE	order_no = @order_no
					--AND		ext = @ext
					--AND		prior_hold = 'RD'
					-- v1.4 End

				END
			END
			-- v1.4 Start
			--ELSE
			--BEGIN
				-- Change to ship complete hold
			--	UPDATE	orders_all
			--	SET		hold_reason = 'SC'
			--	WHERE	order_no = @order_no
			--	AND		ext = @ext
				
			--END
			-- v1.4 End
			-- END v1.2

		END

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@ext = ext
		FROM	#rd_orders
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	DROP TABLE #rd_orders

	RETURN
END
GO
GRANT EXECUTE ON  [dbo].[CVO_Release_Release_Date_Holds_sp] TO [public]
GO
