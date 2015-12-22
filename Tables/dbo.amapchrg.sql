CREATE TABLE [dbo].[amapchrg]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[trx_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[sequence_id] [dbo].[smCounter] NOT NULL,
[line_desc] [dbo].[smStdDescription] NOT NULL,
[gl_exp_acct] [dbo].[smAccountCode] NOT NULL,
[reference_code] [dbo].[smAccountReferenceCode] NOT NULL,
[amt_charged] [dbo].[smMoneyZero] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NULL,
[modified_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amapchrg_ind_0] ON [dbo].[amapchrg] ([company_id], [trx_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapchrg].[sequence_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amapchrg].[line_desc]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amapchrg].[reference_code]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapchrg].[amt_charged]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amapchrg].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amapchrg] TO [public]
GO
GRANT SELECT ON  [dbo].[amapchrg] TO [public]
GO
GRANT INSERT ON  [dbo].[amapchrg] TO [public]
GO
GRANT DELETE ON  [dbo].[amapchrg] TO [public]
GO
GRANT UPDATE ON  [dbo].[amapchrg] TO [public]
GO
