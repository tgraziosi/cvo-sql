CREATE TABLE [dbo].[qc_test]
(
[timestamp] [timestamp] NOT NULL,
[kys] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[units] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[test_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_val] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[max_val] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[target] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[coa] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[print_note] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [qctest1] ON [dbo].[qc_test] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[qc_test] TO [public]
GO
GRANT SELECT ON  [dbo].[qc_test] TO [public]
GO
GRANT INSERT ON  [dbo].[qc_test] TO [public]
GO
GRANT DELETE ON  [dbo].[qc_test] TO [public]
GO
GRANT UPDATE ON  [dbo].[qc_test] TO [public]
GO
