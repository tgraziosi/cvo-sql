SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_inv_tran_landed_cost] @action varchar(30), @i_alloc_no int, @i_tran_no int,
@i_part_no varchar(30), @i_location varchar(10), @typ char(1),
@i_inv_quantity decimal(20,8), @i_balance decimal(20,8), @i_apply_date datetime, @i_status char(1), 
@i_tran_data varchar(255), @i_update_ind int OUT, @COGS int, @in_stock decimal(20,8),
@i_mtrl_cost decimal(20,8) OUT, @i_dir_cost decimal(20,8) OUT, @i_ovhd_cost decimal(20,8) OUT, @i_util_cost decimal(20,8) OUT, 
@unitcost decimal(20,8) OUT, @direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @utility decimal(20,8) OUT,
@update_typ char(1) OUT
AS
BEGIN
  declare @rc int, @temp_qty decimal(20,8), @l_in_stock decimal(20,8),
    @tran_ext int, @tran_line int, @tran_code char(1),
    @uc decimal(20,8), @d decimal(20,8), @o decimal(20,8), @u decimal(20,8)
  declare @audit int, @prev_audit int, @l_ovhd decimal(20,8), @l_tot_ovhd decimal(20,8)

  select @tran_ext = convert(int,substring(@i_tran_data,22,10))
  select @tran_line = convert(int,substring(@i_tran_data,12,10))
  select @tran_code = substring(@i_tran_data,11,1)

  select @rc =  -1

  if @action = 'start of adm_inv_tran' -- start of adm_inv_tran
  begin
    delete inv_costing 
      where part_no=@i_part_no and location=@i_location and account=substring(@i_tran_data,34,10)

    if not exists (select 1 from inv_costing (nolock)
      WHERE part_no = @i_part_no and location = @i_location and account = 'STOCK' and  tran_no = @i_tran_no and 
        tran_ext = @tran_ext and tran_line= @tran_line and tran_code= @tran_code)
      select @i_update_ind = -2

    select @update_typ = 'C'
    select @rc = 1
  end
  if @action = 'after costing' and @i_update_ind >= 0 -- update transaction
  begin
    if @typ = 'S' or @i_update_ind = -2
      return 1		-- standard cost parts do not use cost layers


    select @uc = @i_mtrl_cost / @i_inv_quantity,
      @d = @i_dir_cost / @i_inv_quantity,
      @o = @i_ovhd_cost / @i_inv_quantity,
      @u = @i_util_cost / @i_inv_quantity

    insert into inv_costing (part_no,location,sequence,tran_code,tran_no,tran_ext,tran_line,
      account, tran_date,tran_age,unit_cost,quantity,balance,direct_dolrs,ovhd_dolrs,
      labor,util_dolrs, org_cost,tot_mtrl_cost,tot_dir_cost,tot_ovhd_cost,tot_util_cost) 
    values (@i_part_no, @i_location, 1, @tran_code, @i_tran_no, @tran_ext, @tran_line, 
      substring(@i_tran_data,34,10), getdate(),
      @i_apply_date,@uc, @i_inv_quantity , @i_balance, @d, @o,
      0, @u, @uc,@i_mtrl_cost, @i_dir_cost,@i_ovhd_cost, @i_util_cost) 

    if left(@i_tran_data,10) = 'OHADJ' and @typ != 'A'								-- mls 9/18/00 start
    begin
      select @audit = isnull((select min(audit) from inv_costing
        where part_no = @i_part_no and location = @i_location and account = 'STOCK' 
        and  tran_no = @i_tran_no and tran_ext = @tran_ext and tran_line= @tran_line and tran_code= @tran_code),NULL)

      select @prev_audit = 0, @l_tot_ovhd = 0
      while @audit is not null 
      begin
        select @prev_audit = @audit
        select @l_ovhd = @o * balance
        from inv_costing
        where part_no = @i_part_no and location = @i_location and account = 'STOCK' 
        and  tran_no = @i_tran_no and tran_ext = @tran_ext and tran_line= @tran_line and tran_code= @tran_code
        and audit = @audit

        select @l_tot_ovhd = @l_tot_ovhd + @l_ovhd
      
        Update inv_costing
        set quantity = quantity,
	  ovhd_dolrs = abs(((ovhd_dolrs * balance) + @l_ovhd) / balance),			-- mls 11/1/07 38265
	  --ovhd_dolrs = abs((ovhd_dolrs * balance) + (@l_ovhd / balance)),			-- mls 4/12/04 32618
	  tot_ovhd_cost = tot_ovhd_cost + @l_ovhd
        WHERE part_no = @i_part_no and location = @i_location and account = 'STOCK' and  tran_no = @i_tran_no and 
        tran_ext = @tran_ext and tran_line= @tran_line and tran_code= @tran_code
        and audit = @audit

        select @audit = isnull((select min(audit) from inv_costing
          where part_no = @i_part_no and location = @i_location and account = 'STOCK' 
          and  tran_no = @i_tran_no and tran_ext = @tran_ext and tran_line= @tran_line and tran_code= @tran_code
          and audit > @audit),NULL)
      end
      if @l_tot_ovhd != @i_ovhd_cost 
      begin
        if @prev_audit != 0
          update inv_costing
          set quantity = quantity,
	    tot_ovhd_cost = tot_ovhd_cost + (@i_ovhd_cost - @l_tot_ovhd)
          WHERE part_no = @i_part_no and location = @i_location and account = 'STOCK' and  tran_no = @i_tran_no and 
          tran_ext = @tran_ext and tran_line= @tran_line and tran_code= @tran_code
          and audit = @prev_audit
        else
          return -1
      end

    end												-- mls 9/18/00 end

    delete inv_costing 
      where part_no=@i_part_no and location=@i_location and account=substring(@i_tran_data,34,10)
      
    select @rc = 1
  end

  if @action = 'end of adm_inv_tran' -- update inventory
  begin
    select @rc = 1
  end

  RETURN @rc

END
GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran_landed_cost] TO [public]
GO
