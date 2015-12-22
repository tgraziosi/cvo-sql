SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_security_sp]
	@company_id smallint,

	@user_id int
AS
DECLARE @loginame varchar(255)
DECLARE @start int

	SET NOCOUNT ON

	SELECT @start = CHARINDEX('\',suser_sname()) + 1

	SELECT	ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 70003 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Credit & Collections',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 1 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Export',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 2 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Print',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 3 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Print NOA',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 4 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Age Brackets',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 5 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Chg Password',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 6 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Credit Limit',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 7 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'History',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 8 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Log Types',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 9 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Delete Comments',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 10 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Status Types',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 11 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'PU Reprint',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 12 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'PU Set Status',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 13 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'PU Status History',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 14 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Call Log Rpt',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 15 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Summ Call Log Rpt',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 16 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Cust Aging Rpt',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 17 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Invoice Info Rpt',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 18 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Reprint CM',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 19 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Reprint Inv',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 20 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Delete Note/Link',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 21 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Promise List Rpt',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 22 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Status Code Rpt',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 23 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Task List Rpt',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 24 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Add User to Wrkld',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 25 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Create Wrkld',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 26 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Select Wrkld',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 27 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Select Aging Date',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 28 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Edit Comments',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 29 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Set Phone Mask',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 30 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Modify Attn Name',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 31 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Modify Attn Phone',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 32 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Set Cust Status',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 33 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Modify Tab Enabled',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 34 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Statistics Rpt Enabled',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 35 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Statement Rpt Enabled',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 36 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Cust. Not in WL Rpt Enabled',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 37 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Contact Info Enabled',
					ISNULL((SELECT 1 FROM sysobjects WHERE name = 'orders' and type = 'U'),0) 'Orders Exists',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 39 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'eBackoffice Aging',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 40 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Reprint Maintenance Renewal Invoice',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 41 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Workload Custom',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 42 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Set Priority Codes',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 43 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Order Maintenance',

					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 44 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Print Statements (Range)',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 45 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Workload Listings',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 46 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Change Company',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 47 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Customer Status',

					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 48 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) 'Followup Purge',

					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 49 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) '50 Set Followup Default to No',

					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 50 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) '51 Inv Alert Defaults',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 51 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) '52 Inv Alerts',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 52 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) '53 Inv Alert Purge',
					ISNULL((SELECT 1 FROM CVO_Control..smperm WHERE form_id = 53 AND app_id = 25000 and user_id = @user_id and company_id = @company_id), 0) '54 Org Config'
		SET NOCOUNT OFF 
GO
GRANT EXECUTE ON  [dbo].[cc_security_sp] TO [public]
GO
