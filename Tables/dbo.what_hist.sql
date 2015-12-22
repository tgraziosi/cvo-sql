CREATE TABLE [dbo].[what_hist]
(
[timestamp] [timestamp] NOT NULL,
[asm_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[revision] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[attrib] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[active] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bench_stock] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[eff_date] [datetime] NULL,
[date_entered] [datetime] NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[constrain] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fixed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alt_seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plan_pcs] [decimal] (20, 8) NULL,
[lag_qty] [decimal] (20, 8) NULL,
[cost_pct] [decimal] (20, 8) NULL CONSTRAINT [DF__what_hist__cost___4E157300] DEFAULT ((0)),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__what_hist__locat__4F099739] DEFAULT ('ALL'),
[pool_qty] [decimal] (20, 8) NULL CONSTRAINT [DF__what_hist__pool___4FFDBB72] DEFAULT ((1.0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [whathist1] ON [dbo].[what_hist] ([asm_no], [revision], [seq_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[what_hist] TO [public]
GO
GRANT SELECT ON  [dbo].[what_hist] TO [public]
GO
GRANT INSERT ON  [dbo].[what_hist] TO [public]
GO
GRANT DELETE ON  [dbo].[what_hist] TO [public]
GO
GRANT UPDATE ON  [dbo].[what_hist] TO [public]
GO
