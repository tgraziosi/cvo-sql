SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[glreall]
			AS
			SELECT timestamp, journal_ctrl_num, journal_type, journal_description, date_entered, date_posted, date_last_applied, 
				batch_code, hold_flag, posted_flag, based_type, budget_code, nonfin_budget_code, account_code, intercompany_flag, 
				org_id, interbranch_flag 
			FROM glreall_all 
GO
GRANT REFERENCES ON  [dbo].[glreall] TO [public]
GO
GRANT SELECT ON  [dbo].[glreall] TO [public]
GO
GRANT INSERT ON  [dbo].[glreall] TO [public]
GO
GRANT DELETE ON  [dbo].[glreall] TO [public]
GO
GRANT UPDATE ON  [dbo].[glreall] TO [public]
GO
