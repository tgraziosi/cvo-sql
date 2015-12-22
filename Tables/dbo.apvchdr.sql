CREATE TABLE [dbo].[apvchdr]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[state_flag] [smallint] NOT NULL,
[void_flag] [smallint] NOT NULL,
[amt_net] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[user_id] [smallint] NOT NULL,
[print_batch_num] [int] NOT NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apvchdr_ind_0] ON [dbo].[apvchdr] ([doc_ctrl_num], [cash_acct_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apvchdr] TO [public]
GO
GRANT SELECT ON  [dbo].[apvchdr] TO [public]
GO
GRANT INSERT ON  [dbo].[apvchdr] TO [public]
GO
GRANT DELETE ON  [dbo].[apvchdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvchdr] TO [public]
GO
