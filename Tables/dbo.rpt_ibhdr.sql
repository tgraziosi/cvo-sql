CREATE TABLE [dbo].[rpt_ibhdr]
(
[id] [nvarchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NOT NULL,
[date_applied] [datetime] NOT NULL,
[trx_type] [int] NULL,
[trx_type_desc] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[controlling_org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[detail_org_id] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [decimal] (20, 8) NOT NULL,
[currency_code] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [nvarchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_description] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_details] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ibhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ibhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ibhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ibhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ibhdr] TO [public]
GO
