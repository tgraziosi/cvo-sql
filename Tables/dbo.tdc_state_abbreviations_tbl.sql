CREATE TABLE [dbo].[tdc_state_abbreviations_tbl]
(
[abbr] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[full_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_state_abbreviations_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_state_abbreviations_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_state_abbreviations_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_state_abbreviations_tbl] TO [public]
GO
