SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_save_quotation_info_sp]
	@quote_id	int
AS
	--DELETE EXISTING RECORDS
	DELETE FROM tdc_3pl_quotation_tbl WHERE quote_id = @quote_id
	--#quotation_tbl
	INSERT INTO tdc_3pl_quotation_tbl (quote_id, cust_code, ship_to, active, is_contract, quote_currency, contract_length, contract_start_date,
			 contract_terms, contact_name, contact_number, notes, 
			 created_by, created_date, last_modified_by, last_modified_date)
		SELECT quote_id, cust_code, ship_to, active, is_contract, quote_currency, contract_length, contract_start_date,
			contract_terms, contact_name, contact_number, notes, 
			created_by, created_date, last_modified_by, last_modified_date 
		 FROM #quotation_tbl (NOLOCK) 

	--DELETE EXISTING RECORDS
	DELETE FROM tdc_3pl_quote_invoice_items WHERE quote_id = @quote_id
	--#quote_invoice_items
	INSERT INTO tdc_3pl_quote_invoice_items (quote_id, line_no, location, line_part, line_part_desc, formula)
		SELECT @quote_id, line_no, location, line_part, line_part_desc, formula 
		  FROM #quote_invoice_items (NOLOCK) 

	--DELETE EXISTING RECORDS
	DELETE FROM tdc_3pl_quotation_inventory_costs_tbl WHERE quote_id = @quote_id
	--#quote_inventory_costs_tbl
	INSERT INTO tdc_3pl_quotation_inventory_costs_tbl (quote_id, line_no, inv_cost_description, inv_qty, inv_cost_amount)
		SELECT @quote_id, line_no, inv_cost_description, inv_qty, inv_cost_amount
		 FROM #quote_inventory_costs_tbl (NOLOCK) 

	--DELETE EXISTING RECORDS
	DELETE FROM tdc_3pl_quote_assigned_labor_values WHERE quote_id = @quote_id
	--#quote_assigned_labor_values
	INSERT INTO tdc_3pl_quote_assigned_labor_values (quote_id, tran_id, category, qty)
		SELECT @quote_id, tran_id, category, qty
		FROM #quote_assigned_labor_values (NOLOCK)

	--****BEGIN*****	SAVE "TEMPLATES USED" INFORMATION
	--DELETE EXISTING RECORDS
	DELETE FROM tdc_3pl_quote_templates_used_tbl WHERE quote_id = @quote_id
	--#quote_templates_used_tbl
	INSERT INTO tdc_3pl_quote_templates_used_tbl (quote_id, template_name, location, template_type, value)
		SELECT @quote_id, template_name, location, template_type, value
		FROM #quote_templates_used_tbl (NOLOCK)

	--DELETE EXISTING RECORDS
	DELETE FROM tdc_3pl_quote_templates_labor_details_tbl WHERE quote_id = @quote_id
	--#quote_templates_labor_details_tbl
	INSERT INTO tdc_3pl_quote_templates_labor_details_tbl (quote_id, template_name, location, tran_id, category, fee)
		SELECT @quote_id, template_name, location, tran_id, category, fee 
		FROM #quote_templates_labor_details_tbl
	--****END*******	SAVE "TEMPLATES USED" INFORMATION
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_save_quotation_info_sp] TO [public]
GO
