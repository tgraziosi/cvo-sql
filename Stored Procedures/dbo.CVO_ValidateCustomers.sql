SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_ValidateCustomers] (@debug_level smallint = 0)          
AS          
          
DECLARE @err_info varchar(32),          
  @err_section CHAR(30)          
          
          
          
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/ar_customer_validation.sp' + ', line ' + STR( 124, 5 ) + ' -- Validate information: '          
          
SET @err_info= ISNULL((SELECT e_ldesc FROM arerrdef WHERE e_code = 35059),'')          
SET @err_section = ISNULL((SELECT e_ldesc FROM arerrdef WHERE e_code = 35060),'')          
          
INSERT #ewerror           
SELECT 2000, 35078, @err_section + ISNULL(TEMP.customer_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
GROUP BY TEMP.customer_code          
HAVING COUNT(TEMP.customer_code) >= 2          
          
INSERT #ewerror           
SELECT 2000, 35018, 'Cant Inser Duplicate Customer ' + ISNULL(TEMP.customer_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 INNER JOIN arcust CUST ON TEMP.customer_code = CUST.customer_code          
WHERE TEMP.row_action = 1          
          
INSERT #ewerror           
SELECT 2000, 35019, @err_section + ISNULL(TEMP.customer_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arcust CUST ON TEMP.customer_code = CUST.customer_code          
WHERE TEMP.row_action = 2 AND CUST.customer_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35020, @err_section + '', ''          
FROM ZTEMP_customer_val          
WHERE customer_code IS NULL OR RTRIM(LTRIM(customer_code)) = ''          
          
INSERT #ewerror           
SELECT 2000, 35021, @err_section + CAST(ISNULL(TEMP.status_type,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.status_type IS NULL AND NOT CAST(TEMP.status_type AS SMALLINT) BETWEEN 0 AND 3          
          
INSERT #ewerror           
SELECT 2000, 35022, @err_section + ISNULL(TEMP.ship_to_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arshipto SHP ON TEMP.ship_to_code = SHP.ship_to_code          
WHERE NOT TEMP.ship_to_code IS NULL AND RTRIM(LTRIM(TEMP.ship_to_code)) <> '' AND SHP.ship_to_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35023, @err_section + ISNULL(TEMP.tax_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN artax_vw TAX ON TEMP.tax_code = TAX.tax_code          
WHERE (TEMP.row_action = 1 AND TAX.tax_code IS NULL) OR          
   (TEMP.row_action = 2 AND NOT TEMP.tax_code IS NULL AND TAX.tax_code IS NULL)          
          
INSERT #ewerror           
SELECT 2000, 35024, 'Invalid Terms Code ' + ISNULL(TEMP.terms_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arterms TRMS ON TEMP.terms_code = TRMS.terms_code          
WHERE (TEMP.row_action = 1 AND TRMS.terms_code IS NULL) OR          
   (TEMP.row_action = 2 AND NOT TEMP.terms_code IS NULL AND TRMS.terms_code IS NULL)          
          
INSERT #ewerror           
SELECT 2000, 35025, @err_section + ISNULL(TEMP.fob_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arfob FOB ON TEMP.fob_code = FOB.fob_code          
WHERE NOT TEMP.fob_code IS NULL AND RTRIM(LTRIM(TEMP.fob_code)) <> '' AND FOB.fob_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35026, @err_section + ISNULL(TEMP.freight_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arfrcode FRG ON TEMP.freight_code = FRG.freight_code          
WHERE NOT TEMP.freight_code IS NULL AND RTRIM(LTRIM(TEMP.freight_code)) <> '' AND FRG.freight_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35027, @err_section + ISNULL(TEMP.posting_code,''), TEMP.customer_code        
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN araccts CCTS ON TEMP.posting_code = CCTS.posting_code          
WHERE (TEMP.row_action = 1 AND CCTS.posting_code IS NULL) OR          
   (TEMP.row_action = 2 AND NOT TEMP.posting_code IS NULL AND CCTS.posting_code IS NULL)          
          
INSERT #ewerror           
SELECT 2000, 35028, @err_section + ISNULL(TEMP.location_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arloc_vw LOC ON TEMP.location_code = LOC.location          
WHERE NOT TEMP.location_code IS NULL AND RTRIM(LTRIM(TEMP.location_code)) <> '' AND LOC.location IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35029, @err_section + ISNULL(TEMP.alt_location_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arloc_vw LOC ON TEMP.alt_location_code = LOC.alt_location          
WHERE NOT TEMP.alt_location_code IS NULL AND RTRIM(LTRIM(TEMP.alt_location_code)) <> '' AND LOC.alt_location IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35030, @err_section + ISNULL(TEMP.dest_zone_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arzone ZON ON TEMP.dest_zone_code = ZON.zone_code          
WHERE NOT TEMP.dest_zone_code IS NULL AND RTRIM(LTRIM(TEMP.dest_zone_code)) <> '' AND ZON.zone_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35031, 'Invalid Territory Code ' + ISNULL(TEMP.territory_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arterr TERR ON TEMP.territory_code = TERR.territory_code          
WHERE NOT TEMP.territory_code IS NULL AND RTRIM(LTRIM(TEMP.territory_code)) <> '' AND TERR.territory_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35032, 'Invalid Sales Person Code ' + ISNULL(TEMP.salesperson_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arsalesp SAL ON TEMP.salesperson_code = SAL.salesperson_code          
WHERE NOT TEMP.salesperson_code IS NULL AND RTRIM(LTRIM(TEMP.salesperson_code)) <> '' AND SAL.salesperson_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35033, @err_section + ISNULL(TEMP.fin_chg_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arfinchg FIN ON TEMP.fin_chg_code = FIN.fin_chg_code          
WHERE NOT TEMP.fin_chg_code IS NULL AND RTRIM(LTRIM(TEMP.fin_chg_code)) <> '' AND FIN.fin_chg_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35034, 'Invalid Price Code ' + ISNULL(TEMP.price_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arprice PRC ON TEMP.price_code = PRC.price_code          
WHERE NOT TEMP.price_code IS NULL AND RTRIM(LTRIM(TEMP.price_code)) <> '' AND PRC.price_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35035, @err_section + ISNULL(TEMP.payment_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arpymeth PYMT ON TEMP.payment_code = PYMT.payment_code          
WHERE (TEMP.row_action = 1 AND RTRIM(LTRIM(TEMP.payment_code)) <> '' AND PYMT.payment_code IS NULL) OR          
   (TEMP.row_action = 2 AND RTRIM(LTRIM(TEMP.payment_code)) <> '' AND NOT TEMP.payment_code IS NULL AND PYMT.payment_code IS NULL)          
          
INSERT #ewerror           
SELECT 2000, 35036, @err_section + ISNULL(TEMP.vendor_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN apvend VEND ON TEMP.vendor_code = VEND.vendor_code          
WHERE NOT TEMP.vendor_code IS NULL AND RTRIM(LTRIM(TEMP.vendor_code)) <> '' AND VEND.vendor_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35037, @err_section + ISNULL(TEMP.affiliated_cust_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP    
 LEFT JOIN arcust CUST ON TEMP.affiliated_cust_code = CUST.customer_code          
WHERE NOT TEMP.affiliated_cust_code IS NULL AND RTRIM(LTRIM(TEMP.affiliated_cust_code)) <> '' AND CUST.customer_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35038, @err_section + ISNULL(TEMP.stmt_cycle_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arcycle CYC ON TEMP.stmt_cycle_code = CYC.cycle_code          
WHERE NOT TEMP.stmt_cycle_code IS NULL AND CYC.cycle_code IS NULL AND TEMP.print_stmt_flag = 1          
          
INSERT #ewerror           
SELECT 2000, 35039, @err_section + ISNULL(TEMP.inv_comment_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arcommnt COMM ON TEMP.inv_comment_code = COMM.comment_code          
WHERE NOT TEMP.inv_comment_code IS NULL AND RTRIM(LTRIM(TEMP.inv_comment_code)) <> '' AND COMM.comment_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35040, @err_section + ISNULL(TEMP.stmt_comment_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arcommnt COMM ON TEMP.stmt_comment_code = COMM.comment_code          
WHERE NOT TEMP.stmt_comment_code IS NULL AND RTRIM(LTRIM(TEMP.stmt_comment_code)) <> '' AND COMM.comment_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35041, @err_section + ISNULL(TEMP.dunn_message_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN ardunn DUNN ON TEMP.dunn_message_code = DUNN.dunn_message_code          
WHERE NOT TEMP.dunn_message_code IS NULL AND RTRIM(LTRIM(TEMP.dunn_message_code)) <> '' AND DUNN.dunn_message_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35042, @err_section + CAST(ISNULL(TEMP.aging_limit_bracket,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE TEMP.check_aging_limit = 1 AND NOT TEMP.aging_limit_bracket IS NULL          
AND NOT CAST(TEMP.aging_limit_bracket AS SMALLINT) BETWEEN 1 AND 5          
          
INSERT #ewerror           
SELECT 2000, 35043, @err_section + ISNULL(TEMP.payer_soldto_rel_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN  arrelcde REL ON  TEMP.payer_soldto_rel_code = REL.relation_code          
WHERE NOT TEMP.payer_soldto_rel_code IS NULL AND REL.relation_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35044, @err_section + ISNULL(TEMP.rate_type_home,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN glrtype_vw TYP ON TEMP.rate_type_home = TYP.rate_type          
WHERE NOT TEMP.rate_type_home IS NULL AND RTRIM(LTRIM(TEMP.rate_type_home)) <> '' AND TYP.rate_type IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35045, @err_section + ISNULL(TEMP.rate_type_oper,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN glrtype_vw TYP ON TEMP.rate_type_oper = TYP.rate_type          
WHERE NOT TEMP.rate_type_oper IS NULL AND RTRIM(LTRIM(TEMP.rate_type_oper)) <> '' AND TYP.rate_type IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35046, @err_section + ISNULL(TEMP.nat_cur_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN glcurr_vw CURR ON TEMP.nat_cur_code = CURR.currency_code          
WHERE (TEMP.row_action = 1 AND CURR.currency_code IS NULL) OR          
   (TEMP.row_action = 2 AND NOT TEMP.nat_cur_code IS NULL AND CURR.currency_code IS NULL)          
          
INSERT #ewerror           
SELECT 2000, 35047, 'Invalid Country Code ' + ISNULL(TEMP.country_code,''), TEMP.customer_code      --Fzambada  
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN gl_country CNT ON TEMP.country_code = CNT.country_code          
WHERE (TEMP.row_action = 1 AND CNT.country_code IS NULL) OR          
  (TEMP.row_action = 2 AND NOT TEMP.country_code IS NULL AND CNT.country_code IS NULL)          
          
INSERT #ewerror           
SELECT 2000, 35048, @err_section + ISNULL(TEMP.remit_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arremit REM ON TEMP.remit_code = REM.kys          
WHERE NOT TEMP.remit_code IS NULL AND RTRIM(LTRIM(TEMP.remit_code)) <> '' AND REM.kys IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35049, @err_section + ISNULL(TEMP.forwarder_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arfwdr FWR ON TEMP.forwarder_code = FWR.kys          
WHERE NOT TEMP.forwarder_code IS NULL AND RTRIM(LTRIM(TEMP.forwarder_code)) <> '' AND FWR.kys IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35050, @err_section + ISNULL(TEMP.freight_to_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arfrt_to FRG ON TEMP.freight_to_code = FRG.kys          
WHERE NOT TEMP.freight_to_code IS NULL AND RTRIM(LTRIM(TEMP.freight_to_code)) <> '' AND FRG.kys IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35051, 'Invalid Ship Via Code ' + ISNULL(TEMP.ship_via_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arshipv SHP ON TEMP.ship_via_code = SHP.ship_via_code          
WHERE NOT TEMP.ship_via_code IS NULL AND RTRIM(LTRIM(TEMP.ship_via_code)) <> '' AND SHP.ship_via_code IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35052, @err_section + CAST(ISNULL(TEMP.so_priority_code,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.so_priority_code IS NULL AND NOT CAST(TEMP.so_priority_code AS SMALLINT) BETWEEN 0 AND 8          
          
INSERT #ewerror           
SELECT 2000, 35053, @err_section + ISNULL(TEMP.dunning_group_id,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN ardngpdt DUNN ON TEMP.dunning_group_id = DUNN.group_id          
WHERE NOT TEMP.dunning_group_id IS NULL AND RTRIM(LTRIM(TEMP.dunning_group_id)) <> '' AND DUNN.group_id IS NULL          
          
INSERT #ewerror           
SELECT 2000, 35054, @err_section + ISNULL(TEMP.writeoff_code,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
 LEFT JOIN arwrofac FAC ON TEMP.writeoff_code = FAC.writeoff_code          
WHERE (TEMP.row_action = 1 AND FAC.writeoff_code IS NULL) OR          
   (TEMP.row_action = 2 AND NOT TEMP.writeoff_code IS NULL AND FAC.writeoff_code IS NULL)          
          
          
          
          
          
INSERT #ewerror           
SELECT 2000, 35063, @err_section + CAST(ISNULL(TEMP.print_stmt_flag,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.print_stmt_flag IS NULL AND NOT TEMP.print_stmt_flag BETWEEN 0 AND 1          
          
INSERT #ewerror           
SELECT 2000, 35064, @err_section + CAST(ISNULL(TEMP.check_credit_limit,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.check_credit_limit IS NULL AND NOT TEMP.check_credit_limit BETWEEN 0 AND 1          
          
INSERT #ewerror           
SELECT 2000, 35065, @err_section + CAST(ISNULL(TEMP.check_aging_limit,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.check_aging_limit IS NULL AND NOT TEMP.check_aging_limit BETWEEN 0 AND 1          
          
          
          
          
          
          
          
          
          
INSERT #ewerror           
SELECT 2000, 35067, @err_section + CAST(ISNULL(TEMP.bal_fwd_flag,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.bal_fwd_flag IS NULL AND NOT TEMP.bal_fwd_flag BETWEEN 0 AND 1          
   
INSERT #ewerror           
SELECT 2000, 35068, @err_section + CAST(ISNULL(TEMP.ship_complete_flag,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.ship_complete_flag IS NULL AND NOT TEMP.ship_complete_flag BETWEEN 0 AND 2          
          
INSERT #ewerror           
SELECT 2000, 35069, @err_section + CAST(ISNULL(TEMP.late_chg_type,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.late_chg_type IS NULL AND NOT TEMP.late_chg_type BETWEEN 0 AND 2          
          
INSERT #ewerror           
SELECT 2000, 35070, @err_section + CAST(ISNULL(TEMP.valid_payer_flag,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.valid_payer_flag IS NULL AND NOT TEMP.valid_payer_flag BETWEEN 0 AND 1          
          
INSERT #ewerror           
SELECT 2000, 35071, @err_section + CAST(ISNULL(TEMP.valid_soldto_flag,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.valid_soldto_flag IS NULL AND NOT TEMP.valid_soldto_flag BETWEEN 0 AND 1          
          
INSERT #ewerror           
SELECT 2000, 35072, @err_section + CAST(ISNULL(TEMP.valid_shipto_flag,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.valid_shipto_flag IS NULL AND NOT TEMP.valid_shipto_flag BETWEEN 0 AND 1          
          
INSERT #ewerror           
SELECT 2000, 35073, @err_section + CAST(ISNULL(TEMP.across_na_flag,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.across_na_flag IS NULL AND NOT TEMP.across_na_flag BETWEEN 0 AND 2          
          
INSERT #ewerror           
SELECT 2000, 35074, @err_section + CAST(ISNULL(TEMP.limit_by_home,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.limit_by_home IS NULL AND NOT TEMP.limit_by_home BETWEEN 0 AND 1          
          
INSERT #ewerror           
SELECT 2000, 35075, @err_section + CAST(ISNULL(TEMP.one_cur_cust,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.one_cur_cust IS NULL AND NOT TEMP.one_cur_cust BETWEEN 0 AND 1          
          
INSERT #ewerror           
SELECT 2000, 35076, @err_section + ISNULL(TEMP.price_level,''), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.price_level IS NULL AND NOT CAST(TEMP.price_level AS SMALLINT) BETWEEN 1 AND 5          
          
INSERT #ewerror           
SELECT 2000, 35077, @err_section + CAST(ISNULL(TEMP.consolidated_invoices,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT TEMP.consolidated_invoices IS NULL AND NOT TEMP.consolidated_invoices BETWEEN 0 AND 1          
          
          
INSERT #ewerror           
SELECT 2000, 35079, @err_section + CAST(ISNULL(TEMP.attention_phone,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT (TEMP.attention_phone) IS NULL           
 AND (ISNUMERIC(TEMP.attention_phone) = 0          
 OR CHARINDEX('.',TEMP.attention_phone) != 0          
 OR CHARINDEX('-',TEMP.attention_phone) != 0          
 OR CHARINDEX('+',TEMP.attention_phone) != 0          
 OR CHARINDEX('$',TEMP.attention_phone) != 0)          
 AND TEMP.attention_phone != ''          
          
INSERT #ewerror           
SELECT 2000, 35080, @err_section + CAST(ISNULL(TEMP.contact_phone,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT (TEMP.contact_phone) IS NULL           
 AND (ISNUMERIC(TEMP.contact_phone) = 0          
 OR CHARINDEX('.',TEMP.contact_phone) != 0          
 OR CHARINDEX('-',TEMP.contact_phone) != 0          
 OR CHARINDEX('+',TEMP.contact_phone) != 0          
 OR CHARINDEX('$',TEMP.contact_phone) != 0)          
 AND TEMP.contact_phone != ''          
          
INSERT #ewerror           
SELECT 2000, 35081, @err_section + CAST(ISNULL(TEMP.phone_1,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP          
WHERE NOT (TEMP.phone_1) IS NULL           
 AND (ISNUMERIC(TEMP.phone_1) = 0          
 OR CHARINDEX('.',TEMP.phone_1) != 0          
 OR CHARINDEX('-',TEMP.phone_1) != 0          
 OR CHARINDEX('+',TEMP.phone_1) != 0          
 OR CHARINDEX('$',TEMP.phone_1) != 0)          
 AND TEMP.phone_1 != ''          
          
INSERT #ewerror           
SELECT 2000, 35082, @err_section + CAST(ISNULL(TEMP.phone_2,'') AS VARCHAR(100)), TEMP.customer_code          
FROM ZTEMP_customer_val TEMP    
WHERE NOT (TEMP.phone_2) IS NULL           
 AND (ISNUMERIC(TEMP.phone_2) = 0          
 OR CHARINDEX('.',TEMP.phone_2) != 0          
 OR CHARINDEX('-',TEMP.phone_2) != 0          
 OR CHARINDEX('+',TEMP.phone_2) != 0          
 OR CHARINDEX('$',TEMP.phone_2) != 0)          
 AND TEMP.phone_2 != ''          
          
      
          
RETURN 0 

GO
GRANT EXECUTE ON  [dbo].[CVO_ValidateCustomers] TO [public]
GO
