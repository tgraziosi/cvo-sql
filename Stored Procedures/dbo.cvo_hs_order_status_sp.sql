SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_hs_order_status_sp]
AS 

IF (SELECT OBJECT_ID('dbo.cvo_hs_orders')) IS NULL	
BEGIN
	CREATE TABLE cvo_hs_orders
	(
		hs_order_no varchar(255)	NOT NULL PRIMARY KEY
	)
	GRANT ALL ON cvo_hs_orders TO PUBLIC
END

/* test data
	INSERT INTO cvo_hs_orders (hs_order_no)
	SELECT DISTINCT TOP (100)  LTRIM(RTRIM(REPLACE(user_def_fld4,'-','')))
	FROM orders 
	WHERE user_def_fld4> '' AND date_entered > '1/1/2016' AND LEFT(user_def_fld4,1) <> 'M'
	ORDER BY LTRIM(RTRIM(REPLACE(user_def_fld4,'-',''))) DESC
*/

SELECT hosv.HS_order_no ,
       hosv.order_no ,
       hosv.HS_status ,
       hosv.status ,
       hosv.date_entered ,
       hosv.date_modified ,
       hosv.promo_id ,
       hosv.promo_level ,
       hosv.carrier ,
       hosv.tracking ,
       hosv.source ,
       h.hs_order_no
	   FROM dbo.hs_order_status_vw AS hosv
		JOIN cvo_hs_orders h ON h.hs_order_no = hosv.HS_order_no

-- select * From hs_order_status_vw where status <> 't'
GO
GRANT EXECUTE ON  [dbo].[cvo_hs_order_status_sp] TO [public]
GO
