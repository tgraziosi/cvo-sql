SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
 
CREATE PROCEDURE [dbo].[bows_APImportVouchTax_SP]  
   @debug_level smallint = 0   
AS  
  
DECLARE @err   int,  
 @err_proc  varchar(32),  
 @result  int  
  
SELECT @err = 0, @result = 0, @err_proc=''  
  
/* Begin Rev 1  
 CREATE TABLE #txdetail  
 (  
  control_number varchar(16),  
  reference_number int,  
  tax_type_code  varchar(8),  
  amt_taxable  float  
 )  
  
 CREATE TABLE #txinfo_id  
 (  
  id_col   numeric identity,  
  control_number varchar(16),  
  sequence_id  int,  
  tax_type_code  varchar(8),  
  currency_code  varchar(8)  
 )  
End Rev 1*/  
  
 CREATE TABLE #TXInfo_min_id (control_number varchar(16),min_id_col numeric)  
  
 CREATE TABLE #TxTLD  
 (  
  control_number varchar(16),  
  tax_type_code  varchar(8),  
  tax_code  varchar(8),  
  currency_code  varchar(8),  
  tax_included_flag smallint,  
  base_id  int,  
  amt_taxable  float,  
  amt_gross  float  
 )  
  
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
  
CREATE TABLE #TxLineTax  
(  
 control_number  varchar(16),  
 reference_number int,  
 tax_amount   float,  
 tax_included_flag smallint  
)  
  
 INSERT  #ewerror  
 SELECT  4000,  
   10920,  
   w.tax_code,  
  '',  
  0,  
  0.0,  
  1,  
  w.trx_ctrl_num,  
  0,  
  '',  
   0  
 FROM #apinpcdt w  
 WHERE w.tax_code NOT IN (SELECT tax_code FROM artax)  
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 22, @err_proc='bows_apintax_sp' GOTO lbFinal END END  
  
 INSERT INTO #TxLineInput  
 (  
  control_number,  reference_number, tax_code,  
  quantity,  extended_price,  discount_amount,  
  tax_type,  currency_code  
 )  
 SELECT hdr.trx_ctrl_num, cdt.sequence_id, cdt.tax_code,  
  cdt.qty_received, cdt.amt_extended, cdt.amt_discount,  
  0,   hdr.nat_cur_code  
 FROM #apinpcdt cdt, #apinpchg hdr  
 WHERE cdt.trx_ctrl_num = hdr.trx_ctrl_num  
 AND hdr.trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM #ewerror)  
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 10, @err_proc='bows_apintax_sp' GOTO lbFinal END END  
  
 INSERT INTO #TxLineInput  
 (  
  control_number,  reference_number, tax_code,  
  quantity,  extended_price,  discount_amount,  
  tax_type,  currency_code  
 )  
 SELECT trx_ctrl_num,  0,   tax_code,  
  1,   amt_freight,  0,  
  1,   nat_cur_code  
 FROM #apinpchg hdr  
 WHERE ((amt_freight) > (0.0) + 0.0000001)  
 AND hdr.trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM #ewerror)  
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 20, @err_proc='bows_apintax_sp' GOTO lbFinal END END  
  
/*------------------------------------*/      
  CREATE TABLE #txconnhdrinput       
 (      
  doccode varchar(16),      
  doctype smallint,      
  trx_type smallint,      
  companycode  varchar(20),      
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
      
      
 insert #txconnhdrinput      
 (doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,      
 discount, purchaseorderno, customercode, customerusagetype, detaillevel,      
 referencecode, oriaddressline1, oriaddressline2, oriaddressline3,      
 oricity, oriregion, oripostalcode, oricountry, destaddressline1,      
 destaddressline2, destaddressline3, destcity, destregion, destpostalcode,      
 destcountry)      
 SELECT DISTINCT control_number, -1, -1, '', getdate(), '','',      
 0, '', '', '', 3,      
 '', '', '', '',      
 '', '', '', '', '',      
 '', '', '', '', '',      
 ''      
 FROM #TxLineInput    
/*-------------------------------------*/     
    
    
    
    
 EXEC @result = TXCalculateTax_SP  
 IF ISNULL(@result,-1) <> 1  
 BEGIN  
  SELECT @err = 20, @err_proc='TXCalculateTax_SP'  
  GOTO lbFinal  
 END  
  
 INSERT #apinptax(  
  trx_ctrl_num,  
  trx_type,  
  sequence_id,  
  tax_type_code,  
  amt_taxable,  
  amt_gross,  
  amt_tax,  
  amt_final_tax)  
 SELECT  
  h.trx_ctrl_num,  
  h.trx_type,  
  t.sequence_id,  
  t.tax_type_code,  
  t.amt_taxable,  
  t.amt_gross,  
  t.amt_tax,  
  t.amt_final_tax  
  FROM #TxInfo t, #apinpchg h  
  WHERE  h.trx_ctrl_num = t.control_number  
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 30, @err_proc='bows_apintax_sp' GOTO lbFinal END END  
  
 UPDATE #apinpcdt  
 SET calc_tax = #TxLineTax.tax_amount  
 FROM #TxLineTax  
 WHERE #apinpcdt.trx_ctrl_num = #TxLineTax.control_number  
 AND #apinpcdt.sequence_id = #TxLineTax.reference_number  
  
 UPDATE  #bows_apinptax_link  
 SET db_action = 0  
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 50, @err_proc='bows_apintax_sp' GOTO lbFinal END END  
  
 UPDATE  w  
 SET w.db_action = 1  
 FROM #bows_apinptax_link w, #apinptax a  
 WHERE a.trx_ctrl_num = w.trx_ctrl_num  
 AND a.tax_type_code = w.tax_type_code  
 AND w.tax_calculated_mode = 1  
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 60, @err_proc='bows_apintax_sp' GOTO lbFinal END END  
  
 INSERT  #ewerror  
 SELECT  4000,  
   18000,  
   w.tax_type_code,  
  '',  
  0,  
  0.0,  
  1,  
  w.trx_ctrl_num,  
  0,  
  '',  
   0  
 FROM #bows_apinptax_link w  
 WHERE w.db_action = 0  
 AND w.tax_calculated_mode = 1  
  
 AND NOT (  ((w.amt_final_tax) <= (0.0) + 0.0000001) AND  
   EXISTS(SELECT 1 FROM aptxtype t WHERE t.tax_type_code = w.tax_type_code) )  
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 70, @err_proc='bows_apintax_sp' GOTO lbFinal END END  
  
 UPDATE  #apinptax  
 SET amt_final_tax = w.amt_final_tax 
 FROM #bows_apinptax_link w, #apinptax a  
 WHERE a.trx_ctrl_num = w.trx_ctrl_num  
 AND a.tax_type_code = w.tax_type_code  
 AND w.db_action = 1  
 AND w.tax_calculated_mode = 1  
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 80, @err_proc='bows_apintax_sp' GOTO lbFinal END END  
  
 UPDATE  #apinptax  
 SET amt_final_tax = 0  
 FROM #bows_apinptax_link w, #apinptax a  
 WHERE a.trx_ctrl_num = w.trx_ctrl_num  
 AND w.tax_calculated_mode = 1  
 AND a.tax_type_code NOT IN  
  (SELECT w.tax_type_code  
  FROM  #bows_apinptax_link w  
  WHERE a.trx_ctrl_num = w.trx_ctrl_num  
  AND a.tax_type_code = w.tax_type_code)  
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 90, @err_proc='bows_apintax_sp' GOTO lbFinal END END  
  
 UPDATE t  
 SET amt_tax  = (SIGN(t.amt_tax) * ROUND(ABS(t.amt_tax) + 0.0000001, ISNULL(g.curr_precision,2))),  
  amt_final_tax  = (SIGN(t.amt_final_tax) * ROUND(ABS(t.amt_final_tax) + 0.0000001, ISNULL(g.curr_precision,2))),  
  amt_taxable  = (SIGN(t.amt_taxable) * ROUND(ABS(t.amt_taxable) + 0.0000001, ISNULL(g.curr_precision,2)))  
 FROM #apinptax t, glcurr_vw g, #apinpchg h  
 WHERE h.nat_cur_code = g.currency_code  
 AND t.trx_ctrl_num = h.trx_ctrl_num  
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 100, @err_proc='bows_apintax_sp' GOTO lbFinal END END  
  
 SELECT @err = 0  
  
lbFinal:  
  
IF @debug_level>5 BEGIN  
 SELECT '#APINPTAX after calculating tax'  
 SELECT * FROM #apinptax  
END  
  
IF @err<>0 BEGIN  
 INSERT #ewerror( module_id, err_code,  
 info1,info2,infoint,infofloat,  
 flag1,trx_ctrl_num,sequence_id, source_ctrl_num,extra)  
 SELECT 4000, @err,  
 'PROC:' + @err_proc+ '.','',@result,0.0,  
 0, NULL ,0,'',0  
END  
  
DROP TABLE #TxLineInput  
DROP TABLE #TxInfo  
DROP TABLE #TxLineTax  
--DROP TABLE #txdetail  --Rev 1  
--DROP TABLE #txinfo_id  --Rev 1  
DROP TABLE #TXInfo_min_id  
DROP TABLE #TxTLD  
DROP TABLE #txconnhdrinput   
DROP TABLE #txconnlineinput  
  
RETURN @err  

GO
GRANT EXECUTE ON  [dbo].[bows_APImportVouchTax_SP] TO [public]
GO
