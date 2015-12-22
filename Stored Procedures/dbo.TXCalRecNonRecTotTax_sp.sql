SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
CREATE PROC [dbo].[TXCalRecNonRecTotTax_sp] @control_number       varchar(16),   
     @total_recoverable_tax      decimal(20,8) OUTPUT,  
     @rec_non_included_tax      decimal(20,8) OUTPUT,  
     @rec_included_tax    decimal(20,8) OUTPUT,  
     @total_nonrecoverable_tax    decimal(20,8) OUTPUT,  
     @nonr_non_included_tax       decimal(20,8) OUTPUT,  
     @nonr_included_tax           decimal(20,8) OUTPUT,  
     @nonr_freight_tax    decimal(20,8) OUTPUT,  
                    @calc_method     char(1) = '1'  
  
AS  
declare @curr_precision int, @curr_code varchar(8)  
  

  update tt  
  set recoverable_flag = 1  
  from #TXtaxtype tt  
  where recoverable_flag = 0 and  
    not (tt.cents_code_flag = 0  
    and tt.tax_range_flag = 0)  
  

  update tt  
  set dtl_incl_ind = 1  
  from #TXtaxtype tt  
  where (tt.tax_based_type != 2  
    and tt.cents_code_flag = 0  
    and tt.tax_range_flag = 0)  
  
  
  if @calc_method = '1' -- calc and rounded at total  
  begin  
 SELECT @rec_non_included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc  
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id and tt.recoverable_flag = 1  
 WHERE tc.control_number = @control_number   
 AND tc.tax_included_flag = 0  
  
 SELECT @rec_included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc   
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id and tt.recoverable_flag = 1  
 WHERE tc.control_number = @control_number   
 AND tc.tax_included_flag = 1  
  
 SELECT @nonr_non_included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc  
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id and tt.recoverable_flag = 0  
 WHERE tc.control_number = @control_number   
 AND tt.tax_based_type != 2  
 AND tc.tax_included_flag = 0  
  
 SELECT @nonr_included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc   
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id and tt.recoverable_flag = 0  
 WHERE tc.control_number = @control_number   
 AND tt.tax_based_type != 2  
 AND tc.tax_included_flag = 1  
  
 SELECT @nonr_freight_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc   
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id and tt.recoverable_flag = 0  
 WHERE tc.control_number = @control_number   
 AND tt.tax_based_type = 2  
  
  end  
  else -- @calc_method = '2' -- calc and not rounded and summed to give total  
       -- @calc_method = '3' -- calc and rounded at line item summed to give total  
  begin  
    select TOP 1 @curr_code = currency_code,  
       @curr_precision = curr_precision from #TXLineInput_ex  
  
    if @calc_method = '2'  
      select @curr_precision = isnull( (select curr_precision from glcurr_vw (nolock)  
 where glcurr_vw.currency_code=@curr_code), 1.0 )  
  
 SELECT @rec_non_included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc  
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id and tt.recoverable_flag = 1  
 WHERE tc.control_number = @control_number   
 AND tc.tax_included_flag = 0  
  
 SELECT @rec_included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc   
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id and tt.recoverable_flag = 1  
 WHERE tc.control_number = @control_number   
 AND tc.tax_included_flag = 1  
  
 SELECT @nonr_non_included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc  
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id and tt.recoverable_flag = 0  
 WHERE tc.control_number = @control_number   
 AND tt.tax_based_type != 2  
 AND tc.tax_included_flag = 0  
  
 SELECT @nonr_included_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc   
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id and tt.recoverable_flag = 0  
 WHERE tc.control_number = @control_number   
 AND tt.tax_based_type != 2  
 AND tc.tax_included_flag = 1  
  
 SELECT @nonr_freight_tax = ISNULL(SUM(tt.amt_final_tax), 0.0)  
 FROM #TXtaxcode tc   
        join    #TXtaxtyperec ttr on ttr.tc_row = tc.row_id  
        join    #TXtaxtype tt on tt.ttr_row = ttr.row_id and tt.recoverable_flag = 0  
 WHERE tc.control_number = @control_number   
 AND tt.tax_based_type = 2  
  
    select @nonr_non_included_tax = round(@nonr_non_included_tax,@curr_precision),  
      @nonr_included_tax = round(@nonr_included_tax,@curr_precision),  
      @nonr_freight_tax = round(@nonr_freight_tax,@curr_precision),  
      @rec_non_included_tax = round(@rec_non_included_tax,@curr_precision),  
      @rec_included_tax = round(@rec_included_tax,@curr_precision)  
  end  
  
  
  SELECT @total_recoverable_tax = round(@rec_non_included_tax + @rec_included_tax,2),  
    @total_nonrecoverable_tax = round(@nonr_non_included_tax + @nonr_included_tax + @nonr_freight_tax,2)  
  
GO
GRANT EXECUTE ON  [dbo].[TXCalRecNonRecTotTax_sp] TO [public]
GO
