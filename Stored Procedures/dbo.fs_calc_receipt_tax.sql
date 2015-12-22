SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[fs_calc_receipt_tax] @po varchar(16),@po_line int, @txcode varchar(8),@qty decimal(20,8),
@price decimal(20,8), @tax decimal(20,8) OUT, @nonrec_tax decimal(20,8) OUT, @debug int = 0
AS

declare @controlnum char(16), @curr_code char(8), @hstat char(1)
declare @precision int, @xlin int, @exprice decimal(20,8)
declare @disc decimal(20,8), @err int
declare @total_tax decimal(20,8), @non_included_tax decimal(20,8), @included_tax decimal(20,8)
declare @calc_method char(1)									-- mls 9/22/03 31913
declare @tax_companycode varchar(255), @orders_org_id varchar(30)

if exists (select 1 from artax (nolock) where tax_code = @txcode and tax_included_flag = 0) 
begin
  if (select sum(c.prc_flag + c.amt_tax + c.vat_flag + isnull(c.tax_connect_flag,0))
     from artaxdet b (nolock)
     join artxtype c (nolock) on c.tax_type_code = b.tax_type_code
     where b.tax_code = @txcode) = 0
  begin
    select @tax = 0
    select @nonrec_tax = 0
    return 1
  end 
end												


select @controlnum=@po

select @curr_code = curr_key, @hstat = status,
  @orders_org_id = organization_id
	from purchase_all
	where po_no=@po

select @precision = isnull( (select curr_precision from glcurr_vw
				where glcurr_vw.currency_code=@curr_code), 1.0 )

select @calc_method = isnull((select Upper(substring(value_str,1,1)) from config (nolock)	-- mls 9/22/03 31913
  where flag = 'PO_TAX_CALC_MTHD'),'1')

select @tax_companycode = isnull((select tc_companycode 
  from Organization_all (nolock) where organization_id = @orders_org_id),'')

select @disc    = 0
select @exprice = Round( ( @qty * @price ), @precision )
select @err     = -1
select @xlin    = 1

insert #TXLineInput_ex (control_number,
  reference_number, trx_type, currency_code, curr_precision, 
  tax_code, qty, unit_price, extended_price, seqid)
select @controlnum,@xlin, 0, @curr_code,
case when @calc_method = '2' then 8 else @precision end, 					-- mls 9/22/03 31913
@txcode,@qty,@price, @exprice, @xlin

if @@error <> 0    
 BEGIN
   select @tax = -1
   return 
 END

insert #txconnhdrinput
(doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,
discount, purchaseorderno, customercode, customerusagetype, detaillevel,
referencecode, oriaddressline1, oriaddressline2, oriaddressline3,
oricity, oriregion, oripostalcode, oricountry, destaddressline1,
destaddressline2, destaddressline3, destcity, destregion, destpostalcode,
destcountry,  currCode, currRate, currRateDate, locCode, paymentDt, taxOverrideReason,
taxOverrideAmt, taxOverrideDate, taxOverrideType, commitInd)
select @controlnum, 2, 
4091, @tax_companycode, getdate(), '', '',
0, '', p.vendor_no, '', 3, '', 
case when isnull(p.one_time_vend_ind,0) = 1 then vendor_addr2 else v.addr2 end,
case when isnull(p.one_time_vend_ind,0) = 1 then vendor_addr3 else v.addr3 end,
case when isnull(p.one_time_vend_ind,0) = 1 then vendor_addr4 else v.addr4 end,
case when isnull(p.one_time_vend_ind,0) = 1 then vendor_city else v.city end,
case when isnull(p.one_time_vend_ind,0) = 1 then vendor_state else v.state end,
case when isnull(p.one_time_vend_ind,0) = 1 then vendor_zip else v.postal_code end,
case when isnull(p.one_time_vend_ind,0) = 1 then vendor_country_cd else v.country_code end,
l.addr1,l.addr2,l.addr3,l.city,l.state,l.zip, l.country_code,
p.curr_key, p.curr_factor, getdate(), '', NULL,
'', 0.0, NULL, 2, 0
from purchase_all p (nolock) 
join apmaster_all v on v.vendor_code = p.vendor_no
join pur_list pl on pl.po_no = p.po_no and pl.line = @po_line
join locations_all l on l.location = pl.receiving_loc
 where p.po_no = convert(varchar,@controlnum)

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
  join pur_list l on l.po_no = @po and l.line = @po_line



select @err = -2
exec @err = TXCalculateTax_SP @debug, 1 -- distr_call

if @err <> 1 
begin
if @err >= 0 select @err = -6
  return
end


declare @total_nonr_tax decimal(20,8), @nonr_not_included_tax decimal(20,8), @nonr_included_tax decimal(20,8),
  @nonr_freight_tax decimal(20,8), @not_included_tax decimal(20,8)

select @total_tax=0, @not_included_tax=0, @included_tax=0

exec TXCalRecNonRecTotTax_sp  @controlnum, 
  @total_tax output, @not_included_tax output, @included_tax output, 
  @total_nonr_tax output, @nonr_not_included_tax output, @nonr_included_tax output, 
  @nonr_freight_tax output,  @calc_method	-- mls 9/22/03 31913





select @tax = @included_tax + @nonr_included_tax
select @nonrec_tax = @nonr_not_included_tax + @nonr_included_tax
return @err

GO
GRANT EXECUTE ON  [dbo].[fs_calc_receipt_tax] TO [public]
GO
