SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[TXGetTotal_SP]		@control_number		varchar(16),
					@total_tax			float		OUTPUT,
					@non_included_tax	float		OUTPUT,
					@included_tax		float		OUTPUT,
                    @calc_method    	char(1) = '1',
					@distr_call			int = 0

AS
declare @curr_precision int, @curr_code varchar(8)

if @distr_call = 0
begin
	SELECT	@non_included_tax = ISNULL(SUM(amt_final_tax), 0.0)
	FROM	#TxInfo
	WHERE	control_number = @control_number 
	AND	tax_included_flag = 0

	SELECT	@included_tax = ISNULL(SUM(amt_final_tax), 0.0)
	FROM	#TXInfo
	WHERE	control_number = @control_number 
	AND	tax_included_flag = 1
	
	SELECT	@total_tax = @non_included_tax + @included_tax
end
else
begin
  select TOP 1 @curr_code = currency_code,
     @curr_precision = curr_precision from #TXLineInput_ex

  if @calc_method = '1' -- calc and rounded at total
  begin
	SELECT	@non_included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)
	FROM	#TXtaxcode tc
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id
	WHERE	tc.control_number = @control_number 
	AND	tc.tax_included_flag = 0

	SELECT	@included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)
	FROM	#TXtaxcode tc 
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id
	WHERE	tc.control_number = @control_number 
	AND	tc.tax_included_flag = 1
  end
  else -- @calc_method = '2' -- calc and not rounded and summed to give total
       -- @calc_method = '3' -- calc and rounded at line item summed to give total
  begin

    if @calc_method = '2'
      select @curr_precision = isnull( (select curr_precision from glcurr_vw (nolock)
	where glcurr_vw.currency_code=@curr_code), 1.0 )

    select @non_included_tax = ISNULL(round(sum(ti.calc_tax),@curr_precision), 0.0)
	from #TXLineInput_ex ti, #TXtaxcode tc
	where ti.control_number = @control_number
        and tc.tax_code = ti.tax_code and tc.control_number = ti.control_number
        and tc.tax_included_flag = 0

    select @included_tax = ISNULL(round(sum(ti.calc_tax),@curr_precision), 0.0)
	from #TXLineInput_ex ti, #TXtaxcode tc
	where ti.control_number = @control_number
        and tc.tax_code = ti.tax_code and tc.control_number = ti.control_number
        and tc.tax_included_flag = 1

  end


  SELECT @total_tax = @non_included_tax + @included_tax

  if not exists (select 1 from #TXTaxOutput where control_number = @control_number)
  and exists (select 1 from #TXLineInput_ex where control_number = @control_number)
  begin
    insert #TXTaxOutput (control_number, amtTotal, amtDisc, amtExemption, amtTax, remoteDocId)
    select @control_number,
      isnull((select sum(extended_price) from #TXLineInput_ex where control_number = @control_number),0),
      isnull((select sum(amt_discount) from #TXLineInput_ex where control_number = @control_number),0),
      0, @total_tax, 0

    insert #TXTaxLineOutput(
    control_number, reference_number, t_index, taxRate, taxable, taxCode, taxability,
    amtTax, amtDisc, amtExemption, taxDetailCnt)
    select control_number, reference_number, 0, 
      case when (extended_price - amt_discount + freight) <> 0 then calc_tax / ( extended_price - amt_discount + freight) else 0 end, 
      extended_price - amt_discount + freight,
      tax_code, 'True', calc_tax, amt_discount, 0, 0
    from #TXLineInput_ex
    where control_number = @control_number

    insert #TXTaxLineDetOutput(control_number, reference_number, t_index,
    d_index,    amtBase,exception, jurisCode,                 
    jurisName, jurisType,
    nonTaxable, taxRate, amtTax,taxable,taxType)
    select ti.control_number, ti.reference_number, 0,
      0, case when ti.action_flag = 0 then ti.extended_price - ti.amt_discount else ti.freight end,
      0, -1,ttr.tax_type,
      -1,0,(tt.tax_rate/100),
      round(ttr.cur_amt * case when tc.tot_extended_amt = 0 then 0 else
      (case when ti.action_flag = 0 then ti.extended_price - ti.amt_discount else ti.freight end/tc.tot_extended_amt) end,@curr_precision),	
      case when ti.action_flag = 0 then ti.extended_price - ti.amt_discount else ti.freight end,
      1
    from #TXLineInput_ex ti
    join #TXtaxcode tc on tc.control_number = ti.control_number and tc.tax_code = ti.tax_code
    join #TXtaxtyperec ttr on ttr.tc_row =tc.row_id
    join #TXtaxtype tt on tt.ttr_row = ttr.row_id
  end

end
GO
GRANT EXECUTE ON  [dbo].[TXGetTotal_SP] TO [public]
GO
