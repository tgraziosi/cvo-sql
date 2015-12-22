CREATE TABLE [dbo].[cc_ord_status]
(
[status_code] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_desc] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[use_flag] [int] NOT NULL,
[include_credit_returns] [smallint] NOT NULL CONSTRAINT [DF__cc_ord_st__inclu__50896205] DEFAULT ((0))
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_ord_status] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_ord_status] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_ord_status] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_ord_status] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_ord_status] TO [public]
GO
