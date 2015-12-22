SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
  
CREATE PROCEDURE [dbo].[fs_calculate_matchtax] @match_id int, @err int out, @online_call int = 0,   
@doctype int = 2, @trx_ctrl_num varchar(16) = '',  @debug int = 0 AS  
  
  
  
  
  
  
declare @cpi_count int  
declare @controlnum char(16), @curr_code char(8)   
declare @precision int, @xlin int, @price decimal(20,8), @exprice decimal(20,8), @qty decimal(20,8)  
declare @txcode char(8), @disc decimal(20,8),  @trx_type int  
declare @po_no varchar(16), @po_tax_code varchar(8), @freight decimal(20,8)   -- mls 12/20/00 SCR 24853  
declare @discount decimal(20,8), @gross decimal(20,8)      -- mls 12/20/00 SCR 24854  
declare @origqty decimal(20,8)          -- mls 11/22/02 SCR 30352  
declare @calc_method char(1)         -- mls 9/22/03 31913  
declare @tax_companycode varchar(255), @orders_org_id varchar(30)  
declare @tax_adj_incl decimal(20,8), @tax_adj_not_incl decimal(20,8)  
declare @tax_nr_adj_incl decimal(20,8), @tax_nr_adj_not_incl decimal(20,8), @tax_nr_adj_frt decimal(20,8)  
declare @tax_tot decimal(20,8), @tax_amt decimal(20,8)  
  
select @controlnum=  
  case when @doctype = 3 then @trx_ctrl_num else convert(varchar(16),@match_id) end  
  
select @calc_method = isnull((select Upper(substring(value_str,1,1)) from config (nolock) -- mls 9/22/03 31913  
  where flag = 'PO_TAX_CALC_MTHD'),'2')  
  
if @online_call = 1  
begin  
  
create table #temp (reference_number int, amt_tax decimal(20,8),   
    amt_tax_included decimal(20,8),  
    calc_tax decimal(20,8), tax_included int, non_recoverable_tax decimal(20,8),   
    non_rec_frt_tax decimal(20,8), non_rec_incl_tax decimal(20,8))  
  
select top 1 @orders_org_id = organization_id   
from #online_taxinfo where  control_number = @match_id  
and reference_number = 0  and organization_id is not null and trx_type between 0 and 2  
      
select @tax_companycode = isnull((select tc_companycode   
  from Organization_all (nolock) where organization_id = @orders_org_id),'')  
  
  
  set @debug = 0  
  select TOP 1 @precision = curr_precision  
  from #online_taxinfo  
  where control_number = @match_id and tax_code <> '' and tax_code <> '*'   
  and reference_number > 0 and trx_type between 0 and 2  
  
  select @cpi_count = count(distinct tax_code), @txcode=min(tax_code)       -- mls 5/26/09  
  from #online_taxinfo  
  where control_number = @match_id and tax_code <> '' and tax_code <> '*'   
  and reference_number > 0 and trx_type between 0 and 2  
  
  select @po_tax_code = isnull((select tax_code           
  from #online_taxinfo  
  where control_number = @match_id and tax_code <> '' and tax_code <> '*'    
  and reference_number = 0 and trx_type = 1),'')  
  
  if @txcode <> @po_tax_code                 -- mls 5/26/09  
    select @cpi_count = @cpi_count + 1  
  
  insert #TXLineInput_ex (control_number,  
    reference_number, trx_type, currency_code, curr_precision,   
    tax_code, freight, action_flag, seqid)  
  select control_number,reference_number, trx_type, currency_code,   
    case when @calc_method = '2' then 8 else curr_precision end,  
    tax_code, freight, 1, 0  
  from #online_taxinfo  
  where control_number = @match_id and tax_code <> '' and tax_code <> '*'    
  and reference_number = 0 and freight > 0 and trx_type = 1  
  
  insert #TXLineInput_ex (control_number,  
    reference_number, trx_type, currency_code, curr_precision,   
    tax_code, qty, unit_price, extended_price,  
    amt_discount, seqid)  
  select control_number,reference_number, trx_type, currency_code,   
    case when @calc_method = '2' then 8 else curr_precision end,  
    tax_code, qty,unit_price, round((qty * unit_price), curr_precision), 0, seqid  
  from #online_taxinfo  
  where control_number = @match_id and tax_code <> '' and tax_code <> '*'   
  and reference_number > 0 and trx_type between 0 and 2  
  
  if @@error <> 0   
  begin  
    select @err = -2  
    return  
  end  
  
  select @discount = isnull((select amt_discount from #online_taxinfo   
    where control_number = @match_id and reference_number = 0 and trx_type = 1),0)  
  
  if @discount <> 0    begin  
    select @gross = sum(extended_price)  
    from #online_taxinfo   
    where control_number = @match_id and reference_number > 0 and trx_type between 0 and 2  
   
    update #TXLineInput_ex  
    set amt_discount =  @discount * extended_price / @gross   
    where reference_number > 0   
  end             
  
  insert #txconnhdrinput  
  (doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,  
  discount, purchaseorderno, customercode, customerusagetype, detaillevel,  
  referencecode, oriaddressline1, oriaddressline2, oriaddressline3,  
  oricity, oriregion, oripostalcode, oricountry, destaddressline1,  
  destaddressline2, destaddressline3, destcity, destregion, destpostalcode,  
  destcountry, currCode, currRate, currRateDate, locCode, paymentDt, taxOverrideReason,  
  taxOverrideAmt, taxOverrideDate, taxOverrideType, commitInd)  
  select @controlnum, @doctype,  
    o.tax_trx_type, @tax_companycode, getdate(), '', '',  
    @discount, '', o.vendor_code, '', 3, '',   
    case when isnull(o.one_time_vend_ind,0) = 1 then o.addr1 else v.addr2 end,  
    case when isnull(o.one_time_vend_ind,0) = 1 then o.addr2 else v.addr3 end,  
    case when isnull(o.one_time_vend_ind,0) = 1 then o.addr3 else v.addr4 end,  
    case when isnull(o.one_time_vend_ind,0) = 1 then o.city else v.city end,  
    case when isnull(o.one_time_vend_ind,0) = 1 then o.state else v.state end,  
    case when isnull(o.one_time_vend_ind,0) = 1 then o.zip else v.postal_code end,  
    case when isnull(o.one_time_vend_ind,0) = 1 then o.country else v.country_code end,  
    l.addr1,l.addr2,l.addr3,l.city,l.state,l.zip, l.country_code,  
    o.currency_code, o.currRate, getdate(), '', NULL,  
    '', 0.0, NULL, 2, 0  
  from #online_taxinfo o  
  join apmaster_all v on v.vendor_code = o.vendor_code and v.address_type = 0  
  join locations_all l on l.location = o.location  
  where o.control_number = @match_id and trx_type = 2  
  
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
  
  if @cpi_count = 1                    -- mls 5/26/09  
  and exists (select 1 from artax (nolock) where tax_code = @txcode and tax_included_flag = 0)   
  begin  
    if (select sum(c.prc_flag + c.amt_tax + c.vat_flag + isnull(c.tax_connect_flag,0))  
       from artaxdet b (nolock), artxtype c (nolock)  
       where b.tax_code = @txcode and c.tax_type_code = b.tax_type_code) = 0  
    begin  
      insert #txconnlineinput  
        (doccode, no,   oriaddressline1, oriaddressline2, oriaddressline3,  
        oricity, oriregion, oripostalcode,  oricountry,  destaddressline1,  
        destaddressline2,  destaddressline3, destcity,  destregion,  
        destpostalcode,  destcountry,  qty,   amount,  
        discounted,   exemptionno,    ref1,  
        ref2,   revacct,  taxcode , itemcode)  
      select  
        TLI.control_number, TLI.reference_number, h.oriaddressline1, h.oriaddressline2, h.oriaddressline3,  
        h.oricity, h.oriregion, h.oripostalcode, h.oricountry, h.destaddressline1,  
        h.destaddressline2, h.destaddressline3, h.destcity, h.destregion, h.destpostalcode,  
        h.destcountry,  TLI.qty, TLI.extended_price,   
        case when TLI.amt_discount <> 0 then 1 else 0 end, h.exemptionno, '','', '', TLI.tax_code,  
  case when TLI.reference_number > 0 then oti.part_no else '' end  
      from #TXLineInput_ex TLI  
      join #txconnhdrinput h on TLI.control_number = h.doccode  
   join #online_taxinfo oti on oti.control_number = TLI.control_number and oti.reference_number = TLI.reference_number  
        and oti.trx_type between 0 and 2  
  
      update #online_taxinfo  
      set trx_type = -2  
      where control_number = @match_id and trx_type = -1  
  
      insert #online_taxinfo  
      (control_number, reference_number, trx_type, tax_code, unit_price, extended_price, amt_tax, amt_final_tax,  
       calc_tax,amt_tax_included, non_recoverable_tax, non_rec_incl_tax, non_rec_frt_tax, action_flag)  
      select @match_id,0, -1, min(b.tax_type_code),  
      sum( round((a.qty * a.unit_price), a.curr_precision)),  
      sum( round((a.qty * a.unit_price), a.curr_precision)), 0, 0, 0,0,0,0,0,1  
      from #online_taxinfo a  
      join artaxdet b (nolock) on a.tax_code = b.tax_code  
      where a.control_number = @match_id and a.tax_code <> '' and a.tax_code <> '*'   
      and a.reference_number > 0 and a.trx_type between 0 and 2  
  
      delete #online_taxinfo  
      where control_number = @match_id and trx_type = -2  
  
      delete from #online_taxinfo   
      where control_number = @match_id and trx_type = 3  
    
      insert #temp  
      select 0,  0, 0, 0, 0,0, 0, 0  
  
      insert #temp  
      select reference_number, 0, 0, 0, 0,0, 0, 0  
      from #online_taxinfo  
      where control_number = @match_id and tax_code <> '' and tax_code <> '*'   
      and reference_number > 0 and trx_type between 0 and 2  
  
     insert #online_taxinfo  
     (control_number, reference_number, trx_type, amt_tax, amt_tax_included,  
     calc_tax, tax_included, non_recoverable_tax, non_rec_frt_tax,  
     non_rec_incl_tax)  
     select @match_id, reference_number, 3, amt_tax, amt_tax_included,  
     calc_tax, tax_included, non_recoverable_tax, non_rec_frt_tax,  
     non_rec_incl_tax  
     from #temp    
  
  insert #TXTaxOutput (control_number, amtTotal, amtDisc, amtExemption, amtTax, remoteDocId)  
     select control_number, extended_price, 0, 0, 0,0  
     from #online_taxinfo where control_number = @match_id and trx_type = -1   
  
     insert #TXTaxLineOutput (control_number, reference_number,t_index, taxRate,taxable,taxCode,  
       taxability, amtTax, amtDisc, amtExemption, taxDetailCnt)  
     select control_number, reference_number, 0, 0,   
    case when reference_number = 0 then freight else  round((qty * unit_price), curr_precision) end,  
    tax_code, 'True', 0, 0, 0, 0  
     from #online_taxinfo   
      where control_number = @match_id and tax_code <> '' and tax_code <> '*'   
      and reference_number >= 0 and trx_type between 0 and 2  
  
     insert #TXTaxLineDetOutput (control_number, reference_number,t_index, d_index, amtBase, exception,  
       jurisCode, jurisName, jurisType, nonTaxable, taxRate, amtTax, taxable, taxType)  
     select a.control_number, a.reference_number, 0, 0,   
      case when a.reference_number = 0 then a.freight else  round((a.qty * a.unit_price), a.curr_precision) end,  
     0, '-1',b.tax_type_code,'-1', 0, 0, 0,   
     case when a.reference_number = 0 then a.freight else  round((a.qty * a.unit_price), a.curr_precision) end, 1  
     from #online_taxinfo a  
      join artaxdet b (nolock) on a.tax_code = b.tax_code  
      where control_number = @match_id and a.tax_code <> '' and a.tax_code <> '*'   
      and a.reference_number >= 0 and a.trx_type between 0 and 2  
  
      select @err = 1  
      return  
    end   
  end              
  insert #txconnlineinput  
    (doccode, no,   oriaddressline1, oriaddressline2, oriaddressline3,  
    oricity, oriregion, oripostalcode,  oricountry,  destaddressline1,  
    destaddressline2,  destaddressline3, destcity,  destregion,  
    destpostalcode,  destcountry,  qty,   amount,  
    discounted,   exemptionno,  itemcode,  ref1,  
    ref2,   revacct,  taxcode )  
  select  
    TLI.control_number, TLI.reference_number, h.oriaddressline1, h.oriaddressline2, h.oriaddressline3,  
    h.oricity, h.oriregion, h.oripostalcode, h.oricountry, h.destaddressline1,  
    h.destaddressline2, h.destaddressline3, h.destcity, h.destregion, h.destpostalcode,  
    h.destcountry,  TLI.qty, TLI.extended_price,   
    case when TLI.amt_discount <> 0.0 then 1.0 else 0.0 end, h.exemptionno,   
    case when TLI.reference_number > 0.0 then oti.part_no else '' end, '','', '', TLI.tax_code  
  from #TXLineInput_ex TLI  
  join #txconnhdrinput h on TLI.control_number = h.doccode  
  join #online_taxinfo oti on oti.control_number = TLI.control_number and oti.reference_number = TLI.reference_number  
    and oti.trx_type between 0 and 2  
  where not exists (select 1 from #txconnlineinput l where l.doccode = TLI.control_number  
    and l.no = TLI.reference_number)  
end  
  
if @online_call in ( 0,3)  
begin  
  select @cpi_count = count(distinct tax_code), @txcode=min(tax_code)       -- mls 5/26/09  
  from adm_pomchcdt  
  where match_ctrl_int = @match_id  
  
 UPDATE adm_pomchchg_all  
  SET tax_valid_ind = 0  
  WHERE match_ctrl_int = @match_id  
  
  select @curr_code = nat_cur_code,  
    @trx_type  = trx_type,  
    @freight = amt_freight,         -- mls 12/20/00 SCR 24853  
    @discount = amt_discount,        -- mls 12/20/00 SCR 24854  
    @gross = amt_gross,         -- mls 12/20/00 SCR 24854  
    @po_no = convert(varchar(16), po_no),       -- mls 12/20/00 SCR 24853  
    @po_tax_code = tax_code,         -- mls  7/27/03 SCR 29285  
   @orders_org_id = organization_id   
  from adm_pomchchg_all  
  where match_ctrl_int = @match_id  
  
  select @tax_companycode = isnull((select tc_companycode   
    from Organization_all (nolock) where organization_id = @orders_org_id),'')  
  
  if isnull(@po_tax_code,'') = ''  
    select @po_tax_code = isnull((select tax_code from purchase_all where po_no = @po_no),'')  -- mls 12/20/00 SCR 24853  
  
  if @txcode <> @po_tax_code                 -- mls 5/26/09  
    select @cpi_count = @cpi_count + 1  
  
  select @precision = isnull( (select curr_precision from glcurr_vw  
    where glcurr_vw.currency_code=@curr_code), 1.0 )  
  
  insert #txconnhdrinput  
  (doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,  
  discount, purchaseorderno, customercode, customerusagetype, detaillevel,  
  referencecode, oriaddressline1, oriaddressline2, oriaddressline3,  
  oricity, oriregion, oripostalcode, oricountry, destaddressline1,  
  destaddressline2, destaddressline3, destcity, destregion, destpostalcode,  
  destcountry, currCode, currRate, currRateDate, locCode, paymentDt, taxOverrideReason,  
  taxOverrideAmt, taxOverrideDate, taxOverrideType, commitInd)  
  select @controlnum, @doctype,  
  o.trx_type, @tax_companycode, getdate(), '', '',  
  amt_discount, '', o.vendor_code, '', 3, '',   
  case when isnull(o.one_time_vend_ind,0) = 1 then pay_to_addr2 else v.addr2 end,  
  case when isnull(o.one_time_vend_ind,0) = 1 then pay_to_addr3 else v.addr3 end,  
  case when isnull(o.one_time_vend_ind,0) = 1 then pay_to_addr4 else v.addr4 end,  
  case when isnull(o.one_time_vend_ind,0) = 1 then pay_to_city else v.city end,  
  case when isnull(o.one_time_vend_ind,0) = 1 then pay_to_state else v.state end,  
  case when isnull(o.one_time_vend_ind,0) = 1 then pay_to_zip else v.postal_code end,  
  case when isnull(o.one_time_vend_ind,0) = 1 then pay_to_country_cd else v.country_code end,  
  l.addr1,l.addr2,l.addr3,l.city,l.state,l.zip, l.country_code,  
    o.nat_cur_code, o.curr_factor, getdate(), '', NULL,  
    '', 0.0, NULL, 2, 0  
  from adm_pomchchg_all o  
  join apmaster_all v on v.vendor_code = o.vendor_code and v.address_type = 0  
  join locations_all l on l.location = o.location  
  where o.match_ctrl_int = @match_id  
  
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
      tax_code, qty, unit_price, extended_price,  
      amt_discount, seqid)  
    select @controlnum,match_line_num, 0, @curr_code,   
      case when @calc_method = '2' then 8 else @precision end,      -- mls 9/22/03 31913  
      tax_code,  ( qty_invoiced * conv_factor),curr_cost, Round( ( qty_invoiced * curr_cost ), @precision ), 0, match_line_num  
    from adm_pomchcdt   
    where match_ctrl_int = @match_id  
  
    if @@error <> 0   
    begin  
      select @err = -2  
      return  
    end  
    
  if  @po_tax_code != ''       -- mls 12/20/00 SCR 24853 start  
  begin  
    select @err = -2  
    insert #TXLineInput_ex (control_number,  
      reference_number, trx_type, currency_code, curr_precision,   
      tax_code, freight, action_flag, seqid)  
    select @controlnum, 0, 1, @curr_code,   
      case when @calc_method = '2' then 8 else @precision end,      -- mls 9/22/03 31913  
      @po_tax_code,  @freight, 1, 0  
  
    if @@error <> 0   
    begin  
      select -4  
      return  
    end  
  end            -- mls 12/20/00 SCR 24853 end  
  
  if @cpi_count = 1                    -- mls 5/26/09  
  and exists (select 1 from artax (nolock) where tax_code = @txcode and tax_included_flag = 0)   
  begin  
  
    if (select sum(c.prc_flag + c.amt_tax + c.vat_flag + isnull(c.tax_connect_flag,0))  
       from artaxdet b (nolock), artxtype c (nolock)  
       where b.tax_code = @txcode and c.tax_type_code = b.tax_type_code) = 0  
    begin  
  
      UPDATE adm_pomchchg_all  
      SET   
      amt_tax          = 0,  
      amt_tax_included = 0,  
      amt_due          = amt_gross - amt_discount + amt_freight + amt_misc,  
      amt_net          = amt_gross - amt_discount + amt_freight + amt_misc,  
      tax_freight_no_recoverable = 0,  
      amt_nonrecoverable_tax = 0,  
      amt_nonrecoverable_incl_tax = 0,  
   tax_valid_ind = 1  
      WHERE match_ctrl_int = @match_id  
  and (isnull(amt_tax,1) != 0 or   
          isnull(amt_tax_included,1) != 0 or   
          isnull(amt_due,0) != amt_gross - amt_discount + amt_freight + amt_misc or   
          isnull(amt_net,0) != amt_gross - amt_discount + amt_freight + amt_misc or   
          isnull(tax_freight_no_recoverable,1) != 0 or   
          isnull(amt_nonrecoverable_tax,1) != 0 or   
          isnull(amt_nonrecoverable_incl_tax,1) != 0 or   
          isnull(tax_valid_ind,0) != 1 )  
  
      UPDATE adm_pomchcdt   
      SET amt_tax_included = 0,  
      amt_tax = 0,  
      amt_nonrecoverable_tax = 0,  
      amt_tax_det = 0,  
      calc_tax = 0  
      WHERE match_ctrl_int = @match_id  
  and (isnull(amt_tax,1) != 0 or   
          isnull(amt_tax_included,1) != 0 or   
          isnull(amt_nonrecoverable_tax,1) != 0 or   
          isnull(amt_tax_det,1) != 0 or   
          isnull(calc_tax,1) != 0 )  
  
      DELETE adm_pomchtaxdtl where match_ctrl_int = @match_id  
      DELETE adm_pomchtax    where match_ctrl_int = @match_id  
  
      INSERT INTO adm_pomchtax (  
      match_ctrl_int, sequence_id, tax_type_code,  
      amt_taxable,  amt_gross, amt_tax,  
      amt_final_tax)  
      select @match_id,1, min(b.tax_type_code),  
      sum(round(qty_invoiced * curr_cost,@precision)),  
      sum(round(qty_invoiced * curr_cost,@precision)), 0, 0  
      from adm_pomchcdt  a  
      join artaxdet b (nolock) on a.tax_code = b.tax_code  
      where a.match_ctrl_int = @match_id  
  
  if @online_call = 3  
  begin  
      insert #txconnlineinput  
        (doccode, no,   oriaddressline1, oriaddressline2, oriaddressline3,  
        oricity, oriregion, oripostalcode,  oricountry,  destaddressline1,  
        destaddressline2,  destaddressline3, destcity,  destregion,  
        destpostalcode,  destcountry,  qty,   amount,  
        discounted,   exemptionno,  itemcode,  ref1,  
        ref2,   revacct,  taxcode)  
      select  
        TLI.control_number, TLI.reference_number, h.oriaddressline1, h.oriaddressline2, h.oriaddressline3,  
        h.oricity, h.oriregion, h.oripostalcode, h.oricountry, h.destaddressline1,  
        h.destaddressline2, h.destaddressline3, h.destcity, h.destregion, h.destpostalcode,  
        h.destcountry,  TLI.qty, TLI.extended_price,   
        case when TLI.amt_discount <> 0 then 1 else 0 end, h.exemptionno, isnull(m.part_no,''), '','', '', TLI.tax_code  
      from #TXLineInput_ex TLI  
      join #txconnhdrinput h on TLI.control_number = h.doccode  
   left outer join adm_pomchcdt m on m.match_ctrl_int = @match_id and m.match_line_num = TLI.reference_number  
  
  insert #TXTaxOutput (control_number, amtTotal, amtDisc, amtExemption, amtTax, remoteDocId)  
     select match_ctrl_int, amt_net, 0, 0, 0,0  
  from adm_pomchchg_all where match_ctrl_int = @match_id   
  
     insert #TXTaxLineOutput (control_number, reference_number,t_index, taxRate,taxable,taxCode,  
       taxability, amtTax, amtDisc, amtExemption, taxDetailCnt)  
     select match_ctrl_int, 0, 0, 0, amt_freight,  
    tax_code, 'True', 0, 0, 0, 0  
     from adm_pomchchg_all  
      where match_ctrl_int = @match_id  and amt_freight <> 0  
  
     insert #TXTaxLineOutput (control_number, reference_number,t_index, taxRate,taxable,taxCode,  
       taxability, amtTax, amtDisc, amtExemption, taxDetailCnt)  
     select match_ctrl_int, match_line_num, 0, 0,   
     round((qty_invoiced * curr_cost), @precision) ,  
    tax_code, 'True', 0, 0, 0, 0  
     from adm_pomchcdt   
      where match_ctrl_int = @match_id   
  
     insert #TXTaxLineDetOutput (control_number, reference_number,t_index, d_index, amtBase, exception,  
       jurisCode, jurisName, jurisType, nonTaxable, taxRate, amtTax, taxable, taxType)  
     select a.control_number, a.reference_number, 0, 0,   
      taxable,  
     0, '-1',b.tax_type_code,'-1', 0, 0, 0,   
     taxable, 1  
     from #TXTaxLineOutput a  
      join artaxdet b (nolock) on a.taxCode = b.tax_code  
      where control_number = @match_id   
  end  
  
      select @err = 1  
      return  
    end   
  end              
  
  insert #txconnlineinput  
    (doccode, no,   oriaddressline1, oriaddressline2, oriaddressline3,  
    oricity, oriregion, oripostalcode,  oricountry,  destaddressline1,  
    destaddressline2,  destaddressline3, destcity,  destregion,  
    destpostalcode,  destcountry,  qty,   amount,  
    discounted,   exemptionno,  itemcode,  ref1,  
    ref2,   revacct,  taxcode )  
  select  
    TLI.control_number, TLI.reference_number, h.oriaddressline1, h.oriaddressline2, h.oriaddressline3,  
    h.oricity, h.oriregion, h.oripostalcode, h.oricountry, h.destaddressline1,  
    h.destaddressline2, h.destaddressline3, h.destcity, h.destregion, h.destpostalcode,  
    h.destcountry,  TLI.qty, TLI.extended_price,   
    case when TLI.amt_discount <> 0 then 1 else 0 end, h.exemptionno,   
    case when TLI.reference_number > 0 then m.part_no else '' end,'','', '', TLI.tax_code  
  from #TXLineInput_ex TLI  
  join #txconnhdrinput h on TLI.control_number = h.doccode  
  left outer join adm_pomchcdt m on m.match_ctrl_int = @match_id and m.match_line_num = TLI.reference_number  
  where not exists (select 1 from #txconnlineinput l where l.doccode = TLI.control_number  
    and l.no = TLI.reference_number)  
  
end  
  
  
select @err = -3  
  
exec @err = TXCalculateTax_SP @debug, 1 -- distr_call  
  
if @err <> 1   
begin  
  if @err >= 0 select @err = -6  
    return  
end  
  
declare @total_tax decimal(20,8), @not_included_tax decimal(20,8), @included_tax decimal(20,8),  
  @total_nonr_tax decimal(20,8), @nonr_not_included_tax decimal(20,8), @nonr_included_tax decimal(20,8),  
  @nonr_freight_tax decimal(20,8)  
  
exec TXGetTotal_SP @controlnum,                 -- mls 7/12/07 SCR 36623  
  @total_tax output, @not_included_tax output, @included_tax output, @calc_method, 1  
  
select @total_tax=0, @not_included_tax=0, @included_tax=0  

/*
declare @test varchar(10)

--set @test = 'z'
--set @test = 'y'
set @test = 'a'

--select @test test into cpt_post_tracking 

select @test test into #ct

set @test = 'b'

update #ct set test = @test

select * into cpt_post_tracking from #ct
*/
exec TXCalRecNonRecTotTax_sp @controlnum,   
  @total_tax output, @not_included_tax output, @included_tax output,   
  @total_nonr_tax output, @nonr_not_included_tax output, @nonr_included_tax output,   
  @nonr_freight_tax output,  @calc_method -- mls 9/22/03 31913  
 
  
if @debug > 0  
begin  
  select  @total_tax 'total_tax', @not_included_tax 'not included tax', @included_tax 'included tax',   
    @total_nonr_tax 'total_nonr_tax', @nonr_not_included_tax 'nonr not incl tax', @nonr_included_tax 'nonr incl tax',   
    @nonr_freight_tax 'nonr freight',  @calc_method 'calc method' -- mls 9/22/03 31913  
end  
  
  
  
if @online_call = 1  
begin  
  
  update ati  
  set amt_nonrecoverable_tax = ti.amt_nonrecoverable_tax  
  from #TXLineInput_ex ati,   
    (select ti.row_id, sum(round(tt.amt_final_tax * (ti.extended_price + ti.amt_discount) / (tc.tot_extended_amt),ti.curr_precision)) -- mls 3/12/09 37755  
    from #TXLineInput_ex ti, #TXtaxcode tc, #TXtaxtyperec ttr, #TXtaxtype tt  
   where ti.tax_code  = tc.tax_code and tc.row_id = ttr.tc_row and ttr.row_id = tt.ttr_row  
      and tt.recoverable_flag = 0 and (tt.amt_taxable + tt.amt_tax_included) != 0  
    group by ti.row_id) as ti(row_id, amt_nonrecoverable_tax)  
  where ati.row_id = ti.row_id  
end  
  
update tc  
set tot_extended_amt = s.amt  
from #TXtaxcode tc,   
  (select tax_code, sum(case when action_flag = 0 then extended_price - amt_discount else freight end)  
    from #TXLineInput_ex where calc_tax != 0 group by tax_code) as s (tax_code, amt)  
where tc.tax_code = s.tax_code  
  
update ati  
set amt_nonrecoverable_tax = ti.amt_nonrecoverable_tax  
from #TXLineInput_ex ati,   
  (select ti.row_id, sum(round(tt.amt_final_tax * (ti.extended_price + ti.amt_discount) / (tc.tot_extended_amt),ti.curr_precision)) -- mls 3/12/09 37755  
  from #TXLineInput_ex ti, #TXtaxcode tc, #TXtaxtyperec ttr, #TXtaxtype tt  
  where ti.tax_code  = tc.tax_code and tc.row_id = ttr.tc_row and ttr.row_id = tt.ttr_row  
    and tt.recoverable_flag = 0 and (tt.amt_taxable + tt.amt_tax_included) != 0  
  group by ti.row_id) as ti(row_id, amt_nonrecoverable_tax)  
where ati.row_id = ti.row_id  
  
if @online_call = 1  
begin  
  update #online_taxinfo  
  set trx_type = -2  
  where control_number = @match_id and trx_type = -1  
  
  if @calc_method = '1'  -- calc and rounded at tax code  
  begin  
    insert #online_taxinfo  
    (control_number, reference_number, trx_type, tax_code, unit_price, extended_price, amt_tax, amt_final_tax,  
      calc_tax,amt_tax_included, non_recoverable_tax, non_rec_incl_tax, non_rec_frt_tax, action_flag)  
    select @match_id, 0, -1, tt.tax_type,  sum(tt.amt_gross + tt.amt_tax_included),  
      sum(tt.amt_taxable + tt.amt_tax_included),sum(tt.amt_tax),   
      sum(tt.amt_final_tax),  
      SUM(case when tt.recoverable_flag = 1 and tt.tax_included_flag = 0 then tt.amt_final_tax else 0 end),  
      SUM(case when tt.recoverable_flag = 1 and tt.tax_included_flag = 1 then tt.amt_final_tax else 0 end),  
      SUM(case when tt.recoverable_flag = 0 and tt.tax_included_flag = 0 and tt.tax_based_type != 2 then tt.amt_final_tax else 0 end),  
      SUM(case when tt.recoverable_flag = 0 and tt.tax_included_flag = 1 and tt.tax_based_type != 2 then tt.amt_final_tax else 0 end),  
      SUM(case when tt.recoverable_flag = 0 and tt.tax_based_type  = 2 then tt.amt_final_tax else 0 end),  
      tt.recoverable_flag   
 FROM #TXtaxcode tc  
    join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
    join    #TXtaxtype tt on tt.ttr_row = ttr.row_id   
 WHERE tc.control_number = @match_id   
    group by tt.tax_type, tt.recoverable_flag  
  end  
  else -- @calc_method = '2' -- calc and not rounded and summed to give total  
       -- @calc_method = '3' -- calc and rounded at line item summed to give total  
  begin  
    insert #online_taxinfo  
    (control_number, reference_number, trx_type, tax_code, unit_price, extended_price, amt_tax, amt_final_tax,  
    calc_tax,amt_tax_included, non_recoverable_tax, non_rec_incl_tax, non_rec_frt_tax, action_flag)  
    select @match_id, 0, -1,  
   ttr.tax_type,  
      sum(ti.extended_price),  
      sum(ti.extended_price),  
      sum(round(  
       case when tt.tax_included_flag = 1 then tt.amt_tax_included else ttr.cur_amt end * case when tc.tot_extended_amt = 0 then 0 else  
      ((ti.extended_price - ti.amt_discount) /tc.tot_extended_amt) end,@precision)),   
      sum(round(  
       case when tt.tax_included_flag = 1 then tt.amt_tax_included else ttr.cur_amt end * case when tc.tot_extended_amt = 0 then 0 else  
      ((ti.extended_price - ti.amt_discount)/tc.tot_extended_amt) end,@precision)),  
      sum(round(case when tt.recoverable_flag = 1 and tt.tax_included_flag = 0  
       then ttr.cur_amt * case when tc.tot_extended_amt = 0 then 0 else  
      ((ti.extended_price - ti.amt_discount)/tc.tot_extended_amt) end else 0 end,@precision)),   
      sum(round(case when tt.recoverable_flag = 1 and tt.tax_included_flag = 1  
       then tt.amt_tax_included * case when tc.tot_extended_amt = 0 then 0 else  
      ((ti.extended_price - ti.amt_discount)/tc.tot_extended_amt) end else 0 end,@precision)),   
      sum(round(case when tt.recoverable_flag = 0 and tt.tax_included_flag = 0 and tt.tax_based_type != 2   
       then ttr.cur_amt * case when tc.tot_extended_amt = 0 then 0 else  
      ((ti.extended_price - ti.amt_discount)/tc.tot_extended_amt) end else 0 end,@precision)),   
      sum(round(case when tt.recoverable_flag = 0 and tt.tax_included_flag = 1 and tt.tax_based_type != 2   
       then tt.amt_tax_included * case when tc.tot_extended_amt = 0 then 0 else  
      ((ti.extended_price - ti.amt_discount)/tc.tot_extended_amt) end else 0 end,@precision)),   
      sum(round(case when tt.recoverable_flag = 0 and tt.tax_based_type = 2   
       then case when tt.tax_included_flag = 1 then tt.amt_tax_included else ttr.cur_amt end * case when tc.tot_extended_amt = 0 then 0 else  
      ((ti.extended_price - ti.amt_discount)/tc.tot_extended_amt) end else 0 end,@precision)),  
      tt.recoverable_flag   
    from #TXLineInput_ex ti  
    join #TXtaxcode tc on tc.control_number = ti.control_number and tc.tax_code = ti.tax_code  
    join #TXtaxtyperec ttr on ttr.tc_row =tc.row_id  
    join #TXtaxtype tt on tt.ttr_row = ttr.row_id  
    where ti.action_flag = 0  
    group by ttr.tax_type, tt.recoverable_flag  
  
    insert #online_taxinfo  
    (control_number, reference_number, trx_type, tax_code, unit_price, extended_price, amt_tax, amt_final_tax,  
    calc_tax,amt_tax_included, non_recoverable_tax, non_rec_incl_tax, non_rec_frt_tax, action_flag)  
    select @match_id, 0, -1,  
   ttr.tax_type,  
      sum(ti.freight),  
      sum(ti.freight),  
      sum(round(  
       case when tt.tax_included_flag = 1 then tt.amt_tax_included else ttr.cur_amt end * case when tc.tot_extended_amt = 0 then 0 else  
      (ti.freight/tc.tot_extended_amt) end,@precision)),   
      sum(round(  
       case when tt.tax_included_flag = 1 then tt.amt_tax_included else ttr.cur_amt end * case when tc.tot_extended_amt = 0 then 0 else  
      (ti.freight/tc.tot_extended_amt) end,@precision)),  
      sum(round(case when tt.recoverable_flag = 1 and tt.tax_included_flag = 0  
       then ttr.cur_amt * case when tc.tot_extended_amt = 0 then 0 else  
      (ti.freight /tc.tot_extended_amt) end else 0 end,@precision)),   
      sum(round(case when tt.recoverable_flag = 1 and tt.tax_included_flag = 1  
       then tt.amt_tax_included * case when tc.tot_extended_amt = 0 then 0 else  
      (ti.freight /tc.tot_extended_amt) end else 0 end,@precision)),   
      sum(round(case when tt.recoverable_flag = 0 and tt.tax_included_flag = 0 and tt.tax_based_type != 2   
       then ttr.cur_amt * case when tc.tot_extended_amt = 0 then 0 else  
      (ti.freight /tc.tot_extended_amt) end else 0 end,@precision)),   
      sum(round(case when tt.recoverable_flag = 0 and tt.tax_included_flag = 1 and tt.tax_based_type != 2   
       then tt.amt_tax_included * case when tc.tot_extended_amt = 0 then 0 else  
      (ti.freight /tc.tot_extended_amt) end else 0 end,@precision)),   
      sum(round(case when tt.recoverable_flag = 0 and tt.tax_based_type = 2   
       then case when tt.tax_included_flag = 1 then tt.amt_tax_included else ttr.cur_amt end * case when tc.tot_extended_amt = 0 then 0 else  
      (ti.freight /tc.tot_extended_amt) end else 0 end,@precision)),  
      tt.recoverable_flag  
    from #TXLineInput_ex ti  
    join #TXtaxcode tc on tc.control_number = ti.control_number and tc.tax_code = ti.tax_code  
    join #TXtaxtyperec ttr on ttr.tc_row =tc.row_id  
    join #TXtaxtype tt on tt.ttr_row = ttr.row_id  
    where ti.action_flag = 1 and ti.amt_tax != 0  
    group by ttr.tax_type, tt.recoverable_flag  
  end  
  
  update o1  
  set amt_final_tax = case when o1.amt_tax = o2.amt_tax then o2.amt_final_tax else o1.amt_tax end  
  from #online_taxinfo o1  
  join #online_taxinfo o2 on o2.control_number = o1.control_number and o1.tax_code = o2.tax_code  
    and o2.trx_type = -2   
  where o1.control_number = @match_id and o1.trx_type = -1  
  
  delete #online_taxinfo  
  where control_number = @match_id and trx_type = -2  
  
  select @tax_adj_not_incl =   
    isnull((select sum(amt_final_tax - amt_tax) from  
    #online_taxinfo where control_number = @match_id and trx_type = -1 and amt_final_tax != amt_tax  
    and tax_code in (select tax_type from #TXtaxtype where tax_included_flag = 0 and recoverable_flag = 1 )),0)  
  
  select @tax_adj_incl =   
    isnull((select sum(amt_final_tax - amt_tax) from  
    #online_taxinfo where control_number = @match_id and trx_type = -1 and amt_final_tax != amt_tax  
    and tax_code in (select tax_type from #TXtaxtype where tax_included_flag = 1 and recoverable_flag = 1 ) ),0)  
  
  select @tax_nr_adj_not_incl =   
    isnull((select sum(amt_final_tax - amt_tax) from  
    #online_taxinfo where control_number = @match_id and trx_type = -1 and amt_final_tax != amt_tax  
    and tax_code in (select tax_type from #TXtaxtype where tax_included_flag = 0 and recoverable_flag = 0 )),0)  
  
  select @tax_nr_adj_incl =   
    isnull((select sum(amt_final_tax - amt_tax) from  
    #online_taxinfo where control_number = @match_id and trx_type = -1 and amt_final_tax != amt_tax  
    and tax_code in (select tax_type from #TXtaxtype where tax_included_flag = 1 and recoverable_flag = 0 ) ),0)  
  
  select @total_tax = @total_tax + @tax_adj_not_incl +@tax_adj_incl,  
    @not_included_tax = @not_included_tax + @tax_adj_not_incl,  
    @included_tax = @included_tax + @tax_adj_incl,  
    @nonr_not_included_tax = @nonr_not_included_tax + @tax_nr_adj_not_incl,  
    @nonr_included_tax = @nonr_included_tax + @tax_nr_adj_incl  
  
  insert #temp  
  select 0,  @total_tax, @included_tax + @nonr_included_tax, 0, 0,@nonr_not_included_tax, @nonr_freight_tax, @nonr_included_tax  
  
  insert #temp  
  select ti.reference_number, case when tc.tax_included_flag = 0 then (ti.calc_tax - ti.amt_nonrecoverable_tax) else 0 end,  
    case when tc.tax_included_flag = 1 then (ti.calc_tax) else 0 end,   
    ti.calc_tax, tc.tax_included_flag, isnull(ti.amt_nonrecoverable_tax,0), 0, 0  
  FROM #TXLineInput_ex ti, #TXtaxcode tc  
  WHERE tc.tax_code = ti.tax_code and tc.control_number = ti.control_number  
  and ti.reference_number > 0 AND ti.trx_type >=0  
    
  
  delete from #online_taxinfo   
  where control_number = @match_id and trx_type = 3  
  
  insert #online_taxinfo  
  (control_number, reference_number, trx_type, amt_tax, amt_tax_included,  
  calc_tax, tax_included, non_recoverable_tax, non_rec_frt_tax,  
  non_rec_incl_tax)  
  select @match_id, reference_number, 3, amt_tax, amt_tax_included,  
  calc_tax, tax_included, non_recoverable_tax, non_rec_frt_tax,  
  non_rec_incl_tax  
  from #temp    
end  
  
if @online_call in (0,3)  
begin  
  UPDATE adm_pomchcdt   
  SET amt_tax_included = case when tc.tax_included_flag = 1 then (ti.calc_tax)  else 0 end,  
    amt_tax = case when tc.tax_included_flag = 0 then (ti.calc_tax - ti.amt_nonrecoverable_tax) else 0 end,  
    amt_nonrecoverable_tax = ti.amt_nonrecoverable_tax,  
    amt_tax_det = (ti.calc_tax - ti.amt_nonrecoverable_tax),  
     calc_tax = ti.calc_tax  
  FROM #TXLineInput_ex ti, #TXtaxcode tc  
  WHERE (match_ctrl_int = @match_id AND match_line_num = ti.reference_number AND ti.control_number = @controlnum  
    and tc.tax_code = ti.tax_code and tc.control_number = ti.control_number) and   
 (isnull(adm_pomchcdt.amt_tax_included,0) != case when tc.tax_included_flag = 1 then (ti.calc_tax)  else 0 end  
     or isnull(adm_pomchcdt.amt_tax,0) != case when tc.tax_included_flag = 0 then (ti.calc_tax - ti.amt_nonrecoverable_tax) else 0 end  
     or isnull(adm_pomchcdt.amt_nonrecoverable_tax,0) != ti.amt_nonrecoverable_tax  
     or isnull(adm_pomchcdt.amt_tax_det,0) != (ti.calc_tax - ti.amt_nonrecoverable_tax)  
     or isnull(adm_pomchcdt.calc_tax,0) !=  ti.calc_tax)  
  
  update adm_pomchtax  
  set sequence_id = sequence_id * -1  
  where match_ctrl_int = @match_id  
  
  DELETE adm_pomchtax  
  WHERE match_ctrl_int = @match_id and sequence_id >= 0  
  
  if @calc_method = '1'  -- calc and rounded at tax code  
  begin  
    INSERT INTO adm_pomchtax (  
      match_ctrl_int, sequence_id, tax_type_code,  
      amt_taxable,  amt_gross, amt_tax,  
      amt_final_tax)  
    SELECT @match_id,min(tt.row_id), tt.tax_type,  
      sum(tt.amt_taxable + tt.amt_tax_included), sum(tt.amt_gross + tt.amt_tax_included), sum(tt.amt_tax),   
      sum(tt.amt_final_tax)  
    FROM #TXtaxcode tc  
    join #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
    join #TXtaxtype tt on tt.ttr_row = ttr.row_id   
    group by tt.tax_type  
  end  
  else -- @calc_method = '2' -- calc and not rounded and summed to give total  
       -- @calc_method = '3' -- calc and rounded at line item summed to give total  
  begin  
    INSERT INTO adm_pomchtax(  
      match_ctrl_int, sequence_id, tax_type_code,  
      amt_taxable,  amt_gross, amt_tax,  
      amt_final_tax)  
    select @match_id, min(tt.row_id),  
   ttr.tax_type,  
      sum(tt.amt_taxable + tt.amt_tax_included), sum(tt.amt_gross + tt.amt_tax_included),   
      sum(case when ti.action_flag = 0 then round(  
       case when tt.tax_included_flag = 1 then tt.amt_tax_included else ttr.cur_amt end * case when tc.tot_extended_amt = 0 then 0 else  
      ((ti.extended_price - ti.amt_discount )/tc.tot_extended_amt) end,@precision) else 0 end) +  
      sum(case when ti.action_flag = 1 and ti.amt_tax != 0 then round(  
       case when tt.tax_included_flag = 1 then tt.amt_tax_included else ttr.cur_amt end * case when tc.tot_extended_amt = 0 then 0 else  
      (ti.freight/tc.tot_extended_amt) end ,@precision) else 0 end),   
      sum(round(  
       case when tt.tax_included_flag = 1 then tt.amt_tax_included else ttr.cur_amt end * case when tc.tot_extended_amt = 0 then 0 else  
      (case when ti.action_flag = 0 then ti.extended_price - ti.amt_discount else ti.freight end/tc.tot_extended_amt) end,@precision))  
    from #TXLineInput_ex ti  
    join #TXtaxcode tc on tc.control_number = ti.control_number and tc.tax_code = ti.tax_code  
    join #TXtaxtyperec ttr on ttr.tc_row =tc.row_id  
    join #TXtaxtype tt on tt.ttr_row = ttr.row_id   
    group by ttr.tax_type  
  
  end  
  
  update o1  
  set amt_final_tax = case when o1.amt_tax = o2.amt_tax then o2.amt_final_tax else o1.amt_tax end  
  from adm_pomchtax o1  
  join adm_pomchtax o2 on o2.match_ctrl_int = o1.match_ctrl_int and o1.tax_type_code = o2.tax_type_code  
    and o2.sequence_id < 0  
  where o1.match_ctrl_int = @match_id and o1.sequence_id > 0  
   and o1.amt_final_tax != case when o1.amt_tax = o2.amt_tax then o2.amt_final_tax else o1.amt_tax end  
  
  delete adm_pomchtax  
  where match_ctrl_int = @match_id and sequence_id < 0  
  
  select @tax_adj_not_incl =   
    isnull((select sum(amt_final_tax - amt_tax) from  
    adm_pomchtax where match_ctrl_int = @match_id and amt_final_tax != amt_tax  
    and tax_type_code in (select tax_type from #TXtaxtype where tax_included_flag = 0 and recoverable_flag = 1 )),0)  
  
  select @tax_adj_incl =   
    isnull((select sum(amt_final_tax - amt_tax) from  
    adm_pomchtax where match_ctrl_int = @match_id and amt_final_tax != amt_tax  
    and tax_type_code in (select tax_type from #TXtaxtype where tax_included_flag = 1 and recoverable_flag = 1 ) ),0)  
  
  select @tax_nr_adj_not_incl =   
    isnull((select sum(amt_final_tax - amt_tax) from  
    adm_pomchtax where match_ctrl_int = @match_id and amt_final_tax != amt_tax  
    and tax_type_code in (select tax_type from #TXtaxtype where tax_included_flag = 0 and recoverable_flag = 0 )),0)  
  
  select @tax_nr_adj_incl =   
    isnull((select sum(amt_final_tax - amt_tax) from  
    adm_pomchtax where match_ctrl_int = @match_id and amt_final_tax != amt_tax  
    and tax_type_code in (select tax_type from #TXtaxtype where tax_included_flag = 1 and recoverable_flag = 0 ) ),0)  
  
  select @total_tax = @total_tax + @tax_adj_not_incl +@tax_adj_incl,  
    @not_included_tax = @not_included_tax + @tax_adj_not_incl,  
    @included_tax = @included_tax + @tax_adj_incl,  
    @nonr_not_included_tax = @nonr_not_included_tax + @tax_nr_adj_not_incl,  
    @nonr_included_tax = @nonr_included_tax + @tax_nr_adj_incl  
  
  UPDATE adm_pomchchg_all  
  SET amt_tax          = @total_tax,  
      amt_tax_included = @included_tax + @nonr_included_tax,  
      amt_due          = @not_included_tax + amt_gross - amt_discount + amt_freight + amt_misc + @nonr_not_included_tax + @nonr_freight_tax,  
      amt_net          = @not_included_tax + amt_gross - amt_discount + amt_freight + amt_misc + @nonr_not_included_tax + @nonr_freight_tax,  
      tax_freight_no_recoverable = @nonr_freight_tax,  
      amt_nonrecoverable_tax = @nonr_not_included_tax,  
      amt_nonrecoverable_incl_tax = @nonr_included_tax,  
   tax_valid_ind = 1  
    WHERE match_ctrl_int = @match_id  
  and (isnull(amt_tax,0) != @total_tax or   
          isnull(amt_tax_included,1) != @included_tax + @nonr_included_tax or   
          isnull(amt_due,0) != @not_included_tax + amt_gross - amt_discount + amt_freight + amt_misc + @nonr_not_included_tax + @nonr_freight_tax or  
          isnull(amt_net,0) != @not_included_tax + amt_gross - amt_discount + amt_freight + amt_misc + @nonr_not_included_tax + @nonr_freight_tax or  
          isnull(tax_freight_no_recoverable,1) != @nonr_freight_tax or   
          isnull(amt_nonrecoverable_tax,1) != @nonr_not_included_tax or   
          isnull(amt_nonrecoverable_incl_tax,1) != @nonr_included_tax or   
          isnull(tax_valid_ind,0) != 1 )  
  
  
  DELETE adm_pomchtaxdtl  
  WHERE match_ctrl_int = @match_id  
  
  INSERT INTO adm_pomchtaxdtl(  
    match_ctrl_int, sequence_id, tax_sequence_id, detail_sequence_id,  tax_type_code,  
    amt_taxable, amt_gross, amt_tax,  amt_final_tax,  recoverable_flag)  
  select @match_id, ttr.seq_id, ti.reference_number, ti.reference_number, tt.tax_type,   
    ti.extended_price + ti.amt_discount, ti.extended_price,  
    sum((tt.amt_tax ) * (ti.extended_price + ti.amt_discount) / (tc.tot_extended_amt)),  
    sum(tt.amt_final_tax * (ti.extended_price + ti.amt_discount) / (tc.tot_extended_amt)),  
    tt.recoverable_flag  
  from #TXLineInput_ex ti  
  join #TXtaxcode tc on tc.tax_code = ti.tax_code  
  join #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
  join #TXtaxtype tt on tt.ttr_row = ttr.row_id  
  where (tt.amt_taxable + tt.amt_tax_included) != 0 and (tt.amt_tax + tt.amt_tax_included + tt.amt_final_tax) != 0  
    and isnull(tt.dtl_incl_ind,0) = 1  
  group by ttr.seq_id, ti.reference_number, tt.tax_type, -- mls 2/8/08  
    ti.extended_price, ti.amt_discount, tt.recoverable_flag  
  order by ti.reference_number, tt.tax_type  
  
  if (@tax_adj_not_incl != 0 or @tax_adj_incl != 0 or @tax_nr_adj_not_incl != 0 or @tax_nr_adj_incl != 0)  
  begin  
  
    select @txcode = isnull((select min(tax_type_code) from adm_pomchtax where match_ctrl_int = @match_id  
      and amt_tax != amt_final_tax),'')  
    while @txcode != ''  
    begin  
      set @tax_amt = isnull((select sum(amt_final_tax - amt_tax) from adm_pomchtax where match_ctrl_int = @match_id and tax_type_code = @txcode),0)  
      set @tax_tot = isnull((select sum(amt_tax) from adm_pomchtax where match_ctrl_int = @match_id and tax_type_code = @txcode),0)  
  
      if @tax_tot != 0 and @tax_amt != 0  
      begin  
        update d  
        set amt_final_tax = amt_final_tax + round(round( amt_tax / @tax_tot,4) * @tax_amt, @precision)  
        from adm_pomchtaxdtl d where match_ctrl_int = @match_id and tax_type_code = @txcode  
  and amt_final_tax != amt_final_tax + round(round( amt_tax / @tax_tot,4) * @tax_amt, @precision)  
  
        select @tax_tot = isnull((select sum(amt_final_tax - amt_tax) from adm_pomchtaxdtl where match_ctrl_int = @match_id  
          and tax_type_code = @txcode),0)  
        if @tax_tot != @tax_amt  
        begin  
          set rowcount 1  
          update d  
          set amt_final_tax = amt_final_tax + (@tax_amt - @tax_tot)  
          from adm_pomchtaxdtl d where match_ctrl_int = @match_id and tax_type_code = @txcode  
      and amt_final_tax != amt_final_tax + (@tax_amt - @tax_tot)  
          set rowcount 0  
        end   
      end  
  
      select @txcode = isnull((select min(tax_type_code) from adm_pomchtax where match_ctrl_int = @match_id  
        and amt_tax != amt_final_tax and tax_type_code > @txcode),'')  
    end  
  end  
  
  if (@tax_nr_adj_not_incl != 0 or @tax_nr_adj_incl != 0)  
  begin  
      update d  
      set amt_nonrecoverable_tax = d.amt_nonrecoverable_tax + (t.amt_final_tax - t.amt_tax)  
      from adm_pomchcdt d  
      join adm_pomchtaxdtl t on t.match_ctrl_int = d.match_ctrl_int and t.detail_sequence_id = d.match_line_num  
      where d.match_ctrl_int = @match_id and d.amt_nonrecoverable_tax != 0  
        and amt_nonrecoverable_tax != d.amt_nonrecoverable_tax + (t.amt_final_tax - t.amt_tax)  
  end  
  
  --IF RTV  
  if @trx_type = 4092  
  BEGIN  
    UPDATE rtv_all  
    SET tax_amt = @not_included_tax + @nonr_not_included_tax  
    WHERE match_ctrl_int = @match_id  
  END  
end   
  
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
drop table #TXcents  
  
select @err = 1  
  
return  
GO
GRANT EXECUTE ON  [dbo].[fs_calculate_matchtax] TO [public]
GO
