CREATE TABLE [dbo].[rpt_aptxcode]
(
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_included_flag] [smallint] NOT NULL,
[override_flag] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[base_id] [int] NOT NULL,
[tax_type_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aptxcode] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aptxcode] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aptxcode] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aptxcode] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aptxcode] TO [public]
GO
