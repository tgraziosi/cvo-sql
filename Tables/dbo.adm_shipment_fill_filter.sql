CREATE TABLE [dbo].[adm_shipment_fill_filter]
(
[timestamp] [timestamp] NOT NULL,
[batch_name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rcd_type] [int] NOT NULL CONSTRAINT [DF__adm_shipm__rcd_t__02D35402] DEFAULT ((1)),
[rcd_ord] [int] NOT NULL CONSTRAINT [DF__adm_shipm__rcd_o__03C7783B] DEFAULT ((0)),
[selection_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_date] [datetime] NOT NULL CONSTRAINT [DF__adm_shipm__batch__04BB9C74] DEFAULT (getdate()),
[who_created] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__who_c__05AFC0AD] DEFAULT (''),
[last_user] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__last___06A3E4E6] DEFAULT (''),
[group_ind] [int] NOT NULL CONSTRAINT [DF__adm_shipm__group__0798091F] DEFAULT ((0)),
[sort_order] [int] NOT NULL CONSTRAINT [DF__adm_shipm__sort___088C2D58] DEFAULT ((0)),
[sort_desc_ind] [int] NOT NULL CONSTRAINT [DF__adm_shipm__sort___09805191] DEFAULT ((0)),
[selection_ind] [int] NOT NULL CONSTRAINT [DF__adm_shipm__selec__0A7475CA] DEFAULT ((1)),
[start_value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__start__0B689A03] DEFAULT ((1)),
[stop_value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__stop___0C5CBE3C] DEFAULT ((1)),
[show_edits_ind] [int] NOT NULL CONSTRAINT [DF__adm_shipm__show___0D50E275] DEFAULT ((1)),
[data_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__data___0E4506AE] DEFAULT ('C'),
[batch_no] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_adm_shipment_fill_filter] ON [dbo].[adm_shipment_fill_filter] ([batch_name], [rcd_type], [selection_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_shipment_fill_filter] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_shipment_fill_filter] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_shipment_fill_filter] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_shipment_fill_filter] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_shipment_fill_filter] TO [public]
GO
