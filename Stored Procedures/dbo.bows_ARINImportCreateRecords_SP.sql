SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
    
CREATE PROCEDURE [dbo].[bows_ARINImportCreateRecords_SP] @process_ctrl_num varchar(16),    
       @user_id  smallint,    
       @debug_level  smallint = 0    
    
AS    
 DECLARE    
  @date_entered  int,    
  @result  int    
    
BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinicr.sp' + ', line ' + STR( 33, 5 ) + ' -- ENTRY: '    
    
 UPDATE d    
 SET extended_price  = (SIGN(d.extended_price) * ROUND(ABS(d.extended_price) + 0.0000001, ISNULL(g.curr_precision,2))),    
  discount_amt  = (SIGN(d.discount_amt) * ROUND(ABS(d.discount_amt) + 0.0000001, ISNULL(g.curr_precision,2))),    
  unit_cost = (SIGN(d.unit_cost) * ROUND(ABS(d.unit_cost) + 0.0000001, ISNULL(g.curr_precision,2))),    
  weight  = (SIGN(d.weight) * ROUND(ABS(d.weight) + 0.0000001, ISNULL(g.curr_precision,2)))    
 FROM glcurr_vw g, #arinpchg a, #arinpcdt d    
 WHERE a.nat_cur_code = g.currency_code    
 AND d.trx_ctrl_num = a.trx_ctrl_num    
 IF ( @@error != 0 )    
 BEGIN    
  RETURN 34563    
 END    
    
 CREATE TABLE #cdt    
 (    
  trx_ctrl_num varchar(16),    
  sequence_id int,    
  price  float,    
  discount float,    
  cost  float,    
  weight  float    
 )    
    
 INSERT #cdt    
 SELECT trx_ctrl_num,    
  MAX(sequence_id),    
  SUM(extended_price),    
  SUM(discount_amt),    
  SUM(unit_cost),    
  SUM(weight)    
 FROM #arinpcdt    
 GROUP BY trx_ctrl_num    
    
 IF ( @@error != 0 )    
 BEGIN    
  RETURN 34563    
 END    
    
 UPDATE c    
 SET price   = (SIGN(c.price) * ROUND(ABS(c.price) + 0.0000001, ISNULL(g.curr_precision,2))),    
  discount  = (SIGN(c.discount) * ROUND(ABS(c.discount) + 0.0000001, ISNULL(g.curr_precision,2))),    
  cost   = (SIGN(c.cost) * ROUND(ABS(c.cost) + 0.0000001, ISNULL(g.curr_precision,2)))    
 FROM #cdt c, glcurr_vw g, #arinpchg a    
 WHERE a.nat_cur_code = g.currency_code    
 AND c.trx_ctrl_num = a.trx_ctrl_num    
 IF ( @@error != 0 )    
 BEGIN    
  RETURN 34563    
 END    
    
 UPDATE a    
 SET next_serial_id  = cdt.sequence_id,    
  amt_discount  = cdt.discount,    
  amt_gross  = cdt.price + cdt.discount,    
  amt_net  = cdt.price,    
  amt_paid  = 0.0,    
  amt_due  = CASE trx_type    
     WHEN 2031 THEN cdt.price    
     ELSE 0.0    
     END,    
  amt_cost  = cdt.cost,    
  amt_profit  = cdt.price - cdt.cost,    
  total_weight  = cdt.weight,    
  amt_tax  = 0.0,    
  amt_tax_included = 0.0    
 FROM #cdt cdt, #arinpchg a    
 WHERE cdt.trx_ctrl_num = a.trx_ctrl_num    
 IF ( @@error != 0 )    
 BEGIN    
  RETURN 34563    
 END    
    
 UPDATE #arinpchg    
 SET amt_net = amt_net + amt_freight,    
  amt_due = amt_due + amt_freight    
 IF ( @@error != 0 )    
 BEGIN    
  RETURN 34563    
 END    
    
 EXEC @result = bows_arintax_sp @debug_level    
 IF (ISNULL(@result,-1)<>0)    
  RETURN -1    
    
 SELECT  a.trx_ctrl_num trx_ctrl_num, SUM(a.amt_final_tax) amt_tax, SUM(t.tax_included_flag * a.amt_final_tax ) amt_tax_included    
 INTO #inptax    
 FROM #arinptax a, artxtype t    
 WHERE a.tax_type_code = t.tax_type_code    
 GROUP BY a.trx_ctrl_num    
    
 IF ( @@error != 0 )    
 BEGIN    
  RETURN 34563    
 END    
    
 UPDATE #arinpchg    
 SET amt_gross  = amt_gross - tax.amt_tax_included,    
  amt_net  = amt_net - tax.amt_tax_included + tax.amt_tax,    
  amt_due  = CASE trx_type    
     WHEN 2031 THEN amt_due - tax.amt_tax_included + tax.amt_tax    
     ELSE 0.0    
     END,    
  amt_tax  = tax.amt_tax,    
  amt_tax_included = tax.amt_tax_included    
 FROM #cdt cdt, #inptax tax    
 WHERE #arinpchg.trx_ctrl_num = cdt.trx_ctrl_num    
 AND #arinpchg.trx_ctrl_num = tax.trx_ctrl_num    
    
 IF ( @@error != 0 )    
 BEGIN    
  RETURN 34563    
 END    
    
 DROP TABLE #cdt    
 DROP TABLE #inptax    
    
 IF NOT EXISTS (SELECT trx_ctrl_num FROM #arinpage )    
 BEGIN    
  INSERT #arinpage    
  (    
   trx_ctrl_num,   sequence_id,   doc_ctrl_num,    
   apply_to_num,   apply_trx_type,  trx_type,    
   date_applied,   date_due,   date_aging,    
   customer_code,  salesperson_code,  territory_code,    
   price_code,   amt_due    
  )    
  SELECT hdr.trx_ctrl_num,  1,    hdr.doc_ctrl_num,    
   hdr.apply_to_num,  hdr.apply_trx_type,  hdr.trx_type,    
   hdr.date_applied,  hdr.date_due,   hdr.date_aging,    
   hdr.customer_code,  hdr.salesperson_code, hdr.territory_code,    
   hdr.price_code,  hdr.amt_net    
  FROM #arinpchg hdr    
  WHERE hdr.trx_type = 2031    
    
  IF ( @@error != 0 )    
  BEGIN    
   RETURN 34563    
  END    
 END    
     
 IF ( @debug_level > 0 )    
 BEGIN    
  SELECT 'Dumping #arinpchg...'    
  SELECT 'trx_ctrl_num = ' + trx_ctrl_num +    
   'doc_ctrl_num = ' + doc_ctrl_num +    
   'amt_gross = ' + STR(amt_gross, 10, 2) +    
   'amt_net = ' + STR(amt_net, 10, 2 ) +    
   'amt_tax = ' + STR(amt_tax, 10, 2 ) +    
   'amt_discount = ' + STR(amt_discount, 10, 2 ) +    
   'amt_cost = ' + STR(amt_cost, 10, 2 ) +    
   'amt_profit = ' + STR(amt_profit, 10, 2 ) +    
   'amt_freight = ' + STR(amt_freight, 10, 2)    
  FROM #arinpchg    
  SELECT 'Dumping #arinpcdt...'    
  SELECT 'trx_ctrl_num = ' + trx_ctrl_num +    
   'sequence_id = ' + STR(sequence_id, 5) +    
   'extended_price = ' + STR(extended_price, 10, 2) +    
   'discount_amt = ' + STR(discount_amt, 10, 2 )    
  FROM #arinpcdt    
 END    
    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinicr.sp' + ', line ' + STR( 208, 5 ) + ' -- EXIT: '    
 RETURN 0    
END 
GO
GRANT EXECUTE ON  [dbo].[bows_ARINImportCreateRecords_SP] TO [public]
GO
