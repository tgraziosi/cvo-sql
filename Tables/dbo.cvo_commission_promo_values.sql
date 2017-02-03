CREATE TABLE [dbo].[cvo_commission_promo_values]
(
[territory] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rep_code] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_commi__rep_c__33ADC193] DEFAULT (NULL),
[qty] [int] NULL CONSTRAINT [DF__cvo_commiss__qty__34A1E5CC] DEFAULT (NULL),
[incentive_amount] [decimal] (10, 2) NOT NULL,
[promo_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date] [datetime] NOT NULL,
[recorded_month] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[promo_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_commi__promo__35960A05] DEFAULT (NULL),
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_commi__comme__368A2E3E] DEFAULT (NULL),
[line_type] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_commiss_promo_t_r_m] ON [dbo].[cvo_commission_promo_values] ([territory], [rep_code], [recorded_month]) ON [PRIMARY]
GO
