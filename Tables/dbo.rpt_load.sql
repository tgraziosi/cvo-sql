CREATE TABLE [dbo].[rpt_load]
(
[m_load_no] [int] NULL,
[m_location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_truck_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_trailer_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_driver_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_driver_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_pro_number] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_routing] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_stop_count] [int] NULL,
[m_total_miles] [int] NULL,
[m_sch_ship_date] [datetime] NULL,
[m_date_shipped] [datetime] NULL,
[m_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_orig_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_contact_phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_invoice_type] [int] NULL,
[m_create_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_user_hold_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_credit_hold_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_picked_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_shipped_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_posted_who_nm] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_create_dt] [datetime] NULL,
[m_process_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_user_hold_dt] [datetime] NULL,
[m_credit_hold_dt] [datetime] NULL,
[m_picked_dt] [datetime] NULL,
[m_posted_dt] [datetime] NULL,
[l_load_no] [int] NULL,
[l_seq_no] [int] NULL,
[l_order_no] [int] NULL,
[l_order_ext] [int] NULL,
[l_order_list_row_id] [int] NULL,
[l_freight] [decimal] (20, 8) NULL,
[l_date_shipped] [datetime] NULL,
[o_ship_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_ship_to_add_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_ship_to_add_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_ship_to_add_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_ship_to_add_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_ship_to_add_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_ship_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_ship_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_ship_to_zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_ship_to_country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_ship_to_region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[o_total_amt_order] [decimal] (20, 8) NULL,
[o_freight] [decimal] (20, 8) NULL,
[o_special_instr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[masked_phone] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_load] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_load] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_load] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_load] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_load] TO [public]
GO
