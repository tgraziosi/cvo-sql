CREATE TABLE [dbo].[adm_email_type]
(
[timestamp] [timestamp] NOT NULL,
[email_type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[active_ind] [int] NOT NULL,
[subject] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attach_results] [int] NOT NULL,
[no_header] [int] NOT NULL,
[width] [int] NOT NULL,
[echo_error] [int] NOT NULL,
[separator] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[set_user] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dbuser] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [emailt_t1] ON [dbo].[adm_email_type] ([email_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_email_type] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_email_type] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_email_type] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_email_type] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_email_type] TO [public]
GO
