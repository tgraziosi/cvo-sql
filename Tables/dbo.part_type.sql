CREATE TABLE [dbo].[part_type]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[changed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t500delptype] ON [dbo].[part_type] 
 FOR DELETE 
AS
begin
if exists (select * from config where flag='TRIG_DEL_PTYPE' and value_str='DISABLE')
	return
else
	begin
	exec adm_raiserror 72099,'You Can Not Delete A PART TYPE!' 
	return
	end
end

GO
CREATE UNIQUE CLUSTERED INDEX [ptype1] ON [dbo].[part_type] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[part_type] TO [public]
GO
GRANT SELECT ON  [dbo].[part_type] TO [public]
GO
GRANT INSERT ON  [dbo].[part_type] TO [public]
GO
GRANT DELETE ON  [dbo].[part_type] TO [public]
GO
GRANT UPDATE ON  [dbo].[part_type] TO [public]
GO
