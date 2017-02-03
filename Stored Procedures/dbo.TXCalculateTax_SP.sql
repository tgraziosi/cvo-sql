SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 16/06/2014 - Performance  
-- v1.1 CB 16/01/2017 - Overflow Issue
  
CREATE PROC [dbo].[TXCalculateTax_SP] @debug int = 0, @distr_call int = 0  
AS  
BEGIN  
  
DECLARE @link_id int,  
  @max_base_id int, @this_base_id int,        
  @taxconn smallint,  
  @err int,  
  @ti_row int, @ti_tax_code varchar(8),  
  @ti_control_number varchar(16),  
  @h_doc_type smallint,  
  @err_msg varchar(255),  
  @company_id int,  
  @tax_connect_flag int,  
  @curr_code varchar(8)  
  
  
-- get taxes from Financial table  
  
if @distr_call = 0  
begin  
  
  
CREATE TABLE #TXLineInput_ex  
(  
  row_id int identity,  
  control_number varchar(16) not null,  
  reference_number int not null,  
  trx_type smallint not null default(0),  
  currency_code varchar(8),  
  curr_precision int,  
  amt_tax decimal(20,8) default(0),  
  amt_final_tax decimal(20,8) default(0),  
  tax_code varchar(8),  
  freight decimal(20,8)  default(0),  
  qty decimal(20,8) default(1),  
  unit_price decimal(20,8) default(0),  
  extended_price decimal(20,8) default(0),  
  amt_discount decimal(20,8) default(0),  
  err_no int default(0),  
  action_flag smallint  default(0),  
  seqid int,  
  calc_tax decimal(20,8) default(0),  
  vat_prc decimal(20,8) default(0),  
  amt_nonrecoverable_tax decimal(20,8) default(0),  
  amtTaxCalculated decimal(20,8) default(0)  
)  
create index TXti1 on #TXLineInput_ex(control_number,row_id)  
create index TXti2 on #TXLineInput_ex(control_number, reference_number)  
create index TXti3 on #TXLineInput_ex(row_id)  
  
  
  
create table #TXtaxtype (  
  row_id int identity,  
  ttr_row int,  
  tax_type varchar(8),  
  ext_amt decimal(20,8),  
  amt_gross decimal(20,8),  
  amt_taxable decimal(20,8),  
  amt_tax decimal(20,8),  
  amt_final_tax decimal(20,8),  
  amt_tax_included decimal(20,8),  
  save_flag smallint,  
  tax_rate decimal(20,8),  
  prc_flag smallint,  
  prc_type int,  
  cents_code_flag smallint,  
  cents_code varchar(8),  
  cents_cnt int,  
  tax_based_type int,  
  tax_included_flag smallint,  
  modify_base_prc decimal(20,8),  
  base_range_flag smallint,  
  base_range_type int,  
  base_taxed_type int,  
  min_base_amt decimal(20,8),  
  max_base_amt decimal(20,8),  
  tax_range_flag smallint,  
  tax_range_type int,  
  min_tax_amt decimal(20,8),  
  max_tax_amt decimal(20,8),  
  recoverable_flag smallint,  
  dtl_incl_ind int NULL  
)  
create index Txtt1 on #TXtaxtype(row_id)  
create index Txtt2 on #TXtaxtype(ttr_row)  
  
  
  
create table #TXtaxtyperec (  
  row_id int identity,  
  tc_row int,  
  tax_code varchar(8),  
  seq_id int,  
  base_id int,  
  cur_amt decimal(20,8),  
  old_tax decimal(20,8),  
  tax_type varchar(8)  
)  
create index Txttr1 on #TXtaxtyperec(row_id)  
create index Txttr2 on #TXtaxtyperec(tc_row)  
create index Txttr3 on #TXtaxtyperec(tax_code, tc_row, seq_id)  
  
  
  
create table #TXtaxcode (  
  row_id int identity,  
  ti_row int,  
  control_number varchar(16),  
  tax_code varchar(8),  
  amt_tax decimal(20,8),  
  tax_included_flag smallint,  
  tax_type_cnt int,  
  tot_extended_amt decimal(20,8) NULL  
)  
create index Txtc1 on #TXtaxcode(row_id)  
create index Txtc2 on #TXtaxcode(control_number, tax_code)  
  
  
  
create table #TXcents (  
  row_id int identity,  
  cents_code varchar(8),  
  to_cent decimal(20,8),  
  tax_cents decimal(20,8)  
)  
create index Txc1 on #TXcents(cents_code,row_id)  
  
  
  
 CREATE TABLE #TXTaxOutput   
 (  
  control_number varchar(16) not null,  
  amtTotal float,    
  amtDisc float,    
  amtExemption float,    
  amtTax float,  
  remoteDocId bigint  -- v1.1
 )  
  
 CREATE INDEX #TTO_1 on #TXTaxOutput( control_number )  
  
  
  
 CREATE TABLE #TXTaxLineOutput   
 (  
  control_number varchar(16) not null,  
  reference_number int not null,  
  t_index int,  
  taxRate float,    
  taxable float,    
  taxCode varchar(8),  
  taxability varchar(10),  
  amtTax  float,    
  amtDisc float,    
  amtExemption float,    
  taxDetailCnt int,  
  amtTaxCalculated  float  
 )  
  
 CREATE INDEX #TTLO_1 on #TXTaxLineOutput( control_number, t_index)  
  
  
  
 CREATE TABLE #TXTaxLineDetOutput   
 (  
  control_number varchar(16) not null,  
  reference_number int not null,  
  t_index int,  
  d_index int,  
  amtBase float,    
  exception smallint,  
  jurisCode varchar(30),  
  jurisName varchar(255),  
  jurisType varchar(30),  
  nonTaxable float,    
  taxRate float,    
  amtTax float,    
  taxable float,    
  taxType smallint,    
  amtTaxCalculated float  
 )  
  
 CREATE INDEX #TTLDO_1 on #TXTaxLineDetOutput( control_number, t_index, d_index)  
 CREATE INDEX #TTLDO_2 on #TXTaxLineDetOutput( control_number, jurisCode, jurisType)  
  
  
 IF OBJECT_ID('tempdb..#txinfo_id') IS NULL  
  CREATE TABLE #txinfo_id  
  ( id_col   numeric identity,control_number  varchar(16), sequence_id  int,  
   tax_type_code  varchar(8), currency_code  varchar(8)      )  
  
 CREATE TABLE #TXInfo_min_id   
 ( control_number   varchar(16), min_id_col  numeric       )  
  
  
 insert #TXLineInput_ex (control_number, reference_number, trx_type, currency_code, curr_precision,  
 tax_code, qty, unit_price, extended_price, amt_discount, seqid, vat_prc)     
 select TLI.control_number, TLI.reference_number, TLI.tax_type,  
 TLI.currency_code, isnull(gc.curr_precision,1),  
 TLI.tax_code, TLI.quantity,   
 case when TLI.quantity != 0 then TLI.extended_price / TLI.quantity else TLI.extended_price end,   
 TLI.extended_price,    
 TLI.discount_amount, 0, 0  
 from #TxLineInput TLI  
 left outer join glcurr_vw gc (nolock) on gc.currency_code = TLI.currency_code  
 where TLI.tax_type = 0  
 order by control_number, reference_number  
  
 update #TXLineInput_ex  
 set seqid = row_id  
  
 insert #TXLineInput_ex (control_number, reference_number, trx_type, currency_code, curr_precision,   
 tax_code, freight, action_flag, seqid, vat_prc)  
 select TLI.control_number, TLI.reference_number, TLI.tax_type,  
 TLI.currency_code, isnull(gc.curr_precision,1),  
 TLI.tax_code, TLI.extended_price, 1, 1, 0  
 from #TxLineInput TLI  
 left outer join glcurr_vw gc (nolock) on gc.currency_code = TLI.currency_code  
 where TLI.tax_type = 1  
 order by control_number, reference_number  
   
 insert #TXLineInput_ex   
 (control_number, reference_number, trx_type, currency_code, curr_precision, tax_code, qty,   
 unit_price, extended_price, action_flag, amt_discount, seqid, vat_prc)  
 select TLI.control_number, TLI.reference_number, TLI.tax_type,  
 TLI.currency_code, isnull(gc.curr_precision,1),  
 TLI.tax_code, 1, TLI.extended_price, TLI.extended_price, 2, 0, 1, 0   
 from #TxLineInput TLI  
 left outer join glcurr_vw gc (nolock) on gc.currency_code = TLI.currency_code  
 where TLI.tax_type = 2  
 order by control_number, reference_number   
end  
  
delete from #TxInfo  
delete from #TXtaxtype  
delete from #TXtaxtyperec  
delete from #TXtaxcode  
delete from #TXcents  
delete from #TXTaxOutput  
delete from #TXTaxLineOutput  
delete from #TXTaxLineDetOutput  
  
  
IF OBJECT_ID('tempdb..#txconnhdrinput') IS NULL  
BEGIN  
   
 CREATE TABLE #txconnhdrinput   
 (  
  doccode varchar(16),  
  doctype smallint,  
  trx_type smallint,  
  companycode  varchar(25),  
  docdate  datetime,  
  exemptionno  varchar(20),  
  salespersoncode varchar(20),  
  discount  float,    
  purchaseorderno varchar(20),  
  customercode  varchar(20),  
  customerusagetype varchar(20) ,  
  detaillevel  varchar(20) ,  
  referencecode  varchar(20) ,  
  oriaddressline1 varchar(40),  
  oriaddressline2 varchar(40),  
  oriaddressline3 varchar(40),  
  oricity varchar(40),  
  oriregion varchar(40),  
  oripostalcode varchar(40),  
  oricountry varchar(40),  
  destaddressline1 varchar(40),  
  destaddressline2 varchar(40),  
  destaddressline3 varchar(40),  
  destcity varchar(40),  
  destregion varchar(40),  
  destpostalcode varchar(40),  
  destcountry varchar(40),  
  currCode varchar(8),  
  currRate decimal(20,8),  
  currRateDate datetime null,  
  locCode varchar(20) null,  
  paymentDt datetime null,  
  taxOverrideReason varchar(100) null,  
  taxOverrideAmt decimal(20,8) null,  
  taxOverrideDate datetime null,  
  taxOverrideType int null,  
  commitInd int null    
 )  
  
 CREATE INDEX TCHI_1 on #txconnhdrinput( doctype, doccode)  
 CREATE INDEX TCHI_2 on #txconnhdrinput( doccode)  
  
  
   
 CREATE TABLE #txconnlineinput   
 (  
  doccode varchar(16),  
  no varchar(20),  
  oriaddressline1 varchar(40),  
  oriaddressline2 varchar(40),  
  oriaddressline3 varchar(40),  
  oricity varchar(40),  
  oriregion varchar(40),  
  oripostalcode varchar(40),  
  oricountry varchar(40),  
  destaddressline1 varchar(40),  
  destaddressline2 varchar(40),  
  destaddressline3 varchar(40),  
  destcity varchar(40),  
  destregion varchar(40),  
  destpostalcode varchar(40),  
  destcountry varchar(40),  
  qty float,    
  amount float,    
  discounted smallint,   
  exemptionno varchar(20),  
  itemcode varchar(40) ,  
  ref1 varchar(20) ,  
  ref2 varchar(20) ,  
  revacct varchar(20) ,  
  taxcode varchar(8),  
  customerUsageType varchar(20) null,  
  description varchar(255) null,  
  taxIncluded int null,  
  taxOverrideReason varchar(100) null,  
  taxOverrideTaxAmount decimal(20,8) null,  
  taxOverrideTaxDate datetime null,  
  taxOverrideType int null  
 )  
  
 create index TCLI_1 on #txconnlineinput( doccode, no)  
  
  
  
    if exists (select 1 from #TXLineInput_ex TLI  
      join artax T (nolock) on T.tax_code = TLI.tax_code and T.tax_connect_flag = 1)  
    begin  
      insert #TXTaxLineDetOutput (control_number, reference_number, t_index, d_index, amtBase, exception,  
        jurisCode, jurisName, jurisType, nonTaxable, taxRate, amtTax, taxable, taxType)  
     SELECT DISTINCT control_number, -1, -95, 0, 0, 0,   
        '', 'Cannot use tax connect tax code when txconnhdrinput table not prepopulated', 0, 0, 0, 0, 0, 0  
      from #TXLineInput_ex  
  
      return -95  
    end    
  
 insert #txconnhdrinput  
 (doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,  
 discount, purchaseorderno, customercode, customerusagetype, detaillevel,  
 referencecode, oriaddressline1, oriaddressline2, oriaddressline3,  
 oricity, oriregion, oripostalcode, oricountry, destaddressline1,  
 destaddressline2, destaddressline3, destcity, destregion, destpostalcode,  
 destcountry,  currCode, currRate)  
 SELECT DISTINCT control_number, -1, trx_type, '', getdate(), '','',  
 0, '', '', '', 3,  
 '', '', '', '',  
 '', '', '', '', '',  
 '', '', '', '', '',  
 '', currency_code, 1.0  
 FROM #TXLineInput_ex  
END  
  
  
if exists (select 1 from #TXLineInput_ex TLI   
  where not exists (select 1 from #txconnhdrinput where doccode = TLI.control_number))  
  return -112  
  
if exists (select 1 from #TXLineInput_ex TLI  
  where not exists (select 1 from #txconnlineinput CLI where TLI.control_number = CLI.doccode  
  and TLI.reference_number = CLI.no))  
begin  
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
    h.destcountry,  TLI.qty, case action_flag when 1 then TLI.freight else TLI.extended_price - TLI.amt_discount end,   
    case when amt_discount <> 0 then 1 else 0 end, h.exemptionno,   
 case action_flag when 1 then 'Freight' when 2 then 'Miscellaneous' else '' end,   
 '','', '', TLI.tax_code  
  from #TXLineInput_ex TLI  
  join #txconnhdrinput h on TLI.control_number = h.doccode  
  where not exists (select 1 from #txconnlineinput l where l.doccode = TLI.control_number  
    and l.no = TLI.reference_number)  
end  
  
DECLARE doc_type CURSOR LOCAL STATIC FOR  
select distinct doctype  
FROM #txconnhdrinput h  
join #TXLineInput_ex TLI on TLI.control_number = h.doccode  
order by doctype  
  
OPEN doc_type  
  
FETCH NEXT FROM doc_type into @h_doc_type  
  
While @@FETCH_STATUS = 0  
begin  
  set @taxconn = 0  
  if @h_doc_type in (0,1,4,5)  -- AR types  
  begin  
    if exists (select 1 from #TXLineInput_ex TLI  
      join #txconnhdrinput h on h.doctype = @h_doc_type and h.doccode = TLI.control_number  
      join artax T (nolock) on T.tax_code = TLI.tax_code and T.tax_connect_flag = 1)  
    begin  
      select @company_id = company_id,  
        @tax_connect_flag = tax_connect_flag  
      from arco (nolock)  
  
      if isnull(@tax_connect_flag,0) = 1  
        set @taxconn = 1  
      else  
        set @taxconn = -1  
    end  
  end  
  if @h_doc_type in (2,3)  -- AP types  
  begin  
    if exists (select 1 from #TXLineInput_ex TLI  
      join #txconnhdrinput h on h.doctype = @h_doc_type and h.doccode = TLI.control_number  
      join artax T (nolock) on T.tax_code = TLI.tax_code and T.tax_connect_flag = 1)  
    begin  
      select @company_id = company_id,  
        @tax_connect_flag = tax_connect_flag  
      from apco (nolock)  
  
      if isnull(@tax_connect_flag,0) = 1  
        set @taxconn = 1  
      else  
        set @taxconn = -1  
    end  
  end  
  -- if tax code uses tax connect and tax_connect not integrated  
  if @taxconn = -1  
  begin  
    insert #TXTaxLineDetOutput (control_number, reference_number, t_index, d_index, amtBase, exception,  
      jurisCode, jurisName, jurisType, nonTaxable, taxRate, amtTax, taxable, taxType)  
    select doccode, -1, -110, 0, 0, 0,   
      '', 'Cannot use tax connect tax code when tax integration not activated', 0, 0, 0, 0, 0, 0  
    from #txconnhdrinput where doctype = @h_doc_type  
  
   return -110  
  end  
  -- if tax code uses tax connect  
  if @taxconn = 1   
  begin  
    -- all tax codes on document must use tax connect if at least one does otherwise error  
    if exists (select 1 from #TXLineInput_ex TLI  
    join #txconnhdrinput h on h.doctype = @h_doc_type and h.doccode = TLI.control_number  
    join artax T (nolock) on T.tax_code = TLI.tax_code and T.tax_connect_flag = 0)  
      return -101  
  
    if exists (select 1 from  #TXLineInput_ex TLI  
      where  currency_code not in   
      (select currency_code from gltc_currency (nolock)))  
    begin  
     select top 1 @curr_code = currency_code  
   from  #TXLineInput_ex TLI  
        where  currency_code not in   
        (select currency_code from gltc_currency (nolock))  
  
      select @err_msg = 'Cannot use tax connect tax code because ' +  
        isnull(@curr_code,'<NULL>') + ' is not a supported tax connect currency'   
  
      insert #TXTaxLineDetOutput (control_number, reference_number, t_index, d_index, amtBase, exception,  
        jurisCode, jurisName, jurisType, nonTaxable, taxRate, amtTax, taxable, taxType)  
      select doccode, -1, -111, 0, 0, 0,   
        '', @err_msg, 0, 0, 0, 0, 0, 0  
      from #txconnhdrinput where doctype = @h_doc_type  
  
      return -111  
  
    end  
  
    exec @err = TXavataxlink_sp @h_doc_type, @err_msg output, @debug  
  
    if not exists (select 1 from #TxLineInput)  
    begin  
      insert #TXTaxLineDetOutput (control_number, reference_number, t_index, d_index, amtBase, exception,  
        jurisCode, jurisName, jurisType, nonTaxable, taxRate, amtTax, taxable, taxType)  
      select doccode, -1, @err, 0, 0, 0,   
        '', @err_msg, 0, 0, 0, 0, 0, 0  
      from #txconnhdrinput where doctype = @h_doc_type  
    end  
  
    if @err <> 1  
      return @err  
  end  
  else  
  begin  
  -- not tax connect  
  select @ti_row = isnull((select min(row_id) from #TXLineInput_ex TLI  
    join #txconnhdrinput h on h.doctype = @h_doc_type and h.doccode = TLI.control_number),0)  
  while @ti_row <> 0  
  begin  
    select @ti_tax_code = tax_code,  
      @ti_control_number = control_number  
    from #TXLineInput_ex where row_id = @ti_row  
  
    if @h_doc_type = 1 -- salesinvoice  
    begin  
      delete from gltcrecon  
      where trx_ctrl_num = @ti_control_number and trx_type in (2031,2032)  
    end  
    if @h_doc_type = 3 -- purchaseinvoice  
    begin  
      delete from gltcrecon  
      where trx_ctrl_num = @ti_control_number and trx_type in (4091,4092)  
    end  
  
    exec @err = TXCalTaxCode_sp @ti_row, @ti_tax_code, @ti_control_number, @debug  
  
    if @err <> 1   
    begin  
      return @err  
    end  
      select @ti_row = isnull((select min(row_id) from #TXLineInput_ex TLI  
        join #txconnhdrinput h on h.doctype = @h_doc_type and h.doccode = TLI.control_number  
        where row_id > @ti_row),0)  
  end  
  end  
  FETCH NEXT FROM doc_type into @h_doc_type  
end  
  
close doc_type  
deallocate doc_type  
  
if @distr_call = 0  
begin  
 INSERT #TxInfo (control_number, sequence_id, tax_type_code,  
 amt_taxable, amt_gross, amt_tax,  
 amt_final_tax, currency_code, tax_included_flag)  
 SELECT tc.control_number, ti.reference_number, tt.tax_type,  
 sum(tt.amt_taxable), sum(tt.amt_gross), sum(tt.amt_tax), sum(tt.amt_final_tax),  
 ti.currency_code, tc.tax_included_flag  
 FROM #TXtaxcode tc  
  join #TXLineInput_ex ti on ti.row_id = tc.ti_row  
        join #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join #TXtaxtype tt on tt.ttr_row = ttr.row_id  
        group by tc.control_number, ti.reference_number, tt.tax_type, ti.currency_code, tc.tax_included_flag  
  
        INSERT #txinfo_id (  
        control_number,   
        sequence_id,  
        tax_type_code,  
        currency_code)  
        SELECT  
        control_number,   
        0,  
        tax_type_code,  
        currency_code  
        FROM #TxInfo   
        ORDER BY control_number  
  
        INSERT #TXInfo_min_id (control_number, min_id_col)  
        SELECT control_number, MIN(id_col)   
        FROM #txinfo_id   
        GROUP BY control_number  
   
        UPDATE #txinfo_id  
        SET sequence_id = id_col - min_id_col + 1  
        FROM #TXInfo_min_id  
        WHERE #txinfo_id.control_number = #TXInfo_min_id.control_number  
   
        UPDATE #TxInfo  
        SET sequence_id = #txinfo_id.sequence_id  
        FROM #txinfo_id  
        WHERE #TxInfo.control_number = #txinfo_id.control_number  
        AND #TxInfo.tax_type_code = #txinfo_id.tax_type_code  
        AND #TxInfo.currency_code = #txinfo_id.currency_code  
  
  
 SELECT control_number,        -- mls 10/23/00 SCR 24721 start  
  reference_number 'sequence_id',  
  #TxLineInput.tax_code,  
  artxtype.prc_flag,  
  artxtype.prc_type,  
  artxtype.tax_based_type,  
  artxtype.tax_included_flag,  
  sum(artxtype.amt_tax) 'amt_tax'  
 into #TxType_Sum  
 FROM #TxLineInput  
    join artaxdet (nolock) on #TxLineInput.tax_code = artaxdet.tax_code  
    join artxtype (nolock) on artaxdet.tax_type_code = artxtype.tax_type_code   
 GROUP BY #TxLineInput.control_number, #TxLineInput.reference_number, #TxLineInput.tax_code,  
  artxtype.prc_flag, artxtype.prc_type, artxtype.tax_based_type,   
  artxtype.tax_included_flag      -- mls 10/23/00 SCR 24721 end  
  
 insert into #txdetail (  control_number ,  
   reference_number ,  
   tax_type_code  ,  
   amt_taxable  )  
      SELECT #TxLineInput.control_number,  
      #TxLineInput.reference_number,                
   artaxdet.tax_type_code,  
      CASE artxtype.tax_included_flag                                                                                      
        when 0 then   
          CASE artxtype.prc_flag  
          when 0 then artxtype.amt_tax   
          when 1 then (SIGN((#TxLineInput.extended_price - #TxLineInput.discount_amount) * (artxtype.modify_base_prc / 100.0) * (artxtype.amt_tax / 100.0)) * ABS((#TxLineInput.extended_price - #TxLineInput.discount_amount) * (artxtype.modify_base_prc / 100.0) * (artxtype.amt_tax / 100.0)))  
          end  
        when 1 then   
          CASE artxtype.prc_flag  
          when 0 then artxtype.amt_tax   
          when 1 then (SIGN(((#TxLineInput.extended_price - #TxLineInput.discount_amount) / (1.0 + (#TxType_Sum.amt_tax/100.0))) * (artxtype.amt_tax/100)) * ABS(((#TxLineInput.extended_price - #TxLineInput.discount_amount) / (1.0 + (#TxType_Sum.amt_tax/100.0))) * (artxtype.amt_tax/100))) end  
        end   
      FROM   #TxLineInput  
      join aptax (NOLOCK) on (#TxLineInput.tax_code = aptax.tax_code and aptax.tax_connect_flag = 0)  
      join artaxdet (NOLOCK) on #TxLineInput.tax_code    = artaxdet.tax_code  
      join artxtype (NOLOCK) on artaxdet.tax_type_code = artxtype.tax_type_code and artxtype.tax_based_type = 0   
      join glcurr_vw (NOLOCK) on glcurr_vw.currency_code = #TxLineInput.currency_code  
      join #TxType_Sum on #TxLineInput.control_number       = #TxType_Sum.control_number                           
            AND     #TxLineInput.reference_number   = #TxType_Sum.sequence_id  
            AND     #TxLineInput.tax_code                = #TxType_Sum.tax_code  
            AND     artxtype.prc_flag                        = #TxType_Sum.prc_flag  
            AND     artxtype.prc_type                       = #TxType_Sum.prc_type  
            AND     artxtype.tax_based_type            = #TxType_Sum.tax_based_type  
            AND     artxtype.tax_included_flag          = #TxType_Sum.tax_included_flag            
      WHERE #TxLineInput.tax_type    = 0   
   
   insert into #txdetail (  control_number ,  
  reference_number ,  
  tax_type_code  ,  
  amt_taxable  )  
      SELECT #TxLineInput.control_number,      
                        #TxLineInput.reference_number,                
                        artaxdet.tax_type_code,  
                        (SIGN(#TxLineInput.quantity * (artxtype.modify_base_prc / 100.0) * artxtype.amt_tax) * ABS(#TxLineInput.quantity * (artxtype.modify_base_prc / 100.0) * artxtype.amt_tax) )  
      FROM   #TxLineInput  
      join aptax  (NOLOCK) on (#TxLineInput.tax_code = aptax.tax_code and aptax.tax_connect_flag = 0)  
      join artaxdet  (NOLOCK) on #TxLineInput.tax_code    = artaxdet.tax_code  
      join artxtype (NOLOCK) on artaxdet.tax_type_code = artxtype.tax_type_code and artxtype.tax_based_type = 1  
        AND artxtype.tax_included_flag   = 0  
      join glcurr_vw (NOLOCK) on glcurr_vw.currency_code = #TxLineInput.currency_code  
      WHERE #TxLineInput.tax_type         = 0   
        
        
  
  
   insert into #txdetail (  control_number ,  
  reference_number ,  
  tax_type_code  ,  
  amt_taxable  )    
  SELECT #TXtaxcode.control_number, #TXTaxLineDetOutput.reference_number, #TXtaxtype.tax_type,   
  #TXTaxLineDetOutput.amtTax  
  from #TXtaxcode   
   join #TXtaxtyperec on (#TXtaxcode.row_id = #TXtaxtyperec.tc_row)   
   join #TXtaxtype  on #TXtaxtype.ttr_row = #TXtaxtyperec.row_id  
   join #TXTaxLineDetOutput on (#TXTaxLineDetOutput.control_number = #TXtaxcode.control_number  
    and #TXTaxLineDetOutput.reference_number = #TXtaxtyperec.seq_id)  
   join aptax (nolock) on (#TXtaxcode.tax_code = aptax.tax_code and aptax.tax_connect_flag = 1)  
     
  insert into #txdetail (  control_number ,  
  reference_number ,  
  tax_type_code  ,  
  amt_taxable  )  
  SELECT #TXtaxcode.control_number, #TXTaxLineDetOutput.reference_number, #TXtaxtype.tax_type,   
  #TXTaxLineDetOutput.amtTax  
  from #TXtaxcode   
   join #TXtaxtyperec on (#TXtaxcode.row_id = #TXtaxtyperec.tc_row)   
   join #TXtaxtype  on #TXtaxtype.ttr_row = #TXtaxtyperec.row_id  
   join #TXTaxLineDetOutput on (#TXTaxLineDetOutput.control_number = #TXtaxcode.control_number  
    and #TXTaxLineDetOutput.reference_number = 0)  
   join aptax (nolock) on (#TXtaxcode.tax_code = aptax.tax_code and aptax.tax_connect_flag = 1)     
        
  
  
  
   insert into #txdetail (  control_number ,  
  reference_number ,  
  tax_type_code  ,  
  amt_taxable  )  
      SELECT #TxLineInput.control_number,   
             #TxLineInput.reference_number,  
             artaxdet.tax_type_code,  
            (SIGN((#TxLineInput.extended_price - discount_amount) * (artxtype.amt_tax / 100.0)) *             ABS((#TxLineInput.extended_price - discount_amount) * (artxtype.amt_tax / 100.0)))  
      FROM   #TxLineInput  
      join artaxdet (NOLOCK) on #TxLineInput.tax_code    = artaxdet.tax_code  
      join artxtype (NOLOCK) on artaxdet.tax_type_code = artxtype.tax_type_code and artxtype.tax_based_type = 2  
        AND artxtype.tax_included_flag   = 0  
      join glcurr_vw (NOLOCK) on glcurr_vw.currency_code = #TxLineInput.currency_code  
      WHERE #TxLineInput.tax_type         = 1  
     
   
  
  
 IF OBJECT_ID('tempdb..#TXCalcInpTaxDtl') IS NOT NULL  
 BEGIN  
  if (exists(select 1 from #TXTaxLineDetOutput ))  
  begin  
   EXEC('  
   INSERT INTO #TXCalcInpTaxDtl  
   ( control_number, sequence_id, trx_type, tax_sequence_id, detail_sequence_id,  
   tax_type_code, amt_taxable, amt_gross, amt_tax, amt_final_tax, recoverable_flag )   
   SELECT ti.control_number ,  
     ti.d_index + 1,  
     hdr.trx_type,    
     ti.d_index + 1,  
     ti.reference_number,  
     tt.tax_type,  
     ti.taxable * (case when hdr.trx_type in (2032, 4092) then -1 else 1 end),  
     (ti.taxable + ti.nonTaxable) * (case when hdr.trx_type in (2032, 4092) then -1 else 1 end),  
     ti.amtTaxCalculated * (case when hdr.trx_type in (2032, 4092) then -1 else 1 end),  
     ti.amtTax * (case when hdr.trx_type in (2032, 4092) then -1 else 1 end),  
     tt.recoverable_flag  
   from #TXTaxLineDetOutput ti  
   join #TXtaxcode tc on tc.control_number = ti.control_number   
   join #TXtaxtyperec ttr on ttr.tc_row =tc.row_id  
   join #TXtaxtype tt on tt.ttr_row = ttr.row_id   
   join #txconnhdrinput hdr on hdr.doccode = ti.control_number  
   where ti.reference_number <> -1   
   ')   
     
   EXEC('  
    UPDATE tx SET tx.account_code = b.sales_tax_acct_code,  
    tx. tax_type_code = a.freight_tax_type_code   
    FROM #TXCalcInpTaxDtl tx  
    join gltcconfig a (NOLOCK) on (1=1)  
    join artxtype b (NOLOCK) on (a.freight_tax_type_code = b.tax_type_code)  
    where tx.detail_sequence_id = 0 and b.tax_connect_flag = 1  
   ')  
   end  
  else  
  begin  
   EXEC('  
   INSERT INTO #TXCalcInpTaxDtl  
   ( control_number, sequence_id, trx_type, tax_sequence_id, detail_sequence_id,  
   tax_type_code, amt_taxable, amt_gross, amt_tax, amt_final_tax, recoverable_flag )   
   SELECT tc.control_number,  
     ttr.seq_id,  
     hdr.trx_type,  
     ttr.seq_id,  
     ttr.tc_row,  
     tt.tax_type,  
     tt.amt_taxable,  
     tc.tot_extended_amt,  
     tt.amt_tax ,  
     tt.amt_final_tax ,  
     tt.recoverable_flag  
   from #TXtaxcode tc  
   join #TXtaxtyperec ttr on ttr.tc_row =tc.row_id  
   join #TXtaxtype tt on tt.ttr_row = ttr.row_id   
   join #txconnhdrinput hdr on hdr.doccode = tc.control_number  
   ')  
  end  
 END  
     
end  
  
return 1     
end  
  
GO
GRANT EXECUTE ON  [dbo].[TXCalculateTax_SP] TO [public]
GO
