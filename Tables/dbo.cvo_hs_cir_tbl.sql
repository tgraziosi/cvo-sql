CREATE TABLE [dbo].[cvo_hs_cir_tbl]
(
[customer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mastersku] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[st_units] [float] NULL,
[rx_units] [float] NULL,
[ret_units] [float] NULL,
[first_st] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_st] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CL] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RYG] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[size] [int] NULL,
[color] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
