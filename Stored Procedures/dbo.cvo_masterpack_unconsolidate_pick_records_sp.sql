SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- v1.0 CT 03/04/2014 - Issue #572 - Masterpack unconsolidation of pick records

CREATE PROC [dbo].[cvo_masterpack_unconsolidate_pick_records_sp] @consolidation_no INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rec_id				INT,
			@tran_id			INT,
			@priority			INT, 
			@seq_no				INT

	-- Remove parent records
	DELETE FROM tdc_pick_queue WHERE tran_id IN (SELECT parent_tran_id FROM	dbo.cvo_masterpack_consolidation_picks (NOLOCK) WHERE consolidation_no = @consolidation_no)

	-- Unhide child records
	UPDATE
		dbo.tdc_pick_queue
	SET
		assign_user_id = NULL
	WHERE
		tran_id IN (SELECT child_tran_id FROM dbo.cvo_masterpack_consolidation_picks (NOLOCK) WHERE consolidation_no = @consolidation_no)

	-- Remove consolidated pick records
	DELETE FROM dbo.cvo_masterpack_consolidation_picks WHERE consolidation_no = @consolidation_no
	
END

GO
GRANT EXECUTE ON  [dbo].[cvo_masterpack_unconsolidate_pick_records_sp] TO [public]
GO
