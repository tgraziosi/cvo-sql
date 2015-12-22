CREATE TABLE [dbo].[qc_value]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[test_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[value] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pass_fail] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [qcval1] ON [dbo].[qc_value] ([part_no], [test_key], [value]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[qc_value] TO [public]
GO
GRANT SELECT ON  [dbo].[qc_value] TO [public]
GO
GRANT INSERT ON  [dbo].[qc_value] TO [public]
GO
GRANT DELETE ON  [dbo].[qc_value] TO [public]
GO
GRANT UPDATE ON  [dbo].[qc_value] TO [public]
GO
