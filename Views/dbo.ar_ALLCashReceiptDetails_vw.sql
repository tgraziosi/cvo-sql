SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ar_ALLCashReceiptDetails_vw]
AS
	SELECT  timestamp,			trx_ctrl_num,			org_id,					customer_code,				
			doc_ctrl_num,		posted_flag,			amt_paid_to_date,		amt_applied,
			amt_wr_off,			amt_disc_taken,			line_desc,				sequence_id,
			inv_amt_applied,	apply_to_num
		FROM artrxpdt
	UNION
	SELECT  timestamp,			trx_ctrl_num,			org_id,					customer_code,				
			doc_ctrl_num,		0 AS posted_flag,		amt_paid_to_date,		amt_applied,
			writeoff_amount,	amt_disc_taken,			line_desc,				sequence_id,
			inv_amt_applied,	apply_to_num
		FROM arinppdt 
GO
GRANT SELECT ON  [dbo].[ar_ALLCashReceiptDetails_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_ALLCashReceiptDetails_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_ALLCashReceiptDetails_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_ALLCashReceiptDetails_vw] TO [public]
GO
