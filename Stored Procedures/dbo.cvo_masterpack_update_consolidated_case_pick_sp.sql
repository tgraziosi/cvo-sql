SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[cvo_masterpack_update_consolidated_case_pick_sp] (	@tran_id INT,
																	@qty DECIMAL(20,8))
AS
BEGIN
	DECLARE @parent_tran_id INT

	IF EXISTS (SELECT 1 FROM cvo_masterpack_consolidation_picks WHERE child_tran_id = @tran_id)
	BEGIN
		SELECT 
			@parent_tran_id = parent_tran_id
		FROM 
			dbo.cvo_masterpack_consolidation_picks (NOLOCK)
		WHERE 
			child_tran_id = @tran_id

		UPDATE 
			tdc_pick_queue 
		SET
			qty_to_process = qty_to_process - @qty,
			qty_processed = qty_processed + @qty
		WHERE
			tran_id = @parent_tran_id

		IF EXISTS (SELECT 1 FROM tdc_pick_queue WHERE tran_id = @parent_tran_id AND qty_to_process = 0)
		BEGIN
			DELETE FROM tdc_pick_queue WHERE tran_id = @parent_tran_id
		END
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_masterpack_update_consolidated_case_pick_sp] TO [public]
GO
