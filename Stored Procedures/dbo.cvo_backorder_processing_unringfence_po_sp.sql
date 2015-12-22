SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*


*/

CREATE PROC [dbo].[cvo_backorder_processing_unringfence_po_sp] (@order_no		INT,
															@ext			INT,
															@line_no		INT,	
															@part_no		VARCHAR(30),
															@location		VARCHAR(10),
															@template_code	VARCHAR(30))

AS
BEGIN
	DELETE FROM 
		dbo.CVO_backorder_processing_orders_po_xref 
	WHERE 
		template_code = @template_code
		AND order_no = @order_no
		AND ext = @ext
		AND line_no = @line_no 

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_unringfence_po_sp] TO [public]
GO
