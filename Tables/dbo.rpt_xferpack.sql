CREATE TABLE [dbo].[rpt_xferpack]
(
[x_xfer_no] [int] NULL,
[x_from_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_req_ship_date] [datetime] NULL,
[x_sch_ship_date] [datetime] NULL,
[x_date_shipped] [datetime] NULL,
[x_date_entered] [datetime] NULL,
[x_req_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_who_entered] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_attention] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_routing] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_special_instr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_fob] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_freight] [decimal] (20, 8) NULL,
[x_printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_label_no] [int] NULL,
[x_no_cartons] [int] NULL,
[x_who_shipped] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_date_printed] [datetime] NULL,
[x_who_picked] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_no_pallets] [int] NULL,
[x_shipper_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_shipper_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_shipper_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_shipper_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_shipper_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_shipper_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_shipper_zip] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_freight_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_rec_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_line_no] [int] NULL,
[l_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_ordered] [decimal] (20, 8) NULL,
[l_shipped] [decimal] (20, 8) NULL,
[l_comment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_conv_factor] [decimal] (20, 8) NULL,
[lo_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[i_rpt_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[i_conv_factor] [decimal] (20, 8) NULL,
[v_ship_via_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_back_ord_flag] [int] NOT NULL,
[l_back_ord_flag] [int] NOT NULL,
[bo_xfer_no] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_xferpack] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_xferpack] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_xferpack] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_xferpack] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_xferpack] TO [public]
GO
