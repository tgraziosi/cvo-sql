SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[gl_BudgetVsActual_vw]
AS
	SELECT	glbg2_vw.budget_code,		glbg2_vw.account_code,		glbg2_vw.net_change,
			glbg2_vw.current_balance,	glbg2_vw.date_period_end,	glbg2_vw.nat_cur_code,
			 glbal.home_net_change,			glbal.home_current_balance,		remaining = ABS(glbg2_vw.current_balance) - ABS(glbal.home_current_balance)
	FROM glbg2_vw, glbal 
	WHERE glbal.account_code = glbg2_vw.account_code
	AND glbal.balance_date = glbg2_vw.date_period_end AND glbg2_vw.nat_cur_code = glbal.currency_code
GO
GRANT SELECT ON  [dbo].[gl_BudgetVsActual_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_BudgetVsActual_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_BudgetVsActual_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_BudgetVsActual_vw] TO [public]
GO
