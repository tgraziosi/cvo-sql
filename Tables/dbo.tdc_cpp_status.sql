CREATE TABLE [dbo].[tdc_cpp_status]
(
[status_id] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_cpp_status] ADD CONSTRAINT [PK_tdc_cpp_status_1__16] PRIMARY KEY CLUSTERED  ([status_id], [status]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_cpp_status] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_cpp_status] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_cpp_status] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_cpp_status] TO [public]
GO
