CREATE TABLE [dbo].[rpt_epmchhdr]
(
[match_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vaddr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_remit_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[paddr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paddr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_id] [int] NOT NULL,
[company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_invoice_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_match] [int] NOT NULL,
[tolerance_hold_flag] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tolerance_approval_flag] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[validated_flag] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_net] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_misc] [float] NOT NULL,
[match_posted_flag] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[groupby] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_epmchhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_epmchhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_epmchhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_epmchhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_epmchhdr] TO [public]
GO
