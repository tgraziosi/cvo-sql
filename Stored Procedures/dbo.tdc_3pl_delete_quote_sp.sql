SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_delete_quote_sp]
	@quote_id	int
AS
	DELETE FROM tdc_3pl_quotation_tbl WHERE quote_id = @quote_id
	
	DELETE FROM tdc_3pl_quotation_inventory_costs_tbl WHERE quote_id = @quote_id
	
	DELETE FROM tdc_3pl_quote_assigned_labor_values WHERE quote_id = @quote_id
	
	DELETE FROM tdc_3pl_quote_invoice_items WHERE quote_id = @quote_id
	
	DELETE FROM tdc_3pl_quote_templates_labor_details_tbl WHERE quote_id = @quote_id
	
	DELETE FROM tdc_3pl_quote_templates_used_tbl WHERE quote_id = @quote_id
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_delete_quote_sp] TO [public]
GO
