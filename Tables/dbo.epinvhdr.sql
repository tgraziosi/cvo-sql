CREATE TABLE [dbo].[epinvhdr]
(
[timestamp] [timestamp] NULL,
[receipt_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_accepted] [int] NOT NULL,
[company_id] [int] NOT NULL,
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ref_name] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[credit_card_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[validated_flag] [smallint] NOT NULL CONSTRAINT [DF__epinvhdr__valida__55DFE6A3] DEFAULT ((0)),
[hold_flag] [smallint] NOT NULL CONSTRAINT [DF__epinvhdr__hold_f__56D40ADC] DEFAULT ((0)),
[invoiced_full_flag] [smallint] NOT NULL CONSTRAINT [DF__epinvhdr__invoic__57C82F15] DEFAULT ((0)),
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_home] [float] NULL,
[rate_oper] [float] NULL,
[comment] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_tax] [float] NULL CONSTRAINT [DF__epinvhdr__amt_ta__58BC534E] DEFAULT ((0)),
[amt_discount] [float] NULL CONSTRAINT [DF__epinvhdr__amt_di__59B07787] DEFAULT ((0)),
[amt_freight] [float] NULL CONSTRAINT [DF__epinvhdr__amt_fr__5AA49BC0] DEFAULT ((0)),
[amt_misc] [float] NULL CONSTRAINT [DF__epinvhdr__amt_mi__5B98BFF9] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [epinvhdr_m1] ON [dbo].[epinvhdr] ([po_ctrl_num], [invoiced_full_flag]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [epinvhdr_ind_0] ON [dbo].[epinvhdr] ([receipt_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [epinvhdr_ind_2] ON [dbo].[epinvhdr] ([receipt_ctrl_num], [date_accepted]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [epinvhdr_ind_1] ON [dbo].[epinvhdr] ([receipt_ctrl_num], [vendor_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[epinvhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[epinvhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[epinvhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[epinvhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[epinvhdr] TO [public]
GO
