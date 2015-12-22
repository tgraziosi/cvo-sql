SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apstlct_sp] @calc_type smallint 
AS
  DECLARE
    @on_acct_total_home float,
    @on_acct_total_oper float,
    @applied_total_home float,
    @applied_total_oper float,
    @pa_total_home   float,
    @pa_total_oper   float,
    @doc_sum_entered   float,
    @oa_pa_total_home   float,
    @oa_pa_total_oper   float,
    @dm_total_home   float,
    @dm_total_oper   float,
    @vo_total_home    float,
    @vo_total_oper    float,
    @disc_total_home   float,
    @disc_total_oper   float,
    @onacct_total_home float,
    @onacct_total_oper float,
    @gain_total_home   float,
    @gain_total_oper   float,
    @loss_total_home   float,
    @loss_total_oper   float,
    @vo_amt_nat      float,
    @rate_home	      float,
    @rate_oper	      float

IF @calc_type = 0
BEGIN

  


  SELECT  @pa_total_home = ISNULL( SUM( doc_amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @pa_total_oper = ISNULL( SUM( doc_amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 ),
          @oa_pa_total_home = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @oa_pa_total_oper = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 )
  FROM   #apinppyt3450
  WHERE payment_type  = 2

  


  SELECT  @dm_total_home = ISNULL( SUM( doc_amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @dm_total_oper = ISNULL( SUM( doc_amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 ),
	  @on_acct_total_home = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @on_acct_total_oper = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 )
  FROM #apinppyt3450
  WHERE payment_type  = 3

  



  SELECT   @vo_amt_nat = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(cross_rate))*(cross_rate) + (SIGN(ABS(SIGN(ROUND(cross_rate,6))))/(cross_rate + SIGN(1 - ABS(SIGN(ROUND(cross_rate,6)))))) * SIGN(SIGN(cross_rate) - 1) ) ), 0.0 )
  FROM    #apinppdt3450

  



  SELECT  @pa_total_home, 
	  @pa_total_oper,
          @dm_total_home, 
          @dm_total_oper,        
          ( @pa_total_home + @dm_total_home ), 
          ( @pa_total_oper + @dm_total_oper ),
	  (@on_acct_total_home + @oa_pa_total_home ), 
	  (@on_acct_total_oper + @oa_pa_total_oper ), 
	  @vo_amt_nat
END
ELSE
BEGIN

  



  SELECT  @doc_sum_entered = ISNULL( SUM((  doc_amount) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )), 0.0 )
  FROM    #apinppyt3450

  SELECT @rate_home = MAX(rate_home),
	 @rate_oper = MAX(rate_oper)
  FROM #apinppyt3450

  



  SELECT @pa_total_home = ISNULL( SUM((  doc_amount ) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )), 0.0 ), 
	 @pa_total_oper = ISNULL( SUM((  doc_amount ) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )), 0.0 ),
	 @oa_pa_total_home = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
         @oa_pa_total_oper = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 )
  FROM  #apinppyt3450
  WHERE payment_type  = 2

  



  SELECT @dm_total_home = ISNULL( SUM((  doc_amount ) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )), 0.0 ), 
         @dm_total_oper = ISNULL( SUM((  doc_amount ) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )), 0.0 ),
	 @onacct_total_home = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
         @onacct_total_oper = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 )
  FROM  #apinppyt3450
  WHERE payment_type  = 3

  



  SELECT  @disc_total_home = ISNULL( SUM( amt_disc_taken * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ) ), 0.0 ),
          @disc_total_oper = ISNULL( SUM( amt_disc_taken * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ) ), 0.0 ),
	  @vo_total_home = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ) ), 0.0 ),
	  @vo_total_oper = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ) ), 0.0 ),
	  @vo_amt_nat = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(cross_rate))*(cross_rate) + (SIGN(ABS(SIGN(ROUND(cross_rate,6))))/(cross_rate + SIGN(1 - ABS(SIGN(ROUND(cross_rate,6)))))) * SIGN(SIGN(cross_rate) - 1) ) ), 0.0 )
  FROM    #apinppdt3450


  SELECT  @gain_total_home = SUM( gain_home )
  FROM    #apinppdt3450
  WHERE   gain_home > 0.0

  SELECT  @gain_total_oper = SUM( gain_oper )
  FROM    #apinppdt3450
  WHERE   gain_oper > 0.0

  SELECT  @loss_total_home = SUM( gain_home )
  FROM    #apinppdt3450
  WHERE   gain_home < 0.0

  SELECT  @loss_total_oper = SUM( gain_oper )
  FROM    #apinppdt3450
  WHERE   gain_oper < 0.0

  



  SELECT  @disc_total_home,
          @disc_total_oper,
          @dm_total_home,
          @dm_total_oper,
          @oa_pa_total_home,
          @oa_pa_total_oper,
          @pa_total_home,
          @pa_total_oper,
	  @onacct_total_home,
          @onacct_total_oper,
	  @gain_total_home,
          @gain_total_oper,
          @loss_total_home,
          @loss_total_oper,
          @vo_total_home,
          @vo_total_oper,
          @doc_sum_entered


END
RETURN

GO
GRANT EXECUTE ON  [dbo].[apstlct_sp] TO [public]
GO
