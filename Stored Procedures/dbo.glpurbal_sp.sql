SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

                                                                                CREATE PROCEDURE [dbo].[glpurbal_sp] 
 @purge_start int,  @purge_end int,  @purge_type int AS    DECLARE @year_begin int, 
 @new_balance_date int,  @result int    SELECT @new_balance_date = -1 SELECT @new_balance_date = ( SELECT period_end_date 
 FROM glprd  WHERE period_start_date = @purge_end+1 ) IF ( @new_balance_date = -1 ) 
 goto stop_error    SELECT @year_begin = MAX(period_start_date) FROM glprd WHERE period_type = 1001 
AND period_start_date <= @new_balance_date INSERT #glbaltmp (  account_code,  currency_code, 
 balance_date,  debit,  credit,  net_change,  current_balance,  balance_type,  bal_fwd_flag, 
 seg1_code,  seg2_code,  seg3_code,  seg4_code,  account_type,  home_net_change, 
 home_current_balance,  home_debit,  home_credit,  net_change_oper,  current_balance_oper, 
 credit_oper,  debit_oper) SELECT account_code,  currency_code,  @new_balance_date, 
 debit,  credit,  net_change,  current_balance,  balance_type,  bal_fwd_flag,  seg1_code, 
 seg2_code,  seg3_code,  seg4_code,  account_type,  home_net_change,  home_current_balance, 
 home_debit,  home_credit,  net_change_oper,  current_balance_oper,  credit_oper, 
 debit_oper FROM glbal WHERE balance_type = @purge_type AND balance_date <= @purge_end 
AND balance_until >= @purge_end IF ( @@error != 0 )  goto stop_error    DECLARE @Max_period_end_date as INT 
SELECT @Max_period_end_date = MAX(period_end_date) FROM glprd WHERE period_start_date >= @purge_start 
 and period_end_date <= @purge_end and period_type = 1003 if ISNULL(@Max_period_end_date,0) <> 0 
DELETE #glbaltmp WHERE balance_date <= @Max_period_end_date AND account_type >= 400 
IF ( @@error != 0 ) goto stop_error    DELETE #glbaltmp FROM glbal a, #glbaltmp b 
WHERE a.account_code = b.account_code AND a.currency_code = b.currency_code AND a.balance_date = b.balance_date 
AND a.balance_type = b.balance_type IF ( @@error != 0 )  goto stop_error    DELETE glbal 
WHERE balance_date >= @purge_start AND balance_date <= @purge_end AND balance_type = @purge_type 
IF ( @@error != 0 )  goto stop_error INSERT glbal (  timestamp,  account_code,  currency_code, 
 balance_date,  balance_until,  debit,  credit,  net_change,  current_balance,  balance_type, 
 bal_fwd_flag,  seg1_code,  seg2_code,  seg3_code,  seg4_code,  account_type,  home_net_change, 
 home_current_balance,  home_debit,  home_credit,  net_change_oper,  current_balance_oper, 
 credit_oper,  debit_oper ) SELECT NULL,  account_code,  currency_code,  balance_date, 
 0,  debit,  credit,  net_change,  current_balance,  balance_type,  bal_fwd_flag, 
 seg1_code,  seg2_code,  seg3_code,  seg4_code,  account_type,  home_net_change, 
 home_current_balance,  home_debit,  home_credit,  net_change_oper,  current_balance_oper, 
 credit_oper,  debit_oper FROM #glbaltmp IF ( @@error != 0 )  goto stop_error DELETE #glbaltmp 
RETURN 0 stop_error: DELETE #glbaltmp RETURN -1 
GO
GRANT EXECUTE ON  [dbo].[glpurbal_sp] TO [public]
GO
