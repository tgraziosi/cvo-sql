CREATE TABLE [dbo].[cmimport]
(
[spid] [smallint] NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[document_amount] [float] NULL,
[date_cleared] [int] NULL,
[data1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmimport] TO [public]
GO
GRANT SELECT ON  [dbo].[cmimport] TO [public]
GO
GRANT INSERT ON  [dbo].[cmimport] TO [public]
GO
GRANT DELETE ON  [dbo].[cmimport] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmimport] TO [public]
GO
