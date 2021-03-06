CREATE TABLE [dbo].[forwarder]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fax] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[changed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [fwd1] ON [dbo].[forwarder] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[forwarder] TO [public]
GO
GRANT SELECT ON  [dbo].[forwarder] TO [public]
GO
GRANT INSERT ON  [dbo].[forwarder] TO [public]
GO
GRANT DELETE ON  [dbo].[forwarder] TO [public]
GO
GRANT UPDATE ON  [dbo].[forwarder] TO [public]
GO
