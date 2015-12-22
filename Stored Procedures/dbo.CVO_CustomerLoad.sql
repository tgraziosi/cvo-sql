SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_CustomerLoad] (@debug_level smallint = 0)                
AS                
                
DECLARE @hDoc INT,                
  @result INT,                
  @err_section CHAR(30)                
              
CREATE TABLE #ewerror (                
    module_id     smallint,                
 err_code     int,                
 info2      char(1000),                
 trx_ctrl_num    char(30))                
                
              
              
SET @err_section = ''                
                
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/ar_ins_customer.sp' + ', line ' + STR( 124, 5 ) + ' -- ENTRY: '                
                
                
TRUNCATE TABLE #ewerror                
                
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/ar_ins_customer.sp' + ', line ' + STR( 124, 5 ) + ' -- Fill temp tables: '                
                
                
                
--INSERT INTO ZTEMP_customer                
--SELECT                 
-- 1,                
-- customer_code,                
-- customer_name,                
-- customer_short_name,                
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
-- ship_to_code,                
-- tax_code,                
-- terms_code,                
-- fob_code,                
-- freight_code,                
-- posting_code,                
-- location_code,                
-- alt_location_code,                
-- dest_zone_code,                
-- territory_code,                
-- salesperson_code,                
-- fin_chg_code,                
-- price_code,                
-- payment_code,                
-- vendor_code,                
-- affiliated_cust_code,                
-- print_stmt_flag,                
-- stmt_cycle_code,                
-- inv_comment_code,                
-- stmt_comment_code,                
-- dunn_message_code,                
-- note,                
-- trade_disc_percent,                
-- invoice_copies,                
-- iv_substitution,                
-- ship_to_history,                
-- check_credit_limit,                
-- credit_limit,                
-- check_aging_limit,                
-- aging_limit_bracket,                
-- bal_fwd_flag,                
-- ship_complete_flag,                
-- resale_num,                
-- db_num,                
-- db_date,                
-- db_credit_rating,                
-- ISNULL(address_type,((0))),                
-- late_chg_type,                
-- valid_payer_flag,                
-- valid_soldto_flag,                
-- valid_shipto_flag,                
-- payer_soldto_rel_code,                
-- across_na_flag,                
-- date_opened,                
-- rate_type_home,                
-- rate_type_oper,                
-- limit_by_home,                
-- nat_cur_code,                
-- one_cur_cust,                
-- added_by_user_name,                
-- added_by_date,                
-- modified_by_user_name,                
-- modified_by_date,                
-- city,                
-- state,                
-- postal_code,                
-- country,                
-- remit_code,                
-- forwarder_code,                
-- freight_to_code,                
-- route_code,                
-- route_no,                
-- url,                
-- special_instr,                
-- guid,                
-- price_level,                
-- ship_via_code,                
-- so_priority_code,                
-- country_code,                
-- tax_id_num,                
-- ftp,                
-- attention_email,                
-- contact_email,                
-- dunning_group_id,                
-- ISNULL(consolidated_invoices,((0))),                
-- writeoff_code,                
-- delivery_days                
--FROM OPENXML (@hDoc,'/BackOfficeAR.CreateCustomerDoc/Customers',2)                
--WITH ZTEMP_customer                
                
SET @result = @@error                
IF @result <> 0                 
BEGIN                 
 INSERT #ewerror (module_id, err_code, info2, trx_ctrl_num) VALUES (2000, 35055, @err_section + '', '')                
                 
 RETURN @result                
END                 
                
truncate table ztemp_customer_val                
                
                
INSERT INTO ZTEMP_customer_val                
SELECT  row_action,                
  customer_code,                
  status_type,              
  ship_to_code,                
  tax_code,                
  terms_code,                
  fob_code,                
  freight_code,                
  posting_code,                
  location_code,                
  alt_location_code,                
  dest_zone_code,                
  territory_code,                
  salesperson_code,                
  fin_chg_code,               
price_code,                
  payment_code,                
  vendor_code,                
  affiliated_cust_code,                
  print_stmt_flag,                
  --stmt_cycle_code,        
       'STMT25', --fzambada           
  inv_comment_code,                
  stmt_comment_code,                
  dunn_message_code,                
  check_aging_limit,                
  aging_limit_bracket,                
  payer_soldto_rel_code,                
  rate_type_home,                
  rate_type_oper,                
  nat_cur_code,                
  --country_code,                
 'US',      
  remit_code,                
  forwarder_code,                
  freight_to_code,                
  ship_via_code,                
  so_priority_code,                
  dunning_group_id,                
  writeoff_code,                
  check_credit_limit,                
  bal_fwd_flag,                
  ship_complete_flag,                
  late_chg_type,                
  valid_payer_flag,                
  valid_soldto_flag,                 
  valid_shipto_flag,                
  across_na_flag,                
  limit_by_home,                
  one_cur_cust,                
  price_level,                
  consolidated_invoices,                
  contact_phone,                
  attention_phone,                
  phone_1,                
  phone_2                
FROM ZTEMP_customer                
                
SET @result = @@error                
IF @result <> 0                 
BEGIN                 
 INSERT #ewerror (module_id, err_code, info2, trx_ctrl_num) VALUES (2000, 35056, @err_section + '', '')                
 RETURN @result                
END                 
                
                
                
EXEC CVO_ValidateCustomers 0                
                
                
                
                
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/ar_ins_customer.sp' + ', line ' + STR( 124, 5 ) + ' -- Insert information: '                
                
BEGIN TRANSACTION INSERT_CUSTOMERS                
                
INSERT arcust ( customer_code        ,customer_name                      ,customer_short_name                ,                
    addr1                              ,addr2                              ,addr3                              ,                
    addr4                              ,addr5                              ,addr6                              ,                
    addr_sort1                         ,addr_sort2                         ,addr_sort3                         ,                
    status_type                        ,attention_name                     ,attention_phone                    ,                
    contact_name                       ,contact_phone                     ,tlx_twx                            ,                
    phone_1                            ,phone_2                            ,ship_to_code                       ,                
    tax_code                           ,terms_code                         ,fob_code                           ,                
    freight_code                       ,posting_code                       ,location_code                      ,        
    alt_location_code                  ,dest_zone_code                     ,territory_code                     ,                
    salesperson_code                   ,fin_chg_code                       ,price_code                         ,                
    payment_code                       ,vendor_code                        ,affiliated_cust_code               ,                
    print_stmt_flag                    ,stmt_cycle_code ,inv_comment_code                   ,                
    stmt_comment_code                  ,dunn_message_code                  ,note                               ,                
    trade_disc_percent                 ,invoice_copies                     ,iv_substitution                    ,                
    ship_to_history                    ,check_credit_limit                 ,credit_limit                       ,                
    check_aging_limit                  ,aging_limit_bracket                ,bal_fwd_flag                       ,                
    ship_complete_flag                 ,resale_num                         ,db_num                             ,                
    db_date                            ,db_credit_rating                   ,address_type                       ,                
    late_chg_type                      ,valid_payer_flag                   ,valid_soldto_flag                  ,                
    valid_shipto_flag                  ,payer_soldto_rel_code              ,across_na_flag                     ,                
    date_opened                        ,rate_type_home                     ,rate_type_oper                     ,                
    limit_by_home                      ,nat_cur_code                       ,one_cur_cust                       ,                
    added_by_user_name                 ,added_by_date                      ,modified_by_user_name              ,                
    modified_by_date                   ,city                           ,state                              ,                
    postal_code                        ,country                            ,remit_code                         ,                
    forwarder_code                     ,freight_to_code                    ,route_code                         ,                
    route_no                           ,url                                ,special_instr                      ,                
    guid                               ,price_level           ,ship_via_code                      ,                
    so_priority_code                   ,country_code                       ,tax_id_num                         ,                
    ftp                                ,attention_email                    ,contact_email                      ,                
    dunning_group_id                   ,consolidated_invoices              ,writeoff_code,      
 extended_name,check_extendedname_flag                      )                 
SELECT   TEMP.customer_code      ,TEMP.customer_name         ,SUBSTRING(TEMP.customer_name,1,10)  ,                
    ISNULL(TEMP.addr1,'')        ,ISNULL(TEMP.addr2,'')           ,ISNULL(TEMP.addr3,'')        ,                
    ISNULL(TEMP.addr4,'')        ,ISNULL(TEMP.addr5,'')        ,ISNULL(TEMP.addr6,'')        ,                
    TEMP.addr_sort1       ,TEMP.addr_sort2      ,TEMP.addr_sort3      ,                
    TEMP.status_type      ,TEMP.attention_name     ,TEMP.attention_phone     ,                
    TEMP.contact_name      ,TEMP.contact_phone      ,TEMP.tlx_twx       ,            
    TEMP.phone_1       ,TEMP.phone_2       ,ISNULL(TEMP.ship_to_code,'')      ,                
    TEMP.tax_code       ,TEMP.terms_code      ,TEMP.fob_code       ,                
    TEMP.freight_code      ,TEMP.posting_code      ,TEMP.location_code      ,                
    TEMP.alt_location_code     ,TEMP.dest_zone_code     ,ISNULL(TEMP.territory_code,'')     ,                
    ISNULL(TEMP.salesperson_code,'')     ,ISNULL(TEMP.fin_chg_code,'')      ,TEMP.price_code      ,                
    TEMP.payment_code      ,TEMP.vendor_code      ,TEMP.affiliated_cust_code    ,                
    --TEMP.print_stmt_flag     ,TEMP.stmt_cycle_code     ,TEMP.inv_comment_code     ,                
 1,'STMT25',TEMP.inv_comment_code     ,                
    TEMP.stmt_comment_code     ,TEMP.dunn_message_code     ,TEMP.note        ,                
    --TEMP.trade_disc_percent     ,TEMP.invoice_copies     ,TEMP.iv_substitution     ,                
0     ,TEMP.invoice_copies     ,0,--TEMP.iv_substitution     ,                   
 TEMP.ship_to_history     ,TEMP.check_credit_limit    ,TEMP.credit_limit      ,                
    TEMP.check_aging_limit     ,TEMP.aging_limit_bracket    ,TEMP.bal_fwd_flag      ,                
    TEMP.ship_complete_flag     ,TEMP.resale_num      ,TEMP.db_num       ,                
    TEMP.db_date       ,TEMP.db_credit_rating     ,ISNULL(TEMP.address_type,0)      ,                
    TEMP.late_chg_type      ,TEMP.valid_payer_flag     ,TEMP.valid_soldto_flag     ,                
    TEMP.valid_shipto_flag     ,TEMP.payer_soldto_rel_code    ,0,--TEMP.across_na_flag     ,                
    TEMP.date_opened      ,TEMP.rate_type_home     ,TEMP.rate_type_oper     ,                
    TEMP.limit_by_home      ,TEMP.nat_cur_code      ,TEMP.one_cur_cust      ,                
    TEMP.added_by_user_name     ,TEMP.added_by_date      ,TEMP.modified_by_user_name    ,                
    TEMP.modified_by_date     ,TEMP.city        ,TEMP.state        ,                
    TEMP.postal_code      ,TEMP.country       ,TEMP.remit_code      ,                
    TEMP.forwarder_code      ,TEMP.freight_to_code     ,TEMP.route_code      ,                
    TEMP.route_no       ,TEMP.url        ,TEMP.special_instr      ,                
    TEMP.guid        ,TEMP.price_level      ,TEMP.ship_via_code      ,                
    TEMP.so_priority_code     ,TEMP.country_code      ,TEMP.tax_id_num      ,                
--TEMP.so_priority_code     ,'US'      ,TEMP.tax_id_num      ,                
    TEMP.ftp        ,TEMP.attention_email     ,TEMP.contact_email      ,                
    TEMP.dunning_group_id     ,TEMP.consolidated_invoices    ,TEMP.writeoff_code                ,      
 ISNULL(TEMP.addr1,'')        ,0      
FROM ZTEMP_customer TEMP                
WHERE NOT EXISTS (SELECT 1 FROM #ewerror WHERE trx_ctrl_num = TEMP.customer_code)                
                
SET @result = @@error                
IF @result <> 0                 
BEGIN                 
 ROLLBACK TRANSACTION INSERT_CUSTOMERS                
                
 INSERT #ewerror (module_id, err_code, info2, trx_ctrl_num) VALUES (2000, 35058, @err_section + '', '')                
                
 RETURN @result                
END                 
                
COMMIT TRANSACTION INSERT_CUSTOMERS                
                
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/ar_ins_customer.sp' + ', line ' + STR( 124, 5 ) + ' -- EXIT: '                
            
IF EXISTS (SELECT 1 FROM #ewerror, ZTEMP_customer TEMP WHERE trx_ctrl_num = TEMP.customer_code)            
BEGIN            
Select 'The process completed with errors'            
select * from #ewerror            
END            
                
RETURN @result                
/**/ 
GO
GRANT EXECUTE ON  [dbo].[CVO_CustomerLoad] TO [public]
GO
