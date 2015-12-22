SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glrecprd.SPv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE	PROCEDURE [dbo].[glrecprd_sp] 

	@p_jour_num 		char(32),	
	@p_new_jour_num 	char(32), 
	@p_sys_date 		int,	
	@p_period_end_date 	int,	
	@p_year_end_type 	smallint,
	@p_proc_key 		smallint, 
	@p_user_id 		smallint,	
	@p_orig_flag 		smallint

AS

DECLARE 
	@num_prd 		smallint,	
	@err_mess 		varchar(80), 
	@period_interval 	smallint,
	@base_amt 		float,	
	@last_applied 		int,	
	@cur_date 		int,
	@period 		smallint,	
	@period1 		int, 		
	@period2 		int, 
	@period3 		int, 		
	@period4 		int, 		
	@period5 		int, 
	@period6 		int, 		
	@period7 		int, 		
	@period8 		int, 
	@period9 		int, 		
	@period10 		int, 		
	@period11 		int, 
	@period12 		int, 		
	@period13 		int,		
	@prd_err_found 		int,
	@this_year_begin 	int,	
	@last_year_begin 	int,	
	@new_period1 		int, 		
	@new_period2 		int, 	
	@new_period3 		int, 	
	@new_period4 		int, 		
	@new_period5 		int, 		
	@new_period6 		int, 	
	@new_period7 		int, 		
	@new_period8 		int, 	
	@new_period9 		int, 	
	@new_period10 		int, 		
	@new_period11 		int, 	
	@new_period12 		int, 	
	@new_period13 		int,
	@new_prds 		smallint

SELECT	@new_period1 = 0,	@new_period2 = 0,	@new_period3 = 0,
	@new_period4 = 0,	@new_period5 = 0,	@new_period6 = 0,
	@new_period7 = 0,	@new_period8 = 0,	@new_period9 = 0,
	@new_period10 = 0,	@new_period11 = 0,	@new_period12 = 0,
	@new_period13 = 0


SELECT	@period1 = date_end_period_1,
	@period2 = date_end_period_2,
	@period3 = date_end_period_3,
	@period4 = date_end_period_4,
	@period5 = date_end_period_5,
	@period6 = date_end_period_6,
	@period7 = date_end_period_7,
	@period8 = date_end_period_8,
	@period9 = date_end_period_9,
	@period10 = date_end_period_10,
	@period11 = date_end_period_11,
	@period12 = date_end_period_12,
	@period13 = date_end_period_13,
	@num_prd = number_of_periods,
	@period_interval = period_interval,
	@cur_date = date_last_applied
FROM	glrecur
WHERE	journal_ctrl_num = @p_jour_num


SELECT	@new_prds = 0 


EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period1 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 1
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period2 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 2
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period3 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 3
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period4 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 4
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period5 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 5
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period6 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 6
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period7 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 7
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period8 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 8
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period9 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 9

END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period10 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 10
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period11 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 11
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period12 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 12
END
	

EXEC glgetprd_sp @cur_date, @period_interval, @end=@cur_date OUTPUT
IF @num_prd != 0 AND @cur_date != 0
BEGIN
	SELECT @new_period13 = @cur_date, @num_prd = @num_prd - 1,
	 @new_prds = 13
END

	
UPDATE	glrecur
SET	date_end_period_1 = @new_period1,
	date_end_period_2 = @new_period2, 
	date_end_period_3 = @new_period3, 
	date_end_period_4 = @new_period4, 
	date_end_period_5 = @new_period5, 
	date_end_period_6 = @new_period6, 
	date_end_period_7 = @new_period7, 
	date_end_period_8 = @new_period8, 
	date_end_period_9 = @new_period9, 
	date_end_period_10 = @new_period10,
	date_end_period_11 = @new_period11,
	date_end_period_12 = @new_period12,
	date_end_period_13 = @new_period13,
	number_of_periods = @new_prds
WHERE	journal_ctrl_num = @p_new_jour_num

RETURN 0




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glrecprd_sp] TO [public]
GO
