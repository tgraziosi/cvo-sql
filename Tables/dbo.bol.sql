CREATE TABLE [dbo].[bol]
(
[timestamp] [timestamp] NOT NULL,
[bl_no] [int] NOT NULL,
[bl_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bl_src_no] [int] NOT NULL,
[bl_src_ext] [int] NOT NULL,
[bill_to_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bill_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bill_to_add_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_to_add_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bill_to_zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[routing] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[routing_desc] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[no_packages] [int] NOT NULL,
[cod_amount] [money] NOT NULL,
[date_shipped] [datetime] NULL,
[po_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[skids] [int] NOT NULL,
[ship_to_region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tare_wt] [decimal] (20, 8) NOT NULL,
[freight_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[ship_to_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [bol1] ON [dbo].[bol] ([bl_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[bol] TO [public]
GO
GRANT SELECT ON  [dbo].[bol] TO [public]
GO
GRANT INSERT ON  [dbo].[bol] TO [public]
GO
GRANT DELETE ON  [dbo].[bol] TO [public]
GO
GRANT UPDATE ON  [dbo].[bol] TO [public]
GO
