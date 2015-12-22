SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create proc [dbo].[adm_wavg_cost_var]
@part varchar(30), @loc varchar(10), @tran_code char(1), @tran_no int, @tran_ext int, @tran_line int, @tran_date datetime,
@o_avg_cost decimal(20,8), @o_direct_dolrs decimal(20,8), @o_ovhd_dolrs decimal(20,8), @o_util_dolrs decimal(20,8),
@unitcost decimal(20,8) OUT, @direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @utility decimal(20,8) OUT,
@o_in_stock decimal(20,8), @qty decimal(20,8), @tran_id int,
@n_in_stock decimal(20,8)
as

begin

return 0
end
GO
GRANT EXECUTE ON  [dbo].[adm_wavg_cost_var] TO [public]
GO
