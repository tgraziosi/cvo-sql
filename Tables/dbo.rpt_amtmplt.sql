CREATE TABLE [dbo].[rpt_amtmplt]
(
[company_id] [smallint] NULL,
[template_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[template_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_new] [tinyint] NULL,
[original_cost] [real] NULL,
[acquisition_date] [datetime] NULL,
[placed_in_service_date] [datetime] NULL,
[original_in_service_date] [datetime] NULL,
[orig_quantity] [int] NULL,
[category_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_type_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[employee_code] [char] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[business_usage] [real] NULL,
[personal_usage] [real] NULL,
[investment_usage] [real] NULL,
[account_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tag] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_pledged] [tinyint] NULL,
[lease_type] [tinyint] NULL,
[is_property] [tinyint] NULL,
[linked] [tinyint] NULL,
[parent_id] [int] NULL,
[policy_number] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[classification_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[classification_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amtmplt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amtmplt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amtmplt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amtmplt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amtmplt] TO [public]
GO
