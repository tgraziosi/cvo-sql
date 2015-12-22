CREATE TABLE [dbo].[epmchdtl]
(
[timestamp] [timestamp] NOT NULL,
[match_dtl_key] [char] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[match_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_sequence_id] [int] NOT NULL,
[receipt_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[receipt_dtl_key] [char] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company_id] [int] NOT NULL,
[qty_received] [float] NOT NULL,
[qty_invoiced] [float] NOT NULL,
[qty_prev_invoiced] [float] NOT NULL,
[amt_prev_invoiced] [float] NOT NULL,
[unit_price] [float] NOT NULL,
[invoice_unit_price] [float] NOT NULL,
[tolerance_hold_flag] [smallint] NOT NULL,
[match_posted_flag] [smallint] NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_tax_included] [float] NOT NULL,
[calc_tax] [float] NOT NULL,
[receipt_sequence_id] [int] NULL,
[amt_discount] [float] NULL CONSTRAINT [DF__epmchdtl__amt_di__5E752CA4] DEFAULT ((0)),
[amt_freight] [float] NULL CONSTRAINT [DF__epmchdtl__amt_fr__5F6950DD] DEFAULT ((0)),
[amt_misc] [float] NULL CONSTRAINT [DF__epmchdtl__amt_mi__605D7516] DEFAULT ((0)),
[amt_tax_exp] [float] NULL CONSTRAINT [DF__epmchdtl__amt_ta__6151994F] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [epmchdtl_idx_1] ON [dbo].[epmchdtl] ([account_code], [match_ctrl_num]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [epmchdtl_idx_0] ON [dbo].[epmchdtl] ([match_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [epmchdtl_m1] ON [dbo].[epmchdtl] ([po_ctrl_num], [receipt_dtl_key], [receipt_sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[epmchdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[epmchdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[epmchdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[epmchdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[epmchdtl] TO [public]
GO
