CREATE TABLE [dbo].[prrptmgh]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [datetime] NULL,
[end_date] [datetime] NULL,
[type] [int] NULL,
[total_extended] [float] NULL,
[total_cost] [float] NULL,
[total_rebate] [float] NULL,
[total_margin] [float] NULL,
[mem_type] [smallint] NULL,
[type_str] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prrptmgh] TO [public]
GO
GRANT SELECT ON  [dbo].[prrptmgh] TO [public]
GO
GRANT INSERT ON  [dbo].[prrptmgh] TO [public]
GO
GRANT DELETE ON  [dbo].[prrptmgh] TO [public]
GO
GRANT UPDATE ON  [dbo].[prrptmgh] TO [public]
GO
