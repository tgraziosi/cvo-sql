SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[ARINImportSetDefaults_SP] @process_ctrl_num varchar(16),
            	 @debug_level smallint = 0,
 		@mode	smallint = 0



                
AS
BEGIN

 DECLARE @home_currency varchar(8),
 @oper_currency varchar(8),
 @result int,
 @date_entered int,
 @num int,
 @trx_ctrl_num varchar(16),
 @doc_ctrl_num varchar(16),
 @next_control_num varchar(16),
 @next_number int, 
 @trx_type int,
 @next_number_type int
      
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 28, 5 ) + ' -- ENTRY: '
 
  IF (@debug_level > 0 ) 
  BEGIN
    SELECT 'Dumping #arinpchg...'
    SELECT  'order_ctrl_num = |' + order_ctrl_num + '|' +
      'hold_desc = ' + hold_desc +
      'date_aging = ' + STR(date_aging, 8) +
      'rate_type_home = ' + rate_type_home +
      'ddid = ' + ddid +
      'rate_home = ' + STR(rate_home, 10, 2) +
      'rate_oper = ' + STR(rate_oper, 10, 2) +
      'sign(rate_oper)=' + STR(sign(rate_oper), 3)
    FROM  #arinpchg
  END
  
  SELECT  @date_entered = datediff(dd,'1/1/80',getdate())+722815

  SELECT  @home_currency = home_currency,
    @oper_currency = oper_currency
  FROM  glco

  



  UPDATE  #arinpchg
  SET 
    trx_type = CASE @mode WHEN 1 THEN trx_type ELSE 2031 END,
    printed_flag = 0,
    doc_ctrl_num = CASE @mode WHEN 1 THEN doc_ctrl_num ELSE ' ' END,
    source_trx_ctrl_num = ' ',
    source_trx_type = 0,
    recurring_flag = CASE @mode WHEN 1 THEN recurring_flag ELSE 0 END,
    recurring_code = ' ',
    apply_to_num = CASE @mode WHEN 1 THEN apply_to_num ELSE ' ' END,
    apply_trx_type = CASE @mode WHEN 1 THEN apply_trx_type ELSE 0 END,
    


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
    amt_freight = ISNULL(amt_freight, 0.0 ),
    hold_flag = ISNULL( hold_flag, 0 ),
    hold_desc = ISNULL( hold_desc, ' '),
    doc_desc = ISNULL(doc_desc,' '),
    




    salesperson_code = (CASE LTRIM(salesperson_code)
          WHEN ' ' THEN NULL
          ELSE salesperson_code END),
    terms_code = (CASE LTRIM(terms_code)
          WHEN ' ' THEN NULL
          ELSE terms_code END),
    territory_code = (CASE LTRIM(territory_code)
          WHEN ' ' THEN NULL
          ELSE territory_code END),
    fob_code = (CASE LTRIM(fob_code)
          WHEN ' ' THEN NULL
          ELSE fob_code END),
    freight_code = (CASE LTRIM(freight_code)
          WHEN ' ' THEN NULL
          ELSE freight_code END),
    dest_zone_code = (CASE LTRIM(dest_zone_code)
          WHEN ' ' THEN NULL
          ELSE dest_zone_code END),
    posting_code = (CASE LTRIM(posting_code)
          WHEN ' ' THEN NULL
          ELSE posting_code END),
    tax_code = (CASE LTRIM(tax_code)
          WHEN ' ' THEN NULL
          ELSE tax_code END),
    attention_phone = (CASE LTRIM(attention_phone)
          WHEN ' ' THEN NULL
          ELSE attention_phone END),
    attention_name = (CASE LTRIM(attention_name)
          WHEN ' ' THEN NULL
          ELSE attention_name END),
    nat_cur_code = (CASE LTRIM(nat_cur_code)
          WHEN ' ' THEN NULL
          ELSE nat_cur_code END),
    rate_type_home = (CASE LTRIM(rate_type_home)
          WHEN ' ' THEN NULL
          ELSE rate_type_home END),
    rate_type_oper = (CASE LTRIM(rate_type_oper)
          WHEN ' ' THEN NULL
          ELSE rate_type_oper END)
  IF( @@error != 0 )
  BEGIN
 	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 131, 5 ) + ' -- EXIT: '
	 RETURN 34563
  END
    

  

  



  SELECT @next_number_type=CASE  
        WHEN (@mode=1) AND (trx_type=2031) THEN 2000
        WHEN (@mode=1) AND (trx_type=2032) THEN 2020
        ELSE 2000
        END  
  FROM #arinpchg

  EXEC @result = ARGetNextControl_SP  @next_number_type,
            @next_control_num OUTPUT,
            @next_number OUTPUT


  UPDATE  #arinpchg
  SET trx_ctrl_num = @next_control_num
  IF( @@error != 0 )
  BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 147, 5 ) + ' -- EXIT: '
 RETURN 34563
  END

--  EFO 7.3 SCRs 26064 - 30721 Send CCA info from FO to BO 	Acastaneda 04/28/2003
  UPDATE  #arinptmp
  SET trx_ctrl_num = @next_control_num,
	doc_ctrl_num = @next_control_num
  IF( @@error != 0 )
  BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 147, 5 ) + ' -- EXIT: '
 RETURN 34563
  END

  UPDATE  #arinpcdt
  SET trx_ctrl_num = @next_control_num,
      trx_type =  CASE @mode WHEN 1 THEN trx_type ELSE 2031 END
  IF( @@error != 0 )
  BEGIN
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 156, 5 ) + ' -- EXIT: '
 RETURN 34563
  END
  
  


  
  UPDATE  #arinpchg
  SET ship_to_code = ISNULL(#arinpchg.ship_to_code, cust.ship_to_code)
  FROM  armaster cust
  WHERE #arinpchg.customer_code = cust.customer_code
  AND cust.address_type = 0
  IF( @@error != 0 )
  BEGIN
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 171, 5 ) + ' -- EXIT: '
 RETURN 34563
  END
  
  


  UPDATE  #arinpchg
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
  FROM  armaster ship_to
  WHERE #arinpchg.customer_code = ship_to.customer_code
  AND #arinpchg.ship_to_code = ship_to.ship_to_code
  AND ship_to.address_type = 1
  IF( @@error != 0 )
  BEGIN
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 199, 5 ) + ' -- EXIT: '
 RETURN 34563
  END
  
  



  UPDATE  #arinpchg
  SET ship_to_addr1 = ship_to.addr1,
    ship_to_addr2 = ship_to.addr2,
    ship_to_addr3 = ship_to.addr3,
    ship_to_addr4 = ship_to.addr4,
    ship_to_addr5 = ship_to.addr5,
    ship_to_addr6 = ship_to.addr6
  FROM  armaster ship_to
 WHERE 
( LTRIM(ship_to.addr1+ship_to.addr2+ship_to.addr3+ship_to.addr4+ ship_to.addr5+ship_to.addr6) IS NULL OR LTRIM(ship_to.addr1+ship_to.addr2+ship_to.addr3+ship_to.addr4+ ship_to.addr5+ship_to.addr6) = ' ' )
 AND #arinpchg.customer_code = ship_to.customer_code
 AND #arinpchg.ship_to_code = ship_to.ship_to_code
 AND ship_to.address_type = 1
  IF( @@error != 0 )
  BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 222, 5 ) + ' -- EXIT: '
 RETURN 34563
  END
  
  


  UPDATE  #arinpchg
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
    ship_to_addr6 = ISNULL(#arinpchg.ship_to_addr6, ' ')
  FROM  armaster cust
  WHERE #arinpchg.customer_code = cust.customer_code
  AND cust.address_type = 0
  IF( @@error != 0 )
  BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 258, 5 ) + ' -- EXIT: '
 RETURN 34563
  END
  

  


  IF @mode=1 BEGIN
 	UPDATE #arinpchg
 	SET location_code = ''
 	WHERE #arinpchg.location_code IS NULL
  	IF( @@error != 0 )
  	BEGIN
 		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 258, 5 ) + ' -- EXIT: '
		RETURN 34563
  	END
  END


  



  UPDATE  #arinpchg
  SET customer_addr1 = ISNULL(cust.addr1, ' '),
    customer_addr2 = ISNULL(cust.addr2, ' '),
    customer_addr3 = ISNULL(cust.addr3, ' '),
    customer_addr4 = ISNULL(cust.addr4, ' '),
    customer_addr5 = ISNULL(cust.addr5, ' '),
    customer_addr6 = ISNULL(cust.addr6, ' ')
  FROM  armaster cust
 WHERE 




( LTRIM(ISNULL(customer_addr1, ' ')+ ISNULL(customer_addr2, ' ')+ ISNULL(customer_addr3, ' ')+ ISNULL(customer_addr4, ' ')+ ISNULL(customer_addr5, ' ')+ ISNULL(customer_addr6, ' ')) IS NULL OR LTRIM(ISNULL(customer_addr1, ' ')+ ISNULL(customer_addr2, ' ')+ ISNULL(customer_addr3, ' ')+ ISNULL(customer_addr4, ' ')+ ISNULL(customer_addr5, ' ')+ ISNULL(customer_addr6, ' ')) = ' ' )
 AND #arinpchg.customer_code = cust.customer_code
 AND cust.address_type = 0
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 284, 5 ) + ' -- EXIT: '
 RETURN 34563
 END
  
  



  UPDATE  #arinpchg
  SET customer_addr1 = ISNULL(customer_addr1, ' '),
    customer_addr2 = ISNULL(customer_addr2, ' '),
    customer_addr3 = ISNULL(customer_addr3, ' '),
    customer_addr4 = ISNULL(customer_addr4, ' '),
    customer_addr5 = ISNULL(customer_addr5, ' '),
    customer_addr6 = ISNULL(customer_addr6, ' ')
  
  IF( @@error != 0 )
  BEGIN
	 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 302, 5 ) + ' -- EXIT: '
	 RETURN 34563
  END
  
  


CREATE TABLE #arterm
(
	date_doc		int,
	terms_code		varchar(8),
	date_due		int,
	date_discount		int
)
  
  INSERT #arterm (date_doc, terms_code, date_due, date_discount)
  SELECT date_doc, terms_code, 0, 0
  FROM  #arinpchg
  
  EXEC @result = ARGetTermInfo_SP
  
  UPDATE #arinpchg
  SET date_due = #arterm.date_due
  FROM  #arterm
  
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
    from_currency,    to_currency,    rate_type,
    date_applied,     rate
  )
  SELECT  DISTINCT nat_cur_code,  @home_currency, rate_type_home,
    date_applied,     0.0
  FROM  #arinpchg
 WHERE ( LTRIM(nat_cur_code) IS NOT NULL AND LTRIM(nat_cur_code) != ' ' )
 AND ( LTRIM(rate_type_home) IS NOT NULL AND LTRIM(rate_type_home) != ' ' )
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 356, 5 ) + ' -- EXIT: '
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
    from  #rates
  END
  
  INSERT #rates_oper
  (
    from_currency,    to_currency,    rate_type,
    date_applied,     rate
  )
  SELECT DISTINCT nat_cur_code, @oper_currency, rate_type_oper,
    date_applied,     0.0
  FROM  #arinpchg
 WHERE ( LTRIM(nat_cur_code) IS NOT NULL AND LTRIM(nat_cur_code) != ' ' )
 AND ( LTRIM(rate_type_oper) IS NOT NULL AND LTRIM(rate_type_oper) != ' ' )
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 383, 5 ) + ' -- EXIT: '
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
    from  #rates_oper
  END
  
  DELETE #rates_oper
  FROM  #rates
  WHERE #rates.date_applied = #rates_oper.date_applied
  AND #rates.from_currency = #rates_oper.from_currency
  AND #rates.to_currency = #rates_oper.to_currency
  AND #rates.rate_type = #rates_oper.rate_type

  INSERT #rates
  (
    from_currency,    to_currency,    rate_type,
    date_applied,     rate
  )
  SELECT  
    from_currency,    to_currency,    rate_type,
    date_applied,     rate
  FROM  #rates_oper
  IF( @@error != 0 )
  BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 416, 5 ) + ' -- EXIT: '
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
    from  #rates
  END
  
  UPDATE  #arinpchg
  SET rate_home = ( CASE WHEN SIGN(rate_home) = 0 
          THEN rate
          ELSE rate_home END)
  FROM  #rates
  WHERE from_currency = nat_cur_code
  AND rate_type = rate_type_home
  AND #rates.date_applied = #arinpchg.date_applied
  AND to_currency = @home_currency
  IF( @@error != 0 )
  BEGIN
	 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 446, 5 ) + ' -- EXIT: '
	 RETURN 34563
  END
  
  UPDATE  #arinpchg
  SET rate_oper = ( CASE WHEN SIGN(rate_oper) = 0 
          THEN rate
          ELSE rate_oper END)
  FROM  #rates
  WHERE from_currency = nat_cur_code
  AND rate_type = rate_type_oper
  AND #rates.date_applied = #arinpchg.date_applied
  AND to_currency = @oper_currency
  
  








  IF( @@error != 0 )
  BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 471, 5 ) + ' -- EXIT: '
 RETURN 34563
  END
  
  IF ( @debug_level > 0 )
  BEGIN
    SELECT 'dumping #arinpchg...'
    SELECT  'trx_ctrl_num = ' + trx_ctrl_num +
      'customer_code = ' + customer_code +
      'order_ctrl_num = ' + order_ctrl_num +
      'customer_addr1 =:' + customer_addr1 + ':' +
      'tax_code = ' + tax_code +
      'rate_type_home = ' + rate_type_home +
      'rate_oper = ' + STR(rate_oper, 10, 2) +
      'ddid = ' + ddid
    FROM  #arinpchg
  END
                        

  

                          
  
  EXEC @result = ARINImportsetDetDefaults_SP @debug_level, @mode=@mode
  IF ( @result != 0 )
  BEGIN
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 495, 5 ) + ' -- MSG: ' + 'ARINImportDetailDefaults_SP failed!'
     RETURN @result
  END
  
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arinisd.sp' + ', line ' + STR( 499, 5 ) + ' -- EXIT: '
 RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[ARINImportSetDefaults_SP] TO [public]
GO
