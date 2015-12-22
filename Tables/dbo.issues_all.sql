CREATE TABLE [dbo].[issues_all]
(
[timestamp] [timestamp] NOT NULL,
[issue_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_from] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avg_cost] [decimal] (20, 8) NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[issue_date] [datetime] NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL,
[inventory] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direction] [int] NOT NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[labor] [decimal] (20, 8) NOT NULL,
[reason_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_no] [int] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__issues_al__statu__568ABD70] DEFAULT ('S'),
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[project1] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__issues_al__proje__577EE1A9] DEFAULT (' '),
[project2] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__issues_al__proje__587305E2] DEFAULT (' '),
[project3] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__issues_al__proje__59672A1B] DEFAULT (' '),
[serial_flag] [int] NULL CONSTRAINT [DF__issues_al__seria__5A5B4E54] DEFAULT ((0)),
[oper_avg_cost] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__issues_al__oper___5B4F728D] DEFAULT ((0.0)),
[oper_direct_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__issues_al__oper___5C4396C6] DEFAULT ((0.0)),
[oper_ovhd_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__issues_al__oper___5D37BAFF] DEFAULT ((0.0)),
[oper_util_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__issues_al__oper___5E2BDF38] DEFAULT ((0.0)),
[mtrl_reference_cd_expense] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direct_reference_cd_expense] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ovhd_reference_cd_expense] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[util_reference_cd_expense] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mtrl_account_expense] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direct_account_expense] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ovhd_account_expense] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[util_account_expense] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_def_fld1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__issues_al__user___5F200371] DEFAULT (''),
[user_def_fld2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__issues_al__user___601427AA] DEFAULT (''),
[user_def_fld3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__issues_al__user___61084BE3] DEFAULT (''),
[user_def_fld4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__issues_al__user___61FC701C] DEFAULT (''),
[user_def_fld5] [float] NULL CONSTRAINT [DF__issues_al__user___62F09455] DEFAULT ((0.0)),
[user_def_fld6] [float] NULL CONSTRAINT [DF__issues_al__user___63E4B88E] DEFAULT ((0.0)),
[user_def_fld7] [float] NULL CONSTRAINT [DF__issues_al__user___64D8DCC7] DEFAULT ((0.0)),
[user_def_fld8] [float] NULL CONSTRAINT [DF__issues_al__user___65CD0100] DEFAULT ((0.0)),
[user_def_fld9] [int] NULL CONSTRAINT [DF__issues_al__user___66C12539] DEFAULT ((0)),
[user_def_fld10] [int] NULL CONSTRAINT [DF__issues_al__user___67B54972] DEFAULT ((0)),
[user_def_fld11] [int] NULL CONSTRAINT [DF__issues_al__user___68A96DAB] DEFAULT ((0)),
[user_def_fld12] [int] NULL CONSTRAINT [DF__issues_al__user___699D91E4] DEFAULT ((0)),
[ref_issue_no] [int] NULL CONSTRAINT [DF__issues_al__ref_i__6A91B61D] DEFAULT ((0)),
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t500deliss] ON [dbo].[issues_all]   FOR DELETE AS 
begin
if exists (select * from config where flag='TRIG_DEL_ISS' and value_str='DISABLE')
	return
else
   begin
     rollback tran
     exec adm_raiserror 73299, 'You Can Not Delete An ISSUE!' 
     return
   end
end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insiss] ON [dbo].[issues_all]   FOR INSERT  AS 
BEGIN
DECLARE @i_part_no varchar(30),  @i_location_from varchar(10), @i_direction int, 
  @i_qty decimal(20,8),@i_issue_no int, @i_issue_date datetime, 
  @i_mtrl_account_expense  	varchar(32) ,
  @i_direct_account_expense  	varchar(32) ,		-- this is labor
  @i_ovhd_account_expense  	varchar(32) ,
  @i_util_account_expense	varchar(32) ,
  @i_mtrl_reference_cd varchar(32), @i_direct_reference_cd varchar(32), 
  @i_ovhd_reference_cd varchar(32), @i_util_reference_cd varchar(32),
  @i_avg_cost decimal(20,8), @i_direct_dolrs decimal(20,8),
  @i_ovhd_dolrs decimal(20,8), @i_labor decimal(20,8), @i_util_dolrs decimal(20,8),
  @c_code varchar(10),  @c_account varchar(32),
  @issue_ref_code varchar(32),								-- mls 11/05/03 SCR 32031
  @i_status char(1), @i_who_entered varchar(20), @i_lb_tracking char(1),
  @i_inventory char(1), @i_ref_issue_no int,
  @i_reason_code varchar(10),
  @i_org_id varchar(30)


DECLARE @retval int,
  
  @unitcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8),
  @labor decimal(20,8), @utility decimal(20,8) ,
  @operunitcost decimal(20,8), @operdirect decimal(20,8), @operoverhead decimal(20,8),
  @operutility decimal(20,8), @oper_total_cost decimal(20,8) ,
  @expense_unit_cost 	decimal(20,8) ,
  @expense_direct_cost 	decimal(20,8) ,
  @expense_overhead_cost 	decimal(20,8) ,
  @expense_utility_cost 	decimal(20,8),
  @posting_code varchar(10), @natcode varchar(8),
  @inv_acct varchar(32), @direct_acct varchar(32), @ovhd_acct varchar(32),@util_acct varchar(32),
  @i_ref_cd varchar(32), @msg varchar(80),
  @company_id int,
  @c_unitcost decimal(20,8), @c_direct decimal(20,8), @c_overhead decimal(20,8), @c_labor decimal(20,8), @c_utility decimal(20,8),
  @c_qty decimal(20,8),
  @d_unitcost decimal(20,8), @d_direct decimal(20,8), @d_overhead decimal(20,8), @d_labor decimal(20,8),
  @d_utility decimal(20,8), @d_operunitcost decimal(20,8), @d_operdirect decimal(20,8), 
  @d_operoverhead decimal(20,8), @d_operutility decimal(20,8), 
  @cost decimal(20,8), @opercost decimal(20,8), @in_stock decimal(20,8), 
  @temp_qty decimal(20,8), @dummycost decimal(20,8), @temp_cost decimal(20,8),
  @ar_cgs_code varchar(32), @ar_cgs_direct_code varchar(32), @ar_cgs_ovhd_code varchar(32), 
  @ar_cgs_util_code varchar(32)	,
  @COGS int,
  @iloop int,@d_cost decimal(20,8),@d_opercost decimal(20,8),		-- mls 10/4/99
  @i_acct varchar(32), @icost decimal(20,8), @iopercost decimal(20,8),			-- mls 10/4/99
  @ovhd_reference_code varchar(32), @util_reference_code varchar(32),
  @direct_reference_code varchar(32), @labor_reference_code varchar(32),
  @ovhd_account 	 varchar(32), @util_account  varchar(32),
  @direct_account  varchar(32), @labor_account 	 varchar(32),
  @var_acct varchar(32), @dir_var_acct varchar(32), @ovhd_var_acct varchar(32), @util_var_acct varchar(32),
  @typ char(1), @o_avg_cost decimal(20,8), 						-- mls 5/23/00 SCR 22565
  @o_direct_dolrs decimal(20,8), @o_ovhd_dolrs decimal(20,8),@o_util_dolrs decimal(20,8),	-- mls 5/23/00 SCR 22565
  @s_std_cost decimal(20,8), 
  @s_direct_dolrs decimal(20,8), @s_ovhd_dolrs decimal(20,8),@s_util_dolrs decimal(20,8),
  @r_avg_cost decimal(20,8), 					-- mls 5/23/00 SCR 22565
  @r_direct_dolrs decimal(20,8), @r_ovhd_dolrs decimal(20,8),@r_util_dolrs decimal(20,8),	-- mls 5/23/00 SCR 22565
  @m_status char(1),
  @tempqty decimal(20,8), @line_descr varchar(50),
  @lot varchar(25), @bin varchar(12),@dtexp datetime,
  @a_tran_data varchar(255)

declare @inv_lot_bin int, @m_lb_tracking char(1),
  @lb_sum decimal(20,8), @part_cnt int, @lb_part varchar(30), @lb_loc varchar(10)
DECLARE @a_tran_id int

DECLARE c_issues CURSOR LOCAL FOR
SELECT i.part_no, i.location_from, (i.qty * i.direction), i.issue_no, i.direction,
  i.issue_date, c.code, c.account,
  case when rtrim(isnull(i.mtrl_account_expense,'')) = '' then c.account else i.mtrl_account_expense end,
  case when rtrim(isnull(i.direct_account_expense,'')) = '' then c.account else i.direct_account_expense end, 
  case when rtrim(isnull(i.ovhd_account_expense,'')) = '' then c.account else i.ovhd_account_expense end,
  case when rtrim(isnull(i.util_account_expense,'')) = '' then c.account else i.util_account_expense end,
  i.mtrl_reference_cd_expense, i.direct_reference_cd_expense, i.ovhd_reference_cd_expense,
  i.util_reference_cd_expense,
  isnull(i.avg_cost,0), isnull(i.direct_dolrs,0), isnull(i.ovhd_dolrs,0), 
  isnull(i.labor,0), isnull(i.util_dolrs,0),
  i.status, i.who_entered, i.lb_tracking, i.inventory, i.ref_issue_no,
  i.reason_code, m.lb_tracking,
  isnull(i.organization_id,'')
from inserted i
left outer join inv_master m (nolock) on m.part_no = i.part_no
left outer join issue_code c on c.code = i.code
where i.status > 'H'

OPEN c_issues

if @@cursor_rows > 0
begin
  SELECT @company_id = company_id, @natcode = home_currency
  FROM glco (nolock)

  if @natcode = NULL
  BEGIN
    rollback tran
    exec adm_raiserror 83221, 'Could Not Find Currency Code.'
    return
  END

  select @inv_lot_bin = isnull((select 1 from config (nolock) where flag='INV_LOT_BIN' and upper(value_str) = 'YES' ),0)
    

FETCH NEXT FROM c_issues INTO
  @i_part_no, @i_location_from, @i_qty, @i_issue_no, @i_direction,
  @i_issue_date, @c_code, @c_account,
  @i_mtrl_account_expense, @i_direct_account_expense, 		
  @i_ovhd_account_expense, @i_util_account_expense,
  @i_mtrl_reference_cd, @i_direct_reference_cd,
  @i_ovhd_reference_cd, @i_util_reference_cd,
  @i_avg_cost, @i_direct_dolrs, @i_ovhd_dolrs, @i_labor, @i_util_dolrs, @i_status,
  @i_who_entered, @i_lb_tracking, @i_inventory, @i_ref_issue_no,
  @i_reason_code , @m_lb_tracking,
  @i_org_id


WHILE @@FETCH_STATUS = 0
begin
  if isnull(@c_code,'') = '' and isnull(@i_inventory,'N') != 'Q' 
  begin
    rollback tran
    exec adm_raiserror 83211 ,'Issue code does not exists on Issue_code table.  The transaction is being rolled back.'
    RETURN
  end

  if @m_lb_tracking is null
  begin
    rollback tran
    exec adm_raiserror 832111, 'Part does not exists in inventory.'
    RETURN
  end

  if @m_lb_tracking != @i_lb_tracking
  begin
    rollback tran
    exec adm_raiserror 832112, 'Lot bin tracking flag mismatch with inventory.'
    RETURN
  end

  select @lb_sum = sum(qty * direction),
    @part_cnt = count(distinct (part_no + '!@#' + location)) ,
    @lb_part = min(part_no),
    @lb_loc = min(location)
  from lot_serial_bin_issue (nolock)
  where tran_no = @i_issue_no

  if @m_lb_tracking = 'Y' 
  begin
    if @i_direction < 0 or (@i_direction > 0 and @inv_lot_bin = 1)
    begin 
      if @part_cnt = 0
      begin
        rollback tran
        exec adm_raiserror 832113, 'No lot bin records found on lot_serial_bin_issue for this issue.'
        RETURN
      end
      if @part_cnt > 1
      begin
        rollback tran
        exec adm_raiserror 832113 ,'More than one parts lot bin records found on lot_serial_bin_issue for this issue.'
        RETURN
      end
      if @lb_sum != @i_qty
      begin
        select @msg = 'Adjustment qty of [' + convert(varchar,@i_qty) + '] does not equal the lot and bin qty of [' + convert(varchar,@lb_sum) + '].'
        rollback tran
        exec adm_raiserror 832113, @msg
        RETURN
      end
      if @lb_part != @i_part_no or @lb_loc != @i_location_from
      begin
        select @msg = 'Part/Location on lot_serial_bin_issue is not the same as on issues table.'
        rollback tran
        exec adm_raiserror 832115 ,@msg
        RETURN
      end
    end 
    else
    begin
      if @inv_lot_bin = 0 and @part_cnt > 0
      begin
        select @msg = 'You cannot have lot bin records on an inbound transaction when you are not lb tracking.'
        rollback tran
        exec adm_raiserror 832114 ,@msg
        RETURN
      end
    end
  end
  else
  begin
    if @part_cnt > 0
    begin
      rollback tran
      exec adm_raiserror 832114, 'Lot bin records found on lot_serial_bin_issue for this not lot/bin tracked part.'
      RETURN
    end
  end


  if @i_org_id = ''												-- I/O start
  begin
    select @i_org_id = dbo.adm_get_locations_org_fn(@i_location_from)
    update issues_all
    set organization_id = @i_org_id 
    where issue_no = @i_issue_no
  end

  else
  begin
    if @i_org_id != dbo.adm_get_locations_org_fn(@i_location_from)
    begin
      select @msg = 'Organization ([' + @i_org_id + ']) is not the current organization for Location ([' + @i_location_from + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
  end														-- I/O end

  if isnull(@i_inventory,'N') = 'Q'
  begin
    select @c_code = isnull(@c_code,'')
    if isnull(@i_ref_issue_no,0) = 0
    begin
      select 
        @i_mtrl_account_expense = case when rtrim(isnull(@i_mtrl_account_expense,'')) = '' then c.qc_mtrl_acct else @i_mtrl_account_expense end,
        @i_direct_account_expense = case when rtrim(isnull(@i_direct_account_expense,'')) = '' then c.qc_dir_acct else @i_direct_account_expense end,
        @i_ovhd_account_expense = case when rtrim(isnull(@i_ovhd_account_expense,'')) = '' then c.qc_ovhd_acct else @i_ovhd_account_expense end,
        @i_util_account_expense = case when rtrim(isnull(@i_util_account_expense,'')) = '' then c.qc_util_acct else @i_util_account_expense end
      from in_account c
      join inv_list i on i.acct_code = c.acct_code
      where i.part_no = @i_part_no and i.location = @i_location_from

      select @i_mtrl_account_expense = dbo.adm_mask_acct_fn(@i_mtrl_account_expense, @i_org_id),
        @i_direct_account_expense = dbo.adm_mask_acct_fn(@i_direct_account_expense, @i_org_id),
        @i_ovhd_account_expense = dbo.adm_mask_acct_fn(@i_ovhd_account_expense, @i_org_id),
        @i_util_account_expense = dbo.adm_mask_acct_fn(@i_util_account_expense, @i_org_id)
    end
    else
    begin
      select 
        @i_mtrl_account_expense = mtrl_account_expense,
        @i_direct_account_expense = direct_account_expense,
        @i_ovhd_account_expense = ovhd_account_expense,
        @i_util_account_expense = util_account_expense,
        @i_avg_cost = avg_cost,
        @i_direct_dolrs = direct_dolrs, @i_ovhd_dolrs = ovhd_dolrs, @i_util_dolrs = util_dolrs,
	@i_mtrl_reference_cd = mtrl_reference_cd_expense, @i_direct_reference_cd = direct_reference_cd_expense,
  	@i_ovhd_reference_cd = ovhd_reference_cd_expense, @i_util_reference_cd = util_reference_cd_expense
      from issues_all where issue_no = @i_ref_issue_no
    end

    update issues_all
    set mtrl_account_expense = @i_mtrl_account_expense,
      direct_account_expense = @i_direct_account_expense,
      ovhd_account_expense = @i_ovhd_account_expense,
      util_account_expense = @i_util_account_expense,
      mtrl_reference_cd_expense = @i_mtrl_reference_cd, direct_reference_cd_expense = @i_direct_reference_cd,
      ovhd_reference_cd_expense = @i_ovhd_reference_cd, util_reference_cd_expense = @i_util_reference_cd,
      avg_cost = @i_avg_cost, direct_dolrs = @i_direct_dolrs, ovhd_dolrs = @i_ovhd_dolrs, util_dolrs = @i_util_dolrs
    where issue_no = @i_issue_no
  end

  if @i_status = 'Q' and (@i_qty * @i_direction) < 0 
  begin
    rollback tran
    exec adm_raiserror 83212 ,'You Cannot QC an outbound inventory adjustment.'
    RETURN
  end

  if @i_status > 'H'
  begin 
    SELECT 
      @unitcost = 0, @direct = 0, @overhead = 0, @labor = 0, @utility = 0,
      @operunitcost  = 0, @operdirect=0, @operoverhead=0, @operutility=0,
      @d_unitcost = @i_avg_cost * @i_qty, @d_direct = @i_direct_dolrs * @i_qty, @d_overhead = @i_ovhd_dolrs * @i_qty,
      @d_utility = @i_util_dolrs * @i_qty, @d_labor = @i_labor * @i_qty

    select @unitcost = @d_unitcost, @direct = @d_direct, @overhead = @d_overhead, @utility = @d_utility
    select @a_tran_data = convert(char(8),@c_code) + convert(char(1),@i_status) + ' '

    exec @retval = adm_inv_tran 
      'I', @i_issue_no, 0,0, @i_part_no, @i_location_from, @i_qty, @i_issue_date, '', 1,
      'S', @a_tran_data, DEFAULT, 
      @a_tran_id OUT, @d_unitcost OUT, @d_direct OUT, @d_overhead OUT, @d_utility OUT, @d_labor OUT,
      @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT, @typ OUT
    if @retval <> 1
    begin
      rollback tran
      select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran_issue.'
      exec adm_raiserror 83202, @msg
      RETURN
    end

    if @i_status > 'Q'
    begin
    select @c_unitcost = @d_unitcost - @unitcost, --(@cogs_qty * @n_unitcost),
      @c_direct = @d_direct - @direct, --(@cogs_qty * @n_direct),
      @c_overhead = @d_overhead - @overhead, --(@cogs_qty * @n_overhead),
      @c_utility = @d_utility - @utility, --(@cogs_qty * @n_utility), 
      @c_qty = @i_qty

    if ( @COGS = 2 ) 	--Case the quantity balance start with negative value, but the in coming
    begin			-- Qty will make it becomes positive.
      select @c_qty = - @in_stock  
    end

    

    -- Get Accounts
    SELECT @direct_acct   = inv_direct_acct_code,
      @ovhd_acct     = inv_ovhd_acct_code,
      @util_acct     = inv_util_acct_code,
      @inv_acct      = inv_acct_code,
      @ar_cgs_code = ar_cgs_code,
      @ar_cgs_direct_code  = ar_cgs_direct_code ,
      @ar_cgs_ovhd_code = ar_cgs_ovhd_code,
      @ar_cgs_util_code = ar_cgs_util_code,
      @var_acct      = cost_var_code,
      @dir_var_acct  = cost_var_direct_code,
      @ovhd_var_acct = cost_var_ovhd_code,
      @util_var_acct = cost_var_util_code
    FROM in_account a (nolock)
    join inv_list l on l.acct_code = a.acct_code and l.part_no = @i_part_no and l.location = @i_location_from

    select
      @expense_unit_cost = @d_unitcost , 
      @expense_direct_cost =  @d_direct ,
      @expense_overhead_cost =  @d_overhead ,
      @expense_utility_cost =  @d_utility     

    select @tempqty = @i_qty * -1							-- mls 4/12/02 SCR 28686

    SELECT @iloop = 1									
    WHILE @iloop <= 4  
    BEGIN 
      SELECT @icost =
        CASE @iloop
          WHEN 1 THEN -@expense_unit_cost WHEN 2 THEN -@expense_direct_cost 
          WHEN 3 THEN -@expense_overhead_cost WHEN 4 THEN -@expense_utility_cost END,
        @i_acct =
        CASE @iloop
          WHEN 1 THEN @i_mtrl_account_expense WHEN 2 THEN @i_direct_account_expense
          WHEN 3 THEN @i_ovhd_account_expense WHEN 4 THEN @i_util_account_expense END,
        @i_ref_cd =
        CASE @iloop
          WHEN 1 THEN @i_mtrl_reference_cd WHEN 2 THEN @i_direct_reference_cd
          WHEN 3 THEN @i_ovhd_reference_cd WHEN 4 THEN @i_util_reference_cd END,
        @line_descr =
        CASE @iloop
          WHEN 1 THEN 'exp_acct' WHEN 2 THEN 'exp_direct_acct'
          WHEN 3 THEN 'exp_ovhd_acct' WHEN 4 THEN 'exp_util_acct' END

      if (@icost) != 0
      begin
        select @temp_cost = case when @tempqty != 0 then @icost / @tempqty else @icost end	-- mls 3/23/05 SCR 34443
        exec @retval = adm_gl_insert  @i_part_no,@i_location_from,'I',@i_issue_no,0,0,
          @i_issue_date, @tempqty, @temp_cost , @i_acct , @natcode ,
          DEFAULT , DEFAULT , @company_id, DEFAULT, @i_ref_cd,  @a_tran_id, @line_descr, @icost

        IF @retval <= 0 
        BEGIN
          rollback tran
	  select @msg = 'Error Inserting GL Costing Record! -   material [' + convert(varchar(10),@iloop) + ']'
          exec adm_raiserror 83230, @msg
          return
        END
      end

      SELECT @iloop = @iloop + 1
    end

    -- process the accounts in a while loop since the calculations are the same, the only thing different
    -- is the cost.     
  
    SELECT @iloop = 1										-- mls 10/4/99 start
    WHILE @iloop <= 4  
    BEGIN 
      SELECT @icost =
        CASE @iloop
          WHEN 1 THEN @unitcost WHEN 2 THEN @direct 
          WHEN 3 THEN @overhead WHEN 4 THEN @utility END,
        @iopercost =
        CASE @iloop
          WHEN 1 THEN @operunitcost WHEN 2 THEN @operdirect
          WHEN 3 THEN @operoverhead WHEN 4 THEN @operutility END,
        @d_cost =
        CASE @iloop
          WHEN 1 THEN @d_unitcost WHEN 2 THEN @d_direct
          WHEN 3 THEN @d_overhead WHEN 4 THEN @d_utility END,
        @d_opercost =
        CASE @iloop
          WHEN 1 THEN @d_operunitcost WHEN 2 THEN @d_operdirect
          WHEN 3 THEN @d_operoverhead WHEN 4 THEN @d_operutility END,
        @i_acct =
        CASE @iloop
          WHEN 1 THEN @inv_acct WHEN 2 THEN @direct_acct
          WHEN 3 THEN @ovhd_acct WHEN 4 THEN @util_acct END,
        @i_ref_cd =										-- mls 11/05/03 SCR 32031
        CASE @iloop	
          WHEN 1 THEN @i_mtrl_reference_cd WHEN 2 THEN @i_direct_reference_cd
          WHEN 3 THEN @i_ovhd_reference_cd WHEN 4 THEN @i_util_reference_cd END,
        @line_descr =
        CASE @iloop
          WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct'
          WHEN 3 THEN 'inv_ovhd_acct' WHEN 4 THEN 'inv_util_acct' END

      select @line_descr = @line_descr + case @COGS when 1 then ' (- -)' when 2 then ' (- +)' 
        when 3 then ' (+ -)' else '' end

      select @cost = 0      									-- mls 5/23/00 SCR 22565
      if (@icost != 0  or @d_cost != 0) or @iloop = 1 
      BEGIN 		--spham 10/5/99						-- mls  

        select @issue_ref_code = ''								-- mls 11/05/03 SCR 32031 start
        if exists (select 1 from glrefact (nolock) where @i_acct like account_mask and reference_flag > 1)
        begin
          if exists (select 1 from glratyp t (nolock), glref r (nolock)
            where t.reference_type = r.reference_type and @i_acct like t.account_mask and
            r.status_flag = 0 and r.reference_code  = @i_ref_cd)
          begin
            select @issue_ref_code = @i_ref_cd
          end
        end											-- mls 11/05/03 SCR 32031 end

        select @cost = @icost
        select @temp_cost = case when @i_qty != 0 then @icost / @i_qty else @icost end	-- mls 3/23/05 SCR 34443
        exec @retval = adm_gl_insert  @i_part_no,@i_location_from,'I',@i_issue_no,0,0,	
          @i_issue_date, @i_qty ,@temp_cost,@i_acct,@natcode,DEFAULT,DEFAULT,			
          @company_id, DEFAULT, @issue_ref_code, @a_tran_id, @line_descr, @icost, @iloop		-- mls 11/05/03 SCR 32031
  
        IF @retval <= 0 
        BEGIN
          rollback tran
          select @msg = 'Error Inserting GL Costing Record! [' + convert(varchar(10), @iloop)  + ']'
          exec adm_raiserror 83231, @msg
          return
        END
      END

      SELECT @iloop = @iloop + 1
    END --While										-- mls 10/4/99 end

    if ( @COGS != 0 ) 
    begin  --Case there is a Cost of Good Sold, that currently has negative balance
      SELECT @iloop = 1										-- mls 10/4/99 start
      WHILE @iloop <= 4  
      BEGIN 
        --Create a new gl account with the cost different	
        SELECT @icost =
          CASE @iloop
            WHEN 1 THEN @c_unitcost WHEN 2 THEN @c_direct
            WHEN 3 THEN @c_overhead WHEN 4 THEN @c_utility END,
          @i_acct =
          CASE @iloop
            WHEN 1 THEN @ar_cgs_code WHEN 2 THEN @ar_cgs_direct_code
            WHEN 3 THEN @ar_cgs_ovhd_code WHEN 4 THEN @ar_cgs_util_code END,
          @i_ref_cd =										-- mls 11/05/03 SCR 32031
          CASE @iloop
            WHEN 1 THEN @i_mtrl_reference_cd WHEN 2 THEN @i_direct_reference_cd
            WHEN 3 THEN @i_ovhd_reference_cd WHEN 4 THEN @i_util_reference_cd END,
          @line_descr =
          CASE @iloop
            WHEN 1 THEN 'ar_cgs_acct' WHEN 2 THEN 'ar_cgs_direct_acct'
            WHEN 3 THEN 'ar_cgs_ovhd_acct' WHEN 4 THEN 'ar_cgs_util_acct' END
        

        if (@icost) != 0 
        BEGIN      
          select @issue_ref_code = ''								-- mls 11/05/03 SCR 32031 start
          if exists (select 1 from glrefact (nolock) where @i_acct like account_mask and reference_flag > 1)
          begin
            if exists (select 1 from glratyp t (nolock), glref r (nolock)
              where t.reference_type = r.reference_type and @i_acct like t.account_mask and
              r.status_flag = 0 and r.reference_code  = @i_ref_cd)
            begin
              select @issue_ref_code = @i_ref_cd
            end
          end											-- mls 11/05/03 SCR 32031 end

          select @temp_cost = case when @c_qty != 0 then @icost / @c_qty else @icost end	-- mls 3/23/05 SCR 34443
          exec @retval = adm_gl_insert  @i_part_no,@i_location_from,'I',@i_issue_no,0,0,
            @i_issue_date, @c_qty, @temp_cost, @i_acct, @natcode, DEFAULT, DEFAULT,  	-- mls 6/2/00 SCR 22994
            @company_id, DEFAULT, @issue_ref_code, @a_tran_id, @line_descr, @icost	-- mls 11/05/03 SCR 32031

          IF @retval <= 0
          BEGIN
            rollback tran
            exec adm_raiserror 83231, 'Error Inserting GL Costing Record!'
            return
          END
        END

        SELECT @iloop = @iloop + 1
      END
    END  --COGS

    if ( @COGS = 0 ) and charindex(@typ,'123456789') > 0 and 
      (abs(@c_unitcost) + abs(@c_direct) + abs(@c_overhead) + abs(@c_utility)) != 0
    begin
      SELECT @iloop = 1	
      WHILE @iloop <= 4  
      BEGIN 
        --Create a new gl account with the cost different	
        SELECT @icost =
          CASE @iloop
            WHEN 1 THEN @c_unitcost WHEN 2 THEN @c_direct 
            WHEN 3 THEN @c_overhead WHEN 4 THEN @c_utility END,
          @i_acct =
          CASE @iloop
            WHEN 1 THEN @var_acct WHEN 2 THEN @dir_var_acct
            WHEN 3 THEN @ovhd_var_acct WHEN 4 THEN @util_var_acct END,
          @i_ref_cd =										-- mls 11/05/03 SCR 32031
          CASE @iloop
            WHEN 1 THEN @i_mtrl_reference_cd WHEN 2 THEN @i_direct_reference_cd
            WHEN 3 THEN @i_ovhd_reference_cd WHEN 4 THEN @i_util_reference_cd END,
          @line_descr =
          CASE @iloop
            WHEN 1 THEN 'cost_var_acct' WHEN 2 THEN 'direct_var_acct'
            WHEN 3 THEN 'ovhd_var_acct' WHEN 4 THEN 'util_var_acct' END
        
        if (@icost) != 0 
        BEGIN      
          select @issue_ref_code = ''								-- mls 11/05/03 SCR 32031 start
          if exists (select 1 from glrefact (nolock) where @i_acct like account_mask and reference_flag > 1)
          begin
            if exists (select 1 from glratyp t (nolock), glref r (nolock)
              where t.reference_type = r.reference_type and @i_acct like t.account_mask and
              r.status_flag = 0 and r.reference_code  = @i_ref_cd)
            begin
              select @issue_ref_code = @i_ref_cd
            end
          end											-- mls 11/05/03 SCR 32031 end

          select @temp_cost = case when @c_qty != 0 then @icost / @c_qty else @icost end	-- mls 3/23/05 SCR 34443
          exec @retval = adm_gl_insert  @i_part_no,@i_location_from,'I',@i_issue_no,0,0,
            @i_issue_date, @c_qty, @temp_cost, @i_acct, @natcode, DEFAULT, DEFAULT,  	-- mls 6/2/00 SCR 22994
            @company_id, DEFAULT, @issue_ref_code, @a_tran_id, @line_descr, @icost	-- mls 11/05/03 SCR 32031

          IF @retval <= 0
          BEGIN
            rollback tran
            exec adm_raiserror 83231, 'Error Inserting GL Costing Record!'
            return
          END
        END

        SELECT @iloop = @iloop + 1
      END
    END  --COGS
    end -- @i_status > 'Q'
  end -- @i_status > 'H'
 
  if @i_status = 'Q'
  begin
    --Need to QC the part before release it.
    --Note: the process use QC account
    select @lot=null, @bin=null, @dtexp=null
  
    if @i_lb_tracking = 'Y'
    begin
      select @lot = lot_ser, @bin = bin_no, @dtexp = date_expires
      from lot_serial_bin_issue b
      where b.location = @i_location_from and b.part_no = @i_part_no and b.tran_no = @i_issue_no 
    end
    exec fs_enter_qc 'I', @i_issue_no, 0, 1, @i_part_no, @i_location_from, 
      @lot, @bin, @i_qty, NULL, @i_who_entered, @i_reason_code, @dtexp	-- mls 7/15/04 SCR 33223
  end

  FETCH NEXT FROM c_issues INTO
    @i_part_no, @i_location_from, @i_qty, @i_issue_no, @i_direction,
    @i_issue_date, @c_code, @c_account,
    @i_mtrl_account_expense, @i_direct_account_expense,     
    @i_ovhd_account_expense, @i_util_account_expense,
    @i_mtrl_reference_cd, @i_direct_reference_cd,
    @i_ovhd_reference_cd, @i_util_reference_cd,
    @i_avg_cost, @i_direct_dolrs, @i_ovhd_dolrs, @i_labor, @i_util_dolrs, @i_status,
    @i_who_entered, @i_lb_tracking, @i_inventory, @i_ref_issue_no,
    @i_reason_code , @m_lb_tracking,
    @i_org_id
END

end -- @@cursor_rows > 0

CLOSE c_issues
DEALLOCATE c_issues
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updiss] ON [dbo].[issues_all]   FOR UPDATE  AS 
BEGIN

if (update(avg_cost) or update(organization_id)) and NOT ( UPDATE(qc_no) OR UPDATE(qty) OR UPDATE(part_no) or
UPDATE(location_from) or UPDATE(location_to) or update(status)) return
if (update(qc_no) or update(mtrl_account_expense)) and NOT ( UPDATE(avg_cost) OR UPDATE(qty) OR UPDATE(part_no) or
UPDATE(location_from) or UPDATE(location_to) or update(status)) return

if exists (select * from config where flag='TRIG_UPD_ISS' and value_str='DISABLE') 
begin
  return
end

DECLARE @i_part_no varchar(30),  @i_location_from varchar(10), 
  @i_direction int, @i_qty decimal(20,8), @i_issue_no int, @i_issue_date datetime, 
  @i_mtrl_account_expense    varchar(32) ,
  @i_direct_account_expense    varchar(32) ,    -- this is labor
  @i_ovhd_account_expense    varchar(32) ,
  @i_util_account_expense  varchar(32) ,
  @i_mtrl_reference_cd varchar(32), @i_direct_reference_cd varchar(32), 
  @i_ovhd_reference_cd varchar(32), @i_util_reference_cd varchar(32),
  @i_avg_cost decimal(20,8), @i_direct_dolrs decimal(20,8),
  @i_ovhd_dolrs decimal(20,8), @i_labor decimal(20,8), @i_util_dolrs decimal(20,8),
  @i_status char(1),
  @d_status char(1), @d_issue_no int,
  @c_account varchar(32), @c_code varchar(10),
  @issue_ref_code varchar(32),								-- mls 11/05/03 SCR 32031
  @i_org_id varchar(30)

DECLARE @retval int, @m_status char(1), @i_ref_cd varchar(32),
  @operunitcost decimal(20,8), @operdirect decimal(20,8), @operoverhead decimal(20,8),
  @operutility decimal(20,8), @oper_total_cost decimal(20,8) ,
  @stkacct varchar(10), @tran_date datetime, 
  @unitcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8),
  @labor decimal(20,8), @utility decimal(20,8) ,
  @expense_unit_cost   decimal(20,8) ,  @expense_direct_cost   decimal(20,8) ,
  @expense_overhead_cost   decimal(20,8) ,  @expense_utility_cost   decimal(20,8) ,
  @posting_code varchar(10), @natcode varchar(8),
  @var_acct varchar(32), @var_direct varchar(32), @var_ovhd varchar(32),@var_util varchar(32),
  @inv_acct varchar(32), @direct_acct varchar(32), @ovhd_acct varchar(32),@util_acct varchar(32),
  @reference_code varchar(32),
  @company_id int, @direction int, @return int,
  @c_unitcost decimal(20,8), @c_direct decimal(20,8), @c_overhead decimal(20,8), @c_utility decimal(20,8),
  @d_unitcost decimal(20,8), @d_direct decimal(20,8), @d_overhead decimal(20,8), @d_labor decimal(20,8),
  @q_unitcost decimal(20,8), @q_direct decimal(20,8), @q_overhead decimal(20,8), @q_utility decimal(20,8),
  @d_utility decimal(20,8), @d_operunitcost decimal(20,8), @d_operdirect decimal(20,8), 
  @c_qty decimal(20,8),
  @d_operoverhead decimal(20,8), @d_operutility decimal(20,8), 
  @cost decimal(20,8), @opercost decimal(20,8), @in_stock decimal(20,8), 
  @temp_qty decimal(20,8), @dummycost decimal(20,8),
  @ar_cgs_code varchar(32), @ar_cgs_direct_code varchar(32), @ar_cgs_ovhd_code varchar(32), 
  @ar_cgs_util_code varchar(32)  ,
  @COGS int,
  @use_ac char(1),@iloop int,@d_cost decimal(20,8),@d_opercost decimal(20,8),    -- mls 10/4/99
  @i_acct varchar(32), @icost decimal(20,8), @iopercost decimal(20,8),      -- mls 10/4/99
  @ovhd_reference_code varchar(32), @util_reference_code varchar(32),
  @direct_reference_code varchar(32), @labor_reference_code varchar(32),
  @ovhd_account    varchar(32), @util_account  varchar(32),
  @direct_account  varchar(32), @labor_account    varchar(32),
  @typ char(1), @o_avg_cost decimal(20,8),             -- mls 5/23/00 SCR 22565
  @o_direct_dolrs decimal(20,8), @o_ovhd_dolrs decimal(20,8),@o_util_dolrs decimal(20,8),  -- mls 5/23/00 SCR 22565
  @s_std_cost decimal(20,8), @s_direct_dolrs decimal(20,8), @s_ovhd_dolrs decimal(20,8),
  @s_util_dolrs decimal(20,8),
  @r_avg_cost decimal(20,8),           -- mls 5/23/00 SCR 22565
  @r_direct_dolrs decimal(20,8), @r_ovhd_dolrs decimal(20,8),@r_util_dolrs decimal(20,8),  -- mls 5/23/00 SCR 22565
  @tempqty decimal(20,8), @line_descr varchar(50), @temp_cost decimal(20,8),
  @a_tran_data varchar(255)

DECLARE @a_tran_id int, @msg varchar(255)

DECLARE c_issues CURSOR LOCAL FOR
SELECT i.part_no, i.location_from, (i.qty * i.direction), i.issue_no, i.direction,
  i.issue_date, isnull(c.code,''), c.account,
  case when rtrim(isnull(i.mtrl_account_expense,'')) = '' then c.account else i.mtrl_account_expense end,
  case when rtrim(isnull(i.direct_account_expense,'')) = '' then c.account else i.direct_account_expense end, 
  case when rtrim(isnull(i.ovhd_account_expense,'')) = '' then c.account else i.ovhd_account_expense end,
  case when rtrim(isnull(i.util_account_expense,'')) = '' then c.account else i.util_account_expense end,
  i.mtrl_reference_cd_expense, i.direct_reference_cd_expense, i.ovhd_reference_cd_expense,
  i.util_reference_cd_expense,
  isnull(i.avg_cost,0), isnull(i.direct_dolrs,0), isnull(i.ovhd_dolrs,0), 
  isnull(i.labor,0), isnull(i.util_dolrs,0),
  i.status,
  d.status, d.issue_no,
  isnull(i.organization_id,'')
from inserted i
left outer join deleted d on d.issue_no = i.issue_no
left outer join issue_code c on c.code = i.code
where i.status > 'Q'

OPEN c_issues

FETCH NEXT FROM c_issues INTO
  @i_part_no, @i_location_from, @i_qty, @i_issue_no, @i_direction,
  @i_issue_date, @c_code, @c_account,
  @i_mtrl_account_expense, @i_direct_account_expense, 		
  @i_ovhd_account_expense, @i_util_account_expense,
  @i_mtrl_reference_cd, @i_direct_reference_cd,
  @i_ovhd_reference_cd, @i_util_reference_cd,
  @i_avg_cost, @i_direct_dolrs, @i_ovhd_dolrs, @i_labor, @i_util_dolrs,
  @i_status,
  @d_status,@d_issue_no,
  @i_org_id

WHILE @@FETCH_STATUS = 0
begin
  if @d_issue_no is NULL
  begin
    rollback tran
    exec adm_raiserror 93231, 'You Cannot Change an Issue Number!'
    return
  end
  if @d_status > 'Q'
  begin
    rollback tran
    exec adm_raiserror 93231, 'You Cannot Update Issues!'
    return
  end

  if @i_org_id = ''												-- I/O start
  begin
    select @i_org_id = dbo.adm_get_locations_org_fn(@i_location_from)
    update issues_all
    set organization_id = @i_org_id 
    where issue_no = @i_issue_no
  end

  else
  begin
    if @i_org_id != dbo.adm_get_locations_org_fn(@i_location_from)
    begin
      select @msg = 'Organization ([' + @i_org_id + ']) is not the current organization for Location ([' + @i_location_from + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
  end														-- I/O end

  if @company_id is NULL
  begin
    SELECT @company_id = company_id,
      @natcode    = home_currency
    FROM glco (nolock)

    if @natcode = NULL
    BEGIN
      rollback tran
      exec adm_raiserror 83221, 'Could Not Find Currency Code.'
      return
    END
  end

  SELECT @tran_date = getdate(),                -- mls 6/2/00 SCR 22994
    @unitcost  = 0,  @direct=0,   @overhead=0,   @labor=0,   @utility=0 ,
    @operunitcost  = 0,  @operdirect=0,   @operoverhead=0, @operutility=0 ,
    @d_unitcost = @i_avg_cost * @i_qty, @d_direct = @i_direct_dolrs* @i_qty, @d_overhead = @i_ovhd_dolrs* @i_qty,
    @d_utility = @i_util_dolrs* @i_qty, @d_labor = @i_labor * @i_qty,
    @COGS = 0  --Set Cost of Good Sold to FALSE

  select @unitcost = @d_unitcost, @direct = @d_direct, @overhead = @d_overhead, @utility = @d_utility
  select @a_tran_data = convert(char(8),@c_code) + convert(char(1),@i_status) + convert(char(1),@d_status)

  exec @retval = adm_inv_tran 
    'I', @i_issue_no, 0,0, @i_part_no, @i_location_from, @i_qty, @i_issue_date, '', 1,
    'S', @a_tran_data, DEFAULT, 
    @a_tran_id OUT, @d_unitcost OUT, @d_direct OUT, @d_overhead OUT, @d_utility OUT, @d_labor OUT,
    @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT, @typ OUT
  if @retval <> 1
  begin
    rollback tran
    select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran_issue.'
    exec adm_raiserror 83202, @msg
    RETURN
  end

  select @c_unitcost = @d_unitcost - @unitcost, --(@cogs_qty * @n_unitcost),
    @c_direct = @d_direct - @direct, --(@cogs_qty * @n_direct),
    @c_overhead = @d_overhead - @overhead, --(@cogs_qty * @n_overhead),
    @c_utility = @d_utility - @utility, --(@cogs_qty * @n_utility), 
    @c_qty = @i_qty

  if ( @COGS = 2 ) 	--Case the quantity balance start with negative value, but the in coming
  begin			-- Qty will make it becomes positive.
    select @c_qty = - @in_stock  
  end
     
  

  -- Get Accounts
  SELECT @direct_acct   = inv_direct_acct_code,
    @ovhd_acct     = inv_ovhd_acct_code,
    @util_acct     = inv_util_acct_code,
    @inv_acct      = inv_acct_code,
    @ar_cgs_code = ar_cgs_code,
    @ar_cgs_direct_code  = ar_cgs_direct_code ,
    @ar_cgs_ovhd_code = ar_cgs_ovhd_code,
    @ar_cgs_util_code = ar_cgs_util_code,
    @var_acct      = cost_var_code,
    @var_direct  = cost_var_direct_code,
    @var_ovhd = cost_var_ovhd_code,
    @var_util = cost_var_util_code
  FROM in_account a (nolock)
  join inv_list l on l.acct_code = a.acct_code and l.part_no = @i_part_no and l.location = @i_location_from

  select
    @expense_unit_cost = @d_unitcost , 
    @expense_direct_cost =  @d_direct ,
    @expense_overhead_cost =  @d_overhead ,
    @expense_utility_cost =  @d_utility     

  SELECT @iloop = 1
  WHILE @iloop <= 4  
  BEGIN 
    SELECT @icost =
      CASE @iloop
        WHEN 1 THEN -@expense_unit_cost WHEN 2 THEN -@expense_direct_cost 
        WHEN 3 THEN -@expense_overhead_cost WHEN 4 THEN -@expense_utility_cost END,
      @i_acct =
      CASE @iloop
        WHEN 1 THEN @i_mtrl_account_expense WHEN 2 THEN @i_direct_account_expense
        WHEN 3 THEN @i_ovhd_account_expense WHEN 4 THEN @i_util_account_expense END,
      @i_ref_cd =
      CASE @iloop
        WHEN 1 THEN @i_mtrl_reference_cd WHEN 2 THEN @i_direct_reference_cd
        WHEN 3 THEN @i_ovhd_reference_cd WHEN 4 THEN @i_util_reference_cd END,
      @line_descr =
      CASE @iloop
        WHEN 1 THEN 'exp_acct' WHEN 2 THEN 'exp_direct_acct'
        WHEN 3 THEN 'exp_ovhd_acct' WHEN 4 THEN 'exp_util_acct' END

    if (@icost) != 0 
    begin
      select @temp_cost = @icost / @i_qty
      exec @retval = adm_gl_insert  @i_part_no,@i_location_from,'I',@i_issue_no,0,0,
        @i_issue_date, @i_qty, @temp_cost , @i_acct , @natcode , 
       DEFAULT , DEFAULT , @company_id, DEFAULT, @i_ref_cd, @a_tran_id,	-- mls 6/3/03 SCR 31312
       @line_descr, @icost						-- mls 4/15/02 SCR 28686

      IF @retval <= 0 
      BEGIN
        rollback tran
        exec adm_raiserror 83230, 'Error Inserting GL Costing Record! -   material'
        return
      END
    end

    select @iloop = @iloop + 1
  end

-- process the accounts in a while loop since the calculations are the same, the only thing different
-- is the cost.     
  SELECT @iloop = 1                    -- mls 10/4/99 start
  WHILE @iloop <= 4  
  BEGIN 
    SELECT @icost =
      CASE @iloop
        WHEN 1 THEN @unitcost WHEN 2 THEN @direct 
        WHEN 3 THEN @overhead WHEN 4 THEN @utility END,
      @iopercost =
      CASE @iloop
        WHEN 1 THEN @operunitcost WHEN 2 THEN @operdirect
        WHEN 3 THEN @operoverhead WHEN 4 THEN @operutility END,
      @d_cost =
      CASE @iloop
        WHEN 1 THEN @d_unitcost WHEN 2 THEN @d_direct
        WHEN 3 THEN @d_overhead WHEN 4 THEN @d_utility END,
      @d_opercost =
      CASE @iloop
        WHEN 1 THEN @d_operunitcost WHEN 2 THEN @d_operdirect
        WHEN 3 THEN @d_operoverhead WHEN 4 THEN @d_operutility END,
      @i_acct =
      CASE @iloop
        WHEN 1 THEN @inv_acct WHEN 2 THEN @direct_acct
        WHEN 3 THEN @ovhd_acct WHEN 4 THEN @util_acct END,
      @i_ref_cd =										-- mls 11/05/03 SCR 32031
      CASE @iloop
        WHEN 1 THEN @i_mtrl_reference_cd WHEN 2 THEN @i_direct_reference_cd
        WHEN 3 THEN @i_ovhd_reference_cd WHEN 4 THEN @i_util_reference_cd END,
      @line_descr =
      CASE @iloop
        WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct'
        WHEN 3 THEN 'inv_ovhd_acct' WHEN 4 THEN 'inv_util_acct' END

    select @line_descr = @line_descr + case @COGS when 1 then ' (- -)' when 2 then ' (- +)' else '' end

    select @cost = 0                        -- mls 5/23/00 SCR 22565
    if (@icost != 0  or @d_cost != 0 ) or @iloop = 1
    BEGIN     --spham 10/5/99            -- mls  
      select @issue_ref_code = ''								-- mls 11/05/03 SCR 32031 start
      if exists (select 1 from glrefact (nolock) where @i_acct like account_mask and reference_flag > 1)
      begin
        if exists (select 1 from glratyp t (nolock), glref r (nolock)
          where t.reference_type = r.reference_type and @i_acct like t.account_mask and
          r.status_flag = 0 and r.reference_code  = @i_ref_cd)
        begin
          select @issue_ref_code = @i_ref_cd
        end
      end											-- mls 11/05/03 SCR 32031 end

      select @temp_cost = @icost / @i_qty
      exec @retval = adm_gl_insert  @i_part_no,@i_location_from,'I',@i_issue_no,0,0,
        @i_issue_date, @i_qty,@temp_cost,@i_acct,@natcode,DEFAULT,DEFAULT,      -- mls 6/2/00 SCR 22994
        @company_id,
        DEFAULT, @issue_ref_code, @a_tran_id, @line_descr, @icost, @iloop			-- mls 11/05/03 SCR 32031

      IF @retval <= 0 
      BEGIN
        rollback tran
        exec adm_raiserror 83231, 'Error Inserting GL Costing Record!'
        return
      END
    END

    SELECT @iloop = @iloop + 1
  END --While                    -- mls 10/4/99 end

  if ( @COGS != 0 ) 
  begin  --Case there is a Cost of Good Sold, that currently has negative balance
    SELECT @iloop = 1										-- mls 10/4/99 start
    WHILE @iloop <= 4  
    BEGIN 
      --Create a new gl account with the cost different	
      SELECT @icost =
        CASE @iloop
          WHEN 1 THEN @c_unitcost WHEN 2 THEN @c_direct
          WHEN 3 THEN @c_overhead WHEN 4 THEN @c_utility END,
        @i_acct =
        CASE @iloop
          WHEN 1 THEN @ar_cgs_code WHEN 2 THEN @ar_cgs_direct_code
          WHEN 3 THEN @ar_cgs_ovhd_code WHEN 4 THEN @ar_cgs_util_code END,
        @i_ref_cd =										-- mls 11/05/03 SCR 32031
        CASE @iloop
          WHEN 1 THEN @i_mtrl_reference_cd WHEN 2 THEN @i_direct_reference_cd
          WHEN 3 THEN @i_ovhd_reference_cd WHEN 4 THEN @i_util_reference_cd END,
        @line_descr =
        CASE @iloop
          WHEN 1 THEN 'ar_cgs_acct' WHEN 2 THEN 'ar_cgs_direct_acct'
          WHEN 3 THEN 'ar_cgs_ovhd_acct' WHEN 4 THEN 'ar_cgs_util_acct' END

      if ( @icost) != 0 
      BEGIN      
        select @issue_ref_code = ''								-- mls 11/05/03 SCR 32031 start
        if exists (select 1 from glrefact (nolock) where @i_acct like account_mask and reference_flag > 1)
        begin
          if exists (select 1 from glratyp t (nolock), glref r (nolock)
            where t.reference_type = r.reference_type and @i_acct like t.account_mask and
            r.status_flag = 0 and r.reference_code  = @i_ref_cd)
          begin
            select @issue_ref_code = @i_ref_cd
          end
        end											-- mls 11/05/03 SCR 32031 end

        select @temp_cost = @icost / @c_qty
        exec @retval = adm_gl_insert  @i_part_no,@i_location_from,'I',@i_issue_no,0,0,
          @i_issue_date, @c_qty, @temp_cost, @i_acct, @natcode, DEFAULT, DEFAULT,  	-- mls 6/2/00 SCR 22994
          @company_id,
          DEFAULT, @issue_ref_code, @a_tran_id, @line_descr, @icost				-- mls 11/05/03 SCR 32031

        IF @retval <= 0
        BEGIN
          rollback tran
          exec adm_raiserror 83231, 'Error Inserting GL Costing Record!'
          return
        END
      END

      SELECT @iloop = @iloop + 1
    END
  END  --COGS

  if ( @COGS = 0 ) and (charindex(@typ,'123456789') > 0  or @typ = 'S') and 
    (abs(@c_unitcost) + abs(@c_direct) + abs(@c_overhead) + abs(@c_utility)) != 0
  begin
    SELECT @iloop = 1	
    WHILE @iloop <= 4  
    BEGIN 
      --Create a new gl account with the cost different	
      SELECT @icost =
        CASE @iloop
          WHEN 1 THEN @c_unitcost WHEN 2 THEN @c_direct 
          WHEN 3 THEN @c_overhead WHEN 4 THEN @c_utility END,
        @i_acct =
        CASE @iloop
          WHEN 1 THEN @var_acct WHEN 2 THEN @var_direct
          WHEN 3 THEN @var_ovhd WHEN 4 THEN @var_util END,
        @i_ref_cd =										-- mls 11/05/03 SCR 32031
        CASE @iloop
          WHEN 1 THEN @i_mtrl_reference_cd WHEN 2 THEN @i_direct_reference_cd
          WHEN 3 THEN @i_ovhd_reference_cd WHEN 4 THEN @i_util_reference_cd END,
        @line_descr =
        CASE @iloop
          WHEN 1 THEN 'cost_var_acct' WHEN 2 THEN 'direct_var_acct'
          WHEN 3 THEN 'ovhd_var_acct' WHEN 4 THEN 'util_var_acct' END
        
      if (@icost) != 0 
      BEGIN      
        select @issue_ref_code = ''								-- mls 11/05/03 SCR 32031 start
        if exists (select 1 from glrefact (nolock) where @i_acct like account_mask and reference_flag > 1)
        begin
          if exists (select 1 from glratyp t (nolock), glref r (nolock)
            where t.reference_type = r.reference_type and @i_acct like t.account_mask and
            r.status_flag = 0 and r.reference_code  = @i_ref_cd)
          begin
            select @issue_ref_code = @i_ref_cd
          end
        end											-- mls 11/05/03 SCR 32031 end

        select @temp_cost = @icost / @c_qty
        exec @retval = adm_gl_insert  @i_part_no,@i_location_from,'I',@i_issue_no,0,0,
          @i_issue_date, @c_qty, @temp_cost, @i_acct, @natcode, DEFAULT, DEFAULT,  	-- mls 6/2/00 SCR 22994
          @company_id, DEFAULT, @issue_ref_code, @a_tran_id, @line_descr, @icost		-- mls 11/05/03 SCR 32031

        IF @retval <= 0
        BEGIN
          rollback tran
          exec adm_raiserror 83231 ,'Error Inserting GL Costing Record!'
          return
        END
      END

      SELECT @iloop = @iloop + 1
    END
  END  --COGS
   
  FETCH NEXT FROM c_issues INTO
    @i_part_no, @i_location_from, @i_qty, @i_issue_no, @i_direction,
    @i_issue_date, @c_code, @c_account,
    @i_mtrl_account_expense, @i_direct_account_expense, 		
    @i_ovhd_account_expense, @i_util_account_expense,
    @i_mtrl_reference_cd, @i_direct_reference_cd,
    @i_ovhd_reference_cd, @i_util_reference_cd,
    @i_avg_cost, @i_direct_dolrs, @i_ovhd_dolrs, @i_labor, @i_util_dolrs,
    @i_status,
    @d_status,@d_issue_no,
    @i_org_id
  END
END

close c_issues
deallocate c_issues

GO
ALTER TABLE [dbo].[issues_all] ADD CONSTRAINT [issues_serial_flag_cc1] CHECK (([serial_flag]=(1) OR [serial_flag]=(0)))
GO
CREATE NONCLUSTERED INDEX [iss2] ON [dbo].[issues_all] ([issue_date]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [iss1] ON [dbo].[issues_all] ([issue_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [iss3_111513] ON [dbo].[issues_all] ([part_no], [code]) INCLUDE ([issue_no], [location_from]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[issues_all] TO [public]
GO
GRANT SELECT ON  [dbo].[issues_all] TO [public]
GO
GRANT INSERT ON  [dbo].[issues_all] TO [public]
GO
GRANT DELETE ON  [dbo].[issues_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[issues_all] TO [public]
GO
