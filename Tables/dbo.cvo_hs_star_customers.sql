CREATE TABLE [dbo].[cvo_hs_star_customers]
(
[customer_id] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_date] [datetime] NULL,
[isActive] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_hs_st__isAct__24F9EE5E] DEFAULT ('ACTIVE')
) ON [PRIMARY]
GO
