CREATE TABLE [dbo].[cvo_masterpack_consolidation_hdr]
(
[consolidation_no] [int] NOT NULL,
[type] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carrier] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_date] [datetime] NULL,
[closed] [smallint] NOT NULL,
[shipped] [smallint] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_masterpack_consolidation_hdr_pk] ON [dbo].[cvo_masterpack_consolidation_hdr] ([consolidation_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_masterpack_consolidation_hdr_inx01] ON [dbo].[cvo_masterpack_consolidation_hdr] ([type], [cust_code], [ship_to], [carrier], [ship_date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_masterpack_consolidation_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_masterpack_consolidation_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_masterpack_consolidation_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_masterpack_consolidation_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_masterpack_consolidation_hdr] TO [public]
GO
