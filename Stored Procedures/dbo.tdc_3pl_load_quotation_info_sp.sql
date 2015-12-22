SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_load_quotation_info_sp]
	@quote_id	int
AS
	IF EXISTS(SELECT * FROM tdc_3pl_quotation_tbl (NOLOCK) WHERE quote_id = @quote_id)
	BEGIN
		--#quotation_tbl
		INSERT INTO #quotation_tbl (quote_id, cust_code, ship_to, active, is_contract, contract_length, quote_currency, contract_start_date,
				 contract_terms, contact_name, contact_number, notes, 
				 created_by, created_date, last_modified_by, last_modified_date)
			SELECT quote_id, cust_code, ship_to, active, is_contract, contract_length, quote_currency, contract_start_date,
				contract_terms, contact_name, contact_number, notes, 
				created_by, created_date, last_modified_by, last_modified_date 
			 FROM tdc_3pl_quotation_tbl (NOLOCK) 
			WHERE quote_id = @quote_id

		--#quote_invoice_items
		INSERT INTO #quote_invoice_items (line_no, location, line_part, line_part_desc, formula)
			SELECT line_no, location, line_part, line_part_desc, formula 
			  FROM tdc_3pl_quote_invoice_items (NOLOCK) 
			WHERE quote_id = @quote_id

		--#quote_inventory_costs_tbl
		INSERT INTO #quote_inventory_costs_tbl (line_no, inv_cost_description, inv_qty, inv_cost_amount)
			SELECT line_no, inv_cost_description, inv_qty, inv_cost_amount
			 FROM tdc_3pl_quotation_inventory_costs_tbl (NOLOCK) 
			WHERE quote_id = @quote_id

		--#quote_assigned_labor_values
		INSERT INTO #quote_assigned_labor_values (tran_id, category, qty, [transaction], expert)
			SELECT a.tran_id, a.category, a.qty, b.[transaction], b.expert
			  FROM tdc_3pl_quote_assigned_labor_values a (NOLOCK) ,
				tdc_3pl_labor_avail_transactions b (NOLOCK)
			WHERE a.quote_id = @quote_id
			  AND a.category = b.category
			  AND a.tran_id  = b.tran_id

		--#quote_templates_used_tbl
		INSERT INTO #quote_templates_used_tbl (template_name, location, template_type, value)
			SELECT template_name, location, template_type, value
			FROM tdc_3pl_quote_templates_used_tbl (NOLOCK)
			WHERE quote_id = @quote_id

		--#quote_templates_labor_details_tbl
		INSERT INTO #quote_templates_labor_details_tbl (template_name, location, tran_id, category, fee)
			SELECT template_name, location, tran_id, category, fee 
			FROM tdc_3pl_quote_templates_labor_details_tbl
			WHERE quote_id = @quote_id
	END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_load_quotation_info_sp] TO [public]
GO
