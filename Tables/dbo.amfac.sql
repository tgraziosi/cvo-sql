CREATE TABLE [dbo].[amfac]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[fac_mask] [dbo].[smAccountCode] NOT NULL,
[fac_mask_description] [dbo].[smStdDescription] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amfac_ind_0] ON [dbo].[amfac] ([company_id], [fac_mask]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amfac].[fac_mask_description]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amfac].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amfac] TO [public]
GO
GRANT SELECT ON  [dbo].[amfac] TO [public]
GO
GRANT INSERT ON  [dbo].[amfac] TO [public]
GO
GRANT DELETE ON  [dbo].[amfac] TO [public]
GO
GRANT UPDATE ON  [dbo].[amfac] TO [public]
GO
