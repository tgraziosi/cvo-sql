CREATE TABLE [dbo].[ordList]
(
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_shipped] [datetime] NULL,
[user_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipped] [decimal] (38, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idxList] ON [dbo].[ordList] ([cust_code], [ship_to], [type], [part_no], [date_shipped]) ON [PRIMARY]
GO
