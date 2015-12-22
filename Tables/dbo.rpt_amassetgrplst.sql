CREATE TABLE [dbo].[rpt_amassetgrplst]
(
[company_id] [smallint] NULL,
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[asset_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[timestamp] [timestamp] NULL,
[modified_by] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amassetgrplst] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amassetgrplst] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amassetgrplst] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amassetgrplst] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amassetgrplst] TO [public]
GO
