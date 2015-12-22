CREATE TABLE [dbo].[employee]
(
[timestamp] [timestamp] NOT NULL,
[kys] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[address1] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address2] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip_code] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[department] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[job_title] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t510delemp] ON [dbo].[employee] 
FOR DELETE 
AS
begin
if exists (select * from config where flag='TRIG_DEL_EMP' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 76799, 'You Can Not Delete An EMPLOYEE!' 
	return
	end
end

GO
CREATE UNIQUE CLUSTERED INDEX [emp1] ON [dbo].[employee] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[employee] TO [public]
GO
GRANT SELECT ON  [dbo].[employee] TO [public]
GO
GRANT INSERT ON  [dbo].[employee] TO [public]
GO
GRANT DELETE ON  [dbo].[employee] TO [public]
GO
GRANT UPDATE ON  [dbo].[employee] TO [public]
GO
