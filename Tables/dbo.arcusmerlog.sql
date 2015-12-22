CREATE TABLE [dbo].[arcusmerlog]
(
[entry_date] [timestamp] NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[object_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[target_customer] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[merged_customer] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[level] [int] NULL,
[error_code] [int] NULL,
[error_text] [varchar] (380) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[char1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[char2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[char3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[char4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[float1] [float] NULL,
[float2] [float] NULL,
[float3] [float] NULL,
[float4] [float] NULL,
[integer1] [int] NULL,
[integer2] [int] NULL,
[integer3] [int] NULL,
[integer4] [int] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[arcusmerlog] TO [public]
GO
GRANT INSERT ON  [dbo].[arcusmerlog] TO [public]
GO
GRANT DELETE ON  [dbo].[arcusmerlog] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcusmerlog] TO [public]
GO
