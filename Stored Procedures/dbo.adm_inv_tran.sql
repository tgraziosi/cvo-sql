SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 21/04/2015 - Performance Changes 
  
CREATE PROCEDURE [dbo].[adm_inv_tran]  
@i_tran_type char(1), @i_tran_no int, @i_tran_ext int, @i_tran_line int,  
@i_part_no varchar(30), @i_location varchar(10), @i_uom_quantity decimal(20,8), @i_apply_date datetime,   
@i_uom char(2), @i_conv_factor decimal(20,8), @i_status char(1), @i_tran_data varchar(255) OUT,   
@i_update_ind int = 0, @i_tran_id int OUT, @i_mtrl_cost decimal(20,8) OUT,   
@i_dir_cost decimal(20,8) OUT, @i_ovhd_cost decimal(20,8) OUT, @i_util_cost decimal(20,8) OUT,  
@i_labor_cost decimal(20,8) OUT,  
@COGS int OUT, @o_unitcost decimal(20,8) OUT, @o_direct decimal(20,8) OUT,   
@o_overhead decimal(20,8) OUT, @o_utility decimal(20,8) OUT, @o_labor decimal(20,8) OUT,  
@o_in_stock decimal(20,8) OUT, @typ char(1) = '' OUT  
AS  
BEGIN  
set nocount on  
select @COGS = 0  
  
DECLARE  
  @n_in_stock decimal(20,8),  
  @use_ac char(1), @retval int, @i_quantity decimal(20,8),  
  @in_stock decimal(20,8), @non_holds decimal(20,8), @cl_qty decimal(20,8),  
  @m_status char(1), @l_typ char(1), @std_uom char(2),  
  @wavg_unitcost decimal(20,8), @wavg_direct decimal(20,8), @wavg_overhead decimal(20,8), @wavg_utility decimal(20,8),  
  @avg_unitcost decimal(20,8), @avg_direct decimal(20,8), @avg_overhead decimal(20,8), @avg_utility decimal(20,8),  
  @avg_labor decimal(20,8),  
  @std_unitcost decimal(20,8), @std_direct decimal(20,8), @std_overhead decimal(20,8), @std_utility decimal(20,8),  
  @std_labor decimal(20,8),  
  @rc int, @msg varchar(255),  
  @inv_holds decimal(20,8), @acct_code varchar(8),  
  @l_qty decimal(20,8),  @l_in_stock decimal(20,8),  
  @labor decimal(20,8), @dummycost decimal(20,8),   
  @tran_date datetime,  
  @trn_unitcost decimal(20,8), @trn_direct decimal(20,8), @trn_overhead decimal(20,8), @trn_utility decimal(20,8), @trn_labor decimal(20,8),  
  @inv_unitcost decimal(20,8), @inv_direct decimal(20,8), @inv_overhead decimal(20,8), @inv_utility decimal(20,8), @inv_labor decimal(20,8),  
  @neg_unitcost decimal(20,8), @neg_direct decimal(20,8), @neg_overhead decimal(20,8), @neg_utility decimal(20,8), @neg_labor decimal(20,8),  
  @unitcost decimal(20,8) , @direct decimal(20,8) , @overhead decimal(20,8) , @utility decimal(20,8) ,  
  @sub_function varchar(30), @neg_typ char(1),  
  @process_typ varchar(10), @update_typ char(1),  
  @cl_account varchar(8), @c_tran_type char(1),  
  @layer_qty decimal(20,8), @skip_costing int,  
  @d_qc_flag char(1), @i_qc_flag char(1), @i_qty decimal(20,8), @i_trigger char(1),  
  @avg_cost decimal(20,8), @avg_dir decimal(20,8), @avg_oh decimal(20,8), @avg_utl decimal(20,8), @inv_qty decimal(20,8),  
  @inv_val decimal(20,8), @chg_val decimal(20,8), @i_cost decimal(20,8),  
  @o_in_stock_value decimal(20,8), @i_quantity_value decimal(20,8),  
  @cogs_qty decimal(20,8), @chg_cost decimal(20,8), @hold_qty decimal(20,8)  
  
declare @qty decimal(20,8), @max_seq int,  
  @tot_mtrl_cost decimal(20,8), @tot_dir_cost decimal(20,8), @tot_ovhd_cost decimal(20,8), @tot_util_cost decimal(20,8), @tot_labor_cost decimal(20,8),  
  @r_cost decimal(20,8), @r_direct decimal(20,8), @r_overhead decimal(20,8), @r_utility decimal(20,8), @r_labor decimal(20,8),  
  @jobext int  
  
  if NOT ((@i_tran_type = 'U' and (left(@i_tran_data,2) = 'XJ')) -- do not do for misc part on job production  
    or (@i_tran_type = 'R' and substring(@i_tran_data,3,1) = 'M') -- do not do for misc parts on receipts  
    or (@i_tran_type = 'S' and left(@i_tran_data,1) = 'J')) -- do not do for jobs on sales orders  
  begin  
    execute @rc = adm_get_inv_cost @i_part_no OUT, @i_location OUT,  
      @use_ac OUT, @in_stock OUT, @inv_holds OUT, @non_holds OUT, @typ OUT, @m_status OUT, @acct_code OUT,  
      @std_uom OUT,  
      @avg_unitcost OUT, @avg_direct OUT, @avg_overhead OUT, @avg_utility OUT, @avg_labor OUT,  
      @std_unitcost OUT, @std_direct OUT, @std_overhead OUT, @std_utility OUT, @std_labor OUT,  
      @cl_qty OUT  
  
    if @rc != 1    
      goto adm_get_inv_cost_error  
  end  
  else  
  begin  
    select @m_status = '!', @typ = 'A', @use_ac = 'Y',  
      @avg_unitcost = 0, @avg_direct = 0, @avg_overhead = 0, @avg_utility = 0, @avg_labor = 0,  
      @std_unitcost = 0, @std_direct = 0, @std_overhead = 0, @std_utility = 0, @std_labor = 0,  
      @in_stock = 0, @inv_holds = 0, @non_holds = 0, @std_uom = 'EA', @cl_qty = 0  
  
    if @i_tran_type = 'U'  
      select @acct_code = aracct_code  
      from locations_all (nolock) where location = @i_location  
  
    if @i_tran_type = 'R'  
    begin  
      select @acct_code = apacct_code  
      from locations_all (nolock) where location = @i_location  
    end  
  
    if @i_tran_type = 'S'       -- mls 1/26/04 start  
    begin  
      select @jobext = isnull((select max(prod_ext) from produce_all (nolock) where prod_no = convert(int,@i_part_no)),0)   
  
      select @acct_code = posting_code from produce_all (nolock) where prod_no = convert(int,@i_part_no)  
      and prod_ext = @jobext  
    end          -- mls 1/26/04 end  
  end  
  
  select   
    @tran_date = getdate(),  
    @i_apply_date = isnull(@i_apply_date,getdate()),  
    @l_typ = case when @typ in ('1','2','3','4','5','6','7','8','9') then 'W'   
        when @typ not in ('A','L','F','S','E') then 'A' else @typ end,  
    @o_in_stock = @in_stock + @inv_holds,  
    @unitcost = 0, @direct = 0, @overhead = 0, @utility = 0, @labor = 0,  
    @trn_unitcost = 0, @trn_direct = 0, @trn_overhead = 0, @trn_utility = 0, @trn_labor = 0,  
    @inv_unitcost = 0, @inv_direct = 0, @inv_overhead = 0, @inv_utility = 0, @inv_labor = 0,  
    @hold_qty = 0,  
    @process_typ = '', @update_typ = 'I',  
    @i_tran_id = 0,  
    @cl_account = 'STOCK',  
    @layer_qty = 0, @skip_costing = 1,  
    @c_tran_type = @i_tran_type, @i_trigger = 'I',  
    @d_qc_flag = 'N', @i_qc_flag = 'N', @i_qty = 0, @i_cost = 0,  
    @cogs_qty = 0  
  
  if @l_typ = 'W'  
    select @wavg_unitcost = @avg_unitcost, @wavg_direct = @avg_direct, @wavg_overhead = @avg_overhead,  
      @wavg_utility = @avg_utility  
  
  select @rc = 0, @sub_function = 'Unknown tran type'  
  
  
CREATE TABLE #cost_lots (lot_ser varchar(255) NOT NULL, qty decimal(20,8),  
cl_qty decimal(20,8), lot_qty decimal(20,8) NULL, cl_upd_ind int NULL,  
tot_mtrl_cost decimal(20,8) null, tot_dir_cost decimal(20,8) null,   
tot_ovhd_cost decimal(20,8) null, tot_util_cost decimal(20,8) null,   
tot_labor_cost decimal(20,8) null, row_id int identity(0,1))  
create index cl1 on #cost_lots(lot_ser)  
  
--------------------------------------------------------------------------------------  
  
  if @i_tran_type = 'I'  -- issues  
  begin  
    IF @m_status in ('C','V')  
    BEGIN  
      rollback tran  
      RAISERROR 83202 'You can not adjust Custom Kit or Non-Quantity Bearing Items.'  
      RETURN -1  
    END  
  
    select @sub_function = 'adm_inv_tran_issue',   
      @i_quantity = @i_uom_quantity * @i_conv_factor  
  
    if @l_typ = 'S' and substring(@i_tran_data,10,1) != 'Q'  
      select @i_mtrl_cost = @std_unitcost * @i_quantity, @i_dir_cost = @std_direct * @i_quantity,  
        @i_ovhd_cost = @std_overhead * @i_quantity, @i_util_cost = @std_utility * @i_quantity, @i_labor_cost= @std_labor * @i_quantity  
  
    exec @rc = adm_inv_tran_issue 'start of adm_inv_tran', @i_tran_no , @i_part_no , @i_location ,  
      @i_quantity , @i_apply_date , @i_tran_data , @i_update_ind OUT, 0, @o_in_stock, @l_typ,  
      @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
      @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @update_typ OUT  
  end  
  if @i_tran_type = 'S'  
  begin  
    select @sub_function = 'adm_inv_tran_sales',  
      @i_quantity = @i_uom_quantity * @i_conv_factor  
  
    exec @rc = adm_inv_tran_sales 'start of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
      @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @update_typ OUT, @hold_qty OUT, @l_typ,  
      @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
      @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @process_typ OUT  
  
  end  
  if @i_tran_type = 'R' -- Receiving (receipts table)  
  begin  
    select @sub_function = 'adm_inv_tran_receipt',  
      @i_quantity = @i_uom_quantity * @i_conv_factor,  
      @i_mtrl_cost = @o_unitcost, @i_dir_cost = @o_direct, @i_ovhd_cost = @o_overhead, @i_util_cost = @o_utility,  
      @i_labor_cost = @o_labor  
  
    exec @rc = adm_inv_tran_receipt 'start of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @l_typ, @m_status, @i_quantity OUT, @i_conv_factor, @i_apply_date , @i_status,   
      @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock OUT, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
      @std_unitcost OUT, @std_direct OUT, @std_overhead OUT, @std_utility OUT,  
      @cl_account OUT, @update_typ OUT, @layer_qty OUT, @skip_costing OUT, @d_qc_flag OUT, @i_qc_flag OUT,  
      @i_qty OUT, @i_trigger OUT, @i_cost OUT  
  
    if @i_update_ind < 0  -- misc part_type  
    begin  
      select @trn_unitcost = @i_mtrl_cost, @trn_direct = @i_dir_cost, @trn_overhead = @i_ovhd_cost, @trn_utility = @i_util_cost,  
        @trn_labor = @i_labor_cost  
    end  
  end  
  if @i_tran_type = 'P' -- Production (finished good)  
  begin  
    select @sub_function = 'adm_inv_tran_produce',  
      @i_quantity = @i_uom_quantity * @i_conv_factor,  
      @i_mtrl_cost=@avg_unitcost, @i_dir_cost=@avg_direct, @i_ovhd_cost=@avg_overhead,  
      @i_util_cost=@avg_utility, @i_labor_cost = @avg_labor  
  
    exec @rc = adm_inv_tran_produce 'start of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @l_typ, @m_status, @i_quantity , @i_conv_factor, @i_apply_date , @i_status,   
      @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock OUT, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
      @std_unitcost OUT, @std_direct OUT, @std_overhead OUT, @std_utility OUT  
  end  
  if @i_tran_type = 'U' -- Production (subcomponent usage)  
  begin  
    select @sub_function = 'adm_inv_tran_usage',  
      @i_quantity = @i_uom_quantity * @i_conv_factor,  
      @i_mtrl_cost=@avg_unitcost, @i_dir_cost=@avg_direct, @i_ovhd_cost=@avg_overhead,  
      @i_util_cost=@avg_utility, @i_labor_cost = @avg_labor,  
      @c_tran_type = 'P'      
  
    exec @rc = adm_inv_tran_usage 'start of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @l_typ OUT, @m_status, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data ,   
      @i_update_ind OUT,   
      0, @o_in_stock OUT, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
      @std_unitcost OUT, @std_direct OUT, @std_overhead OUT, @std_utility OUT,   
      @cl_account OUT  
  
    if @i_update_ind = -2  
      select @o_unitcost = 0, @o_direct = 0, @o_overhead = 0, @o_utility = 0, @o_labor = 0,  
        @i_mtrl_cost = 0, @i_dir_cost = 0, @i_ovhd_cost = 0, @i_util_cost = 0, @i_labor_cost = 0  
  end  
  if @i_tran_type = 'K'  
  begin  
    select @sub_function = 'adm_inv_tran_sales_kit',  
      @i_quantity = @i_uom_quantity * @i_conv_factor  
    exec @rc = adm_inv_tran_sales_kit 'start of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
      @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @update_typ OUT, @hold_qty OUT, @l_typ,  
      @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
      @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @process_typ OUT  
  end  
  if @i_tran_type = 'X'  
  begin  
    select @sub_function = 'adm_inv_tran_xfer',  
      @i_quantity = @i_uom_quantity * @i_conv_factor  
    exec @rc = adm_inv_tran_xfer 'start of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock, @l_typ, @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
      @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
      @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT, @update_typ OUT, @hold_qty OUT  
  end  
  if @i_tran_type = 'C' -- Cost layer adjustment (inv_costing_audit table)  
  begin  
    select @i_quantity = @i_uom_quantity * @i_conv_factor,  
      @sub_function = 'adm_inv_tran_cost_adj',  
      @update_typ = 'C', @rc = 1  
  end  
  if @i_tran_type = 'L' -- Landed cost allocation (adm_cost_adjust) - update overhead dollars  
  begin  
    select @sub_function = 'adm_inv_tran_landed_cost',  
      @i_quantity = @i_uom_quantity  
    exec @rc = adm_inv_tran_landed_cost 'start of adm_inv_tran', @i_tran_no , @i_tran_line, @i_part_no ,  
      @i_location , @l_typ, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock, @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
      @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @update_typ OUT  
  end  
  if @i_tran_type = 'N' -- New Std Cost (new_cost table)   
  begin  
    select @sub_function = 'adm_inv_tran_new_cost',  
      @i_quantity = @i_uom_quantity  
    exec @rc = adm_inv_tran_new_cost 'start of adm_inv_tran', @i_tran_no , @i_tran_line, @i_part_no ,  
      @i_location , @l_typ, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock, @std_unitcost OUT, @std_direct OUT, @std_overhead OUT, @std_utility OUT,   
      @o_unitcost OUT, @o_direct OUT, @o_overhead OUT, @o_utility OUT, @update_typ OUT,  
      DEFAULT, DEFAULT, @use_ac  
  end  
  
  if @rc != 1  
    goto adm_inv_tran_error  
  
--------------------------------------------------------------------------------------  
  
  if @l_typ != 'S' and @use_ac = 'Y'        
    and (@avg_unitcost != 0 or @avg_direct = 0 or @avg_overhead != 0 or @avg_utility != 0 or @avg_labor != 0)    
    select @neg_unitcost = @avg_unitcost, @neg_direct = @avg_direct, @neg_overhead = @avg_overhead, @neg_utility = @avg_utility,  
      @neg_labor = @avg_labor, @neg_typ = 'A'  
  else  
    select @neg_unitcost = @std_unitcost, @neg_direct = @std_direct, @neg_overhead = @std_overhead, @neg_utility = @std_utility,  
      @neg_labor = @std_labor, @neg_typ = 'S'  
  
  
  select @inv_qty = @i_quantity  
  
  if @i_tran_type = 'R' and @i_update_ind >= 0 and @d_qc_flag = 'Y'  
  begin  
    delete from inv_costing  
    where tran_code = 'R' and tran_no = @i_tran_no and account = 'QC'  
  end  
  if @i_tran_type = 'R' and @i_update_ind >= 0 and @i_qc_flag = 'Y'  
  begin  
    exec @retval=fs_cost_insert @i_part_no, @i_location, @i_qty, 'R', @i_tran_no, @i_tran_ext, @i_tran_line,  
      'QC', @tran_date, @i_apply_date, @i_cost, 0, 0, 0, 0,   
      @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
      @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac  
  
    if @retval != 1   
    begin  
      rollback tran  
      raiserror 83225 'Costing Error... Try Re-Saving!'  
      return -1  
    end  
  
    select @trn_unitcost = @i_mtrl_cost  
  end  
  
--------------------------------------------------------------------------------------  
  
    
  if @i_quantity < 0 and @i_update_ind >= 0 and @update_typ = 'I' and @i_qc_flag != 'Y'  
  begin   
    select @process_typ = ''  
    if @i_tran_type not in ('P','R')  
    begin  
      select @l_qty = @i_quantity * -1  
      exec @retval=fs_cost_delete @i_part_no, @i_location, @l_qty, @c_tran_type, @i_tran_no, @i_tran_ext, @i_tran_line,   
        @cl_account, @tran_date, @i_apply_date, @unitcost OUT, @direct OUT, @overhead OUT, @labor OUT, @utility OUT,  
        @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
        @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac  
      if @retval != 1  
      begin  
        rollback tran  
        raiserror 83221 'Costing Error... Try Re-Saving!'  
        return -1   
      end  
      select @trn_unitcost= @unitcost, @trn_direct= @direct , @trn_overhead= @overhead, @trn_utility= @utility,  
        @trn_labor = @labor  
      select @inv_unitcost= @unitcost, @inv_direct= @direct , @inv_overhead= @overhead, @inv_utility= @utility,  
        @inv_labor = @labor  
    end  
    if @i_tran_type = 'P'   
    begin -- i_tran_type = P (productions)   
      if @o_in_stock >= 0   
--       and ((substring(@i_tran_data,2,1) = '0'   
--and (((@o_in_stock + @i_quantity) >= 0 and left(@i_tran_data,1) != 'R')  
--        or (@o_in_stock + @i_quantity) < 0)  
      begin  
        if @o_in_stock >= 0 and (@o_in_stock + @i_quantity) < 0 and @l_typ != 'S'  
          select @COGS = 3  
  
        select @l_qty = @i_quantity * -1  
        exec @retval=fs_cost_delete @i_part_no, @i_location, @l_qty, @c_tran_type, @i_tran_no, @i_tran_ext, @i_tran_line,   
          @cl_account, @tran_date, @i_apply_date, @unitcost OUT, @direct OUT, @overhead OUT, @labor OUT, @utility OUT,  
          @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
          @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac  
        if @retval != 1  
        begin  
          rollback tran  
          raiserror 83221 'Costing Error... Try Re-Saving!'  
          return -1   
        end  
        if @COGS = 0  
          select @trn_unitcost= @unitcost, @trn_direct= @direct , @trn_overhead= @overhead, @trn_utility= @utility,  
            @trn_labor = @labor  
        else  
          select @trn_unitcost= @i_mtrl_cost , @trn_direct= @i_dir_cost  ,   
            @trn_overhead= @i_ovhd_cost , @trn_utility= @i_util_cost ,  
            @trn_labor = @i_labor_cost   
  
          select @inv_unitcost= @unitcost, @inv_direct= @direct , @inv_overhead= @overhead, @inv_utility= @utility,  
            @inv_labor = @labor  
      end  
      else  
      begin  
        select @unitcost= @i_mtrl_cost, @direct= @i_dir_cost, @overhead= @i_ovhd_cost, @labor= @i_labor_cost, @utility= @i_util_cost  
        select @trn_unitcost= @unitcost , @trn_direct= @direct ,  
          @trn_overhead= @overhead , @trn_utility= @utility ,  
          @trn_labor = @labor   
  
        if @o_in_stock < 0 and (@o_in_stock + @i_quantity) < 0 and @l_typ != 'S'  
        begin  
          select @COGS = 1, @process_typ = @neg_typ  
          select @unitcost = @neg_unitcost * @i_quantity, @direct = @neg_direct * @i_quantity,   
            @overhead = @neg_overhead * @i_quantity, @utility = @neg_utility * @i_quantity,   
            @labor = @neg_labor * @i_quantity  
        end  
        exec @retval=fs_cost_insert @i_part_no, @i_location, @i_quantity, @c_tran_type, @i_tran_no, @i_tran_ext, @i_tran_line,   
          @cl_account, @tran_date, @i_apply_date, @i_mtrl_cost, @i_dir_cost, @i_ovhd_cost, @i_labor_cost, @i_util_cost,  
          @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
          @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac,  
          @COGS, @i_quantity, @neg_unitcost, @neg_direct, @neg_overhead, @neg_utility, @neg_labor  
        if @retval != 1  
        begin  
          rollback tran  
          raiserror 83221 'Costing Error... Try Re-Saving!'  
          return -1   
        end  
  
        select @inv_unitcost= @unitcost , @inv_direct= @direct ,   
          @inv_overhead= @overhead , @inv_utility= @utility ,  
          @inv_labor = @labor   
      end  
    end -- i_tran_type = 'P'  
    if @i_tran_type = 'R'  
    begin -- i_tran_type = R (receipts)   
      select @o_in_stock_value = @o_in_stock * @avg_unitcost,  
        @i_quantity_value = @i_mtrl_cost  
      if @l_typ in ('S','W') -- this is the old logic.... no changes  
      BEGIN  
        if (@o_in_stock >= 0) or @l_typ = 'S'  
        begin  
          if @l_typ != 'S' and (@o_in_stock + @i_quantity) < 0  
            select @COGS = 3  
  
          select @l_qty = @i_quantity * -1  
          exec @retval=fs_cost_delete @i_part_no, @i_location, @l_qty, @c_tran_type, @i_tran_no, @i_tran_ext, @i_tran_line,   
            @cl_account, @tran_date, @i_apply_date, @unitcost OUT, @direct OUT, @overhead OUT, @labor OUT, @utility OUT,  
            @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
            @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac  
          if @retval != 1  
          begin  
            rollback tran  
            raiserror 83221 'Costing Error... Try Re-Saving!'  
            return -1   
          end  
  
          select @trn_unitcost= @i_mtrl_cost , @trn_direct= @i_dir_cost  ,   
            @trn_overhead= @i_ovhd_cost , @trn_utility= @i_util_cost ,  
            @trn_labor = @i_labor_cost   
          select @inv_unitcost= @unitcost, @inv_direct= @direct , @inv_overhead= @overhead, @inv_utility= @utility,  
            @inv_labor = @labor  
        end  
        else  
        begin  
          select @unitcost= @i_mtrl_cost, @direct= @i_dir_cost, @overhead= @i_ovhd_cost, @labor= @i_labor_cost,   
            @utility= @i_util_cost  
          select @trn_unitcost= @unitcost , @trn_direct= @direct ,   
            @trn_overhead= @overhead , @trn_utility= @utility ,  
            @trn_labor = @labor   
   
          if @o_in_stock < 0 and (@o_in_stock + @i_quantity) < 0 and @l_typ != 'S'  
          begin  
            select @COGS = 1, @process_typ = @neg_typ,  
              @unitcost = @neg_unitcost * @i_quantity, @direct = @neg_direct * @i_quantity, @overhead = @neg_overhead * @i_quantity,   
              @utility = @neg_utility * @i_quantity, @labor = @neg_labor * @i_quantity  
          end  
  
          exec @retval=fs_cost_insert @i_part_no, @i_location, @i_quantity, @c_tran_type, @i_tran_no, @i_tran_ext, @i_tran_line,   
            @cl_account, @tran_date, @i_apply_date, @unitcost, @direct, @overhead, @labor, @utility,  
            @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
            @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac,  
            @COGS, @i_quantity, @neg_unitcost, @neg_direct, @neg_overhead, @neg_utility, @neg_labor  
          if @retval != 1  
          begin  
            rollback tran  
            raiserror 83221 'Costing Error... Try Re-Saving!'  
            return -1   
          end  
  
          select @inv_unitcost= @unitcost , @inv_direct= @direct ,   
            @inv_overhead= @overhead , @inv_utility= @utility , @inv_labor = @labor   
  
        end  
      end -- typ = S,W  
      else  
      begin  
        select @unitcost= @i_mtrl_cost, @direct= @i_dir_cost, @overhead= @i_ovhd_cost, @labor= @i_labor_cost, @utility= @i_util_cost  
        select @trn_unitcost= @unitcost , @trn_direct= @direct  ,   
          @trn_overhead= @overhead , @trn_utility= @utility ,  
          @trn_labor = @labor  
  
        --Delta costing Layer for the QTY that we found!  
        exec @retval= fs_cost_update @i_part_no, @i_location, @i_qty, @i_tran_type, @i_tran_no, @i_tran_ext,   
          @i_tran_line, @cl_account, @tran_date, @i_apply_date, @i_quantity, @i_cost,  
          @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
          @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor,  
          @m_status, @use_ac, @typ,  
          @neg_unitcost, @neg_direct, @neg_overhead, @neg_labor, @neg_utility,  
          @cogs_qty OUT,  
          @unitcost OUT, @direct OUT, @overhead OUT, @labor OUT, @utility OUT, @l_typ  
  
        IF @retval != 1   
        BEGIN  
          rollback tran  
          raiserror 913534 'Costing Error... Try Re-Saving!'  
          return  
        END  
  
        if @unitcost != @trn_unitcost select @COGS = 3, @process_typ = '(0)'  
        if @cogs_qty != 0 select @COGS = 1, @process_typ = @neg_typ  
  
        select @inv_unitcost = @unitcost, @inv_direct = @direct, @inv_overhead = @overhead, @inv_utility = @utility,  
          @inv_labor = @labor  
  
        -- the update of inv_costing triggers an update of the inventory view, and   
        -- recalculates the average cost  
        -- this average cost needs to be updated in the inv_costing rows  
        if @l_typ = 'A'   
        begin  
          select @avg_cost = 0, @avg_dir = 0, @avg_oh = 0, @avg_utl = 0, @avg_labor = 0   -- mls 9/18/00 23804  
          select @avg_cost = avg_cost,  
            @avg_dir = avg_direct_dolrs,         -- mls 9/18/00 23804  
            @avg_oh = avg_ovhd_dolrs,         -- mls 9/18/00 23804  
            @avg_utl = avg_util_dolrs         -- mls 9/18/00 23804  
          from cvo_inventory2 inventory (NOLOCK) -- v1.0   
          where inventory.part_no = @i_part_no and inventory.location = @i_location  
  
          select @qty= sum( balance ),  
            @tot_mtrl_cost = sum(isnull(tot_mtrl_cost,unit_cost * balance)),  
            @tot_dir_cost = sum(isnull(tot_dir_cost,direct_dolrs * balance)),  
            @tot_ovhd_cost = sum(isnull(tot_ovhd_cost,ovhd_dolrs * balance)),  
            @tot_util_cost = sum(isnull(tot_util_cost,util_dolrs * balance)),  
            @tot_labor_cost = sum(isnull(tot_labor_cost,labor * balance)),  
            @max_seq = max(sequence)  
          from inv_costing   
          where part_no = @i_part_no and location = @i_location and account = @cl_account  
  
          select @r_cost = @tot_mtrl_cost - (@avg_cost * @qty),  
            @r_direct = @tot_dir_cost - (@avg_dir * @qty),  
            @r_overhead = @tot_ovhd_cost - (@avg_oh * @qty),  
            @r_utility = @tot_util_cost - (@avg_utl * @qty),  
            @r_labor = @tot_labor_cost - (@avg_labor * @qty)  
  
          update inv_costing   
          set unit_cost = @avg_cost,   
            direct_dolrs = @avg_dir,   
            ovhd_dolrs = @avg_oh,  
            util_dolrs = @avg_utl,  
            labor = @avg_labor,  
            tot_mtrl_cost = (@avg_cost * balance) + case when sequence = @max_seq then @r_cost else 0 end,  
            tot_dir_cost = (@avg_dir * balance) + case when sequence = @max_seq then @r_direct else 0 end,  
            tot_ovhd_cost = (@avg_oh * balance) + case when sequence = @max_seq then @r_overhead else 0 end,  
            tot_util_cost = (@avg_utl * balance) + case when sequence = @max_seq then @r_utility else 0 end,  
            tot_labor_cost = (@avg_labor * balance) + case when sequence = @max_seq then @r_labor else 0 end  
          where part_no = @i_part_no and location = @i_location and account  = @cl_account  
        end  
      end  
    end -- i_tran_type = 'R'  
  
    select @process_typ = '(' + case when @o_in_stock >= 0 then '+' else '-' end + ' ' +  
      case when @o_in_stock + @i_quantity >= 0 then '+' else '-' end + ') ' + @process_typ  
  end   
  
  
--------------------------------------------------------------------------------------  
  
  
  if @i_quantity > 0 and @i_update_ind >= 0 and @update_typ = 'I' and @i_qc_flag != 'Y'     
  begin   
    if @i_tran_type = 'R' and (@d_qc_flag != 'Y' and @l_typ not in ('S','W')) and @i_trigger = 'U'  
    begin  
      select @unitcost= @i_mtrl_cost, @direct= @i_dir_cost, @overhead= @i_ovhd_cost, @labor= @i_labor_cost, @utility= @i_util_cost  
      select @trn_unitcost= @unitcost , @trn_direct= @direct ,   
        @trn_overhead= @overhead , @trn_utility= @utility  ,  
        @trn_labor = @labor   
  
      --Delta costing Layer for the QTY that we found!  
      exec @retval= fs_cost_update @i_part_no, @i_location, @i_qty, @i_tran_type, @i_tran_no, @i_tran_ext,   
        @i_tran_line, @cl_account, @tran_date, @i_apply_date, @i_quantity, @i_cost,   
        @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
        @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor,  
        @m_status, @use_ac, @typ,  
        @neg_unitcost, @neg_direct, @neg_overhead, @neg_labor, @neg_utility,  
          @cogs_qty OUT,  
          @unitcost OUT, @direct OUT, @overhead OUT, 0, @utility OUT, @l_typ  
  
      IF @retval != 1   
      BEGIN  
        rollback tran  
        raiserror 913534 'Costing Error... Try Re-Saving!'  
        return  
      END  
  
      if @cogs_qty = 0 select @process_typ = '(+ +) ' + @process_typ  
      else if @cogs_qty = @i_quantity select @COGS = 1, @process_typ = '(- -) ' + @process_typ  
      else select @COGS = 2, @process_typ = '(- +) ' + @process_typ  
  
      select @inv_unitcost= @unitcost, @inv_direct= @direct , @inv_overhead= @overhead, @inv_utility= @utility,  
        @inv_labor = @labor  
  
      -- the update of inv_costing triggers an update of the inventory view, and   
      -- recalculates the average cost  
      -- this average cost needs to be updated in the inv_costing rows  
      if @l_typ = 'A'   
      begin  
        select @avg_cost = 0, @avg_dir = 0, @avg_oh = 0, @avg_utl = 0, @avg_labor = 0   -- mls 9/18/00 23804  
        select @avg_cost = avg_cost,  
          @avg_dir = avg_direct_dolrs,         -- mls 9/18/00 23804  
          @avg_oh = avg_ovhd_dolrs,         -- mls 9/18/00 23804  
          @avg_utl = avg_util_dolrs         -- mls 9/18/00 23804        
        from cvo_inventory2 inventory (NOLOCK) -- v1.0   
        where inventory.part_no = @i_part_no and inventory.location = @i_location  
  
        select @qty= sum( balance ),  
          @tot_mtrl_cost = sum(isnull(tot_mtrl_cost,unit_cost * balance)),  
          @tot_dir_cost = sum(isnull(tot_dir_cost,direct_dolrs * balance)),  
          @tot_ovhd_cost = sum(isnull(tot_ovhd_cost,ovhd_dolrs * balance)),  
          @tot_util_cost = sum(isnull(tot_util_cost,util_dolrs * balance)),  
          @tot_labor_cost = sum(isnull(tot_labor_cost,labor * balance)),  
          @max_seq = max(sequence)  
        from inv_costing   
        where part_no = @i_part_no and location = @i_location and account = @cl_account  
  
        select @r_cost = @tot_mtrl_cost - (@avg_cost * @qty),  
          @r_direct = @tot_dir_cost - (@avg_dir * @qty),  
          @r_overhead = @tot_ovhd_cost - (@avg_oh * @qty),  
          @r_utility = @tot_util_cost - (@avg_utl * @qty),  
          @r_labor = @tot_labor_cost - (@avg_labor * @qty)  
  
        update inv_costing   
        set unit_cost = @avg_cost,   
          direct_dolrs = @avg_dir,   
          ovhd_dolrs = @avg_oh,  
          util_dolrs = @avg_utl,  
          labor = @avg_labor,  
          tot_mtrl_cost = (@avg_cost * balance) + case when sequence = @max_seq then @r_cost else 0 end,  
          tot_dir_cost = (@avg_dir * balance) + case when sequence = @max_seq then @r_direct else 0 end,  
          tot_ovhd_cost = (@avg_oh * balance) + case when sequence = @max_seq then @r_overhead else 0 end,  
          tot_util_cost = (@avg_utl * balance) + case when sequence = @max_seq then @r_utility else 0 end,  
          tot_labor_cost = (@avg_labor * balance) + case when sequence = @max_seq then @r_labor else 0 end  
        where part_no = @i_part_no and location = @i_location and account  = @cl_account  
      end  
    end --@i_tran_type = 'R' and (@d_qc_flag != 'Y' and @l_typ not in ('S','W')) and @i_trigger = 'U'   
    else  
    begin  
      if @i_tran_type = 'R' and @i_trigger = 'U' and @d_qc_flag != 'Y'  
        select @l_qty = case when @layer_qty < @i_quantity then @i_quantity else @layer_qty end  
      else   
        select @l_qty = @i_quantity           
   
      select @unitcost = @i_mtrl_cost, @direct = @i_dir_cost, @overhead = @i_ovhd_cost, @utility = @i_util_cost,   
        @labor = @i_labor_cost  
  
      IF ( @unitcost = 0 and  @direct = 0 and @overhead = 0 and @utility = 0 and @labor = 0)   
      BEGIN  
        if @i_tran_type in ('I','S','K')  
        begin  
          if @i_tran_type = 'I'         -- mls 6/17/04 start  
          begin  
            if (left(@i_tran_data,4)  = 'PHY ' )  
            BEGIN  
              if @l_typ != 'S' and (@avg_unitcost != 0 or @avg_direct != 0 or @avg_overhead != 0 or @avg_utility != 0 or @avg_labor != 0)  
               select @unitcost = @avg_unitcost * @l_qty, @direct = @avg_direct * @l_qty,   
                @overhead = @avg_overhead * @l_qty, @utility = @avg_utility * @l_qty, @labor = @avg_labor * @l_qty,  
                @process_typ = 'A'  
            else  
              select @unitcost = @std_unitcost * @l_qty, @direct = @std_direct * @l_qty,   
                @overhead = @std_overhead * @l_qty, @utility = @std_utility * @l_qty, @labor = @std_labor * @l_qty,  
                @process_typ = 'S'  
            END   
          END  
         else           -- mls 6/17/04 end  
         begin  
          --Get Average or Standard cost  
          if @l_typ != 'S' and (@avg_unitcost != 0 or @avg_direct != 0 or @avg_overhead != 0 or @avg_utility != 0 or @avg_labor != 0)  
            select @unitcost = @avg_unitcost * @l_qty, @direct = @avg_direct * @l_qty,   
              @overhead = @avg_overhead * @l_qty, @utility = @avg_utility * @l_qty, @labor = @avg_labor * @l_qty,  
              @process_typ = 'A'  
          else  
            select @unitcost = @std_unitcost * @l_qty, @direct = @std_direct * @l_qty,   
              @overhead = @std_overhead * @l_qty, @utility = @std_utility * @l_qty, @labor = @std_labor * @l_qty,  
              @process_typ = 'S'  
          end  
        end  
      END  
  
      select @trn_unitcost= @unitcost, @trn_direct= @direct, @trn_overhead= @overhead, @trn_utility=@utility, --Get Actual Cost  
        @trn_labor = @labor  
  
      if ( @o_in_stock ) >= 0 or (@l_typ = 'S' and (@i_tran_type = 'R' or @m_status = 'R'))  
      begin  
        if @l_typ != 'S'  
          select @inv_unitcost= @unitcost, @inv_direct= @direct , @inv_overhead= @overhead, @inv_utility= @utility, @inv_labor = @labor  
        else  
          select @inv_unitcost= @std_unitcost * @l_qty, @inv_direct= @std_direct * @l_qty ,   
            @inv_overhead= @std_overhead * @l_qty, @inv_utility= @std_utility * @l_qty, @inv_labor = @std_labor * @l_qty,  
            @unitcost= @std_unitcost * @l_qty, @direct= @std_direct  * @l_qty,   
            @overhead= @std_overhead * @l_qty, @utility= @std_utility * @l_qty, @labor = @std_labor * @l_qty  
  
        --Insert into cost layer  
        exec @retval=fs_cost_insert @i_part_no, @i_location, @l_qty, @c_tran_type, @i_tran_no,   
          @i_tran_ext, @i_tran_line, @cl_account, @tran_date, @i_apply_date,   
          @inv_unitcost OUT , @inv_direct OUT, @inv_overhead OUT, @inv_labor OUT, @inv_utility OUT,   
          @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
          @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac  
  
        if @retval != 1   
        begin  
          rollback tran  
          raiserror 83225 'Costing Error... Try Re-Saving!'  
          return -1  
        end  
  
 if @l_typ in ('F','L') and @c_tran_type = 'X'  
        begin  
          select @unitcost = @inv_unitcost, @direct = @inv_direct, @overhead = @inv_overhead, @labor = @inv_labor,  
            @utility = @inv_utility  
          select @trn_unitcost= @unitcost, @trn_direct= @direct, @trn_overhead= @overhead, @trn_utility=@utility, --Get Actual Cost  
            @trn_labor = @labor  
        end  
  
        select @process_typ = '(+ +) ' + @process_typ  
      end  
      else -- ( @o_in_stock ) < 0  
      begin  
        --Case in stock of inv_list is negative  
        select @l_in_stock = @o_in_stock * -1 --convert in_stock to positive number  
        --Get Average or Standard cost  
        select @process_typ = @neg_typ  
        select @unitcost = @neg_unitcost, @direct = @neg_direct, @overhead = @neg_overhead, @utility = @neg_utility,  
          @labor = @neg_labor  
  
        if ( @l_in_stock - @l_qty ) >= 0   
        begin        
          --Case the balance of the end result of the qty is still negative  
          if @l_typ != 'S' Select @COGS = 1  --Set Cost of Good Sold to true   
  
          select  
            @inv_unitcost =  case when @l_typ = 'S' then @std_unitcost * @l_qty else @unitcost * @l_qty end,  
            @inv_direct = case when @l_typ = 'S' then @std_direct * @l_qty  else @direct * @l_qty  end,  
            @inv_overhead = case when @l_typ = 'S' then @std_overhead * @l_qty  else @overhead * @l_qty  end,  
            @inv_utility = case when @l_typ = 'S' then @std_utility * @l_qty  else @utility * @l_qty  end,  
            @inv_labor = case when @l_typ = 'S' then @std_labor * @l_qty  else @labor * @l_qty  end  
  
          --insert the 1st cost layer that made  
          exec @retval=fs_cost_insert @i_part_no, @i_location, @l_qty, @c_tran_type, @i_tran_no,   
            @i_tran_ext, @i_tran_line, @cl_account, @tran_date, @i_apply_date,   
            @inv_unitcost OUT, @inv_direct OUT, @inv_overhead OUT, @inv_labor OUT, @inv_utility OUT,   
            @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
            @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac,  
            @COGS, @l_qty, @neg_unitcost OUT, @neg_direct OUT, @neg_overhead OUT, @neg_utility OUT, @neg_labor OUT  
            
          if @retval != 1   
          begin  
            rollback tran  
            raiserror 83225 'Costing Error... Try Re-Saving!'  
            return -1  
          end  
  
     if @l_typ in ('F','L') and @c_tran_type = 'X'  
          begin  
     select @trn_unitcost = @neg_unitcost, @trn_direct = @neg_direct, @trn_overhead = @neg_overhead,  
              @trn_utility = @neg_utility, @trn_labor = @neg_labor  
          end  
  
          select @process_typ = '(- -) ' + @process_typ,  
            @cogs_qty = case when @l_typ != 'S' then @l_qty else 0 end  
        end -- @cogs = 1 - to -  
        else  
        begin  
          if @l_typ != 'S' Select @COGS = 2  --Set Cost of Good Sold to true     -- mls 6/16/05 SCR 35043  
          Select @cogs_qty = case when @l_typ != 'S' then @l_qty - @l_in_stock else 0 end  -- mls 6/16/05 SCR 35043  
          --Case the balance of the end result of the qty is from negative to positive  
  
          --insert the 1st cost layer that made the balance to 0  
          if @l_typ != 'W'        -- mls 5/23/00 SCR 22567  
          begin         
            select  
              @inv_unitcost =  case when @l_typ = 'S' then @std_unitcost * @l_qty else @trn_unitcost end,  
              @inv_direct = case when @l_typ = 'S' then @std_direct * @l_qty  else @trn_direct end,  
              @inv_overhead = case when @l_typ = 'S' then @std_overhead * @l_qty  else @trn_overhead end,  
              @inv_utility = case when @l_typ = 'S' then @std_utility * @l_qty  else @trn_utility end,  
              @inv_labor = case when @l_typ = 'S' then @std_labor * @l_qty  else @trn_labor end  
  
            exec @retval=fs_cost_insert @i_part_no, @i_location, @l_in_stock, @c_tran_type,   
              @i_tran_no, @i_tran_ext, @i_tran_line, @cl_account, @tran_date,  
              @i_apply_date, @inv_unitcost OUT, @inv_direct OUT, @inv_overhead OUT, @inv_labor OUT, @inv_utility OUT,  
              @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
              @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac,  
              @COGS, @l_qty, @neg_unitcost OUT, @neg_direct OUT, @neg_overhead OUT, @neg_utility OUT, @neg_labor OUT  
               
            if @retval != 1  
            begin  
              rollback tran  
              raiserror 83221 'Costing Error... Try Re-Saving!'  
              return -1  
            end  
  
  
     if @l_typ in ('F','L') and @c_tran_type = 'X'  
            begin  
       select @trn_unitcost = @neg_unitcost, @trn_direct = @neg_direct, @trn_overhead = @neg_overhead,  
                @trn_utility = @neg_utility, @trn_labor = @neg_labor  
            end  
          end -- @l_typ != 'w'  
  
          --After reset the cost layer, insert the 1st cost layer   
          -- with positive balance.  
          --note @l_in_stock is negative number at this point  
  
          if @l_typ = 'W'    
          begin  
            select  
              @inv_unitcost =  @trn_unitcost / @l_qty,  
              @inv_direct = @trn_direct / @l_qty,  
              @inv_overhead = @trn_overhead / @l_qty,  
              @inv_utility = @trn_utility / @l_qty,  
              @inv_labor = @trn_labor / @l_qty  
  
            select @inv_unitcost = @inv_unitcost * @cogs_qty,  
              @inv_direct = @inv_direct * @cogs_qty,  
              @inv_overhead = @inv_overhead * @cogs_qty,  
              @inv_utility = @inv_utility * @cogs_qty,  
              @inv_labor = @inv_labor * @cogs_qty  
  
            exec @retval=fs_cost_insert @i_part_no, @i_location, @cogs_qty, @c_tran_type,   
              @i_tran_no, @i_tran_ext, @i_tran_line, @cl_account, @tran_date,  
              @i_apply_date, @inv_unitcost , @inv_direct , @inv_overhead , @inv_labor , @inv_utility,   
              @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
              @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac  
      
            if @retval != 1   
            begin  
              rollback tran  
              raiserror 83225 'Costing Error... Try Re-Saving!'  
              return -1  
            end  
  
            select @inv_unitcost = (@unitcost * @l_in_stock) + (@inv_unitcost ),  
              @inv_direct = (@direct * @l_in_stock) + (@inv_direct ),  
              @inv_overhead = (@overhead * @l_in_stock) + (@inv_overhead ),  
              @inv_utility = (@utility * @l_in_stock) + (@inv_utility ),  
              @inv_labor = (@labor * @l_in_stock) + (@inv_labor)  
          end  
  
          select @process_typ = '(- +) ' + @process_typ  
        end -- cogs = 2 - to +  
      end -- in_stock < 0  
    end   
  END    
  if @i_update_ind >= 0 and @update_typ = 'C' and @d_qc_flag != 'Y'  
  begin  
    if @i_tran_type in ('N','C')  
    begin  
      select @trn_unitcost = @i_mtrl_cost * @i_quantity, @trn_direct = @i_dir_cost * @i_quantity,   
        @trn_overhead = @i_ovhd_cost * @i_quantity, @trn_utility = @i_util_cost * @i_quantity,  
        @trn_labor = @i_labor_cost * @i_quantity  
      select @trn_unitcost = @trn_unitcost - @o_unitcost, @trn_direct = @trn_direct - @o_direct,   
        @trn_overhead = @trn_overhead - @o_overhead, @trn_utility = @trn_utility - @o_utility,  
        @trn_labor = @trn_labor - @o_labor  
  
      if @i_tran_type = 'C'  
      begin  
        if substring(@i_tran_data,2,1) = '0' select @trn_unitcost = 0  
        if substring(@i_tran_data,3,1) = '0' select @trn_direct = 0  
        if substring(@i_tran_data,4,1) = '0' select @trn_overhead = 0  
        if substring(@i_tran_data,5,1) = '0' select @trn_utility = 0  
      end  
  
      select @inv_unitcost = @trn_unitcost, @inv_direct = @trn_direct, @inv_overhead = @trn_overhead, @inv_utility = @trn_utility,  
        @inv_labor = @trn_labor  
    end  
    else  
    begin  
      select @trn_unitcost = @i_mtrl_cost, @trn_direct = @i_dir_cost, @trn_overhead = @i_ovhd_cost, @trn_utility = @i_util_cost,  
        @trn_labor = @i_labor_cost  
      select @inv_unitcost = @o_unitcost, @inv_direct = @o_direct, @inv_overhead = @o_overhead, @inv_utility = @o_utility,  
        @inv_labor = @o_labor  
    end  
  
    IF @i_tran_type = 'R'  
    BEGIN  
      select @inv_unitcost= 0, @inv_direct= 0 , @inv_overhead= 0, @inv_utility= 0, @inv_labor = 0,  
        @unitcost= 0, @direct= 0 , @overhead= 0, @utility= 0, @labor = 0  
  
      if @l_typ != 'S'  
      begin  
        SELECT @COGS = 0, @inv_qty = 0  
        if @l_typ = 'W'  
        begin  
          select @inv_val = (@o_in_stock * @avg_unitcost)  
          select @inv_qty = case when @layer_qty >= @i_quantity then @i_quantity else @layer_qty end  
        end  
        else  
          select @inv_qty = @i_quantity  
  
        if @inv_qty != 0   
        begin  
          select @trn_unitcost= @i_mtrl_cost, @trn_direct= @i_dir_cost, @trn_overhead= @i_ovhd_cost, @trn_utility= @i_util_cost ,  
            @trn_labor = @i_labor_cost  
          select @unitcost= @i_mtrl_cost, @direct= @i_dir_cost, @overhead= @i_ovhd_cost, @labor= @i_labor_cost, @utility= @i_util_cost  
          if @COGS = 1  
            select @unitcost = @avg_unitcost  
          
          if @l_typ = 'W'  
          BEGIN  
            if @skip_costing != 0        -- mls 8/8/00 SCR 23859  
            BEGIN  
              --Delta costing Layer for the QTY that we found!  
              exec @retval=fs_cost_delete @i_part_no, @i_location, @inv_qty, @i_tran_type, @i_tran_no, @i_tran_ext, @i_tran_line,  
                @cl_account, @tran_date, @i_apply_date, @unitcost , @direct , @overhead , @labor, @utility ,  
                @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
                @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac  
              IF @retval != 1   
              BEGIN  
                rollback tran  
                raiserror 91353 'Costing Error... Try Re-Saving!'  
                return  
              END  
            END  
  
            select @inv_unitcost= @unitcost, @inv_direct= @direct , @inv_overhead= @overhead,   
              @inv_utility= @utility, @inv_labor = @labor  
  
            select @unitcost = @i_cost --* @inv_qty     -- mls 2/24/05 SCR 34297  
            --Case there are positive balance in stock  
            --Insert into inv_costing  
            exec @retval=fs_cost_insert @i_part_no, @i_location, @inv_qty, @i_tran_type, @i_tran_no, @i_tran_ext, @i_tran_line,  
              @cl_account, @tran_date, @i_apply_date, @unitcost, 0, 0, 0, 0,   
              @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
              @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @m_status, @typ, @use_ac  
   
            if @retval != 1   
            begin  
              rollback tran  
              raiserror 81321 'Costing Error... Try Re-Saving!'  
              return  
            end  
          END  
          else -- typ != W  
          begin  
            --Delta costing Layer for the QTY that we found!  
            exec @retval= fs_cost_update @i_part_no, @i_location, @i_quantity, @i_tran_type, @i_tran_no, @i_tran_ext,   
              @i_tran_line, @cl_account, @tran_date, @i_apply_date, 0, @i_cost,  
              @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
              @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor,  
              @m_status, @use_ac, @typ,  
              @neg_unitcost, @neg_direct, @neg_overhead, @neg_labor, @neg_utility,   
              @cogs_qty OUT,  
              @unitcost OUT, @direct OUT, @overhead OUT, @labor OUT, @utility OUT, @l_typ  
  
            IF @retval != 1   
            BEGIN  
              rollback tran  
              raiserror 913534 'Costing Error... Try Re-Saving!'  
              return  
            END  
  
            select @inv_qty = @i_quantity - @cogs_qty  
  
            -- the update of inv_costing triggers an update of the inventory view, and   
            -- recalculates the average cost  
            -- this average cost needs to be updated in the inv_costing rows  
            if @l_typ = 'A'   
            begin  
              select @avg_cost = 0, @avg_dir = 0, @avg_oh = 0, @avg_utl = 0, @avg_labor = 0   -- mls 9/18/00 23804  
              select @avg_cost = avg_cost,  
                @avg_dir = avg_direct_dolrs,         -- mls 9/18/00 23804  
                @avg_oh = avg_ovhd_dolrs,         -- mls 9/18/00 23804  
                @avg_utl = avg_util_dolrs         -- mls 9/18/00 23804  
              from cvo_inventory2 inventory (NOLOCK) -- v1.0   
              where inventory.part_no = @i_part_no and inventory.location = @i_location  
  
              select @qty= sum( balance ),  
                @tot_mtrl_cost = sum(isnull(tot_mtrl_cost,unit_cost * balance)),  
                @tot_dir_cost = sum(isnull(tot_dir_cost,direct_dolrs * balance)),  
                @tot_ovhd_cost = sum(isnull(tot_ovhd_cost,ovhd_dolrs * balance)),  
                @tot_util_cost = sum(isnull(tot_util_cost,util_dolrs * balance)),  
                @tot_labor_cost = sum(isnull(tot_labor_cost,labor * balance)),  
                @max_seq = max(sequence)  
              from inv_costing   
              where part_no = @i_part_no and location = @i_location and account = @cl_account  
  
              select @r_cost = @tot_mtrl_cost - (@avg_cost * @qty),  
                @r_direct = @tot_dir_cost - (@avg_dir * @qty),  
                @r_overhead = @tot_ovhd_cost - (@avg_oh * @qty),  
                @r_utility = @tot_util_cost - (@avg_utl * @qty),  
                @r_labor = @tot_labor_cost - (@avg_labor * @qty)  
  
              update inv_costing   
              set unit_cost = @avg_cost,   
                direct_dolrs = @avg_dir,   
                ovhd_dolrs = @avg_oh,  
                util_dolrs = @avg_utl,  
                labor = @avg_labor,  
                tot_mtrl_cost = (@avg_cost * balance) + case when sequence = @max_seq then @r_cost else 0 end,  
                tot_dir_cost = (@avg_dir * balance) + case when sequence = @max_seq then @r_direct else 0 end,  
                tot_ovhd_cost = (@avg_oh * balance) + case when sequence = @max_seq then @r_overhead else 0 end,  
                tot_util_cost = (@avg_utl * balance) + case when sequence = @max_seq then @r_utility else 0 end,  
                tot_labor_cost = (@avg_labor * balance) + case when sequence = @max_seq then @r_labor else 0 end  
              where part_no = @i_part_no and location = @i_location and account  = @cl_account  
            end  
  
            select @inv_unitcost= @unitcost , @inv_direct= @direct ,   
              @inv_overhead= @overhead , @inv_utility= @utility ,  
              @inv_labor = @labor   
          end -- type != W  
        END -- inv_qty != 0  
      end -- l_typ != 'S'  
      else  
      begin  
        select @cogs_qty = @inv_qty  
      end  
  
      select @o_unitcost = @inv_unitcost, @o_direct = @inv_direct, @o_overhead = @inv_overhead, @o_utility = @inv_utility,  
        @o_labor = @inv_labor  
    end -- tran_type = 'R'  
  end  
  
  if @i_update_ind >= 0   
  begin  
    select @rc = 1  
    if @i_tran_type = 'L' -- Landed cost allocation (adm_cost_adjust) - update overhead dollars  
      exec @rc = adm_inv_tran_landed_cost 'after costing', @i_tran_no , @i_tran_line, @i_part_no ,  
        @i_location , @l_typ, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
        0, @o_in_stock, @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
        @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @update_typ OUT  
    if @i_tran_type = 'N' -- New Std Cost (new_cost table)   
      exec @rc = adm_inv_tran_new_cost 'after costing', @i_tran_no , @i_tran_line, @i_part_no ,  
        @i_location , @l_typ, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
        0, @o_in_stock, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
        @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @update_typ OUT  
    if @i_tran_type = 'P' -- Production (finished good)  
      exec @rc = adm_inv_tran_produce 'after costing', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
        @i_location , @l_typ, @m_status, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data ,   
        @i_update_ind OUT,   
        0, @o_in_stock OUT, @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
        @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT  
    if @i_tran_type = 'U' -- Production (subcomponent usage)  
    exec @rc = adm_inv_tran_usage 'after costing', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
        @i_location , @l_typ OUT, @m_status, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data ,   
        @i_update_ind OUT,   
        0, @o_in_stock OUT, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
        @std_unitcost OUT, @std_direct OUT, @std_overhead OUT, @std_utility OUT,   
        @cl_account OUT  
    if @i_tran_type = 'C' -- Cost Layer Adjustment (inv_costing_audit table)   
      exec @rc = adm_inv_tran_cost_adj 'after costing', @i_tran_no , @i_tran_line, @i_part_no ,  
        @i_location , @l_typ, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
        0, @o_in_stock, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
        @o_unitcost OUT, @o_direct OUT, @o_overhead OUT, @o_utility OUT, @update_typ OUT  
    if @i_tran_type = 'R' -- Receipts  
      exec @rc = adm_inv_tran_receipt 'after costing', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
        @i_location , @l_typ, @m_status, @i_quantity OUT, @i_conv_factor, @i_apply_date , @i_status,   
        @i_tran_data , @i_update_ind OUT,   
        0, @o_in_stock OUT, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
        @std_unitcost OUT, @std_direct OUT, @std_overhead OUT, @std_utility OUT,  
        @cl_account OUT, @update_typ OUT, @layer_qty OUT, @skip_costing OUT, @d_qc_flag OUT, @i_qc_flag OUT,  
        @i_qty OUT, @i_trigger OUT, @i_cost OUT  
  
    if @rc <> 1  
    begin  
      select @msg = 'adm_inv_tran_issue'  
      goto adm_inv_tran_error  
    end  
  end  
  
  if @i_update_ind > -2 and @i_update_ind < 2  
  begin  
  
    if NOT ((@i_tran_type = 'U' and (left(@i_tran_data,2) = 'XJ')) -- do not do for misc part on job production  
      or (@i_tran_type = 'R' and substring(@i_tran_data,3,1) = 'M') -- do not do for misc parts on receipts  
      or (@i_tran_type = 'S' and left(@i_tran_data,1) = 'J') -- do not do for jobs on sales orders  
      or (@i_tran_type = 'C' and @l_typ = 'A'))   
    begin  
      execute @rc = adm_get_inv_cost @i_part_no OUT, @i_location OUT,  
        @use_ac OUT, @in_stock OUT, @inv_holds OUT, @non_holds OUT, @typ OUT, @m_status OUT, @acct_code OUT,  
        @std_uom OUT,  
        @avg_unitcost OUT, @avg_direct OUT, @avg_overhead OUT, @avg_utility OUT, @avg_labor OUT,  
        @std_unitcost OUT, @std_direct OUT, @std_overhead OUT, @std_utility OUT, @std_labor OUT,  
        @cl_qty OUT  
  
      if @rc != 1    
        goto adm_get_inv_cost_error  
    end  
    if (@i_tran_type = 'C' and @l_typ = 'A')  
      select @avg_unitcost = @i_mtrl_cost, @avg_direct = @i_dir_cost, @avg_overhead = @i_ovhd_cost, @avg_utility = @i_util_cost,  
        @avg_labor = @i_labor_cost  
  
    if @l_typ = 'W' and @i_update_ind = 0   
      and ((@i_tran_type in ('I','S','K','U','R','X') and @i_quantity > 0) or (@i_tran_type in ('P')))  
    begin  
      select @n_in_stock = @o_in_stock + case when (@update_typ = 'I') or @update_typ = 'H'   
        then @i_quantity else 0 end + case when (@update_typ = 'I') then @hold_qty else 0 end  
  
      select @inv_unitcost = (@avg_unitcost * @n_in_stock) - (@wavg_unitcost * @o_in_stock)  
      select @inv_direct = (@avg_direct * @n_in_stock) - (@wavg_direct * @o_in_stock)  
      select @inv_overhead = (@avg_overhead * @n_in_stock) - (@wavg_overhead * @o_in_stock)  
      select @inv_utility = (@avg_utility * @n_in_stock) - (@wavg_utility * @o_in_stock)  
  
      select @o_unitcost = @inv_unitcost, @o_direct = @inv_direct, @o_overhead = @inv_overhead, @o_utility = @inv_utility,  
        @o_labor = @inv_labor  
    end  
  
    INSERT INTO inv_tran (part_no, location, update_ind, apply_date,  
      tran_type, tran_no, tran_ext, tran_line, tran_status, tran_inv_qty, tran_uom_qty, tran_uom,   
      tran_mtrl_cost, tran_dir_cost, tran_ovhd_cost, tran_util_cost, inv_qty,  
      inv_mtrl_cost, inv_dir_cost, inv_ovhd_cost, inv_util_cost, update_typ, process_typ,  
      inv_cost_method, inv_status, in_stock, hold_qty, cost_layer_qty, acct_code,   
      avg_mtrl_cost, avg_dir_cost, avg_ovhd_cost, avg_util_cost,   
      std_mtrl_cost, std_dir_cost, std_ovhd_cost, std_util_cost)  
    select @i_part_no, @i_location, @i_update_ind, @i_apply_date,   
      case when @i_tran_type = 'R' and @i_trigger = 'U'  then 'A'   
       when @i_tran_type = 'I' and substring(@i_tran_data,9,1) = 'Q' then 'J'   
       when @i_tran_type = 'I' and substring(@i_tran_data,10,1) = 'Q' then 'H'  
       else @i_tran_type end,  
      @i_tran_no, @i_tran_ext, @i_tran_line, @i_status, @i_quantity, @i_uom_quantity,   
      case when isnull(@i_uom,'') = '' then @std_uom else @i_uom end,  
      @trn_unitcost, @trn_direct, @trn_overhead, @trn_utility, @inv_qty,  
      @inv_unitcost, @inv_direct, @inv_overhead, @inv_utility,   
        case when @i_update_ind >= 0 then @update_typ else   
          case when @update_typ = 'H' then 'H' else '' end end, @process_typ,  
      @typ, @m_status, @in_stock + case when (@update_typ = 'I' and @i_update_ind >= 0) or @update_typ = 'H' or (@i_tran_type = 'I' and left(@i_tran_data,4) = 'XFR ')  
        then @i_quantity else 0 end + case when (@update_typ = 'I' and @i_update_ind >= 0) then @hold_qty else 0 end,  
      @inv_holds - @hold_qty,   
      @cl_qty , @acct_code,  
      @avg_unitcost , @avg_direct , @avg_overhead , @avg_utility ,  
      @std_unitcost , @std_direct , @std_overhead , @std_utility   
  
    select @i_tran_id = @@identity  
  end  
   
  select @rc = 1  
  if @i_tran_type = 'X'  
      exec @rc = adm_inv_tran_xfer 'end of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line,   
        @i_part_no , @i_location , @cogs_qty , @i_conv_factor, @i_apply_date , @i_status,   
        @i_tran_data OUT, @i_update_ind OUT, @COGS, @o_in_stock, @l_typ,  
        @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
        @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
        @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT,  
        @update_typ OUT, @hold_qty OUT  
  if @i_tran_type = 'I'  
    exec @rc = adm_inv_tran_issue 'end of adm_inv_tran', @i_tran_no , @i_part_no , @i_location ,  
      @i_quantity , @i_apply_date , @i_tran_data , @i_update_ind OUT, @COGS, @o_in_stock, @l_typ,  
      @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
      @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @update_typ OUT  
  if @i_tran_type = 'L' -- Landed cost allocation (adm_cost_adjust) - update overhead dollars  
    exec @rc = adm_inv_tran_landed_cost 'end of adm_inv_tran', @i_tran_no , @i_tran_line, @i_part_no ,  
      @i_location , @l_typ, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock, @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
      @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @update_typ OUT  
  if @i_tran_type = 'N' -- New Std Cost (new_cost table)   
    exec @rc = adm_inv_tran_new_cost 'end of adm_inv_tran', @i_tran_no , @i_tran_line, @i_part_no ,  
      @i_location , @l_typ, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock, @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
      @o_unitcost OUT, @o_direct OUT, @o_overhead OUT, @o_utility OUT, @update_typ OUT,   
      @acct_code, @i_tran_id  
  if @i_tran_type = 'P' -- Production (finished good)  
    exec @rc = adm_inv_tran_produce 'end of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @l_typ, @m_status, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data ,   
      @i_update_ind OUT,   
      0, @o_in_stock OUT, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
      @o_unitcost OUT, @o_direct OUT, @o_overhead OUT, @o_utility OUT  
  if @i_tran_type = 'U' -- Production (subcomponent usage)  
    exec @rc = adm_inv_tran_usage 'end of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @l_typ OUT, @m_status, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data ,   
      @i_update_ind OUT,   
      0, @o_in_stock OUT, @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
      @std_unitcost OUT, @std_direct OUT, @std_overhead OUT, @std_utility OUT,   
      @cl_account OUT  
  if @i_tran_type = 'R'  
    exec @rc = adm_inv_tran_receipt 'end of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @l_typ, @m_status, @cogs_qty , @i_conv_factor, @i_apply_date , @i_status,   
      @i_tran_data OUT, @i_update_ind ,   
      0, @o_in_stock OUT, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
      @neg_unitcost OUT, @neg_direct OUT, @neg_overhead OUT, @neg_utility OUT,  
      @cl_account OUT, @update_typ OUT, @layer_qty OUT, @skip_costing OUT, @d_qc_flag OUT, @i_qc_flag OUT,  
      @i_qty OUT, @i_trigger OUT, @i_cost OUT  
  if @i_tran_type = 'C' -- Cost Layer Adjustment (inv_costing_audit table)   
    exec @rc = adm_inv_tran_cost_adj 'end of adm_inv_tran', @i_tran_no , @i_tran_line, @i_part_no ,  
      @i_location , @l_typ, @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock, @i_mtrl_cost OUT, @i_dir_cost OUT, @i_ovhd_cost OUT, @i_util_cost OUT,   
      @inv_unitcost OUT, @inv_direct OUT, @inv_overhead OUT, @inv_utility OUT, @update_typ OUT, @acct_code, @i_tran_id  
  if @i_tran_type = 'S'  
    exec @rc = adm_inv_tran_sales 'end of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock, @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
      @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @update_typ OUT, @hold_qty OUT, @l_typ,  
      @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
      @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @process_typ  
  if @i_tran_type = 'K'  
    exec @rc = adm_inv_tran_sales_kit 'end of adm_inv_tran', @i_tran_no , @i_tran_ext, @i_tran_line, @i_part_no ,  
      @i_location , @i_quantity , @i_conv_factor, @i_apply_date , @i_status, @i_tran_data , @i_update_ind OUT,   
      0, @o_in_stock, @trn_unitcost OUT, @trn_direct OUT, @trn_overhead OUT, @trn_utility OUT,   
      @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @update_typ OUT, @hold_qty OUT, @l_typ,  
      @avg_unitcost, @avg_direct, @avg_overhead, @avg_utility, @avg_labor,  
      @std_unitcost, @std_direct, @std_overhead, @std_utility, @std_labor, @process_typ OUT  
  
  if @rc != 1  
    goto adm_inv_tran_error  
  
  if @update_typ = 'I'  
  begin  
    if @i_update_ind >= 0  
    begin  
      select @o_unitcost = @inv_unitcost, @o_direct = @inv_direct, @o_overhead = @inv_overhead, @o_utility = @inv_utility,  
        @o_labor = @inv_labor  
      select @i_mtrl_cost = @trn_unitcost, @i_dir_cost = @trn_direct, @i_ovhd_cost = @trn_overhead, @i_util_cost = @trn_utility,  
        @i_labor_cost = @trn_labor  
    end  
    else  
    begin  
      select @o_unitcost = 0, @o_direct = 0, @o_overhead = 0, @o_utility = 0,  
        @o_labor = 0  
      select @i_mtrl_cost = 0, @i_dir_cost = 0, @i_ovhd_cost = 0, @i_util_cost = 0,  
        @i_labor_cost = 0  
    end  
  end  
  
  RETURN 1  
  
adm_get_inv_cost_error:  
rollback tran  
select @msg = 'Error returned from adm_get_inv_cost.  No inventory record found for part (' + @i_part_no + ') and location ('  
  + @i_location + ').'  
RAISERROR 832011 @msg  
RETURN -1  
  
adm_inv_tran_error:  
rollback tran  
select @msg = 'Error (' + convert(varchar(10),@rc) + ') returned from ' + @sub_function   
  + ' for part (' + @i_part_no + ') and location (' + @i_location + ').'  
RAISERROR 832011 @msg  
RETURN -1  
  
END  
GO
GRANT EXECUTE ON  [dbo].[adm_inv_tran] TO [public]
GO
