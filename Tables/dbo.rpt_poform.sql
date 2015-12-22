CREATE TABLE [dbo].[rpt_poform]
(
[p_po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_po_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_vendor_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_date_of_order] [datetime] NULL,
[p_date_order_due] [datetime] NULL,
[p_ship_to_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_address1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_address2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_address3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_address4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_address5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_via] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_fob] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_terms] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_attn] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_footing] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_blanket] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_total_amt_order] [decimal] (20, 8) NULL,
[p_freight] [decimal] (20, 8) NULL,
[p_date_to_pay] [datetime] NULL,
[p_discount] [decimal] (20, 8) NULL,
[p_prepaid_amt] [decimal] (20, 8) NULL,
[p_vend_inv_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_email] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_email_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_freight_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_freight_vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_freight_inv_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_void_date] [datetime] NULL,
[p_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_po_key] [int] NULL,
[p_po_ext] [int] NULL,
[p_curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_curr_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_curr_factor] [decimal] (20, 8) NULL,
[p_buyer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_prod_no] [int] NULL,
[p_oper_factor] [decimal] (20, 8) NULL,
[p_hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_total_tax] [decimal] (20, 8) NULL,
[p_rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_user_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_expedite_flag] [smallint] NULL,
[p_vend_order_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_requested_by] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_approved_by] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_user_category] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_blanket_flag] [smallint] NULL,
[p_date_blnk_from] [datetime] NULL,
[p_date_blnk_to] [datetime] NULL,
[p_amt_blnk_limit] [float] NULL,
[l_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_vend_sku] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_account_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_unit_cost] [decimal] (20, 8) NULL,
[l_unit_measure] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_rel_date] [datetime] NULL,
[l_qty_ordered] [decimal] (20, 8) NULL,
[l_qty_received] [decimal] (20, 8) NULL,
[l_who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_ext_cost] [decimal] (20, 8) NULL,
[l_conv_factor] [decimal] (20, 8) NULL,
[l_void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_void_date] [datetime] NULL,
[l_lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_line] [int] NULL,
[l_taxable] [int] NULL,
[l_prev_qty] [decimal] (20, 8) NULL,
[l_po_key] [int] NULL,
[l_weight_ea] [decimal] (20, 8) NULL,
[l_row_id] [int] NULL,
[l_tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_curr_factor] [decimal] (20, 8) NULL,
[l_oper_factor] [decimal] (20, 8) NULL,
[l_total_tax] [decimal] (20, 8) NULL,
[l_curr_cost] [decimal] (20, 8) NULL,
[l_oper_cost] [decimal] (20, 8) NULL,
[l_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_project1] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_project2] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_project3] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_tolerance_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_shipto_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_receiving_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_shipto_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_receipt_batch_no] [int] NULL,
[l_ord_precision] [int] NULL,
[l_rcv_precision] [int] NULL,
[l_cost_precision] [int] NULL,
[r_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_part_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_release_date] [datetime] NULL,
[r_quantity] [decimal] (20, 8) NULL,
[r_received] [decimal] (20, 8) NULL,
[r_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_confirm_date] [datetime] NULL,
[r_confirmed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[r_conv_factor] [decimal] (20, 8) NULL,
[r_prev_qty] [decimal] (20, 8) NULL,
[r_po_key] [int] NULL,
[r_row_id] [int] NULL,
[r_due_date] [datetime] NULL,
[r_ord_line] [int] NULL,
[r_po_line] [int] NULL,
[r_receipt_batch_no] [int] NULL,
[r_change] [int] NULL,
[r_ord_precision] [int] NULL,
[r_rcv_precision] [int] NULL,
[a_vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_curr_precision] [smallint] NULL,
[g_rounding_factor] [int] NULL,
[g_position] [int] NULL,
[g_neg_num_format] [int] NULL,
[g_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_symbol_space] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_dec_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_thou_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[h_currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[h_curr_precision] [smallint] NULL,
[h_rounding_factor] [int] NULL,
[h_position] [int] NULL,
[h_neg_num_format] [int] NULL,
[h_symbol] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[h_symbol_space] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[h_dec_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[h_thou_separator] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_via_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_fob_desc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_terms_desc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_tax_desc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_tax_desc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_buyer_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_category_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_user_status_descr] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_tolerance_descr] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_ship_group] [varchar] (240) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_sort_order] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[n_note_no] [int] NULL,
[o_cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_attention] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_masked_phone] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_extended_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_poform] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_poform] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_poform] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_poform] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_poform] TO [public]
GO
