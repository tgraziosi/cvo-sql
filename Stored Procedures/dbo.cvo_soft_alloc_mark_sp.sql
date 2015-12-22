SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_soft_alloc_mark_sp]	@soft_alloc_no	int,
										@in_progress	int,
										@future_alloc	int,
										@no_return		int = 0	
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- v1.2 Start
	DECLARE	@order_no		int,
			@order_ext		int,
			@status			char(1), -- v1.9
			@hold_reason	varchar(10) -- v1.9
	-- v1.2 End

	-- If the soft alloc record is in progress when the user tries to change it then create a new soft alloc number
-- v1.8	IF EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status IN (-1, -2)) AND @in_progress = 1		
	IF EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status IN (-1)) AND @in_progress = 1 -- v1.8		
	BEGIN
		-- v1.2 Start
		SELECT	@order_no = order_no,
				@order_ext = order_ext
		FROM	cvo_soft_alloc_hdr (NOLOCK)
		WHERE	soft_alloc_no = @soft_alloc_no

-- v1.8	IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND status IN (0, -3, -4) ) AND @in_progress = 1 -- v1.6
		IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND status IN (0, -3, -4, -1) ) AND @in_progress = 1 -- v1.6 v1.8
		BEGIN
			SELECT	@soft_alloc_no = soft_alloc_no
			FROM	dbo.cvo_soft_alloc_hdr (NOLOCK) 
			WHERE	order_no = @order_no 
			AND		order_ext = @order_ext 
-- v1.8		AND		status IN (0, -3, -4) -- v1.6 
			AND		status IN (0, -3, -4, -1) -- v1.6 v1.8

			UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
			SET		status  = 1
			WHERE	soft_alloc_no = @soft_alloc_no
-- v1.8		AND		status IN (0, -3, -4) -- v1.6 
			AND		status IN (0, -3, -4, -1) -- v1.6 v1.8


			-- Set the detail record status to in progress
			UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
			SET		status  = 1
			WHERE	soft_alloc_no = @soft_alloc_no
-- v1.8		AND		status IN (0, -3, -4) -- v1.6 
			AND		status IN (0, -3, -4, -1) -- v1.6 v1.8


			-- Archive record
			DELETE	dbo.cvo_soft_alloc_det_arch
			WHERE	soft_alloc_no = @soft_alloc_no

			INSERT	dbo.cvo_soft_alloc_det_arch  WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
													kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, inv_avail, add_case_flag, case_adjust) -- v1.1 v1.3 v1.4
			SELECT	soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
													kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, inv_avail, add_case_flag, case_adjust -- v1.1 v1.3 v1.4
			FROM	dbo.cvo_soft_alloc_det (NOLOCK)
			WHERE	soft_alloc_no = @soft_alloc_no	

			SELECT @soft_alloc_no	

			RETURN

		END		
		-- v1.2 End

		-- v1.7 Start
		SET	@soft_alloc_no = NULL

		SELECT	@soft_alloc_no = soft_alloc_no
		FROM	cvo_soft_alloc_no_assign (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		IF (@soft_alloc_no IS NULL)
		BEGIN
			BEGIN TRAN
				UPDATE	dbo.cvo_soft_alloc_next_no
				SET		next_no = next_no + 1
			COMMIT TRAN	
			-- Return the number back to the form
			SELECT	@soft_alloc_no = next_no
			FROM	dbo.cvo_soft_alloc_next_no
		END
		-- v1.7 End
	
		SELECT @soft_alloc_no

		RETURN
	END

	-- check for a header soft alloc record for the status - if not in progress then set it
	IF EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status IN (0, -3, -4) ) AND @in_progress = 1 -- v1.6
	BEGIN
		-- Set the header record to in progress
		UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
		SET		status  = 1
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		status IN (0, -3, -4) -- v1.6 


		-- Set the detail record status to in progress
		UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
		SET		status  = 1
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		status IN (0, -3, -4) -- v1.6 


		-- Archive record
		DELETE	dbo.cvo_soft_alloc_det_arch
		WHERE	soft_alloc_no = @soft_alloc_no

		INSERT	dbo.cvo_soft_alloc_det_arch  WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
												kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, inv_avail, add_case_flag, case_adjust) -- v1.1 -- v1.3 v1.4
		SELECT	soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
												kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, inv_avail, add_case_flag, case_adjust -- v1.1 v1.3 v1.4
		FROM	dbo.cvo_soft_alloc_det (NOLOCK)
		WHERE	soft_alloc_no = @soft_alloc_no	
	END

	-- check for a header soft alloc record for the status - if in progress then unset it
	IF EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status = 1 ) AND @in_progress = 0
	BEGIN

		SELECT	@order_no = order_no,
				@order_ext = order_ext
		FROM	cvo_soft_alloc_hdr (NOLOCK)
		WHERE	soft_alloc_no = @soft_alloc_no		

		-- v1.9 Start
		SELECT	@status = status,
				@hold_reason = hold_reason
		FROM	orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		IF ((@status = 'A' AND NOT EXISTS ( SELECT 1 FROM cvo_alloc_hold_values_tbl (NOLOCK) WHERE hold_code = @hold_reason))
			OR (@status = 'C'))
		BEGIN
			SET @future_alloc = 1
		END
		-- v1.9 End

		-- Set the header record to in progress
		UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
		SET		status  = CASE WHEN @future_alloc = 0 THEN 0 ELSE -3 END
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		status = 1

		-- Set the detail record status to in progress
		UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
		SET		status  = CASE WHEN @future_alloc = 0 THEN 0 ELSE -3 END
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		status = 1

		DELETE	dbo.cvo_soft_alloc_det_arch
		WHERE	soft_alloc_no = @soft_alloc_no

		-- v1.5 Start
		-- Remove soft alloc records if cancelling a duplication
		DELETE	cvo_soft_alloc_hdr
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		order_no = 0

		DELETE	cvo_soft_alloc_det
		WHERE	soft_alloc_no = @soft_alloc_no
		AND		order_no = 0
		-- v1.5 End
	END

	IF @no_return = 0
		SELECT @soft_alloc_no

END
GO
GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_mark_sp] TO [public]
GO
