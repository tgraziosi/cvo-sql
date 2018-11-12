CREATE TABLE [dbo].[cvo_dc_refurb_activity]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[activity_date] [datetime] NULL CONSTRAINT [DF__cvo_dc_re__activ__7303CF02] DEFAULT (getdate()),
[resource_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_processed] [int] NULL,
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_qc_failed] [int] NULL,
[isActive] [tinyint] NULL CONSTRAINT [DF__cvo_dc_re__isAct__70E67C66] DEFAULT ('1')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_dc_refurb_activity] ADD CONSTRAINT [PK__cvo_dc_refurb_ac__720FAAC9] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
