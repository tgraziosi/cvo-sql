CREATE TABLE [dbo].[tdc_cyc_count_user_filter_set]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[team_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id_filter] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_tracking_type] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[no_display_rec] [int] NULL,
[update_method] [int] NOT NULL,
[no_qty_matches] [int] NULL,
[order_by_1] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_by_2] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_by_3] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_by_4] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_cyc_count_user_filter_set] ADD CONSTRAINT [PK__tdc_cyc_count_us__0BD117A9] PRIMARY KEY NONCLUSTERED  ([userid]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_cyc_count_user_filter_set] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_cyc_count_user_filter_set] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_cyc_count_user_filter_set] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_cyc_count_user_filter_set] TO [public]
GO
