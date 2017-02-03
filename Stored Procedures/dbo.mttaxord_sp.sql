SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
CREATE PROC [dbo].[mttaxord_sp] @match_ctrl_num varchar(16),   
    @curr_precision smallint,  
    @org_id         varchar(30),  
    @vendor_code    varchar(12),  
    @vendor_remitto  varchar(8) = '',   
    @sequence_id    int,       
    @currency_code  varchar(8)   
 AS  
DECLARE     
 @unit_price          float,    
    @qty_invoiced        float,           
    @tax_code            varchar(8),   
    @tax_type_code            varchar(8),         
 @ext_price    decimal(20,8),    
    @trx_type            smallint,        
  
 @item_code           varchar(18),  
 @taxable_flag    smallint,  
 @po_ctrl_int  int,  
 @total_freight float,  
 @inp_seq_id  int,  
 @line_tax  float,  
 @line_included_tax float,  
 @calc_tax  float,  
 @ins_mtinptax_flag smallint,    
                              
                              
 @gbl_sequence_id  int,   
 @tax_connect_flag       smallint,  
 @tax_code_istax_connect smallint,  
 @receipt_ctrl_num       varchar(16),  
  
 @tax_companycode        varchar(255),  
 @remito_flag            smallint,  
 @err                    smallint,  
 @h_doc_type             smallint,  
 @calc_method            char(1),  
 @err_msg                varchar(255),   
 @debug                  int,  
 @total_tax              decimal(20,8),  
 @non_included_tax       decimal(20,8),   
 @included_tax           decimal(20,8),  
 @org_addr1              varchar(40),  
 @org_addr2              varchar(40),  
 @org_addr3              varchar(40),  
 @org_addr4              varchar(40),    
 @org_city               varchar(40),  
 @org_state              varchar(40),  
 @org_postal_code        varchar(15),  
 @org_country            varchar(3),   
 @str_msg     varchar(255),   
 @count     varchar(3)      
  
  
  
   
  
  
   
 CREATE TABLE #TXTaxOutput   
 (  
  control_number varchar(16) not null,  
  amtTotal float,    
  amtDisc float,    
  amtExemption float,    
  amtTax float,  
  remoteDocId bigint  
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
  
   
CREATE TABLE #TxLineInput  
(  
 control_number  varchar(16),  
 reference_number int,  
 tax_code   varchar(8),  
 quantity   float,  
 extended_price  float,  
 discount_amount  float,  
 tax_type   smallint,  
 currency_code  varchar(8)  
)  
create index #TLI_1 on #TxLineInput( control_number, reference_number)  
  
   
CREATE TABLE #TxInfo  
(  
 control_number  varchar(16),  
 sequence_id  int,  
 tax_type_code  varchar(8),  
 amt_taxable   float,  
 amt_gross   float,  
 amt_tax    float,  
 amt_final_tax  float,  
 currency_code  varchar(8),  
 tax_included_flag smallint  
  
)  
create index #TI_1 on #TxInfo( control_number, sequence_id)  
  
   
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
  
  
  
  
  
           
SELECT    
 @trx_type = 1031,  
 @total_freight = 0.0,  
 @inp_seq_id = 0,  
 @ins_mtinptax_flag = 1,  
 @calc_tax = 0.0,  
 @gbl_sequence_id = 0,     
        @err = 0,  
        @debug = 0  
  
 SELECT @tax_connect_flag = tax_connect_flag from apco  
if @debug > 0  
begin  
   
 select 'tax_connect_flag  ' + CONVERT(char(2), @tax_connect_flag)   
   
end  
  
SET ROWCOUNT 0  
  
  
  
  
  
  
  
  
  
  
  
DELETE #mtinptaxdtl  
WHERE match_ctrl_num = @match_ctrl_num  
  
  
  
  SELECT  @match_ctrl_num = #epmchdtl.match_ctrl_num,   
   @tax_code = #epmchdtl.tax_code  
    FROM  #epmchdtl, epinvdtl (nolock)  
    WHERE  #epmchdtl.match_ctrl_num = @match_ctrl_num  
    AND  #epmchdtl.receipt_dtl_key = epinvdtl.receipt_detail_key  
    AND     #epmchdtl.po_sequence_id = epinvdtl.po_sequence_id  
    AND  #epmchdtl.sequence_id = @sequence_id  
  
  
SELECT @tax_code_istax_connect = tax_connect_flag   
       FROM aptax WHERE tax_code = @tax_code  
if @debug > 0  
begin  
  
   SELECT   'tax_code = ' +  @tax_code       
end  
  
    
SELECT  @vendor_remitto = isnull(@vendor_remitto, '')  
SELECT  @remito_flag = CASE WHEN len(@vendor_remitto) > 0  THEN 1 ELSE 0 END  
   
if @debug > 0  
begin   
 select 'tax_connect_flag  ' + CONVERT(char(2), @tax_connect_flag)   
 select 'tax_code_istax_connect ' + CONVERT(char(2), @tax_code_istax_connect)  
end   
  
  
  
DELETE #TXLineInput_ex  
DELETE #txconnhdrinput  
DELETE #txconnlineinput  
  
  
  
  
SELECT  @tax_companycode = isnull(tc_companycode ,''),  
   @org_addr1 = isnull(addr1,''), @org_addr2 = isnull(addr2,''),  
   @org_addr3 = isnull(addr3,''), @org_addr4 = isnull(addr4,''),  
   @org_city  = isnull(city,''), @org_state = isnull(state,''),  
   @org_postal_code  = isnull(postal_code,'' ),    
   @org_country = isnull(country,'')   
FROM Organization_all (nolock) where organization_id = @org_id  
  
select @h_doc_type = 2   -- purchase   
  
  
INSERT #txconnhdrinput  
   (doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,  
 discount, purchaseorderno, customercode, customerusagetype, detaillevel, referencecode,  
 oriaddressline1, oriaddressline2, oriaddressline3, oricity, oriregion,   
 oripostalcode, oricountry,   
 destaddressline1, destaddressline2, destaddressline3,   
 destcity, destregion, destpostalcode,     destcountry,   
 currCode, currRate)  
SELECT @match_ctrl_num, @h_doc_type, 4091, @tax_companycode, getdate(), '', '',  
  0,                    '', @vendor_code,                 '',           3,     '',   
 v.addr1 ,        v.addr2 ,                v.addr3 , v.city ,  v.state ,  
 v.postal_code , v.country_code ,  
 @org_addr1,    @org_addr2,     @org_addr3,    
 @org_city,  @org_state, @org_postal_code,  @org_country,  
 @currency_code, @curr_precision  
FROM   apmaster_all v  (nolock) WHERE  v.vendor_code = @vendor_code  
  
  
  
  
  
  
  
  
  
SELECT @ext_price = Round( @unit_price * @qty_invoiced, @curr_precision )  
   
   
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
                  
  
INSERT #TXLineInput_ex   
  (control_number,   reference_number, currency_code,   
  curr_precision,    tax_code, qty, unit_price,   
  extended_price, seqid)  
SELECT #epmchdtl.match_ctrl_num, #epmchdtl.sequence_id, @currency_code ,  
  @curr_precision, #epmchdtl.tax_code, #epmchdtl.qty_invoiced, #epmchdtl.invoice_unit_price,   
  (SIGN(#epmchdtl.invoice_unit_price * #epmchdtl.qty_invoiced) * ROUND(ABS(#epmchdtl.invoice_unit_price * #epmchdtl.qty_invoiced) + 0.0000001, @curr_precision)), #epmchdtl.sequence_id  
FROM #epmchdtl  
  
  
  
  
    
  
  
  
  
  
  
  
  
  
  
  
  
  
  
if @debug > 0  
begin  
  SELECT '#TXLineInput_ex'  
  SELECT * from #TXLineInput_ex  
  
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
 case when amt_discount <> 0 then 1 else 0 end, h.exemptionno, '', '','', '', TLI.tax_code  
   from #TXLineInput_ex TLI  
 join #txconnhdrinput h on TLI.control_number = h.doccode  
   where not exists (select 1 from #txconnlineinput l where l.doccode = TLI.control_number  
 and l.no = TLI.reference_number)  
  
  
  
     
   
  
   
 IF exists (select 1 from #epmchdtl where match_ctrl_num = @match_ctrl_num  
  and amt_tax != calc_tax) and @tax_code_istax_connect = 1  
 begin  
   
  EXEC appgetstring_sp 'STR_GLTCCUSTOMTAXOVERRIDE', @str_msg OUT  
    
  UPDATE a   
  SET a.taxOverrideReason = @str_msg,  
   a.taxOverrideTaxAmount = b.amt_tax,  
   a.taxOverrideTaxDate = getdate(),  
   a.taxOverrideType = 3   
  FROM #txconnlineinput a, #epmchdtl b   
  WHERE b.match_ctrl_num = @match_ctrl_num  
  AND a.doccode = @match_ctrl_num  
  AND b.sequence_id = a.no  
  AND b.amt_tax != b.calc_tax  
 end  
   
  
  
  EXEC @err = TXCalculateTax_SP  @debug, 1   
   
  
  
if @err <> 1  
begin  
   -- tax avalara error  
   SELECT 'APTXavataxlink_sp   error'  
    SELECT  @err_msg  
   return -1  
end  
   
  
  
  
  
  
  
  
  
if @debug > 0  
begin  
  SELECT '#TXTaxOutput'  
  select * from #TXTaxOutput  
  SELECT '#TXTaxLineOutput'  
  select * from #TXTaxLineOutput  
  SELECT '#TXTaxLineDetOutput'  
  select * from #TXTaxLineDetOutput  
   SELECT '#TXtaxcode'  
   select * from   #TXtaxcode  
   SELECT '#TXtaxtyperec'  
   select * from #TXtaxtyperec    
   SELECT '#TXtaxtype'      
   select * from  #TXtaxtype  
   SELECT 'tax records non includes'   
   SELECT *   FROM #TXtaxcode tc  
     join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
     join    #TXtaxtype tt on tt.ttr_row = ttr.row_id  
 WHERE tc.control_number = @match_ctrl_num   
   AND tc.tax_included_flag = 0  
  SELECT 'tax records detal '   
   select *  
   from #TXTaxLineDetOutput ti  
  join #TXtaxcode tc on tc.control_number = ti.control_number   
    join #TXtaxtyperec ttr on ttr.tc_row =tc.row_id  
    join #TXtaxtype tt on tt.ttr_row = ttr.row_id   
    where tc.control_number = @match_ctrl_num  
  
end  
  
  
select @total_tax=0, @non_included_tax=0, @included_tax=0  
  
  
SELECT @non_included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc  
     join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
     join    #TXtaxtype tt on tt.ttr_row = ttr.row_id  
 WHERE tc.control_number = @match_ctrl_num   
   AND tc.tax_included_flag = 0  
  
SELECT @included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc   
     join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
     join    #TXtaxtype tt on tt.ttr_row = ttr.row_id  
 WHERE tc.control_number = @match_ctrl_num   
  AND tc.tax_included_flag = 1  
  
SELECT @total_tax = @non_included_tax + @included_tax  
  
if @debug > 0  
begin  
 SELECT '@total_tax ' + CONVERT(char(30),@total_tax)  
 SELECT '@non_included_tax ' + CONVERT(char(30),@non_included_tax)  
 SELECT '@included_tax ' + CONVERT(char(30),@included_tax)  
end  
  
  
  
    
   
    
   
 select @gbl_sequence_id = 0  
     
DELETE FROM #mtinptax WHERE match_ctrl_num = @match_ctrl_num  
  
 INSERT INTO #mtinptax( timestamp,  
      match_ctrl_num,  
      trx_type,  
      sequence_id,   
  tax_type_code,  
  amt_taxable,  
  amt_gross,   
  amt_tax,   
  amt_final_tax )   
  SELECT NULL ,   
   @match_ctrl_num ,    
   @trx_type,  
   ttr.seq_id,  
   tt.tax_type,  
   SUM(tt.amt_taxable),   
   SUM(tc.tot_extended_amt),           
   SUM(tt.amt_tax),  
   SUM(tt.amt_final_tax)  
FROM  #TXtaxcode tc  
 join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
 join    #TXtaxtype tt on tt.ttr_row = ttr.row_id  
WHERE tc.control_number = @match_ctrl_num   
GROUP BY ttr.seq_id, tt.tax_type  
  
  
if (exists(select 1 from #TXTaxLineDetOutput where control_number = @match_ctrl_num))  
begin  
  INSERT #mtinptaxdtl ( match_ctrl_num,   
   sequence_id,  
   trx_type,   
   tax_sequence_id,   
   detail_sequence_id,  
   tax_type_code,  
   amt_taxable,  
   amt_gross,  
   amt_tax,  
   amt_final_tax,  
   recoverable_flag,  
       account_code   
    )  
   SELECT @match_ctrl_num ,  
    ti.d_index + 1,  
    @trx_type,    
    ti.d_index + 1,  
    ti.reference_number,  
    tt.tax_type,  
    ti.taxable,  
    ti.taxable + ti.nonTaxable,  
    isnull(ti.amtTaxCalculated, ti.amtTax) ,  
    ti.amtTax ,  
    tt.recoverable_flag,  
    ' '  
  from #TXTaxLineDetOutput ti  
  join #TXtaxcode tc on tc.control_number = ti.control_number   
    join #TXtaxtyperec ttr on ttr.tc_row =tc.row_id  
    join #TXtaxtype tt on tt.ttr_row = ttr.row_id   
    where tc.control_number = @match_ctrl_num  end  
else  
begin  
  INSERT #mtinptaxdtl ( match_ctrl_num,   
   sequence_id,  
   trx_type,   
   tax_sequence_id,   
   detail_sequence_id,  
   tax_type_code,  
   amt_taxable,  
   amt_gross,  
   amt_tax,  
   amt_final_tax,  
   recoverable_flag,  
       account_code   
    )  
   SELECT @match_ctrl_num ,  
    ttr.seq_id,  
    @trx_type,    
    ttr.seq_id,  
    ttr.tc_row,  
    tt.tax_type,  
    tt.amt_taxable,  
    tc.tot_extended_amt,  
    tt.amt_tax ,  
    tt.amt_final_tax ,  
    tt.recoverable_flag,  
    ' '  
  from #TXtaxcode tc  
    join #TXtaxtyperec ttr on ttr.tc_row =tc.row_id  
    join #TXtaxtype tt on tt.ttr_row = ttr.row_id   
end  
  
      
  
  
    IF( ( SELECT COUNT(1) FROM #mtinptaxdtl WHERE sequence_id = -1 ) > 1 )  
    BEGIN  
   SELECT match_ctrl_num, sequence_id, trx_type, tax_sequence_id, detail_sequence_id, tax_type_code, sum( amt_taxable ) AS amt_taxable,   
       sum( amt_gross ) AS amt_gross, sum( amt_tax ) AS amt_tax, sum( amt_final_tax ) AS amt_final_tax, recoverable_flag, account_code  
   INTO #auxdtl  
   FROM #mtinptaxdtl  
   WHERE sequence_id = -1  
   GROUP BY match_ctrl_num, sequence_id, trx_type, tax_sequence_id, detail_sequence_id, tax_type_code, recoverable_flag, account_code  
  
   DELETE #mtinptaxdtl   
   WHERE sequence_id = -1   
  
   INSERT INTO #mtinptaxdtl   
   SELECT NULL, * FROM #auxdtl  
  
   DROP TABLE #auxdtl  
    END  
  
    SET @count = 0  
  
    SELECT @count = CASE COUNT(1) WHEN 1 THEN 0 ELSE sequence_id END  
    FROM #mtinptax   
    GROUP BY sequence_id  
  
    IF( @count > 0 )  
    BEGIN  
   SELECT match_ctrl_num, trx_type, sequence_id, tax_type_code, sum( amt_taxable ) AS amt_taxable, sum( amt_gross ) AS amt_gross,   
       sum( amt_tax ) AS amt_tax, sum( amt_final_tax ) AS amt_final_tax  
   INTO #aux  
   FROM #mtinptax  
   WHERE sequence_id = @count  
   GROUP BY match_ctrl_num, sequence_id, trx_type, tax_type_code  
  
   DELETE #mtinptax   
   WHERE sequence_id = @count  
  
   INSERT INTO #mtinptax   
   SELECT NULL, * FROM #aux  
  
   DROP TABLE #aux  
    END  
      
  
  
  
    UPDATE  dtl  
    SET dtl.account_code = epm.account_code  
    FROM #mtinptaxdtl dtl, #epmchdtl epm  
  WHERE  epm.match_ctrl_num = dtl.match_ctrl_num  
     AND epm.sequence_id  = dtl.sequence_id  
  
  
 if @debug > 0  
 begin  
    SELECT '#TXLineInput_ex'  
    select * from #TXLineInput_ex  
   SELECT '#mtinptax'      
    select * from  #mtinptax  
    SELECT '#epmchdtl'  
    select * from #epmchdtl  
      
  
  end  
  
  
    
 UPDATE epm  
 SET epm.amt_tax = (SIGN(TXL.calc_tax) * ROUND(ABS(TXL.calc_tax) + 0.0000001, @curr_precision)),  
  epm.calc_tax = (SIGN(TXL.amtTaxCalculated) * ROUND(ABS(TXL.amtTaxCalculated) + 0.0000001, @curr_precision))  
 FROM #epmchdtl epm,  #TXLineInput_ex TXL   
  WHERE   epm.match_ctrl_num = TXL.control_number  
   AND  TXL.seqid  = epm.sequence_id   
   AND TXL.control_number = @match_ctrl_num  
    
   
  
  
   
     
  
      
      
      
  
  
  
  
   
  
UPDATE #mtinptax  
SET amt_taxable = (SIGN(amt_taxable) * ROUND(ABS(amt_taxable) + 0.0000001, @curr_precision)),  
 amt_gross = (SIGN(amt_gross) * ROUND(ABS(amt_gross) + 0.0000001, @curr_precision)),  
 amt_tax = (SIGN(amt_tax) * ROUND(ABS(amt_tax) + 0.0000001, @curr_precision)),  
 amt_final_tax = (SIGN(amt_final_tax) * ROUND(ABS(amt_final_tax) + 0.0000001, @curr_precision))   
WHERE match_ctrl_num = @match_ctrl_num   
   
  
  
  
  
 DROP TABLE #TxLineInput  
 DROP TABLE #TxInfo  
   
   
   
   
   
   
 DROP TABLE #TXLineInput_ex  
        DROP TABLE #txconnhdrinput  
        DROP TABLE #txconnlineinput   
  
  
GO
GRANT EXECUTE ON  [dbo].[mttaxord_sp] TO [public]
GO
