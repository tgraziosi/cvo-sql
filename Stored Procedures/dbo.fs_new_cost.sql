SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			fs_new_cost.sql
Type:			Stored Procedure
Called From:	Enterprise
Description:	Creates new costs for parts
Developer:		Chris Tyler
Date:			7th April 2011

Revision History
v1.1	CT	07/04/11	New parameter 'Style'
*/



CREATE PROCEDURE [dbo].[fs_new_cost]
                 @group varchar(10),    @parttype varchar(10), 
                 @part varchar(30),     @plevel char(4),
                 @newtype char(1),      @newamt money,
                 @newdir integer,       @who varchar(20),
                 @reason varchar(20),   @bdate datetime,
                 @loc varchar(10),			@org varchar(30),
				 @style varchar(40) -- v1.1 
AS 
BEGIN


declare @x integer, @eff_dt datetime, @kys int, @srch_loc varchar(10)



if @newtype = 'D' OR @newtype = 'P'
begin
  BEGIN TRAN

  SELECT @x=count(*)
  FROM   dbo.next_new_cost

  if @x = 0
  begin
    INSERT dbo.next_new_cost (last_no)
    SELECT 0
  end 

  UPDATE dbo.next_new_cost
  SET    dbo.next_new_cost.last_no=dbo.next_new_cost.last_no + 1
  SELECT @x=dbo.next_new_cost.last_no
  FROM   dbo.next_new_cost

  INSERT new_cost
           ( kys,
             location,
             part_no,
             cost_level,
             new_type,
             new_amt,
             new_direction,
             eff_date,
             who_entered,
             date_entered,
             reason,
             status,
             note,
	     apply_qty,										-- mls 1/25/01 SCR 20430 start
	     prev_unit_cost,							
	     prev_direct_dolrs,
	     prev_ovhd_dolrs,
	     prev_util_dolrs,
	     curr_unit_cost,
	     curr_direct_dolrs,
	     curr_ovhd_dolrs,
	     curr_util_dolrs )									-- mls 1/25/01 SCR 20430 end
  SELECT @x,        
           i.location,
           i.part_no, 
           @plevel,     @newtype,
           @newamt,     @newdir,   @bdate,
           @who,        getdate(), @reason,
           'N',         null,				
           0, 0, 0, 0, 0, 0, 0, 0, 0								-- mls 1/25/01 SCR 20430 
  FROM   dbo.inventory i
  INNER JOIN dbo.inv_master_add a ON i.part_no = a.part_no		-- v1.1
  WHERE  i.status < 'R' and i.type_code like @parttype and 
         i.category like @group and i.part_no like @part and
         ((i.location <> '' and i.location = @loc ) or
          ((@org = '%' and @loc = '') or (@loc = '' and i.organization_id like @org)))
		 AND  (isnull(a.field_2,'') like @style ) -- v1.1

  COMMIT TRAN
 
  SELECT count(*)
  FROM   new_cost
  WHERE  kys=@x
end 


if @newtype = 'U'
begin
  select @srch_loc = case when @loc = '' then '%' else @loc end

  select @eff_dt = isnull((select min(eff_date) from new_cost					-- mls 1/25/01 SCR 20430 start
    where location like @srch_loc and eff_date <= getdate() and status = 'N'),NULL)

  While @eff_dt is not NULL
  begin												
    select @kys = isnull((select min(kys) from new_cost
      where location like @srch_loc and eff_date = @eff_dt and status = 'N'),NULL)			
    
    while @kys is not NULL									
    begin											-- mls 1/25/01 SCR 20430 end

    BEGIN TRAN
    							-- mls 1/25/01 SCR 20430 start

    UPDATE inventory
    SET    std_cost = l.std_cost
    from   inventory l, new_cost n
    where  n.location=l.location and 
      l.part_no=n.part_no and l.category like @group and l.type_code like @parttype and 
      n.eff_date = @eff_dt and n.status='N' and n.kys = @kys and
      n.new_type in ('P','D') and n.cost_level like '%1%' and
         ((l.location <> '' and l.location = @loc ) or
          ((@org = '%' and @loc = '') or (@loc = '' and l.organization_id like @org)))

    UPDATE  new_cost
    set prev_unit_cost = i.std_cost,
        prev_direct_dolrs = i.std_direct_dolrs,
        prev_ovhd_dolrs = i.std_ovhd_dolrs,
        prev_util_dolrs = i.std_util_dolrs,
        status = 'W',
        apply_qty = (i.in_stock + i.hold_ord + i.hold_xfr),
        curr_unit_cost=
            case when n.cost_level like '1%'
            then 
              case when ( i.std_cost + ( i.std_cost * ( n.new_amt/100 ) * n.new_direction ) ) > 0
              then ( i.std_cost + ( i.std_cost * ( n.new_amt/100 ) * n.new_direction ) )
              else 0 end
            else i.std_cost end,
        curr_direct_dolrs=
            case when n.cost_level like '_1%' 
            then
              case when ( i.std_direct_dolrs + ( i.std_direct_dolrs * ( new_amt/100 ) * new_direction ) ) > 0
              then ( i.std_direct_dolrs + ( i.std_direct_dolrs * ( new_amt/100 ) * new_direction ) )
              else 0 end
            else i.std_direct_dolrs end,
        curr_ovhd_dolrs =
            case when n.cost_level like '__1%' 
            then
              case when ( i.std_ovhd_dolrs + ( i.std_ovhd_dolrs * ( new_amt/100 ) * new_direction ) )> 0
              then ( i.std_ovhd_dolrs + ( i.std_ovhd_dolrs * ( new_amt/100 ) * new_direction ) )
              else 0 end
            else i.std_ovhd_dolrs end,
        curr_util_dolrs =
            case when n.cost_level like '___1%' 
            then
              case when ( i.std_util_dolrs + ( i.std_util_dolrs * ( new_amt/100 ) * new_direction ) ) > 0
              then ( i.std_util_dolrs + ( i.std_util_dolrs * ( new_amt/100 ) * new_direction ) )
              else 0 end
            else i.std_util_dolrs end
    from    new_cost n, inventory i
    where  n.location=i.location and 
      i.part_no=n.part_no and i.category like @group and i.type_code like @parttype and 
      n.eff_date = @eff_dt and n.status='N' and n.kys = @kys and
      n.new_type = 'P' and n.cost_level like '%1%' and
      ((i.location <> '' and i.location = @loc ) or
       ((@org = '%' and @loc = '') or (@loc = '' and i.organization_id like @org)))

    UPDATE  new_cost
    set prev_unit_cost = i.std_cost,
        prev_direct_dolrs = i.std_direct_dolrs,
        prev_ovhd_dolrs = i.std_ovhd_dolrs,
        prev_util_dolrs = i.std_util_dolrs,
        status = 'W',
        apply_qty = (i.in_stock + i.hold_ord + i.hold_xfr),
        curr_unit_cost=
            case when n.cost_level like '1%'
            then 
              case when ( i.std_cost + ( new_amt * new_direction ) ) > 0 
              then ( i.std_cost + ( new_amt * new_direction ) )
              else 0 end
            else i.std_cost end,
        curr_direct_dolrs=
            case when n.cost_level like '_1%' 
            then
            case when ( i.std_direct_dolrs + ( new_amt * new_direction ) ) > 0
            then ( i.std_direct_dolrs + ( new_amt * new_direction ) )
            else 0 end
            else i.std_direct_dolrs end,
        curr_ovhd_dolrs =
            case when n.cost_level like '__1%' 
            then
            case when ( i.std_ovhd_dolrs + ( new_amt * new_direction ) ) > 0
            then ( i.std_ovhd_dolrs + ( new_amt * new_direction ) )
            else 0 end
            else i.std_ovhd_dolrs end,
        curr_util_dolrs =
            case when n.cost_level like '___1%' 
            then
            case when ( i.std_util_dolrs + ( new_amt * new_direction ) ) > 0
            then ( i.std_util_dolrs + ( new_amt * new_direction ) )
            else 0 end
            else i.std_util_dolrs end
    from    new_cost n, inventory i
    where  n.location=i.location and 
      i.part_no=n.part_no and i.category like @group and i.type_code like @parttype and 
      n.eff_date = @eff_dt and n.status='N' and n.kys = @kys and
      n.new_type = 'D' and n.cost_level like '%1%' and
      ((i.location <> '' and i.location = @loc ) or
       ((@org = '%' and @loc = '') or (@loc = '' and i.organization_id like @org)))
  
    COMMIT TRAN

    select @kys = isnull((select min(kys) from new_cost
      where location like @srch_loc and eff_date = @eff_dt and status = 'N' and kys > @kys),NULL)			
    END -- while kys is not null

    select @eff_dt = isnull((select min(eff_date) from new_cost					-- mls 1/25/01 SCR 20430 start
      where location like @srch_loc and eff_date > @eff_dt and eff_date <= getdate() and status = 'N'),NULL)
  END -- while											-- mls 1/25/01 SCR 20430 end

  DECLARE  @gl_method int, @tran_no int ,@tran_ext int ,@err int, @admmeth char(1)
  DECLARE  @trx_type char(1)

  select @admmeth = value_str from config where flag = 'PSQL_GLPOST_MTH'

  if @admmeth != 'I'
   BEGIN
     SELECT @gl_method = indirect_flag  FROM glco  

     select @trx_type = 'N'									-- mls 1/25/01 SCR 20430
     select @tran_no  = 0
     select @tran_ext = 0
		
     exec  adm_process_gl @who,@gl_method,@trx_type,@tran_no,@tran_ext,@err OUT

     if @err <> 1
      begin
	raiserror 99999 'Error with Post GL Procedure :' 
        select -1
      end
   end

  select 1
end -- new_type = 'U'
END
GO
GRANT EXECUTE ON  [dbo].[fs_new_cost] TO [public]
GO
