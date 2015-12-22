SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[batchctl_reg_sp]
AS
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'batchctl' AND type = 'V') 
		DROP VIEW batchctl
IF (( EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1)))
	BEGIN
		EXEC ('	CREATE VIEW batchctl
			AS
			SELECT 	timestamp, batch_ctrl_num, batch_description, start_date, start_time, 
				completed_date, completed_time, control_number, control_total, actual_number, 
				actual_total, batch_type, document_name, hold_flag, posted_flag, void_flag, 
				selected_flag, number_held, date_applied, date_posted, time_posted, start_user, 
				completed_user, posted_user, company_code, selected_user_id, process_group_num, 
				page_fill_1, page_fill_2, page_fill_3, page_fill_4, page_fill_5, page_fill_6, 
				page_fill_7, page_fill_8, org_id 
			FROM batchctl_all
				WHERE exists (select organization_id from Organization where organization_id = batchctl_all.org_id) ')
	END
ELSE
	BEGIN
		EXEC ('	CREATE VIEW batchctl
			AS
			SELECT 	timestamp, batch_ctrl_num, batch_description, start_date, start_time, 
				completed_date, completed_time, control_number, control_total, actual_number, 
				actual_total, batch_type, document_name, hold_flag, posted_flag, void_flag, 
				selected_flag, number_held, date_applied, date_posted, time_posted, start_user, 
				completed_user, posted_user, company_code, selected_user_id, process_group_num, 
				page_fill_1, page_fill_2, page_fill_3, page_fill_4, page_fill_5, page_fill_6, 
				page_fill_7, page_fill_8, org_id 
			FROM batchctl_all ')		
	END
EXEC ('GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON batchctl TO PUBLIC')
GO
GRANT EXECUTE ON  [dbo].[batchctl_reg_sp] TO [public]
GO
