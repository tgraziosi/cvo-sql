CREATE TABLE [dbo].[atco]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[match_receiptdate_flag] [smallint] NOT NULL,
[match_requestdate_flag] [smallint] NOT NULL,
[voprocs_invoice_taxflag] [smallint] NULL CONSTRAINT [DF__atco__voprocs_in__360813EE] DEFAULT ((1)),
[voprocs_amount_acc_expense] [smallint] NULL CONSTRAINT [DF__atco__voprocs_am__36FC3827] DEFAULT ((0)),
[tax_flag] [smallint] NULL CONSTRAINT [DF__atco__tax_flag__37F05C60] DEFAULT ((1)),
[tax_per_1line_2qty_3amt] [smallint] NULL CONSTRAINT [DF__atco__tax_per_1l__38E48099] DEFAULT ((3)),
[freight_flag] [smallint] NULL CONSTRAINT [DF__atco__freight_fl__39D8A4D2] DEFAULT ((0)),
[freight_per_1line_2qty_3amt] [smallint] NULL CONSTRAINT [DF__atco__freight_pe__3ACCC90B] DEFAULT ((3)),
[disc_flag] [smallint] NULL CONSTRAINT [DF__atco__disc_flag__3BC0ED44] DEFAULT ((0)),
[disc_per_1line_2qty_3amt] [smallint] NULL CONSTRAINT [DF__atco__disc_per_1__3CB5117D] DEFAULT ((3)),
[misc_flag] [smallint] NULL CONSTRAINT [DF__atco__misc_flag__3DA935B6] DEFAULT ((0)),
[misc_per_1line_2qty_3amt] [smallint] NULL CONSTRAINT [DF__atco__misc_per_1__3E9D59EF] DEFAULT ((3))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [atco_ind_0] ON [dbo].[atco] ([company_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[atco] TO [public]
GO
GRANT SELECT ON  [dbo].[atco] TO [public]
GO
GRANT INSERT ON  [dbo].[atco] TO [public]
GO
GRANT DELETE ON  [dbo].[atco] TO [public]
GO
GRANT UPDATE ON  [dbo].[atco] TO [public]
GO
