CREATE TABLE [dbo].[eft_temp]
(
[sequence] [smallint] NOT NULL,
[record_type_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addenda_count] [int] NOT NULL,
[eft_data] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cr_flag] [smallint] NULL,
[rec_length] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [eft_temp_ind_0] ON [dbo].[eft_temp] ([sequence], [record_type_code], [addenda_count]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[eft_temp] TO [public]
GO
GRANT SELECT ON  [dbo].[eft_temp] TO [public]
GO
GRANT INSERT ON  [dbo].[eft_temp] TO [public]
GO
GRANT DELETE ON  [dbo].[eft_temp] TO [public]
GO
GRANT UPDATE ON  [dbo].[eft_temp] TO [public]
GO
