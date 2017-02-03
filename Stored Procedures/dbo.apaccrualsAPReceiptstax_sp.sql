SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*                                                        
               Confidential Information                    
    Limited Distribution of Authorized Persons Only         
    Created 2008 and Protected as Unpublished Work         
          Under the U.S. Copyright Act of 1976              
 Copyright (c) 2008 Epicor Software Corporation, 2008      
                  All Rights Reserved                      
*/                                                  
  
CREATE PROC [dbo].[apaccrualsAPReceiptstax_sp]  
as  
  
   
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
  taxDetailCnt int  
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
  taxType smallint  
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
  destcountry varchar(40)  
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
  taxcode varchar(8)  
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
  amt_nonrecoverable_tax decimal(20,8) default(0)  
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
  
  
DECLARE   
 @organization_id varchar(30),  
 @h_doc_type  smallint,  
 @trx_type  int,  
 @tmp_ctrl_num varchar(16)  
  
  
select @h_doc_type = 2   -- purchase   
select @trx_type = 4091   -- purchase   
  
  
  
select TOP 1 @tmp_ctrl_num = tmp_ctrl_num, @organization_id = organization_id from #APReceipts_tmp  
order by tmp_ctrl_num  
  
  
WHILE @tmp_ctrl_num IS NOT NULL  
BEGIN  
  
   
 delete from #TXTaxOutput  
 delete from #TXTaxLineOutput  
 delete from #TXTaxLineDetOutput  
 delete from #TxLineInput  
 delete from #TxInfo  
 delete from #txconnhdrinput  
 delete from #txconnlineinput  
 delete from #TXLineInput_ex  
 delete from #TXtaxtype  
 delete from #TXtaxtyperec  
 delete from #TXtaxcode  
 delete from #TXcents  
  
   
 INSERT #txconnhdrinput  
    (doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,  
  discount, purchaseorderno, customercode, customerusagetype, detaillevel, referencecode,  
  oriaddressline1, oriaddressline2, oriaddressline3, oricity, oriregion,   
  oripostalcode, oricountry,   
  destaddressline1, destaddressline2, destaddressline3,   
  destcity, destregion, destpostalcode,     destcountry)  
 SELECT ah.receipt_ctrl_num, @h_doc_type, @trx_type, o.tc_companycode, getdate(), '', '',  
   0,                    '', ah.vendor_code,                 '',           3,     '',   
  v.addr1 ,        v.addr2 ,                v.addr3 , v.city ,  v.state ,  
  v.postal_code , v.country_code ,  
  o.addr1,    o.addr2,     o.addr3,    
  o.city,  o.state, o.postal_code,  o.country  
 FROM   epinvhdr ah  
  JOIN apmaster_all v (nolock) ON (v.vendor_code = ah.vendor_code)  
  JOIN Organization_all o (nolock) ON (o.organization_id = @organization_id)  
 WHERE ah.receipt_ctrl_num = @tmp_ctrl_num  
  
  
 INSERT #TXLineInput_ex   
   (control_number,   reference_number, currency_code,   
   curr_precision,    tax_code, qty, unit_price,   
   extended_price, seqid)  
 SELECT ad.receipt_ctrl_num,  ad.sequence_id, hdr.nat_cur_code,  
   c.curr_precision, ad.tax_code, (ad.qty_received - ad.qty_invoiced), ad.unit_price,   
   (SIGN(ad.unit_price * (ad.qty_received - ad.qty_invoiced)) * ROUND(ABS(ad.unit_price * (ad.qty_received - ad.qty_invoiced)) + 0.0000001, c.curr_precision)), ad.sequence_id  
 FROM epinvdtl ad   
  JOIN epinvhdr hdr (nolock) on (ad.receipt_ctrl_num = hdr.receipt_ctrl_num)  
  JOIN glcurr_vw c (nolock) on (hdr.nat_cur_code = c.currency_code)  
 WHERE ( ad.receipt_ctrl_num = @tmp_ctrl_num )   
  
  
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
  
 DECLARE  
  @err                    smallint,  
  @debug                  int  
  EXEC @err = TXCalculateTax_SP  @debug, 1   
  
  
  
   
  INSERT INTO #tmpinptax( timestamp,  
   documenttype,  
   trx_ctrl_num,  
   trx_type,  
   sequence_id,   
   tax_type_code,  
   amt_taxable,  
   amt_gross,   
   amt_tax,   
   amt_final_tax )   
   SELECT NULL ,   
   'MATCHRECEIPT',  
    @tmp_ctrl_num ,    
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
 WHERE tc.control_number = @tmp_ctrl_num   
 GROUP BY ttr.seq_id, tt.tax_type  
  
  
  
 if (exists(select 1 from #TXTaxLineDetOutput where control_number = @tmp_ctrl_num))  
 begin  
   INSERT #tmpinptaxdtl ( trx_ctrl_num,   
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
    SELECT @tmp_ctrl_num ,  
     ti.reference_number,  
     @trx_type,    
     ti.t_index,  
     ti.reference_number,  
     tt.tax_type,  
     ti.taxable,  
     ti.taxable + ti.nonTaxable,  
     ti.amtTax ,  
     ti.amtTax ,  
     tt.recoverable_flag,  
     ' '  
   from #TXTaxLineDetOutput ti  
   join #TXtaxcode tc on tc.control_number = ti.control_number   
     join #TXtaxtyperec ttr on ttr.tc_row =tc.row_id  
     join #TXtaxtype tt on tt.ttr_row = ttr.row_id   
     where tc.control_number = @tmp_ctrl_num  
 end  
 else  
 begin  
   INSERT #tmpinptaxdtl ( trx_ctrl_num,   
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
    SELECT @tmp_ctrl_num ,  
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
  
   
 select TOP 1 @tmp_ctrl_num = tmp_ctrl_num, @organization_id = organization_id from #APReceipts_tmp  
 where tmp_ctrl_num > @tmp_ctrl_num  
 order by tmp_ctrl_num  
 if @@rowcount <= 0  
  SET @tmp_ctrl_num = NULL  
  
END   
  
UPDATE  dtl  
SET dtl.account_code = cdt.account_code  
FROM #tmpinptaxdtl dtl   
 JOIN epinvdtl cdt (nolock) ON ( cdt.receipt_ctrl_num = dtl.trx_ctrl_num  
  AND cdt.sequence_id  = dtl.detail_sequence_id )  
/**/                                                
GO
GRANT EXECUTE ON  [dbo].[apaccrualsAPReceiptstax_sp] TO [public]
GO
