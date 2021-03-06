CREATE TABLE [dbo].[cvo_scorecard]
(
[SCDate] [datetime] NULL CONSTRAINT [DF__cvo_score__SCDat__3A2F0B42] DEFAULT (NULL),
[Terr] [int] NULL CONSTRAINT [DF__cvo_scorec__Terr__3B232F7B] DEFAULT (NULL),
[Salesperson] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_score__Sales__3C1753B4] DEFAULT (NULL),
[Stat] [int] NULL CONSTRAINT [DF__cvo_scorec__Stat__3D0B77ED] DEFAULT (NULL),
[ActiveDoors_2400] [int] NULL CONSTRAINT [DF__cvo_score__Activ__3DFF9C26] DEFAULT (NULL),
[Active_Retn_Pct] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_score__Activ__3EF3C05F] DEFAULT (NULL),
[Active_Retn_Amt] [int] NULL CONSTRAINT [DF__cvo_score__Activ__3FE7E498] DEFAULT (NULL),
[ReAct_Doors] [int] NULL CONSTRAINT [DF__cvo_score__ReAct__40DC08D1] DEFAULT (NULL),
[New_Doors] [int] NULL CONSTRAINT [DF__cvo_score__New_D__41D02D0A] DEFAULT (NULL),
[Valid_ST_Orders] [int] NULL CONSTRAINT [DF__cvo_score__Valid__42C45143] DEFAULT (NULL),
[Valid_ST_Orders_Amt] [int] NULL CONSTRAINT [DF__cvo_score__Valid__43B8757C] DEFAULT (NULL),
[Qual_Annual_Progs] [int] NULL CONSTRAINT [DF__cvo_score__Qual___44AC99B5] DEFAULT (NULL),
[Qual_Seasonal_Progs] [int] NULL CONSTRAINT [DF__cvo_score__Qual___45A0BDEE] DEFAULT (NULL),
[Qual_RXE_Progs] [int] NULL CONSTRAINT [DF__cvo_score__Qual___4694E227] DEFAULT (NULL),
[Doors_4Brands] [int] NULL CONSTRAINT [DF__cvo_score__Doors__47890660] DEFAULT (NULL),
[Net_Sales_TY] [int] NULL CONSTRAINT [DF__cvo_score__Net_S__487D2A99] DEFAULT (NULL),
[LY_TY_Sales_Increase_Amt] [int] NULL CONSTRAINT [DF__cvo_score__LY_TY__49714ED2] DEFAULT (NULL),
[LY_TY_Sales_Incr_Pct] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_score__LY_TY__4A65730B] DEFAULT (NULL),
[Pct_to_Goal] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_score__Pct_t__4B599744] DEFAULT (NULL),
[TY_RX_Pct] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_score__TY_RX__4C4DBB7D] DEFAULT (NULL),
[TY_Ret_Pct] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_score__TY_Re__4D41DFB6] DEFAULT (NULL),
[Doors_500] [int] NULL CONSTRAINT [DF__cvo_score__Doors__4E3603EF] DEFAULT (NULL),
[D500_Retn_Pct] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_score__D500___4F2A2828] DEFAULT (NULL),
[Core_Goal_Amt] [int] NULL CONSTRAINT [DF__cvo_score__Core___501E4C61] DEFAULT (NULL),
[Revo_Goal] [int] NULL CONSTRAINT [DF__cvo_score__Revo___5112709A] DEFAULT (NULL),
[Blutech_Goal] [int] NULL CONSTRAINT [DF__cvo_score__Blute__520694D3] DEFAULT (NULL)
) ON [PRIMARY]
GO
