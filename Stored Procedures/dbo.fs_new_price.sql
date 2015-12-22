SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			fs_new_price.sql
Type:			Stored Procedure
Called From:	Enterprise
Description:	Sets new price for inventory items
Developer:		Chris Tyler
Date:			4th May 2011

Revision History
v1.1	CT	04/05/11	Changes from standard. Additional parameter of style
*/


CREATE PROCEDURE [dbo].[fs_new_price] 
                 @group varchar(10),    @parttype varchar(10), 
                 @part varchar(30),     @plevel char(1),
                 @newtype char(1),      @newamt money,
                 @newdir integer,       @who varchar(20),
                 @reason varchar(20),   @bdate datetime,
				 @currkey varchar(8),
				 @org_level int,	@loc_org_id varchar(30),
				 @style varchar(40)	-- v1.1

AS 		--skk 05/31/00
BEGIN

declare @x int
declare @row_id int, @inv_unit_dec int, @loc varchar(30)

select @inv_unit_dec = isnull((select convert(int,value_str) from config (nolock) where flag = 'INV_UNIT_DECIMALS'),8)

select @loc_org_id = case when isnull(@loc_org_id,'') = '' then '%' else @loc_org_id end


if @newtype = 'D' OR @newtype = 'P'
begin
  BEGIN TRAN
    SELECT @x=count(*)
    FROM   dbo.next_new_price
    if @x = 0
    begin
      INSERT dbo.next_new_price (last_no)
      SELECT 0
    end 
    UPDATE dbo.next_new_price
    SET    dbo.next_new_price.last_no=dbo.next_new_price.last_no + 1

    SELECT @x=dbo.next_new_price.last_no
    FROM   dbo.next_new_price

    if @org_level = 0
    begin 
      INSERT new_price 
           ( kys           , part_no       , 
             price_level   , new_type      , 
             new_amt       , new_direction , eff_date  , 
             who_entered   , date_entered  , reason    , 
             status        , note	   , curr_key  , org_level, loc_org_id  )		--skk 05/31/00
      SELECT @x,          i.part_no, 
           @plevel,     @newtype,
           @newamt,     @newdir,   @bdate,
           @who,        getdate(), @reason,
           'N',         null,      @currkey, 0, ''
      FROM   dbo.inv_master i
	  INNER JOIN dbo.inv_master_add a	-- v1.1
	  ON i.part_no = a.part_no			-- v1.1
      WHERE  (i.status < 'R' or i.status = 'V')				-- mls 10/4/04 SCR 33489
	   and i.type_code like @parttype and 
           i.category like @group and i.part_no like @part
		   AND isnull(a.field_2,'') like @style -- v1.1
    end
    if @org_level = 1
    begin
      INSERT new_price 
           ( kys           , part_no       , 
             price_level   , new_type      , 
             new_amt       , new_direction , eff_date  , 
             who_entered   , date_entered  , reason    , 
             status        , note	   , curr_key  , org_level , loc_org_id )		--skk 05/31/00
      SELECT distinct @x,          i.part_no, 
           @plevel,     @newtype,
           @newamt,     @newdir,   @bdate,
           @who,        getdate(), @reason,
           'N',         null,      @currkey, 1, @loc_org_id
      FROM   dbo.inv_master i 
	  INNER JOIN part_org_price_vw  p	-- v1.1 (changed to join)
	  ON i.part_no = p.part_no			-- v1.1 (changed to join)
	  INNER JOIN dbo.inv_master_add a	-- v1.1
	  ON i.part_no = a.part_no			-- v1.1
      WHERE  (i.status < 'R' or i.status = 'V')				-- mls 10/4/04 SCR 33489
	   and i.type_code like @parttype and 
           i.category like @group and i.part_no like @part
           and p.active_ind = 1 and p.curr_key = @currkey 
           and p.org_level = 1 and p.loc_org_id like @loc_org_id
		   AND isnull(a.field_2,'') like @style -- v1.1
    end
    if @org_level = 2
    begin
      INSERT new_price 
           ( kys           , part_no       , 
             price_level   , new_type      , 
             new_amt       , new_direction , eff_date  , 
             who_entered   , date_entered  , reason    , 
             status        , note	   , curr_key  , org_level , loc_org_id )		--skk 05/31/00
      SELECT distinct @x,          i.part_no, 
           @plevel,     @newtype,
           @newamt,     @newdir,   @bdate,
           @who,        getdate(), @reason,
           'N',         null,      @currkey, 2, @loc_org_id
      FROM   dbo.inv_master i 
	  INNER JOIN part_org_price_vw  p	-- v1.1 (changed to join)
	  ON i.part_no = p.part_no			-- v1.1 (changed to join)
	  INNER JOIN dbo.inv_master_add a	-- v1.1
	  ON i.part_no = a.part_no			-- v1.1
      WHERE  (i.status < 'R' or i.status = 'V')				-- mls 10/4/04 SCR 33489
	   and i.type_code like @parttype and 
           i.category like @group and i.part_no like @part
           and p.active_ind = 1 and p.curr_key = @currkey 
           and p.org_level = 2 and p.loc_org_id like @loc_org_id
		   AND isnull(a.field_2,'') like @style -- v1.1
    end
  COMMIT TRAN
 
  SELECT count(*)
  FROM   new_price
  WHERE  kys=@x
end 

-- remove price updates
if @newtype = 'X'
begin
  select @reason = case when isnull(@reason,'') = '' then '%' else @reason end

  BEGIN TRAN
      delete p
      from inv_master i (nolock)
	  INNER JOIN new_price p		-- v1.1 (changed to join)
	  ON p.part_no = i.part_no		-- v1.1 (changed to join)
	  INNER JOIN dbo.inv_master_add a	-- v1.1
	  ON i.part_no = a.part_no			-- v1.1
      where p.status = 'N' and
        (p.eff_date = @bdate or @bdate = '1/1/1900') and p.reason like @reason and p.curr_key = @currkey and
        p.org_level = @org_level and p.loc_org_id like @loc_org_id 
	      and i.type_code like @parttype and i.category like @group and i.part_no like @part
		  AND isnull(a.field_2,'') like @style -- v1.1
  COMMIT TRAN

  select 1
end 


if @newtype = 'U'
begin
  select @loc = @part -- location passed via part parameter
  
  create table #temp_prices (eff_date datetime, reason varchar(20), kys int)
  create index #tp1 on #temp_prices(eff_date,reason,kys)
  create table #new_prices (eff_date datetime, reason varchar(20), kys int, row_id int identity(1,1))
  create index #np1 on #new_prices(row_id)

  insert #temp_prices (eff_date, reason, kys)
  select distinct n.eff_date, isnull(n.reason,''), n.kys
  from new_price n 
  INNER JOIN inv_master i	-- v1.1 (changed to join)
  ON n.part_no = i.part_no	-- v1.1 (changed to join)
  INNER JOIN dbo.inv_master_add a	-- v1.1
  ON i.part_no = a.part_no			-- v1.1
  where ( n.status = 'N' ) AND  i.category like @group  and i.type_code like @parttype  
    and n.org_level = 0 and n.eff_date<=getdate() 
	AND isnull(a.field_2,'') like @style -- v1.1

  if @loc = '' or @loc_org_id <> '%'
  begin
    insert #temp_prices (eff_date, reason, kys)
    select distinct n.eff_date, isnull(n.reason,''), n.kys
    from new_price n
	INNER JOIN inventory i	-- v1.1 (changed to join)
	ON n.part_no = i.part_no	-- v1.1 (changed to join)
	INNER JOIN dbo.inv_master_add a	-- v1.1
	ON i.part_no = a.part_no			-- v1.1
    where ( n.status = 'N' ) AND  i.category like @group  and i.type_code like @parttype  
      and ((n.org_level = 1 and i.organization_id like n.loc_org_id) or (n.org_level = 2 and i.location like n.loc_org_id))
      and i.organization_id like @loc_org_id
      and n.eff_date<=getdate() 
	  AND isnull(a.field_2,'') like @style -- v1.1
  end

  if @loc <> ''
  begin
    insert #temp_prices (eff_date, reason, kys)
    select distinct n.eff_date, isnull(n.reason,''), n.kys
    from new_price n
	INNER JOIN inventory i	-- v1.1 (changed to join)
	ON n.part_no = i.part_no	-- v1.1 (changed to join)
	INNER JOIN dbo.inv_master_add a	-- v1.1
	ON i.part_no = a.part_no			-- v1.1
    where ( n.status = 'N' ) AND  i.category like @group  and i.type_code like @parttype  
      and (n.org_level = 2 and i.location like n.loc_org_id)
      and i.location = @loc
      and n.eff_date<=getdate()
	  AND isnull(a.field_2,'') like @style -- v1.1
  end
  
  insert #new_prices
  select distinct eff_date, reason, kys
  from #temp_prices
  order by eff_date, reason, kys

  select @row_id = isnull((select min(row_id) from #new_prices),NULL)
  while @row_id is not null
  begin
  select @x = kys from #new_prices where row_id = @row_id

  BEGIN TRAN

  
  update d
    SET d.price = case when ( d.price + ( d.price * ( n.new_amt/100 ) * n.new_direction ) ) < 0 then 0
       else round(( d.price + ( d.price * ( n.new_amt/100 ) * n.new_direction ) ),@inv_unit_dec) end
  FROM    adm_inv_price_det d
  join new_price  n on  n.kys = @x and n.new_type='P' and n.price_level='%'
  join inv_master i on i.part_no = n.part_no and i.category like @group and i.type_code like @parttype 
  join adm_price_catalog c on c.curr_key = n.curr_key and c.type = 0 and c.active_ind = 1
  join adm_inv_price p on p.part_no = n.part_no and p.catalog_id = c.catalog_id and p.active_ind = 1
    and p.org_level = n.org_level and p.loc_org_id like n.loc_org_id
    and d.inv_price_id = p.inv_price_id

  
  update d
    SET d.price = case when ( d.price + ( d.price * ( n.new_amt/100 ) * n.new_direction ) ) < 0 then 0
       else round(( d.price + ( d.price * ( n.new_amt/100 ) * n.new_direction ) ),@inv_unit_dec) end
  FROM    adm_inv_price_det d
  join new_price  n on  n.kys = @x and n.new_type='P' and n.price_level='A'
  join inv_master i on i.part_no = n.part_no and i.category like @group and i.type_code like @parttype 
  join adm_price_catalog c on c.curr_key = n.curr_key and c.type = 0 and c.active_ind = 1
  join adm_inv_price p on p.part_no = n.part_no and p.catalog_id = c.catalog_id and p.active_ind = 1
    and p.org_level = n.org_level and p.loc_org_id like n.loc_org_id
    and d.inv_price_id = p.inv_price_id
  where d.p_level = 1

  update d
    SET d.price = case when ( d.price + ( n.new_amt * n.new_direction ) ) < 0 then 0
       else round(( d.price + ( n.new_amt * n.new_direction ) ),@inv_unit_dec) end
  FROM    adm_inv_price_det d
  join new_price  n on  n.kys = @x and n.new_type='D' and n.price_level='A'
  join inv_master i on i.part_no = n.part_no and i.category like @group and i.type_code like @parttype 
  join adm_price_catalog c on c.curr_key = n.curr_key and c.type = 0 and c.active_ind = 1
  join adm_inv_price p on p.part_no = n.part_no and p.catalog_id = c.catalog_id and p.active_ind = 1
    and p.org_level = n.org_level and p.loc_org_id like n.loc_org_id
    and d.inv_price_id = p.inv_price_id
  where d.p_level = 1

  update d
    SET d.price = case when ( d.price + ( n.new_amt * n.new_direction ) ) < 0 then 0
       else round(( d.price + ( n.new_amt * n.new_direction ) ),@inv_unit_dec) end
  FROM    adm_inv_price_det d
  join new_price  n on  n.kys = @x and n.new_type='D' and n.price_level='%'
  join inv_master i on i.part_no = n.part_no and i.category like @group and i.type_code like @parttype 
  join adm_price_catalog c on c.curr_key = n.curr_key and c.type = 0 and c.active_ind = 1
  join adm_inv_price p on p.part_no = n.part_no and p.catalog_id = c.catalog_id and p.active_ind = 1
    and p.org_level = n.org_level and p.loc_org_id like n.loc_org_id
    and d.inv_price_id = p.inv_price_id

  
  UPDATE  new_price
  SET     new_price.status='P'
  FROM    new_price, inv_master
  WHERE   new_price.part_no=inv_master.part_no and new_price.kys = @x and
          inv_master.category like @group and
          inv_master.type_code like @parttype and new_price.status = 'N'
  COMMIT TRAN

  select @row_id = isnull((select min(row_id) from #new_prices where row_id > @row_id),NULL)
  end
  select 1
end
END

GO
GRANT EXECUTE ON  [dbo].[fs_new_price] TO [public]
GO
