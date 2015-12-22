CREATE TABLE [dbo].[issue_code]
(
[timestamp] [timestamp] NOT NULL,
[code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inventory] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sys_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t500delissc] ON [dbo].[issue_code]   FOR DELETE AS 
begin
if exists (select * from config where flag='TRIG_DEL_ISS_CODE' and value_str='DISABLE')
	return
else
   if exists (select * from deleted where sys_code='Y')
   begin
     rollback tran
     exec adm_raiserror 73399,'You Can Not Delete A SYSTEM ISSUE CODE!' 
     return
   end
end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insissc] ON [dbo].[issue_code] 
FOR insert
AS

declare @acct varchar(10)
select @acct=isnull((select value_str from config where flag='INV_STOCK_ACCOUNT'),'STOCK')

if (select count(*) from inserted where code=@acct) > 0 begin
	rollback tran
	exec adm_raiserror 83301, 'Error - Illegal Issue Code Name.'
	return
end
return
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updissc] ON [dbo].[issue_code] 
FOR update
AS

declare @acct varchar(10)

select @acct=isnull((select value_str from config where flag='INV_STOCK_ACCOUNT'),'STOCK')

if (select count(*) from inserted where code=@acct) > 0 begin
	rollback tran
	exec adm_raiserror 93301, 'Error - Illegal Issue Code Name.'
	return
end
return
GO
CREATE UNIQUE CLUSTERED INDEX [isscode1] ON [dbo].[issue_code] ([code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[issue_code] TO [public]
GO
GRANT SELECT ON  [dbo].[issue_code] TO [public]
GO
GRANT INSERT ON  [dbo].[issue_code] TO [public]
GO
GRANT DELETE ON  [dbo].[issue_code] TO [public]
GO
GRANT UPDATE ON  [dbo].[issue_code] TO [public]
GO
