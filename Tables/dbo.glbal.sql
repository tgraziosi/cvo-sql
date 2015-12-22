CREATE TABLE [dbo].[glbal]
(
[timestamp] [timestamp] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance_date] [int] NOT NULL,
[debit] [float] NOT NULL,
[credit] [float] NOT NULL,
[net_change] [float] NOT NULL,
[current_balance] [float] NOT NULL,
[balance_type] [smallint] NOT NULL,
[bal_fwd_flag] [smallint] NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_type] [smallint] NOT NULL,
[home_net_change] [float] NOT NULL,
[home_current_balance] [float] NOT NULL,
[home_debit] [float] NOT NULL,
[home_credit] [float] NOT NULL,
[balance_until] [int] NOT NULL,
[net_change_oper] [float] NULL,
[current_balance_oper] [float] NULL,
[credit_oper] [float] NULL,
[debit_oper] [float] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glbal_ind_0] ON [dbo].[glbal] ([account_code], [balance_type], [balance_date], [currency_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glbal_ind_1] ON [dbo].[glbal] ([balance_until]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glbal] TO [public]
GO
GRANT SELECT ON  [dbo].[glbal] TO [public]
GO
GRANT INSERT ON  [dbo].[glbal] TO [public]
GO
GRANT DELETE ON  [dbo].[glbal] TO [public]
GO
GRANT UPDATE ON  [dbo].[glbal] TO [public]
GO
