SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_get_in_account]  @acct_code varchar(8), @typ varchar(8),
  @mtrl_acct varchar(32) OUT, @dir_acct varchar(32) out, @ovhd_acct varchar(32) OUT,
  @util_acct varchar(32) OUT
AS
BEGIN
-- rc = -1 - record not found on in_account or is void
-- rc = 1 - record found on in_account
  declare @rc int

  select @rc = 1, @mtrl_acct = '', @dir_acct = '', @ovhd_acct = '', @util_acct = ''

  if @typ = 'FG'
  begin
    select @mtrl_acct = inv_acct_code,
      @dir_acct = inv_direct_acct_code,
      @ovhd_acct = inv_ovhd_acct_code,
      @util_acct = inv_util_acct_code
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'COGS'
  begin
    select @mtrl_acct = ar_cgs_code,
      @dir_acct = ar_cgs_direct_code,
      @ovhd_acct = ar_cgs_ovhd_code,
      @util_acct = ar_cgs_util_code
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'SCI'
  begin
    select @mtrl_acct = std_adj_increase,
      @dir_acct = std_adj_direct_increase,
      @ovhd_acct = std_adj_ovhd_increase,
      @util_acct = std_adj_util_increase
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'SCD'
  begin
    select @mtrl_acct = std_adj_decrease,
      @dir_acct = std_adj_direct_decrease,
      @ovhd_acct = std_adj_ovhd_decrease,
      @util_acct = std_adj_util_decrease
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'COGP'
  begin
    select @mtrl_acct = ap_cgp_code,
      @dir_acct = ap_cgp_direct_code,
      @ovhd_acct = ap_cgp_ovhd_code,
      @util_acct = ap_cgp_util_code
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'CV'
  begin
    select @mtrl_acct = cost_var_code,
      @dir_acct = cost_var_direct_code,
      @ovhd_acct = cost_var_ovhd_code,
      @util_acct = cost_var_util_code
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'WIP'
  begin
    select @mtrl_acct = wip_acct_code,
      @dir_acct = wip_direct_acct_code,
      @ovhd_acct = wip_ovhd_acct_code,
      @util_acct = wip_util_acct_code
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'QC'
  begin
    select @mtrl_acct = qc_acct_code,
      @dir_acct = '',
      @ovhd_acct = '',
      @util_acct = ''
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'MSA'
  begin
    select @mtrl_acct = sales_acct_code,
      @dir_acct = '',
      @ovhd_acct = '',
      @util_acct = ''
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'MSR'
  begin
    select @mtrl_acct = sales_return_code,
      @dir_acct = '',
      @ovhd_acct = '',
      @util_acct = ''
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'MRA'
  begin
    select @mtrl_acct = rec_var_code,
      @dir_acct = '',
      @ovhd_acct = '',
      @util_acct = ''
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'MTA'
  begin
    select @mtrl_acct = transfer_acct_code,
      @dir_acct = '',
      @ovhd_acct = '',
      @util_acct = ''
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else if @typ = 'MARCM'
  begin
    select @mtrl_acct = ar_cgs_mask,
      @dir_acct = '',
      @ovhd_acct = '',
      @util_acct = ''
    from in_account (nolock)
    where acct_code = @acct_code and isnull(void,'N') != 'V'
  end
  else
  begin
    select @rc = -1
  end

  if @@rowcount = 0
  begin
    select @rc = -1
  end

  return @rc
END
GO
GRANT EXECUTE ON  [dbo].[adm_get_in_account] TO [public]
GO
