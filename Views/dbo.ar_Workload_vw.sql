SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ar_Workload_vw]
AS

	SELECT  ar_ALLCashReceipt_vw.trx_type,ar_ALLCashReceipt_vw.user_id,smusers_vw.user_name,
	glprd.period_end_date,count = count(ar_ALLCashReceipt_vw.trx_ctrl_num)  
	FROM ar_ALLCashReceipt_vw, smusers_vw ,glprd
	WHERE 
	smusers_vw.user_id = ar_ALLCashReceipt_vw.user_id AND 
	ar_ALLCashReceipt_vw.date_applied BETWEEN glprd.period_start_date AND glprd.period_end_date   
	GROUP BY ar_ALLCashReceipt_vw.trx_type, ar_ALLCashReceipt_vw.user_id,
	glprd.period_end_date,smusers_vw.user_name
	UNION
	-- Invoices
	SELECT  ar_ALLInvoices_vw.trx_type,ar_ALLInvoices_vw.user_id,smusers_vw.user_name,
	glprd.period_end_date,count = count(ar_ALLInvoices_vw.trx_ctrl_num)  
	FROM ar_ALLInvoices_vw, smusers_vw ,glprd
	WHERE 
	smusers_vw.user_id = ar_ALLInvoices_vw.user_id AND 
	ar_ALLInvoices_vw.date_applied BETWEEN glprd.period_start_date AND glprd.period_end_date   
	GROUP BY ar_ALLInvoices_vw.trx_type, ar_ALLInvoices_vw.user_id,
	glprd.period_end_date,smusers_vw.user_name
	UNION
	-- Credit Memos
	SELECT  ar_ALLCreditMemos_vw.trx_type,ar_ALLCreditMemos_vw.user_id,smusers_vw.user_name,
	glprd.period_end_date,count = count(ar_ALLCreditMemos_vw.trx_ctrl_num)  
	FROM ar_ALLCreditMemos_vw, smusers_vw ,glprd
	WHERE 
	smusers_vw.user_id = ar_ALLCreditMemos_vw.user_id AND 
	ar_ALLCreditMemos_vw.date_applied BETWEEN glprd.period_start_date AND glprd.period_end_date   
	GROUP BY ar_ALLCreditMemos_vw.trx_type, ar_ALLCreditMemos_vw.user_id,
	glprd.period_end_date,smusers_vw.user_name
	UNION
	-- AFT Invoices
	SELECT  ar_ALLAFTInv_vw.trx_type,ar_ALLAFTInv_vw.user_id,smusers_vw.user_name,
	glprd.period_end_date,count = count(ar_ALLAFTInv_vw.trx_ctrl_num)  
	FROM ar_ALLAFTInv_vw, smusers_vw ,glprd
	WHERE 
	smusers_vw.user_id = ar_ALLAFTInv_vw.user_id AND 
	ar_ALLAFTInv_vw.date_applied BETWEEN glprd.period_start_date AND glprd.period_end_date   
	GROUP BY ar_ALLAFTInv_vw.trx_type, ar_ALLAFTInv_vw.user_id,
	glprd.period_end_date,smusers_vw.user_name

GO
GRANT SELECT ON  [dbo].[ar_Workload_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_Workload_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_Workload_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_Workload_vw] TO [public]
GO
