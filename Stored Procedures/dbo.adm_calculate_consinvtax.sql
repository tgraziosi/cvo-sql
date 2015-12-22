SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[adm_calculate_consinvtax] @doc_ctrl_num varchar(16),
 @err int out, @doctype int = 0, @trx_ctrl_num varchar(16) = '', @debug int = 0 AS

declare @tot_ord_tax decimal(20,8), @tot_ord_incl decimal(20,8), @ship_ind int, @freight decimal(20,8)	-- mls 3/28/00 SCR 22705

declare @total_tax decimal(20,8), @non_included_tax decimal(20,8), @included_tax decimal(20,8)
declare @curr_code char(8), @hstat char(1)
declare @precision int, @xlin int, @price decimal(20,8), @exprice decimal(20,8), @exdisc decimal(20,8)
declare @txcode char(8), @disc decimal(20,8)
declare @origqty decimal(20,8), @qty decimal(20,8)
declare @AR_INCL_NON_TAX char(1)								-- mls 11/1/00 SCR 23738
declare @cpi_count int	
declare @calc_method char(1)									-- mls 9/22/03 31913
declare @tax_companycode varchar(255),
@orders_org_id varchar(30)

select @cpi_count = count(distinct tax_code), @txcode=min(tax_code)
from #ord_list
where doc_ctrl_num = @doc_ctrl_num

if @txcode <> (select tax_code from #post_orders (nolock) where doc_ctrl_num = @doc_ctrl_num)
  select @cpi_count = @cpi_count + 1

select @ship_ind = isnull((select distinct 1 from #ord_list					-- mls 11/1/00 SCR 23738
  where doc_ctrl_num = @doc_ctrl_num and (cr_shipped+shipped) != 0),0)

select @AR_INCL_NON_TAX = isnull((select Upper(substring(value_str,1,1)) from config (nolock)	-- mls 11/1/00 SCR 23738
  where flag = 'AR_INCL_NON_TAX'),'N')

select @calc_method = isnull((select Upper(substring(value_str,1,1)) from config (nolock)	-- mls 9/22/03 31913
  where flag = 'SO_TAX_CALC_MTHD'),'1')

declare @VAT_report int, @terms varchar(20), @VAT_disc decimal(20,8)
select @VAT_report = isnull((select VAT_report from arco (nolock)),0)				-- mls 3/16/04 SCR 32499
select @terms = terms_code from #post_orders (nolock) where doc_ctrl_num = @doc_ctrl_num
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

if @cpi_count = 1 										-- mls 3/28/00 SCR 22680 start
and exists (select 1 from artax (nolock) where tax_code = @txcode and tax_included_flag = 0) 
and (@ship_ind = 0 or @AR_INCL_NON_TAX = 'N')							-- mls 11/1/00 SCR 23738
begin
  if (select sum(c.prc_flag + c.amt_tax + c.vat_flag + isnull(c.tax_connect_flag,0))
     from artaxdet b (nolock), artxtype c (nolock)
     where b.tax_code = @txcode and c.tax_type_code = b.tax_type_code) = 0
  begin
    UPDATE #post_orders									
    SET amt_net = amt_net - amt_tax,
      amt_due = amt_due - amt_tax,
      amt_tax = 0
    WHERE doc_ctrl_num = @doc_ctrl_num

    Update #ord_list set total_tax= 0
    where doc_ctrl_num = @doc_ctrl_num and total_tax <> 0

    -- no #ord_list_tax at this point

    select @err = 1
    return
  end 
end												-- mls 3/28/00 SCR 22680 end

select 	@curr_code = nat_cur_code, @hstat = 'T',
	@txcode = tax_code, @origqty = 1, @xlin=-1,						-- mls 3/28/00 SCR 22705 start
	@qty = 1, @exprice = amt_freight, @exdisc = 0, 			
	@freight = amt_freight,									-- mls 3/28/00 SCR 22705 end
    @orders_org_id = organization_id
from #post_orders 
where doc_ctrl_num = @doc_ctrl_num

select @precision = isnull( (select curr_precision from glcurr_vw (nolock)
				where glcurr_vw.currency_code=@curr_code), 1.0 )
select @xlin = 0, @ship_ind = 0									-- mls 3/28/00 SCR 22705 start

select @tax_companycode = isnull((select tc_companycode 
  from Organization_all (nolock) where organization_id = @orders_org_id),'')

insert #TXLineInput_ex (control_number,
reference_number, trx_type, currency_code, curr_precision, 
tax_code, qty, unit_price, extended_price, 
amt_discount, seqid, vat_prc)									-- mls 3/16/04 SCR 32499
select @trx_ctrl_num,row_id, 0, @curr_code, 
case when @calc_method = '2' then 8 else @precision end, 					-- mls 9/22/03 31913
tax_code, ((shipped+cr_shipped) * conv_factor), curr_price, 
Round( ( (shipped+cr_shipped) * curr_price ), @precision ),
Round( ( Round( ( (shipped+cr_shipped) * curr_price ), @precision ) * discount/100 ), @precision ),
row_id, @VAT_disc										-- mls 3/16/04 SCR 32499
from #ord_list 
where doc_ctrl_num = @doc_ctrl_num and (cr_shipped+shipped) <> 0

if exists (select 1 from #ord_list (nolock) where doc_ctrl_num = @doc_ctrl_num
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
  o.trx_type, @tax_companycode, getdate(), '', '',
  amt_discount, '', o.customer_code, '', 3, '', 
  addr1,addr2,addr3,city,state,zip,country_code,
  o.ship_to_addr1, o.ship_to_addr2, o.ship_to_addr3,o.ship_to_city, o.ship_to_state,
  o.ship_to_zip, o.ship_to_country_cd,  o.nat_cur_code, o.rate_home, getdate(), '', NULL,
'', 0.0, NULL, 2, 0
  from #post_orders o
  join locations l on l.location = o.location_code
  where o.doc_ctrl_num = @doc_ctrl_num

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

  update #txconnhdrinput
  set discount = isnull((select sum(Round(((shipped + cr_shipped) * curr_price) * 
     (discount/100), @precision))		-- mls 9/23/99 SCR 70 20885
      from #ord_list where doc_ctrl_num = @doc_ctrl_num), 0)
  where doccode = @trx_ctrl_num

  if @@error <> 0
  begin
    select @err = -23
    return
  end

		
  if @freight > 0
  begin
    insert #TXLineInput_ex (control_number,
      reference_number, trx_type, currency_code, curr_precision, 
      tax_code, freight, action_flag, seqid, vat_prc)
    select @trx_ctrl_num,0, 1, @curr_code, 
      case when @calc_method = '2' then 8 else @precision end, 					-- mls 9/22/03 31913
      @txcode, @freight, 1, 1, @VAT_disc
  end
end													-- mls 3/28/00 SCR 22705 end

-- mls 4/2/08 SCR 050152 - add freight line to txconnlineinput
  insert #txconnlineinput
  (doccode,	no, 		oriaddressline1,	oriaddressline2,	oriaddressline3,
  oricity,	oriregion,	oripostalcode,		oricountry,		destaddressline1,
  destaddressline2,		destaddressline3,	destcity,		destregion,
  destpostalcode,		destcountry,		qty,			amount,
  discounted,			exemptionno,		itemcode,		ref1,
  ref2,				revacct,		taxcode	)
  select
    TLI.control_number, TLI.reference_number, h.addr1, h.addr2, h.addr3,
    h.city, h.state, h.zip, h.country_code, CHI.destaddressline1,
    CHI.destaddressline2, CHI.destaddressline3, CHI.destcity, CHI.destregion, CHI.destpostalcode,
    CHI.destcountry,  TLI.qty, TLI.extended_price, 
    case when amt_discount <> 0 then 1 else 0 end, CHI.exemptionno, l.part_no, '','', '', TLI.tax_code
  from #TXLineInput_ex TLI
  join #txconnhdrinput CHI on CHI.doccode = TLI.control_number
  join #ord_list l on l.doc_ctrl_num = @doc_ctrl_num and l.row_id = TLI.reference_number
  join locations h on h.location = l.location 
  where TLI.action_flag = 0 

if @@error <> 0
begin
  select @err = -24
  return
end

-- mls 4/2/08 SCR 050152 - add freight line to txconnlineinput
  insert #txconnlineinput
  (doccode,	no, 		oriaddressline1,	oriaddressline2,	oriaddressline3,
  oricity,	oriregion,	oripostalcode,		oricountry,		destaddressline1,
  destaddressline2,		destaddressline3,	destcity,		destregion,
  destpostalcode,		destcountry,		qty,			amount,
  discounted,			exemptionno,		itemcode,		ref1,
  ref2,				revacct,		taxcode	)
  select
    TLI.control_number, TLI.reference_number, h.addr1, h.addr2, h.addr3,
    h.city, h.state, h.zip, h.country_code, CHI.destaddressline1,
    CHI.destaddressline2, CHI.destaddressline3, CHI.destcity, CHI.destregion, CHI.destpostalcode,
    CHI.destcountry,  TLI.qty ,TLI.freight,
    0, CHI.exemptionno, 'Freight' , '','', '', TLI.tax_code
  from #TXLineInput_ex TLI
  join #txconnhdrinput CHI on CHI.doccode = TLI.control_number
  join #post_orders l on l.doc_ctrl_num = @doc_ctrl_num 
  join locations h on h.location = l.location_code 
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
	if @err >= 0 select @err = -6
	return
end

select @total_tax=0, @non_included_tax=0, @included_tax=0						-- mls 3/28/00 SCR 22705 start
select @tot_ord_tax = 0, @tot_ord_incl = 0

exec TXGetTotal_SP @trx_ctrl_num, @total_tax output, @non_included_tax output, @included_tax output, @calc_method,	-- mls 9/22/03 31913
  1 -- distr_call

if @ship_ind = 1
begin											
  Update o
  set total_tax=ti.calc_tax,
	taxable = case when tc.tax_included_flag = 0 then 1 else 0 end
	from #TXLineInput_ex ti, #TXtaxcode tc, #ord_list o
	where o.doc_ctrl_num = @doc_ctrl_num and o.row_id=ti.reference_number
	and ti.control_number = @trx_ctrl_num 
        and tc.tax_code = ti.tax_code and tc.control_number = ti.control_number
        and (o.total_tax <> ti.calc_tax or 	
	  o.taxable <> case when tc.tax_included_flag = 0 then 1 else 0 end)

  delete #ord_list_tax
    WHERE doc_ctrl_num = @doc_ctrl_num

  if @calc_method = '1'  -- calc and rounded at tax code
  begin
    INSERT INTO #ord_list_tax
	(
		doc_ctrl_num, order_no,order_ext,	sequence_id,	tax_type_code,
		amt_taxable,		amt_gross,	amt_tax,
		amt_final_tax
	)
	SELECT	@doc_ctrl_num, 0, 0,min(tt.row_id), tt.tax_type,
		sum(tt.amt_taxable), sum(tt.amt_gross), sum(tt.amt_tax), sum(tt.amt_final_tax)
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

    INSERT INTO #ord_list_tax
	(
		doc_ctrl_num, order_no,order_ext,	sequence_id,	tax_type_code,
		amt_taxable,		amt_gross,	amt_tax,
		amt_final_tax
	)
	SELECT	@doc_ctrl_num, 0,0,min(tt.row_id), tt.tax_type,
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
  Update o set total_tax=ti.calc_tax,
	taxable = CASE WHEN tc.tax_included_flag = 0 then 1 else 0 end			
	from #ord_list o, #TXLineInput_ex ti, #TXtaxcode tc
	where o.doc_ctrl_num = @doc_ctrl_num and o.row_id=ti.reference_number
	and ti.control_number = 'ordered'
        and tc.tax_code = ti.tax_code and tc.control_number = ti.control_number
	and (o.total_tax <> ti.calc_tax or						
	o.taxable <> CASE WHEN tc.tax_included_flag = 0 then 1 else 0 end)			

  if exists (select 1 from #ord_list_tax where doc_ctrl_num = @doc_ctrl_num)
  begin
    delete #ord_list_tax WHERE doc_ctrl_num = @doc_ctrl_num
  end
end  -- no records on txlineinput									-- mls 3/28/00 SCR 22705 end

UPDATE #post_orders
SET amt_gross = amt_gross + amt_tax_included - @included_tax,
  amt_tax = @total_tax,
  amt_tax_included = @included_tax
WHERE doc_ctrl_num = @doc_ctrl_num

UPDATE #post_orders
set amt_net = amt_gross + amt_freight + amt_tax - amt_discount,
  amt_due = amt_gross + amt_freight + amt_tax - amt_discount
WHERE doc_ctrl_num = @doc_ctrl_num

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
GRANT EXECUTE ON  [dbo].[adm_calculate_consinvtax] TO [public]
GO
