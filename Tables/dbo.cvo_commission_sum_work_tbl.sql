CREATE TABLE [dbo].[cvo_commission_sum_work_tbl]
(
[salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hiredate] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [money] NULL,
[comm_amt] [money] NULL,
[draw_amount] [decimal] (14, 2) NULL,
[commission] [decimal] (5, 2) NOT NULL,
[incentivePC] [int] NOT NULL,
[incentive] [numeric] (22, 6) NULL,
[other_additions] [int] NOT NULL,
[reduction] [int] NOT NULL,
[addition_rsn] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reduction_rsn] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
