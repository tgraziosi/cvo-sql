SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v10.0 CB 13/06/2012 - Soft Allocation - Tax calc on save
-- v10.1 CB 18/06/2012 - Depending on the status update the tax
-- v10.2 CT 15/10/2012 - Call routine to calculate percentage fee line on credit return
-- v10.3 CB 04/02/2013 - Performance
-- v10.4 CB 09/04/2013 - Issue #1228 - Tax Issue
-- v10.5 CB 01/05/2013 - Replace cursor
-- v10.6 CB 07/05/2013 - Performance 
-- v10.7 CB 16/06/2014 - Performance
CREATE PROCEDURE [dbo].[adm_calculate_oetax] @ord int, @ext int,     
 @err int out, @doctype int = 0, @trx_ctrl_num varchar(16) = '',         
 @online_call int = 0, @debug int = 0 AS        
        
set nocount on        
        
declare @tot_ord_tax decimal(20,8), @tot_ord_incl decimal(20,8), @ship_ind int, @freight decimal(20,8) -- mls 3/28/00 SCR 22705        
        
declare @total_tax decimal(20,8), @non_included_tax decimal(20,8), @included_tax decimal(20,8)        
declare @curr_code char(8), @hstat char(1)        
declare @precision int, @xlin int, @price decimal(20,8), @exprice decimal(20,8), @exdisc decimal(20,8)        
declare @txcode char(8), @disc decimal(20,8)        
declare @origqty decimal(20,8), @qty decimal(20,8)        
declare @AR_INCL_NON_TAX char(1)        -- mls 11/1/00 SCR 23738        
declare @cpi_count int         
declare @calc_method char(1)         -- mls 9/22/03 31913        
declare @VAT_report int, @terms varchar(20), @VAT_disc decimal(20,8)        
declare @tax_companycode varchar(255),        
@orders_org_id varchar(30)   

-- v10.5 Start
DECLARE	@row_id			int,
		@last_row_id    int
-- v10.5 End 

-- START v10.2
EXEC dbo.cvo_calcluate_credit_return_fee_percentage_sp @ord,@ext
-- END v10.2
        
if @online_call = 1        
begin        
  create table #temp (reference_number int, amt_tax decimal(20,8), amt_tax_included decimal(20,8),        
    calc_tax decimal(20,8), tax_included int, non_recoverable_tax decimal(20,8), non_rec_frt_tax decimal(20,8), non_rec_incl_tax decimal(20,8))        
        
  select @cpi_count = count(distinct tax_code), @txcode=min(tax_code)        
  from #online_taxinfo        
  where control_number = @ord and reference_number > 0        
        
  if @txcode <> (select tax_code from #online_taxinfo (nolock)         
    where control_number = @ord and reference_number = 0 and trx_type = 1)  -- mls 3/18/05 SCR 34424        
    select @cpi_count = @cpi_count + 1        
        
  select @ship_ind = 0        
        
  select @terms = tax_code from #online_taxinfo (nolock) where control_number = @ord and reference_number = -10        
end        
        
if @online_call = 0        
begin        
select @cpi_count = count(distinct tax_code), @txcode=min(tax_code)        
from ord_list (NOLOCK) -- v1.0        
where order_no = @ord and order_ext = @ext        
        
if isnull(@trx_ctrl_num,'') = ''        
  select @trx_ctrl_num = 'shipped'        
        
if @txcode <> (select tax_id from orders_all (nolock) where order_no = @ord and ext = @ext)  -- mls 3/18/05 SCR 34424        
  select @cpi_count = @cpi_count + 1        
        
select @ship_ind = isnull((select distinct 1 from ord_list (nolock)     -- mls 11/1/00 SCR 23738        
  where order_no = @ord and order_ext = @ext and (cr_shipped+shipped) != 0),0)        
        
select @terms = terms from orders_all (nolock) where order_no = @ord and ext = @ext        
        
UPDATE orders_all WITH (ROWLOCK)       
SET tax_valid_ind = 0        
WHERE order_no = @ord and ext = @ext        
end        
        
select @AR_INCL_NON_TAX = isnull((select Upper(substring(value_str,1,1)) from config (nolock) -- mls 11/1/00 SCR 23738        
  where flag = 'AR_INCL_NON_TAX'),'N')        
        
select @calc_method = isnull((select Upper(substring(value_str,1,1)) from config (nolock) -- mls 9/22/03 31913        
  where flag = 'SO_TAX_CALC_MTHD'),'1')        
        
select @VAT_report = isnull((select VAT_report from arco (nolock)),0)    -- mls 3/16/04 SCR 32499        
select @VAT_disc = 0        
        
        
-- mls 7/29/04 SCR 33324         
delete from #TxLineInput        
delete from #TXLineInput_ex        
delete from #txconnhdrinput        
delete from #txconnlineinput        
        
delete from #TXtaxtype        
delete from #TXtaxtyperec        
delete from #TXtaxcode        
delete from #TXcents        
        
        
if @VAT_report = 1        
begin        
  select @VAT_disc = isnull((select discount_prc from artermsd d (nolock)        
    where d.terms_code = @terms and         
      d.sequence_id = isnull((select min(sequence_id) from artermsd m (nolock) where m.terms_code = @terms),0)),0)        
end        
        
if @cpi_count = 1           -- mls 3/28/00 SCR 22680 start        
and exists (select 1 from artax (nolock) where tax_code = @txcode and tax_included_flag = 0)         
and (@ship_ind = 0 or @AR_INCL_NON_TAX = 'N')       -- mls 11/1/00 SCR 23738        
begin        
        
  if (select sum(c.prc_flag + c.amt_tax + c.vat_flag + isnull(c.tax_connect_flag,0))        
     from artaxdet b (nolock), artxtype c (nolock)        
     where b.tax_code = @txcode and c.tax_type_code = b.tax_type_code) = 0        
  begin        
    if @online_call = 1        
    begin        
      insert #temp        
      select 0,  0, 0, 0, 0,0, 0, 0        
          
      delete from #online_taxinfo         
      where control_number = @ord and trx_type = 3        
        
      insert #online_taxinfo        
      (control_number, reference_number, trx_type, amt_tax, amt_tax_included,        
      calc_tax, tax_included, non_recoverable_tax, non_rec_frt_tax,        
      non_rec_incl_tax)        
      select @ord, 0, 3, amt_tax, amt_tax_included,        
      calc_tax, tax_included, non_recoverable_tax, non_rec_frt_tax,        
      non_rec_incl_tax        
      from #temp        
    end        
        
    if @online_call = 0        
    begin        
    UPDATE orders_all WITH (ROWLOCK)                
    SET total_invoice = total_invoice - total_tax + tot_tax_incl,        
 total_amt_order = total_amt_order + tot_ord_incl,        
        gross_sales = gross_sales + tot_tax_incl,        
 total_tax = 0,        
    tot_tax_incl = 0,        
    tot_ord_tax = 0,        
    tot_ord_incl = 0,        
 tax_valid_ind = 1        
    WHERE order_no = @ord and ext = @ext         
        
    Update ord_list  WITH (ROWLOCK) set total_tax= 0        
    where order_no=@ord and order_ext=@ext and total_tax <> 0        
        
    if exists (select 1 from ord_list_tax (nolock) where order_no = @ord and order_ext = @ext)        
    begin        
      delete ord_list_tax WHERE order_no = @ord AND order_ext = @ext        
    end                   
        
    select @err = 1        
    end        
    return        
  end         
end            -- mls 3/28/00 SCR 22680 end        
        
if @online_call = 1        
begin        
  select        
    @orders_org_id = organization_id        
  from #online_taxinfo        
  where control_number = @ord and reference_number = 0         
  and trx_type = 1        
        
  select @tax_companycode = isnull((select tc_companycode         
    from Organization_all (nolock) where organization_id = @orders_org_id),'')        
        
        
  insert #txconnhdrinput        
  (doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,        
  discount, purchaseorderno, customercode, customerusagetype, detaillevel,        
  referencecode, oriaddressline1, oriaddressline2, oriaddressline3,        
  oricity, oriregion, oripostalcode, oricountry, destaddressline1,        
  destaddressline2, destaddressline3, destcity, destregion, destpostalcode,        
  destcountry, currCode, currRate, currRateDate, locCode, paymentDt, taxOverrideReason,        
  taxOverrideAmt, taxOverrideDate, taxOverrideType, commitInd)        
  select @ord, @doctype,        
    o.tax_trx_type, @tax_companycode, getdate(), '', '',        
    0, '', o.customer_code, '', 3, '',         
    l.addr1,l.addr2,l.addr3,l.city,l.state,l.zip, l.country_code,        
    case when isnull(o.one_time_vend_ind,0) = 1 then o.addr1 else v.addr2 end,        
    case when isnull(o.one_time_vend_ind,0) = 1 then o.addr2 else v.addr3 end,        
    case when isnull(o.one_time_vend_ind,0) = 1 then o.addr3 else v.addr4 end,        
    case when isnull(o.one_time_vend_ind,0) = 1 then o.city else v.city end,        
    case when isnull(o.one_time_vend_ind,0) = 1 then o.state else v.state end,        
    case when isnull(o.one_time_vend_ind,0) = 1 then o.zip else v.postal_code end,        
    case when isnull(o.one_time_vend_ind,0) = 1 then o.country else v.country_code end,        
    o.currency_code, o.currRate, getdate(), '', NULL,        
    '', 0.0, NULL, 2, 0        
  from #online_taxinfo o        
  join arcust v (nolock) on v.customer_code = o.customer_code and v.address_type = 0 -- v10.3       
-- v10.3  join armaster_all v (nolock) on v.customer_code = o.customer_code and v.address_type = 0        
  join locations_all l (nolock) on l.location = o.location        
  where control_number = @ord and trx_type = 2        
        
  if @@error <> 0         
  begin        
    select @err = -21        
    return     
  end         
        
  if not exists (select 1 from #txconnhdrinput)        
  begin        
    select @err = -22        
    return        
  end        
        
--  set @debug = 0        
  insert #TXLineInput_ex (control_number,        
    reference_number, trx_type, currency_code, curr_precision,         
    tax_code, freight, action_flag, seqid, vat_prc)        
  select @ord,reference_number, trx_type, currency_code,         
    case when @calc_method = '2' then 8 else curr_precision end,        
    tax_code, freight, 1, 0, @VAT_disc        
  from #online_taxinfo        
  where control_number = @ord and tax_code <> '' and tax_code <> '*'  and reference_number = 0 and freight > 0        
  and trx_type = 1        
        
  insert #TXLineInput_ex (control_number,        
    reference_number, trx_type, currency_code, curr_precision,         
    tax_code, qty, unit_price, extended_price,        
    amt_discount, seqid, vat_prc)        
  select @ord,reference_number, trx_type, currency_code,         
    case when @calc_method = '2' then 8 else curr_precision end,        
    tax_code, qty,unit_price, round((qty * unit_price), curr_precision), 0, seqid, @VAT_disc        
  from #online_taxinfo        
  where control_number = @ord and tax_code <> '' and tax_code <> '*' and reference_number > 0        
        
  if @@error <> 0         
  begin        
    select @err = -2        
    return        
  end        
end        
        
if @online_call = 0        
begin        
select  @curr_code = curr_key, @hstat = status,        
 @txcode = tax_id, @origqty = 1, @xlin=-1,      -- mls 3/28/00 SCR 22705 start        
 @qty = 1, @exprice = tot_ord_freight, @exdisc = 0,            
 @freight = freight ,        -- mls 3/28/00 SCR 22705 end        
        
    @orders_org_id = organization_id        
from orders_all (nolock)        
where order_no=@ord and ext=@ext        
        
select @tax_companycode = isnull((select tc_companycode         
  from Organization_all (nolock) where organization_id = @orders_org_id),'')        
        
select @precision = isnull( (select curr_precision from glcurr_vw (nolock)        
    where glcurr_vw.currency_code=@curr_code), 1.0 )        
        
insert #txconnhdrinput        
(doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,        
discount, purchaseorderno, customercode, customerusagetype, detaillevel,        
referencecode, oriaddressline1, oriaddressline2, oriaddressline3,        
oricity, oriregion, oripostalcode, oricountry, destaddressline1,        
destaddressline2, destaddressline3, destcity, destregion, destpostalcode,        
destcountry, currCode, currRate, currRateDate, locCode, paymentDt, taxOverrideReason,        
taxOverrideAmt, taxOverrideDate, taxOverrideType, commitInd)        
select 'ordered', 0,         
case when o.type = 'I' then 2031 else 2032 end, @tax_companycode, getdate(), '', '',        
0 , '', o.cust_code, '', 3, '',         
addr1,addr2,addr3,city,state,zip,country_code,        
o.ship_to_add_1, o.ship_to_add_2, o.ship_to_add_3,o.ship_to_city, o.ship_to_state,        
o.ship_to_zip, o.ship_to_country_cd ,o.curr_key, o.curr_factor, getdate(), '', NULL,        
'', 0.0, NULL, 2, 0        
from orders_all o  (nolock)      
join locations_all l (nolock) on l.location = o.location        
 where order_no = @ord and ext = @ext        
        
if @@error <> 0        
begin        
  select @err = -21        
  return        
end        
        
if not exists (select 1 from #txconnhdrinput)        
begin        
  select @err = -22        
  return        
end        
        
select @xlin = 0, @ship_ind = 0         -- mls 3/28/00 SCR 22705 start        
    
 insert #TXLineInput_ex (control_number,        
 reference_number, trx_type, currency_code, curr_precision,        
 tax_code, qty, unit_price, extended_price,        
 amt_discount, seqid, vat_prc)         -- mls 3/16/04 SCR 32499        
 select 'ordered',line_no, 0, @curr_code,         
 case when @calc_method = '2' then 8 else @precision end,      -- mls 9/22/03 31913        
 tax_code, ((ordered+cr_ordered) * conv_factor), curr_price,         
 Round( ( (ordered+cr_ordered) * curr_price ), @precision ),        
 Round( ( Round( ( (ordered+cr_ordered) * curr_price ), @precision ) * discount/100 ), @precision ),        
 line_no, @VAT_disc          -- mls 3/16/04 SCR 32499        
 from ord_list  (nolock)       
 where order_no=@ord and order_ext=@ext

--BEGIN SED009 -- Tax Connect Integration    
--JVM 09/06/2010      
--IF OBJECT_ID('tempdb..##CORE') IS NOT NULL DROP TABLE ##CORE
--SELECT * INTO ##CORE FROM #TXLineInput_ex
 
 DECLARE @reference_number INT, @qty_tx DECIMAL(20,8), 
 @alloc_qty DECIMAL(20,8), @cr_ordered DECIMAL(20,8), @conv_factor DECIMAL(20,8), @curr_price DECIMAL(20,8), @discount  DECIMAL(20,8),
 @ordered decimal(20,8) -- v10.0
 
	-- v10.5 Start
	CREATE TABLE #aco_line_cursor (
		row_id				int IDENTITY(1,1),
		reference_number	int,
		qty					decimal(20,8))

	INSERT	#aco_line_cursor (reference_number, qty)
	SELECT	reference_number, qty FROM #TXLineInput_ex

	CREATE INDEX #aco_line_cursor_ind0 ON #aco_line_cursor(row_id)

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@reference_number = reference_number,
			@qty_tx = qty
	FROM	#aco_line_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

--	DECLARE line_cursor CURSOR FOR 
--	SELECT reference_number, qty FROM #TXLineInput_ex

--	OPEN line_cursor

--	FETCH NEXT FROM line_cursor 
--	INTO @reference_number, @qty_tx

--	WHILE @@FETCH_STATUS = 0
--	BEGIN
	-- v10.5 End
		SELECT @cr_ordered  = cr_ordered,
			   @conv_factor = conv_factor,
			   @curr_price  = curr_price,
			   @discount    = discount,
			   @ordered = ordered -- v10.0
		FROM   ord_list (nolock)
		WHERE  order_no  = @ord AND 
			   order_ext = @ext AND
			   line_no   = @reference_number


	   IF (SELECT part_type FROM ord_list (nolock) WHERE order_no = @ord AND order_ext = @ext AND line_no = @reference_number ) = 'C'
	   BEGIN
		IF EXISTS(SELECT qty FROM tdc_soft_alloc_tbl(NOLOCK) WHERE order_no = @ord AND order_ext = @ext AND line_no = @reference_number )
			SELECT @alloc_qty = ordered
			FROM  ord_list (NOLOCK)  --tdc_soft_alloc_tbl
			WHERE order_no  = @ord   AND 
				  order_ext = @ext AND 
				  line_no   = @reference_number 	
		ELSE
			SET @alloc_qty = @ordered -- 0 -- v10.0 
	   END
	   
	   IF (SELECT part_type FROM ord_list (nolock) WHERE order_no = @ord AND order_ext = @ext AND line_no = @reference_number ) != 'C'
	   BEGIN
		IF EXISTS(SELECT qty FROM tdc_soft_alloc_tbl(NOLOCK) WHERE order_no = @ord AND order_ext = @ext AND line_no = @reference_number )
			SELECT @alloc_qty = SUM(qty)
			FROM tdc_soft_alloc_tbl(NOLOCK) 
			WHERE order_no  = @ord   AND 
				  order_ext = @ext AND 
				  line_no = @reference_number 
		ELSE
		   SET @alloc_qty = @ordered -- 0 -- v10.0
	   END      
	  
	   SET @qty_tx = (@alloc_qty + @cr_ordered) * @conv_factor
	  
	   UPDATE #TXLineInput_ex
	   SET    qty = @qty_tx
			  ,extended_price = Round( ( (@qty_tx ) * @curr_price ), curr_precision )       
			  ,amt_discount   = Round( ( Round( ( (@qty_tx ) * @curr_price ), curr_precision ) * @discount/100 ), curr_precision)
	   WHERE  reference_number = @reference_number
	   
		-- v10.5 Start
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@reference_number = reference_number,
				@qty_tx = qty
		FROM	#aco_line_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

--	   FETCH NEXT FROM line_cursor 
--	   INTO @reference_number, @qty_tx
	END

--	CLOSE line_cursor
--	DEALLOCATE line_cursor
	DROP TABLE #aco_line_cursor
	-- v10.5 End

	--IF OBJECT_ID('tempdb..##UPD') IS NOT NULL DROP TABLE ##UPD
	--SELECT * INTO ##UPD FROM #TXLineInput_ex

 /*if exists(select * from tdc_soft_alloc_tbl (nolock) where order_no=@ord and order_ext=@ext  )    
 begin    
  insert #TXLineInput_ex (control_number,     reference_number, trx_type, currency_code, curr_precision,     tax_code, qty, unit_price, extended_price,     amt_discount, seqid, vat_prc)         -- mls 3/16/04 SCR 32499        
  select 'ordered', ol.line_no, 0, @curr_code,         
  case when @calc_method = '2' then 8 else @precision end,      -- mls 9/22/03 31913        
  ol.tax_code, ((sa.qty + ol.shipped + ol.cr_ordered) * ol.conv_factor), ol.curr_price,         
  Round( ( (sa.qty + ol.shipped + ol.cr_ordered) * ol.curr_price ), @precision ),        
  Round( ( Round( ( (sa.qty + ol.shipped + ol.cr_ordered) * ol.curr_price ), @precision ) * ol.discount/100 ), @precision ),        
  ol.line_no, @VAT_disc          -- mls 3/16/04 SCR 32499        
  from ord_list ol (nolock), tdc_soft_alloc_tbl sa (nolock)         
  where ol.order_no = sa.order_no and ol.order_ext = sa.order_ext and ol.line_no = sa.line_no and    
  ol.order_no=@ord and ol.order_ext=@ext     
 end    
 else    
 begin    
  insert #TXLineInput_ex (control_number,        
  reference_number, trx_type, currency_code, curr_precision,        
  tax_code, qty, unit_price, extended_price,        
  amt_discount, seqid, vat_prc)         -- mls 3/16/04 SCR 32499        
  select 'ordered',line_no, 0, @curr_code,         
  case when @calc_method = '2' then 8 else @precision end,      -- mls 9/22/03 31913        
  tax_code, ((shipped) * conv_factor), curr_price,         
  Round( ( (shipped) * curr_price ), @precision ),        
  Round( ( Round( ( (shipped) * curr_price ), @precision ) * discount/100 ), @precision ),        
  line_no, @VAT_disc          -- mls 3/16/04 SCR 32499        
  from ord_list         
  where order_no=@ord and order_ext=@ext       
 end     */
--END   SED009 -- Tax Connect Integration     
     
if @@error <> 0         
begin                
  select @err = -2        
  return        
end        
        
select @err = -3        
        
  insert #TXLineInput_ex (control_number,        
    reference_number, trx_type, currency_code, curr_precision,         
    tax_code, freight, action_flag, seqid, vat_prc)        
  select 'ordered',0, 1, @curr_code,         
  case when @calc_method = '2' then 8 else @precision end,      -- mls 9/22/03 31913        
  @txcode, @exprice,1,1, @VAT_disc        
        
insert #TXLineInput_ex (control_number,        
reference_number, trx_type, currency_code, curr_precision,         
tax_code, qty, unit_price, extended_price,         
amt_discount, seqid, vat_prc)         -- mls 3/16/04 SCR 32499       
select @trx_ctrl_num,line_no, 0, @curr_code,         
case when @calc_method = '2' then 8 else @precision end,      -- mls 9/22/03 31913        
tax_code, ((shipped+cr_shipped) * conv_factor), curr_price,         
Round( ( (shipped+cr_shipped) * curr_price ), @precision ),        
Round( ( Round( ( (shipped+cr_shipped) * curr_price ), @precision ) * discount/100 ),@precision ),        
line_no, @VAT_disc          -- mls 3/16/04 SCR 32499        
from ord_list (nolock)        
where order_no=@ord and order_ext=@ext and (cr_shipped+shipped) <> 0       
        
if exists (select 1 from ord_list (nolock) where order_no = @ord and order_ext = @ext         
and (cr_shipped + shipped) <> 0)        
begin          
  select @ship_ind = 1        
        
  insert #txconnhdrinput        
  (doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,        
  discount, purchaseorderno, customercode, customerusagetype, detaillevel,        
  referencecode, oriaddressline1, oriaddressline2, oriaddressline3,        
  oricity, oriregion, oripostalcode, oricountry, destaddressline1,        
  destaddressline2, destaddressline3, destcity, destregion, destpostalcode,        
  destcountry, currCode, currRate, currRateDate, locCode, paymentDt, taxOverrideReason,        
taxOverrideAmt, taxOverrideDate, taxOverrideType, commitInd)        
  select @trx_ctrl_num, @doctype,         
  case when o.type = 'I' then 2031 else 2032 end, @tax_companycode,         
  case when @doctype = 0 then getdate() else isnull(o.date_shipped,getdate()) end, -- mls 1/28/08 SCR 38448        
  '', '',        
  0, '', o.cust_code, '', 3, '',         
  addr1,addr2,addr3,city,state,zip,country_code,        
  o.ship_to_add_1, o.ship_to_add_2, o.ship_to_add_3,o.ship_to_city, o.ship_to_state,        
  o.ship_to_zip, o.ship_to_country_cd ,o.curr_key, o.curr_factor,         
  case when @doctype = 0 then getdate() else isnull(o.date_shipped,getdate()) end,        
  '', NULL,        
  '', 0.0, NULL, 2, 0        
  from orders_all o  (nolock)      
  join locations_all l (nolock) on l.location = o.location        
  where order_no = @ord and ext = @ext        
        
  if @@error <> 0        
  begin        
    select @err = -21        
    return        
  end        
  if not exists (select 1 from #txconnhdrinput)        
  begin        
    select @err = -22        
    return        
  end        
          
    insert #TXLineInput_ex (control_number,        
      reference_number, trx_type, currency_code, curr_precision,         
      tax_code, freight, action_flag, seqid, vat_prc)        
    select @trx_ctrl_num,0, 1, @curr_code,         
      case when @calc_method = '2' then 8 else @precision end,      -- mls 9/22/03 31913        
      @txcode, @freight, 1, 1, @VAT_disc        
end             -- mls 3/28/00 SCR 22705 end        
        
-- mls 4/2/08 SCR 050152 -- add freight line to txconnlineinput        
  insert #txconnlineinput        
  (doccode, no,   oriaddressline1, oriaddressline2, oriaddressline3,        
  oricity, oriregion, oripostalcode,  oricountry,  destaddressline1,        
  destaddressline2,  destaddressline3, destcity,  destregion,        
  destpostalcode,  destcountry,  qty,   amount,        
  discounted,   exemptionno,  itemcode,  ref1,        
  ref2,    revacct,  taxcode )        
  select        
    TLI.control_number, TLI.reference_number, h.addr1, h.addr2, h.addr3,        
    h.city, h.state, h.zip, h.country_code, CHI.destaddressline1,        
    CHI.destaddressline2, CHI.destaddressline3, CHI.destcity, CHI.destregion, CHI.destpostalcode,        
    CHI.destcountry,  TLI.qty ,TLI.extended_price - TLI.amt_discount,        
    case when amt_discount <> 0 then 1 else 0 end, CHI.exemptionno, l.part_no, '','', '', TLI.tax_code        
  from #TXLineInput_ex TLI        
  join #txconnhdrinput CHI on CHI.doccode = TLI.control_number        
  join ord_list l (nolock) on l.order_no = @ord and l.order_ext = @ext and l.line_no = TLI.reference_number        
  join locations_all h (nolock) on h.location = l.location         
  where TLI.action_flag = 0        
        
if @@error <> 0        
begin        
  select @err = -24        
  return        
end        
end        
        
  insert #txconnlineinput        
  (doccode, no,   oriaddressline1, oriaddressline2, oriaddressline3,        
  oricity, oriregion, oripostalcode,  oricountry,  destaddressline1,        
  destaddressline2,  destaddressline3, destcity,  destregion,        
  destpostalcode,  destcountry,  qty,   amount,        
  discounted,   exemptionno,  itemcode,  ref1,        
  ref2,    revacct,  taxcode )        
  select        
   TLI.control_number, TLI.reference_number, h.addr1, h.addr2, h.addr3,        
    h.city, h.state, h.zip, h.country_code, CHI.destaddressline1,        
    CHI.destaddressline2, CHI.destaddressline3, CHI.destcity, CHI.destregion, CHI.destpostalcode,        
    CHI.destcountry,  TLI.qty ,TLI.freight,        
    0, CHI.exemptionno, 'Freight' , '','', '', TLI.tax_code        
  from #TXLineInput_ex TLI        
  join #txconnhdrinput CHI on CHI.doccode = TLI.control_number        
  join orders l (nolock) on l.order_no = @ord and l.ext = @ext        
  join locations h (nolock) on h.location = l.location         
  where TLI.action_flag > 0 and TLI.freight <> 0        
if @@error <> 0        
begin        
  select @err = -25        
  return        
end        
        
select @err = -5        
        
exec @err = TXCalculateTax_SP @debug, 1 -- distr_call        
        
if @err <> 1         
begin        
 select @err = -6        
 return        
end        
        
select @total_tax=0, @non_included_tax=0, @included_tax=0      -- mls 3/28/00 SCR 22705 start        
select @tot_ord_tax = 0, @tot_ord_incl = 0        
        
exec TXGetTotal_SP 'ordered', @tot_ord_tax output, @non_included_tax output, @tot_ord_incl output, @calc_method, -- mls 9/22/03 31913        
  1 -- distr_call        
exec TXGetTotal_SP @trx_ctrl_num, @total_tax output, @non_included_tax output, @included_tax output, @calc_method, -- mls 9/22/03 31913        
  1 -- distr_call        
        
        
if @total_tax < 0        
begin        
 select @err = -81        
 return        
end        
if @tot_ord_tax < 0        
begin        
 select @err = -82        
 return        
end        
        
if @ship_ind = 1        
begin                   
  Update o        
  set total_tax= ti.calc_tax,        
 taxable = case when tc.tax_included_flag = 0 then 1 else 0 end        
 from #TXLineInput_ex ti, #TXtaxcode tc, ord_list o  WITH (ROWLOCK)       
 where o.order_no=@ord and o.order_ext=@ext and o.line_no=ti.reference_number        
 and ti.control_number = @trx_ctrl_num         
        and tc.tax_code = ti.tax_code and tc.control_number = ti.control_number        
        and (o.total_tax <> ti.calc_tax or          
   o.taxable <> case when tc.tax_included_flag = 0 then 1 else 0 end)        
        
  delete ord_list_tax        
    WHERE order_no = @ord AND order_ext = @ext        
        
  if @calc_method = '1'  -- calc and rounded at tax code        
  begin        
    INSERT INTO ord_list_tax   WITH (ROWLOCK)      
 (        
  order_no,order_ext, sequence_id, tax_type_code,        
  amt_taxable,  amt_gross, amt_tax,        
  amt_final_tax        
 )        
 SELECT @ord,@ext,min(tt.row_id), tt.tax_type,        
  sum(tt.amt_taxable),         
        sum(tt.amt_gross),         
        sum(tt.amt_tax),         
        sum(tt.amt_final_tax)        
 FROM #TXtaxcode tc        
        join #TXtaxtyperec ttr on ttr.tc_row = tc.row_id        
        join #TXtaxtype tt on tt.ttr_row = ttr.row_id        
 where tc.control_number = @trx_ctrl_num        
        group by tt.tax_type        
        
  end        
  else -- @calc_method = '2' -- calc and not rounded and summed to give total        
       -- @calc_method = '3' -- calc and rounded at line item summed to give total        
  begin        
    update tc        
    set amt_tax = isnull((select round(sum(calc_tax),@precision) from #TXLineInput_ex ti        
      where ti.control_number = tc.control_number and ti.tax_code = tc.tax_code),0)        
    from #TXtaxcode tc        
    where tc.control_number = @trx_ctrl_num        
        
    update ttr        
    set cur_amt = case when ttr.row_id = isnull((select max(tt1.row_id) from #TXtaxtyperec tt1 where tt1.tc_row = tc.row_id),0)        
      then tc.amt_tax - isnull((select sum(tt2.cur_amt) from #TXtaxtyperec tt2        
        where tt2.tc_row = tc.row_id and tt2.row_id != ttr.row_id),0)         
      else ttr.cur_amt end        
    from #TXtaxtyperec ttr, #TXtaxcode tc        
    where ttr.tc_row = tc.row_id and tc.control_number = @trx_ctrl_num        
   
    update tt        
    set amt_tax = ttr.cur_amt,        
      amt_final_tax = ttr.cur_amt        
    from #TXtaxcode tc        
    join #TXtaxtyperec ttr on ttr.tc_row = tc.row_id        
    join #TXtaxtype tt on tt.ttr_row = ttr.row_id        
    where tc.control_number = @trx_ctrl_num        
        
    INSERT INTO ord_list_tax   WITH (ROWLOCK)      
 (        
  order_no,order_ext, sequence_id, tax_type_code,        
  amt_taxable,  amt_gross, amt_tax,        
  amt_final_tax        
 )        
 SELECT @ord,@ext,min(tt.row_id), tt.tax_type,        
  sum(tt.amt_taxable), sum(tt.amt_gross), sum(tt.amt_tax), sum(tt.amt_final_tax)        
 FROM #TXtaxcode tc        
        join #TXtaxtyperec ttr on ttr.tc_row = tc.row_id        
        join #TXtaxtype tt on tt.ttr_row = ttr.row_id        
 where tc.control_number = @trx_ctrl_num        
        group by tt.tax_type        
  end        
end  -- records on txlineinput                
else                   
begin        
        
  if @online_call = 1        
  begin        
    insert #temp        
    select 0,  @tot_ord_tax, @tot_ord_incl , 0, 0,0, 0, 0        
          
    delete from #online_taxinfo         
    where control_number = @ord and trx_type = 3        
        
    insert #online_taxinfo        
    (control_number, reference_number, trx_type, amt_tax, amt_tax_included,        
    calc_tax, tax_included, non_recoverable_tax, non_rec_frt_tax,        
    non_rec_incl_tax)        
    select @ord, 0, 3, amt_tax, amt_tax_included,        
    calc_tax, tax_included, non_recoverable_tax, non_rec_frt_tax,        
    non_rec_incl_tax        
    from #temp        
  end        
        
  if @online_call = 0        
  begin        
    Update o set total_tax=ti.calc_tax,        
 taxable = CASE WHEN tc.tax_included_flag = 0 then 1 else 0 end           
 from ord_list o  WITH (ROWLOCK), #TXLineInput_ex ti, #TXtaxcode tc  -- v10.6 Remove nolock from update      
 where o.order_no=@ord and o.order_ext=@ext and o.line_no=ti.reference_number        
 and ti.control_number = 'ordered'        
        and tc.tax_code = ti.tax_code and tc.control_number = ti.control_number        
 and (o.total_tax <> ti.calc_tax or              
 o.taxable <> CASE WHEN tc.tax_included_flag = 0 then 1 else 0 end)           
        
    if exists (select 1 from ord_list_tax (NOLOCK) where order_no = @ord and order_ext = @ext) -- v1.0
    begin        
      delete ord_list_tax WHERE order_no = @ord AND order_ext = @ext        
    end        
  end        
end  -- no records on txlineinput         -- mls 3/28/00 SCR 22705 end        
        
if @online_call = 0        
begin        
  UPDATE orders_all  WITH (ROWLOCK)       
  SET total_invoice = total_invoice - total_tax + tot_tax_incl + @total_tax - @included_tax,        
    total_amt_order = total_amt_order + tot_ord_incl - @tot_ord_incl,        
    gross_sales = gross_sales + tot_tax_incl - @included_tax,        
    total_tax = @total_tax,        
    tot_tax_incl = @included_tax,        
-- v10.4    tot_ord_tax = CASE WHEN status > 'N' THEN @total_tax ELSE @tot_ord_tax END,  -- v10.1              
    tot_ord_tax = CASE WHEN status > 'Q' THEN @total_tax ELSE @tot_ord_tax END,  -- v10.4              
    tot_ord_incl = @tot_ord_incl,        
    tax_valid_ind = 1        
WHERE order_no = @ord and ext = @ext        
end        
        
if @debug > 0         
begin        
print '#TXLineInput_ex'        
select * from #TXLineInput_ex        
print 'taxcode'        
select * from #TXtaxcode        
print 'taxtyperec'        
select * from #TXtaxtyperec        
print 'taxtype'        
select * from #TXtaxtype        
end        
        
select @err = 1        
        
return 


GO
GRANT EXECUTE ON  [dbo].[adm_calculate_oetax] TO [public]
GO
