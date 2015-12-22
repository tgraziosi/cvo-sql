SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


Create Procedure [dbo].[fs_prodcost_insert] @row_id int
 AS

DECLARE @inv_acct varchar(32),@direct_acct varchar(32),@ovhd_acct varchar(32),@util_acct varchar(32)
DECLARE @cogs varchar(32), @cogs_direct varchar(32),@cogs_util varchar(32), @cogs_ovhd varchar(32)
DECLARE @glaccount varchar(32),@natcode varchar(8)
DECLARE @var_acct varchar(32), @var_direct varchar(32), @var_ovhd varchar(32)
DECLARE @var_util varchar(32)
DECLARE @wip_acct varchar(32),@wip_direct varchar(32),@wip_ovhd varchar(32),@wip_util varchar(32)
DECLARE @cost decimal(20,8)
DECLARE @company_id int, @iloop int, @retval int
DECLARE @qty decimal(20,8), @unitcost decimal(20,8), @direct decimal(20,8)
DECLARE @overhead decimal(20,8),@labor decimal(20,8), @utility decimal(20,8), @tran_line int, @convfactor decimal(20,8)
DECLARE @i_overhead decimal(20,8), @i_unitcost decimal(20,8), @i_direct decimal(20,8), @i_utility decimal(20,8)	-- mls 1/31/01 SCR 25781

DECLARE @loc varchar(10),@part varchar(30),@posting_code varchar(10), @fgitem varchar(30), @ppostcode varchar(10)
DECLARE @tran_code char(1),@tran_date datetime, @costmethod char(1)
DECLARE @end_of_loop int
DECLARE @v_mtrl_cost decimal(20,8), @v_dir_cost decimal(20,8), @v_ovhd_cost decimal(20,8), @v_util_cost decimal(20,8),
  @v_labor_cost decimal(20,8)
DECLARE @tot_mtrl_cost decimal(20,8), @tot_dir_cost decimal(20,8), @tot_ovhd_cost decimal(20,8), @tot_util_cost decimal(20,8),
  @tot_labor_cost decimal(20,8),
  @tempcost decimal(20,8)
DECLARE @tran_no int, @tran_ext int,@dir int
declare @msg varchar(80),@status char(1),@var char(1),
  @glqty decimal(20,8), @line_descr varchar(50),				-- mls 4/22/02 SCR 28686
  @tran_id int

DECLARE @glpart varchar(30)								-- mls 11/9/00 SCR 24973
BEGIN



 --Get system Defaults
 SELECT @company_id =(SELECT company_id FROM glco) 
 SELECT @natcode =(SELECT home_currency FROM glco)

 SELECT @part = i.part_no,
 @loc = p.location,
 @qty = i.qty,
 @tran_code = 'P',
 @tran_no = i.prod_no,
 @tran_ext = i.prod_ext,
 @tran_date = i.tran_date,
 @unitcost = i.cost,
 @direct = i.direct_dolrs,
 @overhead = i.ovhd_dolrs,
 @labor = i.labor,
 @utility = i.util_dolrs,
 @tran_line = line_no,
 @status = p.status,
 @tot_mtrl_cost = isnull(tot_mtrl_cost,i.cost * i.qty),
 @tot_dir_cost = isnull(tot_dir_cost,i.direct_dolrs * i.qty),
 @tot_ovhd_cost = isnull(tot_ovhd_cost,i.ovhd_dolrs * i.qty),
 @tot_util_cost = isnull(tot_util_cost,i.util_dolrs * i.qty),
 @tot_labor_cost = isnull(tot_labor_cost,i.labor * i.qty),
 @tran_id = isnull(tran_id,0)
 FROM prod_list_cost i, produce_all p
 WHERE i.row_id = @row_id AND 
 i.prod_no = p.prod_no AND
 i.prod_ext = p.prod_ext 

 --Get Direction from Prod
 SELECT @dir = direction
 from prod_list 
 where prod_no = @tran_no AND 
 prod_ext = @tran_ext AND 
 line_no = @tran_line

if @dir = 1 											-- mls 10/14/99 start
  return 1											-- mls 10/14/99 end

select @end_of_loop = 4

if NOT exists (select * from inv_list where part_no = @part and location = @loc)
BEGIN
  if @part = 'COST_VARIANCE' or @part = 'JOB_COST_TOTAL'
  BEGIN --Got a cost Variance Item!!
    if @part = 'COST_VARIANCE' select @var = 'Y'				-- mls 4/22/99  EPR 19038

    if (select prod_type from produce_all (nolock) where prod_no = @tran_no and prod_ext = @tran_ext) = 'J'
    BEGIN
      select @end_of_loop = 8 -- do inventory transactions

      select @posting_code = posting_code, 
        @dir = 1,
        @part = part_no,
        @costmethod = 'A'
      FROM produce_all
      WHERE prod_no = @tran_no and prod_ext = @tran_ext
    END
    ELSE
    BEGIN
      select @end_of_loop = 8 -- do variance transactions

      SELECT @part = part_no,
        @dir = direction
      FROM prod_list 
      WHERE seq_no = '' AND prod_no = @tran_no AND prod_ext = @tran_ext 
 
      SELECT @costmethod = inv_cost_method,
        @posting_code = acct_code
      FROM inventory(nolock) 
      WHERE part_no = @part AND  location = @loc
    END
  
  END
  ELSE --Got a Misc Item!
    SELECT @costmethod = 'A',
      @posting_code = apacct_code
    FROM locations_all (nolock) 
    WHERE location = @loc
END
ELSE --Have an Inventory item
BEGIN
  select @var = 'N'
  SELECT @costmethod = inv_cost_method,
    @posting_code = acct_code
  FROM inventory(nolock) 
  WHERE part_no = @part AND location = @loc
END

--Default to Average if not in list
--if @costmethod NOT IN ('A','F','L','W','S') select @costmethod='A'

--select @i_mtrl_cost = @tot_mtrl_cost, @i_dir_cost = @tot_dir_cost, @i_ovhd_cost = @tot_ovhd_cost,
--  @i_util_cost = @tot_util_cost, @i_labor_cost = @tot_labor_cost


















-- Get Accounts
SELECT 
  @direct_acct = inv_direct_acct_code,
  @ovhd_acct = inv_ovhd_acct_code,
  @util_acct = inv_util_acct_code,
  @inv_acct = inv_acct_code,
--  @cogs = ar_cgs_code,
--  @cogs_direct = ar_cgs_direct_code,
--  @cogs_ovhd = ar_cgs_ovhd_code,
--  @cogs_util = ar_cgs_util_code,
  @wip_acct = wip_acct_code,
  @wip_direct = wip_direct_acct_code,
  @wip_ovhd = wip_ovhd_acct_code,
  @wip_util = wip_util_acct_code,
  @var_acct = cost_var_code,
  @var_direct = cost_var_direct_code,
  @var_ovhd = cost_var_ovhd_code,
  @var_util = cost_var_util_code
FROM in_account(nolock)
WHERE acct_code = @posting_code










if @dir = -1 --Have a consumption record Need FG WIP Accounts
BEGIN
  --Get FG item Code / Posting Coce
  SELECT @fgitem = p.part_no,
    @ppostcode = inventory.acct_code
  FROM produce_all p (nolock), inventory(nolock)
  WHERE prod_no = @tran_no AND prod_ext = @tran_ext AND p.part_no = inventory.part_no AND
    inventory.location = @loc AND p.prod_type != 'J'

  --Get FG item Code / Posting Coce
  SELECT @fgitem = p.part_no,
    @ppostcode = p.posting_code
  FROM produce_all p (nolock)
  WHERE prod_no = @tran_no AND prod_ext = @tran_ext AND prod_type = 'J'

  SELECT @wip_acct = wip_acct_code,
    @wip_direct = wip_direct_acct_code,
    @wip_ovhd = wip_ovhd_acct_code,
    @wip_util = wip_util_acct_code
  FROM in_account(nolock)
  WHERE acct_code = @ppostcode
END
ELSE --dir = 1
BEGIN
  SELECT @qty = @qty * -1
END

--Inventory Accounts / WIP
SELECT @iloop = 1

WHILE @iloop <= @end_of_loop
--WHILE @iloop <= 12
BEGIN 
  Select @cost = 
    CASE @iloop
    WHEN 1 THEN @tot_mtrl_cost 									
    WHEN 2 THEN @tot_dir_cost 
    WHEN 3 THEN @tot_ovhd_cost 
    WHEN 4 THEN @tot_util_cost 
    WHEN 5 THEN -@tot_mtrl_cost 									
    WHEN 6 THEN -@tot_dir_cost 
    WHEN 7 THEN -@tot_ovhd_cost 
    WHEN 8 THEN -@tot_util_cost 














    END

  select @glqty = case when @iloop between 1 and 4 then -@qty else @qty end
  select @glqty = @glqty * @dir								-- mls 4/22/02 SCR 28686 
											-- mls 12/20/00 SCR 25339 start








 
  Select @glaccount = 
    CASE @iloop
    WHEN 1 THEN @wip_acct
    WHEN 2 THEN @wip_direct
    WHEN 3 THEN @wip_ovhd
    WHEN 4 THEN @wip_util
    WHEN 5 THEN case when @var = 'Y' then @var_acct else @inv_acct end
    WHEN 6 THEN case when @var = 'Y' then @var_direct else @direct_acct end
    WHEN 7 THEN case when @var = 'Y' then @var_ovhd else @ovhd_acct end
    WHEN 8 THEN case when @var = 'Y' then @var_util else @util_acct end














    END,
    @line_descr =									-- mls 4/22/02 SCR 28686
    CASE @iloop
    WHEN 1 THEN 'wip_acct'
    WHEN 2 THEN 'wip_direct_acct'
    WHEN 3 THEN 'wip_ovhd_acct'
    WHEN 4 THEN 'wip_util_acct'
    WHEN 5 THEN case when @var = 'Y' then 'cost_var_acct' else 'inv_acct' end	
    WHEN 6 THEN case when @var = 'Y' then 'cost_var_direct_acct' else 'inv_direct_acct' end	
    WHEN 7 THEN case when @var = 'Y' then 'cost_var_ovhd_acct' else 'inv_ovhd_acct' end	
    WHEN 8 THEN case when @var = 'Y' then 'cost_var_util_acct' else 'inv_util_acct' end	














    END

  select @glpart = case when @iloop between 1 and 4 then isnull(@fgitem,@part) else @part end







  IF @cost <> 0 
  BEGIN

    select @tempcost = @cost / @glqty
    exec @retval = adm_gl_insert @glpart,@loc,@tran_code,@tran_no,@tran_ext,@tran_line,		-- mls 01/24/01 SCR 20787
      @tran_date,@glqty,@tempcost,@glaccount,@natcode,DEFAULT,DEFAULT,			-- mls 4/22/02 SCR 28686
      @company_id, DEFAULT, DEFAULT, @tran_id, @line_descr, @cost			-- mls 4/22/02 SCR 28686

    IF @retval != 1
    BEGIN
      rollback tran
      select @msg = str(@retval) + ' : Error Inserting GL Costing Record!'
      raiserror 81331 @msg
      return -100
    END
  END 

  SELECT @iloop = @iloop + 1
END --While

RETURN 1
END
GO
GRANT EXECUTE ON  [dbo].[fs_prodcost_insert] TO [public]
GO
