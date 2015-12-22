CREATE TABLE [dbo].[arremit]
(
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fax] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [smallint] NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arremit1] ON [dbo].[arremit] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arremit] TO [public]
GO
GRANT SELECT ON  [dbo].[arremit] TO [public]
GO
GRANT INSERT ON  [dbo].[arremit] TO [public]
GO
GRANT DELETE ON  [dbo].[arremit] TO [public]
GO
GRANT UPDATE ON  [dbo].[arremit] TO [public]
GO
