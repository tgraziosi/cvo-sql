CREATE TABLE [dbo].[uom_list]
(
[timestamp] [timestamp] NOT NULL,
[uom] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t500deluom] ON [dbo].[uom_list]   FOR DELETE AS 
begin
if exists (select * from config where flag='TRIG_DEL_UOM' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 72199, 'You Can Not Delete A UOM!' 
	return
	end
end

GO
CREATE UNIQUE CLUSTERED INDEX [uom1] ON [dbo].[uom_list] ([uom]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[uom_list] TO [public]
GO
GRANT SELECT ON  [dbo].[uom_list] TO [public]
GO
GRANT INSERT ON  [dbo].[uom_list] TO [public]
GO
GRANT DELETE ON  [dbo].[uom_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[uom_list] TO [public]
GO
