SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[argetrec_sp]	
				@debug_level		smallint = 0,
				@perf_level		smallint = 0
AS

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "
	
	
	

	UPDATE	#arinpchg_rec 
	SET	date_recurring = a.date_applied + 1
	FROM	#arinpchg_rec a, arcycle b
	WHERE	a.recurring_code = b.cycle_code
	AND	b.cycle_type = 1

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 52, 5 ) + " -- EXIT: "
 	RETURN 34563
	END
	
	

	UPDATE	#arinpchg_rec 
	SET	date_recurring = a.date_applied + 7
	FROM	#arinpchg_rec a, arcycle b
	WHERE	a.recurring_code = b.cycle_code
	AND	b.cycle_type = 2

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 68, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	
	UPDATE #arinpchg_rec 
	SET date_recurring = 

				datediff(dd,"1/1/1800",
				
				dateadd(dd,14,
				
				dateadd(dd,
				
				- datepart(dd,dateadd(dd,a.date_applied - 657072,"1/1/1800")) + 1
				
				,dateadd(dd,a.date_applied - 657072,"1/1/1800") 
				)
				)
				)+657072



	FROM	#arinpchg_rec a, arcycle b
	WHERE	a.recurring_code = b.cycle_code
	AND	b.cycle_type = 3
	AND	datepart(dd,dateadd(dd,a.date_applied - 657072,"1/1/1800")) < 15

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	UPDATE #arinpchg_rec 
	SET date_recurring = 
				datediff(dd,"1/1/1800",
				
				dateadd(mm,1,
				
				dateadd(dd,
				
				- datepart(dd,dateadd(dd,a.date_applied - 657072,"1/1/1800")) + 1
				
				,dateadd(dd,a.date_applied - 657072,"1/1/1800") 
				)
				)
				)+657072
	FROM	#arinpchg_rec a, arcycle b
	WHERE	a.recurring_code = b.cycle_code
	AND	b.cycle_type = 3
	AND	datepart(dd,dateadd(dd,a.date_applied - 657072,"1/1/1800")) >= 15

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 125, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	
	UPDATE	#arinpchg_rec 
	SET	date_recurring = datediff(dd,"1/1/1800",(dateadd(mm,1,dateadd(dd,a.date_applied - 657072,"1/1/1800"))))+657072
	FROM	#arinpchg_rec a, arcycle b
	WHERE	a.recurring_code = b.cycle_code
	AND	b.cycle_type = 4

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 140, 5 ) + " -- EXIT: "
 	RETURN 34563
	END


	
	UPDATE	#arinpchg_rec
	SET	date_recurring = datediff(dd,"1/1/1800",
		dateadd(dd,-1,
			dateadd(mm,datepart(mm,dateadd(dd,date_applied - 657072,"1/1/1800")) +1, 
					dateadd(yy,datepart(yy,dateadd(dd,date_applied - 657072,"1/1/1800")) - 1800,"1/1/1800"))))+657072
	FROM	#arinpchg_rec a, arcycle b
	WHERE	a.recurring_code = b.cycle_code
	AND	b.cycle_type = 0

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 159, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	
	UPDATE	#arinpchg_rec 
	SET	date_recurring = a.date_applied + b.number
	FROM	#arinpchg_rec a, arcycle b
	WHERE	a.recurring_code = b.cycle_code
	AND	b.cycle_type = 5

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 174, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	
	UPDATE	#arinpchg_rec 
	SET	date_recurring = a.date_applied + (b.number * 7)
	FROM	#arinpchg_rec a, arcycle b
	WHERE	a.recurring_code = b.cycle_code
	AND	b.cycle_type = 6

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 189, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	
	UPDATE	#arinpchg_rec 
	SET	date_recurring = (datediff(dd,"1/1/1800",(dateadd(mm,b.number,dateadd(dd,a.date_applied - 657072,"1/1/1800"))))+657072) 
	FROM	#arinpchg_rec a, arcycle b
	WHERE	a.recurring_code = b.cycle_code
	AND	b.cycle_type = 7

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 204, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	
	UPDATE	#arinpchg_rec
	SET	date_due	= SIGN(date_due) * (date_due + (date_recurring - date_applied)),
		date_doc	= SIGN(date_doc) * (date_doc + (date_recurring - date_applied)),
		date_entered	= SIGN(date_entered) * (date_entered + (date_recurring - date_applied)),
		date_shipped	= SIGN(date_shipped) * (date_shipped + (date_recurring - date_applied)),
		date_required	= SIGN(date_required) * (date_required + (date_recurring - date_applied)),
		date_aging	= SIGN(date_aging) * (date_aging + (date_recurring - date_applied)),
		date_applied	= date_recurring

	DELETE	#arinpchg_rec
	FROM	#arinpchg_rec a, arcycle b
	WHERE	a.recurring_code = b.cycle_code
	AND	b.cancel_flag > 0 
	AND	a.date_recurring > b.date_cancel

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 228, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	
	UPDATE	#arinpchg_rec
	SET	date_due = b.date_due
	FROM	#arinpchg_rec a, arterms b
	WHERE	a.terms_code = b.terms_code
	AND	b.terms_type = 3

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 245, 5 ) + " -- EXIT: "
 	RETURN 34563
	END


	
	
	SELECT	a.date_doc doc_date,
		b.terms_code term,
		datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) month,
		datepart(dd,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) days,
		datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) years,
		datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")) - 1,"1/1/1800")),
				dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")),"1/1/1800"))) month1,
		datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800")),"1/1/1800")),
				dateadd(yy,datepart(yy,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,a.date_doc + min_days_due - 657072,"1/1/1800"))+1,"1/1/1800"))) month2,
		b.days_due,
		(1-ABS(SIGN(b.min_days_due-31)))*(1-ABS(SIGN(b.days_due-31)))*
			datepart(mm,dateadd(dd,a.date_doc - 657072,"1/1/1800"))*5 mark_flag
	INTO	#days_temp
	FROM	#arinpchg_rec a, arterms b
	WHERE	a.terms_code = b.terms_code
	AND	b.terms_type = 2

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 288, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	
	UPDATE	#days_temp
	SET	mark_flag = 1,
		days = days_due
	WHERE	days_due <= month1
	AND	days_due >= days
	AND	mark_flag = 0

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 305, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	
	UPDATE	#days_temp
	SET	mark_flag = 2,
		days = month1
	WHERE	days_due >= days
	AND	days_due > month1
	AND	mark_flag = 0

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 323, 5 ) + " -- EXIT: "
 	RETURN 34563
	END
	
	UPDATE	#days_temp
	SET	mark_flag = 3,
		days = days_due,
		month = month + 1
	WHERE	days_due <= month2
	AND	days_due < days
	AND	mark_flag = 0

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 340, 5 ) + " -- EXIT: "
 	RETURN 34563
	END
	
	
	UPDATE	#days_temp
	SET	mark_flag = 4,
		days = month2,
		month = month + 1
	WHERE	days_due > month2
	AND	days_due < days
	AND	mark_flag = 0

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 359, 5 ) + " -- EXIT: "
 	RETURN 34563
	END
	
	
	UPDATE	#days_temp
	SET	month = mark_flag/5 + 1,
		days = datediff(dd,dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,"1/1/1800"))-1800,
			dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,"1/1/1800")),"1/1/1800")),
				dateadd(yy,datepart(yy,dateadd(dd,doc_date - 657072,"1/1/1800"))-1800,
					dateadd(mm,datepart(mm,dateadd(dd,doc_date - 657072,"1/1/1800"))+1,"1/1/1800"))),
		mark_flag = 5
	WHERE	mark_flag >= 5
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 380, 5 ) + " -- EXIT: "
 	RETURN 34563
	END
	
	
	UPDATE	#days_temp
	SET	years = years + 1,
		month = 1
	WHERE	month = 13

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 394, 5 ) + " -- EXIT: "
 	RETURN 34563
	END

	UPDATE	#arinpchg_rec
	SET	date_due = datediff(dd,"1/1/1800",
			(dateadd(dd, days - 1,
				dateadd(mm,month - 1, 
					dateadd(yy,years - 1800,"1/1/1800")))))+657072
	FROM	#arinpchg_rec a, arterms b, #days_temp d
	WHERE	a.terms_code = b.terms_code
	AND	b.terms_type = 2
	AND	a.terms_code = d.term
	AND	a.date_doc = d.doc_date

 	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 411, 5 ) + " -- EXIT: "
 	RETURN 34563
	END
	
	DROP TABLE #days_temp

	
	DELETE FROM #arinpchg_rec
		WHERE recurring_code in
			( SELECT a.recurring_code FROM #arinpchg_rec a, #arcycle_work b		
				WHERE
					a.recurring_code = b.cycle_code	
					and tracked_flag = 1	
				GROUP BY recurring_code
				HAVING round(sum(a.amt_net) + max(amt_tracked_balance),6) > round(max(b.amt_base),6)
			)

	IF( @@error != 0 )
		BEGIN
			SET ROWCOUNT 0			
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 435, 5 ) + " -- EXIT: "
 	RETURN 34563
		END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argetrec.sp" + ", line " + STR( 439, 5 ) + " -- EXIT: "
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[argetrec_sp] TO [public]
GO
