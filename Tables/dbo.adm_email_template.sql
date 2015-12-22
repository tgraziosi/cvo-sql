CREATE TABLE [dbo].[adm_email_template]
(
[timestamp] [timestamp] NOT NULL,
[email_template_nm] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[email_type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[active_ind] [int] NOT NULL,
[start_dt] [datetime] NULL,
[end_dt] [datetime] NULL,
[subject] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attach_results] [int] NOT NULL,
[no_header] [int] NOT NULL,
[width] [int] NOT NULL,
[echo_error] [int] NOT NULL,
[separator] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[set_user] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dbuser] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[exp_days] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [email_t1] ON [dbo].[adm_email_template] ([email_template_nm]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_email_template] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_email_template] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_email_template] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_email_template] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_email_template] TO [public]
GO
