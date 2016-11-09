SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_promotions_tracker_REVOandSUNPS_sp]
    @sdate DATETIME ,
    @edate DATETIME ,
    @Terr VARCHAR(1000) = NULL ,
    @Promo VARCHAR(5000) = NULL,
    @PromoLevel VARCHAR(5000) = NULL
AS
    BEGIN

-- exec cvo_promotions_tracker_REVOANDSUNPS_sp '11/1/2015','10/31/2016'

        SET NOCOUNT ON;
        SET ANSI_WARNINGS OFF;


        DECLARE @sdately DATETIME ,
            @edately DATETIME;

		SET  @edate   = DATEADD(ms,-3, DATEADD(DAY,1,@edate))
        set  @sdately = DATEADD(YEAR, -1, @sdate)
		SET  @edately = DATEADD(ms, -1, @sdate)

		-- SELECT @sdate, @edate, @sdately, @edately


        CREATE TABLE #temptable
            (
              order_no VARCHAR(10) ,
              ext VARCHAR(3) ,
              cust_code VARCHAR(10) ,
              ship_to VARCHAR(10) ,
              ship_to_name VARCHAR(40) ,
              location VARCHAR(10) ,
              cust_po VARCHAR(20) ,
              routing VARCHAR(20) ,
              fob VARCHAR(10) ,
              attention VARCHAR(40) ,
              tax_id VARCHAR(10) ,
              terms VARCHAR(10) ,
              curr_key VARCHAR(10) ,
              salesperson VARCHAR(8) ,
              Territory VARCHAR(8) ,
              region VARCHAR(3) ,
              total_amt_order DECIMAL(20, 8) ,
              total_discount DECIMAL(20, 8) ,
              total_tax DECIMAL(20, 8) ,
              freight DECIMAL(20, 8) ,
              qty_ordered DECIMAL(38, 8) ,
              qty_shipped DECIMAL(38, 8) ,
              total_invoice DECIMAL(23, 8) ,
              invoice_no VARCHAR(10) ,
              doc_ctrl_num VARCHAR(16) ,
              date_invoice DATETIME ,
              date_entered DATETIME ,
              date_sch_ship DATETIME ,
              date_shipped DATETIME ,
              status VARCHAR(1) ,
              status_desc VARCHAR(13) ,
              who_entered VARCHAR(20) ,
              shipped_flag VARCHAR(3) ,
              hold_reason VARCHAR(10) ,
              orig_no INT ,
              orig_ext INT ,
              promo_id VARCHAR(255) ,
              promo_level VARCHAR(255) ,
              order_type VARCHAR(10) ,
              FramesOrdered DECIMAL(38, 8) ,
              FramesShipped DECIMAL(38, 8) ,
              back_ord_flag CHAR(1) ,
              Cust_type VARCHAR(40) ,
              return_date DATETIME ,
              reason VARCHAR(40) ,
              return_amt DECIMAL(20, 8) ,
              return_qty INT ,
              source VARCHAR(1) ,
              Qual_order INT ,
              override_reason VARCHAR(2000) ,
              UC INT ,
              wk_Begindate VARCHAR(30) ,
              wk_EndDate VARCHAR(30)
            );
			
		SELECT @PROMO = 'REVO', @PromoLevel = '1,2,3,LAUNCH 1, LAUNCH 2, LAUNCH 3'

        INSERT  INTO #temptable
                EXEC cvo_promotions_tracker_terr_sp @sdate, @edate, @Terr, @Promo, @PromoLevel;

--                 EXEC cvo_promotions_tracker_terr_sp '1/1/2016','8/22/2016', '50505','aspire','1,3,launch,new,vew'
--				   EXEC cvo_promotions_tracker_tyly_sp '1/1/2016','8/22/2016', '50505','aspire','1,3,launch,new,vew'

-- UPDATE #temptable SET yy = 'TY' WHERE yy = null

		
		
		SELECT @PROMO = 'SUNPS', @PromoLevel = 'OP'

        INSERT  INTO #temptable
                EXEC cvo_promotions_tracker_terr_sp @sdate, @edate, @Terr,
                    @Promo, @PromoLevel;
-- UPDATE #temptable SET yy = 'LY' WHERE yy = null	

      --  SELECT  t.salesperson ,
      --          t.Territory ,
      --          t.region ,
      --          t.promo_id ,
      --          t.promo_level ,
      --          SUM(t.FramesOrdered*t.Qual_order) FramesOrdered ,
      --          SUM(t.FramesShipped*t.Qual_order) FramesShipped ,
      --          SUM(t.Qual_order) Qual_order ,
      --          sum(t.order_count) Tot_order ,
      --          SUM(t.UC) UC ,
      --          t.yy
      --  FROM    ( SELECT    slp.salesperson_code salesperson ,
      --                      Territory ,
      --                      region ,
      --                      promo_id ,
      --                      promo_level ,
      --                      FramesOrdered ,
      --                      FramesShipped ,
      --                      Qual_order ,
      --                      CASE WHEN source = 'E' THEN 1 ELSE 0 END AS order_count ,
      --                      UC ,
      --                      yy = CASE WHEN date_entered >= @sdate 
      --                                THEN DATEPART(YEAR, @sdate)
      --                                WHEN date_entered <= @edately
      --                                THEN DATEPART(YEAR, @sdately)
      --                                ELSE 9999
      --                           END
      --            FROM      #temptable
				  --JOIN arsalesp slp ON slp.salesperson_code = #temptable.salesperson
      --          ) AS t
      --  GROUP BY t.salesperson ,
      --          t.Territory ,
      --          t.region ,
      --          t.promo_id ,
      --          t.promo_level ,
      --          t.yy;

		 SELECT DISTINCT * FROM #temptable AS t -- WHERE t.Territory IN ('30324','70780','30338')
	   
    END;






GO
