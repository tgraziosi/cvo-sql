SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[glmkrec_sp] 
 @period_end	int,		
 @batch_ctrl_num	varchar(16),	
	@sys_date	int,		
	@debug		smallint = 0	
							
AS DECLARE 						
		@min_journal_ctrl_num varchar(16),	
 @app_id			smallint,
	@i			int,
	@max_jcn		varchar(16),
 @rep_trx_count		int,
 @rev_trx_count		int,
 @rec_trx_count		int,	 				
 @err_msg		char(80), 	
	@new_journal_ctrl_num	varchar(16),
 @next_prd	 	int,				
 @company_code		varchar(8),
	@result		 	int,
	@start_time		datetime,
	@work_time		datetime

IF ( @debug >= 1 )
BEGIN
	SELECT 	"-------------------- Entering glmkrec_sp -------------------"
	SELECT	@start_time = getdate()
END


IF NOT EXISTS (
	SELECT 	1 
	FROM 	#gldtrx_grp 
	WHERE	recurring_flag + repeating_flag + reversing_flag > 0 )
BEGIN
	IF @debug >= 1
		SELECT "No GLMKREC transactions to process."
	RETURN 0
END


SELECT	@batch_ctrl_num = ISNULL( @batch_ctrl_num, " " )


SELECT	@next_prd = NULL

SELECT @next_prd = MIN( period_end_date )
FROM glprd
WHERE period_end_date > @period_end

IF ( @next_prd IS NULL )
BEGIN
	EXEC	glgetmsg_sp	1040,
				@err_msg OUTPUT
	IF ( @debug >= 1 )
		SELECT @err_msg

	RETURN 1040
END



SELECT	@rep_trx_count = count(company_id)
FROM 	glnumber

IF @rep_trx_count = 0
BEGIN
	IF ( @debug >= 1 )
		SELECT "No record in glnumber table."

	RETURN 1015
END


SELECT	@rep_trx_count = SUM( repeating_flag )
FROM	#gldtrx_grp

SELECT	@rev_trx_count = SUM( reversing_flag )
FROM	#gldtrx_grp

SELECT	@rec_trx_count = SUM( recurring_flag )
FROM	#gldtrx_grp

IF ( @debug >= 3 )
	SELECT 	" " "Transactions to process", 
		@rep_trx_count "Repeating",
		@rev_trx_count "Reversing", 
		@rec_trx_count "Recurring"

IF ( @debug >= 3)
BEGIN
	SELECT "Creating repeating JCNs"
	SELECT	@work_time = getdate()
END

SELECT	@i = 0

WHILE @i < @rep_trx_count
BEGIN
	SELECT	@max_jcn = MAX(journal_ctrl_num)
	FROM	#new_trx
	WHERE	flag_type = 1

	IF ( @max_jcn IS NULL )
		SELECT	@max_jcn = " "

	EXEC	glnxttrx_sp	@new_journal_ctrl_num OUTPUT

	SELECT 	@min_journal_ctrl_num = MIN(journal_ctrl_num)		
	FROM 	#gldtrx_grp a											
	WHERE	a.journal_ctrl_num > @max_jcn						
 	 AND	a.repeating_flag = 1								

	INSERT 	#new_trx
	SELECT 	journal_ctrl_num, @new_journal_ctrl_num, 1
	FROM 	#gldtrx_grp a
	WHERE	a.journal_ctrl_num > @max_jcn
 	 AND	a.repeating_flag = 1
	 AND	a.journal_ctrl_num = @min_journal_ctrl_num			

	SELECT	@i = @i + 1

END

SELECT	@i = 0

IF ( @debug >= 3)
	SELECT "Creating reversing JCNs"
WHILE @i < @rev_trx_count
BEGIN
	SELECT	@max_jcn = MAX(journal_ctrl_num)
	FROM	#new_trx
	WHERE	flag_type = 2

	IF ( @max_jcn IS NULL )
		SELECT	@max_jcn = " "

	EXEC	glnxttrx_sp	@new_journal_ctrl_num OUTPUT

	SELECT 	@min_journal_ctrl_num = MIN(journal_ctrl_num)		
	FROM 	#gldtrx_grp a											
	WHERE	a.journal_ctrl_num > @max_jcn						
 	 AND	a.reversing_flag = 1								
	
	INSERT 	#new_trx
	SELECT 	journal_ctrl_num, @new_journal_ctrl_num, 2
	FROM 	#gldtrx_grp a
	WHERE	a.journal_ctrl_num > @max_jcn
 	 AND	a.reversing_flag = 1
	 AND	a.journal_ctrl_num = @min_journal_ctrl_num			

	SELECT	@i = @i + 1
END


SELECT	@i = 0

IF ( @debug >= 3)
	SELECT "Creating recurring JCNs"
WHILE @i < @rec_trx_count
BEGIN
	SELECT	@max_jcn = MAX(journal_ctrl_num)
	FROM	#new_trx
	WHERE	flag_type = 3

	IF ( @max_jcn IS NULL )
		SELECT	@max_jcn = " "

	EXEC	glnxtrec_sp	@new_journal_ctrl_num OUTPUT

	SELECT 	@min_journal_ctrl_num = MIN(journal_ctrl_num)		
	FROM 	#gldtrx_grp a											
	WHERE	a.journal_ctrl_num > @max_jcn						
 	 AND	a.recurring_flag = 1								

	INSERT 	#new_trx
	SELECT 	journal_ctrl_num, @new_journal_ctrl_num, 3
	FROM 	#gldtrx_grp a
	WHERE	a.journal_ctrl_num > @max_jcn
 	 AND	a.recurring_flag = 1
	 AND	a.journal_ctrl_num = @min_journal_ctrl_num			

	SELECT	@i = @i + 1
END

IF ( @debug >= 3 )
BEGIN
	SELECT	"Creating JCNs - time: " +
		convert (varchar(10), datediff( ms, @work_time, getdate() ) ) +
		" ms" " "
	IF ( @debug >= 5)
		SELECT * FROM #new_trx
	SELECT 	" "
	SELECT	"Creating new transactions - repeating"
	SELECT	@work_time = getdate()
END

EXEC	@result =	glmktrx_sp
			@batch_ctrl_num,
			@sys_date,
			@next_prd,
			@debug

IF ( @result != 0 )
	RETURN	@result



IF ( @rep_trx_count + @rev_trx_count + @rec_trx_count > 0 )
BEGIN
 UPDATE batchctl 
 SET actual_number =
 (SELECT count(batch_code)
 FROM gltrx
 WHERE batch_code = @batch_ctrl_num), 
 actual_total = 0.0 
 WHERE batch_ctrl_num = @batch_ctrl_num

 
 IF ( @rep_trx_count > 0 )
 BEGIN
	 UPDATE batchctl 
	 SET number_held =
			(SELECT count(batch_code)
	 FROM gltrx
 	 WHERE batch_code = @batch_ctrl_num
			 AND hold_flag = 1), 
		 hold_flag = 1
	 WHERE batch_ctrl_num = @batch_ctrl_num
 END
END

DELETE #new_trx

IF ( @debug >= 1 )
BEGIN
	IF ( @debug >= 3 )
	BEGIN
		SELECT	"Updating batch totals - time: " +
			convert (varchar(10), datediff( ms, @work_time, getdate() ) ) +
			" ms" " "
	END
	IF ( @debug >= 2 )
	BEGIN
		SELECT	"Total GLMKREC execution - time: " +
			convert (varchar(10), datediff( ms, @start_time, getdate() ) ) +
			" ms" " "
	END
	SELECT 	"-------------------- Leaving glmkrec_sp -------------------"
END

RETURN 0



GO
GRANT EXECUTE ON  [dbo].[glmkrec_sp] TO [public]
GO
