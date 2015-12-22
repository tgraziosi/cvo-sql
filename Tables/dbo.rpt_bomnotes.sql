CREATE TABLE [dbo].[rpt_bomnotes]
(
[w_asm_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_who_entered] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_seq_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_attrib] [decimal] (20, 8) NULL,
[w_active] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_bench_stock] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_eff_date] [datetime] NULL,
[w_date_entered] [datetime] NULL,
[i_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_conv_factor] [decimal] (20, 8) NULL,
[w_constrain] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_fixed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_qty] [decimal] (20, 8) NULL,
[w_alt_seq_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_note2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_note3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_note4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[w_notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_bomnotes] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_bomnotes] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_bomnotes] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_bomnotes] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_bomnotes] TO [public]
GO
