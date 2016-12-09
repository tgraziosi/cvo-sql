SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[cvo_process_holds_sp]	@called_from varchar(20), 
										@calling_override varchar(10),
										@process_hold varchar(10),
										@call_action varchar(10), 
										@who varchar(50),
										@order_no int = 0,
										@order_ext int = 0
AS
BEGIN	
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS		
	DECLARE	@hold_priority	int,
			@log_msg		varchar(255)
		
	-- PROCESSING
	IF (@call_action = 'ADD')
	BEGIN	
		IF ((@called_from = 'C&C' OR @calling_override = 'C&C') AND (@process_hold <> 'PROMOHLD'))
		BEGIN
			SELECT @hold_priority = dbo.f_get_hold_priority(@process_hold,'C&C')
		END
		ELSE
		BEGIN
			SELECT @hold_priority = dbo.f_get_hold_priority(@process_hold,'')
		END
	
		IF NOT EXISTS (SELECT 1 FROM cvo_so_holds (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND hold_reason = @process_hold)				
		BEGIN				
			INSERT	cvo_so_holds (order_no, order_ext, hold_reason, hold_priority, hold_user, hold_date)
			SELECT	@order_no, @order_ext, @process_hold, @hold_priority, @who, GETDATE()

			IF (@calling_override = 'C&C')
			BEGIN
				SET @log_msg = 'ADD HOLD: ACCOUNTING HOLD - ' + @process_hold
			END
			ELSE
			BEGIN
				SET @log_msg = 'ADD HOLD: ' + @process_hold
			END

			INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			SELECT	GETDATE(), @who, 'BO', @called_from, 'ORDER UPDATE', @order_no, @order_ext, '', '', '', '', '', @log_msg
		END	
	END
	
	IF (@call_action = 'REMOVE')
	BEGIN
		IF EXISTS (SELECT 1 FROM cvo_so_holds (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND hold_reason = @process_hold)
		BEGIN				
			DELETE	cvo_so_holds
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		hold_reason = @process_hold

			SET @log_msg = 'RELEASE HOLD: ' + @process_hold

			INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			SELECT	GETDATE(), @who, 'BO', @called_from, 'ORDER UPDATE', @order_no, @order_ext, '', '', '', '', '', @log_msg
		END
	END

	IF (@call_action = 'PROMOTE')
	BEGIN
		SET @process_hold = NULL

		SELECT	TOP 1 @process_hold = hold_reason
		FROM	cvo_so_holds (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		ORDER BY hold_priority ASC, hold_date ASC

		IF (ISNULL(@process_hold,'') > '')
		BEGIN
			UPDATE	orders_all WITH (ROWLOCK)
			SET		status = CASE WHEN @process_hold IN ('PD','CL') THEN 'C' ELSE 'A' END,
					hold_reason = @process_hold
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			DELETE	cvo_so_holds
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		hold_reason = @process_hold

			SET @log_msg = CASE WHEN @process_hold IN ('PD','CL') THEN 'STATUS:C/CREDIT HOLD; HOLD REASON: ' ELSE 'STATUS:A/HOLD; HOLD REASON: ' END + @process_hold

			INSERT	tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
			SELECT	GETDATE(), @who, 'BO', @called_from, 'ORDER UPDATE', @order_no, @order_ext, '', '', '', '', '', @log_msg
		END

	END

	IF (@call_action = 'GETUPD')
	BEGIN
		SET @process_hold = NULL

		SELECT	TOP 1 @process_hold = hold_reason
		FROM	cvo_so_holds (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		ORDER BY hold_priority ASC, hold_date ASC

		IF (ISNULL(@process_hold,'') > '')
		BEGIN
			SELECT	@process_hold 

			DELETE	cvo_so_holds
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		hold_reason = @process_hold

		END

	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_process_holds_sp] TO [public]
GO
