SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

	
CREATE proc [dbo].[EAI_Send_sp] (@type varchar(32), @data varchar(100), @source varchar(32), @action int, @SenderID varchar(32)='', @ReceiverID varchar(32)='')
as
begin

  declare @object int,
	  @hr int,
	  @sql_exec_string varchar(255),
          @return_value varchar(255),
          @debug int

  declare @hr2 int,
          @hrhex char(10),
          @source_app varchar(255),
          @description varchar(255)

  declare @Config_ID         varchar(32),
          @RegPath           varchar(100),
          @RegDestApp        varchar(30),  
          @Config_Name       varchar(100),
          @Config_Name_Last  varchar(100),
          @Config_Count      int,
          @Company_ID        varchar(32),
          @Publish_Count     int,
          @SvrAppString      varchar(255),
          @SvrAppPos         int,
          @SvrAppName        varchar(255),
          @SQLString         varchar(255)
          
  /* Only for debug set on @debug = 1 */
   select @debug = 0

  /* Begin Checks for Default Overrides */

  if ( @SenderID = '')
  begin
    select @Config_ID = config_value from EAI_config where config_item = 'Control ID'

    if (@Config_ID <> '') 
    begin
      
      select @SenderID = @Config_ID
      if @debug > 0
      select @SenderID 'SenderID'
    end
  end

  if ( @ReceiverID = '')
  begin
    select @RegPath = 'SOFTWARE\Epicor\EAI\Receiver'

    select replicate(' ',255) value, replicate(' ',255) data into #reg_info   
    delete #reg_info

    select ' ' keyexists into #reg_info2   
    delete #reg_info2

    insert #reg_info2
    exec master..xp_regread N'HKEY_LOCAL_MACHINE', @RegPath
    if exists (select 'keyexists' from #reg_info2 where keyexists = 1)
     begin 
       insert #reg_info
       exec master..xp_regenumvalues N'HKEY_LOCAL_MACHINE', @RegPath
     end
     else 
      insert EAI_error_log (error_key, bus_doc_name, primary_keys, error_no, error_location, error_desc, error_status, error_type, notes)
        values(newid(), @type, @data, 0, 'BO', 'EAI_Send_sp - ' + 'NOT EXIST Register ' + @RegPath + ' to fix change receiver secuence BO,FO to FO,BO in register keys '  ,'N','S','') 
 
    delete #reg_info2 
   
    if @debug > 0
       select @RegPath
     
    select @SvrAppPos = 0
 
    select @SvrAppString = data + ',' from #reg_info where value = 'Queues'
    
    if @debug > 0
       select @SvrAppString 'Queues'

    delete #reg_info

    select @RegDestApp = ''

    while (1=1)
    begin
      if (charindex(',',@SvrAppString,1) > 0)
      begin
        select @SvrAppName = left(@SvrAppString,(charindex(',',@SvrAppString,1)) - 1)
        select @SvrAppString = substring(@SvrAppString,(charindex(',',@SvrAppString,1)) + 1,999)
        if @debug > 0
        begin
           select @SvrAppName  'svrName'
           select @SvrAppString 'svrString'
        end
      end
      else
      begin
        break
      end
 
      select @RegPath = 'SOFTWARE\Epicor\EAI\Applications\' + @source + '\Routing\' + @type + '\' + @SvrAppName

      delete #reg_info2
 
      insert #reg_info2
      exec master..xp_regread N'HKEY_LOCAL_MACHINE', @RegPath

      if exists (select 'keyexists' from #reg_info2 where keyexists = 1)
      begin
        select @RegDestApp = @SvrAppName
        if @debug > 0
           select @RegDestApp  'RegDestApp'
        break
      end
      else
        insert EAI_error_log (error_key, bus_doc_name, primary_keys, error_no, error_location, error_desc, error_status, error_type, notes)
        values(newid(), @type, @data, 0, 'BO', 'EAI_Send_sp - ' + 'NOT EXIST Register '+ @RegPath   ,'N','S','') 
 
    end
 
    if (@RegDestApp <> '')
    begin
      if @debug > 0
         SELECT @RegDestApp 'RegDestApp'

      select @Config_Count = count(*) from EAI_config where config_item = @RegDestApp
      if @debug > 0  
         select @Config_Count 'count config'
         
      if ( @Config_Count > 0)
      begin
        if ( @Config_Count = 1)
        begin
          select @Config_Name = config_value from EAI_config where config_item = @RegDestApp

          select @Company_ID = DDID from EAI_IntegrationCompanies where AppName = @RegDestApp and CompanyName = @Config_Name

          if @debug > 0 
          begin
            select @Config_Name 'Config_Name'
            select @Company_ID  'Company_ID'
          end
          if ( @Company_ID <> '') 
          begin
            select @ReceiverID = @Company_ID
            if @debug > 0
                select @ReceiverID 'ReceiverID'
          end
        end

        if ( @Config_Count > 1)
        begin
          if exists (select name from sysobjects where name = 'smcomp')
          begin
            select @Config_Name_Last = ''
            select @Publish_Count = 0

            while (1=1)
            begin
              set rowcount 1

              select distinct @Config_Name = config_value from EAI_config 
              where config_item = @RegDestApp and config_value > @Config_Name_Last 

              if ( @@rowcount = 0)
              begin              
                set rowcount 0
                break
              end
              set rowcount 0

              select @Company_ID = ''

              set rowcount 1
              select @Company_ID = DDID from EAI_IntegrationCompanies where AppName = @RegDestApp and CompanyName = @Config_Name
              set rowcount 0
              if @debug > 0
                 select @Company_ID '@Company_ID'
              if ( @Company_ID <> '') 
              begin
                select @Publish_Count = @Publish_Count + 1

                select @SQLString = 'EAI_Send_sp ' + char(39) + @type + char(39) + ', ' + char(39) + @data + char(39) + ', ' + char(39) + @source + char(39) + ', ' + char(39) + convert(varchar(10),@action) + char(39) + ', ' + char(39) + @SenderID +
                       char(39) + ', ' + char(39) + @Company_ID + char(39)

                --exec EAI_Send_sp @type, @data, @source, @action, @SenderID, @Company_ID
                exec (@SQLString)
                if @debug > 0
                   select @SQLString 'Stringexec'
              end

              select @Config_Name_Last = @Config_Name
            end
 
            if ( @Publish_Count > 0) 
            begin
              return 0 
            end 
          end
        end
      end --
      else 
      BEGIN 
        if @debug > 0
            select 'config no found EAI_IntegrationCompanies'

      END
    end
  end
 
  /* Completed Checks for Default Overrides - Resume script processing */

  if exists(select * from master..sysprocesses where spid=@@SPID and program_name = 'Epicor EAI')
  begin 
    if @debug > 0
       select 'sp_OACreate EAISQL1.SENDER'
    exec @hr = sp_OACreate 'EAISQL1.SENDER', @object output  
  end 
  else  
  begin
    if @debug > 0
       select 'sp_OACreate EAISQL2.SENDER'
    exec @hr = sp_OACreate 'EAISQL2.SENDER', @object output
  end

  if ( @hr <> 0 )
  begin
    exec @hr2 = sp_OAGetErrorInfo @object, @source_app OUT, @description OUT
    if ( @hr2 = 0 )
      begin
        if @debug > 0
           select 'sp_OACreate EAISQL.SENDER insert error ' + @description
        insert EAI_error_log (error_key, bus_doc_name, primary_keys, error_no, error_location, error_desc, error_status, error_type, notes)
        values(newid(), @type, @data, @hr, @source_app, 'sp_OACreate - ' + @description,'N','S','') 
      end
    if @debug > 0
       select 'sp_OACreate EAISQL.SENDER return'
    return @hr
  end

    if @debug > 0
    begin
       select 'go'
       select @object 'object', @source_app 'source', @description 'description'
    end
  if ( @hr = 0 )
  begin
    if @debug > 0
       select 'sp_OAMethod: go'
    exec @hr = sp_OAMethod @object, 'go', NULL, @type, @data, @source, @action, @SenderID, @ReceiverID  

    if ( @hr <> 0 )
    begin
      exec @hr2 = sp_OAGetErrorInfo @object, @source_app OUT, @description OUT
      if ( @hr2 = 0 )
      begin
        insert EAI_error_log (error_key, bus_doc_name, primary_keys, error_no, error_location, error_desc, error_status, error_type, notes)
        values(newid(), @type, @data, @hr, @source_app, 'sp_OAMethod - ' + @description,'N','S','') 
      end
    end
    if @debug > 0
    begin 
        select 'sp_OADestroy'

        select @object 'object', @source_app 'source', @description 'description'
    end
    exec @hr = sp_OADestroy @object	
    if @debug > 0
     if(@hr <> 0)
       select 'sp_OADestroy Error' 
    
  end
  if @debug > 0
  begin
     if(@hr <> 0)
        select 'sp_OAGetErrorInfo return error' 
     if(@hr = 0)
        select 'Send Success'
  end
  return @hr

end
GO
GRANT EXECUTE ON  [dbo].[EAI_Send_sp] TO [public]
GO
