CREATE TABLE [dbo].[cvo_terr_scorecard]
(
[SCDate] [datetime] NULL,
[Territory_Code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Salesperson_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Stat_Year] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ActiveDoors_2400] [int] NULL,
[Active_Retn_Pct] [decimal] (18, 2) NULL,
[Active_Retn_Amt] [decimal] (20, 8) NULL,
[ReAct_Doors] [int] NULL,
[New_Doors] [int] NULL,
[Valid_ST_Orders] [int] NULL,
[Valid_ST_Orders_Amt] [decimal] (20, 8) NULL,
[Qual_Annual_Progs] [int] NULL,
[Qual_Seasonal_Progs] [int] NULL,
[Qual_RXE_Progs] [int] NULL,
[Doors_4Brands] [int] NULL,
[Net_Sales_TY] [decimal] (20, 8) NULL,
[LY_TY_Sales_Increase_Amt] [decimal] (20, 8) NULL,
[LY_TY_Sales_Incr_Pct] [decimal] (18, 2) NULL,
[Pct_to_Goal] [decimal] (18, 2) NULL,
[TY_RX_Pct] [decimal] (18, 2) NULL,
[TY_Ret_Pct] [decimal] (18, 2) NULL,
[Doors_500] [int] NULL,
[D500_Retn_Pct] [decimal] (18, 2) NULL,
[Core_Goal_Amt] [decimal] (20, 8) NULL,
[Revo_Goal_Amt] [decimal] (20, 8) NULL,
[Blutech_Goal_Amt] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [pk_terr_scorecard] ON [dbo].[cvo_terr_scorecard] ([Territory_Code], [Stat_Year]) ON [PRIMARY]
GO
