SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE	[dbo].[EAI_ord_tax_n_total] @ord_no int, @ext int, @cust_code varchar(10), @status varchar(1), @date_entered int AS
Begin
   declare @err_no int
   declare @result int


	--Declare all the temp tables that need to call from fs_calculate_oetax.
	CREATE TABLE #TxLineInput (control_number varchar(16), reference_number int, tax_code varchar(8), quantity FLOAT, extended_price float,
      		discount_amount float, tax_type smallint, currency_code varchar(8))

	CREATE TABLE #TxInfo ( control_number varchar(16), sequence_id int, tax_type_code varchar(8), amt_taxable float, amt_gross float,
		amt_tax float, amt_final_tax float, currency_code varchar(8), tax_included_flag	smallint )

	CREATE TABLE #TxLineTax (control_number varchar(16), reference_number int, tax_amount float, tax_included_flag	smallint )
	
	CREATE TABLE #txdetail ( control_number	varchar(16), reference_number	int, 
		tax_type_code		varchar(8),	amt_taxable		float	) 

	CREATE TABLE #txinfo_id ( id_col numeric identity, control_number	varchar(16), 
		sequence_id		int,	tax_type_code		varchar(8),	currency_code		varchar(8)	)

	CREATE TABLE #TXInfo_min_id (control_number varchar(16),min_id_col numeric) 

	CREATE TABLE	#TxTLD ( control_number	varchar(16), tax_type_code varchar(8), tax_code varchar(8), currency_code varchar(8),
		tax_included_flag smallint, base_id int, amt_taxable float, amt_gross float)

	CREATE TABLE #arcrchk (  customer_code varchar(8), check_credit_limit smallint, credit_limit float, limit_by_home smallint)

	CREATE UNIQUE INDEX #arcrchk_ind_0 ON #arcrchk (customer_code)

/*
** Rev 4 Tables updated. 
*/
create table #adm_taxinfo(
  row_id int identity,
  control_number varchar(16) not null,
  reference_number int not null,
  trx_type int not null,
  currency_code	varchar(8),
  curr_precision int,
  amt_tax decimal(20,8),
  amt_final_tax decimal(20,8),
  tax_code varchar(8),
  freight decimal(20,8),
  qty decimal(20,8),
  unit_price decimal(20,8),
  extended_price decimal(20,8),
  amt_discount decimal(20,8),
  err_no int,
  action_flag int,
  seqid int,
  calc_tax decimal(20,8),
  vat_prc decimal(20,8))

create index adm_ti1 on #adm_taxinfo(row_id)
create index adm_ti2 on #adm_taxinfo(control_number, reference_number)

create table #adm_taxtype (
  row_id int identity,
  ttr_row int,
  tax_type varchar(8),
  ext_amt decimal(20,8),
  amt_gross decimal(20,8),
  amt_taxable decimal(20,8),
  amt_tax decimal(20,8),
  amt_final_tax decimal(20,8),
  amt_tax_included decimal(20,8),
  save_flag int,
  tax_rate decimal(20,8),
  prc_flag int,
  prc_type int,
  cents_code_flag int,
  cents_code varchar(8),
  cents_cnt int,
  tax_based_type int,
  tax_included_flag int,
  modify_base_prc decimal(20,8),
  base_range_flag int,
  base_range_type int,
  base_taxed_type int,
  min_base_amt decimal(20,8),
  max_base_amt decimal(20,8),
  tax_range_flag int,
  tax_range_type int,
  min_tax_amt decimal(20,8),
  max_tax_amt decimal(20,8),
  recoverable_flag int)

create index adm_tt1 on #adm_taxtype(row_id)
create index adm_tt2 on #adm_taxtype(ttr_row)


create table #adm_taxtyperec (
  row_id int identity,
  tc_row int,
  tax_code varchar(8),
  seq_id int,
  base_id int,
  cur_amt decimal(20,8),
  old_tax decimal(20,8),
  tax_type varchar(8))


create index adm_ttr1 on #adm_taxtyperec(row_id)
create index adm_ttr2 on #adm_taxtyperec(tc_row)
create index adm_ttr3 on #adm_taxtyperec(tax_code, tc_row, seq_id)

create table #adm_taxcode (
  row_id int identity,
  ti_row int,
  control_number varchar(16),
  tax_code varchar(8),
  amt_tax decimal(20,8),
  tax_included_flag int,
  tax_type_cnt int,
  tot_extended_amt decimal(20,8) NULL)


create index adm_tc1 on #adm_taxcode(row_id)
create index adm_tc2 on #adm_taxcode(control_number, tax_code)

create table #cents (
  row_id int identity,
  cents_code varchar(8),
  to_cent float,
  tax_cents float)

create index c1 on #cents(cents_code,row_id)





   begin transaction
   	exec fs_calculate_oetax @ord_no, @ext, @err_no out

   	If ((@err_no <> 1) or ( @@error <> 0 ))
   	begin
		raiserror 90000 'Cannot call fs_calculate_oetax'
		rollback transaction
   		return @@error 
   	end

   	exec fs_updordtots  @ord_no, @ext
   	If ((@err_no <> 1) or ( @@error <> 0 ))
   	begin
		raiserror 90001 'Cannot call fs_updordtots.'
		rollback transaction
   		return @@error 
   	end


	if (@status = 'N') begin		-- check status on new orders, not voided
		exec fs_archklmt_sp @cust_code, @date_entered, @ord_no, @ext, @result OUT

		if @@error <> 0 begin
			raiserror 90002 'Cannot call fs_archklmt_sp.'
			rollback transaction
	   		return @@error 
	   	end

		if (@result < 0) begin
			if @status = 'H' begin 
				select @status = 'B'
			end
			else begin
				select @status = 'C'
			end

			UPDATE orders 
			SET status = @status
			WHERE orders.order_no = @ord_no and orders.ext = @ext
		end
	end
   commit transaction

drop table #adm_taxinfo
drop table #adm_taxcode
drop table #adm_taxtype
drop table #adm_taxtyperec
drop table #cents

END 
GO
GRANT EXECUTE ON  [dbo].[EAI_ord_tax_n_total] TO [public]
GO
