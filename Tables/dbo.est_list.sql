CREATE TABLE [dbo].[est_list]
(
[timestamp] [timestamp] NOT NULL,
[est_no] [int] NOT NULL,
[line_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[matl_cost] [decimal] (20, 8) NOT NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fixed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quoted_qty] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [estl1] ON [dbo].[est_list] ([est_no], [quoted_qty], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[est_list] TO [public]
GO
GRANT SELECT ON  [dbo].[est_list] TO [public]
GO
GRANT INSERT ON  [dbo].[est_list] TO [public]
GO
GRANT DELETE ON  [dbo].[est_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[est_list] TO [public]
GO
