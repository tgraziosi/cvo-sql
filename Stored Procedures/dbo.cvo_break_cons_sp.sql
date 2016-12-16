SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_break_cons_sp] (@cons int)
AS 
BEGIN

-- exec cvo_break_cons_sp 20074

--1) -- check the consolidation info
-- DECLARE @cons INT

-- SELECT @cons = 20074

select o.order_no, o.ext, o.cust_code, co.promo_id, co.promo_level, co.st_consolidate, o.freight_allow_type, o.status, o.date_shipped
From cvo_masterpack_consolidation_det x
inner join orders o (nolock) on o.order_no = x.order_no  and o.ext = x.order_ext
inner join cvo_orders_all co (nolock) on co.order_no = x.order_no  and co.ext = x.order_ext

where x.consolidation_no in (@cons)
-- or
-- WHERE o.order_no in (2811835, 2811842)

-- SELECT * FROM dbo.cvo_masterpack_consolidation_det AS mcd WHERE mcd.consolidation_no = @cons

--2)
-- unhide the ORDER picks and remove the parent picks

EXEC dbo.cvo_masterpack_unconsolidate_pick_records_sp @consolidation_no = @cons 


-- UPDATE dbo.tdc_pick_queue SET assign_user_id = NULL WHERE trans_type_no IN ('2874349','2874350')

-- check if the consolidation is on a cart

-- SELECT * FROM dbo.cvo_cart_parts_processed AS ccpp WHERE ccpp.order_no = '17897'

-- UPDATE tdc_pick_queue SET mp_consolidation_no = 6513 WHERE mp_consolidation_no IN (6511, 6513)
-- UPDATE dbo.cvo_masterpack_consolidation_picks SET consolidation_no = 6513 WHERE consolidation_no IN (6511, 6513)
-- delete From tdc_pick_queue where mp_consolidation_no in (17938)

--SELECT * FROM dbo.tdc_pick_queue AS tpq WHERE tpq.trans_type_no IN(
--2875434,
--2875435,
--2875437)

--3)

update x set order_ext = 99
-- select * 
From cvo_masterpack_consolidation_det x
where 1=1
-- AND order_no IN (2687426)
and consolidation_no in (@cons )


UPDATE cvo_orders_all WITH (ROWLOCK) SET st_consolidate = 0 
-- SELECT * FROM cvo_orders_all 
WHERE st_consolidate = 1 
and
order_no
IN
(SELECT DISTINCT order_no 
FROM dbo.cvo_masterpack_consolidation_det AS mcd 
WHERE mcd.consolidation_no = @cons
)



END

GRANT EXECUTE on cvo_break_cons_sp TO PUBLIC

GO
GRANT EXECUTE ON  [dbo].[cvo_break_cons_sp] TO [public]
GO
