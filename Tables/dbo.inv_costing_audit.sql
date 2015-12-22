CREATE TABLE [dbo].[inv_costing_audit]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence] [int] NOT NULL,
[tran_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [int] NOT NULL,
[tran_ext] [int] NOT NULL,
[tran_line] [int] NOT NULL,
[tran_date] [datetime] NOT NULL,
[tran_age] [datetime] NOT NULL,
[unit_cost] [decimal] (20, 8) NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[balance] [decimal] (20, 8) NOT NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[labor] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[account] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_cost] [decimal] (20, 8) NOT NULL,
[audit] [int] NOT NULL IDENTITY(1, 1),
[prev_unit_cost] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__inv_costi__prev___24F361DC] DEFAULT ((0)),
[prev_direct_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__inv_costi__prev___25E78615] DEFAULT ((0)),
[prev_ovhd_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__inv_costi__prev___26DBAA4E] DEFAULT ((0)),
[prev_util_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__inv_costi__prev___27CFCE87] DEFAULT ((0)),
[lot_ser] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_costi__lot_s__28C3F2C0] DEFAULT ('')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700delinvaud] ON [dbo].[inv_costing_audit] 
FOR DELETE 
AS

BEGIN
if exists (select * from config where flag='TRIG_DEL_INVAUDIT' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 71399, 'You Can Not Delete A Costing Audit Record!' 
	return
	end
end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insinvaud] ON [dbo].[inv_costing_audit] FOR insert AS 
BEGIN

DECLARE @i_part_no varchar(30), @i_location varchar(10), @i_sequence int, @i_tran_code char(1),
@i_tran_no int, @i_tran_ext int, @i_tran_line int, @i_tran_date datetime, @i_tran_age datetime,
@i_unit_cost decimal(20,8), @i_quantity decimal(20,8), @i_balance decimal(20,8),
@i_direct_dolrs decimal(20,8), @i_ovhd_dolrs decimal(20,8), @i_labor decimal(20,8),
@i_util_dolrs decimal(20,8), @i_account varchar(10), @i_org_cost decimal(20,8), @i_audit int,
@i_prev_unit_cost decimal(20,8), @i_prev_direct_dolrs decimal(20,8),
@i_prev_ovhd_dolrs decimal(20,8), @i_prev_util_dolrs decimal(20,8)

DECLARE @company_id int, @iloop int, @retval int, @typ char(1), @sqty decimal(20,8)
DECLARE @natcode   varchar(8), @tran_date datetime, @posting_code varchar(8)
DECLARE @qty  decimal(20,8)
DECLARE @prev_unit_cost decimal(20,8), @prev_direct_dolrs decimal(20,8)				-- mls 1/22/01 SCR 20425
DECLARE @prev_ovhd_dolrs decimal(20,8), @prev_util_dolrs decimal(20,8)				-- mls 1/22/01 SCR 20425
DECLARE @prev_labor decimal(20,8)
DECLARE @prev_tot_m_cost decimal(20,8), @prev_tot_d_cost decimal(20,8)				-- mls 1/22/01 SCR 20425
DECLARE @prev_tot_o_cost decimal(20,8), @prev_tot_u_cost decimal(20,8)				-- mls 1/22/01 SCR 20425
DECLARE @prev_tot_l_cost decimal(20,8)
DECLARE @inv_acct  varchar(32), @direct_acct varchar(32), @recv_acct varchar(32)
DECLARE @ovhd_acct varchar(32), @util_acct   varchar(32), @account   varchar(32)
DECLARE @line_descr varchar(50)								-- mls 4/22/02 SCR 28686
DECLARE @a_tran_id int
DECLARE @COGS int, @in_stock decimal(20,8), @msg varchar(255), @a_tran_info int,
  @a_tran_data varchar(255)


DECLARE t700insinv__cursor CURSOR LOCAL STATIC FOR
SELECT i.part_no, i.location, i.sequence, i.tran_code, i.tran_no, i.tran_ext, i.tran_line,
i.tran_date, i.tran_age, i.unit_cost, i.quantity, i.balance, i.direct_dolrs, i.ovhd_dolrs,
i.labor, i.util_dolrs, i.account, i.org_cost, i.audit, i.prev_unit_cost, i.prev_direct_dolrs,
i.prev_ovhd_dolrs, i.prev_util_dolrs
from inserted i

OPEN t700insinv__cursor

if @@cursor_rows = 0
begin
  CLOSE t700insinv__cursor
  DEALLOCATE t700insinv__cursor
  return
end

SELECT @company_id   = company_id,
       @natcode = home_currency
 FROM glco(nolock)

FETCH NEXT FROM t700insinv__cursor into
@i_part_no, @i_location, @i_sequence, @i_tran_code, @i_tran_no, @i_tran_ext, @i_tran_line,
@i_tran_date, @i_tran_age, @i_unit_cost, @i_quantity, @i_balance, @i_direct_dolrs,
@i_ovhd_dolrs, @i_labor, @i_util_dolrs, @i_account, @i_org_cost, @i_audit, @i_prev_unit_cost,
@i_prev_direct_dolrs, @i_prev_ovhd_dolrs, @i_prev_util_dolrs

While @@FETCH_STATUS = 0
begin
  BEGIN TRAN

  SELECT 
    @prev_unit_cost = d.unit_cost,
    @prev_direct_dolrs = d.direct_dolrs,
    @prev_ovhd_dolrs = d.ovhd_dolrs,
    @prev_util_dolrs = d.util_dolrs,
    @prev_labor = d.labor,
    @prev_tot_m_cost = isnull(tot_mtrl_cost,d.unit_cost*d.balance),	
    @prev_tot_d_cost = isnull(tot_dir_cost,d.direct_dolrs *d.balance),	
    @prev_tot_o_cost = isnull(tot_ovhd_cost,d.ovhd_dolrs *d.balance),	
    @prev_tot_u_cost = isnull(tot_util_cost,d.util_dolrs *d.balance),
    @prev_tot_l_cost = isnull(tot_labor_cost,d.labor * d.balance),
    @tran_date    = getdate(),
    @qty          = d.balance
  FROM inv_costing d
  WHERE d.part_no  = @i_part_no  AND d.location = @i_location AND d.account  = @i_account  AND
    d.sequence = @i_sequence  

  select @a_tran_info = 200002

  if @i_unit_cost != @prev_unit_cost select @a_tran_info = @a_tran_info + 10000
  if @i_direct_dolrs != @prev_direct_dolrs select @a_tran_info = @a_tran_info + 1000
  if @i_ovhd_dolrs != @prev_ovhd_dolrs select @a_tran_info = @a_tran_info + 100
  if @i_util_dolrs != @prev_util_dolrs select @a_tran_info = @a_tran_info + 10
  select @a_tran_data = @a_tran_info 
  select @a_tran_data = @a_tran_data + @i_account

  exec @retval = adm_inv_tran 
    'C', @i_audit, 0, @i_sequence, @i_part_no, @i_location, @qty, @tran_date, '', 
    1, '', @a_tran_data, DEFAULT, 
    @a_tran_id OUT, @i_unit_cost OUT, @i_direct_dolrs OUT, @i_ovhd_dolrs OUT, @i_util_dolrs OUT, @i_labor OUT,
    @COGS OUT, @prev_tot_m_cost OUT, @prev_tot_d_cost OUT, @prev_tot_o_cost OUT, @prev_tot_u_cost OUT, 
    @prev_tot_l_cost OUT, @in_stock OUT
  if @retval <> 1
  begin
    rollback tran
    select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
    exec adm_raiserror 83202, @msg
    RETURN
  end

  COMMIT TRAN

  FETCH NEXT FROM t700insinv__cursor into
  @i_part_no, @i_location, @i_sequence, @i_tran_code, @i_tran_no, @i_tran_ext, @i_tran_line,
  @i_tran_date, @i_tran_age, @i_unit_cost, @i_quantity, @i_balance, @i_direct_dolrs,
  @i_ovhd_dolrs, @i_labor, @i_util_dolrs, @i_account, @i_org_cost, @i_audit, @i_prev_unit_cost,
  @i_prev_direct_dolrs, @i_prev_ovhd_dolrs, @i_prev_util_dolrs
end -- while

CLOSE t700insinv__cursor
DEALLOCATE t700insinv__cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updinvaud] ON [dbo].[inv_costing_audit] 
FOR UPDATE 
AS
BEGIN

  if Not (Update(part_no) or Update(location) or Update(sequence) or Update(tran_code) or		-- mls 1/22/01 SCR 20425 start
    Update(tran_no) or Update(tran_ext) or Update(tran_line) or Update(tran_date) or Update(tran_age)
    or Update(unit_cost) or Update(quantity) or Update(balance) or Update(direct_dolrs) or
    Update(ovhd_dolrs) or Update(util_dolrs) or Update(labor) or Update(account) or Update(org_cost))
  begin
    return
  end													-- mls 1/22/01 SCR 20425 end

  if exists (select * from config where flag='TRIG_UPD_INVAUDIT' and value_str='DISABLE')
	return
  else
	begin
	rollback tran
	exec adm_raiserror 71399, 'You Can Not Update A Costing Audit Record!'
	return
	end
  end
GO
CREATE CLUSTERED INDEX [invcosta1] ON [dbo].[inv_costing_audit] ([part_no], [location], [account], [sequence]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_costing_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_costing_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_costing_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_costing_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_costing_audit] TO [public]
GO
