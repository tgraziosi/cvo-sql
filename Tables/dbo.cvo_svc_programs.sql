CREATE TABLE [dbo].[cvo_svc_programs]
(
[program_id] [int] NOT NULL IDENTITY(1, 1),
[program_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[program_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[show_qty] [int] NULL,
[order_qty] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_svc_programs] ADD CONSTRAINT [PK__cvo_svc_programs__4D676AA8] PRIMARY KEY CLUSTERED  ([program_id]) ON [PRIMARY]
GO
