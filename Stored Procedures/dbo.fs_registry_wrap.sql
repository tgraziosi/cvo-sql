SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[fs_registry_wrap] @registry_key varchar(255), @registry_mode char(1), @registry_type char(1),
  @registry_data varchar(255) as
BEGIN
declare @rc int, @err_txt varchar(80)
declare @found int, @ilevel int, @reg_id int, @reg_key varchar(255)
declare @count int

select @err_txt = ''

if @registry_mode = 'G' and @registry_type = 'A'				-- mls 8/1/01 SCR 27314 start
begin
  create table #keys 
  (registry_id int, parent_id int NULL, ilevel int, name varchar(32), rtype char(1), rdata varchar(255), rkey varchar(255))

  create index #k1 on #keys (ilevel, registry_id, rkey)

  insert into #keys
  select registry_id, parent_id, 0, registry_name, registry_type, registry_data, registry_name
  from registry
  where parent_id IS NULL

  select @found = @@rowcount
  select @ilevel = 0

  while @found > 0
  begin
    select @found = 0
    DECLARE regcur CURSOR LOCAL FOR					
    SELECT registry_id, rkey from #keys where ilevel = @ilevel

    OPEN regcur
    FETCH NEXT FROM regcur into @reg_id, @reg_key

    While @@FETCH_STATUS = 0
    begin									
      insert into #keys
      select registry_id, parent_id, (@ilevel + 1), registry_name, registry_type, registry_data, @reg_key + '/' + registry_name
      from registry
      where parent_id = @reg_id

      select @count = @@rowcount
      select @found = @found + @count

      FETCH NEXT FROM regcur into @reg_id, @reg_key
    end
    close regcur
    deallocate regcur

    select @ilevel = @ilevel + 1
  end

  SELECT rtype, rdata, 1, '',rkey
  FROM #keys									-- mls 8/1/01 SCR 27314 end
end
else
begin
  exec @rc = dbo.fs_registry @registry_key, @registry_mode, @registry_type OUTPUT , @registry_data OUTPUT, 1

  if @rc <> 1
  begin
    select @err_txt = 
      case @rc 
        when 69540 then 'Registry key not found'
        else 'Error ' + convert(varchar(10),@rc) + ' was returned from the operation.'
      end
  end

  SELECT @registry_type, @registry_data, @rc, @err_txt, @registry_key
end

END 

GO
GRANT EXECUTE ON  [dbo].[fs_registry_wrap] TO [public]
GO
