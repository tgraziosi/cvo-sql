SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_who]  --1995/11/03 10:16
    @loginame     varchar(30) = NULL, @dbname varchar(30) = NULL
as

declare @dbid int
set nocount on
if @dbname is null begin
   Select @dbname = '%'
end
if @dbname != '%' begin
   Select @dbid = db_id( @dbname )
end
if @loginame = '%' begin
   Select @loginame = null
end
declare
    @retcode         int
   ,@max_suid_spid   int
   ,@int1            int
declare
    @suidlow         int
   ,@suidhigh        int
   ,@spidlow         int
   ,@spidhigh        int
declare
    @charMaxLenLoginName      varchar(6)
   ,@charMaxLenDBName         varchar(6)
   ,@charMaxLenCPUTime        varchar(10)
   ,@charMaxLenDiskIO         varchar(10)
   ,@charMaxLenHostName       varchar(10)
   ,@charMaxLenProgramName    varchar(10)
   ,@charMaxLenLastBatch      varchar(10)
   ,@charMaxLenCommand        varchar(10)
declare
    @charsuidlow              varchar(11)
   ,@charsuidhigh             varchar(11)
   ,@charspidlow              varchar(11)
   ,@charspidhigh             varchar(11)
--------
select
    @retcode         = 0      -- 0=good ,1=bad.
   ,@max_suid_spid   = 32767
--------defaults
select
    @suidlow         = 0
   ,@suidhigh        = @max_suid_spid
   ,@spidlow         = 0
   ,@spidhigh        = @max_suid_spid
--------------------------------------------------------------
IF (@loginame IS     NULL)  --Simple default to all LoginNames.
      GOTO LABEL_17PARM1EDITED
--------
select @int1 = suser_sid(@loginame)
IF (@int1 IS NOT NULL)  --Parm is a recognized login name.
   begin
   select @suidlow  = suser_sid(@loginame)
         ,@suidhigh = suser_sid(@loginame)
   GOTO LABEL_17PARM1EDITED
   end
--------
IF (lower(@loginame) IN ('active'))  --Special action, not sleeping.
   begin
   select @loginame = lower(@loginame)
   GOTO LABEL_17PARM1EDITED
   end
--------
IF (patindex ('%[^0-9]%' , isnull(@loginame,'z')) = 0)  --Is a number.
   begin
   select
             @spidlow   = convert(int, @loginame)
            ,@spidhigh  = convert(int, @loginame)
   GOTO LABEL_17PARM1EDITED
   end
--------
RaisError(15007,-1,-1,@loginame)
select @retcode = 1
GOTO LABEL_86RETURN
LABEL_17PARM1EDITED:
--------------------  Capture consistent sysprocesses.  -------------------
SELECT
  spid
 ,kpid
 ,status
 ,sid
 ,hostname
 ,program_name
 ,hostprocess
 ,cmd
 ,cpu
 ,physical_io
 ,memusage
 ,blocked
 ,waittype
 ,dbid
 ,uid
 ,' ' 'gid'
 ,login_time
 ,last_batch
 ,nt_domain
 ,nt_username
 ,net_address
 ,net_library
 ,spid as 'spid_sort'
 ,  substring( convert(varchar,last_batch,111) ,6  ,5 ) + ' '
  + substring( convert(varchar,last_batch,113) ,13 ,8 )
       as 'last_batch_char'

      INTO    #tb1_sysprocesses
      from master..sysprocesses   (nolock)
where dbid = @dbid
--------Screen out any rows?
IF (@loginame IN ('active'))
   DELETE #tb1_sysprocesses
         where   lower(status)  = 'sleeping'
         and     upper(cmd)    IN (
                     'AWAITING COMMAND'
                    ,'MIRROR HANDLER'
                    ,'LAZY WRITER'
                    ,'CHECKPOINT SLEEP'
                    ,'RA MANAGER'
                                  )
         and     blocked       = 0
--------Prepare to dynamically optimize column widths.
Select
    @charsuidlow     = convert(varchar,@suidlow)
   ,@charsuidhigh    = convert(varchar,@suidhigh)
   ,@charspidlow     = convert(varchar,@spidlow)
   ,@charspidhigh    = convert(varchar,@spidhigh)
SELECT
             @charMaxLenLoginName =
                  convert( varchar
                          ,isnull( max( datalength( convert(varchar,suser_sname(sid)))) ,5)
                         )
            ,@charMaxLenDBName    =
                  convert( varchar
                          ,isnull( max( datalength( convert(varchar,db_name(dbid)))) ,6)
                         )
            ,@charMaxLenCPUTime   =
                  convert( varchar
                          ,isnull( max( datalength( convert(varchar,cpu))) ,7)
                         )
            ,@charMaxLenDiskIO    =
                  convert( varchar
                          ,isnull( max( datalength( convert(varchar,physical_io))) ,6)
                         )
            ,@charMaxLenCommand  =
                  convert( varchar
                          ,isnull( max( datalength( convert(varchar,cmd))) ,7)
                         )
            ,@charMaxLenHostName  =
                  convert( varchar
                          ,isnull( max( datalength( convert(varchar,hostname))) ,8)
                         )
            ,@charMaxLenProgramName =
                  convert( varchar
                          ,isnull( max( datalength( convert(varchar,program_name))) ,11)
                         )
            ,@charMaxLenLastBatch =
                  convert( varchar
                          ,isnull( max( datalength( convert(varchar,last_batch_char))) ,9)
                         )
      from
             #tb1_sysprocesses
      where
             convert(varbinary(1), sid) >= @suidlow
      and    convert(varbinary(1), sid) <= @suidhigh
      and
             spid >= @spidlow
      and    spid <= @spidhigh
--------Output the report.
EXECUTE(
'
SET nocount off
SELECT
             SPID          = convert(char(5),spid)
            ,Status        =
                  CASE lower(status)
                     When ''sleeping'' Then lower(status)
                     Else                   upper(status)
                  END
            ,Login         = substring(suser_sname(sid),1,' + @charMaxLenLoginName + ')
            ,HostName      =
                  CASE hostname
                     When Null  Then ''  .''
                     When '' '' Then ''  .''
                     Else    substring(hostname,1,' + @charMaxLenHostName + ')
                  END
            ,BlkBy         =
                  CASE               isnull(convert(char(5),blocked),''0'')
                     When ''0'' Then ''  .''
                     Else            isnull(convert(char(5),blocked),''0'')
                  END
            ,DBName        = substring(db_name(dbid),1,' + @charMaxLenDBName + ')
            ,Command       = substring(cmd,1,' + @charMaxLenCommand + ')
            ,CPUTime       = substring(convert(varchar,cpu),1,' + @charMaxLenCPUTime + ')
            ,DiskIO        = substring(convert(varchar,physical_io),1,' + @charMaxLenDiskIO + ')
            ,LastBatch     = substring(last_batch_char,1,' + @charMaxLenLastBatch + ')
            ,ProgramName   = substring(program_name,1,' + @charMaxLenProgramName + ')
            ,SPID          = convert(char(5),spid)  --Handy extra for right-scrolling users.
      from
             #tb1_sysprocesses  --Usually DB qualification is needed in exec().
      where
             convert(varbinary(1), sid) >= ' + @charsuidlow  + '
      and    convert(varbinary(1), sid) <= ' + @charsuidhigh + '
      and
             spid >= ' + @charspidlow  + '
      and    spid <= ' + @charspidhigh + '
      -- (Seems always auto sorted.)   order by spid_sort
SET nocount on
'
)
LABEL_86RETURN:
if (object_id('tempdb..#tb1_sysprocesses') is not null)
            drop table #tb1_sysprocesses
return @retcode

GO
GRANT EXECUTE ON  [dbo].[fs_who] TO [public]
GO
