SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[glopenitems_eu_sp]
	@fperiod int, @tperiod int,
	@posted smallint, @non_zero smallint, 
	@oper_totals smallint, @open_items smallint
AS
DECLARE
 @prec_oper smallint, @home_prec smallint,
 @period_1 int, @period_2 int,
 @year_start_1 int, @year_start_2 int


 SELECT @period_1 = MAX(period_end_date) 
 FROM glprd
 WHERE period_end_date < @fperiod

 SELECT @period_2 = @tperiod 

 SELECT @year_start_1 = MAX(period_start_date) 
 FROM glprd
 WHERE period_start_date <@fperiod
 AND period_type = 1001

 SELECT @year_start_2 = MAX(period_start_date) 
 FROM glprd
 WHERE period_start_date <@tperiod
 AND period_type = 1001

 SELECT @home_prec = m1.curr_precision,
 @prec_oper = m2.curr_precision
 FROM glco c,glcurr_vw m1, glcurr_vw m2
 WHERE m1.currency_code = c.home_currency
 AND m2.currency_code = c.oper_currency



INSERT #glbalrefpartner_eu
 (
 account_code, balance_type,
 balance_date, currency_code, reference_code,
 partner_code, partner_code_type, debit,
 credit, debit_home, credit_home,
 debit_oper, credit_oper, current_balance,
 home_current_balance, 
 current_balance_oper, 
 bal_fwd_flag)
 SELECT
 d.account_code, 1,
 @period_1, '', d.reference_code,
 '', 0, 0.0,
 0.0, 0.0, 0.0,
 0.0, 0.0, 0.0,
 ISNULL(SUM(ROUND( balance, @home_prec)),0.0), 
 ISNULL(SUM(ROUND( balance_oper, @prec_oper)),0.0), 
	 1
 FROM gltrx h, gltrxdet d, glchart a, #range_acct_ref r
 WHERE h.journal_ctrl_num = d.journal_ctrl_num 
 AND d.account_code = a.account_code
	AND a.account_type < 400
	AND d.reference_code<>''
 AND h.date_applied <=@period_1
 AND d.account_code = r.account_code
	AND d.reference_code = r.reference_code
 AND (@posted = 2 or (h.posted_flag = @posted))
 GROUP BY d.account_code, d.reference_code, a.account_type



INSERT #glbalrefpartner_eu
 (
 account_code, balance_type,
 balance_date, currency_code, reference_code,
 partner_code, partner_code_type, debit,
 credit, debit_home, credit_home,
 debit_oper, credit_oper, current_balance,
 home_current_balance, 
 current_balance_oper, 
 bal_fwd_flag)
 SELECT
 d.account_code, 1,
 @period_1, '', d.reference_code,
 '', 0, 0.0,
 0.0, 0.0, 0.0,
 0.0, 0.0, 0.0,
 CASE WHEN @year_start_1=@year_start_2 THEN
 ISNULL(SUM(ROUND( balance, @home_prec) * (((sign(400-account_type)+1)/2 + (sign(date_applied+1-@year_start_1)+1)/2 + 1) /2)),0.0)
 ELSE 0.0 END, 
 CASE WHEN @year_start_1=@year_start_2 THEN
 ISNULL(SUM(ROUND( balance_oper, @prec_oper) * (((sign(400-account_type)+1)/2 + (sign(date_applied+1-@year_start_1)+1)/2 + 1) /2)),0.0)
 ELSE 0.0 END, 
	 0
 FROM gltrx h, gltrxdet d, glchart a, #range_acct_ref r
 WHERE h.journal_ctrl_num = d.journal_ctrl_num 
 AND d.account_code = a.account_code
	AND a.account_type >= 400
	AND d.reference_code<>''
 AND h.date_applied <=@period_1
 AND d.account_code = r.account_code
	AND d.reference_code = r.reference_code
 AND (@posted = 2 or (h.posted_flag = @posted))
 GROUP BY d.account_code, d.reference_code, a.account_type


 INSERT #glbalrefpartner_tmp_eu
 (
 account_code, balance_type,
 balance_date, currency_code, reference_code,
 partner_code, partner_code_type, debit,
 credit, debit_home, credit_home,
 debit_oper, credit_oper, current_balance,
 home_current_balance, 
 current_balance_oper, 
 bal_fwd_flag,
 db_action)
 SELECT
 d.account_code, 1,
 @period_2, '', d.reference_code,
 '', 0, 0.0,
 0.0, 
 ISNULL(SUM(ROUND(balance * (SIGN(balance) + 1)/2, @home_prec)),0.0),
 ISNULL(SUM(ROUND(balance * (SIGN(balance) - 1)/2, @home_prec)),0.0),
 ISNULL(SUM(ROUND(balance_oper * (SIGN(balance_oper) + 1)/2, @prec_oper)),0.0),
 ISNULL(SUM(ROUND(balance_oper * (SIGN(balance_oper) - 1)/2, @prec_oper)),0.0),
 0.0, 0.0, 0.0,
 CASE WHEN a.account_type < 400 THEN 1 ELSE 0 END,
 0
 FROM gltrx h, gltrxdet d, glchart a , #range_acct_ref r
 WHERE h.journal_ctrl_num = d.journal_ctrl_num
 AND d.account_code = a.account_code
	 AND d.reference_code<>''
 AND (h.date_applied between @fperiod and @tperiod)
 AND d.account_code = r.account_code
	 AND d.reference_code = r.reference_code
 AND (@posted = 2 or (h.posted_flag = @posted))
 GROUP BY d.account_code, d.reference_code, a.account_type




 UPDATE #glbalrefpartner_tmp_eu 
 SET db_action = 1
 FROM #glbalrefpartner_tmp_eu t, #glbalrefpartner_eu p
 WHERE p.balance_date = @period_1
	 AND p.account_code = t.account_code
	 AND p.reference_code = t.reference_code



 UPDATE #glbalrefpartner_tmp_eu
 SET current_balance = debit-credit,
 home_current_balance = home_current_balance+debit_home-credit_home,
 current_balance_oper = current_balance_oper+debit_oper-credit_oper
 FROM #glbalrefpartner_tmp_eu

 UPDATE #glbalrefpartner_tmp_eu
 SET current_balance = t.current_balance+ISNULL(p.current_balance, 0.0),
 home_current_balance = t.home_current_balance+ISNULL(p. home_current_balance, 0.0),
 current_balance_oper = t.current_balance_oper+ISNULL(p.current_balance_oper, 0.0)
 FROM #glbalrefpartner_tmp_eu t, #glbalrefpartner_eu p
 WHERE p.account_code = t.account_code
	 AND p.reference_code = t.reference_code
 AND p.balance_date = @period_1
 AND t.balance_date = @period_2
 AND t.db_action = 1



 INSERT #glbalrefpartner_eu(
 account_code ,
 balance_type ,
 balance_date ,
 currency_code ,
 reference_code ,
 partner_code ,
 partner_code_type ,
 debit ,
 debit_home ,
 debit_oper ,
 credit ,
 credit_home ,
 credit_oper ,
 home_current_balance ,
 current_balance_oper ,
 bal_fwd_flag )

 SELECT 	
 account_code ,
 balance_type ,
 balance_date ,
 currency_code ,
 reference_code ,
 partner_code ,
 partner_code_type ,
 debit ,
 debit_home ,
 debit_oper ,
 credit ,
 credit_home ,
 credit_oper ,
 home_current_balance ,
 current_balance_oper ,
 bal_fwd_flag 

 FROM #glbalrefpartner_tmp_eu








 insert #bal_acct_ref( 
 account_code ,
 reference_code ,
 debit,
 credit,
 beginning_balance ,
 ending_balance ,
 bal_fwd_flag )
 select account_code, reference_code, 
 case when (@oper_totals = 0) then debit_home else debit_oper end, 
 case when (@oper_totals = 0) then credit_home else credit_oper end, 
 0.0,
 case when (@oper_totals = 0) then home_current_balance else current_balance_oper end,
 bal_fwd_flag 
 from #glbalrefpartner_eu
 where balance_date = @period_2


 
 insert #bal_acct_ref( 
 account_code ,
 reference_code ,
 debit,
 credit,
 beginning_balance ,
 ending_balance ,
 bal_fwd_flag )
 select a.account_code, a.reference_code, 
 case when (@oper_totals = 0) then a.debit_home else a.debit_oper end, 
 case when (@oper_totals = 0) then a.credit_home else a.credit_oper end, 
 case when (@oper_totals = 0) then a.home_current_balance else a.current_balance_oper end, 
 case when (@oper_totals = 0) then a.home_current_balance else a.current_balance_oper end,
 a.bal_fwd_flag 
 from #glbalrefpartner_eu a 
 where a.balance_date = @period_1
 and not exists (select 1 from #glbalrefpartner_eu c
	where a.account_code = c.account_code
	and a.reference_code = c.reference_code
	and c.balance_date = @period_2)
 
 
 update #bal_acct_ref
 set beginning_balance = case when (@oper_totals = 0) then a.home_current_balance 
 else a.current_balance_oper end
 from #glbalrefpartner_eu a, #bal_acct_ref b 
 where a.account_code = b.account_code
 and a.reference_code = b.reference_code
 and a.balance_date = @period_1
 


if @open_items > 0
 DELETE #bal_acct_ref
 WHERE ending_balance = 0.0

GO
GRANT EXECUTE ON  [dbo].[glopenitems_eu_sp] TO [public]
GO
