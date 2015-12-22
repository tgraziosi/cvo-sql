CREATE TABLE [dbo].[tdc_main]
(
[consolidation_no] [int] NOT NULL,
[consolidation_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[created_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[creation_date] [datetime] NULL,
[filter_name_used] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[virtual_freight] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_tdc_dsf_mai_Virtual_Fre] DEFAULT ('N'),
[pre_pack] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_main__pre_pa__71DC3B7C] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_main] ADD CONSTRAINT [PK_tdc_dsf_main_1__12] PRIMARY KEY CLUSTERED  ([consolidation_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_main] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_main] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_main] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_main] TO [public]
GO
