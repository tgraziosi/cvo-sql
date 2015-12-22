SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_sp_who2] 
AS

SET NOCOUNT ON

DECLARE  @charMaxLenLoginName	varchar(6)
   	,@charMaxLenDBName	varchar(6)
 
DECLARE  @charsidlow		varchar(85)
   	,@charsidhigh		varchar(85)
   	,@charspidlow		varchar(11)
   	,@charspidhigh		varchar(11)

DECLARE	 @spidlow		int
	,@spidhigh		int

SELECT  @spidlow = 0, @spidhigh = 32767

--------------------  Capture consistent sysprocesses.  -------------------

SELECT spid, dbid, convert(sysname, rtrim(loginame)) as loginname
	INTO #tdc_sysprocesses
      		FROM master.dbo.sysprocesses (nolock)

SELECT @charspidlow  = convert(varchar, @spidlow)
SELECT @charspidhigh = convert(varchar, @spidhigh)

SELECT @charMaxLenLoginName = convert(varchar, isnull(max(datalength(loginname)), 5)),
       @charMaxLenDBName    = convert(varchar, isnull(max(datalength(convert(varchar, db_name(dbid)))), 6))
      FROM #tdc_sysprocesses
      WHERE spid >= @spidlow AND spid <= @spidhigh

--------Output the report.

EXECUTE(
'
SET NOCOUNT OFF

SELECT Login = substring(loginname, 1,' + @charMaxLenLoginName + '), DBName = substring(db_name(dbid), 1,' + @charMaxLenDBName + ')   
	FROM #tdc_sysprocesses  
		WHERE spid >= ' + @charspidlow  + '
		AND   spid <= ' + @charspidhigh + '

SET NOCOUNT ON
'
)

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[tdc_sp_who2] TO [public]
GO
