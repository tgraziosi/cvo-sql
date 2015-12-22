CREATE TABLE [dbo].[tdc_mis_msg_def_tbl]
(
[message] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[tdc_mis_msg_def_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[tdc_mis_msg_def_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_mis_msg_def_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_mis_msg_def_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_mis_msg_def_tbl] TO [public]
GO
