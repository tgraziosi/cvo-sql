CREATE TABLE [dbo].[uom_table]
(
[timestamp] [timestamp] NOT NULL,
[item] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[std_uom] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[alt_uom] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[conv_factor] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t500deluomt] ON [dbo].[uom_table]   FOR DELETE AS 
begin
if exists (select * from config where flag='TRIG_DEL_CONVF' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 72299, 'You Can Not Delete A UOM CONVERSION FACTOR!' 
	return
	end
end

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t55upduomt] ON [dbo].[uom_table] FOR UPDATE AS 
begin
if exists (select * from config where flag='TRIG_UPD_UOM' and value_str='DISABLE') begin
	return
end
rollback tran
exec adm_raiserror 92231 ,'You Cannot Update UOM Conversions.'
return
end

GO
CREATE UNIQUE CLUSTERED INDEX [uomconv1] ON [dbo].[uom_table] ([item], [std_uom], [alt_uom]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[uom_table] TO [public]
GO
GRANT SELECT ON  [dbo].[uom_table] TO [public]
GO
GRANT INSERT ON  [dbo].[uom_table] TO [public]
GO
GRANT DELETE ON  [dbo].[uom_table] TO [public]
GO
GRANT UPDATE ON  [dbo].[uom_table] TO [public]
GO
