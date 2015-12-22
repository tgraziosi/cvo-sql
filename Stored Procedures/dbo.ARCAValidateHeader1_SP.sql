SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARCAValidateHeader1_SP] @error_level smallint, 
 @debug_level smallint = 0
AS

DECLARE 
 @result smallint,
 @e_level_1 smallint,
 @e_level_2 smallint,
 @e_level_3 smallint


BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 37, 5 ) + " -- ENTRY: "

 
 
 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20600) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 69, 5 ) + " -- MSG: " + "Validate user id exists"

 UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM ewusers_vw ew
 WHERE #arvalpyt.user_id = ew.user_id
 

 INSERT #ewerror
 SELECT 2000,
 20600,
 "",
 "",
 user_id,
 0.0,
 2,
 trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0
 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20601) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 101, 5 ) + " -- MSG: " + "Validate customer code exists"

 UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM arcust
 WHERE #arvalpyt.customer_code = arcust.customer_code
 

 INSERT #ewerror
 SELECT 2000,
 20601,
 customer_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0
 END

 
 SELECT @e_level_1 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20611
 SELECT @e_level_2 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20612
 SELECT @e_level_3 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20613

 IF (@e_level_1 + @e_level_2 + @e_level_3) > 0 
 BEGIN
 CREATE TABLE #adj_payments
 (
 doc_ctrl_num varchar(16),
 customer_code varchar(8),
 amount float NULL,
 currency_code varchar(8) NULL,
 exists_flag smallint
 )

 INSERT #adj_payments (doc_ctrl_num, customer_code, exists_flag)
 SELECT DISTINCT doc_ctrl_num,
 customer_code,
 0
 FROM #arvalpyt

 UPDATE #adj_payments
 SET amount = trx.amt_net,
 currency_code = trx.nat_cur_code,
 exists_flag = 1
 FROM artrx trx
 WHERE #adj_payments.doc_ctrl_num = trx.doc_ctrl_num
 AND #adj_payments.customer_code = trx.customer_code
 AND trx.trx_type = 2111
 AND trx.payment_type IN (1,3)
 AND trx.void_flag = 0
 END
 
 IF @e_level_1 = 1
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 173, 5 ) + " -- MSG: " + "Validate payment being adjusted exists"

 INSERT #ewerror
 SELECT 2000,
 20611,
 pyt.doc_ctrl_num + " -- " + pyt.customer_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt pyt, #adj_payments adj 
 WHERE adj.exists_flag = 0
 AND pyt.customer_code = adj.customer_code
 AND pyt.doc_ctrl_num = adj.doc_ctrl_num
 
 
 IF( @@rowcount > 0 )
 BEGIN
 SELECT @e_level_2 = 0,
 @e_level_3 = 0
 END
 END

 
 IF @e_level_2 = 1
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 208, 5 ) + " -- MSG: " + "Validate the adjustment and payment header amount are equal"

 UPDATE #arvalpyt
 SET temp_flag = 0

 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM #adj_payments pyt, glcurr_vw gl
 WHERE #arvalpyt.customer_code = pyt.customer_code
 AND #arvalpyt.doc_ctrl_num = pyt.doc_ctrl_num
 AND (ABS(((SIGN(#arvalpyt.amt_payment) * ROUND(ABS(#arvalpyt.amt_payment) + 0.0000001, 6)))-((SIGN(pyt.amount) * ROUND(ABS(pyt.amount) + 0.0000001, 6)))) < 0.0000001)

 INSERT #ewerror
 SELECT 2000,
 20612,
 doc_ctrl_num + " -- " + customer_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0
 END

 
 IF @e_level_3 = 1
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 241, 5 ) + " -- MSG: " + "Validate the adjustment and payment currency are same"

 UPDATE #arvalpyt
 SET temp_flag = 0

 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM #adj_payments pyt
 WHERE #arvalpyt.customer_code = pyt.customer_code
 AND #arvalpyt.doc_ctrl_num = pyt.doc_ctrl_num
 AND #arvalpyt.nat_cur_code = pyt.currency_code

 INSERT #ewerror
 SELECT 2000,
 20613,
 doc_ctrl_num + " -- " + customer_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0
 END

 IF (@e_level_1 + @e_level_2 + @e_level_3) > 0 
 BEGIN
 DROP TABLE #adj_payments
 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20614) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 279, 5 ) + " -- MSG: " + "Validate the home rate type exists"

 CREATE TABLE #duplicate
 (
 customer_code varchar(8),
 doc_ctrl_num varchar(16),
 total smallint 
 )

 INSERT #duplicate
 
 SELECT customer_code, doc_ctrl_num, COUNT(*)
 FROM #arvalpyt
 GROUP BY doc_ctrl_num, customer_code

 INSERT #ewerror
 SELECT 2000,
 20614,
 pyt.doc_ctrl_num + " -- " + pyt.customer_code,
 "",
 0,
 0.0,
 1,
 pyt.trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt pyt, #duplicate dup
 WHERE pyt.doc_ctrl_num = dup.doc_ctrl_num
 AND pyt.customer_code = dup.customer_code
 
 AND dup.total > 1

 DROP TABLE #duplicate
 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20620) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 320, 5 ) + " -- MSG: " + "Validate the home rate type exists"

 UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM glrtype_vw gl
 WHERE #arvalpyt.rate_type_home = gl.rate_type
 

 INSERT #ewerror
 SELECT 2000,
 20620,
 rate_type_home,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0
 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20621) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 352, 5 ) + " -- MSG: " + "Validate the operational rate type exists"

 UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM glrtype_vw gl
 WHERE #arvalpyt.rate_type_oper = gl.rate_type
 

 INSERT #ewerror
 SELECT 2000,
 20621,
 rate_type_oper,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0
 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20623) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 384, 5 ) + " -- MSG: " + "Validate the home rate is not 0.0"

 INSERT #ewerror
 SELECT 2000,
 20623,
 rate_type_home,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt 
 WHERE (ABS((rate_home)-(0.0)) < 0.0000001)
 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20622) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 407, 5 ) + " -- MSG: " + "Validate the operational rate is not 0.0"

 INSERT #ewerror
 SELECT 2000,
 20622,
 rate_type_oper,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt 
 WHERE (ABS((rate_oper)-(0.0)) < 0.0000001)
 END

 
 IF (SELECT e_level FROM aredterr WHERE e_code = 20624) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 430, 5 ) + " -- MSG: " + "Validate the currency code exists"

 UPDATE #arvalpyt
 SET temp_flag = 0
 
 UPDATE #arvalpyt
 SET temp_flag = 1
 FROM glcurr_vw gl
 WHERE #arvalpyt.nat_cur_code = gl.currency_code
 

 INSERT #ewerror
 SELECT 2000,
 20624,
 nat_cur_code,
 "",
 0,
 0.0,
 1,
 trx_ctrl_num,
 0,
 "",
 0
 FROM #arvalpyt 
 WHERE temp_flag = 0
 END


 RETURN 0
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavh1.sp" + ", line " + STR( 459, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARCAValidateHeader1_SP] TO [public]
GO
