CREATE TABLE [dbo].[tdc_bin_group]
(
[group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_code_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bg_udef_a] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bg_udef_b] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bg_udef_c] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bg_udef_d] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bg_udef_e] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_bin_group] ADD CONSTRAINT [PK_tdc_bin_group_1__17] PRIMARY KEY CLUSTERED  ([group_code], [group_code_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bin_group] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bin_group] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bin_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bin_group] TO [public]
GO
