CREATE TABLE [dbo].[epinvdtl]
(
[timestamp] [timestamp] NULL,
[receipt_detail_key] [char] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[receipt_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[po_sequence_id] [int] NOT NULL,
[company_id] [int] NOT NULL,
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_price] [float] NOT NULL,
[unit_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_received] [float] NOT NULL,
[qty_invoiced] [float] NOT NULL CONSTRAINT [DF__epinvdtl__qty_in__4C567C69] DEFAULT ((0)),
[amt_invoiced] [float] NOT NULL CONSTRAINT [DF__epinvdtl__amt_in__4D4AA0A2] DEFAULT ((0)),
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_closed_flag] [smallint] NOT NULL,
[invoiced_full_flag] [smallint] NOT NULL CONSTRAINT [DF__epinvdtl__invoic__4E3EC4DB] DEFAULT ((0)),
[accept_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acceptance_comment] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_tax] [float] NULL CONSTRAINT [DF__epinvdtl__amt_ta__4F32E914] DEFAULT ((0)),
[amt_discount] [float] NULL CONSTRAINT [DF__epinvdtl__amt_di__50270D4D] DEFAULT ((0)),
[amt_freight] [float] NULL CONSTRAINT [DF__epinvdtl__amt_fr__511B3186] DEFAULT ((0)),
[amt_misc] [float] NULL CONSTRAINT [DF__epinvdtl__amt_mi__520F55BF] DEFAULT ((0)),
[comment] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__epinvdtl__commen__530379F8] DEFAULT ('')
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [epinvdtl_ind_0] ON [dbo].[epinvdtl] ([receipt_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [epinvdtl_m1] ON [dbo].[epinvdtl] ([receipt_detail_key], [po_sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[epinvdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[epinvdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[epinvdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[epinvdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[epinvdtl] TO [public]
GO
