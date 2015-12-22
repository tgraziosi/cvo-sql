CREATE TABLE [dbo].[tdc_pick_ticket]
(
[cons_no] [int] NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ord_qty] [decimal] (20, 8) NOT NULL,
[pick_qty] [decimal] (20, 8) NOT NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_date] [datetime] NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sch_ship_date] [datetime] NULL,
[carrier_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[special_instr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[kit_caption] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cancel_date] [datetime] NULL,
[kit_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_code_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq_no] [int] NULL,
[tran_id] [int] NULL,
[dest_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_ticket_inx2] ON [dbo].[tdc_pick_ticket] ([order_no], [order_ext], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_ticket_inx1] ON [dbo].[tdc_pick_ticket] ([order_no], [order_ext], [location], [user_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pick_ticket] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pick_ticket] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pick_ticket] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pick_ticket] TO [public]
GO
