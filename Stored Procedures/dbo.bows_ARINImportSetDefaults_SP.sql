SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
    
CREATE PROCEDURE [dbo].[bows_ARINImportSetDefaults_SP] @process_ctrl_num varchar(16),    
 @debug_level smallint = 0    
    
AS    
BEGIN    
    
 DECLARE @home_currency varchar(8),    
 @oper_currency  varchar(8),    
 @result  int,    
 @date_entered  int,    
 @trx_ctrl_num  varchar(16),    
 @doc_ctrl_num  varchar(16),    
 @rate_type_home  varchar(8),    
 @rate_type_oper  varchar(8)    
    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 27, 5 ) + ' -- ENTRY: '    
    
 IF (@debug_level > 0 )    
 BEGIN    
 SELECT 'Dumping #arinpchg...'    
 SELECT * FROM #arinpchg    
 END    
    
 SELECT @date_entered = datediff(dd,'1/1/80',getdate())+722815    
    
 SELECT @home_currency = home_currency,    
 @oper_currency = oper_currency    
 FROM glco    
    
 UPDATE #arinpchg    
 SET    
    
 date_applied = (CASE WHEN date_applied IS NULL OR date_applied = 0    
 THEN @date_entered    
 ELSE date_applied END),    
 date_doc = (CASE WHEN date_doc IS NULL OR date_doc = 0    
 THEN @date_entered    
 ELSE date_doc END),    
 date_shipped = (CASE WHEN date_shipped IS NULL OR date_shipped = 0    
 THEN @date_entered    
 ELSE date_shipped END),    
 date_required = (CASE WHEN date_required IS NULL OR date_required = 0    
 THEN @date_entered    
 ELSE date_required END),    
 date_aging = (CASE WHEN date_aging IS NULL OR date_aging = 0    
 THEN @date_entered    
 ELSE date_aging END),    
 process_group_num = @process_ctrl_num    
 IF( @@error != 0 ) BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 66, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 UPDATE #arinpchg    
 SET ship_to_code = ISNULL(#arinpchg.ship_to_code, cust.ship_to_code)    
 FROM armaster cust    
 WHERE #arinpchg.customer_code = cust.customer_code    
 AND cust.address_type = 0    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 82, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 UPDATE #arinpchg    
 SET salesperson_code = ISNULL( #arinpchg.salesperson_code, ship_to.salesperson_code ),    
 terms_code = ISNULL( #arinpchg.terms_code, ship_to.terms_code ),    
 territory_code = ISNULL( #arinpchg.territory_code, ship_to.territory_code ),    
 fob_code = ISNULL( #arinpchg.fob_code, ship_to.fob_code ),    
 freight_code = ISNULL( #arinpchg.freight_code, ship_to.freight_code ),    
 dest_zone_code = ISNULL( #arinpchg.dest_zone_code, ship_to.dest_zone_code ),    
 posting_code = ISNULL( #arinpchg.posting_code, ship_to.posting_code ),    
 tax_code = ISNULL( #arinpchg.tax_code, ship_to.tax_code ),    
 location_code = ISNULL( #arinpchg.location_code, ship_to.location_code ),    
 attention_phone = ISNULL( #arinpchg.attention_phone, ship_to.attention_phone ),    
 attention_name = ISNULL( #arinpchg.attention_name, ship_to.attention_name ),    
 nat_cur_code = ISNULL( #arinpchg.nat_cur_code, ship_to.nat_cur_code ),    
 rate_type_home = ISNULL( #arinpchg.rate_type_home, ship_to.rate_type_home ),    
 rate_type_oper = ISNULL( #arinpchg.rate_type_oper, ship_to.rate_type_oper )    
 FROM armaster ship_to    
 WHERE #arinpchg.customer_code = ship_to.customer_code    
 AND #arinpchg.ship_to_code = ship_to.ship_to_code    
 AND ship_to.address_type = 1    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 110, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 UPDATE #arinpchg    
 SET ship_to_addr1 = ship_to.addr1,    
 ship_to_addr2 = ship_to.addr2,    
 ship_to_addr3 = ship_to.addr3,    
 ship_to_addr4 = ship_to.addr4,    
 ship_to_addr5 = ship_to.addr5,    
 ship_to_addr6 = ship_to.addr6    
 FROM armaster ship_to    
 WHERE    
( LTRIM(ship_to.addr1+ship_to.addr2+ship_to.addr3+ship_to.addr4+ ship_to.addr5+ship_to.addr6) IS NULL OR LTRIM(ship_to.addr1+ship_to.addr2+ship_to.addr3+ship_to.addr4+ ship_to.addr5+ship_to.addr6) = ' ' )    
 AND #arinpchg.customer_code = ship_to.customer_code    
 AND #arinpchg.ship_to_code = ship_to.ship_to_code    
 AND ship_to.address_type = 1    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 133, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 UPDATE #arinpchg    
 SET salesperson_code = ISNULL( #arinpchg.salesperson_code, cust.salesperson_code ),    
 terms_code = ISNULL( #arinpchg.terms_code, cust.terms_code ),    
 territory_code = ISNULL( #arinpchg.territory_code, cust.territory_code ),    
 fob_code = ISNULL( #arinpchg.fob_code, cust.fob_code ),    
 freight_code = ISNULL( #arinpchg.freight_code, cust.freight_code ),    
 fin_chg_code = ISNULL( #arinpchg.fin_chg_code, cust.fin_chg_code ),    
 price_code = ISNULL( #arinpchg.price_code, cust.price_code ),    
 dest_zone_code = ISNULL( #arinpchg.dest_zone_code, cust.dest_zone_code ),    
 posting_code = ISNULL( #arinpchg.posting_code, cust.posting_code ),    
 tax_code = ISNULL( #arinpchg.tax_code, cust.tax_code ),    
 location_code = ISNULL( #arinpchg.location_code, cust.location_code ),    
 attention_phone = ISNULL( #arinpchg.attention_phone, cust.attention_phone ),    
 attention_name = ISNULL( #arinpchg.attention_name, cust.attention_name ),    
 nat_cur_code = ISNULL( #arinpchg.nat_cur_code, cust.nat_cur_code ),    
 rate_type_home = ISNULL( #arinpchg.rate_type_home, cust.rate_type_home ),    
 rate_type_oper = ISNULL( #arinpchg.rate_type_oper, cust.rate_type_oper ),    
 comment_code = ISNULL( #arinpchg.comment_code, cust.inv_comment_code ),    
 ship_to_addr1 = ISNULL(#arinpchg.ship_to_addr1, ' '),    
 ship_to_addr2 = ISNULL(#arinpchg.ship_to_addr2, ' '),    
 ship_to_addr3 = ISNULL(#arinpchg.ship_to_addr3, ' '),    
 ship_to_addr4 = ISNULL(#arinpchg.ship_to_addr4, ' '),    
 ship_to_addr5 = ISNULL(#arinpchg.ship_to_addr5, ' '),    
 ship_to_addr6 = ISNULL(#arinpchg.ship_to_addr6, ' '),    
 writeoff_code = CASE    
   WHEN (#arinpchg.trx_type=2032) THEN ISNULL(#arinpchg.writeoff_code, cust.writeoff_code)    
   ELSE #arinpchg.writeoff_code    
   END    
 FROM armaster cust    
 WHERE #arinpchg.customer_code = cust.customer_code    
 AND cust.address_type = 0    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 173, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
     
 SELECT  @rate_type_home = glco.rate_type_home,    
  @rate_type_oper = glco.rate_type_oper    
 FROM  glco    
  IF( @@error != 0 )    
  BEGIN    
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 183, 5 ) + ' -- EXIT: '    
  RETURN 34563    
  END    
    
 SELECT  @rate_type_home = ISNULL(@rate_type_home,''),    
  @rate_type_oper = ISNULL(@rate_type_oper,'')    
    
 UPDATE #arinpchg    
 SET    
 salesperson_code= ISNULL( #arinpchg.salesperson_code, ''),    
  terms_code  = ISNULL( #arinpchg.terms_code, ''),    
  territory_code  = ISNULL( #arinpchg.territory_code, ''),    
  fob_code  = ISNULL( #arinpchg.fob_code, ''),    
  freight_code  = ISNULL( #arinpchg.freight_code, ''),    
  fin_chg_code  = ISNULL( #arinpchg.fin_chg_code, ''),    
  price_code  = ISNULL( #arinpchg.price_code, ''),    
  dest_zone_code  = ISNULL( #arinpchg.dest_zone_code, ''),    
  location_code  = ISNULL( #arinpchg.location_code, ''),    
  attention_phone = ISNULL( #arinpchg.attention_phone, ''),    
  attention_name  = ISNULL( #arinpchg.attention_name, ''),    
  comment_code  = ISNULL( #arinpchg.comment_code, ''),    
  rate_type_home  = ISNULL( #arinpchg.rate_type_home, @rate_type_home),    
  rate_type_oper  = ISNULL( #arinpchg.rate_type_oper, @rate_type_oper)    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 211, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 UPDATE #arinpchg    
 SET customer_addr1 = ISNULL(cust.addr1, ' '),    
 customer_addr2 = ISNULL(cust.addr2, ' '),    
 customer_addr3 = ISNULL(cust.addr3, ' '),    
 customer_addr4 = ISNULL(cust.addr4, ' '),    
 customer_addr5 = ISNULL(cust.addr5, ' '),    
 customer_addr6 = ISNULL(cust.addr6, ' ')    
 FROM armaster cust    
 WHERE    
    
( LTRIM(ISNULL(customer_addr1, ' ')+ ISNULL(customer_addr2, ' ')+ ISNULL(customer_addr3, ' ')+ ISNULL(customer_addr4, ' ')+ ISNULL(customer_addr5, ' ')+ ISNULL(customer_addr6, ' ')) IS NULL OR LTRIM(ISNULL(customer_addr1, ' ')+ ISNULL(customer_addr2, ' '
  
)+ ISNULL(customer_addr3, ' ')+ ISNULL(customer_addr4, ' ')+ ISNULL(customer_addr5, ' ')+ ISNULL(customer_addr6, ' ')) = ' ' )    
 AND #arinpchg.customer_code = cust.customer_code    
 AND cust.address_type = 0    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 238, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 UPDATE #arinpchg    
 SET customer_addr1 = ISNULL(customer_addr1, ' '),    
 customer_addr2 = ISNULL(customer_addr2, ' '),    
 customer_addr3 = ISNULL(customer_addr3, ' '),    
 customer_addr4 = ISNULL(customer_addr4, ' '),    
 customer_addr5 = ISNULL(customer_addr5, ' '),    
 customer_addr6 = ISNULL(customer_addr6, ' ')    
    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 256, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
CREATE TABLE #arterm    
(    
 trx_ctrl_num   varchar(16),    
 date_doc  int,    
 terms_code  varchar(8),    
 date_due  int,    
 date_discount  int    
)    
    
 INSERT #arterm (trx_ctrl_num, date_doc, terms_code, date_due, date_discount)    
 SELECT trx_ctrl_num, date_doc, terms_code, 0, 0    
 FROM #arinpchg    
    
 EXEC @result = ARGetTermInfo_SP    
    
 UPDATE #arinpchg    
 SET date_due = #arterm.date_due    
 FROM #arterm    
 WHERE #arterm.trx_ctrl_num = #arinpchg.trx_ctrl_num    
    
 DROP TABLE #arterm    
    
 CREATE TABLE #rates_oper    
 (    
 from_currency varchar(8),    
 to_currency varchar(8),    
 rate_type varchar(8),    
 date_applied int,    
 rate float    
 )    
    
 CREATE TABLE #rates    
 (    
 from_currency varchar(8),    
 to_currency varchar(8),    
 rate_type varchar(8),    
 date_applied int,    
 rate float    
 )    
    
 INSERT #rates    
 (    
 from_currency, to_currency, rate_type,    
 date_applied, rate    
 )    
 SELECT DISTINCT nat_cur_code, @home_currency, rate_type_home,    
 date_applied, 0.0    
 FROM #arinpchg    
 WHERE ( LTRIM(nat_cur_code) IS NOT NULL AND LTRIM(nat_cur_code) != ' ' )    
 AND ( LTRIM(rate_type_home) IS NOT NULL AND LTRIM(rate_type_home) != ' ' )    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 310, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 IF (@debug_level > 0 )    
 BEGIN    
 select 'dumping #rates...'    
 select 'from_currency = ' + from_currency +    
 'to_currency = ' + to_currency +    
 'rate_type = ' + rate_type +    
 'date_applied = ' + STR(date_applied, 8) +    
 'rate = ' + STR(rate, 10, 2)    
 from #rates    
 END    
    
 INSERT #rates_oper    
 (    
 from_currency, to_currency, rate_type,    
 date_applied, rate    
 )    
 SELECT DISTINCT nat_cur_code, @oper_currency, rate_type_oper,    
 date_applied, 0.0    
 FROM #arinpchg    
 WHERE ( LTRIM(nat_cur_code) IS NOT NULL AND LTRIM(nat_cur_code) != ' ' )    
 AND ( LTRIM(rate_type_oper) IS NOT NULL AND LTRIM(rate_type_oper) != ' ' )    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 337, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 IF (@debug_level > 0 )    
 BEGIN    
 select 'dumping #rates_oper...'    
 select 'from_currency = ' + from_currency +    
 'to_currency = ' + to_currency +    
 'rate_type = ' + rate_type +    
 'date_applied = ' + STR(date_applied, 8) +    
 'rate = ' + STR(rate, 10, 2)    
 from #rates_oper    
 END    
    
 DELETE #rates_oper    
 FROM #rates    
 WHERE #rates.date_applied = #rates_oper.date_applied    
 AND #rates.from_currency = #rates_oper.from_currency    
 AND #rates.to_currency = #rates_oper.to_currency    
 AND #rates.rate_type = #rates_oper.rate_type    
    
 INSERT #rates    
 (    
 from_currency, to_currency, rate_type,    
 date_applied, rate    
 )    
 SELECT    
 from_currency, to_currency, rate_type,    
 date_applied, rate    
 FROM #rates_oper    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 370, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 DROP TABLE #rates_oper    
    
 EXEC CVO_Control..mcrates_sp    
    
 IF (@debug_level > 0 )    
 BEGIN    
 select 'dumping #rates...after mcrates_sp'    
 select 'from_currency = ' + from_currency +    
 'to_currency = ' + to_currency +    
 'rate_type = ' + rate_type +    
 'date_applied = ' + STR(date_applied, 8) +    
 'rate = ' + STR(rate, 10, 2)    
 from #rates    
 END    
    
 UPDATE #arinpchg    
 SET rate_home = ( CASE WHEN SIGN(rate_home) = 0    
 THEN rate    
 ELSE rate_home END)    
 FROM #rates    
 WHERE from_currency = nat_cur_code    
 AND rate_type = rate_type_home    
 AND #rates.date_applied = #arinpchg.date_applied    
 AND to_currency = @home_currency    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 400, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 UPDATE #arinpchg    
 SET rate_oper = ( CASE WHEN SIGN(rate_oper) = 0    
 THEN rate    
 ELSE rate_oper END)    
 FROM #rates    
 WHERE from_currency = nat_cur_code    
 AND rate_type = rate_type_oper    
 AND #rates.date_applied = #arinpchg.date_applied    
 AND to_currency = @oper_currency    
    
 IF( @@error != 0 )    
 BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 425, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
    
 IF ( @debug_level > 0 )    
 BEGIN    
 SELECT 'dumping #arinpchg...'    
 SELECT * FROM #arinpchg    
 END    
    
 EXEC @result = bows_ARINImportsetDetDefaults_SP @debug_level    
 IF( @@error != 0 ) BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 440, 5 ) + ' -- EXIT: '    
 RETURN 34563    
 END    
 IF ( @result != 0 )    
 BEGIN    
 IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 445, 5 ) + ' -- MSG: ' + 'ARINImportDetailDefaults_SP failed!'    
 RETURN @result    
 END    
    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinisd.sp' + ', line ' + STR( 451, 5 ) + ' -- EXIT: '    
 RETURN 0    
END 
GO
GRANT EXECUTE ON  [dbo].[bows_ARINImportSetDefaults_SP] TO [public]
GO
