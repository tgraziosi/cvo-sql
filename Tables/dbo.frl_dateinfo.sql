CREATE TABLE [dbo].[frl_dateinfo]
(
[gmt_offset] [float] NOT NULL,
[dst_used] [smallint] NOT NULL,
[dst_start] [datetime] NULL,
[dst_stop] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[frl_dateinfo] TO [public]
GO
GRANT SELECT ON  [dbo].[frl_dateinfo] TO [public]
GO
GRANT INSERT ON  [dbo].[frl_dateinfo] TO [public]
GO
GRANT DELETE ON  [dbo].[frl_dateinfo] TO [public]
GO
GRANT UPDATE ON  [dbo].[frl_dateinfo] TO [public]
GO
