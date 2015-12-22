CREATE TABLE [dbo].[cust_log]
(
[timestamp] [timestamp] NOT NULL,
[customer_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [custlog1] ON [dbo].[cust_log] ([customer_key], [date_entered]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cust_log] TO [public]
GO
GRANT SELECT ON  [dbo].[cust_log] TO [public]
GO
GRANT INSERT ON  [dbo].[cust_log] TO [public]
GO
GRANT DELETE ON  [dbo].[cust_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[cust_log] TO [public]
GO
