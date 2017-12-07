SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[z_EAI_install_permissions] AS

declare @obj varchar(255)
declare @cmd varchar(255)
select @cmd = 'GRANT  DUMP TRANSACTION  TO public'
execute (@cmd)

--select 'Granting permissions to TABLES...'
select @obj=''
select @obj=isnull( (select min(name) from sysobjects where type ='U' and name>@obj),'')
while @obj>'' begin
 select @cmd = 'GRANT  SELECT ,  INSERT ,  DELETE ,  UPDATE  ON ' + @obj + '  TO public'
 execute (@cmd)
 select @obj=isnull( (select min(name) from sysobjects where type ='U' and name>@obj),'')
end

--select 'Granting permissions to VIEWS...'
select @obj=''
select @obj=isnull( (select min(name) from sysobjects where type ='V' and name>@obj),'')
while @obj > '' 
 begin
 if @obj NOT IN ('REFERENTIAL_CONSTRAINTS','CHECK_CONSTRAINTS','CONSTRAINT_TABLE_USAGE',
			 'CONSTRAINT_COLUMN_USAGE','VIEWS','VIEW_TABLE_USAGE','VIEW_COLUMN_USAGE',
			 'syssegments','sysconstraints','sysalternates','SCHEMATA','TABLES',
			 'TABLE_CONSTRAINTS','TABLE_PRIVILEGES','COLUMNS','COLUMN_DOMAIN_USAGE',
			 'COLUMN_PRIVILEGES','DOMAINS','DOMAIN_CONSTRAINTS','KEY_COLUMN_USAGE')
 begin
 select @cmd = 'GRANT  SELECT  ON ' + @obj + '  TO public'
 execute (@cmd)
 
 end
select @obj=isnull( (select min(name) from sysobjects where type ='V' and name>@obj),'')
end

--select 'Granting permissions to STORED PROCEDURES...'
select @obj=''
select @obj=isnull( (select min(name) from sysobjects where type ='P' and name>@obj and name like 'EAI%'),'')
while @obj>'' begin
 select @cmd = 'GRANT  EXECUTE  ON ' + @obj + '  TO public'

 execute (@cmd)
 select @obj=isnull( (select min(name) from sysobjects where type ='P' and name>@obj and name like 'EAI%'),'')
end

-- select 'Granting permissions to OLE Automation...'
select @obj=min(name) from master..sysobjects where type ='X' and name like 'sp_OA%'
while @obj is not null begin
 select @cmd = 'USE master GRANT EXECUTE  ON ' + @obj + '  TO public'
 execute (@cmd)
 select @obj=min(name) from master..sysobjects where type ='X' and name like 'sp_OA%' and name>@obj
end

--select 'Granting permissions complete.'
GO
GRANT EXECUTE ON  [dbo].[z_EAI_install_permissions] TO [public]
GO
