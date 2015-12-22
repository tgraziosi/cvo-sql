CREATE TABLE [dbo].[resource_sch]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[sch_date] [datetime] NOT NULL,
[ilevel] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[demand_date] [datetime] NOT NULL,
[demand_qty] [decimal] (20, 8) NULL,
[demand_source] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cnt] [int] NULL,
[demand_source_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_sch_date] [datetime] NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t601insressch] ON [dbo].[resource_sch] 
   FOR INSERT
AS

insert resource_avail (part_no,qty,avail_date,commit_ed,source,location,
	source_no,temp_qty,type)
	select part_no, qty, end_sch_date, 0, 'D', location,
		convert(varchar(20),cnt), 0, type from inserted
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t601updressch] ON [dbo].[resource_sch] 
  FOR UPDATE 
AS
update resource_avail 
  set resource_avail.qty=resource_avail.qty + (i.qty-d.qty) 
  from inserted i,	deleted d 
  where
	i.part_no	=d.part_no and 
	i.location	=d.location and
	i.part_no	=resource_avail.part_no and 
	resource_avail.avail_date=i.end_sch_date and 
	resource_avail.source='D' and
	resource_avail.location=i.location and 
	convert(varchar(20),i.cnt)=resource_avail.source_no
GO
CREATE UNIQUE CLUSTERED INDEX [res1] ON [dbo].[resource_sch] ([cnt]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[resource_sch] TO [public]
GO
GRANT SELECT ON  [dbo].[resource_sch] TO [public]
GO
GRANT INSERT ON  [dbo].[resource_sch] TO [public]
GO
GRANT DELETE ON  [dbo].[resource_sch] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource_sch] TO [public]
GO
