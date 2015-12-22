CREATE TABLE [dbo].[epcoa]
(
[guid] [char] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_dt] [datetime] NULL,
[inactive_dt] [datetime] NULL,
[active_dt] [datetime] NULL,
[deleted_dt] [datetime] NULL,
[send_inactive_flg] [int] NOT NULL CONSTRAINT [DF_epcoa_send_inactive_flag] DEFAULT ((0)),
[deleted_flg] [int] NOT NULL CONSTRAINT [DF_epcoa_inactive_flag] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[epcoa] ADD CONSTRAINT [PK_epcoa] PRIMARY KEY NONCLUSTERED  ([guid], [account_code]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_epcoa] ON [dbo].[epcoa] ([account_code], [reference_code], [modified_dt], [inactive_dt]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[epcoa] TO [public]
GO
GRANT INSERT ON  [dbo].[epcoa] TO [public]
GO
GRANT DELETE ON  [dbo].[epcoa] TO [public]
GO
GRANT UPDATE ON  [dbo].[epcoa] TO [public]
GO
