SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[cvo_set_bucket_sp]  
AS  
  
SET NOCOUNT ON  
  
  
   
DECLARE @today datetime,  
    @day  smallint,  
    @month smallint,  
    @year  int,  
    @stmt  varchar(20),  
    @stmt_int int,  
    @prev_month datetime,  
    @from_month datetime  
       
SELECT @today = GETDATE()  
SELECT @day = DAY(GETDATE())  
SELECT @month = MONTH(GETDATE())  
SELECT @year = YEAR(GETDATE())  
  
  
-- tag 12/26/2012  
  
IF @day > 25 and @month <> 12  
 SELECT @month = @month + 1  
else  
if @day > 25 and @month = 12  
 begin  
  select @month = 1  
  select @year = @year + 1  
 end  
   
SELECT @stmt = STR(@month) + '/25/' + CONVERT(varchar(4),@year)  
  
SELECT @stmt_int = DATEDIFF(dd, '1/1/1753', @stmt) + 639906  
  
INSERT #dates  
SELECT @stmt_int, @stmt_int, 'future'  
  
  
SELECT @prev_month = CONVERT(datetime,DATEADD(month, -1, @stmt))  
  
INSERT #dates  
SELECT DATEDIFF(dd, '1/1/1753', @prev_month) + 639906 + 1, @stmt_int, 'current'  
  
SELECT @from_month = DATEADD(month, -1, @prev_month)  
INSERT #dates  
SELECT DATEDIFF(dd, '1/1/1753', @from_month) + 639906 + 1, DATEDIFF(dd, '1/1/1753', @prev_month) + 639906, '1-30'  
  
SELECT @prev_month = @from_month  
SELECT @from_month = DATEADD(month, -1, @prev_month)  
INSERT #dates  
SELECT DATEDIFF(dd, '1/1/1753', @from_month) + 639906 + 1, DATEDIFF(dd, '1/1/1753', @prev_month) + 639906, '31-60'  
  
SELECT @prev_month = @from_month  
SELECT @from_month = DATEADD(month, -1, @prev_month)  
INSERT #dates  
SELECT DATEDIFF(dd, '1/1/1753', @from_month) + 639906 + 1, DATEDIFF(dd, '1/1/1753', @prev_month) + 639906, '61-90'  
  
SELECT @prev_month = @from_month  
SELECT @from_month = DATEADD(month, -1, @prev_month)  
INSERT #dates  
SELECT DATEDIFF(dd, '1/1/1753', @from_month) + 639906 + 1, DATEDIFF(dd, '1/1/1753', @prev_month) + 639906, '91-120'  
  
SELECT @prev_month = @from_month  
SELECT @from_month = DATEADD(month, -1, @prev_month)  
INSERT #dates  
SELECT DATEDIFF(dd, '1/1/1753', @from_month) + 639906 + 1, DATEDIFF(dd, '1/1/1753', @prev_month) + 639906, '121-150'  
/*  
INSERT #dates  
SELECT DATEDIFF(dd, '1/1/1753', @from_month) + 639906, DATEDIFF(dd, '1/1/1753', @from_month) + 639906, 'over 150'  
*/  
  
--SELECT CONVERT(varchar(12), DATEADD(dd, date_start - 639906, '1/1/1753'),101), CONVERT(varchar(12), DATEADD(dd, date_end - 639906, '1/1/1753'),101), bucket from #dates  
  
  
  
GO
GRANT EXECUTE ON  [dbo].[cvo_set_bucket_sp] TO [public]
GO
