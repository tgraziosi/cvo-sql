CREATE TABLE [dbo].[apmchhdr]
(
[timestamp] [timestamp] NOT NULL,
[match_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[match_ctrl_int] [int] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_remit_to] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_invoice_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_match] [int] NOT NULL,
[tolerance_hold_flag] [smallint] NOT NULL,
[tolerance_approval_flag] [smallint] NOT NULL,
[awaiting_receipt_flag] [smallint] NOT NULL,
[printed_flag] [smallint] NOT NULL,
[vendor_invoice_date] [int] NOT NULL,
[invoice_receive_date] [int] NOT NULL,
[apply_date] [int] NOT NULL,
[aging_date] [int] NOT NULL,
[due_date] [int] NOT NULL,
[discount_date] [int] NOT NULL,
[amt_net] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_misc] [float] NOT NULL,
[amt_due] [float] NOT NULL,
[match_posted_flag] [smallint] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_tax_included] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apmchhdr_idx_0] ON [dbo].[apmchhdr] ([match_ctrl_int]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [apmchhdr_idx_1] ON [dbo].[apmchhdr] ([match_ctrl_int], [vendor_code], [vendor_invoice_no]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [apmchhdr_idx_2] ON [dbo].[apmchhdr] ([match_ctrl_num]) WITH (FILLFACTOR=50) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[apmchhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[apmchhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[apmchhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[apmchhdr] TO [public]
GO
