SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[gl_Workload_vw]
AS
	SELECT gltrx.trx_type, gltrx.user_id, smusers_vw.user_name, glprd.period_end_date , count = COUNT(journal_ctrl_num)   
	FROM  gltrx, smusers_vw, glprd
	WHERE 
	smusers_vw.user_id = gltrx.user_id 
	AND gltrx.date_applied BETWEEN glprd.period_start_date AND glprd.period_end_date 
	AND gltrx.type_flag IN ( 0, 2, 3, 4, 5, 6 )
	AND trx_type != 101
	GROUP BY gltrx.trx_type, gltrx.user_id, smusers_vw.user_name, glprd.period_end_date
	UNION ALL
	--Unposted Recurring Transaction
	SELECT gl_UnRecuTrans_vw.trx_type, gl_UnRecuTrans_vw.user_id, smusers_vw.user_name, glprd.period_end_date , count = COUNT(gl_UnRecuTrans_vw.journal_ctrl_num)   
	FROM  gl_UnRecuTrans_vw, smusers_vw, glprd
	WHERE 
	smusers_vw.user_id = gl_UnRecuTrans_vw.user_id 
	AND gl_UnRecuTrans_vw.date_end_period_1 BETWEEN glprd.period_start_date AND glprd.period_end_date 
	GROUP BY gl_UnRecuTrans_vw.trx_type, gl_UnRecuTrans_vw.user_id, smusers_vw.user_name, glprd.period_end_date
	UNION ALL
	-- Unposted Reallocation Transaction
	SELECT gl_UnReallTrans_vw.trx_type, gl_UnReallTrans_vw.user_id, smusers_vw.user_name, glprd.period_end_date , count = COUNT(gl_UnReallTrans_vw.journal_ctrl_num)   
	FROM  gl_UnReallTrans_vw, smusers_vw, glprd
	WHERE 
	smusers_vw.user_id = gl_UnReallTrans_vw.user_id 
	AND gl_UnReallTrans_vw.date_entered BETWEEN glprd.period_start_date AND glprd.period_end_date 
	GROUP BY gl_UnReallTrans_vw.trx_type, gl_UnReallTrans_vw.user_id, smusers_vw.user_name, glprd.period_end_date
GO
GRANT SELECT ON  [dbo].[gl_Workload_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_Workload_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_Workload_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_Workload_vw] TO [public]
GO
