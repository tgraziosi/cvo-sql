CREATE TABLE [dbo].[cvo_DC_RetailDashboard]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[entered_date] [datetime] NULL,
[order_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SpecialPackaging] [bit] NULL,
[KA_DueDate] [datetime] NULL,
[KA_Agent] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_DC_RetailDashboard] ADD CONSTRAINT [PK__cvo_DC_RetailDas__0AB40529] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
