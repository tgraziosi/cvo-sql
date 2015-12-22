CREATE TABLE [dbo].[new_price]
(
[timestamp] [timestamp] NOT NULL,
[kys] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price_level] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_amt] [decimal] (20, 8) NOT NULL,
[new_direction] [int] NOT NULL,
[eff_date] [datetime] NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NULL,
[reason] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[curr_key] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_level] [int] NULL,
[loc_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [newprice1] ON [dbo].[new_price] ([kys], [part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[new_price] TO [public]
GO
GRANT SELECT ON  [dbo].[new_price] TO [public]
GO
GRANT INSERT ON  [dbo].[new_price] TO [public]
GO
GRANT DELETE ON  [dbo].[new_price] TO [public]
GO
GRANT UPDATE ON  [dbo].[new_price] TO [public]
GO
