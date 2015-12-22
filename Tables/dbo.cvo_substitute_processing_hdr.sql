CREATE TABLE [dbo].[cvo_substitute_processing_hdr]
(
[spid] [int] NOT NULL,
[replacement_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_required] [decimal] (20, 8) NOT NULL,
[qty_available] [decimal] (20, 8) NOT NULL,
[qty_assigned] [decimal] (20, 8) NOT NULL,
[qty_unassigned] [decimal] (20, 8) NOT NULL,
[qty_remaining] [decimal] (20, 8) NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_substitute_processing_hdr_pk] ON [dbo].[cvo_substitute_processing_hdr] ([spid]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_substitute_processing_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_substitute_processing_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_substitute_processing_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_substitute_processing_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_substitute_processing_hdr] TO [public]
GO
