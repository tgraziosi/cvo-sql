CREATE TABLE [dbo].[ntresult]
(
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [int] NOT NULL,
[due_date] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_date] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (33) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DR] [float] NULL,
[CR] [float] NULL,
[trx_type] [smallint] NOT NULL,
[order_field] [int] NOT NULL,
[date_applied] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ntresult] TO [public]
GO
GRANT SELECT ON  [dbo].[ntresult] TO [public]
GO
GRANT INSERT ON  [dbo].[ntresult] TO [public]
GO
GRANT DELETE ON  [dbo].[ntresult] TO [public]
GO
GRANT UPDATE ON  [dbo].[ntresult] TO [public]
GO
