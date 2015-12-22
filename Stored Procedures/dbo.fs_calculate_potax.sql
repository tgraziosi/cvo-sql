SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[fs_calculate_potax] @po varchar(16),  @err int OUT,
  @debug int = 0
AS
set nocount on

declare @calc_method char(1)									-- mls 9/22/03 #1


declare @controlnum char(16), @curr_code char(8), @hstat char(1)
declare @precision int, @xlin int, @price decimal(20,8), @exprice decimal(20,8), @qty decimal(20,8)
declare @txcode char(8), @disc decimal(20,8), @origqty decimal(20,8)
declare @tax_companycode varchar(255), @orders_org_id varchar(30)

select @controlnum=@po

select @curr_code = curr_key, @hstat = status,
  @orders_org_id = organization_id
	from purchase_all
	where po_no=@po

select @precision = isnull( (select curr_precision from glcurr_vw
				where glcurr_vw.currency_code=@curr_code), 1.0 )

select @calc_method = isnull((select Upper(substring(value_str,1,1)) from config (nolock)	-- mls 9/22/03 #1
  where flag = 'PO_TAX_CALC_MTHD'),'1')

UPDATE purchase_all
SET tax_valid_ind = 0
WHERE po_no = @po

select @tax_companycode = isnull((select tc_companycode 
  from Organization_all (nolock) where organization_id = @orders_org_id),'')

insert #txconnhdrinput
(doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,
discount, purchaseorderno, customercode, customerusagetype, detaillevel,
referencecode, oriaddressline1, oriaddressline2, oriaddressline3,
oricity, oriregion, oripostalcode, oricountry, destaddressline1,
destaddressline2, destaddressline3, destcity, destregion, destpostalcode,
destcountry, currCode, currRate)
select @po, 2, 
4091, @tax_companycode, getdate(), '', '',
0, '', o.vendor_no, '', 3, '', 
case when isnull(o.one_time_vend_ind,0) = 1 then o.vendor_addr2 else v.addr1 end,
case when isnull(o.one_time_vend_ind,0) = 1 then o.vendor_addr3 else v.addr2 end,
case when isnull(o.one_time_vend_ind,0) = 1 then o.vendor_addr4 else v.addr3 end,
case when isnull(o.one_time_vend_ind,0) = 1 then o.vendor_city else v.city end,
case when isnull(o.one_time_vend_ind,0) = 1 then o.vendor_state else v.state end,
case when isnull(o.one_time_vend_ind,0) = 1 then o.vendor_zip else v.postal_code end,
case when isnull(o.one_time_vend_ind,0) = 1 then o.vendor_country_cd else v.country_code end,
o.ship_address1, o.ship_address2, o.ship_address3,o.ship_city, o.ship_state,
o.ship_zip, o.ship_country_cd,  o.curr_key, o.curr_factor
from purchase_all o
join apmaster_all v on v.vendor_code = o.vendor_no and v.address_type = 0
join locations_all l on l.location = o.location
 where o.po_no = @po

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

select @xlin = 0
select @xlin = isnull( (select min(line) from pur_list
                        where po_no=@po and
                        line>@xlin), 0 )

WHILE @xlin > 0 BEGIN

	select 	@txcode = tax_code,
                @origqty = qty_ordered,
                @qty   = (qty_ordered * conv_factor ), 
		@price = (curr_cost),
                @disc = 0
		from pur_list 
                where po_no=@po and line=@xlin

	select @exprice = Round( ( @origqty * @price ), @precision )
	select @err = -1

        insert #TXLineInput_ex (control_number,
          reference_number, currency_code, curr_precision, 
          tax_code, qty, unit_price, extended_price, seqid)
        select @controlnum,@xlin, @curr_code, 
          case when @calc_method = '2' then 8 else @precision end, 					-- mls 9/22/03 #1
          @txcode, @qty,@price, @exprice, @xlin

	if @@error <> 0 begin
	      select @err = -2
              return
	end

	select @xlin = isnull( (select min(line) from pur_list
                        where po_no=@po and
                        line>@xlin), 0 )
END

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
	l.addr1,l.addr2,l.addr3,l.city,l.state,l.zip, l.country_cd,
	TLI.qty, TLI.extended_price, 
    case when amt_discount <> 0 then 1 else 0 end, CHI.exemptionno, l.part_no, '','', '', TLI.tax_code
  from #TXLineInput_ex TLI
  join #txconnhdrinput CHI on CHI.doccode = TLI.control_number
  join pur_list l on l.po_no = @po and l.line = TLI.reference_number


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


Update purchase_all set total_tax=@total_tax,
tax_valid_ind = 1
where po_no=@po


Update p set total_tax=ti.calc_tax,
  taxable = case tc.tax_included_flag when 1 then 0 else 1 end
 FROM pur_list p, #TXLineInput_ex ti, #TXtaxcode tc
 WHERE p.po_no = @po and p.line = ti.reference_number
   and tc.tax_code = ti.tax_code

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


select @err = 1
return
GO
GRANT EXECUTE ON  [dbo].[fs_calculate_potax] TO [public]
GO
