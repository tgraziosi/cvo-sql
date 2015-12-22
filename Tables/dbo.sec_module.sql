CREATE TABLE [dbo].[sec_module]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ilevel] [int] NULL,
[prod_id] [int] NULL CONSTRAINT [DF__sec_modul__prod___0D3BD3DC] DEFAULT ((0)),
[rpt_flag] [int] NULL CONSTRAINT [DF__sec_modul__rpt_f__0E2FF815] DEFAULT ((0)),
[rpt_path] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rpt_type] [int] NULL CONSTRAINT [DF__sec_modul__rpt_t__0F241C4E] DEFAULT ((0)),
[form_id] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sec_mod] ON [dbo].[sec_module] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sec_module] TO [public]
GO
GRANT SELECT ON  [dbo].[sec_module] TO [public]
GO
GRANT INSERT ON  [dbo].[sec_module] TO [public]
GO
GRANT DELETE ON  [dbo].[sec_module] TO [public]
GO
GRANT UPDATE ON  [dbo].[sec_module] TO [public]
GO
