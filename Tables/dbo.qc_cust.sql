CREATE TABLE [dbo].[qc_cust]
(
[timestamp] [timestamp] NOT NULL,
[customer_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[test_key] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
CREATE UNIQUE CLUSTERED INDEX [qccust1] ON [dbo].[qc_cust] ([customer_key], [ship_to_no], [part_no], [test_key]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[qc_cust] TO [public]
GO
GRANT SELECT ON  [dbo].[qc_cust] TO [public]
GO
GRANT INSERT ON  [dbo].[qc_cust] TO [public]
GO
GRANT DELETE ON  [dbo].[qc_cust] TO [public]
GO
GRANT UPDATE ON  [dbo].[qc_cust] TO [public]
GO
