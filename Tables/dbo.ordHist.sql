CREATE TABLE [dbo].[ordHist]
(
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NULL,
[user_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipped] [decimal] (38, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idxList] ON [dbo].[ordHist] ([cust_code], [ship_to], [type], [part_no], [date_shipped]) ON [PRIMARY]
GO
