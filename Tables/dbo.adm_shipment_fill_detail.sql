CREATE TABLE [dbo].[adm_shipment_fill_detail]
(
[timestamp] [timestamp] NOT NULL,
[batch_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[filled] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[needed] [decimal] (20, 8) NULL,
[commit_ed] [decimal] (20, 8) NULL,
[line_no] [int] NULL,
[sch_ship_date] [datetime] NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[priority] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[picked] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [adm_shipment_fill_detail_pk] ON [dbo].[adm_shipment_fill_detail] ([batch_no], [order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_shipment_fill_detail] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_shipment_fill_detail] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_shipment_fill_detail] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_shipment_fill_detail] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_shipment_fill_detail] TO [public]
GO
