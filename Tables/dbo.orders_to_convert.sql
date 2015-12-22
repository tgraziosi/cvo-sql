CREATE TABLE [dbo].[orders_to_convert]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[order_no] [int] NULL,
[order_ext] [int] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[has_sa] [int] NULL,
[bo_hold] [int] NULL,
[case_issue] [int] NULL,
[is_allocated] [int] NULL,
[complete] [int] NULL,
[sch_ship_date] [datetime] NULL
) ON [PRIMARY]
GO
