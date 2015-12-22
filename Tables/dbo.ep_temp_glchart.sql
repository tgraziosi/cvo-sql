CREATE TABLE [dbo].[ep_temp_glchart]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type] [smallint] NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[active_dt] [datetime] NULL,
[inactive_dt] [datetime] NULL,
[modified_dt] [datetime] NULL,
[inactive_flag] [int] NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ep_temp_glchart] ADD CONSTRAINT [PK_ep_temp_glchart] PRIMARY KEY NONCLUSTERED  ([account_code]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_ep_temp_glchart] ON [dbo].[ep_temp_glchart] ([account_code], [seg1_code], [seg2_code], [seg3_code], [seg4_code], [modified_dt], [inactive_dt]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[ep_temp_glchart] TO [public]
GO
GRANT INSERT ON  [dbo].[ep_temp_glchart] TO [public]
GO
GRANT DELETE ON  [dbo].[ep_temp_glchart] TO [public]
GO
GRANT UPDATE ON  [dbo].[ep_temp_glchart] TO [public]
GO
