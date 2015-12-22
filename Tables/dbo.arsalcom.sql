CREATE TABLE [dbo].[arsalcom]
(
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comm_type] [smallint] NOT NULL,
[serial_id] [smallint] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[doc_date] [int] NOT NULL,
[description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[commission_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_amt] [float] NOT NULL,
[amt_cost] [float] NOT NULL,
[commissionable_amt] [float] NOT NULL,
[commissionable] [float] NOT NULL,
[commission_adjust] [float] NOT NULL,
[net_commission] [float] NOT NULL,
[date_used] [int] NOT NULL,
[user_id] [int] NOT NULL,
[date_commission] [int] NOT NULL,
[base_type] [smallint] NOT NULL,
[table_amt_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [arsalcom_ind_1] ON [dbo].[arsalcom] ([salesperson_code], [doc_ctrl_num], [comm_type]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [arsalcom_ind_2] ON [dbo].[arsalcom] ([salesperson_code], [serial_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arsalcom] TO [public]
GO
GRANT SELECT ON  [dbo].[arsalcom] TO [public]
GO
GRANT INSERT ON  [dbo].[arsalcom] TO [public]
GO
GRANT DELETE ON  [dbo].[arsalcom] TO [public]
GO
GRANT UPDATE ON  [dbo].[arsalcom] TO [public]
GO
