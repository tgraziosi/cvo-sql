SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_VendorLoad] (@debug_level smallint = 0)          
AS          
          
DECLARE @hDoc INT,          
  @result INT,          
  @err_section CHAR(30)          
          
SET @err_section = ''          
          
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/ap_ins_vendor.sp' + ', line ' + STR( 124, 5 ) + ' -- ENTRY: '          
          
create table #ewerror        
(module_id int, err_code int, info2 int, trx_ctrl_num varchar(50))        
    
delete from ztemp_vendor where row_action=0        
        
--CREATE TABLE ZTEMP_vendor (          
-- row_action       SMALLINT NULL,          
-- vendor_code                VARCHAR (12) NULL,          
-- vendor_name                VARCHAR (40) NULL,          
-- vendor_short_name          VARCHAR (10) NULL,          
-- addr1                      VARCHAR (40) NULL,          
-- addr2                      VARCHAR (40) NULL,          
-- addr3                      VARCHAR (40) NULL,          
-- addr4                      VARCHAR (40) NULL,          
-- addr5                      VARCHAR (40) NULL,          
-- addr6                      VARCHAR (40) NULL,          
-- addr_sort1                 VARCHAR (40) NULL,          
-- addr_sort2                 VARCHAR (40) NULL,          
-- addr_sort3                 VARCHAR (40) NULL,          
-- status_type                SMALLINT NULL,          
-- attention_name             VARCHAR (40) NULL,          
-- attention_phone            VARCHAR (30) NULL,          
-- contact_name               VARCHAR (40) NULL,          
-- contact_phone              VARCHAR (30) NULL,          
-- tlx_twx                    VARCHAR (30) NULL,          
-- phone_1                    VARCHAR (30) NULL,          
-- phone_2                    VARCHAR (30) NULL,          
-- pay_to_code                VARCHAR (8) NULL,          
-- tax_code                   VARCHAR (8) NULL,          
-- terms_code                 VARCHAR (8) NULL,          
-- fob_code                   VARCHAR (8) NULL,          
-- posting_code               VARCHAR (8) NULL,          
-- location_code              VARCHAR (10) NULL,          
-- orig_zone_code             VARCHAR (8) NULL,          
-- customer_code              VARCHAR (8) NULL,          
-- affiliated_vend_code       VARCHAR (12) NULL,          
-- alt_vendor_code            VARCHAR (12) NULL,          
-- comment_code               VARCHAR (8) NULL,          
-- vend_class_code            VARCHAR (8) NULL,          
-- branch_code                VARCHAR (8) NULL,          
-- pay_to_hist_flag           SMALLINT NULL,          
-- item_hist_flag             SMALLINT NULL,          
-- credit_limit_flag          SMALLINT NULL,          
-- credit_limit               FLOAT NULL,          
-- aging_limit_flag           SMALLINT NULL,          
-- aging_limit                SMALLINT NULL,          
-- restock_chg_flag           SMALLINT NULL,          
-- restock_chg                FLOAT NULL,          
-- prc_flag                   SMALLINT NULL,          
-- vend_acct                  VARCHAR (20) NULL,          
-- tax_id_num                 VARCHAR (20) NULL,          
-- flag_1099                  SMALLINT NULL,          
-- exp_acct_code              VARCHAR (32) NULL,          
-- amt_max_check              FLOAT NULL,          
-- lead_time                  SMALLINT NULL,          
-- one_check_flag             SMALLINT NULL,          
-- dup_voucher_flag           SMALLINT NULL,          
-- dup_amt_flag               SMALLINT NULL,          
-- code_1099                  VARCHAR (8) NULL,          
-- user_trx_type_code         VARCHAR (8) NULL,          
-- payment_code               VARCHAR (8) NULL,          
-- address_type               SMALLINT NULL,          
-- limit_by_home              SMALLINT NULL,          
-- rate_type_home             VARCHAR (8) NULL,          
-- rate_type_oper             VARCHAR (8) NULL,          
-- nat_cur_code               VARCHAR (8) NULL,          
-- one_cur_vendor             SMALLINT NULL,          
-- cash_acct_code             VARCHAR (32) NULL,          
-- city                       VARCHAR (40) NULL,          
-- state    VARCHAR (40) NULL,          
-- postal_code                VARCHAR (15) NULL,          
-- country                    VARCHAR (40) NULL,          
-- freight_code               VARCHAR (10) NULL,          
-- note               VARCHAR (255) NULL,          
-- url                        VARCHAR (255) NULL,          
-- country_code               VARCHAR (3) NULL,          
-- ftp                        VARCHAR (255) NULL,          
-- attention_email            VARCHAR (255) NULL,          
-- contact_email              VARCHAR (255) NULL,          
-- etransmit_ind              INT NULL,          
-- po_item_flag               INT NULL,          
-- vo_hold_flag               INT NULL,          
-- buying_cycle               INT NULL,          
-- proc_vend_flag             INT NULL)          
--          
--CREATE TABLE ZTEMP_eft_apmsvend (          
-- row_action       SMALLINT NULL,          
-- vendor_code                VARCHAR (12) NULL,          
-- pay_to_code                VARCHAR (8) NULL,          
-- bank_name                  VARCHAR (40) NULL,          
-- addr1_bnk                  VARCHAR (40) NULL,          
-- addr2_bnk                  VARCHAR (40) NULL,          
-- addr3_bnk                  VARCHAR (40) NULL,          
-- addr4_bnk                  VARCHAR (40) NULL,          
-- addr5_bnk                  VARCHAR (40) NULL,          
-- addr6_bnk                  VARCHAR (40) NULL,          
-- bank_account_num           VARCHAR (20) NULL,          
-- aba_number                 VARCHAR (16) NULL,          
-- account_type               SMALLINT NULL)          
--          
--CREATE TABLE ZTEMP_vendor_val (          
-- row_action       SMALLINT NULL,          
-- vendor_code                VARCHAR (12) NULL,          
-- vendor_name                VARCHAR (40) NULL,          
-- addr1                      VARCHAR (40) NULL,          
-- status_type                SMALLINT NULL,          
-- pay_to_code                VARCHAR (8) NULL,          
-- tax_code                   VARCHAR (8) NULL,          
-- terms_code                 VARCHAR (8) NULL,          
-- fob_code                   VARCHAR (8) NULL,          
-- posting_code               VARCHAR (8) NULL,          
-- orig_zone_code             VARCHAR (8) NULL,          
-- customer_code              VARCHAR (8) NULL,          
-- alt_vendor_code            VARCHAR (12) NULL,          
-- comment_code               VARCHAR (8) NULL,          
-- vend_class_code            VARCHAR (8) NULL,          
-- branch_code                VARCHAR (8) NULL,          
-- credit_limit_flag          SMALLINT NULL,          
-- credit_limit               FLOAT NULL,          
-- aging_limit_flag           SMALLINT NULL,          
-- aging_limit                SMALLINT NULL,          
-- restock_chg_flag           SMALLINT NULL,          
-- restock_chg                FLOAT NULL,          
-- exp_acct_code              VARCHAR (32) NULL,          
-- code_1099                  VARCHAR (8) NULL,          
-- user_trx_type_code         VARCHAR (8) NULL,          
-- payment_code               VARCHAR (8) NULL,          
-- rate_type_home             VARCHAR (8) NULL,          
-- rate_type_oper             VARCHAR (8) NULL,          
-- nat_cur_code               VARCHAR (8) NULL,          
-- cash_acct_code             VARCHAR (32) NULL,          
-- freight_code               VARCHAR (10) NULL,          
-- country_code               VARCHAR (3) NULL,          
-- proc_vend_flag             INT NULL,          
-- limit_by_home              SMALLINT NULL,          
-- flag_1099                  SMALLINT NULL,          
-- one_cur_vendor             SMALLINT NULL,          
-- one_check_flag             SMALLINT NULL,          
-- prc_flag                   SMALLINT NULL,          
-- attention_phone            VARCHAR (30) NULL,          
-- contact_phone              VARCHAR (30) NULL,          -- phone_1                    VARCHAR (30) NULL,          
-- phone_2                    VARCHAR (30) NULL)          
--          
          
TRUNCATE TABLE #ewerror          
          
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/ap_ins_vendor.sp' + ', line ' + STR( 124, 5 ) + ' -- Fill temp tables: '          
          
--          
--EXEC @result = sp_xml_preparedocument @hDoc OUTPUT, @InputXml          
          
--          
--INSERT INTO ZTEMP_vendor          
--SELECT           
-- 1,          
-- vendor_code,          
-- vendor_name,          
-- vendor_short_name,          
-- addr1,          
-- addr2,          
-- addr3,          
-- addr4,          
-- addr5,          
-- addr6,         
-- addr_sort1,          
-- addr_sort2,          
-- addr_sort3,          
-- status_type,          
-- attention_name,          
-- attention_phone,          
-- contact_name,          
-- contact_phone,          
-- tlx_twx,          
-- phone_1,          
-- phone_2,          
-- pay_to_code,          
-- tax_code,          
-- terms_code,          
-- fob_code,          
-- posting_code,          
-- location_code,          
-- orig_zone_code,          
-- customer_code,          
-- affiliated_vend_code,          
-- alt_vendor_code,          
-- comment_code,          
-- vend_class_code,          
-- branch_code,          
-- pay_to_hist_flag,          
-- item_hist_flag,          
-- credit_limit_flag,          
-- credit_limit,          
-- aging_limit_flag,          
-- aging_limit,          
-- restock_chg_flag,          
-- restock_chg,          
-- prc_flag,          
-- vend_acct,          
-- tax_id_num,          
-- flag_1099,          
-- exp_acct_code,          
-- amt_max_check,          
-- lead_time,          
-- one_check_flag,          
-- dup_voucher_flag,          
-- dup_amt_flag,          
-- code_1099,          
-- user_trx_type_code,          
-- payment_code,          
-- address_type,          
-- limit_by_home,          
-- rate_type_home,          
-- rate_type_oper,          
-- nat_cur_code,          
-- one_cur_vendor,          
-- cash_acct_code,          
-- city,          
-- state,          
-- postal_code,          
-- country,          
-- freight_code,          
-- note,          
-- url,          
-- country_code,          
-- ftp,          
-- attention_email,          
-- contact_email,          
-- etransmit_ind,          
-- po_item_flag,          
-- vo_hold_flag,          
-- buying_cycle,          
-- proc_vend_flag          
--FROM OPENXML (@hDoc,'/BackOfficeAP.CreateVendorDoc/Vendors',2)          
--WITH #TEMP_vendor          
--          
--SET @result = @@error          
--IF @result <> 0           
--BEGIN           
-- INSERT #ewerror (module_id, err_code, info2, trx_ctrl_num) VALUES (4000, 37247, @err_section + '', '')          
--           
-- RETURN @result          
--END           
--          
--INSERT INTO #TEMP_eft_apmsvend          
--SELECT           
-- 1,          
-- vendor_code,          
-- ISNULL(pay_to_code,''),          
-- bank_name,          
-- addr1_bnk,          
-- addr2_bnk,          
-- addr3_bnk,          
-- addr4_bnk,           
-- addr5_bnk,          
-- addr6_bnk,          
-- bank_account_num,          
-- aba_number,          
-- account_type          
--FROM OPENXML (@hDoc,'/BackOfficeAP.CreateVendorDoc/Vendors',2)          
--WITH #TEMP_eft_apmsvend          
--WHERE NOT bank_name IS NULL          
--          
--          
--SET @result = @@error          
--IF @result <> 0           
--BEGIN           
-- INSERT #ewerror (module_id, err_code, info2, trx_ctrl_num) VALUES (4000, 37248, @err_section + '', '')          
--           
-- RETURN @result          
--END           
--          
--          
--EXEC @result = sp_xml_removedocument @hDoc          
--          
--          
--          
--INSERT INTO #TEMP_vendor_val          
--SELECT  row_action,          
--  vendor_code,          
--  vendor_name,          
--  addr1,          
--  status_type,          
--  pay_to_code,          
--  tax_code,          
--  terms_code,          
--  fob_code,          
--  posting_code,          
--  orig_zone_code,          
--  customer_code,          
--  alt_vendor_code,          
--  comment_code,          
--  vend_class_code,          
--  branch_code,          
--  credit_limit_flag,          
--  credit_limit,          
--  aging_limit_flag,          
--  aging_limit,          
--  restock_chg_flag,          
--  restock_chg,          
--  exp_acct_code,          
--  code_1099,          
--  user_trx_type_code,          
--  payment_code,          
--  rate_type_home,          
--  rate_type_oper,          
--  nat_cur_code,          
--  cash_acct_code,          
--  freight_code,          
--  country_code,          
--  proc_vend_flag,          
--  limit_by_home,          
--  flag_1099,          
--  one_cur_vendor,          
--  one_check_flag,          
--  prc_flag,          
--  attention_phone,          
--  contact_phone,          
--  phone_1,          
--  phone_2          
--FROM #TEMP_vendor          
--          
--SET @result = @@error          
--IF @result <> 0           
--BEGIN           
-- INSERT #ewerror (module_id, err_code, info2, trx_ctrl_num) VALUES (4000, 37249, @err_section + '', '')          
--           
-- RETURN @result          
--END           
--          
          
          
EXEC CVO_ValidateVendors 0          
          
          
          
          
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/ap_ins_vendor.sp' + ', line ' + STR( 124, 5 ) + ' -- Insert information: '          
          
BEGIN TRANSACTION INSERT_VENDORS          
          
INSERT apvend ( vendor_code,      vendor_name,        vendor_short_name,          
    addr1,        addr2,          addr3,          
    addr4,        addr5,          addr6,          
    addr_sort1,       addr_sort2,         addr_sort3,          
    status_type,      attention_name,        attention_phone,          
    contact_name,      contact_phone,        tlx_twx,          
    phone_1,       phone_2,         pay_to_code,          
    tax_code,       terms_code,         fob_code,          
    posting_code,      location_code,        orig_zone_code,          
    customer_code,      affiliated_vend_code,      alt_vendor_code,          
    comment_code,      vend_class_code,       branch_code,          
    pay_to_hist_flag,     item_hist_flag,        credit_limit_flag,          
    credit_limit,      aging_limit_flag,       aging_limit,          
    restock_chg_flag,     restock_chg,        prc_flag,          
    vend_acct,       tax_id_num,         flag_1099,          
    exp_acct_code,      amt_max_check,        lead_time,          
    one_check_flag,      dup_voucher_flag,       dup_amt_flag,          
    code_1099,       user_trx_type_code,       payment_code,          
    address_type,      limit_by_home,        rate_type_home,          
    rate_type_oper,      nat_cur_code,        one_cur_vendor,          
    cash_acct_code,      city,          state,          
    postal_code,      country,         freight_code,          
    note,        url,          country_code,          
    ftp,        attention_email,       contact_email,          
    etransmit_ind,      po_item_flag,        vo_hold_flag,          
    buying_cycle,      proc_vend_flag,extended_name,check_extendedname_flag)           
SELECT   TEMP.vendor_code,      TEMP.vendor_name,        CASE WHEN TEMP.vendor_short_name IS NULL THEN SUBSTRING(TEMP.vendor_name,1,10) ELSE SUBSTRING(TEMP.vendor_short_name,1,10) END,          
    ISNULL(TEMP.addr1,''),     ISNULL(TEMP.addr2,''),       ISNULL(TEMP.addr3,''),          
    ISNULL(TEMP.addr4,''),     ISNULL(TEMP.addr5,''),       ISNULL(TEMP.addr6,''),          
    ISNULL(TEMP.addr_sort1,''),    ISNULL(TEMP.addr_sort2,''),      ISNULL(TEMP.addr_sort3,''),          
    TEMP.status_type,      ISNULL(TEMP.attention_name,''),     ISNULL(TEMP.attention_phone,''),          
    ISNULL(TEMP.contact_name,''),   ISNULL(TEMP.contact_phone,''),     ISNULL(TEMP.tlx_twx,''),          
    ISNULL(TEMP.phone_1,''),    ISNULL(TEMP.phone_2,''),      '',--TEMP.pay_to_code,          
    TEMP.tax_code,       TEMP.terms_code,        ISNULL(TEMP.fob_code,''),          
    TEMP.posting_code,      ISNULL(TEMP.location_code,''),     ISNULL(TEMP.orig_zone_code,''),          
    TEMP.customer_code,      TEMP.affiliated_vend_code,      TEMP.alt_vendor_code,          
    TEMP.comment_code,      TEMP.vend_class_code,       TEMP.branch_code,          
    TEMP.pay_to_hist_flag,     TEMP.item_hist_flag,       TEMP.credit_limit_flag,          
    TEMP.credit_limit,      TEMP.aging_limit_flag,       TEMP.aging_limit,          
    TEMP.restock_chg_flag,     TEMP.restock_chg,        TEMP.prc_flag,          
    TEMP.vend_acct,       TEMP.tax_id_num,        TEMP.flag_1099,          
    TEMP.exp_acct_code,      TEMP.amt_max_check, TEMP.lead_time,          
    TEMP.one_check_flag,     TEMP.dup_voucher_flag,       TEMP.dup_amt_flag,          
    TEMP.code_1099,       TEMP.user_trx_type_code,      TEMP.payment_code,          
    ISNULL(TEMP.address_type,((0))),  TEMP.limit_by_home,        TEMP.rate_type_home,          
    TEMP.rate_type_oper,     TEMP.nat_cur_code,        TEMP.one_cur_vendor,          
    TEMP.cash_acct_code,     ISNULL(TEMP.city,''),       ISNULL(TEMP.state,''),          
    --ISNULL(TEMP.postal_code,''),   ISNULL(TEMP.country,''),      ISNULL(TEMP.freight_code,''),          
ISNULL(TEMP.postal_code,''),   '',      ISNULL(TEMP.freight_code,''),          
    ISNULL(TEMP.note,''),     ISNULL(TEMP.url,''),       TEMP.country_code,          
    TEMP.ftp,        TEMP.attention_email,       TEMP.contact_email,          
    TEMP.etransmit_ind,      TEMP.po_item_flag,        TEMP.vo_hold_flag,          
    TEMP.buying_cycle,      TEMP.proc_vend_flag,TEMP.vendor_name, 0          
FROM ZTEMP_vendor TEMP          
WHERE NOT EXISTS (SELECT 1 FROM #ewerror WHERE trx_ctrl_num = TEMP.vendor_code)          
          
SET @result = @@error          
IF @result <> 0           
BEGIN           
 ROLLBACK TRANSACTION INSERT_VENDORS          
          
 INSERT #ewerror (module_id, err_code, info2, trx_ctrl_num) VALUES (4000, 37258, @err_section + '', '')          
          
 RETURN @result          
END           
          
IF EXISTS (SELECT 1 FROM ZTEMP_eft_apmsvend)          
BEGIN          
           
          
 UPDATE BNK          
  SET BNK.pay_to_code             = ISNULL(TEMP.pay_to_code,            BNK.pay_to_code),          
   BNK.bank_name               = ISNULL(TEMP.bank_name,              BNK.bank_name),          
   BNK.addr1                   = ISNULL(TEMP.addr1_bnk,              BNK.addr1),          
   BNK.addr2                   = ISNULL(TEMP.addr2_bnk,              BNK.addr2),          
   BNK.addr3                   = ISNULL(TEMP.addr3_bnk,              BNK.addr3),          
   BNK.addr4                   = ISNULL(TEMP.addr4_bnk,              BNK.addr4),          
   BNK.addr5                   = ISNULL(TEMP.addr5_bnk,              BNK.addr5),          
   BNK.addr6                   = ISNULL(TEMP.addr6_bnk,              BNK.addr6),          
   BNK.bank_account_num        = ISNULL(TEMP.bank_account_num,       BNK.bank_account_num),          
   BNK.aba_number              = ISNULL(TEMP.aba_number,             BNK.aba_number),          
   BNK.account_type            = ISNULL(TEMP.account_type,           BNK.account_type)          
 FROM eft_apmsvend_vw BNK          
  INNER JOIN ZTEMP_eft_apmsvend TEMP ON BNK.vendor_code = TEMP.vendor_code          
 WHERE NOT EXISTS (SELECT 1 FROM #ewerror WHERE trx_ctrl_num = TEMP.vendor_code)          
          
 SET @result = @@error          
 IF @result <> 0           
 BEGIN           
  ROLLBACK TRANSACTION INSERT_VENDORS          
          
  INSERT #ewerror (module_id, err_code, info2, trx_ctrl_num) VALUES (4000, 37261, @err_section + '', '')          
          
  RETURN @result          
 END           
          
 INSERT eft_apmsvend_vw (vendor_code,     pay_to_code,         bank_name,          
       addr1,       addr2,           addr3,          
       addr4,       addr5,           addr6,          
       bank_account_num,    aba_number,          account_type)          
 SELECT   TEMP.vendor_code,     TEMP.pay_to_code,       TEMP.bank_name,          
       TEMP.addr1_bnk,      TEMP.addr2_bnk,        TEMP.addr3_bnk,          
       TEMP.addr4_bnk,      TEMP.addr5_bnk,        TEMP.addr6_bnk,          
       TEMP.bank_account_num,    TEMP.aba_number,       TEMP.account_type          
 FROM ZTEMP_eft_apmsvend TEMP          
  LEFT JOIN eft_apmsvend_vw BNK ON TEMP.vendor_code = BNK.vendor_code          
 WHERE NOT EXISTS (SELECT 1 FROM #ewerror WHERE trx_ctrl_num = TEMP.vendor_code)          
  AND BNK.vendor_code IS NULL          
          
 SET @result = @@error          
 IF @result <> 0           
 BEGIN           
  ROLLBACK TRANSACTION INSERT_VENDORS          
          
  INSERT #ewerror (module_id, err_code, info2, trx_ctrl_num) VALUES (4000, 37259, @err_section + '', '')          
          
  RETURN @result          
 END           
END          
          
COMMIT TRANSACTION INSERT_VENDORS          
          
--DROP TABLE #TEMP_vendor          
          
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/ap_ins_vendor.sp' + ', line ' + STR( 124, 5 ) + ' -- EXIT: '          
          
RETURN @result          
/**/   
  
GO
GRANT EXECUTE ON  [dbo].[CVO_VendorLoad] TO [public]
GO
