SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[z_EAI_install] AS

declare @cmd varchar(255)


if not exists (select * from master..syslogins where name = 'psqladm')
BEGIN
	declare @logindb varchar(30), @loginlang varchar(30) select @logindb = 'adm', @loginlang = null
	if @logindb is null or not exists (select * from master..sysdatabases where name = @logindb)
		select @logindb = 'master'
	if @loginlang is null or (not exists (select * from master..syslanguages where name = @loginlang) and @loginlang <> 'us_english')
		select @loginlang = @@language
	exec sp_addlogin 'psqladm', 'dRoF*Adra@HCir', @logindb, @loginlang
END


if not exists (select * from sysusers where name = 'psqladm' and uid < 16382)
	EXEC sp_adduser 'psqladm', 'psqladm', 'public'


EXEC z_EAI_install_permissions


GO
GRANT EXECUTE ON  [dbo].[z_EAI_install] TO [public]
GO
