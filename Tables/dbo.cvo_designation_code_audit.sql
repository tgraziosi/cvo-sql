CREATE TABLE [dbo].[cvo_designation_code_audit]
(
[audit_date] [datetime] NULL,
[audit_user] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[audit_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_reqd_changed] [smallint] NULL,
[from_start_date] [datetime] NULL,
[to_start_date] [datetime] NULL,
[from_end_date] [datetime] NULL,
[to_end_date] [datetime] NULL,
[primary_flag_changed] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_designation_code_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_designation_code_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_designation_code_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_designation_code_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_designation_code_audit] TO [public]
GO
