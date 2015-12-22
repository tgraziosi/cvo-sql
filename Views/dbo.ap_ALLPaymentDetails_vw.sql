SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ap_ALLPaymentDetails_vw]
AS
	SELECT		timestamp,trx_ctrl_num,		org_id,		void_flag,			'1' AS posted_flag, 
				0 AS hold_flag,				apply_to_num				
			FROM appydet 
		UNION
	SELECT		timestamp,trx_ctrl_num,		org_id,		void_flag,			'0' AS posted_flag,
				payment_hold_flag AS hold_flag, 	apply_to_num		
			FROM apinppdt 
GO
GRANT SELECT ON  [dbo].[ap_ALLPaymentDetails_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ap_ALLPaymentDetails_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ap_ALLPaymentDetails_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ap_ALLPaymentDetails_vw] TO [public]
GO
