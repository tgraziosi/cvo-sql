SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
  
CREATE procedure [dbo].[adm_rpt_soinvform] @order int, @incl_prev int,   
@invoice varchar(16), @range varchar(8000), @rpt_table varchar(255) = '' as  
begin  
set nocount on 
  
--v4.0 TM 05/19/2012 - Print all line values but based on List Price for Buying Groups  
--v4.1 CB 29/05/2012 - If the customer range includes buying groups then expand to include the child customers
--v4.2 CB 01/06/2012 - Add invoice/credit date to the ranges
--v4.3 CB 14/06/2012 - Issue with index on #invoices table - as the invoice number for a credit and order can be the same it needs to include trx_type
--v4.4 CB 06/07/2012 - Standard bug - does not use order ext
--v4.5 CB 13/07/2012 - Use invoice date from cvo_order_invoice
--v4.6 CB 18/07/2012 - For credits use the date_shipped
--v10.1 CB 24/07/2012 - Custom Frame Processing
--v10.2 CB 10/09/2012 - Issue #755 - Print frames first then cases  
--v10.3 CB 08/11/2012 - Remove number from custom frame notation
--v10.4 CT 21/11/2012 - Don't alter price for credit return fee on Buying Group credits
-- v10.5 CB 11/01/2013 - Issue #866 - Display invoice notes
-- v10.6 CB 26/02/2013 - Use relationship code for national accounts
-- v10.7 CB 21/05/2013 - Issue #815 - Fix rounding issue on discount
-- v10.8 CB 10/07/2013 - Issue #927 - Buying Group Switching
-- v10.9 CB 07/12/2012 - Issue #925 - BG print options
-- v11.0 CB 21/10/2013 - Issue #925 - BG print options - if option not set then default to on
-- v11.1 CB 23/10/2013 - Issue #925 - BG print options - Always display buying group and correct discount, list price etc
-- v11.2 CB 04/11/2013 - Issue #925 - BG print options - Further Change
-- v11.3 CB 12/02/2014 - Issue #1349 - Display RA # for credits
-- v11.4 CB 30/06/2014 - Issue #1488 - Only display net price for BG with promo where fixed price set
-- v11.5 CT 20/10/2014 - Issue #1367 - If net price > list price, set list = net and discount = 0
-- v11.6 CT 23/10/2014 - Issue #1504 - Fix calculation for credit returns with a discount percentage
-- v11.7 CT 28/10/2014 - Issue #1367 - If net price > list price, set list = net and discount = 0 for BG printing non BG invoices
-- tag - 032715 - set up config setting to control print filter for month-end - CVO_FILTER_CREDITS
-- v11.8 CB 13/05/2015 - Issue #1446 - Invoice notes for customer
-- v11.9 CB 23/06/2015 - Pick up tax & freight from the shipped fields
-- v12.0 CB 15/07/2015 - For BG then display zero prices for free frames
-- v12.1 CB 22/09/2015 - As per Tine - They want to see the gross price (list price) as whatever it is (non-zero), and the net price to show as $0.
-- v12.2 CB 11/05/2016 - Fix issue with promo discount
-- v12.3 CB 04/08/2016 - #1599 email ship confirmation order may not be posted

--DECLARE	@custom_count int -- v10.1 v10.3
  
declare @ord_len int, @inv_len int, @inv_cnt int, @typ char(1), @prt_summ char(1)  

-- v4.1
DECLARE @cust_range varchar(8000), @end_range int 
DECLARE @date_range varchar(8000) -- v4.2

DECLARE @relation_code varchar(10) -- v10.6

-- v10.8 Start
DECLARE	@dstart		varchar(2000),
		@dend		varchar(2000)
-- v10.8 End

SELECT	@relation_code = report_rel_code
FROM	arco (NOLOCK) -- v10.6
  
create table #invoices (printed char(1), invoice_no int,  
discount decimal(20,8), tax decimal(20,8), freight decimal(20,8), payments decimal(20,8),  
total_invoice decimal(20,8), type char(1), order_no int,   
trx_type int, doc_ctrl_num varchar(16), level int, order_ext int) -- v4.4  
  
create unique index inv_idx0 on #invoices (invoice_no, trx_type)  

-- v4.1
CREATE TABLE #customers (cust_code varchar(10), cust_type varchar(40))
create index cust_idx0 on #customers (cust_code,cust_type)  


  
create table #rpt_soinvform (  
o_order_no int NOT NULL default(-1),  
o_ext int NOT NULL  default(-1),  
o_cust_code varchar (10) NOT NULL  default(''),  
o_ship_to varchar (10) NULL ,  
o_req_ship_date datetime NOT NULL  default(getdate()),  
o_sch_ship_date datetime NULL ,  
o_date_shipped datetime NULL ,  
o_date_entered datetime NOT NULL  default(getdate()),  
o_cust_po varchar (20) NULL ,  
o_who_entered varchar (20) NULL ,  
o_status char (1) NOT NULL  default(''),  
o_attention varchar (40) NULL ,  
o_phone varchar (20) NULL ,  
o_terms varchar (10) NULL ,  
o_routing varchar (20) NULL ,  
o_special_instr varchar (255) NULL ,  
o_invoice_date datetime NULL ,  
o_total_invoice decimal(20, 8) NOT NULL  default(-1),  
o_total_amt_order decimal(20, 8) NOT NULL  default(-1),  
o_salesperson varchar (10) NULL ,  
o_tax_id varchar (10) NOT NULL  default(''),  
o_tax_perc decimal(20, 8) NOT NULL  default(-1),  
o_invoice_no int NULL ,  
o_fob varchar (10) NULL ,  
o_freight decimal(20, 8) NULL ,  
o_printed char (1) NULL ,  
o_discount decimal(20, 8) NULL ,  
o_label_no int NULL ,  
o_cancel_date datetime NULL ,  
o_new char (1) NULL ,  
o_ship_to_name varchar (40) NULL ,  
o_ship_to_add_1 varchar (40) NULL ,  
o_ship_to_add_2 varchar (40) NULL ,  
o_ship_to_add_3 varchar (40) NULL ,  
o_ship_to_add_4 varchar (40) NULL ,  
o_ship_to_add_5 varchar (40) NULL ,  
o_ship_to_city varchar (40) NULL ,  
o_ship_to_state varchar (40) NULL ,  
o_ship_to_zip varchar (15) NULL ,  
o_ship_to_country varchar (40) NULL ,  
o_ship_to_region varchar (10) NULL ,  
o_cash_flag char (1) NULL ,  
o_type char (1) NOT NULL  default('X'),  
o_back_ord_flag char (1) NULL ,  
o_freight_allow_pct decimal(20, 8) NULL ,  
o_route_code varchar (10) NULL ,  
o_route_no decimal(20, 8) NULL ,  
o_date_printed datetime NULL ,  
o_date_transfered datetime NULL ,  
o_cr_invoice_no int NULL ,  
o_who_picked varchar (20) NULL ,  
o_note varchar (255) NULL ,  
o_void char (1) NULL ,  
o_void_who varchar (20) NULL ,  
o_void_date datetime NULL ,  
o_changed char (1) NULL ,  
o_remit_key varchar (10) NULL ,  
o_forwarder_key varchar (10) NULL ,  
o_freight_to varchar (10) NULL ,  
o_sales_comm decimal(20, 8) NULL ,  
o_freight_allow_type varchar (10) NULL ,  
o_cust_dfpa char (1) NULL ,  
o_location varchar (10) NULL ,  
o_total_tax decimal(20, 8) NULL ,  
o_total_discount decimal(20, 8) NULL ,  
o_f_note varchar (200) NULL ,  
o_invoice_edi char (1) NULL ,  
o_edi_batch varchar (10) NULL ,  
o_post_edi_date datetime NULL ,  
o_blanket char (1) NULL ,  
o_gross_sales decimal(20, 8) NULL ,  
o_load_no int NULL ,  
o_curr_key varchar (10) NULL ,  
o_curr_type char (1) NULL ,  
o_curr_factor decimal(20, 8) NULL ,  
o_bill_to_key varchar (10) NULL ,  
o_oper_factor decimal(20, 8) NULL ,  
o_tot_ord_tax decimal(20, 8) NULL ,  
o_tot_ord_disc decimal(20, 8) NULL ,  
o_tot_ord_freight decimal(20, 8) NULL ,  
o_posting_code varchar (10) NULL ,  
o_rate_type_home varchar (8) NULL ,  
o_rate_type_oper varchar (8) NULL ,  
o_reference_code varchar (32) NULL ,  
o_hold_reason varchar (10) NULL ,  
o_dest_zone_code varchar (8) NULL ,  
o_orig_no int NULL ,  
o_orig_ext int NULL ,  
o_tot_tax_incl decimal(20, 8) NULL ,  
o_process_ctrl_num varchar (32) NULL ,  
o_batch_code varchar (16) NULL ,  
o_tot_ord_incl decimal(20, 8) NULL ,  
o_barcode_status char (2) NULL ,  
o_multiple_flag char (1) NOT NULL  default(''),  
o_so_priority_code char (1) NULL ,  
o_FO_order_no varchar (30) NULL ,  
o_blanket_amt float NULL ,  
o_user_priority varchar (8) NULL ,  
o_user_category varchar (10) NULL ,  
o_from_date datetime NULL ,  
o_to_date datetime NULL ,  
o_consolidate_flag smallint NULL ,  
o_proc_inv_no varchar (32) NULL ,  
o_sold_to_addr1 varchar (40) NULL ,  
o_sold_to_addr2 varchar (40) NULL ,  
o_sold_to_addr3 varchar (40) NULL ,  
o_sold_to_addr4 varchar (40) NULL ,  
o_sold_to_addr5 varchar (40) NULL ,  
o_sold_to_addr6 varchar (40) NULL ,  
o_user_code varchar (8) NOT NULL  default(''),  
o_user_def_fld1 varchar (255) NULL ,  
o_user_def_fld2 varchar (255) NULL ,  
o_user_def_fld3 varchar (255) NULL ,  
o_user_def_fld4 varchar (255) NULL ,  
o_user_def_fld5 float NULL ,  
o_user_def_fld6 float NULL ,  
o_user_def_fld7 float NULL ,  
o_user_def_fld8 float NULL ,  
o_user_def_fld9 int NULL ,  
o_user_def_fld10 int NULL ,  
o_user_def_fld11 int NULL ,  
o_user_def_fld12 int NULL ,  
o_eprocurement_ind int NULL ,  
o_sold_to varchar (10) NULL,  
  
l_line_no int NOT NULL  default(-1),  
l_location varchar (10) NULL ,  
l_part_no varchar (30) NOT NULL  default(''),  
l_description varchar (255) NULL ,  
l_time_entered datetime NOT NULL  default(getdate()),  
l_ordered decimal(20, 8) NOT NULL  default(-1),  
l_shipped decimal(20, 8) NOT NULL  default(-1),  
l_price decimal(20, 8) NOT NULL  default(-1),  
l_price_type char (1) NULL ,  
l_note varchar (255) NULL ,  
l_status char (1) NOT NULL  default(''),  
l_cost decimal(20, 8) NOT NULL  default(-1),  
l_who_entered varchar (20) NULL ,  
l_sales_comm decimal(20, 8) NOT NULL  default(-1),  
l_temp_price decimal(20, 8) NULL ,  
l_temp_type char (1) NULL ,  
l_cr_ordered decimal(20, 8) NOT NULL  default(-1),  
l_cr_shipped decimal(20, 8) NOT NULL  default(-1),  
l_discount decimal(20, 8) NOT NULL  default(-1),  
l_uom char (2) NULL ,  
l_conv_factor decimal(20, 8) NOT NULL  default(-1),  
l_void char (1) NULL ,  
l_void_who varchar (20) NULL ,  
l_void_date datetime NULL ,  
l_std_cost decimal(20, 8) NOT NULL  default(-1),  
l_cubic_feet decimal(20, 8) NOT NULL  default(-1),  
l_printed char (1) NULL ,  
l_lb_tracking char (1) NULL ,  
l_labor decimal(20, 8) NOT NULL  default(-1),  
l_direct_dolrs decimal(20, 8) NOT NULL  default(-1),  
l_ovhd_dolrs decimal(20, 8) NOT NULL  default(-1),  
l_util_dolrs decimal(20, 8) NOT NULL  default(-1),  
l_taxable int NULL ,  
l_weight_ea decimal(20, 8) NULL ,  
l_qc_flag char (1) NULL ,  
l_reason_code varchar (10) NULL ,  
l_row_id int NOT NULL  default(-1),  
l_qc_no int NULL ,  
l_rejected decimal(20, 8) NULL ,  
l_part_type char (1) NULL ,  
l_orig_part_no varchar (30) NULL ,  
l_back_ord_flag char (1) NULL ,  
l_gl_rev_acct varchar (32) NULL ,  
l_total_tax decimal(20, 8) NOT NULL  default(-1),  
l_tax_code varchar (10) NULL ,  
l_curr_price decimal(20, 8) NOT NULL  default(-1),  
l_oper_price decimal(20, 8) NOT NULL  default(-1),  
l_display_line int NOT NULL  default(-1),  
l_std_direct_dolrs decimal(20, 2) NULL ,    --v3.0  
l_std_ovhd_dolrs decimal(20, 2) NULL ,     --v3.0  
l_std_util_dolrs decimal(20, 2) NULL ,     --v3.0  
l_reference_code varchar (32) NULL ,  
l_contract varchar (16) NULL ,  
l_agreement_id varchar (32) NULL ,  
l_ship_to varchar (10) NULL ,  
l_service_agreement_flag char (1) NULL ,  
l_inv_available_flag char (1) NOT NULL  default(''),  
l_create_po_flag smallint NULL ,  
l_load_group_no int NULL ,  
l_return_code varchar (10) NULL ,  
l_user_count int NULL ,  
l_ord_precision int NULL,  
l_shp_precision int NULL,  
l_price_precision int NULL,  
  
c_customer_name varchar (40) NULL ,  
c_addr1 varchar (40) NULL ,  
c_addr2 varchar (40) NULL ,  
c_addr3 varchar (40) NULL ,  
c_addr4 varchar (40) NULL ,  
c_addr5 varchar (40) NULL ,  
c_addr6 varchar (40) NULL ,  
c_contact_name varchar (40) NULL ,  
c_inv_comment_code varchar (8) NULL ,  
c_city varchar (40) NULL ,  
c_state varchar (40) NULL ,  
c_postal_code varchar (15) NULL ,  
c_country varchar (40) NULL ,  
  
n_company_name varchar (30) NULL ,  
n_addr1 varchar (40) NULL ,  
n_addr2 varchar (40) NULL ,  
n_addr3 varchar (40) NULL ,  
n_addr4 varchar (40) NULL ,  
n_addr5 varchar (40) NULL ,  
n_addr6 varchar (40) NULL ,  
  
r_name varchar (40) NULL ,  
r_addr1 varchar (40) NULL ,  
r_addr2 varchar (40) NULL ,  
r_addr3 varchar (40) NULL ,  
r_addr4 varchar (40) NULL ,  
r_addr5 varchar (40) NULL ,  
  
g_currency_mask varchar (100) NULL ,  
g_curr_precision smallint NULL ,  
g_rounding_factor float NULL ,  
g_postion int NULL,  
g_neg_num_format int NULL,  
g_symbol varchar (8) NULL,  
g_symbol_space char (1) NULL,  
g_dec_separator char (1) NULL,  
g_thou_separator char (1) NULL,  
  
p_amt_payment decimal(20, 8) NULL ,  
p_amt_disc_taken decimal(20, 8) NULL ,  
  
m_comment_line varchar (40) NULL ,  
  
i_doc_ctrl_num varchar (16) NULL ,  
i_discount decimal (20,8) NULL,  
i_tax decimal (20,8) NULL,  
i_freight decimal (20,8) NULL,  
i_payments decimal (20,8) NULL,  
i_total_invoice decimal (20,8) NULL,  
  
v_ship_via_name varchar (40) NULL ,  
f_description varchar (40) NULL ,  
fob_fob_desc varchar (40) NULL ,  
t_terms_desc varchar (30) NULL ,  
tax_tax_desc varchar (40) NULL ,  
taxd_tax_desc varchar (40) NULL ,  
  
o_sort_order varchar (50) NULL,  
o_sort_order2 varchar (50) NULL,  
o_sort_order3 varchar (50) NULL,  
  
h_currency_mask varchar (100) NULL ,  
h_curr_precision smallint NULL ,  
h_rounding_factor float NULL ,  
h_position int NULL,  
h_neg_num_format int NULL,  
h_symbol varchar (8) NULL,  
h_symbol_space char (1) NULL,  
h_dec_separator char (1) NULL,  
h_thou_separator char (1) NULL,  
  
a_note_no int NULL ,  
c_extended_name varchar(120) NULL  
)  
  
create index soinv_idx0 on #rpt_soinvform (o_order_no, o_ext, o_invoice_no, l_line_no)  
  
select @range = replace(@range,'orders.', 'orders_all.')  
select @range = replace(@range,'orders_all.order_no',' orders_all.type = ''I'' and orders_all.order_no')  
select @range = replace(@range,'orders_all.cm_no',' orders_all.type = ''C'' and orders_all.order_no')  
select @range = replace(@range,'orders_all.date_shipped','datediff(day,"01/01/1900",date_shipped) + 693596 ')  
select @range = replace(@range,'orders_all.invoice_date','datediff(day,"01/01/1900",orders_all.invoice_date) + 693596 ')  -- v4.2
select @range = replace(@range,'"','''')  
  
select @invoice = isnull(@invoice,'')  
  
select @prt_summ = left(@invoice,1)  

-- v12.3 Start
IF (@prt_summ = 'Q')
BEGIN
	SELECT @typ = SUBSTRING(@invoice, 2, 1)  
	SELECT @invoice = SUBSTRING(@invoice, 4, 16)  

	exec('insert #invoices  
	select min(printed), inv_number, 0,0,0,0,0, type, min(orders_all.order_no),  
	case when type = ''I'' then 2031 else 2032 end, oi.doc_ctrl_num, 0, min(orders_all.ext)  
	from orders_all (nolock)  
	join cvo_order_invoice oi (NOLOCK) on oi.order_no = orders_all.order_no and oi.order_ext = orders_all.ext  
	where status >= ''R'' and status < ''V'' and inv_number = ' + @invoice + ' and type = ''' + @typ + '''   
	and isnull(tax_valid_ind,1) = 1   
	group by inv_number, type, oi.doc_ctrl_num')  

END
ELSE
BEGIN

	select @invoice = substring(@invoice,2,16)  
	  
	if @invoice <> ''  
	begin  
	  select @typ     = left(@invoice,1)  
	  select @invoice = substring(@invoice,3,16)  
	  if @typ != 'L'  
	  begin  
		exec('insert #invoices  
		select min(printed),invoice_no, 0,0,0,0,0, type, min(orders_all.order_no),  
		case when type = ''I'' then 2031 else 2032 end, oi.doc_ctrl_num, 0, min(orders_all.ext)  
		from orders_all (nolock)  
		join orders_invoice oi (NOLOCK) on oi.order_no = orders_all.order_no and oi.order_ext = orders_all.ext  
		where status >= ''T'' and status < ''V'' and invoice_no = ' + @invoice + ' and type = ''' + @typ + '''   
		and isnull(tax_valid_ind,1) = 1   
		group by invoice_no, type, oi.doc_ctrl_num')  
	  end  
	  else  
	  begin  
		exec('insert #invoices  
		select min(printed),invoice_no, 0,0,0,0,0, type, min(orders_all.order_no),  
		case when type = ''I'' then 2031 else 2032 end, oi.doc_ctrl_num, 0, min(orders_all.ext)    
		from orders_all (NOLOCK)  
		join orders_invoice oi (NOLOCK) on oi.order_no = orders_all.order_no and oi.order_ext = orders_all.ext  
		where status >= ''T'' and status < ''V'' and invoice_no > 0 and load_no = ' + @invoice + ' and type < ''X'' and printed < ''T''   
		and isnull(tax_valid_ind,1) = 1   
		group by invoice_no, type, oi.doc_ctrl_num')  
	  end  
	end  
	else  
	begin  
	  if @incl_prev = 0  
	  begin  

		IF PATINDEX('%orders_all.cust_code%',@range) > 0
		BEGIN
			SET @cust_range = SUBSTRING(@range,PATINDEX('%orders_all.cust_code%',@range),8000)
			SET @end_range = PATINDEX('%) )%',@cust_range) - 2
			SET @cust_range = SUBSTRING(@cust_range,1,@end_range)
			SET @cust_range = replace(@cust_range,'orders_all.cust_code', 'c.customer_code')  
	    

			exec('insert #customers  (cust_code, cust_type)
			select distinct c.customer_code, c.addr_sort1
			from adm_cust c (nolock)
			where ' + @cust_range ) 		
		END
	 
		exec('insert #invoices  
		select min(printed),invoice_no, 0,0,0,0,0, type, min(orders_all.order_no),  
		case when type = ''I'' then 2031 else 2032 end, oi.doc_ctrl_num, 0, min(orders_all.ext)    
		from orders_all (nolock)  
		join adm_cust c (nolock) on orders_all.cust_code = c.customer_code  
		join orders_invoice oi (nolock) on oi.order_no = orders_all.order_no and oi.order_ext = orders_all.ext  
		join locations l (nolock) on l.location = orders_all.location  
		join region_vw r (nolock) on l.organization_id = r.org_id  
		where orders_all.status >= ''T'' and orders_all.status < ''V'' and orders_all.invoice_no > 0 and orders_all.type < ''X'' and   
		  isnull(orders_all.tax_valid_ind,1) = 1 and  
	   orders_all.printed < ''T'' and ' + @range +  
		' group by orders_all.invoice_no, orders_all.type, oi.doc_ctrl_num')   
	  end  
	  else  
	  begin  

		IF PATINDEX('%orders_all.cust_code%',@range) > 0
		BEGIN
			SET @cust_range = SUBSTRING(@range,PATINDEX('%orders_all.cust_code%',@range),8000)
			SET @end_range = PATINDEX('%) )%',@cust_range) - 2
			SET @cust_range = SUBSTRING(@cust_range,1,@end_range)
			SET @cust_range = replace(@cust_range,'orders_all.cust_code', 'c.customer_code')  
	    
			exec('insert #customers  (cust_code, cust_type)
			select distinct c.customer_code, c.addr_sort1
			from adm_cust c (nolock)
			where ' + @cust_range ) 			
		END

		exec('insert #invoices  
		select min(printed),invoice_no, 0,0,0,0,0, type, min(orders_all.order_no),  
		case when type = ''I'' then 2031 else 2032 end, oi.doc_ctrl_num, 0, min(orders_all.ext)    
		from orders_all (nolock)  
		join adm_cust c (nolock) on orders_all.cust_code = c.customer_code  
		join locations l (nolock) on l.location = orders_all.location   
		join region_vw r (nolock) on l.organization_id = r.org_id   
		join orders_invoice oi (nolock) on oi.order_no = orders_all.order_no and oi.order_ext = orders_all.ext  
		where orders_all.status >= ''T'' and orders_all.status < ''V''  and  
		  isnull(orders_all.tax_valid_ind,1) = 1   
		  and orders_all.invoice_no > 0 and orders_all.type < ''X'' and ' + @range +  
		' group by orders_all.invoice_no, orders_all.type, oi.doc_ctrl_num')   
	  end  

		-- v4.1 
		-- if any buying groups exist get the child list
		IF EXISTS (SELECT 1 FROM #customers WHERE UPPER(cust_type) = 'BUYING GROUP')
		BEGIN
			-- v10.8 Start
			-- Get the date range if set
			IF PATINDEX('%orders_all.invoice_date%',@range) > 0
			BEGIN
				-- Extract the start and end dates from the range and convert from julian dates
				SELECT @dstart = DATEADD(DAY,(LEFT(SUBSTRING(@range,PATINDEX("%datediff(day,'01/01/1900',orders_all.invoice_date) + 693596  >= %",@range)+ 64,8000),6)) - 693596, '01/01/1900')
				SELECT @dend = DATEADD(DAY, (LEFT(SUBSTRING(@range,PATINDEX("%datediff(day,'01/01/1900',orders_all.invoice_date) + 693596  <= %",@range)+ 64,8000),6)) - 693596, '01/01/1900')
			END
			ELSE
			BEGIN
				SELECT @dstart = NULL
				SELECT @dend = NULL
			END

			INSERT 	#customers (cust_code, 	cust_type)
			SELECT	b.child, c.addr_sort1
			FROM	#customers a
			CROSS APPLY dbo.f_cvo_get_buying_group_child_list_range(a.cust_code,@dstart,@dend) b 
			JOIN	armaster_all c (NOLOCK)
			ON		b.child = c.customer_code
			WHERE	c.address_type = 0

	--		SELECT	a.rel_cust, b.addr_sort1
	--		FROM	artierrl a (NOLOCK)
	--		JOIN	armaster_all b (NOLOCK)
	--		ON		a.rel_cust = b.customer_code
	--		JOIN	#customers c
	--		ON		a.parent = c.cust_code
	--		WHERE	a.tier_level > 1
	--		AND		b.address_type = 0
	--		AND		a.relation_code = @relation_code -- v10.6
			-- v10.8 End

			-- Remove any customers from the list if they already exist in the original range including the buying group
			DELETE	#customers 
			WHERE	cust_code in (
				SELECT	a.cust_code 
				FROM	orders_all a (NOLOCK)
				JOIN	#invoices b
				ON		a.order_no = b.order_no)

			-- v4.2
			SET @date_range = ' 1 = 1 '
			IF PATINDEX('%orders_all.invoice_date%',@range) > 0
			BEGIN
				SET @date_range = SUBSTRING(@range,PATINDEX('%datediff(day,''01/01/1900'',orders_all.invoice_date%',@range),8000)
				SET @end_range = PATINDEX('%) )%',@date_range) - 2
				SET @date_range = SUBSTRING(@date_range,1,@end_range)

			END
			

			IF @incl_prev = 0  
			BEGIN
				exec('insert #invoices  
				select min(printed),invoice_no, 0,0,0,0,0, type, min(orders_all.order_no),  
				case when type = ''I'' then 2031 else 2032 end, oi.doc_ctrl_num, 0, min(orders_all.ext)    
				from orders_all (nolock)  
				join adm_cust c (nolock) on orders_all.cust_code = c.customer_code  
				join orders_invoice oi (nolock) on oi.order_no = orders_all.order_no and oi.order_ext = orders_all.ext  
				join locations l (nolock) on l.location = orders_all.location  
				join region_vw r (nolock) on l.organization_id = r.org_id  
				join #customers tc on c.customer_code = tc.cust_code
				where orders_all.status >= ''T'' and orders_all.status < ''V'' and orders_all.invoice_no > 0 and orders_all.type < ''X'' and   
				  isnull(orders_all.tax_valid_ind,1) = 1 and  ' + @date_range + ' and
			   orders_all.printed < ''T'' group by orders_all.invoice_no, orders_all.type, oi.doc_ctrl_num')   

			END 
			ELSE
			BEGIN
			   exec('insert #invoices  
				select min(printed),invoice_no, 0,0,0,0,0, type, min(orders_all.order_no),  
				case when type = ''I'' then 2031 else 2032 end, oi.doc_ctrl_num, 0, min(orders_all.ext)    
				from orders_all (nolock)  
				join adm_cust c (nolock) on orders_all.cust_code = c.customer_code  
				join locations l (nolock) on l.location = orders_all.location   
				join region_vw r (nolock) on l.organization_id = r.org_id   
				join orders_invoice oi (nolock) on oi.order_no = orders_all.order_no and oi.order_ext = orders_all.ext  
				join #customers tc on c.customer_code = tc.cust_code
				where orders_all.status >= ''T'' and orders_all.status < ''V''  and  ' + @date_range + ' and
				  isnull(orders_all.tax_valid_ind,1) = 1   
				  and orders_all.invoice_no > 0 and orders_all.type < ''X'' group by orders_all.invoice_no, orders_all.type, oi.doc_ctrl_num')   
			END

		END

	end  
END
-- v12.3 End
-- v4.1  
DROP TABLE #customers

delete i  
from #invoices i  
join dbo.orders_all o (nolock) on o.invoice_no = i.invoice_no and o.type = i.type  
and isnull(o.tax_valid_ind,1) = 0  
  
  
update i  
set   
discount = isnull((select sum(total_discount) from orders_all o (NOLOCK) where o.invoice_no = i.invoice_no and o.type = i.type),0),  
-- v11.9 tax = isnull((select sum(tot_ord_tax) from orders_all o (NOLOCK) where o.invoice_no = i.invoice_no and o.type = i.type),0),  
tax = isnull((select sum(total_tax) from orders_all o (NOLOCK) where o.invoice_no = i.invoice_no and o.type = i.type),0),  -- v11.9
-- v11.9 freight = isnull((select sum(tot_ord_freight) from orders_all o (NOLOCK) where o.invoice_no = i.invoice_no and o.type = i.type),0),  
freight = isnull((select sum(freight) from orders_all o (NOLOCK) where o.invoice_no = i.invoice_no and o.type = i.type),0),  -- v11.9
payments =   
isnull((select sum(p.amt_payment - p.amt_disc_taken) from orders_all o (NOLOCK), ord_payment p (NOLOCK) where o.invoice_no = i.invoice_no and   
  o.order_no = p.order_no and o.ext = p.order_ext and o.type = i.type),0),  
total_invoice = isnull((select sum(total_invoice) from orders_all o (NOLOCK) where o.invoice_no = i.invoice_no and o.type = i.type),0)  
from #invoices i  
  
select @ord_len = max(datalength(order_no)),  
  @inv_len = max(datalength(invoice_no))  
from #invoices (nolock)  
  
  
--update o  
--set printed = 'T'  
--from orders_all o, #invoices t  
--where o.invoice_no = t.invoice_no and o.printed < 'T' and o.type = t.type  

-- v12.3 Start
IF (@prt_summ = 'Q')
BEGIN
	insert #rpt_soinvform  
	SELECT   
	o.order_no, o.ext, o.cust_code, o.ship_to, o.req_ship_date, o.sch_ship_date, o.date_shipped, o.date_entered,  
	o.cust_po, o.who_entered, o.status, o.attention, o.phone, o.terms, o.routing, o.special_instr, o.invoice_date,  
	o.total_invoice, o.total_amt_order, o.salesperson, o.tax_id, o.tax_perc, i.inv_number, o.fob, o.freight,  
	#invoices.printed,  
	o.discount, o.label_no, o.cancel_date, o.new,  
	isnull(o.ship_to_name,''),    -- mls 3/1/05 SCR 34332  
	isnull(o.ship_to_add_1,''),  
	isnull(o.ship_to_add_2,''),  
	isnull(o.ship_to_add_3,''),  
	isnull(o.ship_to_add_4,''),  
	isnull(o.ship_to_add_5,''),  
	isnull(o.ship_to_city,''),  
	isnull(o.ship_to_state,''),  
	isnull(o.ship_to_zip,''),  
	isnull(o.ship_to_country,''),  
	isnull(o.ship_to_region,''),  
	o.cash_flag, o.type, o.back_ord_flag, o.freight_allow_pct, o.route_code, o.route_no, o.date_printed, o.date_transfered,  
	o.cr_invoice_no, o.who_picked, o.note, o.void, o.void_who, o.void_date, o.changed, isnull(o.remit_key,''),  
	o.forwarder_key, o.freight_to, o.sales_comm, o.freight_allow_type, o.cust_dfpa, o.location,   
	o.total_tax, o.total_discount, o.f_note, o.invoice_edi, o.edi_batch, o.post_edi_date, o.blanket,   
	o.gross_sales, o.load_no, o.curr_key, o.curr_type, o.curr_factor, o.bill_to_key, o.oper_factor,   
	o.tot_ord_tax, o.tot_ord_disc, o.tot_ord_freight, o.posting_code, o.rate_type_home, o.rate_type_oper, o.reference_code,  
	o.hold_reason, o.dest_zone_code, o.orig_no, o.orig_ext, o.tot_tax_incl, o.process_ctrl_num, o.batch_code, o.tot_ord_incl,  
	o.barcode_status, o.multiple_flag, o.so_priority_code, o.FO_order_no, o.blanket_amt, o.user_priority, o.user_category,  
	o.from_date, o.to_date, isnull(o.consolidate_flag,0), o.proc_inv_no,  
	isnull(o.sold_to_addr1,''),  -- mls 3/1/05 SCR 34332   
	isnull(o.sold_to_addr2,''),  
	isnull(o.sold_to_addr3,''),  
	isnull(o.sold_to_addr4,''),  
	isnull(o.sold_to_addr5,''),  
	isnull(o.sold_to_addr6,''),  
	o.user_code, o.user_def_fld1, o.user_def_fld2, o.user_def_fld3, o.user_def_fld4, o.user_def_fld5, o.user_def_fld6,  
	o.user_def_fld7, o.user_def_fld8, o.user_def_fld9, o.user_def_fld10, o.user_def_fld11, o.user_def_fld12,  
	case when o.type != 'I' then 0 else isnull(o.eprocurement_ind,0) end,  
	o.sold_to,  
	  
	l.line_no,  
	l.location,  
	l.part_no,  
	isnull(l.description,''),  
	l.time_entered,  
	l.ordered,  
	l.shipped,  
	CASE o.type WHEN 'I' THEN ROUND((l.curr_price - ROUND(cv1.amt_disc,2)),2,1)  -- v10.7
	   ELSE CASE l.discount WHEN 0 THEN l.curr_price  
	   -- START v11.6
	   ELSE CASE WHEN cv1.list_price = l.curr_price THEN ROUND(cv1.list_price - (cv1.list_price * l.discount/100),2)
		  ELSE ROUND((l.curr_price - ROUND(l.curr_price * l.discount/100,2 * l.discount/100,2)),2,1) END
	   --ELSE ROUND((l.curr_price - ROUND(cv1.amt_disc,2)),2,1) -- v10.7
	   -- END v11.6
	END END as price,             --v3.0  
	l.price_type,  
	isnull(l.note,''),  
	l.status,  
	l.cost,  
	l.who_entered,  
	l.sales_comm,  
	l.temp_price,  
	l.temp_type,  
	l.cr_ordered,  
	l.cr_shipped,  
	l.discount,  
	l.uom,  
	l.conv_factor,  
	l.void,  
	l.void_who,  
	l.void_date,  
	l.std_cost,  
	l.cubic_feet,  
	l.printed,  
	l.lb_tracking,  
	l.labor,  
	l.direct_dolrs,  
	l.ovhd_dolrs,  
	l.util_dolrs,  
	l.taxable,  
	l.weight_ea,  
	l.qc_flag,  
	l.reason_code,  
	l.row_id,  
	l.qc_no,  
	l.rejected,  
	l.part_type,  
	isnull(l.orig_part_no,''),  
	l.back_ord_flag,  
	l.gl_rev_acct,  
	l.total_tax,  
	l.tax_code,  
	l.curr_price,  
	l.oper_price,  
	l.display_line,
	-- START v11.5  
	--cv1.list_price as std_direct_dolrs,                   --v3.0 List Price  
	-- v12.2 Start
	CASE WHEN l.curr_price < 0 THEN l.curr_price ELSE
	CASE WHEN l.curr_price > cv1.list_price THEN l.curr_price ELSE cv1.list_price END 
	END
	-- v12.2 End
	as std_direct_dolrs,                   --v3.0 List Price 
	/*
	CASE o.type WHEN 'I' THEN (cv1.list_price - l.curr_price) + ROUND(cv1.amt_disc,2) -- v10.7 
	   ELSE CASE l.discount WHEN 0 THEN (cv1.list_price - l.curr_price)   
	   ELSE (cv1.list_price - l.curr_price) + ROUND(cv1.amt_disc,2) -- v10.7  
	END END as std_ovhd_dolrs,      --v3.0 Total Discount  
	*/
	-- v12.2 Start
	CASE WHEN l.curr_price < 0 THEN 0 ELSE
	CASE WHEN l.curr_price > cv1.list_price THEN 0 ELSE
		CASE o.type WHEN 'I' THEN (cv1.list_price - l.curr_price) + ROUND(cv1.amt_disc,2) -- v10.7 
		ELSE CASE l.discount WHEN 0 THEN (cv1.list_price - l.curr_price) 
		-- START v11.6
		ELSE CASE WHEN cv1.list_price = l.curr_price THEN ROUND(cv1.list_price * l.discount/100,2) 
		ELSE (cv1.list_price - l.curr_price) + ROUND(l.curr_price * l.discount/100,2) END END
		--ELSE (cv1.list_price - l.curr_price) + ROUND(cv1.amt_disc,2) END -- v10.7  
		-- END v11.6 
		END 
	END
	END
	-- v12.2 End
	as std_ovhd_dolrs,      --v3.0 Total Discount 
	/*
	CASE l.price WHEN 0 THEN 100                    --v3.0 Discount Pct  
		ELSE CASE cv1.list_price WHEN 0 THEN 0  
		ELSE CASE o.type WHEN 'I'   
		  THEN CAST((((cv1.list_price - (l.curr_price - ROUND(cv1.amt_disc,2))) / cv1.list_price) * 100) as DECIMAL(20,2))  -- v10.7
		ELSE CASE l.discount WHEN 0 THEN CAST((((cv1.list_price - (l.curr_price - ROUND(cv1.amt_disc,2))) / cv1.list_price) * 100) as DECIMAL(20,2))  -- v10.7
		ELSE CAST((((cv1.list_price - l.curr_price) / cv1.list_price) * 100) as DECIMAL(20,2))  
	END END END END as std_util_dolrs,                    --v3.0 Discount Pct  
	*/
	CASE WHEN l.curr_price > cv1.list_price THEN 0 ELSE
		CASE l.price WHEN 0 THEN 100                    --v3.0 Discount Pct  
		ELSE CASE cv1.list_price WHEN 0 THEN 0  
		ELSE CASE o.type WHEN 'I'   
		  THEN CAST((((cv1.list_price - (l.curr_price - ROUND(cv1.amt_disc,2))) / cv1.list_price) * 100) as DECIMAL(20,2))  -- v10.7
		ELSE CASE l.discount WHEN 0 THEN CAST((((cv1.list_price - (l.curr_price - ROUND(cv1.amt_disc,2))) / cv1.list_price) * 100) as DECIMAL(20,2))  -- v10.7
		ELSE CAST((((cv1.list_price - l.curr_price) / cv1.list_price) * 100) as DECIMAL(20,2))  
	END END END END END as std_util_dolrs,                    --v3.0 Discount Pct  
	-- END v11.5
	l.reference_code,  
	l.contract,  
	l.agreement_id,  
	l.ship_to,  
	l.service_agreement_flag,  
	l.inv_available_flag,  
	l.create_po_flag,  
	l.load_group_no,  
	l.return_code,  
	l.user_count,  
	datalength(rtrim(replace(cast((l.ordered + l.cr_ordered) as varchar(40)),'0',' '))) -   
	charindex('.',cast((l.ordered + l.cr_ordered) as varchar(40))),  
	datalength(rtrim(replace(cast((l.shipped + l.cr_shipped) as varchar(40)),'0',' '))) -   
	charindex('.',cast((l.shipped + l.cr_shipped) as varchar(40))),  
	datalength(rtrim(replace(cast(l.curr_price as varchar(40)),'0',' '))) -   
	charindex('.',cast(l.curr_price as varchar(40))),  
	  
	c.customer_name,     
	isnull(c.addr1,''),  
	isnull(c.addr2,''),     
	isnull(c.addr3,''),     
	isnull(c.addr4,''),     
	isnull(c.addr5,''),     
	isnull(c.addr6,''),  
	c.contact_name,     
	c.inv_comment_code,     
	c.city,  
	c.state,     
	c.postal_code,  
	c.country,  
	  
	n.company_name,     
	n.addr1,     
	n.addr2,     
	n.addr3,     
	n.addr4,     
	n.addr5,     
	n.addr6,     
	  
	isnull(r.name,''),  
	isnull(r.addr1,''),     
	isnull(r.addr2,''),     
	isnull(r.addr3,''),     
	isnull(r.addr4,''),     
	isnull(r.addr5,''),     
	  
	g.currency_mask,     
	g.curr_precision,   
	g.rounding_factor,   
	case when g.neg_num_format in (0,1,2,10,15) then 1 when g.neg_num_format in (6,7,9,14) then 2   
	  when g.neg_num_format in (5,8,11,16) then 3 else 0 end,  
	case when g.neg_num_format in (2,3,6,9,10,13) then 1 when g.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,  
	g.symbol,  
	case when g.neg_num_format < 9 then '' when g.neg_num_format in (9,11,14,16) then 'b' else 'a' end,  
	'.',  
	',',  
	  
	p.amt_payment,     
	p.amt_disc_taken,     
	  
	isnull(m.comment_line ,''),  
	  
	i.doc_ctrl_num,  
	#invoices.discount,  
	#invoices.tax,  
	#invoices.freight,  
	#invoices.payments,  
	#invoices.total_invoice,  
	  
	isnull(v.ship_via_name,o.routing),  
	isnull(f.description,o.freight_allow_type),  
	isnull(fob.fob_desc,o.fob),  
	isnull(t.terms_desc,o.terms),  
	isnull(tax.tax_desc,o.tax_id),  
	isnull(taxd.tax_desc,l.tax_code),  
	case when o.type = 'I' then 'Invoice' else 'Credit Memo' end,  
	case when @order = 0 then o.cust_code   
	  when @order = 1 then replicate(' ',@ord_len - datalength(convert(varchar(10),#invoices.order_no))) + convert(varchar(10),#invoices.order_no)  
	  else '' end,  
	'',  
	  
	'',2,2,0,1,'','b','.',',',  
	isnull((select min(note_no) from notes n where n.code = convert(varchar(10),o.order_no) and n.code_type = 'O' and n.invoice = 'Y'),-1),  
	case when isnull(c.check_extendedname_flag,0) = 1 then c.extended_name else c.customer_name end -- extended_name  
	  
	from #invoices   
	join dbo.orders_all o (nolock) on o.order_no = #invoices.order_no and o.type = #invoices.type and o.ext = #invoices.order_ext -- v4.4
	join dbo.ord_list l (nolock) on l.order_no = o.order_no and l.order_ext = o.ext  
	join dbo.cvo_ord_list cv1 (nolock) on l.order_no = cv1.order_no and l.order_ext = cv1.order_ext and l.line_no = cv1.line_no  --v3.0  
	join dbo.adm_cust_all c (nolock) on c.customer_code = o.cust_code     
	join dbo.arco n (nolock) on 1 = 1  
	left outer join dbo.arremit r (nolock) on r.kys = o.remit_key  
	join dbo.glcurr_vw g (nolock) on g.currency_code = o.curr_key     
	left outer join dbo.ord_payment p (nolock) on p.order_no = o.order_no and p.order_ext = o.ext  
	left outer join dbo.arcommnt m (nolock) on m.comment_code = c.inv_comment_code  
	join dbo.cvo_order_invoice i (nolock) on i.order_no = o.order_no and i.order_ext = o.ext  
	left outer join dbo.arshipv v (nolock) on v.ship_via_code = o.routing  
	left outer join dbo.freight_type f (nolock) on f.kys = o.freight_allow_type  
	left outer join dbo.arfob fob (nolock) on fob.fob_code = o.fob  
	left outer join dbo.arterms t (nolock) on t.terms_code = o.terms  
	left outer join dbo.artax tax (nolock) on tax.tax_code = o.tax_id  
	left outer join dbo.artax taxd (nolock) on taxd.tax_code = l.tax_code  


END
ELSE
BEGIN  
	insert #rpt_soinvform  
	SELECT   
	o.order_no, o.ext, o.cust_code, o.ship_to, o.req_ship_date, o.sch_ship_date, o.date_shipped, o.date_entered,  
	o.cust_po, o.who_entered, o.status, o.attention, o.phone, o.terms, o.routing, o.special_instr, o.invoice_date,  
	o.total_invoice, o.total_amt_order, o.salesperson, o.tax_id, o.tax_perc, o.invoice_no, o.fob, o.freight,  
	#invoices.printed,  
	o.discount, o.label_no, o.cancel_date, o.new,  
	isnull(o.ship_to_name,''),    -- mls 3/1/05 SCR 34332  
	isnull(o.ship_to_add_1,''),  
	isnull(o.ship_to_add_2,''),  
	isnull(o.ship_to_add_3,''),  
	isnull(o.ship_to_add_4,''),  
	isnull(o.ship_to_add_5,''),  
	isnull(o.ship_to_city,''),  
	isnull(o.ship_to_state,''),  
	isnull(o.ship_to_zip,''),  
	isnull(o.ship_to_country,''),  
	isnull(o.ship_to_region,''),  
	o.cash_flag, o.type, o.back_ord_flag, o.freight_allow_pct, o.route_code, o.route_no, o.date_printed, o.date_transfered,  
	o.cr_invoice_no, o.who_picked, o.note, o.void, o.void_who, o.void_date, o.changed, isnull(o.remit_key,''),  
	o.forwarder_key, o.freight_to, o.sales_comm, o.freight_allow_type, o.cust_dfpa, o.location,   
	o.total_tax, o.total_discount, o.f_note, o.invoice_edi, o.edi_batch, o.post_edi_date, o.blanket,   
	o.gross_sales, o.load_no, o.curr_key, o.curr_type, o.curr_factor, o.bill_to_key, o.oper_factor,   
	o.tot_ord_tax, o.tot_ord_disc, o.tot_ord_freight, o.posting_code, o.rate_type_home, o.rate_type_oper, o.reference_code,  
	o.hold_reason, o.dest_zone_code, o.orig_no, o.orig_ext, o.tot_tax_incl, o.process_ctrl_num, o.batch_code, o.tot_ord_incl,  
	o.barcode_status, o.multiple_flag, o.so_priority_code, o.FO_order_no, o.blanket_amt, o.user_priority, o.user_category,  
	o.from_date, o.to_date, isnull(o.consolidate_flag,0), o.proc_inv_no,  
	isnull(o.sold_to_addr1,''),  -- mls 3/1/05 SCR 34332   
	isnull(o.sold_to_addr2,''),  
	isnull(o.sold_to_addr3,''),  
	isnull(o.sold_to_addr4,''),  
	isnull(o.sold_to_addr5,''),  
	isnull(o.sold_to_addr6,''),  
	o.user_code, o.user_def_fld1, o.user_def_fld2, o.user_def_fld3, o.user_def_fld4, o.user_def_fld5, o.user_def_fld6,  
	o.user_def_fld7, o.user_def_fld8, o.user_def_fld9, o.user_def_fld10, o.user_def_fld11, o.user_def_fld12,  
	case when o.type != 'I' then 0 else isnull(o.eprocurement_ind,0) end,  
	o.sold_to,  
	  
	l.line_no,  
	l.location,  
	l.part_no,  
	isnull(l.description,''),  
	l.time_entered,  
	l.ordered,  
	l.shipped,  
	CASE o.type WHEN 'I' THEN ROUND((l.curr_price - ROUND(cv1.amt_disc,2)),2,1)  -- v10.7
	   ELSE CASE l.discount WHEN 0 THEN l.curr_price  
	   -- START v11.6
	   ELSE CASE WHEN cv1.list_price = l.curr_price THEN ROUND(cv1.list_price - (cv1.list_price * l.discount/100),2)
		  ELSE ROUND((l.curr_price - ROUND(l.curr_price * l.discount/100,2 * l.discount/100,2)),2,1) END
	   --ELSE ROUND((l.curr_price - ROUND(cv1.amt_disc,2)),2,1) -- v10.7
	   -- END v11.6
	END END as price,             --v3.0  
	l.price_type,  
	isnull(l.note,''),  
	l.status,  
	l.cost,  
	l.who_entered,  
	l.sales_comm,  
	l.temp_price,  
	l.temp_type,  
	l.cr_ordered,  
	l.cr_shipped,  
	l.discount,  
	l.uom,  
	l.conv_factor,  
	l.void,  
	l.void_who,  
	l.void_date,  
	l.std_cost,  
	l.cubic_feet,  
	l.printed,  
	l.lb_tracking,  
	l.labor,  
	l.direct_dolrs,  
	l.ovhd_dolrs,  
	l.util_dolrs,  
	l.taxable,  
	l.weight_ea,  
	l.qc_flag,  
	l.reason_code,  
	l.row_id,  
	l.qc_no,  
	l.rejected,  
	l.part_type,  
	isnull(l.orig_part_no,''),  
	l.back_ord_flag,  
	l.gl_rev_acct,  
	l.total_tax,  
	l.tax_code,  
	l.curr_price,  
	l.oper_price,  
	l.display_line,
	-- START v11.5  
	--cv1.list_price as std_direct_dolrs,                   --v3.0 List Price  
	-- v12.2 Start
	CASE WHEN l.curr_price < 0 THEN l.curr_price ELSE
	CASE WHEN l.curr_price > cv1.list_price THEN l.curr_price ELSE cv1.list_price END 
	END
	-- v12.2 End
	as std_direct_dolrs,                   --v3.0 List Price 
	/*
	CASE o.type WHEN 'I' THEN (cv1.list_price - l.curr_price) + ROUND(cv1.amt_disc,2) -- v10.7 
	   ELSE CASE l.discount WHEN 0 THEN (cv1.list_price - l.curr_price)   
	   ELSE (cv1.list_price - l.curr_price) + ROUND(cv1.amt_disc,2) -- v10.7  
	END END as std_ovhd_dolrs,      --v3.0 Total Discount  
	*/
	-- v12.2 Start
	CASE WHEN l.curr_price < 0 THEN 0 ELSE
	CASE WHEN l.curr_price > cv1.list_price THEN 0 ELSE
		CASE o.type WHEN 'I' THEN (cv1.list_price - l.curr_price) + ROUND(cv1.amt_disc,2) -- v10.7 
		ELSE CASE l.discount WHEN 0 THEN (cv1.list_price - l.curr_price) 
		-- START v11.6
		ELSE CASE WHEN cv1.list_price = l.curr_price THEN ROUND(cv1.list_price * l.discount/100,2) 
		ELSE (cv1.list_price - l.curr_price) + ROUND(l.curr_price * l.discount/100,2) END END
		--ELSE (cv1.list_price - l.curr_price) + ROUND(cv1.amt_disc,2) END -- v10.7  
		-- END v11.6 
		END 
	END
	END
	-- v12.2 End
	as std_ovhd_dolrs,      --v3.0 Total Discount 
	/*
	CASE l.price WHEN 0 THEN 100                    --v3.0 Discount Pct  
		ELSE CASE cv1.list_price WHEN 0 THEN 0  
		ELSE CASE o.type WHEN 'I'   
		  THEN CAST((((cv1.list_price - (l.curr_price - ROUND(cv1.amt_disc,2))) / cv1.list_price) * 100) as DECIMAL(20,2))  -- v10.7
		ELSE CASE l.discount WHEN 0 THEN CAST((((cv1.list_price - (l.curr_price - ROUND(cv1.amt_disc,2))) / cv1.list_price) * 100) as DECIMAL(20,2))  -- v10.7
		ELSE CAST((((cv1.list_price - l.curr_price) / cv1.list_price) * 100) as DECIMAL(20,2))  
	END END END END as std_util_dolrs,                    --v3.0 Discount Pct  
	*/
	CASE WHEN l.curr_price > cv1.list_price THEN 0 ELSE
		CASE l.price WHEN 0 THEN 100                    --v3.0 Discount Pct  
		ELSE CASE cv1.list_price WHEN 0 THEN 0  
		ELSE CASE o.type WHEN 'I'   
		  THEN CAST((((cv1.list_price - (l.curr_price - ROUND(cv1.amt_disc,2))) / cv1.list_price) * 100) as DECIMAL(20,2))  -- v10.7
		ELSE CASE l.discount WHEN 0 THEN CAST((((cv1.list_price - (l.curr_price - ROUND(cv1.amt_disc,2))) / cv1.list_price) * 100) as DECIMAL(20,2))  -- v10.7
		ELSE CAST((((cv1.list_price - l.curr_price) / cv1.list_price) * 100) as DECIMAL(20,2))  
	END END END END END as std_util_dolrs,                    --v3.0 Discount Pct  
	-- END v11.5
	l.reference_code,  
	l.contract,  
	l.agreement_id,  
	l.ship_to,  
	l.service_agreement_flag,  
	l.inv_available_flag,  
	l.create_po_flag,  
	l.load_group_no,  
	l.return_code,  
	l.user_count,  
	datalength(rtrim(replace(cast((l.ordered + l.cr_ordered) as varchar(40)),'0',' '))) -   
	charindex('.',cast((l.ordered + l.cr_ordered) as varchar(40))),  
	datalength(rtrim(replace(cast((l.shipped + l.cr_shipped) as varchar(40)),'0',' '))) -   
	charindex('.',cast((l.shipped + l.cr_shipped) as varchar(40))),  
	datalength(rtrim(replace(cast(l.curr_price as varchar(40)),'0',' '))) -   
	charindex('.',cast(l.curr_price as varchar(40))),  
	  
	c.customer_name,     
	isnull(c.addr1,''),  
	isnull(c.addr2,''),     
	isnull(c.addr3,''),     
	isnull(c.addr4,''),     
	isnull(c.addr5,''),     
	isnull(c.addr6,''),  
	c.contact_name,     
	c.inv_comment_code,     
	c.city,  
	c.state,     
	c.postal_code,  
	c.country,  
	  
	n.company_name,     
	n.addr1,     
	n.addr2,     
	n.addr3,     
	n.addr4,     
	n.addr5,     
	n.addr6,     
	  
	isnull(r.name,''),  
	isnull(r.addr1,''),     
	isnull(r.addr2,''),     
	isnull(r.addr3,''),     
	isnull(r.addr4,''),     
	isnull(r.addr5,''),     
	  
	g.currency_mask,     
	g.curr_precision,   
	g.rounding_factor,   
	case when g.neg_num_format in (0,1,2,10,15) then 1 when g.neg_num_format in (6,7,9,14) then 2   
	  when g.neg_num_format in (5,8,11,16) then 3 else 0 end,  
	case when g.neg_num_format in (2,3,6,9,10,13) then 1 when g.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,  
	g.symbol,  
	case when g.neg_num_format < 9 then '' when g.neg_num_format in (9,11,14,16) then 'b' else 'a' end,  
	'.',  
	',',  
	  
	p.amt_payment,     
	p.amt_disc_taken,     
	  
	isnull(m.comment_line ,''),  
	  
	i.doc_ctrl_num,  
	#invoices.discount,  
	#invoices.tax,  
	#invoices.freight,  
	#invoices.payments,  
	#invoices.total_invoice,  
	  
	isnull(v.ship_via_name,o.routing),  
	isnull(f.description,o.freight_allow_type),  
	isnull(fob.fob_desc,o.fob),  
	isnull(t.terms_desc,o.terms),  
	isnull(tax.tax_desc,o.tax_id),  
	isnull(taxd.tax_desc,l.tax_code),  
	case when o.type = 'I' then 'Invoice' else 'Credit Memo' end,  
	case when @order = 0 then o.cust_code   
	  when @order = 1 then replicate(' ',@ord_len - datalength(convert(varchar(10),#invoices.order_no))) + convert(varchar(10),#invoices.order_no)  
	  else '' end,  
	'',  
	  
	'',2,2,0,1,'','b','.',',',  
	isnull((select min(note_no) from notes n where n.code = convert(varchar(10),o.order_no) and n.code_type = 'O' and n.invoice = 'Y'),-1),  
	case when isnull(c.check_extendedname_flag,0) = 1 then c.extended_name else c.customer_name end -- extended_name  
	  
	from #invoices   
	join dbo.orders_all o (nolock) on o.invoice_no = #invoices.invoice_no and o.type = #invoices.type and o.ext = #invoices.order_ext -- v4.4
	join dbo.ord_list l (nolock) on l.order_no = o.order_no and l.order_ext = o.ext  
	join dbo.cvo_ord_list cv1 (nolock) on l.order_no = cv1.order_no and l.order_ext = cv1.order_ext and l.line_no = cv1.line_no  --v3.0  
	join dbo.adm_cust_all c (nolock) on c.customer_code = o.cust_code     
	join dbo.arco n (nolock) on 1 = 1  
	left outer join dbo.arremit r (nolock) on r.kys = o.remit_key  
	join dbo.glcurr_vw g (nolock) on g.currency_code = o.curr_key     
	left outer join dbo.ord_payment p (nolock) on p.order_no = o.order_no and p.order_ext = o.ext  
	left outer join dbo.arcommnt m (nolock) on m.comment_code = c.inv_comment_code  
	join dbo.orders_invoice i (nolock) on i.order_no = o.order_no and i.order_ext = o.ext  
	left outer join dbo.arshipv v (nolock) on v.ship_via_code = o.routing  
	left outer join dbo.freight_type f (nolock) on f.kys = o.freight_allow_type  
	left outer join dbo.arfob fob (nolock) on fob.fob_code = o.fob  
	left outer join dbo.arterms t (nolock) on t.terms_code = o.terms  
	left outer join dbo.artax tax (nolock) on tax.tax_code = o.tax_id  
	left outer join dbo.artax taxd (nolock) on taxd.tax_code = l.tax_code  

END
-- v12.3 End
 
-- CVO : Delete any transactions where the Customer is not printing credit memos  
if ISNULL((select isnull(value_str,'N') from config where flag = 'CVO_FILTER_CREDITS'),'N') = 'Y'
begin
  delete #rpt_soinvform  where o_type = 'C'   
  and o_cust_code in (select customer_code 
					  from cvo_armaster_all (nolock) 
					  where cvo_print_cm = 0 and address_type = 0)  
end  
  
--v2.0 Add Buying Group Name  
UPDATE #rpt_soinvform SET o_user_def_fld4 = IsNull(customer_name,' ')  
  FROM #rpt_soinvform i  
 LEFT OUTER JOIN CVO_orders_all c (nolock) ON i.o_order_no = c.order_no AND i.o_ext = c.ext  
 LEFT OUTER JOIN arcust a (nolock) ON  c.buying_group = a.customer_code  
-- v11.1 WHERE ISNULL(a.alt_location_code,'1') = '1' -- v10.9 v11.0
--  

-- v10.9 Start - Clear out buying group is bg is set to print regular invoices
-- v11.1 Start
--UPDATE #rpt_soinvform SET o_user_def_fld4 = ' '
--  FROM #rpt_soinvform i  
-- LEFT OUTER JOIN CVO_orders_all c (nolock) ON i.o_order_no = c.order_no AND i.o_ext = c.ext  
-- LEFT OUTER JOIN arcust a (nolock) ON  c.buying_group = a.customer_code 
-- WHERE ISNULL(a.alt_location_code,'1') = '0' -- v11.0
-- v11.1 End
-- v10.9 End

UPDATE #rpt_soinvform SET o_user_def_fld9 = 1  
  FROM #rpt_soinvform i  
 LEFT OUTER JOIN CVO_orders_all c (nolock) ON i.o_order_no = c.order_no AND i.o_ext = c.ext  
 LEFT OUTER JOIN arcust a (nolock) ON  c.buying_group = a.customer_code  
 WHERE a.addr_sort1 = 'Buying Group' 
 AND ISNULL(a.alt_location_code,'1') = '1' -- v10.5 v11.0
 
--v2.0  
  
--v3.0  
UPDATE #rpt_soinvform SET r_addr5 = IsNull(p.promo_name,'')  
  FROM #rpt_soinvform i  
 LEFT OUTER JOIN CVO_orders_all c (nolock) ON i.o_order_no = c.order_no AND i.o_ext = c.ext  
 LEFT OUTER JOIN CVO_Promotions p (nolock) ON c.promo_id = p.promo_id AND c.promo_level = p.promo_level  
--  
  
--v4.0 BEGIN  - Set Date Entered to value of Original Order  
UPDATE #rpt_soinvform   
   SET o_date_entered = c.date_entered  
  FROM #rpt_soinvform i  
 LEFT OUTER JOIN orders_all c (nolock) ON i.o_order_no = c.order_no AND c.ext = 0  
--v4.0 END  
  
  
--v4.0 BEGIN  
UPDATE #rpt_soinvform   
   SET l_std_ovhd_dolrs = 0,   -- Disc Amount  
    l_price = l_std_direct_dolrs  -- Net Unit Price  
 WHERE o_user_def_fld9 = 1 
 AND l_part_no <> 'Credit Return Fee' -- v10.4
--v4.0 END  
  

-- v11.1 Start
UPDATE	o
-- START v11.7
SET		
l_std_direct_dolrs = CASE WHEN l.curr_price > cv1.list_price THEN l.curr_price ELSE cv1.orig_list_price END,
-- l_std_direct_dolrs = cv1.orig_list_price, -- v11.2 CASE WHEN l.curr_price = l.temp_price THEN cv1.list_price ELSE l.temp_price END,
l_std_ovhd_dolrs = CASE WHEN l.curr_price > cv1.list_price THEN 0 ELSE cv1.orig_list_price - l.curr_price END
-- l_std_ovhd_dolrs = cv1.orig_list_price - l.curr_price -- v11.2 CASE WHEN l.curr_price = l.temp_price THEN (cv1.orig_list_price - l.curr_price) 
								-- v11.2 ELSE (cv1.orig_list_price - l.curr_price) END
-- END v11.7
FROM	#rpt_soinvform o
JOIN	ord_list l (NOLOCK)
ON		o.o_order_no = l.order_no
AND		o.o_ext = l.order_ext
AND		o.l_line_no = l.line_no
JOIN	cvo_ord_list cv1 (NOLOCK)
ON		o.o_order_no = cv1.order_no
AND		o.o_ext = cv1.order_ext
AND		o.l_line_no = cv1.line_no
WHERE	ISNULL(o.o_user_def_fld4,'') <> ''
AND		ISNULL(o_user_def_fld9,0) = 0
AND		o.o_type = 'I'
-- v11.1 End
  
-- v11.4 Start
UPDATE	o
SET		l_std_direct_dolrs = l_price,
		l_std_ovhd_dolrs = 0
FROM	#rpt_soinvform o
JOIN	ord_list b (NOLOCK)
ON		o.o_order_no = b.order_no
AND		o.o_ext = b.order_ext
AND		o.l_line_no = b.line_no
JOIN	inv_master c (NOLOCK)
ON		b.part_no = c.part_no
JOIN	cvo_orders_all d (NOLOCK)
ON		o.o_order_no = d.order_no
AND		o.o_ext = d.ext
JOIN	CVO_line_discounts e (NOLOCK)
ON		d.promo_id = e.promo_id
AND		d.promo_level = e.promo_level
WHERE	c.type_code	= e.category
AND		ISNULL(e.price_override,'N') = 'Y'	

-- v11.4 End

update #rpt_soinvform  
set h_currency_mask = h.currency_mask,  
h_curr_precision = h.curr_precision,  
h_rounding_factor = h.rounding_factor,  
h_position = case when h.neg_num_format in (0,1,2,10,15) then 1 when h.neg_num_format in (6,7,9,14) then 2   
  when h.neg_num_format in (5,8,11,16) then 3 else 0 end,  
h_neg_num_format = case when h.neg_num_format in (2,3,6,9,10,13) then 1 when h.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,  
h_symbol = h.symbol,  
h_symbol_space = case when h.neg_num_format < 9 then '' when h.neg_num_format in (9,11,14,16) then 'b' else 'a' end  
from #rpt_soinvform, glcurr_vw h (nolock), glco g (nolock)  
where h.currency_code = g.home_currency  
  
select @inv_cnt = count(*) from #rpt_soinvform  
  
if isnull(@inv_cnt,0) > 0 and isnull(@prt_summ,'Y') = 'Y'  
begin  
set rowcount 1  
  insert #rpt_soinvform (o_type,o_sort_order, o_sort_order2, o_sort_order3,o_invoice_no,l_description,  
h_currency_mask ,  
h_curr_precision,   
h_rounding_factor ,  
h_position ,  
h_neg_num_format,  
h_symbol,  
h_symbol_space,  
h_dec_separator,  
h_thou_separator  
)  
  select 'X','Summary Report',convert(varchar(10),@inv_cnt),'',@inv_cnt,'',  
h_currency_mask ,  
h_curr_precision,   
h_rounding_factor ,  
h_position ,  
h_neg_num_format,  
h_symbol,  
h_symbol_space,  
h_dec_separator,  
h_thou_separator  
from #rpt_soinvform  
set rowcount 0  
end  
  
-- v4.5
UPDATE	a
SET		o_invoice_date = b.inv_date
FROM	#rpt_soinvform a
JOIN	cvo_order_invoice b (NOLOCK)
ON		a.o_order_no = b.order_no
AND		a.o_ext = b.order_ext
WHERE	b.inv_date IS NOT NULL
AND		a.o_type = 'I'

-- v4.6
UPDATE	#rpt_soinvform
SET		o_invoice_date = o_date_shipped
FROM	#rpt_soinvform 
WHERE	o_type = 'C'

-- v11.3 Start
UPDATE	a
SET		o_cust_po = b.ra1
FROM	#rpt_soinvform a
JOIN	cvo_orders_all b (NOLOCK)
ON		a.o_order_no = b.order_no
AND		a.o_ext = b.ext
WHERE	o_type = 'C'
AND		b.ra1 IS NOT NULL
-- v11.3 End

-- v10.1 Start
UPDATE	a
SET		l_description = CASE WHEN b.is_customized = 'S' THEN '(*) ' + a.l_description ELSE a.l_description END -- v10.3
-- v10.3 SET		l_description = CASE WHEN b.is_customized = 'S' THEN '(*1) ' + a.l_description ELSE a.l_description END
FROM	#rpt_soinvform a
JOIN	cvo_ord_list b (NOLOCK)
ON		a.o_order_no = b.order_no
AND		a.o_ext = b.order_ext
AND		a.l_line_no = b.line_no
  -- v10.1 End

-- v10.2 Start
UPDATE	#rpt_soinvform
SET		l_display_line = CASE WHEN b.type_code = 'FRAME' THEN 1
							  WHEN b.type_code = 'SUN' THEN 1
							  ELSE 2 END
FROM	#rpt_soinvform a
JOIN	inv_master b (NOLOCK)
ON		a.l_part_no = b.part_no
-- v10.2 End

-- v10.5 Start -- invoice notes
UPDATE	a
SET		o_special_instr = b.invoice_note
FROM	#rpt_soinvform a
JOIN	cvo_orders_all b (NOLOCK)
ON		a.o_order_no = b.order_no
AND		a.o_ext = b.ext
-- v10.5 End

-- v12.0 Start
UPDATE	a
SET		l_std_direct_dolrs = l_price, -- v12.1
		l_price = 0,
		l_std_ovhd_dolrs = l_price -- v12.1
FROM	#rpt_soinvform a
JOIN	cvo_ord_list b (NOLOCK)
ON		a.o_order_no = b.order_no
AND		a.o_ext = b.order_ext
AND		a.l_line_no = b.line_no
JOIN	cvo_orders_all c (NOLOCK)
ON		a.o_order_no = c.order_no
AND		a.o_ext = c.ext
WHERE	(b.free_frame = 1 OR a.l_discount = 100) 
AND		ISNULL(c.buying_group,'') > ''
-- v12.0 End

-- v12.2 Start
UPDATE	#rpt_soinvform
SET		l_std_direct_dolrs = l_price,
		l_std_ovhd_dolrs = 0
WHERE	l_price < 0
-- v12.2 End

-- v11.8 Start
UPDATE	#rpt_soinvform
SET		o_special_instr = m_comment_line + CASE WHEN ISNULL(o_special_instr,'') > '' THEN ' \ ' ELSE '' END + ISNULL(o_special_instr,'')
WHERE	ISNULL(m_comment_line,'') > ''
-- v11.8 End

if isnull(@rpt_table,'') = ''  
begin  
  select * from #rpt_soinvform (nolock)  
  order by o_type,o_sort_order, o_sort_order2, o_sort_order3, i_doc_ctrl_num,   
  l_display_line  
end  
else  
begin  
  exec ('insert into ' + @rpt_table + '  
  select * from #rpt_soinvform (nolock)  
  order by o_type,o_sort_order, o_sort_order2, o_sort_order3, i_doc_ctrl_num,   
  l_display_line')  
end  
end  
  
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_soinvform] TO [public]
GO
