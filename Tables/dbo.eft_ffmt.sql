CREATE TABLE [dbo].[eft_ffmt]
(
[timestamp] [timestamp] NOT NULL,
[file_fmt_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[file_fmt_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [eft_ffmt_ind_0] ON [dbo].[eft_ffmt] ([file_fmt_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[eft_ffmt] TO [public]
GO
GRANT SELECT ON  [dbo].[eft_ffmt] TO [public]
GO
GRANT INSERT ON  [dbo].[eft_ffmt] TO [public]
GO
GRANT DELETE ON  [dbo].[eft_ffmt] TO [public]
GO
GRANT UPDATE ON  [dbo].[eft_ffmt] TO [public]
GO
