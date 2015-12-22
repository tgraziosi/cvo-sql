CREATE TABLE [dbo].[rpt_aprptchk]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [datetime] NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_payment] [float] NOT NULL,
[company_logo_id] [int] NOT NULL,
[signature_id] [int] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[print_batch_num] [int] NOT NULL,
[vend_acct] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[extra_copy] [smallint] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aprptchk] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aprptchk] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aprptchk] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aprptchk] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aprptchk] TO [public]
GO
