CREATE TABLE [dbo].[glchart_history]
(
[guid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[active_date] [int] NULL,
[inactive_date] [int] NULL,
[status] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [hist_index1] ON [dbo].[glchart_history] ([account_code], [reference_code], [reference_type]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [hist_index2] ON [dbo].[glchart_history] ([guid]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[glchart_history] TO [public]
GO
GRANT INSERT ON  [dbo].[glchart_history] TO [public]
GO
GRANT DELETE ON  [dbo].[glchart_history] TO [public]
GO
GRANT UPDATE ON  [dbo].[glchart_history] TO [public]
GO
