CREATE TABLE [dbo].[arintdet]
(
[link] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [numeric] (18, 0) NOT NULL IDENTITY(1, 1),
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_code] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_ordered] [float] NULL,
[qty_shipped] [float] NULL,
[unit_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_price] [float] NOT NULL,
[unit_cost] [float] NULL,
[weight] [float] NULL,
[serial_id] [int] NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[disc_prc_flag] [smallint] NULL,
[discount] [float] NULL,
[iv_post_flag] [smallint] NULL,
[oe_orig_flag] [smallint] NULL,
[discount_prc] [float] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[arintdet] ADD CONSTRAINT [FK__arintdet__link__44DC4A77] FOREIGN KEY ([link]) REFERENCES [dbo].[arinthdr] ([link])
GO
GRANT REFERENCES ON  [dbo].[arintdet] TO [public]
GO
GRANT SELECT ON  [dbo].[arintdet] TO [public]
GO
GRANT INSERT ON  [dbo].[arintdet] TO [public]
GO
GRANT DELETE ON  [dbo].[arintdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[arintdet] TO [public]
GO
