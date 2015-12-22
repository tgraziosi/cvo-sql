CREATE TABLE [dbo].[EAI_svc_agr_xref]
(
[FO_svc_agr_id] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[item_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EAI_svc_agr_xref] ADD CONSTRAINT [EAI_svc_agr_xref_status_cc1] CHECK (([status]='R' OR [status]='A'))
GO
ALTER TABLE [dbo].[EAI_svc_agr_xref] ADD CONSTRAINT [EAI_svc_agr_xref_pk] PRIMARY KEY CLUSTERED  ([FO_svc_agr_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[EAI_svc_agr_xref] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_svc_agr_xref] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_svc_agr_xref] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_svc_agr_xref] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_svc_agr_xref] TO [public]
GO
