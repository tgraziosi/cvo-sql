SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[glrecur]
			AS
			SELECT timestamp, journal_ctrl_num, recur_description, journal_type, tracked_balance_flag, percentage_flag, 
				continuous_flag, year_end_type, recur_if_zero_flag, hold_flag, posted_flag, tracked_balance_amount, 
				base_amount, date_last_applied, date_end_period_1, date_end_period_2, date_end_period_3, date_end_period_4, 
				date_end_period_5, date_end_period_6, date_end_period_7, date_end_period_8, date_end_period_9, 
				date_end_period_10, date_end_period_11, date_end_period_12, date_end_period_13, all_periods, 
				number_of_periods, period_interval, intercompany_flag, nat_cur_code, document_1, rate_type_home, 
				rate_type_oper, org_id, interbranch_flag 
			FROM glrecur_all 
GO
GRANT REFERENCES ON  [dbo].[glrecur] TO [public]
GO
GRANT SELECT ON  [dbo].[glrecur] TO [public]
GO
GRANT INSERT ON  [dbo].[glrecur] TO [public]
GO
GRANT DELETE ON  [dbo].[glrecur] TO [public]
GO
GRANT UPDATE ON  [dbo].[glrecur] TO [public]
GO
