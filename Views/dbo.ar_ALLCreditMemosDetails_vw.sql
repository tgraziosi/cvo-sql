SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ar_ALLCreditMemosDetails_vw]
AS
	SELECT  	timestamp,		trx_ctrl_num, 		sequence_id,			location_code,		item_code,		
				line_desc,		qty_shipped,		unit_code,				unit_price,			qty_returned,	
				tax_code,		disc_prc_flag,		extended_price,			gl_rev_acct	
		FROM artrxcdt
	UNION
	SELECT		timestamp,		trx_ctrl_num,		sequence_id,			location_code,		item_code,		
				line_desc,		qty_shipped,		unit_code,				unit_price,		qty_returned,	
				tax_code,		disc_prc_flag,		extended_price,			gl_rev_acct	
		FROM arinpcdt
GO
GRANT SELECT ON  [dbo].[ar_ALLCreditMemosDetails_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_ALLCreditMemosDetails_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_ALLCreditMemosDetails_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_ALLCreditMemosDetails_vw] TO [public]
GO
