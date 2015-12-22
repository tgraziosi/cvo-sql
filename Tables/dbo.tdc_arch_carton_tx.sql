CREATE TABLE [dbo].[tdc_arch_carton_tx]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[carton_no] [int] NOT NULL,
[carton_type] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carton_class] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carrier_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipper] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NULL,
[weight] [decimal] (20, 8) NULL,
[weight_uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_tx_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_tracking_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_zone] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_oversize] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_call_tag_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_airbill_no] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_other] [money] NULL,
[cs_pickup_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cs_dim_weight] [int] NULL,
[cs_published_freight] [decimal] (20, 8) NULL,
[cs_disc_freight] [decimal] (20, 8) NULL,
[cs_estimated_freight] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_freight] [decimal] (20, 8) NULL,
[freight_to] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adjust_rate] [int] NULL,
[template_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[operator] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[consolidated_pick_no] [int] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[station_id] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[charge_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_to_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_arch___order__42623284] DEFAULT ('S'),
[stlbin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stl_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_arch___stl_s__435656BD] DEFAULT ('N'),
[changed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_arch___chang__444A7AF6] DEFAULT ('N'),
[carton_content_value] [decimal] (20, 8) NULL,
[carton_tax_value] [decimal] (20, 2) NULL,
[carton_seq] [int] NULL CONSTRAINT [DF__tdc_arch___carto__453E9F2F] DEFAULT (NULL),
[tag_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lic_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carton_cnt] [int] NULL,
[date_archived] [datetime] NULL,
[who_archived] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_arch_carton_tx] ADD CONSTRAINT [PK_tdc_arch_carton_tx] PRIMARY KEY NONCLUSTERED  ([carton_no]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [tdc_arch_carton_tx_idx_1] ON [dbo].[tdc_arch_carton_tx] ([carton_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_arch_carton_tx_idx_2] ON [dbo].[tdc_arch_carton_tx] ([order_no], [order_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_arch_carton_tx_idx_3] ON [dbo].[tdc_arch_carton_tx] ([order_no], [order_ext], [carton_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_arch_carton_tx] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_arch_carton_tx] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_arch_carton_tx] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_arch_carton_tx] TO [public]
GO
