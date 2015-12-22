CREATE TABLE [dbo].[bol_list]
(
[timestamp] [timestamp] NOT NULL,
[bl_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_class] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_entered] [datetime] NOT NULL,
[shipped] [decimal] (20, 8) NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[misc] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[weight] [decimal] (20, 8) NULL,
[dot] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hm] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom2] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipped2] [decimal] (20, 8) NULL,
[bl_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NULL,
[conv_factor2] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [bollist1] ON [dbo].[bol_list] ([bl_no], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[bol_list] TO [public]
GO
GRANT SELECT ON  [dbo].[bol_list] TO [public]
GO
GRANT INSERT ON  [dbo].[bol_list] TO [public]
GO
GRANT DELETE ON  [dbo].[bol_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[bol_list] TO [public]
GO
