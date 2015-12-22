SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_inv_tran_cost_adj] @action varchar(30), @i_audit int, @i_sequence int,
@i_part_no varchar(30), @i_location varchar(10), @typ char(1),
@i_inv_quantity decimal(20,8), @i_balance decimal(20,8), @i_apply_date datetime, @i_status char(1), 
@i_tran_data varchar(255), @i_update_ind int OUT, @COGS int, @in_stock decimal(20,8),
@i_mtrl_cost decimal(20,8) OUT, @i_dir_cost decimal(20,8) OUT, @i_ovhd_cost decimal(20,8) OUT, @i_util_cost decimal(20,8) OUT, 
@unitcost decimal(20,8) OUT, @direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @utility decimal(20,8) OUT,
@update_typ char(1) OUT, @acct_code varchar(8) = '', @a_tran_id int = 0, @use_ac char(1) = ''
AS
BEGIN
  declare @i_account varchar(10), @sqty decimal(20,8)
  declare @rc int
  DECLARE @inv_acct varchar(32), @inv_direct varchar(32),@inv_ovhd varchar(32), @inv_util varchar(32),
    @recv_acct varchar(32), @iloop int, @account varchar(32),
    @line_descr varchar(50), @retval int,
    @sumcost decimal(20,8), @totcost decimal(20,8), @cost decimal(20,8),
    @company_id int, @natcode varchar(8)

  select @rc =  -1

  if @action = 'start of adm_inv_tran' -- start of adm_inv_tran
  begin
    select @rc = 1
  end
  if @action = 'after costing' and @i_update_ind >= 0 -- update transaction
  begin
    select @i_account = substring(@i_tran_data,7,10)			-- mls 3/8/04 SCR 32498

    UPDATE inv_costing
    SET unit_cost    = @i_mtrl_cost ,
      direct_dolrs = @i_dir_cost , 
      ovhd_dolrs   = @i_ovhd_cost ,
      util_dolrs   = @i_util_cost ,
      tot_mtrl_cost = @i_mtrl_cost * @i_inv_quantity ,
      tot_dir_cost = @i_dir_cost * @i_inv_quantity ,
      tot_ovhd_cost = @i_ovhd_cost * @i_inv_quantity ,
      tot_util_cost = @i_util_cost  * @i_inv_quantity,
      tot_labor_cost = 0
    WHERE inv_costing.part_no  = @i_part_no  AND inv_costing.location = @i_location AND
      inv_costing.account  = @i_account  AND inv_costing.sequence = @i_sequence

    Update inv_costing_audit									-- mls 1/22/01 SCR 20425 start
    set prev_unit_cost =  @unitcost /@i_inv_quantity,
      prev_direct_dolrs =  @direct /@i_inv_quantity,
      prev_ovhd_dolrs =  @overhead /@i_inv_quantity, 
      prev_util_dolrs =  @utility /@i_inv_quantity
    where audit = @i_audit										-- mls 1/22/01 SCR 20425 end


    if @typ = 'A' and @i_account = 'STOCK' --Update avg cost in Inventory when costing method is Average.
    BEGIN
      UPDATE inv_list
      SET	avg_cost	= @i_mtrl_cost,
       	avg_direct_dolrs	= @i_dir_cost, 
	avg_ovhd_dolrs  	= @i_ovhd_cost,
        avg_util_dolrs		= @i_util_cost
      WHERE inv_list.part_no  	= @i_part_no  AND inv_list.location = @i_location 
    END

    if (@typ in ( 'F' ,'L','E')) and @i_account = 'STOCK' --Update avg cost in Inventory when costing method is LIFO/FIFO.
    BEGIN
      SELECT @sqty = isNull((SELECT sum(abs(i.balance)) 
        FROM inv_costing i
        WHERE i.part_no = @i_part_no AND i.location = @i_location AND i.account = 'STOCK'),1)

      UPDATE inv_list
      SET avg_cost = abs(isnull((SELECT sum(i.unit_cost * abs(i.balance)) / @sqty
          FROM inv_costing i 
          WHERE i.part_no = @i_part_no and i.location = @i_location and i.account = 'STOCK'), inv_list.avg_cost)),
        avg_direct_dolrs = abs(isnull((SELECT sum(i.direct_dolrs * abs(i.balance)) / @sqty
          FROM inv_costing i 
          WHERE i.part_no = @i_part_no and i.location = @i_location and i.account = 'STOCK'), inv_list.avg_direct_dolrs)),
        avg_ovhd_dolrs = abs(isnull((SELECT sum(i.ovhd_dolrs * abs(i.balance)) / @sqty
          FROM inv_costing i 
          WHERE i.part_no = @i_part_no and i.location = @i_location and i.account = 'STOCK'), inv_list.avg_ovhd_dolrs)),
        avg_util_dolrs = abs(isnull((SELECT sum(i.util_dolrs * abs(i.balance)) / @sqty
          FROM inv_costing i 
          WHERE i.part_no = @i_part_no and i.location = @i_location and i.account = 'STOCK'), inv_list.avg_util_dolrs))
      WHERE inv_list.part_no = @i_part_no AND inv_list.location = @i_location
    END

    select @rc = 1
  end
  if @action = 'end of adm_inv_tran' -- update inventory
  begin
    if @i_update_ind >= 0
    BEGIN                 
      if isnull(@acct_code,'') = ''
        return -2

      exec @rc = adm_get_in_account @acct_code, 'FG',
         @inv_acct OUT, @inv_direct OUT, @inv_ovhd OUT, @inv_util OUT

      if @rc <> 1  return @rc

      exec @rc = adm_get_in_account @acct_code, 'MRA', @recv_acct OUT, '','',''

      if @rc <> 1  return @rc

      SELECT @iloop = 1, @sumcost = 0
      WHILE @iloop <= 4
      BEGIN 
        Select @totcost = 
        CASE @iloop
          WHEN 1 THEN @unitcost 
          WHEN 2 THEN @direct 
          WHEN 3 THEN @overhead 
          WHEN 4 THEN @utility 
        END
      
        Select @account = 
          CASE @iloop
            WHEN 1 THEN @inv_acct
            WHEN 2 THEN @inv_direct
            WHEN 3 THEN @inv_ovhd
            WHEN 4 THEN @inv_util
          END,
          @line_descr =							-- mls 4/22/02 SCR 28686
          CASE @iloop
            WHEN 1 THEN 'inv_acct'
            WHEN 2 THEN 'inv_direct_acct'
            WHEN 3 THEN 'inv_ovhd_acct'
            WHEN 4 THEN 'inv_util_acct'
          END    
            
        IF @totcost != 0 
        BEGIN
          if @company_id is NULL									
          begin
            SELECT @company_id = (SELECT company_id FROM glco(nolock))
            SELECT @natcode    = (SELECT home_currency FROM glco(nolock) WHERE company_id = @company_id)
          end											

          select @cost = @totcost / @i_inv_quantity
          exec @retval = adm_gl_insert  @i_part_no,@i_location,'C',@i_audit,0,@i_sequence,
            @i_apply_date,@i_inv_quantity,@cost,@account,@natcode,DEFAULT,DEFAULT, @company_id,
            DEFAULT,DEFAULT, @a_tran_id, @line_descr, @totcost
	    -- mls 4/22/02 SCR 28686

          IF @retval <= 0
          BEGIN
            rollback tran
            raiserror 89010 'Error Inserting GL Costing Record!'
            return -4
          END

          select @sumcost = @sumcost + @totcost
        END 

        SELECT @iloop = @iloop + 1
      END --While

      select @sumcost = @sumcost * -1
      select @cost = @sumcost / @i_inv_quantity

      --Insert variance account
      exec @retval = adm_gl_insert  @i_part_no,@i_location,'C',@i_audit,0,@i_sequence,
        @i_apply_date,@i_inv_quantity,@cost,@recv_acct,@natcode,DEFAULT,DEFAULT,@company_id,
        DEFAULT,DEFAULT, @a_tran_id, 'rec_var_acct', @sumcost

      IF @retval <= 0
      BEGIN
        rollback tran
        raiserror 89011 'Error Inserting GL Costing Record!'
        return -5
      END
    end
  end

  select @rc = 1

  RETURN @rc
END
GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran_cost_adj] TO [public]
GO
