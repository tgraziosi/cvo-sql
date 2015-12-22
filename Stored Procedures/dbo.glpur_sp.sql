SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glpur.SPv - e7.2.2 : 1.13
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 




























































































































































































































































CREATE PROCEDURE [dbo].[glpur_sp] 	
	
	@trx_flag 	smallint,	
	@bal_flag 	smallint, 	
	@bud_flag 	smallint,	
	@non_fin_flag 	smallint,	
	@sum_bal_flag 	smallint,
	@trx_start 	int,		
	@trx_end 	int,
	@bal_start 	int,		
	@bal_end 	int,
	@bud_start 	int,		
	@bud_end 	int,
	@nofin_start 	int,	
	@nofin_end 	int,
	@acc_start 	int,		
	@acc_end 	int

AS


DECLARE	@tot_trx 		float, 
	@perc_done 		float, 
	@tran_started		tinyint,
	@ret_status		int

SELECT	@tran_started = 0


CREATE TABLE #glbaltmp
(
	account_code		varchar(32),
	currency_code		varchar(8),
	balance_date		int,
	debit			float,		
	credit			float,	 
	net_change		float,	 
	current_balance		float,	 
	balance_type		smallint, 
	bal_fwd_flag		smallint, 
	seg1_code		varchar(32),	
	seg2_code		varchar(32),
	seg3_code		varchar(32),
	seg4_code		varchar(32),
	account_type		smallint,
	home_net_change		float,		
	home_current_balance	float,		
	home_debit		float,		
	home_credit		float,
	net_change_oper		float null,
	current_balance_oper	float null,
	credit_oper		float null,
	debit_oper		float null
)
CREATE UNIQUE INDEX #glbal_ind_0
	 ON #glbaltmp (account_code,currency_code,balance_date,balance_type)



IF ( @@trancount = 0 )
BEGIN
	BEGIN TRAN
	SELECT @tran_started = 1
END


IF ( @trx_flag = 1 )
BEGIN
	DELETE	gltrxdet
	WHERE	journal_ctrl_num 
		IN (	SELECT	journal_ctrl_num
			FROM	gltrx
			WHERE	date_applied >= @trx_start
			 AND	date_applied <= @trx_end
			 AND	posted_flag = 1
		 )

	DELETE glictrxd
	WHERE journal_ctrl_num
	 IN ( SELECT journal_ctrl_num
		 FROM gltrx
			WHERE date_applied >= @trx_start
			 AND date_applied <= @trx_end
			 AND	 posted_flag = 1
		 )

	DELETE	gltrx
	WHERE	date_applied >= @trx_start
	 AND date_applied <= @trx_end
	 AND	posted_flag = 1

END


IF ( @bud_flag = 1 )
BEGIN
	DELETE	glbuddet
	FROM	glbuddet b
	WHERE	period_end_date >= @bud_start
	AND period_end_date <= @bud_end
	AND	period_end_date NOT IN ( SELECT date_last_applied
					 FROM glreall r
					 WHERE r.budget_code = b.budget_code )

	DELETE glbud
	WHERE budget_code NOT IN ( SELECT DISTINCT budget_code
				 FROM glbuddet )	
END


IF ( @non_fin_flag = 1 )
BEGIN
	DELETE	glnofind
	FROM	glnofind n
	WHERE	period_end_date >= @nofin_start
	AND period_end_date <= @nofin_end
	AND	period_end_date NOT IN ( SELECT date_last_applied
					 FROM glreall r
					 WHERE r.nonfin_budget_code = n.nonfin_budget_code )

	DELETE glnofin
	WHERE nonfin_budget_code NOT IN
			( SELECT DISTINCT nonfin_budget_code
			 FROM glnofind )			
END


IF ( @bal_flag = 1 )
BEGIN
	EXEC @ret_status = glpurbal_sp @bal_start, @bal_end, 1

	IF ( @ret_status != 0 )
		goto stop_error
END


IF ( @sum_bal_flag = 1)
BEGIN
	EXEC @ret_status = glpurbal_sp @acc_start, @acc_end, 2

	IF ( @ret_status != 0 )
		goto stop_error
END


IF ( @tran_started = 1 )
BEGIN
	COMMIT TRAN
	SELECT @tran_started = 0
END


if ( @bal_flag = 1 OR @sum_bal_flag = 1 )
	EXEC	@ret_status = glbalchk_sp	
			 'REPAIR', 1 

DROP TABLE #glbaltmp

RETURN	@ret_status

stop_error:
ROLLBACK TRAN
DROP TABLE #glbaltmp
RETURN	@ret_status



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glpur_sp] TO [public]
GO
