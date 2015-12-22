CREATE TABLE [dbo].[accrualsdet]
(
[timestamp] [timestamp] NOT NULL,
[accrual_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[total_amt] [float] NOT NULL,
[to_post_flag] [int] NOT NULL,
[trans_type] [int] NOT NULL,
[posted_flag] [int] NULL,
[err_description] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [accrualsdet_ind_0] ON [dbo].[accrualsdet] ([trx_ctrl_num], [trans_type], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[accrualsdet] TO [public]
GO
GRANT SELECT ON  [dbo].[accrualsdet] TO [public]
GO
GRANT INSERT ON  [dbo].[accrualsdet] TO [public]
GO
GRANT DELETE ON  [dbo].[accrualsdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[accrualsdet] TO [public]
GO
