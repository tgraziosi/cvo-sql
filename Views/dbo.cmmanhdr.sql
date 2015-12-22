SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[cmmanhdr]
			AS
			  SELECT timestamp, trx_ctrl_num, trx_type, description, batch_code, cash_acct_code, user_id, date_applied, 
				date_entered, hold_flag, posted_flag, total, currency_code, rate_type_home, rate_type_oper, rate_home, 
				rate_oper, process_group_num, reference_code, org_id, interbranch_flag, temp_flag 
			  FROM cmmanhdr_all 
GO
GRANT REFERENCES ON  [dbo].[cmmanhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[cmmanhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[cmmanhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[cmmanhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmmanhdr] TO [public]
GO
