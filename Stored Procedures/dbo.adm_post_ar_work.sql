SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 16/05/2011 - Call new invoice splitting routine
-- v1.1 CB 20/02/2012 - Add credits to the splitting routine call so the due dates are updated
-- v1.3 CB 19/03/2012 - Ignore the applying of sales orders to credits as this causes issues with split invoices
-- v1.4 CB 14/06/2012 - Add coop processing to routine so as to include credits
-- v1.5 CB 03/10/2012 - Soft Allocation
-- v1.6 CB 21/01/2013 - Issue #1116 - Rounding issue on posting
-- v1.7 CB 16/07/2013 - Issue #927 - Buying Group Switching
-- v1.8 CB 12/02/2014 - Issue 1349 - RA# - Copy ra1 field for credit returns into the cust po field
-- v1.9 CB 15/07/2014 - Fix issue with discount rounding
CREATE PROCEDURE [dbo].[adm_post_ar_work] 
@user_id int,			@user varchar(30),			@post_batch_id int,
@process_ctrl_num varchar(16) ,	@trx_type smallint,			@AR_INCL_NON_TAX char(1) = NULL OUT,
@printed char(1) = NULL OUT,	@home_currency varchar(8) = NULL OUT, 	@oper_currency varchar(8) = NULL OUT,
@company_id int = NULL OUT,	@err int OUT ,				@num_in_batch int OUT
AS 
set nocount on
----------------------------------------------------------------------------------------------------------------------------------------------

DECLARE  
@disc_prc_flag smallint,         @exclusive_flag smallint,         @module_id smallint,
@next_serial_id smallint,        @percent_flag smallint,	   @printed_flag smallint,
@split_flag smallint,	         @date_applied int,	           @result int,
@val_mode smallint,	         @apply_to_num varchar(16),        @oper_rate decimal(20,8),
@home_rate decimal(20,8),        @new_batch_code varchar(16),      @nat_cur_code varchar(8),
@rate_type_home varchar(8),      @rate_type_oper varchar(8),       @home_override_flag smallint,
@oper_override_flag smallint,	 @divide_flag_h smallint,   	   @divide_flag_o smallint,
@tcn_num int, 			 @first_tcn int, 	 	   @tcn_mask varchar(16), 
@error int,			 @ewerror_cnt int,		   @last_row int,
@err_msg varchar(255)

-- v1.4
DECLARE	@id			int,
		@last_id	int,
		@order_no	int,
		@order_ext	int
----------------------------------------------------------------------------------------------------------------------------------------------

-- Get system Default Values 
SELECT @module_id  = 2001

if @company_id is null
  SELECT @company_id = company_id FROM arco (nolock)

if @AR_INCL_NON_TAX is NULL
begin
  SELECT @AR_INCL_NON_TAX = isnull((select upper(substring(value_str,1,1)) 	
    FROM config (nolock) WHERE flag = 'AR_INCL_NON_TAX'),'N')				-- mls 12/22/00 SCR 23738

  SELECT @printed = isnull((select upper(value_str) FROM config (nolock) WHERE flag = 'PLT_PRINT_INV'),'')

  SELECT @home_currency = home_currency, @oper_currency = oper_currency FROM glco (nolock)	
end

delete from #arterm
delete from #arinpchg
delete from #arinpage
delete from #arinptax
delete from #arinpcom
delete from #arinptmp
delete from #arinpcdt
delete from #t1
delete from #post_orders
delete from #arinbat
delete from #arbatsum
delete from #arbatnum
delete from #aritemp

----------------------------------------------------------------------------------------------------------------------------------------------
select @err = 1

INSERT #post_orders
(       order_no, 		ext,			tmp_ctrl_num,
	trx_ctrl_num,		doc_ctrl_num,		doc_desc,
	apply_to_num,		apply_trx_type,		order_ctrl_num,
	batch_code, 		trx_type,		date_entered,
	date_applied,		date_doc,		date_shipped,
	date_required,		date_due,		date_aging,
	customer_code, 		ship_to_code, 		salesperson_code,
	territory_code,		comment_code,		fob_code,
	freight_code,		terms_code,		fin_chg_code,
	price_code,		dest_zone_code,		posting_code,
	recurring_flag,		recurring_code,		tax_code,
	cust_po_num,		total_weight, 		amt_gross,
	amt_freight, 		amt_tax, 		amt_discount,
	amt_net,		amt_paid,		amt_due,				
	amt_cost,		amt_profit,		next_serial_id,
	printed_flag,		posted_flag,		hold_flag,
	hold_desc,		user_id,		customer_addr1,
	customer_addr2,		customer_addr3,		customer_addr4,
	customer_addr5,		customer_addr6,		ship_to_addr1,
	ship_to_addr2,		ship_to_addr3,		ship_to_addr4,
	ship_to_addr5,		ship_to_addr6,		attention_name,
	attention_phone,	amt_rem_rev,		amt_rem_tax,
	date_recurring,		location_code,		process_group_num,
	trx_state,		mark_flag,		amt_discount_taken,
	amt_write_off_given,	source_trx_ctrl_num,	source_trx_type,
	nat_cur_code,		rate_type_home,		rate_type_oper,
	rate_home,		rate_oper,		edit_list_flag, 
	amt_tax_included, 	nat_precision, 		home_override_flag, 
	oper_override_flag,	cr_invoice_no,		line_item_cnt,
	organization_id,
	customer_city, customer_state, customer_postal_code, customer_country_code,
	ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code,
	writeoff_code)
select	
  o.order_no,  o.ext,
  convert(varchar(11),o.order_no) + '-' + convert(varchar(4),o.ext),	-- tmp_ctrl_num 
  ot.trx_ctrl_num,  oi.doc_ctrl_num, 	
  CASE type WHEN 'I' THEN 'SO:' ELSE 'CM:' END, -- doc_desc
  '', 0, (convert(varchar(10),o.order_no) + '-' + convert(varchar(10),o.ext)),  
  '', CASE type WHEN 'I' THEN 2031 ELSE 2032 END, 			
  datediff(day,'01/01/1900',getdate()) + 693596, 
  datediff(day,'01/01/1900',date_shipped) + 693596,
  datediff(day,'01/01/1900',date_shipped) + 693596,
  datediff(day,'01/01/1900',date_shipped) + 693596, -- date_shipped,
  datediff(day,'01/01/1900',req_ship_date) + 693596, -- date_required,		
  0, -- date_due,			
  datediff(day,'01/01/1900',date_shipped) + 693596,
  cust_code,  isnull(ship_to,''), isnull(salesperson,''), 
  isnull(ship_to_region,''),  isnull(a.inv_comment_code,''),  fob,					-- mls 3/8/06 SCR 35922
  '',  terms,  a.fin_chg_code, isnull(a.price_code,''), 				-- mls 4/20/06 SCR 36110
											-- mls 11/19/03 SCR 31069	
  isnull(o.dest_zone_code,' '), o.posting_code, 
  CASE type WHEN 'I' THEN 0 ELSE 1 END, '', tax_id, 
  isnull(cust_po,' '), 0, gross_sales, freight, total_tax, 
  total_discount, (gross_sales + freight + total_tax) - total_discount,
  0.0, 
  case type when 'I' then (gross_sales + freight + total_tax) - total_discount
  else 0 end,
  0, 0, 0,  CASE @printed WHEN 'A' THEN 1 ELSE 0 END,
  0, 0, '', @user_id, isnull(a.addr1,' '), isnull(a.addr2,' '), 
  isnull(a.addr3,' '), isnull(a.addr4,' '), isnull(a.addr5,' '), 
  isnull(a.addr6,' '), isnull(o.ship_to_name,' '), 
  isnull(o.ship_to_add_1,' '), isnull(o.ship_to_add_2,' '), 
  isnull(o.ship_to_add_3,' '), isnull(o.ship_to_add_4,' '), 
  isnull(o.ship_to_add_5,' '), isnull(a.attention_name,' '),
  isnull(a.attention_phone,' '), 0, 0, 0, substring(location,1,10), 
  process_ctrl_num, 0, 0, 0.0, 0.0, '', 0, curr_key, 
  o.rate_type_home, o.rate_type_oper, o.curr_factor, 
  o.oper_factor, 0, isnull(tot_tax_incl,0), isnull(gc.curr_precision,2),  
  isnull(hcr.override_flag,0), isnull(ocr.override_flag,0),
  o.cr_invoice_no, 0, -- line_item_cnt
  o.organization_id,
  a.city, a.state, a.postal_code, a.country_code,
  o.ship_to_city, o.ship_to_state, o.ship_to_zip, o.ship_to_country_cd,
  case when o.type = 'I' then '' else a.writeoff_code end
from #orders ot
join orders_all o on o.order_no = ot.order_no and o.ext = ot.ext and o.status = 'S'
left outer join adm_cust_all a (nolock) on o.cust_code  = a.customer_code
left outer join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
left outer join glcurr_vw gc (nolock) on gc.currency_code = o.curr_key
left outer join glcurate_vw hcr (nolock) on hcr.from_currency = o.curr_key 
  AND hcr.to_currency = @home_currency AND hcr.rate_type = o.rate_type_home 
  AND hcr.inactive_flag = 0
left outer join glcurate_vw ocr (nolock) on ocr.from_currency = o.curr_key 
  AND ocr.to_currency = @oper_currency AND ocr.rate_type = o.rate_type_oper 
  AND ocr.inactive_flag = 0

IF ( @error != 0 )
BEGIN
  select @err = 65
  RETURN
END     

-- v1.8 Start
UPDATE	a
SET		cust_po_num = b.ra1
FROM	#post_orders a
JOIN	cvo_orders_all b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.ext = b.ext
WHERE	a.trx_type = 2032
AND		b.ra1 IS NOT NULL
-- v1.8 End

-- v1.7 Start
UPDATE	a
SET		buying_group = dbo.f_cvo_get_buying_group(b.cust_code,b.date_shipped)
FROM	cvo_orders_all a
JOIN	orders_all b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.ext = b.ext
JOIN	#orders ot
ON		a.order_no = ot.order_no
AND		a.ext = ot.ext
WHERE	RIGHT(b.user_category,2) <> 'RB'
-- v1.7 End

-- v1.3 Start
--if @trx_type = 2032
--begin
--  update po
--  set apply_to_num = oi.doc_ctrl_num, 
--    apply_trx_type = 2031
--  from #post_orders po, orders_all o (nolock), orders_invoice oi (nolock)
--  where po.trx_type = 2032 		and po.cr_invoice_no != 0 
--    and o.invoice_no = po.cr_invoice_no and o.order_no = oi.order_no
--    and o.ext = oi.order_ext 		and o.type = 'I'
--
--  IF ( @@error != 0 )
--  BEGIN
--    select @err = 72
--    RETURN
--  END     
--END
-- v1.3 End

/*START: 04/19/2010, AMENDEZ, 68668-001-MOD Promotions modification*/
INSERT #arinpcdt 
( trx_ctrl_num,		doc_ctrl_num,	sequence_id,	trx_type,	location_code,
  item_code,		bulk_flag,	date_entered,	line_desc, 	qty_ordered,
  qty_shipped,		unit_code,	unit_price,	unit_cost,	weight,
  serial_id,		tax_code,	gl_rev_acct,	disc_prc_flag,	discount_amt,
  commission_flag,	rma_num,	return_code,	qty_returned,	qty_prev_returned,
  new_gl_rev_acct,	iv_post_flag,	oe_orig_flag,	trx_state,	mark_flag,
  discount_prc,		extended_price,	calc_tax,	reference_code,	cust_po,
  org_id)
select
  o.trx_ctrl_num,	o.doc_ctrl_num,	l.line_no,	o.trx_type,	substring(l.location,1,10),
  l.part_no,	0,	o.date_entered,	
  case when isnull(l.contract,'') != '' then
    Substring( convert(varchar(60),isnull(l.description,'')), 1, ( 60 - ( len( isnull(l.contract,'') ) + 11 ) )) + ' Contract: ' + l.contract
    else convert(varchar(60),isnull(l.description,''))
  end,
  case o.trx_type when 2031 then l.ordered else 0 end,
  case o.trx_type when 2031 then l.shipped else 0 end,
  l.uom,	ROUND(l.curr_price,o.nat_precision),	(l.cost + l.direct_dolrs + l.ovhd_dolrs + l.util_dolrs), -- v1.6
--  v1.6 l.uom,	l.curr_price,	(l.cost + l.direct_dolrs + l.ovhd_dolrs + l.util_dolrs), 
  isnull(weight_ea * (shipped + cr_shipped),0), 0,l.tax_code,	l.gl_rev_acct,	
  CASE co.is_amt_disc   /*AMENDEZ: disc_prc_flag*/
	WHEN 'Y' THEN 0		/*AMENDEZ*/
	ELSE 1 END,				/*AMENDEZ*/
  CASE o.trx_type
    WHEN 2031 THEN 
-- v1.9 Start
		CASE co.is_amt_disc   /*AMENDEZ: discount_amt*/
			WHEN 'Y' THEN (l.shipped * ROUND(amt_disc, o.nat_precision))		/*AMENDEZ*/
			ELSE ( (l.shipped  * ROUND((l.curr_price * (l.discount / 100.00)),o.nat_precision))) END	-- mls 10/16/00 SCR 24556 /*AMENDEZ*/
    ELSE round(( (l.cr_shipped * l.curr_price) *  (l.discount / 100.00)),o.nat_precision)		-- mls 10/16/00 SCR 24556
--		CASE co.is_amt_disc   /*AMENDEZ: discount_amt*/
--			WHEN 'Y' THEN round((l.shipped * amt_disc), o.nat_precision)		/*AMENDEZ*/
--			ELSE round(( (l.shipped  * l.curr_price) * (l.discount / 100.00)),o.nat_precision) END	-- mls 10/16/00 SCR 24556 /*AMENDEZ*/
--    ELSE round(( (l.cr_shipped * l.curr_price) *  (l.discount / 100.00)),o.nat_precision)		-- mls 10/16/00 SCR 24556
-- v1.9 End
  END,
  0,	'',	
  case o.trx_type when 2031 then '' else isnull(l.return_code,'') end,				-- mls 5/18/05 SCR 34563
  case o.trx_type when 2031 then 0 else l.cr_shipped end,
  0,	'',	0,	1, 	0,	0,	
  CASE co.is_amt_disc   /*AMENDEZ: discount_prc*/
	WHEN 'Y' THEN 0		/*AMENDEZ*/
	ELSE l.discount END,	/*AMENDEZ*/	
  CASE o.trx_type
    WHEN 2031 THEN 
-- v1.9 Start
			CASE co.is_amt_disc   /*AMENDEZ*/
			WHEN 'Y' THEN	round(l.shipped * l.curr_price,o.nat_precision) -  /*AMENDEZ*/
							(l.shipped * ROUND(amt_disc,o.nat_precision))		/*AMENDEZ*/
			ELSE	round(l.shipped * l.curr_price,o.nat_precision) -   
					( (l.shipped * ROUND((l.curr_price) * (l.discount / 100.00),o.nat_precision))) END			-- mls 10/16/00 SCR 24556
    ELSE round(l.cr_shipped * l.curr_price,o.nat_precision) -  
      round(( (l.cr_shipped * l.curr_price) * (l.discount / 100.00)),o.nat_precision) 		-- mls 10/27/00 SCR 24556

--			CASE co.is_amt_disc   /*AMENDEZ*/
--			WHEN 'Y' THEN	round(l.shipped * l.curr_price,o.nat_precision) -  /*AMENDEZ*/
--							round((l.shipped * amt_disc),o.nat_precision)		/*AMENDEZ*/
--			ELSE	round(l.shipped * l.curr_price,o.nat_precision) -   
--					round(( (l.shipped * l.curr_price) * (l.discount / 100.00)),o.nat_precision) END			-- mls 10/16/00 SCR 24556
--  ELSE round(l.cr_shipped * l.curr_price,o.nat_precision) -  
--      round(( (l.cr_shipped * l.curr_price) * (l.discount / 100.00)),o.nat_precision) 		-- mls 10/27/00 SCR 24556
-- v1.9 End
  END,
  l.total_tax, isnull(l.reference_code,''), isnull(l.cust_po,o.cust_po_num),				-- DJPB REV 11
  l.organization_id
FROM  #post_orders o
	INNER JOIN ord_list l (nolock) ON o.order_no = l.order_no AND o.ext = l.order_ext
	LEFT JOIN CVO_ord_list co (nolock)ON l.order_no = co.order_no AND l.order_ext = co.order_ext AND l.line_no = co.line_no
WHERE  (l.shipped > 0 or l.cr_shipped > 0) 


/*
INSERT #arinpcdt 
( trx_ctrl_num,		doc_ctrl_num,	sequence_id,	trx_type,	location_code,
  item_code,		bulk_flag,	date_entered,	line_desc, 	qty_ordered,
  qty_shipped,		unit_code,	unit_price,	unit_cost,	weight,
  serial_id,		tax_code,	gl_rev_acct,	disc_prc_flag,	discount_amt,
  commission_flag,	rma_num,	return_code,	qty_returned,	qty_prev_returned,
  new_gl_rev_acct,	iv_post_flag,	oe_orig_flag,	trx_state,	mark_flag,
  discount_prc,		extended_price,	calc_tax,	reference_code,	cust_po,
  org_id)
select
  o.trx_ctrl_num,	o.doc_ctrl_num,	l.line_no,	o.trx_type,	substring(l.location,1,10),
  l.part_no,	0,	o.date_entered,	
  case when isnull(l.contract,'') != '' then
    Substring( convert(varchar(60),isnull(l.description,'')), 1, ( 60 - ( len( isnull(l.contract,'') ) + 11 ) )) + ' Contract: ' + l.contract
    else convert(varchar(60),isnull(l.description,''))
  end,
  case o.trx_type when 2031 then l.ordered else 0 end,
  case o.trx_type when 2031 then l.shipped else 0 end,
  l.uom,	l.curr_price,	(l.cost + l.direct_dolrs + l.ovhd_dolrs + l.util_dolrs), 
  isnull(weight_ea * (shipped + cr_shipped),0), 0,l.tax_code,	l.gl_rev_acct,	1,	
  CASE o.trx_type
    WHEN 2031 THEN round(( (l.shipped  * l.curr_price) * (l.discount / 100.00)),o.nat_precision)	-- mls 10/16/00 SCR 24556
    ELSE round(( (l.cr_shipped * l.curr_price) *  (l.discount / 100.00)),o.nat_precision)		-- mls 10/16/00 SCR 24556
  END,
  0,	'',	
  case o.trx_type when 2031 then '' else isnull(l.return_code,'') end,				-- mls 5/18/05 SCR 34563
  case o.trx_type when 2031 then 0 else l.cr_shipped end,
  0,	'',	0,	1, 	0,	0,	l.discount,	
  CASE o.trx_type
    WHEN 2031 THEN round(l.shipped * l.curr_price,o.nat_precision) - 
      round(( (l.shipped * l.curr_price) * (l.discount / 100.00)),o.nat_precision)			-- mls 10/16/00 SCR 24556
    ELSE round(l.cr_shipped * l.curr_price,o.nat_precision) -  
      round(( (l.cr_shipped * l.curr_price) * (l.discount / 100.00)),o.nat_precision) 		-- mls 10/27/00 SCR 24556
  END,
  l.total_tax, isnull(l.reference_code,''), isnull(l.cust_po,o.cust_po_num),				-- DJPB REV 11
  l.organization_id
FROM  #post_orders o, ord_list l (nolock)
WHERE o.order_no = l.order_no and o.ext = l.order_ext and (l.shipped > 0 or l.cr_shipped > 0) 
*/
/*END: 04/19/2010, AMENDEZ, 68668-001-MOD Promotions modification*/

IF ( @@error != 0 )
BEGIN
  select @err = 70
  RETURN
END     

  
update po
set total_weight = l.weight,
    amt_cost = l.cost,
    line_item_cnt = l.cnt
from #post_orders po,
(SELECT trx_ctrl_num, count(*), sum(weight), sum(unit_cost * (qty_shipped + qty_returned))
  FROM #arinpcdt 
  group by trx_ctrl_num) as l ( trx_ctrl_num, cnt, weight, cost)
where po.trx_ctrl_num = l.trx_ctrl_num

IF ( @@error != 0 )
BEGIN
  select @err = 74
  RETURN
END     

delete from #post_orders where line_item_cnt = 0

select @num_in_batch = (select count(*) from #post_orders)
if @num_in_batch = 0
begin
  select @err = 1
  return
end

DECLARE currency_cursor CURSOR LOCAL STATIC FOR
SELECT distinct date_applied,  nat_cur_code, rate_type_home,  rate_type_oper,
  home_override_flag, oper_override_flag, trx_type, apply_to_num
from #post_orders
where (home_override_flag = 0 and not (trx_type = 2032 and apply_to_num is not NULL)  and nat_cur_code != @home_currency)
   or (oper_override_flag = 0 and not (trx_type = 2032 and apply_to_num is not NULL)  and nat_cur_code != @oper_currency)

OPEN currency_cursor

if @@cursor_rows > 0
begin
  FETCH NEXT FROM currency_cursor into
    @date_applied, @nat_cur_code, @rate_type_home, @rate_type_oper, @home_override_flag,
    @oper_override_flag, @trx_type, @apply_to_num

  While @@FETCH_STATUS = 0
  begin
    select @home_rate = 1, @oper_rate = 1
    IF(@home_override_flag = 0) and not (@trx_type = 2032 and @apply_to_num is not null) and
      @home_currency != @nat_cur_code
    BEGIN
      EXEC @result = adm_mccurate_sp @date_applied, @nat_cur_code, @home_currency,		
        @rate_type_home, @home_rate OUTPUT, 0, @divide_flag_h	OUTPUT
		
      IF ( @result != 0 ) SELECT @home_rate = 0
    END

    IF(@oper_override_flag = 0) and not (@trx_type = 2032 and @apply_to_num is not null) and
      @oper_currency != @nat_cur_code
    BEGIN
      EXEC @result = adm_mccurate_sp @date_applied, @nat_cur_code, @oper_currency,		
        @rate_type_oper, @oper_rate OUTPUT, 0, @divide_flag_o OUTPUT
					
      IF ( @result != 0 ) SELECT @oper_rate = 0
    END

    Update #post_orders
    set rate_home = @home_rate,
      rate_oper = @oper_rate
    where date_applied = @date_applied and nat_cur_code = @nat_cur_code and
      rate_type_home = @rate_type_home and rate_type_oper = @rate_type_oper

    FETCH NEXT FROM currency_cursor into
      @date_applied, @nat_cur_code, @rate_type_home, @rate_type_oper, @home_override_flag,
      @oper_override_flag, @trx_type, @apply_to_num
  END -- while tmp_ctrl_num not null
end

close currency_cursor
DEALLOCATE currency_cursor

--Process Payment Record
INSERT #arinptmp (
  trx_ctrl_num,	doc_ctrl_num,	trx_desc,	date_doc,	customer_code,
  payment_code,	amt_payment,	prompt1_inp,	prompt2_inp,	prompt3_inp,
  prompt4_inp,	amt_disc_taken,	cash_acct_code	)
SELECT	
  i.trx_ctrl_num, o.doc_ctrl_num,	o.trx_desc, 	i.date_doc,	i.customer_code,
  o.payment_code, o.amt_payment,	prompt1_inp,	prompt2_inp,	prompt3_inp,
  prompt4_inp,	  o.amt_disc_taken,	isnull(c.account_code,'') 			-- mls 4/21/06 SCR 35623
FROM ord_payment o (nolock)
join arpymeth p (nolock) on o.payment_code = p.payment_code
join #post_orders i  on i.order_no = o.order_no and i.ext = o.order_ext
left outer join  glchart c (nolock) on c.account_code = dbo.IBAcctMask_fn(p.asset_acct_code,i.organization_id)

IF ( @@error != 0 )
begin
  select @err = 40
  return 
END

Update #post_orders
set amt_paid = o.amt_payment + o.amt_disc_taken,
  amt_due = 
  CASE 
    WHEN ((i.amt_gross + i.amt_freight + i.amt_tax) - i.amt_discount - (o.amt_payment + o.amt_disc_taken) < 0) 
      or i.trx_type = 2032 THEN 0
    ELSE (i.amt_gross + i.amt_freight + i.amt_tax) - i.amt_discount - (o.amt_payment + o.amt_disc_taken) 
  END
from #post_orders i, #arinptmp o
where i.trx_ctrl_num = o.trx_ctrl_num

insert into #arterm
select distinct date_doc, terms_code,0,0
from #post_orders

exec ARGetTermInfo_SP

Update #post_orders
set date_due = a.date_due
from #arterm a, #post_orders o
where a.terms_code = o.terms_code and a.date_doc = o.date_doc

INSERT #arinpchg ( 
	trx_ctrl_num,		doc_ctrl_num,		doc_desc,
    	apply_to_num,		apply_trx_type,		order_ctrl_num,
	batch_code, 		trx_type,		date_entered,
	date_applied,		date_doc,		date_shipped,
	date_required,		date_due,		date_aging,

 	customer_code, 		ship_to_code, 		salesperson_code,
	territory_code,		comment_code,		fob_code,
	freight_code,		terms_code,		fin_chg_code,
	price_code,		dest_zone_code,		posting_code,
 	recurring_flag,		recurring_code,		tax_code,
 	cust_po_num,		total_weight, 		amt_gross,
 	amt_freight, 		amt_tax, 		amt_discount,
 	amt_net,		amt_paid,		amt_due,				
	amt_cost,		amt_profit,		next_serial_id,
	printed_flag,		posted_flag,		hold_flag,
	hold_desc,		user_id,		customer_addr1,
	customer_addr2,		customer_addr3,		customer_addr4,
	customer_addr5,		customer_addr6,		ship_to_addr1,
	ship_to_addr2,		ship_to_addr3,		ship_to_addr4,
	ship_to_addr5,		ship_to_addr6,		attention_name,
	attention_phone,	amt_rem_rev,		amt_rem_tax,
	date_recurring,		location_code,		process_group_num,
	trx_state,		mark_flag,		amt_discount_taken,
	amt_write_off_given,	source_trx_ctrl_num,	source_trx_type,
	nat_cur_code,		rate_type_home,		rate_type_oper,
	rate_home,		rate_oper,		edit_list_flag, 
	amt_tax_included,	org_id,
	customer_city, customer_state, customer_postal_code, customer_country_code,
	ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code,
	writeoff_code)
select
	trx_ctrl_num,		doc_ctrl_num,		doc_desc + tmp_ctrl_num + ' ' + convert(varchar(10),user_id),
    	apply_to_num,		apply_trx_type,		order_ctrl_num,
	batch_code, 		trx_type,		date_entered,
	date_applied,		date_doc,		date_shipped,
	date_required,		date_due,		date_aging,
 	customer_code, 		ship_to_code, 		salesperson_code,
	territory_code,		comment_code,		fob_code,
	freight_code,		terms_code,		fin_chg_code,
	price_code,		dest_zone_code,		posting_code,
 	recurring_flag,		recurring_code,		tax_code,
 	cust_po_num,		total_weight, 		amt_gross,
 	amt_freight, 		amt_tax, 		amt_discount,
 	amt_net,		amt_paid,		amt_due,				
	amt_cost,		amt_profit,		next_serial_id,
	printed_flag,		posted_flag,		hold_flag,
	hold_desc,		user_id,		customer_addr1,
	customer_addr2,		customer_addr3,		customer_addr4,
	customer_addr5,		customer_addr6,		ship_to_addr1,
	ship_to_addr2,		ship_to_addr3,		ship_to_addr4,
	ship_to_addr5,		ship_to_addr6,		attention_name,
	attention_phone,	amt_rem_rev,		amt_rem_tax,
	date_recurring,		location_code,		process_group_num,
	trx_state,		mark_flag,		amt_discount_taken,
	amt_write_off_given,	source_trx_ctrl_num,	source_trx_type,
	nat_cur_code,		rate_type_home,		rate_type_oper,
	rate_home,		rate_oper,		edit_list_flag, 
	amt_tax_included,	organization_id,
	customer_city, customer_state, customer_postal_code, customer_country_code,
	ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code,
	writeoff_code
FROM #post_orders

IF ( @@error != 0 )
BEGIN
  select @err = 20 
  return 
END

  update r
  set amt_gross = o.amt_gross,
    amt_tax = o.amt_tax,
    doc_ctrl_num = o.doc_ctrl_num
  from gltcrecon r
  join #post_orders o on r.trx_ctrl_num = o.trx_ctrl_num and r.trx_type = o.trx_type

-- Call gltrxcra_sp  --Aging Record
if @trx_type = 2031
begin
  INSERT #arinpage (
	trx_ctrl_num,	sequence_id,	doc_ctrl_num,		apply_to_num,
	apply_trx_type,	trx_type,	date_applied,		date_due,
	date_aging,	customer_code,	salesperson_code,	territory_code,
	price_code,	amt_due,	trx_state,		mark_flag )
  SELECT
	trx_ctrl_num,	1,		doc_ctrl_num,		'',
	0,		trx_type,	date_applied,		date_due,
	date_aging,	customer_code,	salesperson_code,	territory_code,
	price_code,	amt_net,	2,			0 
  FROM #post_orders
  where trx_type = 2031							-- mls 3/29/02 SCR 28527

  IF ( @@error != 0 )
  BEGIN
    select @err = 30
    return 
  END
END

--Process Commissions
INSERT #arinpcom (
	trx_ctrl_num,	trx_type,	sequence_id,		salesperson_code,
	amt_commission,	percent_flag,	exclusive_flag,		split_flag,
	trx_state,	mark_flag )
SELECT  trx_ctrl_num,	trx_type,	display_line,		r.salesperson,
	r.sales_comm,	r.percent_flag,	r.exclusive_flag, 	r.split_flag,
	2,		0 
FROM #post_orders o, ord_rep r (nolock)
where o.order_no = r.order_no and o.ext = r.order_ext 

IF ( @@error != 0 )
BEGIN
  Select @err = 50
  RETURN
END
	
--Process Tax Records
INSERT #arinptax (	
	trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,
	amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	trx_state,
	mark_flag)
SELECT	trx_ctrl_num,	trx_type,	t.sequence_id,	t.tax_type_code,	
	t.amt_taxable,	t.amt_gross,	t.amt_tax,	t.amt_final_tax,	2,		 
	0
FROM #post_orders o, ord_list_tax t (nolock)
where o.order_no = t.order_no and o.ext = t.order_ext and (@AR_INCL_NON_TAX = 'Y' or amt_final_tax <> 0)

IF ( @@error != 0 )
BEGIN
  select @err = 60
  RETURN
END


--Populate validation files










while (0=0)
begin
  delete from #ewerror
  delete from #arvalchg
  delete from #arvalcdt
  delete from #arvalage
  delete from #arvaltax
  delete from #arvaltmp
  delete from #arvalrev

  EXEC @result = ARINSrcInsertValTables_SP

  IF @result !=  0
   BEGIN
     select @err = 70
     return 
   END

  if @trx_type =  2031  
  BEGIN
    EXEC @result = arinvedt_sp 1 

    IF @result !=  0
    BEGIN
      select @err = 80
      return  
    END

    DELETE from #ewerror where err_code = 20001  	
    DELETE from #ewerror where err_code = 20097  	-- mls 4/21/06 SCR 35623
    DELETE from #ewerror where err_code = 20070  		-- mls 4/21/06 SCR 35623

    select @ewerror_cnt = (select count(*) from #ewerror)
  END
  ELSE 
  BEGIN
    EXEC @result = arcmedt_sp 1 

    IF @result !=  0
    BEGIN
      select @err = 80
      return  
    END

    DELETE from #ewerror where err_code = 20201  
    DELETE from #ewerror where err_code = 20097  	-- mls 4/21/06 SCR 35623
    DELETE from #ewerror where err_code = 20070  		-- mls 4/21/06 SCR 35623

    select @ewerror_cnt = (select count(distinct trx_ctrl_num) from #ewerror)
  END

  IF @ewerror_cnt = 0
    BREAK

  select @err = 90

  insert adm_post_hist_batch_errors (
    post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
    infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
    source_ctrl_num ,	extra, 		order_no, 	order_ext)
  select 
    @post_batch_id, 	e.module_id, 	e.err_code, 	e.info1, 	e.info2 ,
    e.infoint, 		e.infofloat , 	e.flag1 , 	e.trx_ctrl_num,	e.sequence_id, 
    e.source_ctrl_num , e.extra, 	p.order_no, 	p.ext
  from #ewerror e, #post_orders p
  where e.trx_ctrl_num = p.trx_ctrl_num

  select @num_in_batch = @num_in_batch - @ewerror_cnt

  truncate table #orders
  insert #orders (order_no, ext, trx_ctrl_num, trx_type)
  select p.order_no, p.ext, p.trx_ctrl_num, p.trx_type
  from #ewerror e, #post_orders p
  where e.trx_ctrl_num = p.trx_ctrl_num 

  exec adm_post_ar_cancel_tax @err_msg out
  truncate table #orders

  if @num_in_batch <= 0
    return

  update o
  set process_ctrl_num = ''
  from #ewerror e, #post_orders p, orders_all o
  where e.trx_ctrl_num = p.trx_ctrl_num and o.order_no = p.order_no and o.ext = p.ext
 
  delete t
  from #ewerror e, #arinpcdt t
  where e.trx_ctrl_num = t.trx_ctrl_num

  delete t
  from #ewerror e, #arinptmp t
  where e.trx_ctrl_num = t.trx_ctrl_num

  delete t
  from #ewerror e, #arinpchg t
  where e.trx_ctrl_num = t.trx_ctrl_num

  delete t
  from #ewerror e, #arinpage t
  where e.trx_ctrl_num = t.trx_ctrl_num

  delete t
  from #ewerror e, #arinpcom t
  where e.trx_ctrl_num = t.trx_ctrl_num

  delete t
  from #ewerror e, #arinptax t
  where e.trx_ctrl_num = t.trx_ctrl_num
 
  delete t
  from #ewerror e, #post_orders t
  where e.trx_ctrl_num = t.trx_ctrl_num

  insert #orders (order_no, ext, trx_ctrl_num, trx_type)
  select p.order_no, p.ext, p.trx_ctrl_num, p.trx_type
  from #post_orders p

end -- while

BEGIN TRAN

-- v1.0 Start
if @trx_type IN (2031,2032) -- v1.2 
BEGIN
	EXEC @result = dbo.CVO_Installment_Invoice_Split_sp

	IF @result !=  0
	BEGIN
	  ROLLBACK TRAN
	  select @err = 95
	  return 
	END
END
-- v1.0 End

EXEC @result = arinsav_sp @user_id, @new_batch_code OUTPUT

IF @result !=  0
BEGIN
  ROLLBACK TRAN
  select @err = 95
  return 
END

update o
set batch_code = convert(varchar(16),@new_batch_code), status = 'T',
  date_transfered = dateadd(day, p.date_applied - 693596, '01/01/1900')	-- skk 06/09/00 22637
from #post_orders p, orders_all o
where p.order_no = o.order_no and p.ext = o.ext and o.status != 'T'

-- v1.5 Start
DELETE	a
FROM	cvo_soft_alloc_start a
JOIN	#post_orders b
ON		a.order_no = b.order_no
AND		a.order_ext = b.ext
-- v1.5 End
COMMIT TRAN

-- v1.4 Now orders/credits have posted update the coop figures

CREATE TABLE #coop_to_process (id int identity(1,1), order_no int, order_ext int)

INSERT	#coop_to_process (order_no, order_ext)
SELECT	distinct order_no, ext
FROM	#post_orders

SET @last_id = 0

SELECT	TOP 1 @id = id,
		@order_no = order_no,
		@order_ext = order_ext
FROM	#coop_to_process
WHERE	id > @last_id
ORDER BY id ASC

WHILE @@ROWCOUNT <> 0
BEGIN

	EXEC CVO_coop_dollars @order_no, @order_ext

	SET @last_id = @id

	SELECT	TOP 1 @id = id,
			@order_no = order_no,
			@order_ext = order_ext
	FROM	#coop_to_process
	WHERE	id > @last_id
	ORDER BY id ASC
END

DROP TABLE #coop_to_process

truncate table #orders

if @trx_type = 2032 -- credit memos
  exec icv_fs_post_cradj @user, @process_ctrl_num , @err OUT

return 
GO
GRANT EXECUTE ON  [dbo].[adm_post_ar_work] TO [public]
GO
