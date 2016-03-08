CREATE TABLE [dbo].[cvo_eyerep_rp_tbl]
(
[rep_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rep_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_password] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[first_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email_address] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
