CREATE TABLE [dbo].[phy_hdr]
(
[timestamp] [timestamp] NOT NULL,
[phy_batch] [int] NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sort_type] [int] NOT NULL,
[date_init] [datetime] NOT NULL,
[date_closed] [datetime] NULL,
[who_init] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_closed] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[phyhupd700t] ON [dbo].[phy_hdr] 
FOR UPDATE
AS

if update( status ) begin
   update physical set close_flag='V'
   from inserted i, physical
   where i.phy_batch=physical.phy_batch and i.status='V' and
         physical.close_flag<>'Y'
end


GO
CREATE UNIQUE CLUSTERED INDEX [phyh1] ON [dbo].[phy_hdr] ([phy_batch]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[phy_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[phy_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[phy_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[phy_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[phy_hdr] TO [public]
GO
