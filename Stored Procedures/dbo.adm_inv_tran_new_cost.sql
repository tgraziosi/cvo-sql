SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_inv_tran_new_cost] @action varchar(30), @i_kys int, @i_row_id int,
@i_part_no varchar(30), @i_location varchar(10), @typ char(1),
@i_inv_quantity decimal(20,8), @i_balance decimal(20,8), @i_apply_date datetime, @i_status char(1), 
@i_tran_data varchar(255), @i_update_ind int OUT, @COGS int, @in_stock decimal(20,8),
@i_mtrl_cost decimal(20,8) OUT, @i_dir_cost decimal(20,8) OUT, @i_ovhd_cost decimal(20,8) OUT, @i_util_cost decimal(20,8) OUT, 
@unitcost decimal(20,8) OUT, @direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @utility decimal(20,8) OUT,
@update_typ char(1) OUT, @acct_code varchar(8) = '', @a_tran_id int = 0, @use_ac char(1) = ''
AS
BEGIN
  declare @rc int, @acct_typ varchar(8)
  DECLARE @company_id int, @natcode varchar(8)
  DECLARE @inv_acct varchar(32), @account varchar(32)
  DECLARE @inv_direct varchar(32),@inv_ovhd varchar(32), @inv_util varchar(32), @std_inc varchar(32)
  DECLARE @inc_direct varchar(32),@inc_ovhd varchar(32), @inc_util varchar(32), @std_dec varchar(32)
  DECLARE @dec_direct varchar(32),@dec_ovhd varchar(32), @dec_util varchar(32), @iloop int,
    @cost decimal(20,8), @retval int
  declare @line_descr varchar(50), @totcost decimal(20,8)


  select @rc =  -1

  if @action = 'start of adm_inv_tran' -- start of adm_inv_tran
  begin
    select @update_typ = 'C'
    if @typ != 'S' and (@in_stock >= 0 or @use_ac = 'Y')
       select @i_update_ind = -2  -- if not a std costed part or not using std when negative, do not write an entry to inv_tran 

    if @i_status = 'S' -- manual cost change - update the std cost variables to the prev costs because the inv_list
                       -- std cost has already been updated to the new cost at this time and we want to report the original costs
      select @i_mtrl_cost = @unitcost, @i_dir_cost = @direct, @i_ovhd_cost = @overhead, @i_util_cost = @utility

    select @rc = 1
  end
  if @action = 'after costing' and @i_update_ind >= 0 -- update transaction
  begin
    update inv_list
    set std_cost = @i_mtrl_cost,
      std_direct_dolrs = @i_dir_cost,
      std_ovhd_dolrs = @i_ovhd_cost,
      std_util_dolrs = @i_util_cost
    where part_no = @i_part_no and location = @i_location

    if @typ != 'S'
      update inv_costing
      set unit_cost = @i_mtrl_cost,
        direct_dolrs = @i_dir_cost, ovhd_dolrs = @i_ovhd_cost, util_dolrs = @i_util_cost,
        balance = balance 				-- need to do this to fire trigger
      where part_no = @i_part_no and location = @i_location and account = 'STOCK'

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


      select @acct_typ = case when @typ = 'S' then 'SCI' else 'COGS' end
      exec @rc = adm_get_in_account @acct_code, @acct_typ,
         @std_inc OUT, @inc_direct OUT, @inc_ovhd OUT, @inc_util OUT

      if @rc <> 1  return @rc

      select @acct_typ = case when @typ = 'S' then 'SCD' else 'COGS' end
      exec @rc = adm_get_in_account @acct_code, @acct_typ,
         @std_dec OUT, @dec_direct OUT, @dec_ovhd OUT, @dec_util OUT

      if @rc <> 1  return @rc
     
      SELECT @iloop = 1

      WHILE @iloop <= 8
      BEGIN 
        Select @totcost = 
          CASE @iloop
            WHEN 1 THEN (@i_mtrl_cost )
            WHEN 2 THEN (@i_dir_cost )
            WHEN 3 THEN (@i_ovhd_cost )
            WHEN 4 THEN (@i_util_cost )
            WHEN 5 THEN ( - @i_mtrl_cost)
            WHEN 6 THEN ( - @i_dir_cost)
            WHEN 7 THEN ( - @i_ovhd_cost)
            WHEN 8 THEN ( - @i_util_cost)
          END  

        SELECT @account = 
          CASE @iloop
            WHEN 1 THEN @inv_acct	    
            WHEN 2 THEN @inv_direct
            WHEN 3 THEN @inv_ovhd
            WHEN 4 THEN @inv_util
            WHEN 5 THEN case when @totcost < 0 then @std_inc else @std_dec end	    
            WHEN 6 THEN case when @totcost < 0 then @inc_direct else @dec_direct end
            WHEN 7 THEN case when @totcost < 0 then @inc_ovhd else @dec_ovhd end
            WHEN 8 THEN case when @totcost < 0 then @inc_util else @dec_util end
          END,
          @line_descr =									-- mls 4/25/02 SCR 28686
          CASE @iloop
            WHEN 1 THEN 'inv_acct'	    
            WHEN 2 THEN 'inv_direct_acct'
            WHEN 3 THEN 'inv_ovhd_acct'
            WHEN 4 THEN 'inv_util_acct'
            WHEN 5 THEN case when @typ != 'S' then 'cogs_mtrl_acct' else
              case when @totcost < 0 then 'std_adj_inc_acct' else 'std_adj_dec_acct' end end
            WHEN 6 THEN case when @typ != 'S' then 'cogs_direct_acct' else
              case when @totcost < 0 then 'std_adj_inc_direct_acct' else 'std_adj_dec_direct_acct' end end
            WHEN 7 THEN case when @typ != 'S' then 'cogs_ovhd_acct' else
              case when @totcost < 0 then 'std_adj_inc_ovhd_acct' else 'std_adj_dec_ovhd_acct' end end
            WHEN 8 THEN case when @typ != 'S' then 'cogs_util_acct' else
              case when @totcost < 0 then 'std_adj_inc_util_acct' else 'std_adj_dec_util_acct' end end
          END

        IF @totcost <> 0 AND @i_inv_quantity <> 0
        BEGIN 
          if @company_id is NULL									
          begin
            SELECT @company_id = (SELECT company_id FROM glco(nolock))
            SELECT @natcode    = (SELECT home_currency FROM glco(nolock) WHERE company_id = @company_id)
          end											
          select @cost = @totcost / @i_inv_quantity
         
          exec @retval = adm_gl_insert @i_part_no,@i_location,'N',@i_row_id,0,0,
            @i_apply_date,@i_inv_quantity,@cost,@account,@natcode,DEFAULT,DEFAULT,@company_id,
            DEFAULT, DEFAULT, @a_tran_id, @line_descr, @totcost					-- mls 4/25/02 SCR 28686

          IF @retval <= 0
          BEGIN
            rollback tran
            raiserror 31910 'Error Inserting GL Costing Record!'
            return
          END
        END 
    
        SELECT @iloop = @iloop + 1
      END --While @iloop < 8
    END --IF i_update_ind >= 0
    
    update new_cost
    set apply_date = @i_apply_date,
      status = case when @i_update_ind >= 0 then 'P' else 'X' end
    where row_id = @i_row_id and kys = @i_kys and location = @i_location and part_no = @i_part_no

    select @rc = 1
  end

  RETURN @rc
END
GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran_new_cost] TO [public]
GO
