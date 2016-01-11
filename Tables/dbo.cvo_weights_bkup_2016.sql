CREATE TABLE [dbo].[cvo_weights_bkup_2016]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[Weight_code] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[wgt] [decimal] (20, 8) NULL,
[charge] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
