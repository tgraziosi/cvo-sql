CREATE TABLE [dbo].[glbudimperr]
(
[spid] [smallint] NOT NULL,
[budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[error_code] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glbudimperr_ind_0] ON [dbo].[glbudimperr] ([spid], [budget_code], [account_code], [reference_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glbudimperr] TO [public]
GO
GRANT SELECT ON  [dbo].[glbudimperr] TO [public]
GO
GRANT INSERT ON  [dbo].[glbudimperr] TO [public]
GO
GRANT DELETE ON  [dbo].[glbudimperr] TO [public]
GO
GRANT UPDATE ON  [dbo].[glbudimperr] TO [public]
GO
