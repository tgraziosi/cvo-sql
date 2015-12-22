CREATE TABLE [dbo].[CVO_disassembled_frame_B2B_history_tbl]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_from] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_to] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_disassembled_frame_B2B_history_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_disassembled_frame_B2B_history_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_disassembled_frame_B2B_history_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_disassembled_frame_B2B_history_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_disassembled_frame_B2B_history_tbl] TO [public]
GO
