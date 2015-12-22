CREATE TABLE [dbo].[rpt_arsalcom]
(
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comm_type] [smallint] NOT NULL,
[serial_id] [smallint] NOT NULL,
[doc_date] [int] NOT NULL,
[description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[commission_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_amt] [float] NOT NULL,
[commissionable_amt] [float] NOT NULL,
[commission_adjust] [float] NOT NULL,
[net_commission] [float] NOT NULL,
[date_used] [int] NOT NULL,
[date_commission] [int] NOT NULL,
[amt_cost] [float] NOT NULL,
[base_type] [smallint] NOT NULL,
[from_bracket] [float] NOT NULL,
[to_bracket] [float] NOT NULL,
[bracket_amt] [float] NOT NULL,
[percent_flag] [float] NOT NULL,
[commissionable_amt1] [float] NOT NULL,
[commission_amt] [float] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arsalcom] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arsalcom] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arsalcom] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arsalcom] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arsalcom] TO [public]
GO
