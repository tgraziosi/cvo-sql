CREATE TABLE [dbo].[tdc_vf_queue_tbl]
(
[consolidation_no] [int] NOT NULL,
[stage_no] [char] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_date] [datetime] NOT NULL,
[code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[station_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[priority] [int] NULL,
[status] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Pack_verify_complete] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vf_Packed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[outsource] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[tdc_vf_queue_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[tdc_vf_queue_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_vf_queue_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_vf_queue_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_vf_queue_tbl] TO [public]
GO
