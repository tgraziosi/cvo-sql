CREATE TABLE [dbo].[adm_message_dtl]
(
[timestamp] [timestamp] NOT NULL,
[message_id] [uniqueidentifier] NOT NULL,
[dtl_typ] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dtl_typ_seq_id] [int] NOT NULL,
[dtl_value] [varchar] (7900) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dtl_flags] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sent_ind] [int] NULL,
[user_dtl_read_ind] [int] NULL,
[user_dtl_deleted_ind] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [message_td1] ON [dbo].[adm_message_dtl] ([message_id], [dtl_typ], [dtl_typ_seq_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [message_td2] ON [dbo].[adm_message_dtl] ([message_id], [dtl_typ], [sent_ind], [dtl_typ_seq_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_message_dtl] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_message_dtl] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_message_dtl] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_message_dtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_message_dtl] TO [public]
GO
