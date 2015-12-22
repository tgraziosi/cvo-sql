SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
 EXEC cvo_adm_print_invoice_sp 'NI:76732'
 DROP TABLE ##rpt8736_rpt_soinvform
 select * from cvo_rpt_soinvform
 delete cvo_rpt_soinvform

*/

CREATE PROC [dbo].[cvo_adm_print_invoice_sp]	@param varchar(30) 
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@tablename		varchar(100),
			@org_name		varchar(100),
			@company_name	varchar(30),
			@home_currency	varchar(8),
			@symbol			varchar(8),
			@acct_format	varchar(35),
			@sqlstring		varchar(8000),			
			@sqlstring2		varchar(8000)			

	-- Get the next crystal report table number
	BEGIN TRANSACTION 

	UPDATE CVO_Control..rnum SET next_num = (next_num + 1)%10000
	SELECT @tablename = '##rpt' + convert(varchar(16), next_num-1) FROM CVO_Control..rnum

	COMMIT TRANSACTION 

	-- Replicate the report processing
	SET @tablename = @tablename + '_rpt_soinvform'

	SELECT @org_name = organization_name FROM Organization WHERE organization_id = dbo.sm_get_current_org_fn()

	SELECT	@company_name = glco.company_name, 
			@home_currency = glco.home_currency, 
			@symbol = glcurr_vw.symbol, 
			@acct_format = glco.account_format_mask 
	FROM	glco (NOLOCK), glcurr_vw (NOLOCK) 
	WHERE	glco.home_currency = glcurr_vw.currency_code

	-- Create the global temp table for the report
	SET @sqlstring = 'CREATE TABLE ' + @tablename + ' (o_order_no int NOT NULL , o_ext int NOT NULL , o_cust_code varchar (10) NOT NULL , o_ship_to varchar (10) NULL , o_req_ship_date datetime NOT NULL , 
				o_sch_ship_date datetime NULL , o_date_shipped datetime NULL , o_date_entered datetime NOT NULL , o_cust_po varchar (20) NULL , o_who_entered varchar (20) NULL , 
				o_status char (1) NOT NULL , o_attention varchar (40) NULL , o_phone varchar (20) NULL , o_terms varchar (10) NULL , o_routing varchar (20) NULL , o_special_instr varchar (255) NULL , 
				o_invoice_date datetime NULL , o_total_invoice decimal(20, 8) NOT NULL , o_total_amt_order decimal(20, 8) NOT NULL , o_salesperson varchar (10) NULL , o_tax_id varchar (10) NOT NULL , 
				o_tax_perc decimal(20, 8) NOT NULL , o_invoice_no int NULL , o_fob varchar (10) NULL , o_freight decimal(20, 8) NULL , o_printed char (1) NULL , o_discount decimal(20, 8) NULL , 
				o_label_no int NULL , o_cancel_date datetime NULL , o_new char (1) NULL , o_ship_to_name varchar (40) NULL , o_ship_to_add_1 varchar (40) NULL , o_ship_to_add_2 varchar (40) NULL , 
				o_ship_to_add_3 varchar (40) NULL , o_ship_to_add_4 varchar (40) NULL , o_ship_to_add_5 varchar (40) NULL , o_ship_to_city varchar (40) NULL , o_ship_to_state varchar (40) NULL , 
				o_ship_to_zip varchar (10) NULL , o_ship_to_country varchar (40) NULL , o_ship_to_region varchar (10) NULL , o_cash_flag char (1) NULL , o_type char (1) NOT NULL , 
				o_back_ord_flag char (1) NULL , o_freight_allow_pct decimal(20, 8) NULL , o_route_code varchar (10) NULL , o_route_no decimal(20, 8) NULL , o_date_printed datetime NULL , 
				o_date_transfered datetime NULL , o_cr_invoice_no int NULL , o_who_picked varchar (20) NULL , o_note varchar (255) NULL , o_void char (1) NULL , o_void_who varchar (20) NULL , 
				o_void_date datetime NULL , o_changed char (1) NULL , o_remit_key varchar (10) NULL , o_forwarder_key varchar (10) NULL , o_freight_to varchar (10) NULL , 
				o_sales_comm decimal(20, 8) NULL , o_freight_allow_type varchar (10) NULL , o_cust_dfpa char (1) NULL , o_location varchar (10) NULL , o_total_tax decimal(20, 8) NULL , 
				o_total_discount decimal(20, 8) NULL , o_f_note varchar (200) NULL , o_invoice_edi char (1) NULL , o_edi_batch varchar (10) NULL , o_post_edi_date datetime NULL , 
				o_blanket char (1) NULL , o_gross_sales decimal(20, 8) NULL , o_load_no int NULL , o_curr_key varchar (10) NULL , o_curr_type char (1) NULL , o_curr_factor decimal(20, 8) NULL , 
				o_bill_to_key varchar (10) NULL , o_oper_factor decimal(20, 8) NULL , o_tot_ord_tax decimal(20, 8) NULL , o_tot_ord_disc decimal(20, 8) NULL , o_tot_ord_freight decimal(20, 8) NULL , 
				o_posting_code varchar (10) NULL , o_rate_type_home varchar (8) NULL , o_rate_type_oper varchar (8) NULL , o_reference_code varchar (32) NULL , o_hold_reason varchar (10) NULL , 
				o_dest_zone_code varchar (8) NULL , o_orig_no int NULL , o_orig_ext int NULL , o_tot_tax_incl decimal(20, 8) NULL , o_process_ctrl_num varchar (32) NULL , 
				o_batch_code varchar (16) NULL , o_tot_ord_incl decimal(20, 8) NULL , o_barcode_status char (2) NULL , o_multiple_flag char (1) NOT NULL , o_so_priority_code char (1) NULL , 
				o_FO_order_no varchar (30) NULL , o_blanket_amt float NULL , o_user_priority varchar (8) NULL , o_user_category varchar (10) NULL , o_from_date datetime NULL , 
				o_to_date datetime NULL , o_consolidate_flag smallint NULL , o_proc_inv_no varchar (32) NULL , o_sold_to_addr1 varchar (40) NULL , o_sold_to_addr2 varchar (40) NULL , 
				o_sold_to_addr3 varchar (40) NULL , o_sold_to_addr4 varchar (40) NULL , o_sold_to_addr5 varchar (40) NULL , o_sold_to_addr6 varchar (40) NULL , o_user_code varchar (8) NOT NULL , 
				o_user_def_fld1 varchar (255) NULL , o_user_def_fld2 varchar (255) NULL , o_user_def_fld3 varchar (255) NULL , o_user_def_fld4 varchar (255) NULL , o_user_def_fld5 float NULL , 
				o_user_def_fld6 float NULL , o_user_def_fld7 float NULL , o_user_def_fld8 float NULL , o_user_def_fld9 int NULL , o_user_def_fld10 int NULL , o_user_def_fld11 int NULL , 
				o_user_def_fld12 int NULL , o_eprocurement_ind int NULL , o_sold_to varchar (10) NULL , l_line_no int NOT NULL , l_location varchar (10) NULL , l_part_no varchar (30) NOT NULL , 
				l_description varchar (255) NULL , l_time_entered datetime NOT NULL , l_ordered decimal(20, 8) NOT NULL , l_shipped decimal(20, 8) NOT NULL , l_price decimal(20, 8) NOT NULL , 
				l_price_type char (1) NULL , l_note varchar (255) NULL , l_status char (1) NOT NULL , l_cost decimal(20, 8) NOT NULL , l_who_entered varchar (20) NULL , 
				l_sales_comm decimal(20, 8) NOT NULL , l_temp_price decimal(20, 8) NULL , l_temp_type char (1) NULL , l_cr_ordered decimal(20, 8) NOT NULL , l_cr_shipped decimal(20, 8) NOT NULL , 
				l_discount decimal(20, 8) NOT NULL , l_uom char (2) NULL , l_conv_factor decimal(20, 8) NOT NULL , l_void char (1) NULL , l_void_who varchar (20) NULL , l_void_date datetime NULL , 
				l_std_cost decimal(20, 8) NOT NULL , l_cubic_feet decimal(20, 8) NOT NULL , l_printed char (1) NULL , l_lb_tracking char (1) NULL , l_labor decimal(20, 8) NOT NULL , 
				l_direct_dolrs decimal(20, 8) NOT NULL , l_ovhd_dolrs decimal(20, 8) NOT NULL , l_util_dolrs decimal(20, 8) NOT NULL , l_taxable int NULL , l_weight_ea decimal(20, 8) NULL , 
				l_qc_flag char (1) NULL , l_reason_code varchar (10) NULL , l_row_id int NOT NULL , l_qc_no int NULL , l_rejected decimal(20, 8) NULL , l_part_type char (1) NULL , 
				l_orig_part_no varchar (30) NULL , l_back_ord_flag char (1) NULL , l_gl_rev_acct varchar (32) NULL , l_total_tax decimal(20, 8) NOT NULL , l_tax_code varchar (10) NULL , 
				l_curr_price decimal(20, 8) NOT NULL , l_oper_price decimal(20, 8) NOT NULL , l_display_line int NOT NULL , l_std_direct_dolrs decimal(20, 8) NULL , 
				l_std_ovhd_dolrs decimal(20, 8) NULL , l_std_util_dolrs decimal(20, 8) NULL , l_reference_code varchar (32) NULL , l_contract varchar (16) NULL , l_agreement_id varchar (32) NULL , 
				l_ship_to varchar (10) NULL , l_service_agreement_flag char (1) NULL , l_inv_available_flag char (1) NOT NULL , l_create_po_flag smallint NULL , l_load_group_no int NULL , 
				l_return_code varchar (10) NULL , l_user_count int NULL , l_ord_precision int NULL , l_shp_precision int NULL , l_price_precision int NULL , c_customer_name varchar (40) NULL , 
				c_addr1 varchar (40) NULL , c_addr2 varchar (40) NULL , c_addr3 varchar (40) NULL , c_addr4 varchar (40) NULL , c_addr5 varchar (40) NULL , c_addr6 varchar (40) NULL , 
				c_contact_name varchar (40) NULL , c_inv_comment_code varchar (8) NULL , c_city varchar (40) NULL , c_state varchar (40) NULL , c_postal_code varchar (15) NULL , 
				c_country varchar (40) NULL , n_company_name varchar (30) NULL , n_addr1 varchar (40) NULL , n_addr2 varchar (40) NULL , n_addr3 varchar (40) NULL , n_addr4 varchar (40) NULL , 
				n_addr5 varchar (40) NULL , n_addr6 varchar (40) NULL , r_name varchar (40) NULL , r_addr1 varchar (40) NULL , r_addr2 varchar (40) NULL , r_addr3 varchar (40) NULL , 
				r_addr4 varchar (40) NULL , r_addr5 varchar (40) NULL , g_currency_mask varchar (100) NULL , g_curr_precision smallint NULL , g_rounding_factor float NULL , g_postion int NULL, 
				g_neg_num_format int NULL, g_symbol varchar (8) NULL, g_symbol_space char (1) NULL, g_dec_separator char (1) NULL, g_thou_separator char (1) NULL, p_amt_payment decimal(20, 8) NULL , 
				p_amt_disc_taken decimal(20, 8) NULL , m_comment_line varchar (40) NULL , i_doc_ctrl_num varchar (16) NULL , i_discount decimal (20,8) NULL, i_tax decimal (20,8) NULL, 
				i_freight decimal (20,8) NULL, i_payments decimal (20,8) NULL, i_total_invoice decimal (20,8) NULL, v_ship_via_name varchar (40) NULL , f_description varchar (40) NULL , 
				fob_fob_desc varchar (40) NULL , t_terms_desc varchar (30) NULL , tax_tax_desc varchar (40) NULL , taxd_tax_desc varchar (40) NULL , '

				SET @sqlstring2 = 'o_sort_order varchar (50) NULL, 
				o_sort_order2 varchar (50) NULL, o_sort_order3 varchar (50) NULL, h_currency_mask varchar (100) NULL , h_curr_precision smallint NULL , h_rounding_factor float NULL , 
				h_position int NULL, h_neg_num_format int NULL, h_symbol varchar (8) NULL, h_symbol_space char (1) NULL, h_dec_separator char (1) NULL, h_thou_separator char (1) NULL, 
				a_note_no int NULL, c_extended_name varchar(120) NULL )'

	-- Run the SQL
	EXEC(@sqlstring + @sqlstring2)

	-- Call the standard stored procedure
	EXEC adm_rpt_soinvform 2 , 0 , @param,'0 = 0', @tablename

	-- Populate the report table
	SET @sqlstring = 'INSERT dbo.cvo_rpt_soinvform SELECT ''' + @tablename + ''', * FROM ' + @tablename

	-- Run the SQL
	EXEC(@sqlstring)

	-- Remove the temp report table
	SET @sqlstring = 'DROP TABLE ' + @tablename

	-- Run the SQL
	EXEC(@sqlstring)


	-- Return the table name
	SELECT @tablename

END
GO
GRANT EXECUTE ON  [dbo].[cvo_adm_print_invoice_sp] TO [public]
GO
