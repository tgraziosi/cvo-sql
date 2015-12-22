CREATE TABLE [dbo].[rpt_arpvcashcust]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[transfer_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arpvcashcust] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arpvcashcust] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arpvcashcust] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arpvcashcust] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arpvcashcust] TO [public]
GO
