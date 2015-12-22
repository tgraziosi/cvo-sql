CREATE TABLE [dbo].[rpt_appymeth]
(
[timestamp] [timestamp] NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[on_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[next_doc_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_appymeth] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_appymeth] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_appymeth] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_appymeth] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_appymeth] TO [public]
GO
