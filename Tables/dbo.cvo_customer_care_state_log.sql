CREATE TABLE [dbo].[cvo_customer_care_state_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[agent] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ext] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[agent_state] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state_change] [datetime] NULL,
[log_date] [datetime] NULL,
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_customer_care_state_log] ADD CONSTRAINT [PK__cvo_customer_car__712FC9D2] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
