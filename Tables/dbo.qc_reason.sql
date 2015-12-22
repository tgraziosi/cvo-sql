CREATE TABLE [dbo].[qc_reason]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[step] [int] NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [qc_reas1] ON [dbo].[qc_reason] ([kys], [step]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[qc_reason] TO [public]
GO
GRANT SELECT ON  [dbo].[qc_reason] TO [public]
GO
GRANT INSERT ON  [dbo].[qc_reason] TO [public]
GO
GRANT DELETE ON  [dbo].[qc_reason] TO [public]
GO
GRANT UPDATE ON  [dbo].[qc_reason] TO [public]
GO
