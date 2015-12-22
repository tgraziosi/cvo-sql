CREATE TABLE [dbo].[rpt_recvng]
(
[receipt_no] [int] NULL,
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[recv_date] [datetime] NULL,
[part_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [float] NULL,
[unit_cost] [float] NULL,
[location] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_measure] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ext_cost] [decimal] (13, 4) NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[p_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[i_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[over_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_curr] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_factor] [decimal] (13, 4) NOT NULL,
[curr_cost] [decimal] (13, 4) NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_3] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_recvng] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_recvng] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_recvng] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_recvng] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_recvng] TO [public]
GO
