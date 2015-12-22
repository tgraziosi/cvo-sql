CREATE TABLE [dbo].[rpt_amAdditions]
(
[asset_type_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asset_ctrl_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[in_service_date] [datetime] NULL,
[original_cost] [float] NOT NULL,
[accum_depr_on_add] [float] NULL,
[total] [float] NOT NULL,
[asset_ctrl_num1] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asset_ctrl_num2] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[book_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_start] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_end] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[activity_state] [int] NOT NULL,
[is_imported] [int] NOT NULL,
[activity_state_selected] [int] NOT NULL,
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amAdditions] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amAdditions] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amAdditions] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amAdditions] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amAdditions] TO [public]
GO
