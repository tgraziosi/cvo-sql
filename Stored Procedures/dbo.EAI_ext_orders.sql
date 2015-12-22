SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[EAI_ext_orders] @order_no int AS
BEGIN

declare @ret_status varchar(1), @ret_priority int, @row_count int

create table #ship_date_with_status_priority (req_ship_date datetime, status varchar(1), str_status varchar(10), priority int)
create table #ship_date (req_ship_date datetime, status varchar(1))

INSERT #ship_date_with_status_priority
	SELECT sch_ship_date, status, str_status='', priority=0
	FROM orders (nolock)
	WHERE order_no = @order_no AND
	      status NOT IN ('L', 'M')

SELECT @row_count = count(*)
FROM #ship_date_with_status_priority

if (@row_count <= 0) begin
   SELECT req_ship_date, status
   FROM #ship_date

   return
end

UPDATE #ship_date_with_status_priority 
	SET str_status = 'cancel', priority = 1
	WHERE status in ('V','X')

UPDATE #ship_date_with_status_priority 
	SET str_status = 'open', priority = 2
	WHERE status in ('N','P','Q','R')

UPDATE #ship_date_with_status_priority 
	SET str_status = 'shipped', priority = 3
	WHERE status in ('S','T')

UPDATE #ship_date_with_status_priority 
	SET str_status = 'hold', priority = 4
	WHERE status in ('A','B','C','E','H')

SELECT @ret_priority = MAX(priority)
FROM #ship_date_with_status_priority

SELECT @ret_status = MAX(status)
FROM #ship_date_with_status_priority
WHERE priority = @ret_priority

INSERT #ship_date
	SELECT MAX(req_ship_date) req_ship_date, status=''
	FROM #ship_date_with_status_priority

UPDATE #ship_date
	SET status = @ret_status WHERE status=''

SELECT req_ship_date, status
FROM #ship_date

END
GO
GRANT EXECUTE ON  [dbo].[EAI_ext_orders] TO [public]
GO
