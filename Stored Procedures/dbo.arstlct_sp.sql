SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arstlct_sp] @calc_type smallint 
AS
  DECLARE
    @on_acct_total_home float,
    @on_acct_total_oper float,
    @applied_total_home float,
    @applied_total_oper float,
    @cr_total_home   float,
    @cr_total_oper   float,
    @doc_sum_entered   float,
    @oa_cr_total_home   float,
    @oa_cr_total_oper   float,
    @cm_total_home   float,
    @cm_total_oper   float,
    @inv_total_home    float,
    @inv_total_oper    float,
    @disc_total_home   float,
    @disc_total_oper   float,
    @wroff_total_home  float,
    @wroff_total_oper  float,
    @onacct_total_home float,
    @onacct_total_oper float,
    @gain_total_home   float,
    @gain_total_oper   float,
    @loss_total_home   float,
    @loss_total_oper   float,
    @inv_amt_nat      float,
    @rate_home	      float,
    @rate_oper	      float

IF @calc_type = 0
BEGIN

  


  SELECT  @cr_total_home = ISNULL( SUM( doc_amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @cr_total_oper = ISNULL( SUM( doc_amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 ),
	  @oa_cr_total_home = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @oa_cr_total_oper = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 )
  FROM #arinppyt4750
  WHERE payment_type = 2

  


  SELECT  @cm_total_home = ISNULL( SUM( doc_amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @cm_total_oper = ISNULL( SUM( doc_amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 ),
	  @on_acct_total_home = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
          @on_acct_total_oper = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 )
  FROM #arinppyt4750
  WHERE payment_type  = 4


  



  SELECT  @inv_amt_nat = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(cross_rate))*(cross_rate) + (SIGN(ABS(SIGN(ROUND(cross_rate,6))))/(cross_rate + SIGN(1 - ABS(SIGN(ROUND(cross_rate,6)))))) * SIGN(SIGN(cross_rate) - 1) ) ), 0.0 )
  FROM    #arinppdt4750


 
  


  SELECT  @cr_total_home, 
          @cr_total_oper,
          @cm_total_home, 
          @cm_total_oper,        
          ( @cr_total_home + @cm_total_home ), 
          ( @cr_total_oper + @cm_total_oper ),
	  ( @on_acct_total_home + @oa_cr_total_home ), 
          ( @on_acct_total_oper + @oa_cr_total_oper ),
	  @inv_amt_nat
END
ELSE
BEGIN


  



  SELECT  @doc_sum_entered = ISNULL( SUM((  doc_amount) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )), 0.0 )
  FROM    #arinppyt4750

  SELECT @rate_home = MAX(rate_home),
	 @rate_oper = MAX(rate_oper)
  FROM #arinppyt4750

  


   
  SELECT @cr_total_home = ISNULL( SUM((  doc_amount ) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )), 0.0 ), 
	 @cr_total_oper = ISNULL( SUM((  doc_amount ) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )), 0.0 ),
	 @oa_cr_total_home = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
         @oa_cr_total_oper = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 )
  FROM  #arinppyt4750
  WHERE payment_type = 2

  



  SELECT @cm_total_home = ISNULL( SUM((  doc_amount ) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )), 0.0 ), 
         @cm_total_oper = ISNULL( SUM((  doc_amount ) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )), 0.0 ),
	 @onacct_total_home = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ) ), 0.0 ),
         @onacct_total_oper = ISNULL( SUM( amt_on_acct * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ) ), 0.0 )
  FROM  #arinppyt4750
  WHERE payment_type = 4

  



  SELECT  @disc_total_home = ISNULL( SUM( amt_disc_taken * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ) ), 0.0 ),
          @disc_total_oper = ISNULL( SUM( amt_disc_taken * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ) ), 0.0 ),
          @wroff_total_home = ISNULL( SUM( writeoff_amount * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ) ), 0.0 ),
          @wroff_total_oper = ISNULL( SUM( writeoff_amount * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ) ), 0.0 ),
	  @inv_total_home = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ) ), 0.0 ),
	  @inv_total_oper = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ) ), 0.0 ),
	  @inv_amt_nat = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(cross_rate))*(cross_rate) + (SIGN(ABS(SIGN(ROUND(cross_rate,6))))/(cross_rate + SIGN(1 - ABS(SIGN(ROUND(cross_rate,6)))))) * SIGN(SIGN(cross_rate) - 1) ) ), 0.0 )
  FROM    #arinppdt4750

  SELECT  @gain_total_home = SUM( gain_home )
  FROM    #arinppdt4750
  WHERE   gain_home > 0.0

  SELECT  @gain_total_oper = SUM( gain_oper )
  FROM    #arinppdt4750
  WHERE   gain_oper > 0.0

  SELECT  @loss_total_home = SUM( gain_home )
  FROM    #arinppdt4750
  WHERE   gain_home < 0.0

  SELECT  @loss_total_oper = SUM( gain_oper )
  FROM    #arinppdt4750
  WHERE   gain_oper < 0.0
 
  


  SELECT  @cr_total_home,
          @cr_total_oper,
          @oa_cr_total_home,
          @oa_cr_total_oper,
          @cm_total_home,
          @cm_total_oper,
          @inv_total_home,
          @inv_total_oper,
          @disc_total_home,
          @disc_total_oper,
          @wroff_total_home,
          @wroff_total_oper,
          @onacct_total_home,
          @onacct_total_oper,
          @gain_total_home,
          @gain_total_oper,
          @loss_total_home,
          @loss_total_oper,
	  @doc_sum_entered



END
RETURN

GO
GRANT EXECUTE ON  [dbo].[arstlct_sp] TO [public]
GO
