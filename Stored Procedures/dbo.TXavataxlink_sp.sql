SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 16/06/2014 - Performance  
  
CREATE procedure [dbo].[TXavataxlink_sp]   @docType varchar(16), @err_msg varchar(255) output, @debug int = 0  
as   
set nocount on  
  
-- Scratch variables used in the script  
DECLARE @retVal  INT,  
  @comHandle   INT,  
  @errorSource   VARCHAR(8000),  
  @errorDescription  VARCHAR(8000),  
  @retString   VARCHAR(1000),  
  @l_url   varchar(900),   
  @l_viaurl   varchar(900),   
  @l_username   varchar(50),   
  @l_password   varchar(50),  
  @l_company_id  int,  
  @in_cursor  smallint,  
  @return_type   varchar(50),   
  @index_required  smallint,  
  @TaxLinesCount  int,  
  @TaxLinesDetCount  int,  
  @cnt    int,   
  @cnt2   int,  
  @tc_tax_included  smallint,  
  @tax_type_cnt  int,  
  @ref_no   int,  
  @l_requesttimeout  int  
  
  
  
declare @h_doccode varchar(16),  
  @h_doctype  smallint,  
  @h_companycode  varchar(25),  
  @h_docdate   datetime,  
  @h_exemptionno  varchar(20),  
  @h_salespersoncode  varchar(20),  
  @h_discount   float,  
  @h_purchaseorderno  varchar(20),  
  @h_customercode  varchar(20),  
  @h_customerusagetype  varchar(20) ,  
  @h_detaillevel  varchar(20) ,  
  @h_referencecode  varchar(20) ,  
  @h_oriaddressline1 varchar(40),  
  @h_oriaddressline2 varchar(40),  
  @h_oriaddressline3 varchar(40),  
  @h_oricity  varchar(40),  
  @h_oriregion  varchar(40),  
  @h_oripostalcode varchar(40),  
  @h_oricountry  varchar(40),  
  @h_destaddressline1 varchar(40),  
  @h_destaddressline2 varchar(40),  
  @h_destaddressline3 varchar(40),  
  @h_destcity  varchar(40),  
  @h_destregion  varchar(40),  
  @h_destpostalcode varchar(40),  
  @h_destcountry varchar(40),  
  @h_trx_type  smallint,  
  @h_currCode varchar(8),  
  @h_currRate float,  
  @h_currRateDate datetime ,  
  @h_locCode varchar(20) ,  
  @h_paymentDt datetime ,  
  @h_taxOverrideReason varchar(100) ,  
  @h_taxOverrideAmt float ,  
  @h_taxOverrideDate datetime ,  
  @h_taxOverrideType int ,  
  @h_commitInd int     
  
declare @d_doccode varchar(16),  
  @d_no   varchar(20),  
  @d_oriaddressline1 varchar(40),  
  @d_oriaddressline2 varchar(40),  
  @d_oriaddressline3 varchar(40),  
  @d_oricity  varchar(40),  
  @d_oriregion  varchar(40),  
  @d_oripostalcode varchar(40),  
  @d_oricountry  varchar(40),  
  @d_destaddressline1 varchar(40),  
  @d_destaddressline2 varchar(40),  
  @d_destaddressline3 varchar(40),  
  @d_destcity  varchar(40),  
  @d_destregion  varchar(40),  
  @d_destpostalcode varchar(40),  
  @d_destcountry varchar(40),  
  @d_qty  float,  
  @d_amount  float,  
  @d_discounted  smallint,   
  @d_exemptionno varchar(20),  
  @d_itemcode  varchar(40) ,  
  @d_ref1  varchar(20) ,  
  @d_ref2  varchar(20) ,  
  @d_revacct  varchar(20) ,  
  @d_taxcode  varchar(8),  
    
  
  @d_customerUsageType varchar(20),  
  @d_description varchar(255),  
  @d_taxIncluded int,  
  @d_taxOverrideReason varchar(100),  
  @d_taxOverrideTaxAmount decimal(20,8),  
  @d_taxOverrideTaxDate datetime,  
  @d_taxOverrideType int,  
  
  @result_code   int  
  
declare @pltdate int  
  
create table #return_parameters (seq_id int, return_type varchar(50), index_required smallint)  
  
insert #return_parameters values (1, 'get_TotalAmount',0)  
insert #return_parameters values (2, 'get_TotalDiscount',0)  
insert #return_parameters values (3, 'get_TotalExemption',0)  
insert #return_parameters values (4, 'get_TaxLinesCount',0)  
insert #return_parameters values (5, 'get_No',1)  
insert #return_parameters values (6, 'get_Rate',1)  
insert #return_parameters values (7, 'get_Taxable',1)  
insert #return_parameters values (8, 'get_TaxCode',1)  
insert #return_parameters values (9, 'get_Taxability',1)  
insert #return_parameters values (10, 'get_Tax',1)  
insert #return_parameters values (11, 'get_Discount',1)  
insert #return_parameters values (12, 'get_Exemption',1)  
insert #return_parameters values (13, 'get_TaxLinesDetCount',1)  
insert #return_parameters values (14, 'get_DetBase',2)  
insert #return_parameters values (15, 'get_DetExemption',2)  
insert #return_parameters values (16, 'get_DetJurisCode',2)  
insert #return_parameters values (17, 'get_DetJurisName',2)  
insert #return_parameters values (18, 'get_DetJurisType',2)  
insert #return_parameters values (19, 'get_DetNonTaxable',2)  
insert #return_parameters values (20, 'get_DetRate',2)  
insert #return_parameters values (21, 'get_DetTax',2)  
insert #return_parameters values (22, 'get_DetTaxable',2)  
insert #return_parameters values (23, 'get_DetTaxType',2)  
insert #return_parameters values (24, 'get_TotalTax',0)  
insert #return_parameters values (25, 'get_DocId',0)  
insert #return_parameters values (26, 'get_TaxCalculated',1)  
insert #return_parameters values (27, 'get_DetTaxCalculated',2)  
  
create table #TXtaxtype_juris (  
  control_number varchar(16) not null,  
  tt_row int,  
  taxCode varchar(8),  
  taxType varchar(8),  
  tc_global smallint,   
  jurisType varchar(30),  
  jurisCode varchar(30),  
  amtBase float,  
  nonTaxable float,  
  amtTax float,  
  taxable float,  
  linked int  
)  
create index TTJ_1 on #TXtaxtype_juris(tc_global,control_number,taxCode,jurisCode,jurisType)  
create index TTJ_2 on #TXtaxtype_juris(tt_row)  
  
create table #TXTaxTypeOutput (  
  control_number varchar(16) not null,  
  taxCode varchar(8),  
  tax_type varchar(8),  
  jurisCode varchar(30),  
  jurisName varchar(255),  
  jurisType varchar(30),  
  amtBase float,  
  nonTaxable float,  
  amtTax float,  
  taxable float,  
  taxType smallint,   
  linked smallint  
)  
create index TTO_1 on #TXTaxTypeOutput(control_number,taxCode,jurisCode,jurisType)  
create index TTO_2 on #TXTaxTypeOutput(linked,control_number,taxCode)  
  
-- populate the tax tables used by the internal tax processes  
insert #TXtaxcode (ti_row, control_number, tax_code, amt_tax, tax_included_flag, tax_type_cnt, tot_extended_amt)  
select min(ti.row_id), ti.control_number, ti.tax_code, 0, tc.tax_included_flag,   
  case tc.tax_code when NULL then 0 else 1 end,   
  sum(case when ti.action_flag = 0 then ti.extended_price - ti.amt_discount else ti.freight end)  
from #TXLineInput_ex ti  
join #txconnhdrinput h on h.doctype = @docType and h.doccode = ti.control_number  
left outer join artax tc (nolock) on tc.tax_code = ti.tax_code  
group by ti.control_number, ti.tax_code, tc.tax_included_flag, case tc.tax_code when NULL then 0 else 1 end  
  
insert #TXtaxtyperec (tc_row, tax_code, seq_id, base_id, cur_amt, old_tax, tax_type)  
select tc.row_id, tc.tax_code, sequence_id, base_id, 0.0, 0.0, ar.tax_type_code  
from #TXtaxcode tc  
join #txconnhdrinput h on h.doctype = @docType and h.doccode = tc.control_number  
join artaxdet ar (NOLOCK) on ar.tax_code = tc.tax_code  
order by tc.tax_code, ar.sequence_id  
  
insert #TXtaxtyperec (tc_row, tax_code, seq_id, base_id, cur_amt, old_tax, tax_type)  
select tc.row_id, tc.tax_code,   
isnull((select max(ad.sequence_id) from artaxdet ad where ad.tax_code = tc.tax_code),0) + 1, 0,  
 0.0, 0.0, ar.tax_type_code  
from #TXtaxcode tc  
join #txconnhdrinput h on h.doctype = @docType and h.doccode = tc.control_number  
join artxtype ar (NOLOCK) on  isnull(tax_connect_flag,0) = 1  
where not exists (select 1 from #TXtaxtyperec ttr  
where ttr.tc_row = tc.row_id and ttr.tax_code = tc.tax_code and ttr.tax_type = ar.tax_type_code)  
  
  
insert #TXtaxtype (ttr_row, tax_type, ext_amt, amt_gross, amt_taxable, amt_tax,  
  amt_final_tax, amt_tax_included, save_flag, tax_rate, prc_flag, prc_type,  
  cents_code_flag, cents_code, cents_cnt, tax_based_type, tax_included_flag,  
  modify_base_prc, base_range_flag, base_range_type, base_taxed_type,  
  min_base_amt, max_base_amt, tax_range_flag, tax_range_type, min_tax_amt,  
  max_tax_amt, recoverable_flag)  
select ttr.row_id, tt.tax_type_code, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, tt.amt_tax,   
  tt.prc_flag, tt.prc_type, tt.cents_code_flag, tt.cents_code, 0, tt.tax_based_type,   
  tt.tax_included_flag, tt.modify_base_prc, tt.base_range_flag, tt.base_range_type,   
  tt.base_taxed_type, tt.min_base_amt, tt.max_base_amt, tt.tax_range_flag,   
  tt.tax_range_type, tt.min_tax_amt, tt.max_tax_amt, tt.recoverable_flag  
FROM #TXtaxtyperec ttr  
join artxtype tt (NOLOCK) on tt.tax_type_code = ttr.tax_type  
join #TXtaxcode tc on tc.row_id = ttr.tc_row  
join #txconnhdrinput h on h.doctype = @docType and h.doccode = tc.control_number  
  
-- populate the tax jurisdiction - tax type relationship table  
insert #TXtaxtype_juris (control_number, tt_row, taxCode, taxType, tc_global, jurisType, jurisCode,  
  amtBase ,  nonTaxable ,  amtTax ,  taxable , linked)  
select tc.control_number, tt.row_id, tc.tax_code, tt.tax_type,  
  att.tc_global, att.tc_juristype, att.tc_juriscode, 0, 0, 0, 0, 0  
from #TXtaxtype tt  
join #TXtaxtyperec ttr on ttr.row_id = tt.ttr_row  
join #TXtaxcode tc on tc.row_id = ttr.tc_row  
join artxtype att (NOLOCK) on att.tax_type_code = tt.tax_type  
join #txconnhdrinput h on h.doctype = @docType and h.doccode = tc.control_number  
  
if exists (select control_number, taxCode, sum(tc_global)  
from #TXtaxtype_juris  
group by control_number, taxCode  
having sum(tc_global) = 0)  
begin   
  select @err_msg = 'No global tax type defined for tax code'  
  goto Exit_Bad_1  
end  
  
-- Initialize the COM component. fsavataxlink.TaxCalculator  
EXEC @retVal = sp_OACreate '{E755AA05-2D40-4CE4-9903-36ACCF9D6622}', @comHandle OUTPUT, 4  
IF (@retVal <> 0) goto Exit_Bad  
  
select @l_company_id = company_id from arco (nolock)  
set @in_cursor = 0  
  
-- get the tax configuration data  
select @l_url = url,   
  @l_viaurl = viaurl,  
  @l_username = username,  
  @l_password = password,  
  @l_requesttimeout = requesttimeout  
from gltcconfig (nolock)  
where company_id = @l_company_id  
  
-- Initialize the COM component.  
EXEC @retVal = sp_OAMethod @comHandle, 'fSetConfig', @retString OUTPUT,   
  @a_url = @l_url, @a_viaurl = @l_viaurl, @a_username = @l_username, @a_password = @l_password,  
  @a_requesttimeout = @l_requesttimeout  
IF (@retVal <> 0) goto Exit_Bad  
  
-- read the tax header input table to get each tax document to be calculated  
DECLARE tax_doc CURSOR LOCAL STATIC FOR  
select doccode, doctype, companycode, docdate, exemptionno,   
  salespersoncode, discount, purchaseorderno, customercode, customerusagetype,   
  detaillevel, referencecode, oriaddressline1, oriaddressline2, oriaddressline3,   
  oricity, oriregion, oripostalcode, oricountry, destaddressline1, destaddressline2,   
  destaddressline3, destcity, destregion, destpostalcode, destcountry, trx_type,  
  isnull(gltc_currency.tc_currency_code, currCode), currRate, isnull(currRateDate ,docdate), isnull(locCode,''),  
  isnull(paymentDt,'1/1/1900'), isnull(taxOverrideReason,''),isnull(taxOverrideAmt,0.0),  
  isnull(taxOverrideDate,'1/1/1900'), isnull(taxOverrideType,2), isnull(commitInd,0)  
FROM #txconnhdrinput  
left outer join gltc_currency (NOLOCK) on gltc_currency.currency_code = #txconnhdrinput.currCode  
where doctype = @docType  
  
OPEN tax_doc  
set @in_cursor = 1  
  
FETCH NEXT FROM tax_doc into   
  @h_doccode   ,  @h_doctype  ,  @h_companycode  ,  
  @h_docdate   ,  @h_exemptionno  ,  @h_salespersoncode  ,  
  @h_discount   ,  @h_purchaseorderno  ,  @h_customercode  ,  
  @h_customerusagetype  ,  @h_detaillevel  ,  @h_referencecode  ,  
  @h_oriaddressline1 ,  @h_oriaddressline2 ,  @h_oriaddressline3 ,  
  @h_oricity  ,  @h_oriregion  ,  @h_oripostalcode ,  
  @h_oricountry  ,  @h_destaddressline1 ,  @h_destaddressline2 ,  
  @h_destaddressline3 ,  @h_destcity  ,  @h_destregion ,  
  @h_destpostalcode ,  @h_destcountry ,  @h_trx_type,    
  @h_currCode ,  
  @h_currRate ,  
  @h_currRateDate ,  
  @h_locCode ,  
  @h_paymentDt,  
  @h_taxOverrideReason,  
  @h_taxOverrideAmt,  
  @h_taxOverrideDate,  
  @h_taxOverrideType,  
  @h_commitInd  
  
While @@FETCH_STATUS = 0  
begin  
  if isnull(@h_companycode,'') = ''  
  begin  
    select @err_msg = 'Tax Connect Company Code not defined for Organization on document ' + @h_doccode  
    return -1  
  end  
  
  if not exists (select 1 from gltc_currency (NOLOCK) where tc_currency_code = @h_currCode)  
  begin  
    select @err_msg = 'Currency defined not valid for use with Tax Connect on document ' + @h_doccode  
    return -1  
  end  
  
  IF @h_doctype in (1,3,5)  
  begin  
    if exists (select 1 from gltcrecon (nolock)  
      where trx_ctrl_num = @h_doccode and trx_type = @h_trx_type  
      and (posted_flag = 1 or remote_state > 1 or reconciled_flag > 0))  
    begin  
      select @err_msg = 'Transaction already posted in tax connect.'  
      return -1  
    end   
  end  
  
  if @h_trx_type in (2032,4092)  
    select @h_discount = -@h_discount  
  
  -- Call a method into the component  
 if @debug > 0 print 'setheader_v5'  
  EXEC @retVal    = sp_OAMethod @comHandle, 'SetHeader_v5', NULL,  
    @aDocCode   = @h_doccode,  @aDocType  = @h_doctype,  
    @aCompanyCode = @h_companycode,  @aDocDate  = @h_docdate,  
    @aExemptionNo = @h_exemptionno,  @aSalespersonCode = @h_salespersoncode,  
    @aDiscount    = @h_discount, @aPurchaseOrderNo = @h_purchaseorderno,  
    @aCustomerCode= @h_customercode, @aCustomerUsageType = @h_customerusagetype,  
    @aDetailLevel = @h_detaillevel, @aReferenceCode = @h_referencecode,  
 @aCurrencyCode = @h_currCode ,  
    @aExchangeRate = @h_currRate ,  
    @aExchangeRateEffDate = @h_currRateDate ,  
    @aLocationCode = @h_locCode ,  
    @aPaymentDate = @h_paymentDt,  
    @aTaxOverrideReason = @h_taxOverrideReason,  
    @aTaxOverrideTaxAmount = @h_taxOverrideAmt,  
    @aTaxOverrideTaxDate = @h_taxOverrideDate,  
    @aTaxOverrideType = @h_taxOverrideType,  
    @aCommit = @h_commitInd  
  
  IF (@retVal <> 0) goto Exit_Bad  
   
  -- Call a method into the component  
  if @debug > 0 print 'setOaddr'  
  EXEC @retVal  = sp_OAMethod @comHandle, 'SetOriginAddress', NULL,  
    @aAddressLine1= @h_oriaddressline1, @aAddressLine2 = @h_oriaddressline2,  
    @aAddressLine3= @h_oriaddressline3, @aCity  = @h_oricity,   
    @aRegion = @h_oriregion,  @aPostalCode = @h_oripostalcode,   
    @aCountry = @h_oricountry,  @aShowResults = 0  
  IF (@retVal <> 0) goto Exit_Bad  
  
  -- Call a method into the component  
  if @debug > 0 print 'setDaddr'  
  EXEC @retVal = sp_OAMethod @comHandle, 'SetDestinationAdddress', NULL,  
    @aAddressLine1= @h_destaddressline1, @aAddressLine2 = @h_destaddressline2,  
    @aAddressLine3= @h_destaddressline3, @aCity  = @h_destcity,   
    @aRegion  = @h_destregion,  @aPostalCode = @h_destpostalcode,   
    @aCountry = @h_destcountry,  @aShowResults = 0  
  IF (@retVal <> 0) goto Exit_Bad  
  
  -- read the tax documents lines for the current tax document  
    
  DECLARE tax_lines CURSOR LOCAL STATIC FOR  
  SELECT no, oriaddressline1, oriaddressline2, oriaddressline3, oricity,  
    oriregion, oripostalcode, oricountry, destaddressline1,  
    destaddressline2, destaddressline3, destcity,  
    destregion, destpostalcode, destcountry,  
    qty, amount, discounted, exemptionno,  
    itemcode, ref1, ref2, revacct, taxcode,  
 customerUsageType, description, taxIncluded, taxOverrideReason,  
 taxOverrideTaxAmount, taxOverrideTaxDate, taxOverrideType   
  FROM #txconnlineinput   
  where doccode = @h_doccode  
  OPEN tax_lines  
  set @in_cursor = 2  
  
    
  FETCH NEXT FROM tax_lines into   
    @d_no, @d_oriaddressline1, @d_oriaddressline2, @d_oriaddressline3, @d_oricity,   
    @d_oriregion, @d_oripostalcode, @d_oricountry, @d_destaddressline1,   
    @d_destaddressline2, @d_destaddressline3, @d_destcity,   
    @d_destregion, @d_destpostalcode, @d_destcountry,   
    @d_qty, @d_amount, @d_discounted, @d_exemptionno,   
    @d_itemcode, @d_ref1, @d_ref2, @d_revacct, @d_taxcode,  
 @d_customerUsageType, @d_description, @d_taxIncluded, @d_taxOverrideReason,  
 @d_taxOverrideTaxAmount, @d_taxOverrideTaxDate, @d_taxOverrideType  
  
  While @@FETCH_STATUS = 0  
  begin  
    if @h_trx_type in (2032,4092)  
    begin  
      select @d_qty = -@d_qty, @d_amount = -@d_amount  
    end  
   
 SELECT @d_customerUsageType = isnull(@d_customerUsageType, 0),   
  @d_description=isnull(@d_description,''),   
  @d_taxIncluded=isnull(@d_taxIncluded,0),   
  @d_taxOverrideReason=isnull(@d_taxOverrideReason,''),  
  @d_taxOverrideTaxAmount= isnull(@d_taxOverrideTaxAmount,0),   
  @d_taxOverrideTaxDate=isnull(@d_taxOverrideTaxDate,convert(datetime, '01/01/1900', 101)),   
  @d_taxOverrideType=isnull(@d_taxOverrideType,2)  
   
    -- Call a method into the component  
    if @debug > 0 print 'addline'   
    EXEC @retVal = sp_OAMethod @comHandle, 'AddLine_v5', NULL,  
      @aNo  = @d_no,   @aOriAddressLine1 = @d_oriaddressline1,   
      @aOriAddressLine2 = @d_oriaddressline2,  @aOriAddressLine3 = @d_oriaddressline3,  
      @aOriCity  = @d_oricity,   @aOriRegion = @d_oriregion,   
      @aOriPostalCode = @d_oripostalcode,  @aOriCountry = @d_oricountry,   
      @aDestAddressLine1= @d_destaddressline1,  @aDestAddressLine2 = @d_destaddressline2,   
      @aDestAddressLine3= @d_destaddressline3, @aDestCity = @d_destcity,   
      @aDestRegion = @d_destregion,  @aDestPostalCode = @d_destpostalcode,   
      @aDestCountry = @d_destcountry,  @aQty  = @d_qty,   
      @aAmount  = @d_amount,   @aDiscounted = @d_discounted,   
      @aExemptionNo = @d_exemptionno,  @aItemCode = @d_itemcode,   
      @aRef1  = @d_ref1,   @aRef2  = @d_ref2,   
      @aRevAcct  = @d_revacct,   @aTaxCode = @d_taxcode,  
      @aCustomerUsageType = @d_customerUsageType, @aDescription = @d_description,   
      @aTaxIncluded = @d_taxIncluded, @aTaxOverrideReason = @d_taxOverrideReason,  
      @aTaxOverrideTaxAmount = @d_taxOverrideTaxAmount,   
      @aTaxOverrideTaxDate = @d_taxOverrideTaxDate, @aTaxOverrideType = @d_taxOverrideType      
    IF (@retVal <> 0) goto Exit_Bad  
  
    FETCH NEXT FROM tax_lines into   
      @d_no, @d_oriaddressline1, @d_oriaddressline2, @d_oriaddressline3, @d_oricity,   
      @d_oriregion, @d_oripostalcode, @d_oricountry, @d_destaddressline1,   
      @d_destaddressline2, @d_destaddressline3, @d_destcity,   
      @d_destregion, @d_destpostalcode, @d_destcountry,   
      @d_qty, @d_amount, @d_discounted, @d_exemptionno,   
      @d_itemcode, @d_ref1, @d_ref2, @d_revacct, @d_taxcode,  
   @d_customerUsageType, @d_description, @d_taxIncluded, @d_taxOverrideReason,  
   @d_taxOverrideTaxAmount, @d_taxOverrideTaxDate, @d_taxOverrideType  
  end  
  
  close tax_lines  
  deallocate tax_lines  
  set @in_cursor = 1  
  
  -- Call a method into the component  
  if @debug > 0 print 'gettax'  
  EXEC @retVal = sp_OAMethod @comHandle, 'GetTax', @retString OUTPUT  
  IF (@retVal <> 0) goto Exit_Bad  
  
  -- Call a method into the component  
  if @debug > 0 print 'getresultcode'  
  EXEC @retVal = sp_OAMethod @comHandle, 'get_ResultCode', @retString OUTPUT  
  
  IF (@retVal <> 0) goto Exit_Bad  
  select @result_code = convert(int, @retString)  
  
  EXEC @retVal = sp_OAMethod @comHandle, 'get_ResultCodeDesc', @retString OUTPUT  
  
  IF (@retVal <> 0) goto Exit_Bad  
  
  -- Print the value returned from the method call  
  if @debug > 0 SELECT 'Return Code '+ @retString  
  
  IF @retString in ( 'Error','Exception') or @result_code in (2,3)  
  begin  
    -- Call a method into the component  
    EXEC @retVal = sp_OAMethod @comHandle, 'get_ResultMessages', @retString OUTPUT  
    IF (@retVal <> 0) goto Exit_Bad  
  
    if @debug > 0  
    SELECT 'Error Message: '+@retString  
  
    While ascii(left(@retString,1)) < 32 and datalength(@retString) > 0  
    begin  
      select @retString = substring(@retString,2,255)  
    end  
    select @err_msg = @retString  
    return -1  
  end  
  
  IF @h_doctype in (1,3,5)  
  begin  
    select @pltdate = datediff(day,'1/1/1950',convert(datetime,  
      convert(varchar(8), (year(@h_docdate) * 10000) + (month(@h_docdate) * 100) + day(@h_docdate)))  ) + 711858  
  
    if not exists (select 1 from gltcrecon (nolock)  
      where trx_ctrl_num = @h_doccode and trx_type = @h_trx_type)  
      insert gltcrecon WITH (ROWLOCK) (trx_ctrl_num, trx_type, app_id, posted_flag, remote_doc_id,   
        remote_state, reconciled_flag, amt_gross, amt_tax, remote_amt_gross,   
        remote_amt_tax, customervendor_code, date_doc, reconciliated_date,doc_ctrl_num)  
      select @h_doccode, @h_trx_type,   
        case when @h_trx_type in (4091, 4092) then 4000  
          when @h_trx_type in (2031, 2032) then 2000  
        else 0 end, 0,   
         '', 0, 0, 0, 0, 0, 0, @h_customercode, @pltdate, 0, ''  
  end  
  
  -- header return values  
  -- read the return_paramters table for index_required = 0 (header records) and call a method  
  -- contained in the return_type to get the value back from the component  
  DECLARE tax_lines CURSOR LOCAL STATIC FOR  
  select return_type, index_required  
  from #return_parameters where index_required = 0  
  order by seq_id  
  
  OPEN tax_lines  
  set @in_cursor = 2  
  
  FETCH NEXT FROM tax_lines into @return_type, @index_required  
  While @@FETCH_STATUS = 0  
  begin  
    -- Call a method into the component  
    EXEC @retVal = sp_OAMethod @comHandle, @return_type, @retString OUTPUT  
    IF (@retVal <> 0) goto Exit_Bad  
  
    -- get_TotalAmount is the first return type read so it will create a entry in the table for the rest  
    if @return_type = 'get_TotalAmount'  
    begin  
      insert #TXTaxOutput (control_number, amtTotal, amtDisc, amtExemption, amtTax, remoteDocId)  
      select @h_doccode, convert(decimal(20,8),@retString), 0, 0, 0, 0  
    end  
    else  
      update #TXTaxOutput   
      set amtDisc = case when @return_type = 'get_TotalDiscount' then convert(decimal(20,8),@retString) else amtDisc end,  
   amtExemption = case when @return_type = 'get_TotalExemption' then convert(decimal(20,8),@retString) else amtExemption end,  
   amtTax = case when @return_type = 'get_TotalTax' then convert(decimal(20,8),@retString) else amtTax end,  
   remoteDocId = case when @return_type = 'get_DocId' then convert(int,@retString) else remoteDocId end  
      where control_number = @h_doccode   
  
    if @return_type = 'get_TaxLinesCount'    
      select @TaxLinesCount = convert(int, @retString)  
  
    FETCH NEXT FROM tax_lines into @return_type, @index_required  
  end  
  
  close tax_lines  
  deallocate tax_lines  
  set @in_cursor = 1  
  
  IF @h_doctype in (1,3,5)  
  begin  
    update r  
    set remote_doc_id = t.remoteDocId,  
      remote_amt_gross = case when r.trx_type = 2032 then -t.amtTotal else t.amtTotal end,   
      remote_amt_tax = case when r.trx_type = 2032 then -t.amtTax else t.amtTax end,  
      remote_state = 1  
    from gltcrecon r WITH (ROWLOCK) 
    join #TXTaxOutput t on t.control_number = @h_doccode  
    where r.trx_ctrl_num = @h_doccode and r.trx_type = @h_trx_type  
  end  
  
  -- tax lines return values  
  -- read the return_paramters table for index_required = 1 (tax line records) and call a method  
  -- contained in the return_type to get the value back from the component  
  DECLARE tax_lines CURSOR LOCAL STATIC FOR  
  select return_type, index_required  
  from #return_parameters where index_required = 1  
  order by seq_id  
  
  OPEN tax_lines  
  set @in_cursor = 2  
  
  FETCH NEXT FROM tax_lines into @return_type, @index_required  
  While @@FETCH_STATUS = 0  
  begin  
    set @cnt = 0  
    set @ref_no = 0  
  
    while @cnt < @TaxLinesCount  
    begin  
      -- Call a method into the component  
      EXEC @retVal = sp_OAMethod @comHandle, @return_type, @retString OUTPUT, @index = @cnt  
      IF (@retVal <> 0) goto Exit_Bad  
  
      -- get_No is the first call made so it creates an entry in the table for the rest  
      if @return_type = 'get_No'  
      begin  
        select @ref_no = convert(int,@retString)  
        insert #TXTaxLineOutput (control_number, reference_number, t_index, taxRate, taxable, taxCode,  
          taxability, amtTax, amtDisc, amtExemption)  
        select @h_doccode, @ref_no, @cnt, 0, 0, taxcode, 0, 0, 0, 0            -- mls 11/1/07 SCR 38264  
        FROM #txconnlineinput   
        where doccode = @h_doccode and no = @ref_no  
      end  
      else  
        update #TXTaxLineOutput  
        set  
   taxRate = case when @return_type = 'get_Rate' then convert(decimal(20,8),@retString) else taxRate end,  
   taxable = case when @return_type = 'get_Taxable' then convert(decimal(20,8),@retString) else taxable end,  
   --taxCode = case when @return_type = 'get_TaxCode' then @retString else taxCode end,      -- mls 11/1/07 SCR 38264  
   taxability = case when @return_type = 'get_Taxability' then @retString else taxability end,  
   amtTax = case when @return_type = 'get_Tax' then convert(decimal(20,8),@retString) else amtTax end,  
   amtDisc = case when @return_type = 'get_Discount' then convert(decimal(20,8),@retString) else amtDisc end,  
   amtExemption = case when @return_type = 'get_Exemption' then convert(decimal(20,8),@retString) else amtExemption end,  
      taxDetailCnt = case when @return_type = 'get_TaxLinesDetCount' then convert(int,@retString) else taxDetailCnt end,  
      amtTaxCalculated =  case when @return_type = 'get_TaxCalculated' then convert(decimal(20,8),@retString) else amtTaxCalculated end            
        where control_number = @h_doccode and t_index = @cnt  
  
      select @cnt = @cnt + 1  
    end  
  
    FETCH NEXT FROM tax_lines into @return_type, @index_required  
  end  
  
  close tax_lines  
  deallocate tax_lines  
  set @in_cursor = 1  
  
  -- tax detail return values  
  -- read the return_paramters table for index_required = 2 (tax detail line records) and call a method  
  -- contained in the return_type to get the value back from the component  
  DECLARE tax_lines CURSOR LOCAL STATIC FOR  
  select return_type, index_required  
  from #return_parameters where index_required = 2  
  order by seq_id  
  
  OPEN tax_lines  
  set @in_cursor = 2  
  
  FETCH NEXT FROM tax_lines into @return_type, @index_required  
  While @@FETCH_STATUS = 0  
  begin  
    set @cnt = 0  
    while @cnt < @TaxLinesCount  
    begin  
      select @TaxLinesDetCount = taxDetailCnt  
      from #TXTaxLineOutput where control_number = @h_doccode and t_index = @cnt  
  
      set @cnt2 = 0  
      while @cnt2 < @TaxLinesDetCount  
      begin  
        -- Call a method into the component  
        EXEC @retVal = sp_OAMethod @comHandle, @return_type, @retString OUTPUT, @index = @cnt, @Detindex = @cnt2  
        IF (@retVal <> 0) goto Exit_Bad  
  
 -- get_DetBase is the first one read so it create an entry in the table for the rest  
        if @return_type = 'get_DetBase'  
        begin  
          select @ref_no = reference_number  
          from #TXTaxLineOutput  
          where control_number = @h_doccode and t_index = @cnt  
  
          insert #TXTaxLineDetOutput (control_number, reference_number, t_index, d_index, amtBase, exception,  
            jurisCode, jurisName, jurisType, nonTaxable, taxRate, amtTax, taxable, taxType)  
          select @h_doccode, @ref_no, @cnt, @cnt2, convert(decimal(20,8),@retString), 0,   
            '', '', 0, 0, 0, 0, 0, 0  
        end  
        else  
          update #TXTaxLineDetOutput  
          set  
      exception = case when @return_type = 'get_DetExemption' then case when convert(decimal(20,8),@retString) = 0 then 0 else 1 end else exception end,  
     jurisCode = case when @return_type = 'get_DetJurisCode' then @retString else jurisCode end,  
     jurisName = case when @return_type = 'get_DetJurisName' then @retString else jurisName end,  
     jurisType = case when @return_type = 'get_DetJurisType' then @retString else jurisType end,  
      nonTaxable = case when @return_type = 'get_DetNonTaxable' then convert(decimal(20,8),@retString) else nonTaxable end,  
     taxRate = case when @return_type = 'get_DetRate' then convert(decimal(20,8),@retString) else taxRate end,  
     amtTax = case when @return_type = 'get_DetTax' then convert(decimal(20,8),@retString) else amtTax end,  
     taxable = case when @return_type = 'get_DetTaxable' then convert(decimal(20,8),@retString) else taxable end,  
     taxType = case when @return_type = 'get_DetTaxType' then convert(int,@retString) else taxType end,  
     amtTaxCalculated = case when @return_type = 'get_DetTaxCalculated' then convert(decimal(20,8),@retString) else amtTaxCalculated end  
          where control_number = @h_doccode and t_index = @cnt and d_index = @cnt2  
  
        select @cnt2 = @cnt2 + 1  
      end  
      select @cnt = @cnt + 1  
    end  
  
    FETCH NEXT FROM tax_lines into @return_type, @index_required  
  end  
  
  close tax_lines  
  deallocate tax_lines  
  set @in_cursor = 1  
  
  
  if @debug > 0 print 'reset'  
  EXEC @retVal = sp_OAMethod @comHandle, 'Reset', NULL  
  IF (@retVal <> 0) goto Exit_Bad  
  
  
  
  
  
  
  
  
  
  
  FETCH NEXT FROM tax_doc into   
    @h_doccode   ,  @h_doctype  ,  @h_companycode  ,  
    @h_docdate   ,  @h_exemptionno  ,  @h_salespersoncode  ,  
    @h_discount  ,  @h_purchaseorderno  ,  @h_customercode  ,  
    @h_customerusagetype,  @h_detaillevel  ,  @h_referencecode  ,  
    @h_oriaddressline1 ,  @h_oriaddressline2 ,  @h_oriaddressline3 ,  
    @h_oricity  ,  @h_oriregion  ,  @h_oripostalcode ,  
    @h_oricountry ,  @h_destaddressline1 ,  @h_destaddressline2 ,  
    @h_destaddressline3 ,  @h_destcity  ,  @h_destregion ,  
    @h_destpostalcode ,  @h_destcountry ,  @h_trx_type ,   
   @h_currCode ,  
   @h_currRate ,  
   @h_currRateDate ,  
   @h_locCode ,  
   @h_paymentDt,  
   @h_taxOverrideReason,  
   @h_taxOverrideAmt,  
   @h_taxOverrideDate,  
   @h_taxOverrideType,  
   @h_commitInd  
end  
  
  -- Release the reference to the COM object  
EXEC sp_OADestroy @comHandle  
  
-- update TXLineInput_ex and set the tax on each line to the tax returned in the TaxLineOutput  
update TLI  
set TLI.calc_tax = case when @h_trx_type in (2032,4092) then -1 else 1 end * TLO.amtTax,  
TLI.amtTaxCalculated = case when @h_trx_type in (2032,4092) then -1 else 1 end * TLO.amtTaxCalculated  
from #TXLineInput_ex TLI, #TXTaxLineOutput TLO  
where TLI.control_number = TLO.control_number and TLI.reference_number = TLO.reference_number  
  
-- insert in TaxTypeOutput the summed tax values for control_number, tax_code, juris_code and juris_type  
-- this is a calculation of the tax for each jurisdiction for the control number and each distinct tax code  
-- on the tax document  
insert #TXTaxTypeOutput (control_number, taxCode, tax_type,   
  jurisCode, jurisName, jurisType, amtBase, nonTaxable, amtTax, taxable, taxType, linked )  
select TLDO.control_number, TLO.taxCode, '',  
  TLDO.jurisCode, '', TLDO.jurisType, sum(case when TLDO.d_index = 0 then TLDO.amtBase else 0 end), sum(TLDO.nonTaxable),  
  sum(TLDO.amtTax), sum(case when TLDO.d_index = 0 then TLDO.taxable else 0 end), '', 0  
from #TXTaxLineDetOutput TLDO  
join #TXTaxLineOutput TLO on TLO.control_number = TLDO.control_number and TLO.t_index = TLDO.t_index  
group by TLDO.control_number, TLDO.jurisCode, TLDO.jurisType, TLO.taxCode  
  
-- update the TaxTypeOutput table with the number of matching tax_types linked to jurisdictions on the   
-- #TXtaxtype_juris table.  It should be one but if it is more than one, we need to divide the tax between them  
update TTO  
set linked = TTJ.cnt  
from #TXTaxTypeOutput TTO  
join (select control_number, taxCode, jurisCode, jurisType, count(*)  
from #TXtaxtype_juris where tc_global = 0  
group by control_number, taxCode, jurisCode, jurisType)  
as TTJ(control_number, taxCode, jurisCode, jurisType, cnt)  
on TTO.control_number = TTJ.control_number and TTO.taxCode = TTJ.taxCode and TTO.jurisCode = TTJ.jurisCode  
  and TTO.jurisType = TTJ.jurisType  
  
-- update the #TXtaxtype_juris table with the tax amount from the TaxTypeOutput table  
update TTJ  
set amtBase = TTO.amtBase / TTO.linked ,  
nonTaxable = TTO.nonTaxable/ TTO.linked ,  
amtTax = TTO.amtTax / TTO.linked ,  
taxable = TTO.taxable / TTO.linked ,  
linked = 1  
from #TXtaxtype_juris TTJ  
join #TXTaxTypeOutput TTO on TTO.control_number = TTJ.control_number  
  and TTO.taxCode = TTJ.taxCode and TTO.jurisCode = TTJ.jurisCode and TTO.jurisType = TTJ.jurisType  
  and TTO.linked > 0 and TTJ.tc_global = 0  
  
-- Now create an entry in TaxTypeOutput as a sum of all the non linked tax types  
insert #TXTaxTypeOutput (control_number, taxCode, tax_type,   
  jurisCode, jurisName, jurisType, amtBase, nonTaxable, amtTax, taxable, taxType, linked )  
select TTO.control_number, TTO.taxCode, '',  
  '*NONE*', '*NONE*', '', sum(TTO.amtBase), sum(TTO.nonTaxable),  
  sum(TTO.amtTax), sum(TTO.taxable), '', -1  
from #TXTaxTypeOutput TTO  
where TTO.linked = 0  
group by TTO.control_number, TTO.taxCode  
  
-- update the TaxTypeOutput table with the number of matching tax_types not linked to jurisdictions on the   
-- #TXtaxtype_juris table.  It should be one but if it is more than one, we need to divide the tax between them  
update TTO  
set linked = TTJ.cnt  
from #TXTaxTypeOutput TTO  
join (select control_number, taxCode, count(*)  
from #TXtaxtype_juris where tc_global = 1  
group by control_number, taxCode)  
as TTJ(control_number, taxCode, cnt)  
on TTO.control_number = TTJ.control_number and TTO.taxCode = TTJ.taxCode and TTO.linked = -1  
  
-- update the #TXtaxtype_juris table with the tax amount from the TaxTypeOutput table  
update TTJ  
set amtBase = TTO.amtBase / TTO.linked ,  
nonTaxable = TTO.nonTaxable/ TTO.linked ,  
amtTax = TTO.amtTax / TTO.linked ,  
taxable = TTO.taxable / TTO.linked ,  
linked = 1  
from #TXtaxtype_juris TTJ  
join #TXTaxTypeOutput TTO on TTO.control_number = TTJ.control_number  
  and TTO.taxCode = TTJ.taxCode and TTO.jurisCode = '*NONE*' and TTJ.tc_global = 1  
  and TTO.linked > 0  
  
delete from TTR  
from #TXtaxtyperec TTR  
join #TXtaxtype TT on TT.ttr_row = TTR.row_id  
join #TXtaxtype_juris TTJ on TTJ.tt_row = TT.row_id and TTJ.linked = 0  
  
delete from TT  
from #TXtaxtype TT  
join #TXtaxtype_juris TTJ on TTJ.tt_row = TT.row_id and TTJ.linked = 0  
  
update TT  
set amt_gross = case when @h_trx_type in (2032,4092) then -1 else 1 end * TTJ.amtBase,  
amt_taxable = case when @h_trx_type in (2032,4092) then -1 else 1 end * TTJ.taxable,  
amt_tax = case when @h_trx_type in (2032,4092) then -1 else 1 end * TTJ.amtTax,  
amt_final_tax = case when @h_trx_type in (2032,4092) then -1 else 1 end * TTJ.amtTax  
from #TXtaxtype TT  
join #TXtaxtype_juris TTJ on TTJ.tt_row = TT.row_id  
  
update TTR  
set cur_amt = TT.amt_tax  
from #TXtaxtyperec TTR  
join #TXtaxtype TT on TT.ttr_row = TTR.row_id  
  
if @debug > 0  
begin  
  print '#TXTaxOutput'  
  select * from #TXTaxOutput  
  print '#TXTaxLineOutput'  
  select * from #TXTaxLineOutput  
  print '#TXTaxLineDetOutput'  
  select * from #TXTaxLineDetOutput  
  print '#TXtaxtype_juris'  
  select * from #TXtaxtype_juris  
  print '#TXTaxTypeOutput'  
  select * from #TXTaxTypeOutput  
end  
  
set @retVal = 1  
set @err_msg = 'Tax calculated successfully.'  
goto Exit_Good  
  
Exit_Bad:  
 -- Trap errors if any  
 EXEC sp_OAGetErrorInfo @comHandle, @errorSource OUTPUT, @errorDescription OUTPUT  
 if @debug > 0  
 SELECT [Error Source] = @errorSource, [Description] = @errorDescription  
 select @err_msg = @errorSource  
  
Exit_Bad_1:  
 if @in_cursor > 0  
 begin  
    close tax_doc  
           deallocate tax_doc  
 end  
 if @in_cursor > 1  
 begin  
    close tax_lines  
           deallocate tax_lines  
 end  
        set @retVal = -1  
  
Exit_Good:  
 RETURN @retVal  
GO
GRANT EXECUTE ON  [dbo].[TXavataxlink_sp] TO [public]
GO
