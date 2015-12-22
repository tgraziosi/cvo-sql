CREATE TABLE [dbo].[rpt_amassetdetail]
(
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[acquisition_date] [datetime] NULL,
[placed_in_service_date] [datetime] NULL,
[original_in_service_date] [datetime] NULL,
[disposition_date] [datetime] NULL,
[orig_quantity] [int] NULL,
[category_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[employee_code] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[owner_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[business_usage] [float] NULL,
[personal_usage] [float] NULL,
[investment_usage] [float] NULL,
[activity_state] [tinyint] NULL,
[account_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tag] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_pledged] [tinyint] NULL,
[lease_type] [tinyint] NULL,
[is_property] [tinyint] NULL,
[depr_overridden] [tinyint] NULL,
[parent_id] [int] NULL,
[policy_number] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[linked] [tinyint] NULL,
[is_imported] [tinyint] NULL,
[manufacturer] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[serial_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_code] [varchar] (22) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contract_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[original_cost] [float] NULL,
[invoice_date] [datetime] NULL,
[vendor_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NULL,
[item_tag] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_cost] [float] NULL,
[status_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[employee_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_type_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_ctrl_num2] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_quantity] [int] NULL,
[item_disposition_date] [datetime] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amassetdetail] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amassetdetail] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amassetdetail] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amassetdetail] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amassetdetail] TO [public]
GO
