CREATE TABLE [dbo].[ntalrtls]
(
[alert_id] [int] NOT NULL IDENTITY(1, 1),
[user_id] [int] NOT NULL,
[alert_template_id] [int] NOT NULL,
[next_test] [datetime] NOT NULL,
[next_test_sql] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_test_desc] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sql_text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sql_text2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sql_text3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sql_text4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alert_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[email_target] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[email_cc] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email_text_in] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[email_text_out] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email_subject] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[alert_description] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create trigger [dbo].[ntalrtls_del] on [dbo].[ntalrtls] for delete as
	delete ntalrtvl
	from ntalrtvl v, deleted d
	where v.alert_id = d.alert_id

GO
ALTER TABLE [dbo].[ntalrtls] ADD CONSTRAINT [CK__ntalrtls__alert___6AB9714A] CHECK (([alert_type]='F' OR [alert_type]='T' OR [alert_type]='S' OR [alert_type]='R'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [ntalrtls_ind_1] ON [dbo].[ntalrtls] ([alert_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ntalrtls] TO [public]
GO
GRANT SELECT ON  [dbo].[ntalrtls] TO [public]
GO
GRANT INSERT ON  [dbo].[ntalrtls] TO [public]
GO
GRANT DELETE ON  [dbo].[ntalrtls] TO [public]
GO
GRANT UPDATE ON  [dbo].[ntalrtls] TO [public]
GO
