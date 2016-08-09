SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_promotions_tracker_TYLY_sp]
    @sdate DATETIME ,
    @edate DATETIME ,
    @Terr VARCHAR(1000) ,
    @Promo VARCHAR(5000) ,
    @PromoLevel VARCHAR(5000)
AS
    BEGIN

-- exec cvo_promotions_tracker_tyly_sp '1/1/2016','08/08/2016', null , 'aspire', null

        SET NOCOUNT ON;
        SET ANSI_WARNINGS OFF;


        DECLARE @sdately DATETIME ,
            @edately DATETIME;

        SELECT  @sdately = DATEADD(YEAR, -1, @sdate) ,
                @edately = DATEADD(ms, -1, @sdate);

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

        INSERT  INTO #temptable
                EXEC cvo_promotions_tracker_terr_sp @sdate, @edate, @Terr,
                    @Promo, @PromoLevel;
-- UPDATE #temptable SET yy = 'TY' WHERE yy = null

		
        INSERT  INTO #temptable
                EXEC cvo_promotions_tracker_terr_sp @sdately, @edately, @Terr,
                    @Promo, @PromoLevel;
-- UPDATE #temptable SET yy = 'LY' WHERE yy = null	

        SELECT  t.salesperson ,
                t.Territory ,
                t.region ,
                t.promo_id ,
                t.promo_level ,
                SUM(t.FramesOrdered) FramesOrdered ,
                SUM(t.FramesShipped) FramesShipped ,
                SUM(t.Qual_order) Qual_order ,
                COUNT(t.order_no) Tot_order ,
                SUM(t.UC) UC ,
                t.yy
        FROM    ( SELECT    salesperson ,
                            Territory ,
                            region ,
                            promo_id ,
                            promo_level ,
                            FramesOrdered ,
                            FramesShipped ,
                            Qual_order ,
                            order_no ,
                            UC ,
                            yy = CASE WHEN date_entered BETWEEN @sdate AND @edate
                                      THEN DATEPART(YEAR, @sdate)
                                      WHEN date_entered BETWEEN @sdately AND @edately
                                      THEN DATEPART(YEAR, @sdately)
                                      ELSE 9999
                                 END
                  FROM      #temptable
                ) AS t
        GROUP BY t.salesperson ,
                t.Territory ,
                t.region ,
                t.promo_id ,
                t.promo_level ,
                t.yy;
	   
    END;

GO
GRANT EXECUTE ON  [dbo].[cvo_promotions_tracker_TYLY_sp] TO [public]
GO
