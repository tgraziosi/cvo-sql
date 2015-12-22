SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[fs_calculate_rtvtax] @rtv int, @rtntype int=0, @err int OUT , @debug int = 0
AS
declare @calc_method char(1)									-- mls 9/22/03 #1

declare @controlnum char(16), @curr_code char(8), @hstat char(1)
declare @precision int, @xlin int, @price decimal(20,8), @exprice decimal(20,8), @qty decimal(20,8)
declare @txcode char(8), @disc decimal(20,8), @origqty decimal(20,8)
declare @tax_companycode varchar(255), @orders_org_id varchar(30)

select @controlnum=convert(varchar(12),@rtv)

select	@curr_code = currency_key,
  @orders_org_id = organization_id
from 	rtv_all
where 	rtv_no=@rtv

select 	@precision = isnull( (select curr_precision from glcurr_vw
							where glcurr_vw.currency_code=@curr_code), 1.0 )

select @calc_method = isnull((select Upper(substring(value_str,1,1)) from config (nolock)	-- mls 9/22/03 #1
  where flag = 'PO_TAX_CALC_MTHD'),'1')

UPDATE rtv_all
SET tax_valid_ind = 0
WHERE rtv_no = @rtv

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
select @rtv, 2, 
4092, @tax_companycode, getdate(), '', '',
0, '', o.vendor_no, '', 3, '', 
o.ship_address1,
o.ship_address2,
o.ship_address3,
o.ship_city,
o.ship_state,
o.ship_zip,
o.ship_to_country_cd,
l.addr1,l.addr2,l.addr3,l.city,l.state,l.zip, l.country_code,
o.currency_key, o.curr_factor, getdate(), '', NULL,
'', 0.0, NULL, 2, 0
from rtv_all o
join apmaster_all v on v.vendor_code = o.vendor_no and v.address_type = 0
join locations_all l on l.location = o.location
 where o.rtv_no = @rtv

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

select 	@xlin = 0
select 	@xlin = isnull( (select min(row_id) from rtv_list
						where rtv_no=@rtv and row_id >@xlin), 0 )

WHILE @xlin > 0 BEGIN

	select 	@txcode = tax_code,
 			@origqty = qty_ordered,
			@qty = (qty_ordered * conv_factor ),
			@price = (curr_cost),
			@disc = 0
	from 	rtv_list
 	where 	rtv_no=@rtv and row_id=@xlin

	select @exprice = Round( ( @origqty * @price ), @precision )
	select @err = -1


        insert #TXLineInput_ex (control_number,
          reference_number, currency_code, curr_precision, 
          tax_code, qty, unit_price, extended_price, seqid)
        select @controlnum,@xlin, @curr_code, 
          case when @calc_method = '2' then 8 else @precision end, 					-- mls 9/22/03 #1
          @txcode, @qty,@price, @exprice, @xlin

	if @@error <> 0 begin
	 if @rtntype = 0 begin
	 	select @err = -2
	 	return
	 	end
	 else begin
	 	return @err
	 	end
	end

	select	@xlin = isnull( (select min(row_id) from rtv_list
	where	rtv_no = @rtv and
			row_id>@xlin), 0 )
END

declare @freight decimal(20,8), @hdr_code varchar(8)
select @freight = freight,
@hdr_code = tax_code
from rtv_all where rtv_no = @rtv

if isnull(@hdr_code,'') != ''
begin
    insert #TXLineInput_ex (control_number,
      reference_number, trx_type, currency_code, curr_precision, 
      tax_code, freight, action_flag, seqid)
    select @controlnum, 0, 1, @curr_code, 
      case when @calc_method = '2' then 8 else @precision end, 					-- mls 9/22/03 #1
      @hdr_code, @freight, 1, 0

    if @@error <> 0 
    begin
	 select -4
	 return
    end
  end												-- mls 12/20/00 SCR 24853 end

  insert #txconnlineinput
  (doccode,	no, 		oriaddressline1,	oriaddressline2,	oriaddressline3,
  oricity,	oriregion,	oripostalcode,		oricountry,		destaddressline1,
  destaddressline2,		destaddressline3,	destcity,		destregion,
  destpostalcode,		destcountry,		qty,			amount,
  discounted,			exemptionno,		itemcode,		ref1,
  ref2,				revacct,		taxcode	)
  select
    TLI.control_number, TLI.reference_number,
	CHI.oriaddressline1, CHI.oriaddressline2, CHI.oriaddressline3,
	CHI.oricity, CHI.oriregion, CHI.oripostalcode, CHI.oricountry, 
	CHI.destaddressline1,CHI.destaddressline2, CHI.destaddressline3, 
	CHI.destcity, CHI.destregion, CHI.destpostalcode,CHI.destcountry,
	TLI.qty, TLI.extended_price, 
    case when amt_discount <> 0 then 1 else 0 end, CHI.exemptionno, 
    case when TLI.reference_number = 0 then '' else l.part_no end, '','', '', TLI.tax_code
  from #TXLineInput_ex TLI
  join #txconnhdrinput CHI on CHI.doccode = TLI.control_number
  left outer join rtv_list l on l.rtv_no = @rtv and l.row_id = TLI.reference_number


select @err = -2

exec @err = TXCalculateTax_SP @debug, 1 -- distr_call

if @err <> 1 begin
	if @err >= 0 select @err = -6
	return
end

declare @total_tax decimal(20,8), @non_included_tax decimal(20,8), @included_tax decimal(20,8)

select @total_tax=0, @non_included_tax=0, @included_tax=0

exec TXGetTotal_SP @controlnum, @total_tax output, @non_included_tax output, @included_tax output, @calc_method,	-- mls 9/22/03 #1
  1 -- distr_call

Update 	rtv_all
set		tax_amt =@total_tax,
  amt_tax_included = @included_tax	,			-- mls 7/1/04 SCR 33107
  tax_valid_ind = 1
where 	rtv_no= @rtv

Update	r set total_tax=ti.calc_tax,
  taxable = case when tc.tax_included_flag = 1 then 0 else 1 end       
from 	rtv_list r, #TXLineInput_ex ti, #TXtaxcode tc
where	r.rtv_no =@rtv and r.row_id=ti.reference_number
  and   tc.tax_code = ti.tax_code and tc.control_number = ti.control_number

if @debug > 0 
begin
  print 'taxinfo'
  select * from #TXLineInput_ex
  print 'taxcode'
  select * from #TXtaxcode
  print 'taxtyperec'
  select * from #TXtaxtyperec
  print 'taxtype'
  select * from #TXtaxtype
end

drop table #TXLineInput_ex
drop table #TXtaxcode
drop table #TXtaxtype
drop table #TXtaxtyperec

return
GO
GRANT EXECUTE ON  [dbo].[fs_calculate_rtvtax] TO [public]
GO
