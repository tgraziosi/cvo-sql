SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ap_Workload_vw]
AS
	--Debit Memos
	SELECT  ap_ALLDebitMemos_vw.trx_type,ap_ALLDebitMemos_vw.user_id,smusers_vw.user_name,
	glprd.period_end_date,count = count(ap_ALLDebitMemos_vw.trx_ctrl_num)  
	FROM ap_ALLDebitMemos_vw, smusers_vw ,glprd
	WHERE 
	smusers_vw.user_id = ap_ALLDebitMemos_vw.user_id AND 
	ap_ALLDebitMemos_vw.date_applied BETWEEN glprd.period_start_date AND glprd.period_end_date   
	GROUP BY ap_ALLDebitMemos_vw.trx_type, ap_ALLDebitMemos_vw.user_id,
	glprd.period_end_date,smusers_vw.user_name
	UNION
	--Vouchers
	SELECT  ap_ALLVouchers_vw.trx_type,ap_ALLVouchers_vw.user_id,smusers_vw.user_name,
	glprd.period_end_date,count = count(ap_ALLVouchers_vw.trx_ctrl_num)  
	FROM ap_ALLVouchers_vw, smusers_vw ,glprd
	WHERE 
	smusers_vw.user_id = ap_ALLVouchers_vw.user_id AND 
	ap_ALLVouchers_vw.date_applied BETWEEN glprd.period_start_date AND glprd.period_end_date   
	GROUP BY ap_ALLVouchers_vw.trx_type, ap_ALLVouchers_vw.user_id,
	glprd.period_end_date,smusers_vw.user_name,ap_ALLVouchers_vw.timestamp
	UNION
	--Payments
	SELECT  ap_ALLPayments_vw.trx_type,ap_ALLPayments_vw.user_id,smusers_vw.user_name,
	glprd.period_end_date,count = count(ap_ALLPayments_vw.trx_ctrl_num)  
	FROM ap_ALLPayments_vw, smusers_vw ,glprd
	WHERE 
	smusers_vw.user_id = ap_ALLPayments_vw.user_id AND 
	ap_ALLPayments_vw.date_applied BETWEEN glprd.period_start_date AND glprd.period_end_date   
	GROUP BY ap_ALLPayments_vw.trx_type, ap_ALLPayments_vw.user_id,
	glprd.period_end_date,smusers_vw.user_name
GO
GRANT SELECT ON  [dbo].[ap_Workload_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ap_Workload_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ap_Workload_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ap_Workload_vw] TO [public]
GO
