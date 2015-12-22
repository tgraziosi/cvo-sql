CREATE TABLE [dbo].[adm_email_template_dtl]
(
[timestamp] [timestamp] NOT NULL,
[email_template_nm] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dtl_typ] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dtl_typ_seq_id] [int] NOT NULL,
[dtl_value] [varchar] (7900) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dtl_flags] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [email_td1] ON [dbo].[adm_email_template_dtl] ([email_template_nm], [dtl_typ], [dtl_typ_seq_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_email_template_dtl] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_email_template_dtl] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_email_template_dtl] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_email_template_dtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_email_template_dtl] TO [public]
GO
