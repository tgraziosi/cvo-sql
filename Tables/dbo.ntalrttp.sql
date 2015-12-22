CREATE TABLE [dbo].[ntalrttp]
(
[template_id] [int] NOT NULL IDENTITY(1, 1),
[template_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pltsql] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pltsql2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pltsql3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pltsql4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alert_email_in] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[alert_email_out] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ntalrttp_ind_1] ON [dbo].[ntalrttp] ([template_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ntalrttp] TO [public]
GO
GRANT SELECT ON  [dbo].[ntalrttp] TO [public]
GO
GRANT INSERT ON  [dbo].[ntalrttp] TO [public]
GO
GRANT DELETE ON  [dbo].[ntalrttp] TO [public]
GO
GRANT UPDATE ON  [dbo].[ntalrttp] TO [public]
GO
