CREATE TABLE [dbo].[ord_payment]
(
[timestamp] [timestamp] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[seq_no] [int] NOT NULL,
[trx_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [datetime] NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_payment] [decimal] (20, 8) NOT NULL,
[prompt1_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt2_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt3_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt4_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_disc_taken] [decimal] (20, 8) NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ord_payment_ind_0] ON [dbo].[ord_payment] ([order_no], [order_ext], [seq_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ord_payment] TO [public]
GO
GRANT SELECT ON  [dbo].[ord_payment] TO [public]
GO
GRANT INSERT ON  [dbo].[ord_payment] TO [public]
GO
GRANT DELETE ON  [dbo].[ord_payment] TO [public]
GO
GRANT UPDATE ON  [dbo].[ord_payment] TO [public]
GO
