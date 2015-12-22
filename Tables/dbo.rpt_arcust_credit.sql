CREATE TABLE [dbo].[rpt_arcust_credit]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message1] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message2] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message3] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message4] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message5] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message6] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_line6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcust_credit] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcust_credit] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcust_credit] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcust_credit] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcust_credit] TO [public]
GO
