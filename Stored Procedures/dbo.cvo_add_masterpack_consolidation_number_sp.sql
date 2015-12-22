SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_add_masterpack_consolidation_number_sp]
AS
BEGIN

	IF (object_id('tempdb..#so_alloc_management')       IS NOT NULL)
	BEGIN
		UPDATE
			a
		SET
			mp_consolidation_no = b.consolidation_no
		FROM
			#so_alloc_management a
		LEFT JOIN
			dbo.cvo_masterpack_consolidation_det b 
		ON 
			a.order_no = b.order_no 
			AND a.order_ext = b.order_ext
	END
	
	IF (object_id('tempdb..#so_pick_ticket_details')       IS NOT NULL)
	BEGIN
		UPDATE
			a
		SET
			mp_consolidation_no = b.consolidation_no
		FROM
			#so_pick_ticket_details a
		LEFT JOIN
			dbo.cvo_masterpack_consolidation_det b 
		ON 
			a.order_no = b.order_no 
			AND a.order_ext = b.order_ext
	END


END
GO
GRANT EXECUTE ON  [dbo].[cvo_add_masterpack_consolidation_number_sp] TO [public]
GO
