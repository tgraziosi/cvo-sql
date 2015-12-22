CREATE TABLE [dbo].[amgrpdet]
(
[timestamp] [timestamp] NOT NULL,
[group_id] [dbo].[smSurrogateKey] NOT NULL,
[sequence_id] [dbo].[smCounter] NOT NULL,
[group_text] [dbo].[smStringText] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amgrpdet_ind_0] ON [dbo].[amgrpdet] ([group_id], [sequence_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amgrpdet].[group_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amgrpdet].[sequence_id]'
GO
GRANT REFERENCES ON  [dbo].[amgrpdet] TO [public]
GO
GRANT SELECT ON  [dbo].[amgrpdet] TO [public]
GO
GRANT INSERT ON  [dbo].[amgrpdet] TO [public]
GO
GRANT DELETE ON  [dbo].[amgrpdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[amgrpdet] TO [public]
GO
