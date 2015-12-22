CREATE TABLE [dbo].[cust_rep]
(
[customer_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sales_comm] [decimal] (20, 8) NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[percent_flag] [int] NOT NULL CONSTRAINT [DF__cust_rep__percen__373076FA] DEFAULT ((0)),
[exclusive_flag] [int] NOT NULL CONSTRAINT [DF__cust_rep__exclus__38249B33] DEFAULT ((0)),
[split_flag] [int] NOT NULL CONSTRAINT [DF__cust_rep__split___3918BF6C] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [custrep1] ON [dbo].[cust_rep] ([customer_key], [salesperson]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cust_rep] TO [public]
GO
GRANT SELECT ON  [dbo].[cust_rep] TO [public]
GO
GRANT INSERT ON  [dbo].[cust_rep] TO [public]
GO
GRANT DELETE ON  [dbo].[cust_rep] TO [public]
GO
GRANT UPDATE ON  [dbo].[cust_rep] TO [public]
GO
