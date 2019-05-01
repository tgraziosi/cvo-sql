SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[fs_create_backorder] @ordno int, @ordext int AS
declare @ext int, @xlp int, @tot_inv decimal(20,8), @tot_tax decimal(20,8),  
 @tot_disc decimal(20,8), @sub_tot decimal(20,8), @disc decimal(20,8),  
 @frt decimal(20,8), @tax decimal(20,8), @invno int, @edi_inv char(1),  
 @currency varchar(10), @precision int, @newstat char(1), @qty decimal(20,8),  
        @err int  
DECLARE @process_id varchar(10), @action_id varchar(10)  
DECLARE @doc_ctrl_num  VARCHAR(16) -- #9  
declare @prod_no int, @new_prod int, @ptype char(1), @rc int, @shipped decimal(20,8), @prod_ext int -- mls 3/26/01 SCR 20667  
  
/*START: 02/09/2010, AMENDEZ, 68668-001-MOD: Freight Lookup Calculation*/  
DECLARE @carrier	VARCHAR(20),  
		@cust_code	VARCHAR(20),  
		@ship_to	VARCHAR(20),
		@cust_terms	VARCHAR(8),													-- CVO - Progressive Aging Mod
		@sold_to	varchar(10) -- v10.1


DECLARE @freight_allow_type VARCHAR(10) -- v3.2

-- START v11.1
DECLARE @is_discadj SMALLINT,
		@std_price	DECIMAL(20,8),
		@promo_disc	DECIMAL(20,8)
-- END v11.1

-- START v11.3
DECLARE @promo_id		VARCHAR(20),	
		@promo_level	VARCHAR(30)
-- END v11.3
SET NOCOUNT ON


/*END: 02/09/2010, AMENDEZ, 68668-001-MOD: Freight Lookup Calculation*/  

-- v1.1 CB 13/04/2011 - Future Allocations
-- v1.2 CB 11/11/2011 - Add in prior_hold column
-- v1.3 CB 20/02/2012 - Add in missing columns for cvo_ord_list and cvo_ord_list_kit
-- v2.0	TM 03/27/2012 - When creating backorder we must carry forward the SOLD_TO (Global Lab)
-- v2.1 CB 25/04/2012 - Copy the address from original order
-- v3.0	TM 04/18/2012 - Ship To Country Code not being sent
-- v3.2 CT 19/09/2012 - Check customer freight settings for free freight on back orders

-- v10.0 CB 18/05/2012 - Soft Allocation Process
-- v10.1 CB 22/11/2012 - Fix - When the order has a global lab set then use the carrier from the global lab
-- v10.2 CT 04/12/2012 - Add invoice_note
-- v10.3 CB 24/12/2012 - Issue #1041 - Add back in from_line_no and add orig_list_price
-- v10.4 CT 28/02/2013 - New field on cvo_ord_list (free_frame)
-- v10.5 CB 18/04/2013 - Issue #1209 - Carrier for global lab needs to come from ext 0 order
-- v10.6 CB 29/04/2013 - Convert old order to new soft allocation
-- v10.7 CB 02/05/2013 - Clear up soft allocation on posting
-- v10.8 CB 07/06/2013 - Frame / Case releationship at order entry
-- v10.9 CB 11/06/2013 - Issue #1043 - POP Backorder freight
-- v11.0 CB 11/06/2013 - Issue #965 - Tax Calculation
-- v11.1 CT 03/07/2013 - Issue #863 - If order line exists in discount adjustment audit table then use the details from there
-- v11.2 CB 16/07/2013 - Issue #927 - Buying Group Switching
-- v11.3 CT 07/02/2014 - Issue #864 - If current order has a drawdown promo on it, apply relevant credit to backorder
-- v11.4 CB 14/02/2014 - Issue #1302 - Commission Override
-- v11.5 CT	11/11/2014 - Issue #1505 - Add email address
-- v11.6 CB 06/01/2015 - Fix issue with st_consolidate not being populated on a backorder
-- v11.7 CB 18/03/2015 - Initialize st_consolidate flag on a backorder
-- v11.8 CT 15/05/2015 - Issue #1474 - don't create backorder if only out of stock items are cases
-- v11.9 CB 21/08/2015 - Issue #1563 - Upsell flag
-- v12.0 CB 26/01/2016 - #1581 2nd Polarized Option
-- v12.1 CB 20/06/2016 - Issue #1602 - Must Go Today flag
-- v12.2 CB 12/07/2016 - Issue #1602 - Default Must Go Today flag to zero for backorders
-- v12.3 CB 06/03/2017 - For backorders clean out the freight_allow_type ifthe carrier is not 3rd party
-- v12.4 CB 19/09/2017 - Check for customers set for no freight charge
-- v12.5 CB 13/11/2018 - Add upsell_flag for detail
-- v12.6 CB 29/11/2018 - #1502 Multi Salesrep
-- v12.7 CB 20/03/2019 - Add in additional fields for #1502
-- v12.8 CB 18/04/2019 - Add in thrid party ship to data
  
exec @err = fs_updordtots @ordno, @ordext  
 if @@error != 0  
 begin  
  return @@error  
 end  
 if @err != 1  
 begin  
  return @err  
 end  

-- v10.7 Start
IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @ordno and ext = @ordext AND status > 'R')
BEGIN
	INSERT	dbo.cvo_soft_alloc_hdr_posted (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
	SELECT	soft_alloc_no, order_no, order_ext, location, bo_hold, status
	FROM	dbo.cvo_soft_alloc_hdr
	WHERE	order_no = @ordno
	AND		order_ext = @ordext

	INSERT	dbo.cvo_soft_alloc_det_posted (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
											kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, row_id)
	SELECT	soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
											kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, row_id
	FROM	dbo.cvo_soft_alloc_det
	WHERE	order_no = @ordno
	AND		order_ext = @ordext

	DELETE	dbo.cvo_soft_alloc_hdr
	WHERE	order_no = @ordno
	AND		order_ext = @ordext
	  
	DELETE	dbo.cvo_soft_alloc_det
	WHERE	order_no = @ordno
	AND		order_ext = @ordext
END 

  
if (select back_ord_flag from orders_all where order_no=@ordno and ext=@ordext) != '0'  
BEGIN  
 return 1  
END  
  
  
if NOT exists (select * from ord_list where order_no=@ordno and order_ext=@ordext  
 and shipped < ordered and back_ord_flag='0' )  
   begin  
 return 1  
   end  
 

-- START v11.8
-- If only cases outstanding then don't create backorder
IF NOT EXISTS(SELECT 1 FROM dbo.ord_list a (NOLOCK) INNER JOIN dbo.inv_master b (NOLOCK) ON a.part_no = b.part_no WHERE a.order_no=@ordno AND a.order_ext=@ordext  
 AND a.shipped < a.ordered AND a.back_ord_flag='0' AND b.type_code <> 'CASE')
BEGIN
	RETURN 1
END
-- END v11.8  
  
select @ext = (SELECT MAX( ext )FROM orders_all (NOLOCK) WHERE order_no = @ordno)  
  
select @ext=@ext + 1  
  
  
if exists (select * from orders_all (NOLOCK) where order_no = @ordno and ext = @ext) return 1  -- mls 3/29/00 SCR 70 20720  
  
/*START: 02/09/2010, AMENDEZ, 68668-001-MOD: Freight Lookup Calculation*/  
SELECT @cust_code = cust_code, @ship_to = ship_to, @sold_to = sold_to FROM orders (NOLOCK) WHERE order_no=@ordno and ext=@ordext  -- v10.1
  
SELECT @cust_terms = terms_code FROM arcust (NOLOCK) WHERE customer_code = @cust_code						-- CVO - Progressive Aging Mod

SELECT @carrier = bo_carrier FROM CVO_armaster_all (NOLOCK) WHERE customer_code = @cust_code AND ship_to = @ship_to AND address_type = 0  
  
-- v10.1 Start
IF (ISNULL(@sold_to,'') > '')
BEGIN
	-- v10.5 Start
	SELECT @carrier = routing FROM orders (NOLOCK) WHERE order_no=@ordno and ext=@ordext  
	IF (ISNULL(@carrier, '') = '')
		SELECT @carrier = ship_via_code FROM armaster_all (NOLOCK) WHERE address_type = 9 and customer_code = @sold_to
END
-- v10.1 End

IF ISNULL(@carrier, '') = ''  
BEGIN  
 SELECT @carrier = routing FROM orders (NOLOCK) WHERE order_no=@ordno and ext=@ordext  
END  
/*END: 02/09/2010, AMENDEZ, 68668-001-MOD: Freight Lookup Calculation*/  
  
-- START v3.2
SET @freight_allow_type = NULL

-- v12.3 Start
IF (LEFT(@carrier,1) <> '3')
BEGIN
	SET @freight_allow_type = ''
END
-- v12.3 End

-- v12.4 IF EXISTS(SELECT 1 FROM dbo.cvo_armaster_all (NOLOCK) WHERE customer_code = @cust_code AND address_type = 0 AND ISNULL(freight_charge,1) = 2)
IF EXISTS(SELECT 1 FROM dbo.cvo_armaster_all (NOLOCK) WHERE customer_code = @cust_code AND address_type = 0 AND ISNULL(freight_charge,1) IN (2,3)) -- v12.4
BEGIN
	SET @freight_allow_type = 'FRTOVRID'
END
-- END v3.2

INSERT orders_all ( order_no, ext,  cust_code, ship_to,  
  req_ship_date, sch_ship_date, date_shipped, date_entered,                     
  cust_po, who_entered, status,  attention,                        
  phone,  terms,  routing, special_instr,  
  invoice_date, total_invoice, total_amt_order,salesperson,  
  tax_id,  tax_perc, invoice_no, fob,  
  freight, printed, discount, label_no,  
  cancel_date, new,  ship_to_name,  
  ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4,  
  ship_to_add_5, ship_to_city, ship_to_state,  
  ship_to_zip, ship_to_country,ship_to_region, cash_flag,  
  type,  back_ord_flag, freight_allow_pct,  
  route_code, route_no, date_printed,  
  date_transfered,cr_invoice_no, who_picked, note,  
  void,  void_who, void_date, changed,  
  remit_key, forwarder_key, freight_to, sales_comm,  
  freight_allow_type,cust_dfpa, location, total_tax,  
  total_discount, f_note,  invoice_edi, edi_batch,  
  post_edi_date, blanket, gross_sales, load_no,  
  curr_key, curr_type, curr_factor, bill_to_key,  
  oper_factor, tot_ord_tax, tot_ord_disc, tot_ord_freight,  
  posting_code, rate_type_home, rate_type_oper, reference_code,  
  hold_reason, dest_zone_code, orig_no, orig_ext,  
  tot_tax_incl, multiple_flag, user_code,   
  consolidate_flag,     --skk 05/16/00 mshipto   
                user_priority,  user_category,  so_priority_code, eprocurement_ind, -- mls 10/2/03 SCR 31956  
                FO_order_no,    proc_inv_no,
				sold_to, sold_to_city, sold_to_state, sold_to_zip, sold_to_country_cd,				--v2.0
                sold_to_addr1,  sold_to_addr2,  sold_to_addr3,  sold_to_addr4,    
                sold_to_addr5,  sold_to_addr6,  
		ship_to_country_cd,						--v3.0
                user_def_fld1,  user_def_fld2,  user_def_fld3,  user_def_fld4,    
                user_def_fld5,  user_def_fld6,  user_def_fld7,  user_def_fld8,    
                user_def_fld9,  user_def_fld10, user_def_fld11, user_def_fld12, internal_so_ind)      
 SELECT order_no, @ext,  cust_code, ship_to,  
  req_ship_date, sch_ship_date, null,  getdate(),                     
  cust_po, 'BACKORDR', '@',  attention,                        
  phone,  IsNull(@cust_terms,terms),  @carrier, special_instr,						-- CVO - Progressive Aging Mod
  null,  0,  0,  salesperson,  
  tax_id,  tax_perc, 0,  fob,  
  0,  'N',  discount, 0,  
  cancel_date, new,  ship_to_name,  
  ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4,  
  ship_to_add_5, ship_to_city, ship_to_state,  
  
  ship_to_zip, ship_to_country,ship_to_region, cash_flag,  
  type,  back_ord_flag, freight_allow_pct,  
  route_code, route_no, null,  
  null,  0,  null,  note,  
  void,  void_who, void_date, changed,  
  remit_key, forwarder_key, freight_to, sales_comm,  
  -- START v3.2
  ISNULL(@freight_allow_type,freight_allow_type),cust_dfpa, location, 0,  
  --freight_allow_type,cust_dfpa, location, 0, 
  -- END v3.2 
  0,  f_note,  'N',  null,  
  null,  blanket, 0,  0,  
  curr_key, curr_type, curr_factor, bill_to_key,  
  oper_factor, 0,  0,  0,  
  posting_code, rate_type_home, rate_type_oper, reference_code,  
  hold_reason, dest_zone_code, order_no, ext,  
  0,  multiple_flag, (SELECT user_stat_code FROM so_usrstat WHERE default_flag = 1 AND status_code = 'N'),  
  consolidate_flag,     --skk 05/16/00 mshipto        
                user_priority,  user_category,  so_priority_code, eprocurement_ind, -- mls 10/2/03 SCR 31956  
                FO_order_no,    proc_inv_no,
				sold_to, sold_to_city, sold_to_state, sold_to_zip, sold_to_country_cd,				--v2.0
                sold_to_addr1,  sold_to_addr2,  sold_to_addr3,  sold_to_addr4,    
                sold_to_addr5,  sold_to_addr6,  
		ship_to_country_cd,								--v3.0
                user_def_fld1,  user_def_fld2,  user_def_fld3,  user_def_fld4,    
                user_def_fld5,  user_def_fld6,  user_def_fld7,  user_def_fld8,    
                user_def_fld9,  user_def_fld10, user_def_fld11, user_def_fld12, internal_so_ind  
 FROM orders_all 
 WHERE order_no=@ordno and ext=@ordext  
 if @@error != 0  
 begin  
  return @@error  
 end  
  

 /*START: 03/31/2010, AMENDEZ, 68668-001-MOD Promotions modification*/  
-- v1.1 Add new column
-- v2.0 Add missing columns		TLM
 INSERT INTO CVO_orders_all (  
    order_no,  ext,  add_case, add_pattern, promo_id, promo_level, free_shipping,
		split_order, flag_print, buying_group, allocation_date,  commission_pct, stage_hold,prior_hold, invoice_note, commission_override, email_address, st_consolidate, upsell_flag, must_go_today, written_by) -- v1.2 + v10.2 v11.4 v11.5 v11.6 v11.9 v12.1 v12.7
 SELECT order_no, @ext, add_case, add_pattern, promo_id, promo_level, free_shipping,
		split_order, flag_print, dbo.f_cvo_get_buying_group(@cust_code,GETDATE()), allocation_date,  commission_pct, stage_hold, prior_hold, invoice_note, commission_override, email_address, 0, upsell_flag, 0, written_by -- v1.2 + v10.2 + v11.2 v11.4 v11.5 v11.6 v11.7 v11.9 v12.1 v12.2
 FROM CVO_orders_all  
 WHERE order_no=@ordno and ext=@ordext  
 if @@error != 0  
 begin  
  return @@error  
 end  
 /*END: 03/31/2010, AMENDEZ, 68668-001-MOD Promotions modification*/  

-- v12.6 Start
	INSERT	ord_rep (order_no, order_ext, salesperson, sales_comm, percent_flag, exclusive_flag, split_flag, note, display_line,
		primary_rep, include_rx, brand, brand_split, brand_excl, commission, brand_exclude, promo_id, rx_only, startdate, enddate) -- v12.7
	SELECT	order_no, @ext, salesperson, sales_comm, percent_flag, exclusive_flag, split_flag, note, display_line,
		primary_rep, include_rx, brand, brand_split, brand_excl, commission, brand_exclude, promo_id, rx_only, startdate, enddate -- v12.7
	FROM	ord_rep (NOLOCK)
	WHERE	order_no = @ordno
	AND		order_ext = @ordext

	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN @@error   
	END  

	-- v12.8 Start
	INSERT	cvo_order_third_party_ship_to (order_no, order_ext, third_party_code, tp_address_1, tp_address_2, tp_address_3, tp_address_4, tp_address_5, tp_address_6,
		tp_city, tp_state, tp_zip, tp_country)
	SELECT	order_no, @ext, third_party_code, tp_address_1, tp_address_2, tp_address_3, tp_address_4, tp_address_5, tp_address_6,
			tp_city, tp_state, tp_zip, tp_country
	FROM	cvo_order_third_party_ship_to (NOLOCK)
	WHERE	order_no = @ordno
	AND		order_ext = @ordext

	IF (@@ERROR <> 0)  
	BEGIN  
		RETURN @@error   
	END  
	-- v12.8 End
   
--INSERT ord_rep (order_no, order_ext, salesperson,   
--  sales_comm, note,  percent_flag,  
--  exclusive_flag, split_flag, display_line )  
-- SELECT  order_no, @ext,  salesperson,   
--  sales_comm, note,  percent_flag,  
--  exclusive_flag, split_flag, display_line   
-- FROM ord_rep  
-- WHERE order_no=@ordno and order_ext=@ordext   
-- if @@error != 0  
--  begin  
--  return @@error  
--  end  
-- v12.6 End
  
--#9 Start  
IF EXISTS (SELECT 1 FROM icv_cctype WHERE payment_code = (SELECT payment_code FROM ord_payment WHERE order_no=@ordno and order_ext=@ordext))  
BEGIN  
   
  
  
 SELECT @doc_ctrl_num = CONVERT(CHAR(8),GETDATE(),112) + SUBSTRING(CONVERT(CHAR(8),GETDATE(),8),1,2) + SUBSTRING(CONVERT(CHAR(8),GETDATE(),8),4,2) + SUBSTRING(CONVERT(CHAR(8),GETDATE(),8),7,2)  
 INSERT ord_payment (order_no, order_ext, seq_no,   
   trx_desc, date_doc, payment_code,  
   amt_payment, prompt1_inp, prompt2_inp,  
   prompt3_inp, prompt4_inp, amt_disc_taken,  
   cash_acct_code,   doc_ctrl_num )  
  SELECT  order_no, @ext,  1,   
   trx_desc, date_doc, payment_code,  
   0, prompt1_inp, prompt2_inp,  
   prompt3_inp, '', 0,  
   cash_acct_code,   @doc_ctrl_num  
  FROM ord_payment  
  WHERE order_no=@ordno and order_ext=@ordext   
  if @@error != 0  
   begin  
   return @@error  
   end  
  
 exec adm_cca_copyaccts_sp @ordno, @ext, @ordno, @ordext, 0  
END  
--#9 End  
  
  
SELECT @xlp=isnull((select min(line_no) from ord_list where order_no=@ordno and  
  order_ext=@ordext and shipped < ordered and  
  (back_ord_flag='0' OR back_ord_flag is null)),0)  
while @xlp > 0  
BEGIN  
   
 IF NOT exists (select * from ord_list where order_no=@ordno and order_ext=@ordext  
  and line_no=@xlp and location like 'DROP%' and printed='V' and shipped !=0)    
 BEGIN  
   
	SELECT @qty=(ordered - shipped), @ptype = part_type,     -- mls 3/26/01 SCR 20667  
	@shipped = shipped         -- mls 3/26/01 SCR 20667  
	FROM ord_list  
	WHERE order_no=@ordno and order_ext=@ordext and line_no=@xlp  

	if @ptype = 'J'          -- mls 3/26/01  SCR 20667 start  
	begin          
		SELECT @prod_no = convert(int,part_no)        
		FROM ord_list  
		WHERE order_no=@ordno and order_ext=@ordext and line_no=@xlp  
		select @new_prod = @prod_no          
	 
		if exists (select 1 from config (nolock) where flag = 'BACKORDER_JOBS'  
			and substring(lower(value_str),1,1) = 'y')   
		begin   
			if @shipped != 0           
			begin  
				select @prod_ext = isnull((select max(prod_ext) from produce_all  
				where prod_no = @prod_no),0)  
				exec @rc = fs_create_backorder_job @prod_no, @prod_ext, @qty, @new_prod OUT  
				if @rc <> 1  
					return 991202  
			end   
		end            
	end           -- mls 3/26/01  SCR 20667 end  

	-- START v11.1
	SET @is_discadj = 0
	IF EXISTS (SELECT 1 FROM dbo.CVO_discount_adjustment_audit (NOLOCK) WHERE order_no = @ordno AND ext = @ordext AND line_no = @xlp AND [status] >= 'R')
	BEGIN
		SET @is_discadj = 1

		SELECT TOP 1
			@std_price = new_price,
			@promo_disc = new_discount
		FROM 
			dbo.CVO_discount_adjustment_audit (NOLOCK) 
		WHERE 
			order_no = @ordno 
			AND ext = @ordext 
			AND line_no = @xlp 
			AND [status] >= 'R'
	END


	INSERT ord_list(order_no,order_ext,  line_no,  location,  
	part_no, description,  time_entered,  ordered,  
	shipped, price,   price_type,  note,  
	status,  cost,   who_entered,  sales_comm,  
	temp_price, temp_type,  cr_ordered,  cr_shipped,  
	discount, uom,   conv_factor,  void,  
	void_who, void_date,  std_cost,  cubic_feet,  
	printed, lb_tracking,  labor,   direct_dolrs,  
	ovhd_dolrs, util_dolrs,  taxable,  weight_ea,  
	qc_flag, reason_code,  qc_no,   rejected,  
	part_type, orig_part_no,  back_ord_flag,  gl_rev_acct,  
	total_tax, tax_code,  curr_price,  oper_price,  
	display_line, std_direct_dolrs, std_ovhd_dolrs,  std_util_dolrs,  
	reference_code, ship_to, service_agreement_flag, --skk 05/16/00 mshipto ,ssb 06/26/00 23195                       
				agreement_id,   create_po_flag,         load_group_no,          return_code, -- mls 10/2/03 SCR 31956  
				user_count, cust_po)  
	SELECT order_no, @ext,   line_no,  location,  
	case part_type when 'J' then convert(varchar(30),@new_prod) else part_no end, -- mls 3/26/01  SCR 20667  
	description,  time_entered,  @qty,  
	-- START v11.1
	0,  CASE @is_discadj WHEN 1 THEN @std_price ELSE price END,   price_type,  note,  
	--0,  price,   price_type,  note,  
	'N',  cost,   who_entered,  sales_comm,  
	CASE @is_discadj WHEN 1 THEN @std_price ELSE temp_price END, temp_type,  cr_ordered,  cr_shipped,  
	--temp_price, temp_type,  cr_ordered,  cr_shipped,  
	CASE @is_discadj WHEN 1 THEN @promo_disc ELSE discount END, uom,   conv_factor,  void,  
	--discount, uom,   conv_factor,  void,  
	void_who, void_date,  std_cost,  cubic_feet,  
	printed, lb_tracking,  labor,   direct_dolrs,  
	ovhd_dolrs, util_dolrs,  taxable,  weight_ea,  
	qc_flag, reason_code,  qc_no,   rejected,  
	part_type, orig_part_no,  back_ord_flag,  gl_rev_acct,  
	0,  tax_code,  CASE @is_discadj WHEN 1 THEN @std_price ELSE curr_price END , CASE @is_discadj WHEN 1 THEN @std_price ELSE oper_price END,  
	--0,  tax_code,  curr_price,  oper_price,  
	-- END v11.1
	display_line, std_direct_dolrs, std_ovhd_dolrs,  std_util_dolrs,  
	reference_code, ship_to, service_agreement_flag, --skk 05/16/00 mshipto, ssb 06/26/00 23195                  
				agreement_id,   create_po_flag,         0,             return_code, -- mls 10/2/03 SCR 31956  
				user_count,  
	cust_po  
	FROM ord_list  
	WHERE order_no=@ordno and order_ext=@ordext and line_no=@xlp  
	if @@error != 0  
	begin  
	return @@error  
	end  

	/*START: 03/31/2010, AMENDEZ, 68668-001-MOD Promotions modification*/  
	INSERT INTO CVO_ord_list (  
	order_no,  order_ext,  line_no, add_case,  
	add_pattern, from_line_no, is_case, is_pattern,  
	add_polarized, is_polarized, is_pop_gif,
	is_amt_disc, amt_disc, is_customized, promo_item, list_price, orig_list_price, -- v1.3 v10.3
	free_frame, upsell_flag -- v10.4 v12.5
	)  
	SELECT  order_no,  @ext,   line_no, add_case,  
	--    add_pattern, from_line_no, is_case, is_pattern,  -- v10.0
	add_pattern, from_line_no, is_case, is_pattern,  -- v10.3
	add_polarized, is_polarized, is_pop_gif,
	-- START v11.1
	is_amt_disc, CASE @is_discadj WHEN 1 THEN (CASE @promo_disc WHEN 0 THEN 0 ELSE @std_price * (@promo_disc/100) END ) ELSE amt_disc END, is_customized, promo_item, list_price, orig_list_price, -- v1.3  v10.3
	--is_amt_disc, amt_disc, is_customized, promo_item, list_price, orig_list_price, -- v1.3  v10.3
	-- END v11.1
	free_frame, -- v10.4
	upsell_flag -- v12.5
	FROM CVO_ord_list  
	WHERE order_no=@ordno and order_ext=@ordext and line_no=@xlp  
	if @@error != 0  
	begin  
	return @@error  
	end  

	/*END: 03/31/2010, AMENDEZ, 68668-001-MOD Promotions modification*/  

	INSERT ord_list_kit( order_no, order_ext, line_no,  
	location, part_no, part_type,  
	ordered, shipped,  status,  
	lb_tracking, cr_ordered, cr_shipped,  
	uom,  conv_factor, cost,  
	labor,  direct_dolrs, ovhd_dolrs,  

	util_dolrs, note,  qty_per,  
	qc_flag, qc_no,  description )  -- mls 9/6/00 SCR 24091  
	SELECT order_no, @ext,  line_no,  
	location, part_no, part_type,  
	@qty,  0,  'N',  
	lb_tracking, cr_ordered, cr_shipped,  
	uom,  conv_factor, cost,  
	labor,  direct_dolrs, ovhd_dolrs,  
	util_dolrs, note,  qty_per,  
	qc_flag, qc_no,  description   -- mls 9/6/00 SCR 24091  
	FROM ord_list_kit  

	WHERE order_no=@ordno and order_ext=@ordext and line_no=@xlp  
	if @@error != 0  
	begin  
	return @@error  
	end  

	-- v1.3 Deal with custom frame breaks  
	INSERT INTO cvo_ord_list_kit (  
	order_no,  order_ext,  line_no, location,
	part_no, replaced, new1, part_no_original)  
	SELECT  order_no,  @ext,  line_no, location,
	part_no, replaced, new1, part_no_original  
	FROM cvo_ord_list_kit  
	WHERE order_no=@ordno and order_ext=@ordext and line_no=@xlp  
	if @@error != 0  
	begin  
	return @@error  
	end  

	END   

	SELECT @xlp=isnull((select min(line_no) from ord_list where order_no=@ordno and  
	order_ext=@ordext and shipped < ordered and  
	(back_ord_flag='0' OR back_ord_flag is null) and line_no > @xlp),0)  
END   
  
IF (select count(*) from ord_list where order_no=@ordno and order_ext=@ext) = 0  
 BEGIN  
  DELETE orders_all WHERE order_no=@ordno and ext=@ext  
  if @@error != 0  
   begin  
   return @@error  
   end  
 END  
ELSE  
  
 BEGIN  
 UPDATE orders_all set status='N' WHERE order_no=@ordno and ext=@ext  
 if @@error != 0  
  begin  
  return @@error  
  end  
 END  


-- v10.9 Start
IF NOT EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN inv_master b (NOLOCK) ON a.part_no = b.part_no
				WHERE a.order_no = @ordno AND a.order_ext = @ext AND b.type_code IN ('FRAME','SUN'))
BEGIN
	UPDATE	orders_all
	SET		tot_ord_freight = 0,
			freight_allow_type = 'FRTOVRID',
			routing = 'UPSGR'
	WHERE	order_no = @ordno
	AND		ext = @ext
END
-- v10.9 End

-- v11.0 Start
IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @ordno AND ext = @ext AND LEFT(user_category,2) = 'RX')
BEGIN		
	exec fs_calculate_oetax_wrap @ordno, @ext, 0, 1  
END
-- v11.0 End

 exec fs_updordtots @ordno, @ext  

-- v2.1 Copy the original address to the backorder as it has already been validated. Can not change the validation routine as it calls the external tax system
 UPDATE	a 
 SET	ship_to_name = b.ship_to_name,
		ship_to_add_1 = b.ship_to_add_1,
		ship_to_add_2 = b.ship_to_add_2,
		ship_to_add_3 = b.ship_to_add_3,
		ship_to_add_4 = b.ship_to_add_4,
		ship_to_add_5 = b.ship_to_add_5,
		ship_to_city = b.ship_to_city,
		ship_to_state = b.ship_to_state,
		ship_to_zip = b.ship_to_zip,
		ship_to_country_cd = b.ship_to_country_cd,
		sold_to_addr1 = b.sold_to_addr1,
		sold_to_addr2 = b.sold_to_addr2,
		sold_to_addr3 = b.sold_to_addr3,
		sold_to_addr4 = b.sold_to_addr4,
		sold_to_addr5 = b.sold_to_addr5,
		sold_to_addr6 = b.sold_to_addr6,
		sold_to_city = b.sold_to_city,
		sold_to_state = b.sold_to_state,
		sold_to_zip = b.sold_to_zip,
		sold_to_country_cd = b.sold_to_country_cd
FROM	orders_all a
JOIN	orders_all b (NOLOCK)
ON		a.order_no = b.order_no
WHERE	b.ext = 0
AND		a.order_no = @ordno 
AND		a.ext = @ext  


-- v10.0
-- Call soft allocation backorder routine
-- v10.6 Start

IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @ordno AND order_ext = @ext AND from_line_no <> 0)
BEGIN
	EXEC cvo_soft_allocation_order_conversion_sp @ordno, @ext
	UPDATE cvo_soft_alloc_hdr SET bo_hold = 1 WHERE order_no = @ordno AND order_ext = @ext and status = 0
END
ELSE
BEGIN
	EXEC cvo_soft_alloc_backorder_sp 0, @ordno, @ordext, @ext
END

-- v10.6 End

-- v10.8 Start
DELETE	cvo_ord_list_fc
WHERE	order_no = @ordno
AND		order_ext = @ext

INSERT	dbo.cvo_ord_list_fc (order_no, order_ext, line_no, part_no, case_part, pattern_part, polarized_part) -- v12.0
SELECT	order_no, @ext, line_no, part_no, case_part, pattern_part, polarized_part -- v12.0
FROM	cvo_ord_list_fc (NOLOCK)
WHERE	order_no = @ordno
AND		order_ext = @ordext	
ORDER BY order_no, order_ext, line_no


-- v10.8 End

-- START v11.3
-- Get promo
SELECT
	@promo_id = promo_id,
	@promo_level = promo_level
FROM
	dbo.cvo_orders_all (NOLOCK)
WHERE
	order_no = @ordno
	AND ext = @ext

-- Check it's a drawdown promo
IF EXISTS (SELECT 1 FROM dbo.cvo_promotions (NOLOCK) WHERE promo_id = @promo_id AND promo_level = @promo_level AND ISNULL(drawdown_promo,0) = 1)
BEGIN
	EXEC CVO_apply_debit_promo_to_backorder_sp @ordno, @ext, @promo_id, @promo_level, @ordext		
END
-- END v11.3
  
return 1
GO
GRANT EXECUTE ON  [dbo].[fs_create_backorder] TO [public]
GO
