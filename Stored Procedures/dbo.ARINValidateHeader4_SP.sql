SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[ARINValidateHeader4_SP] @error_level smallint,
 @trx_type smallint,
 @debug_level smallint = 0,
 @rec_inv smallint
AS

DECLARE 
 @result smallint,
 @min_period_start_date int,
 @max_period_end_date int
 

BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 50, 5 ) + " -- ENTRY: "

 SELECT @min_period_start_date = min(period_start_date),
 @max_period_end_date = max(period_end_date)
 FROM glprd
 
 
 IF ( ( SELECT e_level FROM aredterr WHERE e_code = 20031 ) >= @error_level ) AND @rec_inv = 0
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 61, 5 ) + " -- MSG: " + "Check if applied date is for a future period"
 
 
 INSERT #ewerror
 SELECT 2000,
 20031,
 "",
 "",
 date_applied,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg a, arco b
 WHERE a.date_applied > b.period_end_date
 END

 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20032 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 87, 5 ) + " -- MSG: " + "Check if apply date is to a prior period"
 
 
 INSERT #ewerror
 SELECT 2000,
 20032,
 "",
 "",
 a.date_applied,
 0.0,
 3,
 a.trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg a, glprd b, arco c
 WHERE a.date_applied < b.period_start_date
 AND b.period_end_date = c.period_end_date
 END

 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20033 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 114, 5 ) + " -- MSG: " + "Check if apply date does not fall within any period defined in GL"
 
 
 INSERT #ewerror
 SELECT 2000,
 20033,
 "",
 "",
 date_applied,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg 
 WHERE date_applied < @min_period_start_date
 OR date_applied > @max_period_end_date
 END


 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20034 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 142, 5 ) + " -- MSG: " + "Check if the apply date is not in the range specified on the Name and Options form"
 
 
 INSERT #ewerror
 SELECT 2000,
 20034,
 "",
 "",
 date_applied,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg a, arco b
 WHERE ABS(a.date_applied - a.date_entered) > b.date_range_verify
 END


 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20035 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 169, 5 ) + " -- MSG: " + "Validate that if the apply date falls within any period defined in GL"
 
 
 INSERT #ewerror
 SELECT 2000,
 20035,
 "",
 "",
 date_aging,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg 
 WHERE date_applied < @min_period_start_date
 OR date_applied > @max_period_end_date
 END

 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20036 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 196, 5 ) + " -- MSG: " + "Validate that the aging date is not the same as the due date"
 
 
 INSERT #ewerror
 SELECT 2000,
 20036,
 "",
 "",
 date_aging,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg 
 WHERE date_aging - date_due = 0
 END

 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20037 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 222, 5 ) + " -- MSG: " + "The due date should be greater than the document date"
 
 
 INSERT #ewerror
 SELECT 2000,
 20037,
 "",
 "",
 date_due,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg 
 WHERE date_due < date_doc
 END
 
 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20038 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 248, 5 ) + " -- MSG: " + "The due date should be greater than the apply date"
 
 
 INSERT #ewerror
 SELECT 2000,
 20038,
 "",
 "",
 date_due,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg 
 WHERE date_due < date_applied
 END



 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20039 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 276, 5 ) + " -- MSG: " + "Validate that if the due date falls within any period defined in GL"
 
 
 INSERT #ewerror
 SELECT 2000,
 20039,
 "",
 "",
 date_due,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg 
 WHERE date_due < @min_period_start_date
 OR date_due > @max_period_end_date
 END


 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20040 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 304, 5 ) + " -- MSG: " + "Validate that the due date matches the terms code definition"
 
 
 INSERT #ewerror
 SELECT 2000,
 20040,
 "",
 "",
 a.date_due,
 0.0,
 3,
 a.trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg a, arterms b
 WHERE a.terms_code = b.terms_code
 AND b.terms_type = 1
 AND a.date_due != a.date_doc + b.days_due
 END


 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20041 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 334, 5 ) + " -- MSG: " + "Validate that the due date matches the day of the month specified in the terms code"
 
 
 
 SELECT a.date_applied apply_date,
 b.terms_code term,
 datepart(mm,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800")) month,
 datepart(dd,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800")) days,
 datepart(yy,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800")) years,
 datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800"))-1800,
 dateadd(mm,datepart(mm,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800")) - 1,"1/1/1800")),
 dateadd(yy,datepart(yy,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800"))-1800,
 dateadd(mm,datepart(mm,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800")),"1/1/1800"))) month1,
 datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800"))-1800,
 dateadd(mm,datepart(mm,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800")),"1/1/1800")),
 dateadd(yy,datepart(yy,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800"))-1800,
 dateadd(mm,datepart(mm,dateadd(dd,a.date_applied + min_days_due - 657072,"1/1/1800"))+1,"1/1/1800"))) month2,
 b.days_due,
 (1-ABS(SIGN(b.min_days_due-31)))*(1-ABS(SIGN(b.days_due-31)))*
 datepart(mm,dateadd(dd,a.date_applied - 657072,"1/1/1800"))*5 mark_flag
 INTO #days_temp
 FROM #arvalchg a, arterms b
 WHERE a.terms_code = b.terms_code
 AND b.terms_type = 2

 
 UPDATE #days_temp
 SET mark_flag = 1,
 days = days_due
 WHERE days_due <= month1
 AND days_due >= days
 AND mark_flag = 0

 
 UPDATE #days_temp
 SET mark_flag = 2,
 days = month1
 WHERE days_due >= days
 AND days_due > month1
 AND mark_flag = 0

 
 UPDATE #days_temp
 SET mark_flag = 3,
 days = days_due,
 month = month + 1
 WHERE days_due <= month2
 AND days_due < days
 AND mark_flag = 0

 
 UPDATE #days_temp
 SET mark_flag = 4,
 days = month2,
 month = month + 1
 WHERE days_due > month2
 AND days_due < days
 AND mark_flag = 0

 
 UPDATE #days_temp
 SET month = mark_flag/5 + 1,
 days = datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,apply_date - 657072,"1/1/1800"))-1800,
 dateadd(mm,datepart(mm,dateadd(dd,apply_date - 657072,"1/1/1800")),"1/1/1800")),
 dateadd(yy,datepart(yy,dateadd(dd,apply_date - 657072,"1/1/1800"))-1800,
 dateadd(mm,datepart(mm,dateadd(dd,apply_date - 657072,"1/1/1800"))+1,"1/1/1800"))),
 mark_flag = 5
 WHERE mark_flag >= 5
 
 
 UPDATE #days_temp
 SET years = years + 1,
 month = 1
 WHERE month = 13

 
 INSERT #ewerror
 SELECT 2000,
 20041,
 "",
 "",
 a.date_due,
 0.0,
 3,
 a.trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg a, arterms b, #days_temp d
 WHERE a.terms_code = b.terms_code
 AND b.terms_type = 2
 AND a.terms_code = d.term
 AND a.date_applied = d.apply_date
 AND a.date_due != datediff(dd,"1/1/1800",
 (dateadd(dd, days - 1,
 dateadd(mm,month - 1, 
 dateadd(yy,years - 1800,"1/1/1800")))))+657072 
 
 DROP TABLE #days_temp

 END


 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20042 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 476, 5 ) + " -- MSG: " + "Validate that the due date matches the fixed due date specified in the terms code"
 
 
 INSERT #ewerror
 SELECT 2000,
 20042,
 "",
 "",
 a.date_due,
 0.0,
 3,
 a.trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg a, arterms b
 WHERE a.terms_code = b.terms_code
 AND b.terms_type = 3
 AND a.date_due != b.date_due
 END

 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20043 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 504, 5 ) + " -- MSG: " + "Validate that the doc date falls within any period defined in GL"
 
 
 INSERT #ewerror
 SELECT 2000,
 20043,
 "",
 "",
 date_doc,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg 
 WHERE date_doc < @min_period_start_date
 OR date_doc > @max_period_end_date
 END


 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20044 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 532, 5 ) + " -- MSG: " + "Validate that the entry date falls within any period defined in GL"
 
 
 INSERT #ewerror
 SELECT 2000,
 20044,
 "",
 "",
 date_entered,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg 
 WHERE date_entered < @min_period_start_date
 OR date_entered > @max_period_end_date
 END


 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20045 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 560, 5 ) + " -- MSG: " + "Validate that the date requested falls within any period defined in GL"
 
 
 INSERT #ewerror
 SELECT 2000,
 20045,
 "",
 "",
 date_required,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg 
 WHERE (date_required < @min_period_start_date
 OR date_required > @max_period_end_date)
 AND #arvalchg.trx_type != 2021 
 END


 
 IF ( SELECT e_level FROM aredterr WHERE e_code = 20046 ) >= @error_level
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 589, 5 ) + " -- MSG: " + "Validate that the date shipped falls within any period defined in GL"
 
 
 INSERT #ewerror
 SELECT 2000,
 20046,
 "",
 "",
 date_shipped,
 0.0,
 3,
 trx_ctrl_num,
 0,
 ISNULL(source_trx_ctrl_num, ""),
 0
 FROM #arvalchg 
 WHERE (date_shipped < @min_period_start_date
 OR date_shipped > @max_period_end_date)
 AND #arvalchg.trx_type != 2021 
 END

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh4.sp" + ", line " + STR( 612, 5 ) + " -- EXIT: "
 RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINValidateHeader4_SP] TO [public]
GO
