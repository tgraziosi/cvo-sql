SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
                                                 
    
CREATE PROCEDURE [dbo].[CVO_ValidateVendors] (@debug_level smallint = 0)    
AS    
    
DECLARE @err_info varchar(32),    
  @err_section CHAR(30)    
    
    
    
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/ap_vendor_validation.sp' + ', line ' + STR( 124, 5 ) + ' -- Validate information: '    
    
SET @err_info= ISNULL((SELECT e_ldesc FROM aperrdef WHERE e_code = 37250),'')    
SET @err_section = ISNULL((SELECT e_ldesc FROM aperrdef WHERE e_code = 37251),'')    
    
INSERT #ewerror     
SELECT 4000, 37274, @err_section + ISNULL(TEMP.vendor_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
GROUP BY TEMP.vendor_code    
HAVING COUNT(TEMP.vendor_code) >= 2    
    
INSERT #ewerror     
SELECT 4000, 37218, @err_section + ISNULL(TEMP.vendor_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 INNER JOIN apvend VEND ON TEMP.vendor_code = VEND.vendor_code    
WHERE TEMP.row_action = 1    
    
INSERT #ewerror     
SELECT 4000, 37222, @err_section + ISNULL(TEMP.vendor_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN apvend VEND ON TEMP.vendor_code = VEND.vendor_code    
WHERE TEMP.row_action = 2 AND VEND.vendor_code IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37219, @err_section + ISNULL(TEMP.vendor_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE TEMP.vendor_code IS NULL OR RTRIM(LTRIM(TEMP.vendor_code)) = ''    
    
INSERT #ewerror     
SELECT 4000, 37220, @err_section + ISNULL(TEMP.vendor_name,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE TEMP.row_action = 1 AND TEMP.vendor_name IS NULL OR RTRIM(LTRIM(TEMP.vendor_name)) = ''    
    
INSERT #ewerror     
SELECT 4000, 37221, @err_section + ISNULL(TEMP.addr1,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE TEMP.row_action = 1 AND TEMP.addr1 IS NULL OR RTRIM(LTRIM(TEMP.addr1)) = ''    
    
INSERT #ewerror     
SELECT 4000, 37223, @err_section + ISNULL(TEMP.pay_to_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN appayto PAY ON TEMP.pay_to_code = PAY.pay_to_code    
WHERE NOT TEMP.pay_to_code IS NULL AND RTRIM(LTRIM(TEMP.pay_to_code)) <> '' AND PAY.pay_to_code IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37224, @err_section + ISNULL(TEMP.tax_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN aptax_vw TAX ON TEMP.tax_code = TAX.tax_code    
WHERE (TEMP.row_action = 1 AND TAX.tax_code IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.tax_code IS NULL AND TAX.tax_code IS NULL)    
    
INSERT #ewerror     
SELECT 4000, 37225, @err_section + ISNULL(TEMP.terms_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN apterms TRM ON TEMP.terms_code = TRM.terms_code    
WHERE (TEMP.row_action = 1 AND TRM.terms_code IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.terms_code IS NULL AND TRM.terms_code IS NULL)    
    
INSERT #ewerror     
SELECT 4000, 37226, @err_section + ISNULL(TEMP.fob_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN apfob FOB ON TEMP.fob_code = FOB.fob_code    
WHERE NOT TEMP.fob_code IS NULL AND RTRIM(LTRIM(TEMP.fob_code)) <> '' AND FOB.fob_code IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37227, @err_section + ISNULL(TEMP.posting_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN apaccts ACCT ON TEMP.posting_code = ACCT.posting_code    
WHERE (TEMP.row_action = 1 AND ACCT.posting_code IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.posting_code IS NULL AND ACCT.posting_code IS NULL)    
    
INSERT #ewerror     
SELECT 4000, 37228, @err_section + ISNULL(TEMP.orig_zone_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN apzone ZON ON TEMP.orig_zone_code = ZON.zone_code  WHERE NOT TEMP.orig_zone_code IS NULL AND RTRIM(LTRIM(TEMP.orig_zone_code)) <> '' AND ZON.zone_code IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37229, @err_section + ISNULL(TEMP.customer_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN arcust CUST ON TEMP.customer_code = CUST.customer_code    
WHERE NOT TEMP.customer_code IS NULL AND RTRIM(LTRIM(TEMP.customer_code)) <> '' AND CUST.customer_code IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37230, @err_section + ISNULL(TEMP.alt_vendor_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN apvendok_vw VEND ON TEMP.alt_vendor_code = VEND.vendor_code    
WHERE NOT TEMP.alt_vendor_code IS NULL AND RTRIM(LTRIM(TEMP.alt_vendor_code)) <> '' AND VEND.vendor_code IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37231, @err_section + ISNULL(TEMP.comment_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN apcommnt COMM ON TEMP.comment_code = COMM.comment_code    
WHERE NOT TEMP.comment_code IS NULL AND RTRIM(LTRIM(TEMP.comment_code)) <> '' AND COMM.comment_code IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37232, @err_section + ISNULL(TEMP.vend_class_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN apclass CLSS ON TEMP.vend_class_code = CLSS.class_code    
WHERE (TEMP.row_action = 1 AND CLSS.class_code IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.vend_class_code IS NULL AND CLSS.class_code IS NULL)    
    
INSERT #ewerror     
SELECT 4000, 37233, @err_section + ISNULL(TEMP.branch_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN apbranch BRN ON TEMP.branch_code = BRN.branch_code    
WHERE (TEMP.row_action = 1 AND BRN.branch_code IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.branch_code IS NULL AND BRN.branch_code IS NULL)    
    
INSERT #ewerror     
SELECT 4000, 37234, @err_section + ISNULL(CAST(TEMP.credit_limit AS VARCHAR(30)),''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE TEMP.credit_limit_flag = 1 AND TEMP.credit_limit IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37235, @err_section + ISNULL(CAST(TEMP.aging_limit AS VARCHAR(30)),''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE TEMP.aging_limit_flag = 1 AND TEMP.aging_limit IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37236, @err_section + ISNULL(CAST(TEMP.restock_chg AS VARCHAR(30)),''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE TEMP.restock_chg_flag = 1 AND TEMP.restock_chg IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37237, @err_section + ISNULL(TEMP.exp_acct_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN glchart_vw CHRT ON TEMP.exp_acct_code = CHRT.account_code    
WHERE NOT TEMP.exp_acct_code IS NULL AND RTRIM(LTRIM(TEMP.exp_acct_code)) <> '' AND CHRT.account_code IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37238, @err_section + ISNULL(TEMP.code_1099,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN appyt PAY ON TEMP.code_1099 = PAY.code_1099    
WHERE NOT TEMP.code_1099 IS NULL AND RTRIM(LTRIM(TEMP.code_1099)) <> '' AND PAY.code_1099 IS NULL    
    
INSERT #ewerror     
SELECT 4000, 37239, @err_section + ISNULL(TEMP.user_trx_type_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN apusrtyp TYP ON TEMP.user_trx_type_code = TYP.user_trx_type_code    
WHERE (TEMP.row_action = 1 AND TYP.user_trx_type_code IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.user_trx_type_code IS NULL AND TYP.user_trx_type_code IS NULL)    
     
INSERT #ewerror     
SELECT 4000, 37240, @err_section + ISNULL(TEMP.payment_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN appymeth_vw PAY ON TEMP.payment_code = PAY.payment_code    
WHERE (TEMP.row_action = 1 AND PAY.payment_code IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.payment_code IS NULL AND PAY.payment_code IS NULL)    
    
INSERT #ewerror     
SELECT 4000, 37241, @err_section + ISNULL(TEMP.rate_type_home,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN glrtype_vw TYP ON TEMP.rate_type_home = TYP.rate_type    
WHERE (TEMP.row_action = 1 AND TYP.rate_type IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.rate_type_home IS NULL AND TYP.rate_type IS NULL)    
    
INSERT #ewerror     
SELECT 4000, 37242, @err_section + ISNULL(TEMP.rate_type_oper,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN glrtype_vw TYP ON TEMP.rate_type_oper = TYP.rate_type    
WHERE (TEMP.row_action = 1 AND TYP.rate_type IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.rate_type_oper IS NULL AND TYP.rate_type IS NULL)    
    
INSERT #ewerror     
SELECT 4000, 37243, @err_section + ISNULL(TEMP.nat_cur_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN glcurr_vw CUR ON TEMP.nat_cur_code = CUR.currency_code    
WHERE (TEMP.row_action = 1 AND CUR.currency_code IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.nat_cur_code IS NULL AND CUR.currency_code IS NULL)    
    
INSERT #ewerror     
SELECT 4000, 37244, @err_section + ISNULL(TEMP.cash_acct_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN glchart_vw CHRT ON TEMP.cash_acct_code = CHRT.account_code    
WHERE (TEMP.row_action = 1 AND CHRT.account_code IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.cash_acct_code IS NULL AND CHRT.account_code IS NULL)    
    
INSERT #ewerror     
SELECT 4000, 37245, @err_section + ISNULL(TEMP.freight_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN arshipv SHP ON TEMP.freight_code = SHP.ship_via_code    
WHERE NOT TEMP.freight_code IS NULL AND RTRIM(LTRIM(TEMP.freight_code)) <> '' AND SHP.ship_via_code IS NULL    
    
    
    
    
INSERT #ewerror     
SELECT 4000, 37246, @err_section + ISNULL(TEMP.country_code,''), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
 LEFT JOIN gl_country CTRY ON TEMP.country_code = CTRY.country_code    
WHERE (TEMP.row_action = 1 AND CTRY.country_code IS NULL) OR    
   (TEMP.row_action = 2 AND NOT TEMP.country_code IS NULL AND CTRY.country_code IS NULL)    
    
    
INSERT #ewerror     
SELECT 4000, 37264, @err_section + CAST(ISNULL(TEMP.status_type,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT TEMP.status_type IS NULL AND NOT CAST(TEMP.status_type AS SMALLINT) BETWEEN 5 AND 6    
    
INSERT #ewerror     
SELECT 4000, 37275, @err_section + TEMP.vendor_code, TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE TEMP.row_action = 2 AND CAST(TEMP.status_type AS SMALLINT) = 6 AND EXISTS (SELECT COUNT(1) FROM apinpchg WHERE trx_type = 4091 AND vendor_code = TEMP.vendor_code)    
    
    
INSERT #ewerror     
SELECT 4000, 37265, @err_section + CAST(ISNULL(TEMP.proc_vend_flag,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT TEMP.proc_vend_flag IS NULL AND NOT CAST(TEMP.proc_vend_flag AS SMALLINT) BETWEEN 0 AND 1    
    
    
INSERT #ewerror     
SELECT 4000, 37266, @err_section + CAST(ISNULL(TEMP.limit_by_home,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT TEMP.limit_by_home IS NULL AND NOT CAST(TEMP.limit_by_home AS SMALLINT) BETWEEN 0 AND 1    
    
    
INSERT #ewerror     
SELECT 4000, 37267, @err_section + CAST(ISNULL(TEMP.credit_limit_flag,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT TEMP.credit_limit_flag IS NULL AND NOT CAST(TEMP.credit_limit_flag AS SMALLINT) BETWEEN 0 AND 1    
    
    
INSERT #ewerror     
SELECT 4000, 37268, @err_section + CAST(ISNULL(TEMP.aging_limit_flag,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT TEMP.aging_limit_flag IS NULL AND NOT CAST(TEMP.aging_limit_flag AS SMALLINT) BETWEEN 0 AND 1    
    
    
INSERT #ewerror     
SELECT 4000, 37269, @err_section + CAST(ISNULL(TEMP.flag_1099,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT TEMP.flag_1099 IS NULL AND NOT CAST(TEMP.flag_1099 AS SMALLINT) BETWEEN 0 AND 1    
    
    
INSERT #ewerror     
SELECT 4000, 37271, @err_section + CAST(ISNULL(TEMP.one_cur_vendor,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT TEMP.one_cur_vendor IS NULL AND NOT CAST(TEMP.one_cur_vendor AS SMALLINT) BETWEEN 0 AND 1    
    
INSERT #ewerror     
SELECT 4000, 37270, @err_section + CAST(ISNULL(TEMP.one_check_flag,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT TEMP.one_check_flag IS NULL AND NOT CAST(TEMP.one_check_flag AS SMALLINT) BETWEEN 0 AND 1    
    
    
INSERT #ewerror     
SELECT 4000, 37272, @err_section + CAST(ISNULL(TEMP.restock_chg_flag,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT TEMP.restock_chg_flag IS NULL AND NOT CAST(TEMP.restock_chg_flag AS SMALLINT) BETWEEN 0 AND 1    
    
    
INSERT #ewerror     
SELECT 4000, 37273, @err_section + CAST(ISNULL(TEMP.prc_flag,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT TEMP.prc_flag IS NULL AND NOT CAST(TEMP.prc_flag AS SMALLINT) BETWEEN 0 AND 1    
    
    
INSERT #ewerror     
SELECT 4000, 37279, @err_section + CAST(ISNULL(TEMP.phone_1,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT (TEMP.phone_1) IS NULL     
 AND (ISNUMERIC(TEMP.phone_1) = 0    
 OR CHARINDEX('.',TEMP.phone_1) != 0    
 OR CHARINDEX('-',TEMP.phone_1) != 0    
 OR CHARINDEX('+',TEMP.phone_1) != 0    
 OR CHARINDEX('$',TEMP.phone_1) != 0)    
 AND TEMP.phone_1 != ''    
    
INSERT #ewerror     
SELECT 4000, 37280, @err_section  + CAST(ISNULL(TEMP.phone_2,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT (TEMP.phone_2) IS NULL     
 AND (ISNUMERIC(TEMP.phone_2) = 0    
 OR CHARINDEX('.',TEMP.phone_2) != 0    
 OR CHARINDEX('-',TEMP.phone_2) != 0    
 OR CHARINDEX('+',TEMP.phone_2) != 0    
 OR CHARINDEX('$',TEMP.phone_2) != 0)    
 AND TEMP.phone_2 != ''    
     
INSERT #ewerror     
SELECT 4000, 37277, @err_section + CAST(ISNULL(TEMP.attention_phone,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT (TEMP.attention_phone) IS NULL     
 AND (ISNUMERIC(TEMP.attention_phone) = 0    
 OR CHARINDEX('.',TEMP.attention_phone) != 0    
 OR CHARINDEX('-',TEMP.attention_phone) != 0    
 OR CHARINDEX('+',TEMP.attention_phone) != 0    
 OR CHARINDEX('$',TEMP.attention_phone) != 0)    
 AND TEMP.attention_phone != ''    
     
    
INSERT #ewerror     
SELECT 4000, 37278, @err_section + CAST(ISNULL(TEMP.contact_phone,'') AS VARCHAR(100)), TEMP.vendor_code    
FROM ZTEMP_vendor_val TEMP    
WHERE NOT (TEMP.contact_phone) IS NULL     
 AND (ISNUMERIC(TEMP.contact_phone) = 0    
 OR CHARINDEX('.',TEMP.contact_phone) != 0    
 OR CHARINDEX('-',TEMP.contact_phone) != 0    
 OR CHARINDEX('+',TEMP.contact_phone) != 0    
 OR CHARINDEX('$',TEMP.contact_phone) != 0)    
 AND TEMP.contact_phone != ''    
    
SET @err_section = ISNULL((SELECT e_ldesc FROM aperrdef WHERE e_code = 37252),'')    
    
INSERT #ewerror     
SELECT 4000, 37219, @err_section + ISNULL(TEMP.vendor_code,''), TEMP.vendor_code    
FROM ZTEMP_eft_apmsvend TEMP    
WHERE (TEMP.row_action = 1 AND (TEMP.vendor_code IS NULL OR RTRIM(LTRIM(TEMP.vendor_code)) = '')) OR    
   (TEMP.row_action = 2 AND (NOT TEMP.vendor_code IS NULL AND RTRIM(LTRIM(TEMP.vendor_code)) = ''))    
    
INSERT #ewerror     
SELECT 4000, 37254, @err_section + ISNULL(TEMP.bank_name,''), TEMP.vendor_code    
FROM ZTEMP_eft_apmsvend TEMP    
WHERE (TEMP.row_action = 1 AND (TEMP.bank_name IS NULL OR RTRIM(LTRIM(TEMP.bank_name)) = '')) OR    
   (TEMP.row_action = 2 AND (NOT TEMP.bank_name IS NULL AND RTRIM(LTRIM(TEMP.bank_name)) = ''))    
    
INSERT #ewerror     
SELECT 4000, 37255, @err_section + ISNULL(TEMP.bank_account_num,''), TEMP.vendor_code    
FROM ZTEMP_eft_apmsvend TEMP    
WHERE (TEMP.row_action = 1 AND (TEMP.bank_account_num IS NULL OR RTRIM(LTRIM(TEMP.bank_account_num)) = '')) OR    
   (TEMP.row_action = 2 AND (NOT TEMP.bank_account_num IS NULL AND RTRIM(LTRIM(TEMP.bank_account_num)) = ''))    
    
INSERT #ewerror     
SELECT 4000, 37256, @err_section + ISNULL(TEMP.aba_number,''), TEMP.vendor_code    
FROM ZTEMP_eft_apmsvend TEMP    
WHERE (TEMP.row_action = 1 AND (TEMP.aba_number IS NULL OR RTRIM(LTRIM(TEMP.aba_number)) = '')) OR    
   (TEMP.row_action = 2 AND (NOT TEMP.aba_number IS NULL AND RTRIM(LTRIM(TEMP.aba_number)) = ''))    
    
INSERT #ewerror     
SELECT 4000, 37257, @err_section + ISNULL(CAST(TEMP.account_type AS VARCHAR(30)),''), TEMP.vendor_code    
FROM ZTEMP_eft_apmsvend TEMP    
WHERE (TEMP.row_action = 1 AND (TEMP.account_type IS NULL OR NOT TEMP.account_type BETWEEN 0 AND 1)) OR    
   (TEMP.row_action = 2 AND (NOT TEMP.account_type IS NULL AND NOT TEMP.account_type BETWEEN 0 AND 1))    
    
RETURN 0    
/**/ 

GO
GRANT EXECUTE ON  [dbo].[CVO_ValidateVendors] TO [public]
GO
