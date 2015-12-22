CREATE TABLE [dbo].[amsurkey]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[key_type] [dbo].[smKeyType] NOT NULL,
[sequence_id] [dbo].[smSurrogateKey] NOT NULL,
[filler1] [dbo].[smFiller] NOT NULL,
[filler2] [dbo].[smFiller] NOT NULL,
[filler3] [dbo].[smFiller] NOT NULL,
[filler4] [dbo].[smFiller] NOT NULL,
[filler5] [dbo].[smFiller] NOT NULL,
[filler6] [dbo].[smFiller] NOT NULL,
[filler7] [dbo].[smFiller] NOT NULL,
[filler8] [dbo].[smLastFiller] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amsurkey_ind_0] ON [dbo].[amsurkey] ([company_id], [key_type]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smKeyType_rl]', N'[dbo].[amsurkey].[key_type]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amsurkey].[sequence_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amsurkey].[filler1]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amsurkey].[filler2]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amsurkey].[filler3]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amsurkey].[filler4]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amsurkey].[filler5]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amsurkey].[filler6]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amsurkey].[filler7]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amsurkey].[filler8]'
GO
GRANT REFERENCES ON  [dbo].[amsurkey] TO [public]
GO
GRANT SELECT ON  [dbo].[amsurkey] TO [public]
GO
GRANT INSERT ON  [dbo].[amsurkey] TO [public]
GO
GRANT DELETE ON  [dbo].[amsurkey] TO [public]
GO
GRANT UPDATE ON  [dbo].[amsurkey] TO [public]
GO
