CREATE TABLE [dbo].[CVO_Promo_Overrides_SSRS]
(
[Terr] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Order_no] [int] NOT NULL,
[Status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Req_Ship_Date] [datetime] NOT NULL,
[Promo_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Promo_Level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OrgPcsOrd] [decimal] (12, 0) NULL,
[OverrideDate] [datetime] NOT NULL,
[Override_User] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Failure_Reason] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
