CREATE TABLE [dbo].[qc_detail]
(
[timestamp] [timestamp] NOT NULL,
[qc_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[test_key] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[value] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[coa] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[print_note] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pass_fail] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [qcd1] ON [dbo].[qc_detail] ([qc_no], [test_key]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[qc_detail] TO [public]
GO
GRANT SELECT ON  [dbo].[qc_detail] TO [public]
GO
GRANT INSERT ON  [dbo].[qc_detail] TO [public]
GO
GRANT DELETE ON  [dbo].[qc_detail] TO [public]
GO
GRANT UPDATE ON  [dbo].[qc_detail] TO [public]
GO
