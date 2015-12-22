CREATE TABLE [dbo].[arduncus]
(
[timestamp] [timestamp] NOT NULL,
[control_id] [int] NOT NULL IDENTITY(1, 1),
[dunning_doc_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_generated] [int] NOT NULL,
[date_printed] [int] NOT NULL CONSTRAINT [DF__arduncus__date_p__632BC76D] DEFAULT ((0)),
[generated_by] [smallint] NOT NULL,
[printed_by] [smallint] NOT NULL,
[max_dunning_level] [int] NOT NULL,
[dunning_group_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_fin_chg] [smallint] NOT NULL,
[print_fin_only] [smallint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[arduncus] ADD CONSTRAINT [PK__arduncus__6237A334] PRIMARY KEY CLUSTERED  ([control_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arduncus_01] ON [dbo].[arduncus] ([customer_code], [nat_cur_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arduncus] TO [public]
GO
GRANT SELECT ON  [dbo].[arduncus] TO [public]
GO
GRANT INSERT ON  [dbo].[arduncus] TO [public]
GO
GRANT DELETE ON  [dbo].[arduncus] TO [public]
GO
GRANT UPDATE ON  [dbo].[arduncus] TO [public]
GO
