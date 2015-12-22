CREATE TABLE [dbo].[rpt_glseg]
(
[timestamp] [timestamp] NOT NULL,
[seg_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[short_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_flag] [smallint] NOT NULL,
[consol_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[consol_detail_flag] [smallint] NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glseg] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glseg] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glseg] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glseg] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glseg] TO [public]
GO
