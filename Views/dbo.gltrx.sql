SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[gltrx]
			AS
			SELECT timestamp, journal_type, journal_ctrl_num, journal_description, date_entered, date_applied,
				recurring_flag, repeating_flag, reversing_flag, hold_flag, posted_flag, date_posted, source_batch_code, 
				batch_code, type_flag, intercompany_flag, company_code, app_id, home_cur_code, document_1, trx_type, 
				user_id, source_company_code, process_group_num, oper_cur_code, org_id, interbranch_flag 
			FROM gltrx_all 
GO
GRANT REFERENCES ON  [dbo].[gltrx] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrx] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrx] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrx] TO [public]
GO
