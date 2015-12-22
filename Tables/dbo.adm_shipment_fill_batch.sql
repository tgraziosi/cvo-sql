CREATE TABLE [dbo].[adm_shipment_fill_batch]
(
[timestamp] [timestamp] NOT NULL,
[batch_no] [int] NOT NULL,
[batch_date] [datetime] NOT NULL CONSTRAINT [DF__adm_shipm__batch__7949E9C8] DEFAULT (getdate()),
[group_no] [int] NOT NULL CONSTRAINT [DF__adm_shipm__group__7A3E0E01] DEFAULT ((0)),
[label] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__label__7B32323A] DEFAULT (''),
[rcd_type] [int] NOT NULL CONSTRAINT [DF__adm_shipm__rcd_t__7C265673] DEFAULT ((0)),
[order_no] [int] NOT NULL CONSTRAINT [DF__adm_shipm__order__7D1A7AAC] DEFAULT ((0)),
[ext] [int] NOT NULL CONSTRAINT [DF__adm_shipmen__ext__7E0E9EE5] DEFAULT ((0)),
[cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[so_priority_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_region] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NOT NULL,
[req_ship_date] [datetime] NOT NULL,
[sch_ship_date] [datetime] NOT NULL,
[percent_fillable] [decimal] (20, 8) NOT NULL,
[curr_key] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[back_ord_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[route_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[route_no] [int] NOT NULL,
[backorders_only] [int] NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [adm_shipment_fb1] ON [dbo].[adm_shipment_fill_batch] ([batch_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_shipment_fill_batch] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_shipment_fill_batch] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_shipment_fill_batch] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_shipment_fill_batch] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_shipment_fill_batch] TO [public]
GO
