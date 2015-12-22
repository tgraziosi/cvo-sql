CREATE TABLE [dbo].[rpt_xferpick]
(
[x_xfer_no] [int] NULL,
[x_from_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_date_shipped] [datetime] NULL,
[x_date_entered] [datetime] NULL,
[x_req_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_attention] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_routing] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_special_instr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_freight] [decimal] (20, 8) NULL,
[x_to_loc_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_to_loc_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_no_pallets] [int] NULL,
[x_sch_ship_date] [datetime] NULL,
[x_req_ship_date] [datetime] NULL,
[x_freight_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_line_no] [int] NULL,
[l_lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_from_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_shipped] [decimal] (20, 8) NULL,
[l_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_comment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[l_ordered] [decimal] (20, 8) NULL,
[l_conv_factor] [decimal] (20, 8) NULL,
[lo_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lo_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b_lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[b_uom_qty] [decimal] (20, 8) NULL,
[b_bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[i_rpt_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[i_conv_factor] [decimal] (20, 8) NULL,
[x_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[v_ship_via_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[f_freight_type_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_extended_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_xferpick] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_xferpick] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_xferpick] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_xferpick] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_xferpick] TO [public]
GO
