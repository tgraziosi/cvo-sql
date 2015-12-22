SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
    
CREATE PROCEDURE [dbo].[bows_ARINImportsetDetDefaults_SP]  @debug_level smallint = 0    
    
AS    
BEGIN    
 DECLARE @result  int    
    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinidd.sp' + ', line ' + STR( 20, 5 ) + ' -- ENTRY: '    
    
 UPDATE #arinpcdt    
 SET iv_post_flag = 0,    
  location_code = ISNULL(#arinpcdt.location_code,' '),    
  item_code = ISNULL(#arinpcdt.item_code,' '),    
  line_desc = ISNULL(#arinpcdt.line_desc,' '),    
  qty_shipped = CASE WHEN (ISNULL(qty_shipped,0)=0) AND (trx_type=2031) THEN 1 ELSE ISNULL(qty_shipped,0) END,    
  qty_ordered = ISNULL(#arinpcdt.qty_ordered,ISNULL(#arinpcdt.qty_shipped,1)),    
  unit_code = ISNULL(#arinpcdt.unit_code,' '),    
  unit_cost = ISNULL(#arinpcdt.unit_cost,0.0),    
  weight = ISNULL(#arinpcdt.weight,0.0),    
  serial_id = ISNULL(#arinpcdt.serial_id,1),    
  disc_prc_flag = ISNULL(disc_prc_flag,0),    
  discount_amt = ISNULL(discount_amt,0.0),    
  discount_prc = ISNULL(discount_prc, 0.0),    
  oe_orig_flag = ISNULL(oe_orig_flag,0),    
  qty_returned = CASE WHEN (ISNULL(qty_returned,0)=0) AND (trx_type=2032) THEN 1 ELSE ISNULL(qty_returned,0) END    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinidd.sp' + ', line ' + STR( 43, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 UPDATE #arinpcdt    
 SET extended_price = CASE trx_type    
   WHEN 2032 THEN unit_price * qty_returned - discount_amt    
   WHEN 2031 THEN unit_price * qty_shipped - discount_amt    
   ELSE extended_price    
   END    
 WHERE extended_price IS NULL    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinidd.sp' + ', line ' + STR( 60, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 UPDATE d    
 SET tax_code = CASE ISNULL(d.tax_code,'') WHEN '' THEN h.tax_code ELSE d.tax_code END,    
  d.date_entered = h.date_entered    
 FROM #arinpchg h, #arinpcdt d    
 WHERE h.trx_ctrl_num = d.trx_ctrl_num    
 IF( @@error != 0 ) BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinidd.sp' + ', line ' + STR( 75, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 UPDATE #arinpcdt    
 SET gl_rev_acct = araccts.rev_acct_code    
 FROM araccts, #arinpchg    
 WHERE #arinpchg.posting_code = araccts.posting_code    
  AND ISNULL(gl_rev_acct,'')=''    
 IF( @@error != 0 ) BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinidd.sp' + ', line ' + STR( 88, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 UPDATE d    
  SET  d.trx_ctrl_num = h.trx_ctrl_num    
 FROM #arinpcom d, #arinpchg h    
 WHERE  d.trx_ctrl_num = h.link    
 IF( @@error != 0 ) BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinidd.sp' + ', line ' + STR( 98, 5 ) + ' -- EXIT: '    
  RETURN 34563    
 END    
    
 UPDATE #arinpcom    
 SET exclusive_flag = ISNULL(#arinpcom.exclusive_flag, 0),    
  split_flag = ISNULL(#arinpcom.split_flag, 0),    
  percent_flag = ISNULL(#arinpcom.percent_flag, 0),    
  mark_flag = 0    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinidd.sp' + ', line ' + STR( 112, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 UPDATE c    
 SET c.mark_flag = 1    
 FROM #arinpcom c, arsalesp p    
 WHERE c.salesperson_code = p.salesperson_code    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinidd.sp' + ', line ' + STR( 123, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 INSERT #ewerror(    
  module_id, err_code,info1,info2,infoint,infofloat,    
  flag1,trx_ctrl_num,sequence_id, source_ctrl_num,extra)    
 SELECT  null, -1,'Invalid commission salesperson',c.salesperson_code,null, null,    
  null, c.trx_ctrl_num ,null,null,null    
 FROM #arinpcom c    
 WHERE c.mark_flag <> 1    
 IF ( @@error != 0 ) BEGIN    
  RETURN 34563    
 END    
    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinidd.sp' + ', line ' + STR( 139, 5 ) + ' -- EXIT: '    
 RETURN 0    
END 
GO
GRANT EXECUTE ON  [dbo].[bows_ARINImportsetDetDefaults_SP] TO [public]
GO
