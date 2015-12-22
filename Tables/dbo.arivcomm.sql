CREATE TABLE [dbo].[arivcomm]
(
[timestamp] [timestamp] NOT NULL,
[iv_commission_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[base_type] [smallint] NOT NULL,
[date_from] [int] NOT NULL,
[date_thru] [int] NOT NULL,
[exclusive_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arivcomm_ind_0] ON [dbo].[arivcomm] ([iv_commission_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arivcomm] TO [public]
GO
GRANT SELECT ON  [dbo].[arivcomm] TO [public]
GO
GRANT INSERT ON  [dbo].[arivcomm] TO [public]
GO
GRANT DELETE ON  [dbo].[arivcomm] TO [public]
GO
GRANT UPDATE ON  [dbo].[arivcomm] TO [public]
GO
