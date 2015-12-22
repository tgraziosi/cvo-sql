CREATE TABLE [dbo].[tdc_stage_numbers_tbl]
(
[stage_no] [char] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[active] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[creation_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_stage_numbers_tbl] ADD CONSTRAINT [PK_tdc_stage_no] PRIMARY KEY NONCLUSTERED  ([stage_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_stage_numbers_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_stage_numbers_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_stage_numbers_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_stage_numbers_tbl] TO [public]
GO
