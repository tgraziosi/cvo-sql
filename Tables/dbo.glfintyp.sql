CREATE TABLE [dbo].[glfintyp]
(
[report_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[report_group] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_type] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type_group] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glfintyp_ind_0] ON [dbo].[glfintyp] ([account_type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[glfintyp] TO [public]
GO
GRANT INSERT ON  [dbo].[glfintyp] TO [public]
GO
GRANT DELETE ON  [dbo].[glfintyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[glfintyp] TO [public]
GO
