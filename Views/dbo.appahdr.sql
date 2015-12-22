SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[appahdr]
			AS
			SELECT timestamp, trx_ctrl_num, doc_ctrl_num, batch_code, date_posted, 
			      date_applied, date_entered, cash_acct_code, state_flag, void_flag,
			      doc_desc, user_id, journal_ctrl_num, process_ctrl_num, org_id
			FROM appahdr_all 
GO
GRANT REFERENCES ON  [dbo].[appahdr] TO [public]
GO
GRANT SELECT ON  [dbo].[appahdr] TO [public]
GO
GRANT INSERT ON  [dbo].[appahdr] TO [public]
GO
GRANT DELETE ON  [dbo].[appahdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[appahdr] TO [public]
GO
