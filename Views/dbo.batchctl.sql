SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE VIEW [dbo].[batchctl]
			AS
			SELECT 	timestamp, batch_ctrl_num, batch_description, start_date, start_time, 
				completed_date, completed_time, control_number, control_total, actual_number, 
				actual_total, batch_type, document_name, hold_flag, posted_flag, void_flag, 
				selected_flag, number_held, date_applied, date_posted, time_posted, start_user, 
				completed_user, posted_user, company_code, selected_user_id, process_group_num, 
				page_fill_1, page_fill_2, page_fill_3, page_fill_4, page_fill_5, page_fill_6, 
				page_fill_7, page_fill_8, org_id 
			FROM batchctl_all 
GO
GRANT REFERENCES ON  [dbo].[batchctl] TO [public]
GO
GRANT SELECT ON  [dbo].[batchctl] TO [public]
GO
GRANT INSERT ON  [dbo].[batchctl] TO [public]
GO
GRANT DELETE ON  [dbo].[batchctl] TO [public]
GO
GRANT UPDATE ON  [dbo].[batchctl] TO [public]
GO
