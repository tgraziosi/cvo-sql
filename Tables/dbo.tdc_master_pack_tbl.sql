CREATE TABLE [dbo].[tdc_master_pack_tbl]
(
[pack_no] [int] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[create_date] [datetime] NOT NULL,
[created_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[carrier_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[weight] [decimal] (20, 8) NULL,
[name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_tx_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_tracking_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_zone] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_oversize] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_call_tag_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_airbill_no] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_other] [money] NULL,
[cs_pickup_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_dim_weight] [decimal] (20, 8) NULL,
[cs_published_freight] [decimal] (20, 8) NULL,
[cs_disc_freight] [decimal] (20, 8) NULL,
[cs_estimated_freight] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NULL,
[freight_to] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_freight] [decimal] (20, 8) NULL,
[adjust_rate] [int] NULL,
[charge_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[template_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SSCC] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tag_type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[epc_tag] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SGTIN] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_master_pack_tbl_idx1] ON [dbo].[tdc_master_pack_tbl] ([pack_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_master_pack_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_master_pack_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_master_pack_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_master_pack_tbl] TO [public]
GO
