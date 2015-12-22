CREATE TABLE [dbo].[options_clude]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[feature] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[option_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[feature2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[option_part2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[include_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[include_qty] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [optclude1] ON [dbo].[options_clude] ([part_no], [feature], [option_part], [feature2], [option_part2], [include_exclude]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[options_clude] TO [public]
GO
GRANT SELECT ON  [dbo].[options_clude] TO [public]
GO
GRANT INSERT ON  [dbo].[options_clude] TO [public]
GO
GRANT DELETE ON  [dbo].[options_clude] TO [public]
GO
GRANT UPDATE ON  [dbo].[options_clude] TO [public]
GO
