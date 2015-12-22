CREATE TABLE [dbo].[rpt_sal_com_hdr]
(
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comm_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[base_type] [smallint] NOT NULL,
[amt_type] [smallint] NOT NULL,
[calc_type] [smallint] NOT NULL,
[when_paid_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_sal_com_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_sal_com_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_sal_com_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_sal_com_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_sal_com_hdr] TO [public]
GO
