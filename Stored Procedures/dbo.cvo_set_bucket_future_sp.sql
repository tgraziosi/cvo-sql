SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[cvo_set_bucket_future_sp]
AS
    SET NOCOUNT ON;  
  
  
  /*
  CREATE TABLE #dates
    (
      startdate INT ,
      enddate INT ,
      bucket VARCHAR(10)
    );

truncate table #dates;

EXEC dbo.cvo_set_bucket_future_sp;

SELECT  dbo.adm_format_pltdate_f(startdate) startdate ,
        dbo.adm_format_pltdate_f(enddate) enddate ,
        bucket
FROM    #dates;

*/
 
    DECLARE @today DATETIME ,
        @day SMALLINT ,
        @month SMALLINT ,
        @year INT ,
        @stmt VARCHAR(20) ,
        @stmt_int INT ,
        @next_month DATETIME ,
        @from_month DATETIME;  
       
    SELECT  @today = GETDATE();  
    SELECT  @day = DAY(GETDATE());  
    SELECT  @month = MONTH(GETDATE());  
    SELECT  @year = YEAR(GETDATE());  
  
  
-- tag 12/26/2012  
  
    IF @day > 25
        AND @month <> 12
        SELECT  @month = @month + 1;  
    ELSE
        IF @day > 25
            AND @month = 12
            BEGIN  
                SELECT  @month = 1;  
                SELECT  @year = @year + 1;  
            END;  
   
    SELECT  @stmt = STR(@month) + '/26/' + CONVERT(VARCHAR(4), @year);  
  
    SELECT  @stmt_int = DATEDIFF(dd, '1/1/1753', @stmt) + 639906;  
  
    INSERT  #dates
            SELECT  @stmt_int ,
                    @stmt_int ,
                    'future';  
  
  
    SELECT  @next_month = CONVERT(DATETIME, DATEADD(MONTH, 1, @stmt));  
  
    INSERT  #dates
            SELECT  @stmt_int ,
					DATEDIFF(dd, '1/1/1753', @next_month) + 639906 - 1  ,
                    '1-30';  
  
    SELECT  @from_month = DATEADD(MONTH, 1, @next_month);  
    INSERT  #dates
            SELECT  DATEDIFF(dd, '1/1/1753', @next_month) + 639906 ,
                    DATEDIFF(dd, '1/1/1753', @from_month) + 639906 - 1,
                    '31-60';  
  
    SELECT  @next_month = @from_month;  
    SELECT  @from_month = DATEADD(MONTH, 1, @next_month);  
    INSERT  #dates
            SELECT  DATEDIFF(dd, '1/1/1753', @next_month) + 639906 ,
                    DATEDIFF(dd, '1/1/1753', @from_month) + 639906 - 1 ,
                    '61-90';  
  
    SELECT  @next_month = @from_month;  
    SELECT  @from_month = DATEADD(MONTH, 1, @next_month);  
    INSERT  #dates
            SELECT  DATEDIFF(dd, '1/1/1753', @next_month) + 639906 ,
					DATEDIFF(dd, '1/1/1753', @from_month) + 639906 - 1 ,
                    '91-120';  
  
    SELECT  @next_month = @from_month;  
    SELECT  @from_month = DATEADD(MONTH, 1, @next_month);  
    INSERT  #dates
            SELECT  DATEDIFF(dd, '1/1/1753', @next_month) + 639906 ,
					DATEDIFF(dd, '1/1/1753', @from_month) + 639906 - 1 ,
					'121-150';  
  
    SELECT  @next_month = @from_month;  
    SELECT  @from_month = DATEADD(MONTH, 1, @next_month);  
    INSERT  #dates
            SELECT  DATEDIFF(dd, '1/1/1753', @next_month) + 639906 ,
					DATEDIFF(dd, '1/1/1753', @from_month) + 639906 - 1 ,
                    '151+';  
/*  
INSERT #dates  
SELECT DATEDIFF(dd, '1/1/1753', @from_month) + 639906, DATEDIFF(dd, '1/1/1753', @from_month) + 639906, 'over 150'  
*/  
  
--SELECT CONVERT(varchar(12), DATEADD(dd, date_start - 639906, '1/1/1753'),101), CONVERT(varchar(12), DATEADD(dd, date_end - 639906, '1/1/1753'),101), bucket from #dates  
  
  
  
GO
