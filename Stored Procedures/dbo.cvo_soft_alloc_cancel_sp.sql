SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_soft_alloc_cancel_sp]	@soft_alloc_no	int, @void int	
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- check for a header soft alloc record with an order number
	-- Reset the soft allocation record
	IF EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status > 0 AND order_no <> 0) AND @void <> 2 -- v1.1
	BEGIN

		-- Retrieve the archive record
		IF EXISTS(SELECT 1 FROM cvo_soft_alloc_det_arch (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no)
		BEGIN
			DELETE	dbo.cvo_soft_alloc_det
			WHERE	soft_alloc_no = @soft_alloc_no

			INSERT	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
													kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, inv_avail, add_case_flag, case_adjust) -- v1.2 v1.4 v1.5
			SELECT	soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
													kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, inv_avail, add_case_flag, case_adjust -- v1.2 v1.4 v1.5
			FROM	dbo.cvo_soft_alloc_det_arch (NOLOCK)
			WHERE	soft_alloc_no = @soft_alloc_no	

			DELETE	dbo.cvo_soft_alloc_hdr
			WHERE	soft_alloc_no NOT IN (SELECT soft_alloc_no FROM dbo.cvo_soft_alloc_det (NOLOCK))
		END
		ELSE
		BEGIN
			-- v1.3 Start
			DELETE	dbo.cvo_soft_alloc_det
			WHERE	soft_alloc_no = @soft_alloc_no

			DELETE	dbo.cvo_soft_alloc_hdr
			WHERE	soft_alloc_no NOT IN (SELECT soft_alloc_no FROM dbo.cvo_soft_alloc_det (NOLOCK))
			-- v1.3 End
		END
		
	END

	-- If the order has not been saved then clear out the soft allocation records
	IF EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status > 0 AND order_no = 0) OR @void = 1
	BEGIN
		-- Retrieve the archive record
		DELETE	dbo.cvo_soft_alloc_det
		WHERE	soft_alloc_no = @soft_alloc_no

		DELETE	dbo.cvo_soft_alloc_hdr
		WHERE	soft_alloc_no = @soft_alloc_no

	END
	
	-- START v1.1
	-- This logic deals with a change to order lines (and so soft_alloc_det records) and then Update Order button is clicked instead of save (which ignores the line changes in base tables)
	IF EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status > 0 AND order_no <> 0) AND @void = 2
	BEGIN  
	  
	   DELETE dbo.cvo_soft_alloc_det  
	   WHERE soft_alloc_no = @soft_alloc_no  
	  
	   INSERT dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,    
				 kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, inv_avail, add_case_flag, case_adjust)  -- v1.2 v1.4 v1.5
	   SELECT soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,    
				 kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status , inv_avail, add_case_flag, case_adjust -- v1.2 v1.4 v1.5
	   FROM dbo.cvo_soft_alloc_det_arch (NOLOCK)  
	   WHERE soft_alloc_no = @soft_alloc_no   
	  
	   DELETE dbo.cvo_soft_alloc_hdr  
	   WHERE soft_alloc_no NOT IN (SELECT soft_alloc_no FROM dbo.cvo_soft_alloc_det (NOLOCK))  
	END 
	-- END v1.1

	DELETE	dbo.cvo_soft_alloc_det_arch
	WHERE	soft_alloc_no = @soft_alloc_no
END
GO
GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_cancel_sp] TO [public]
GO
